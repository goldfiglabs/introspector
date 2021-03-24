import logging
import os

from sqlalchemy.orm import Session

from introspector import PathStack, db_import_writer
from introspector.aws import account_paths_for_import, load_boto_session
from introspector.aws.ec2_adjunct import find_adjunct_data
from introspector.aws.fetch import Proxy
from introspector.aws.iam import synthesize_account_root
from introspector.aws.logs import add_logs_resource_policies
from introspector.aws.mapper_fns import get_mapper_fns
from introspector.aws.svc import ImportSpec, resource_gate, service_gate
from introspector.aws.region import RegionCache
from introspector.aws.uri import get_arn_fn
from introspector.delta.partial import map_partial_deletes, map_partial_prefix
from introspector.delta.resource import map_relation_deletes, map_resource_deletes, map_resource_prefix, map_resource_relations
from introspector.error import GFError, GFInternal
from introspector.mapper import DivisionURI, load_transforms, Mapper
from introspector.models import ImportJob

_log = logging.getLogger(__name__)


class AWSDivisionURI(DivisionURI):
  def __init__(self,
               master_account_id: str,
               graph,
               org_id: str,
               partition: str = 'aws'):
    self._master_account_id = master_account_id
    self._org_id = org_id
    self._graph = graph
    self._partition = partition

  def uri_for_path(self, path: str) -> str:
    assert path != ''
    # Remove any trailing region or other data
    org_path = path.split('$')[1]
    org_segments = org_path.split('/')
    # Since this is not for a division, expect this to be an
    # account id
    tail = org_segments[-1]
    arn = f'arn:{self._partition}:organizations::{self._master_account_id}:account/{self._org_id}/{tail}'
    return arn

  def _path_to_account(self, account_id: str) -> str:
    for path, accounts in self._graph['accounts'].items():
      for account in accounts:
        if account['Id'] == account_id:
          return path.split('/')[-1]
    raise GFInternal('Could not find account')

  def _path_to_ou(self, ou_id: str) -> str:
    for path, ous in self._graph['organizational_units'].items():
      for ou in ous:
        if ou['Id'] == ou_id:
          return path.split('/')[-1]
    raise GFInternal('Could not find organizational unit')

  def uri_for_parent(self, uri: str) -> str:
    # Only called for division, so no regions, just paths
    parts = uri.split(':')
    path = parts[5]
    org_segments = path.split('/')
    node_type = org_segments[0]
    if node_type == 'root':
      # This was the root, and it's in the organization
      return f'arn:{self._partition}:organizations::{self._master_account_id}:organization/{self._org_id}'
    elif node_type == 'account':
      account_id = org_segments[2]
      tail = self._path_to_account(account_id)
    else:
      ou_id = org_segments[2]
      tail = self._path_to_ou(ou_id)
    if tail.startswith('r-'):
      # This is contained directly in the root
      return f'arn:{self._partition}:organizations::{self._master_account_id}:root/{self._org_id}/{tail}'
    elif tail.startswith('ou-'):
      # This is contained in an organizational unit
      return f'arn:{self._partition}:organizations::{self._master_account_id}:ou/{self._org_id}/{tail}'
    else:
      raise GFInternal(f'Unknown AWS graph node {tail}')


def _get_mapper(import_job: ImportJob,
                extra_attrs=None,
                extra_fns=None) -> Mapper:
  org_config = import_job.configuration['aws_org']
  division_uri = AWSDivisionURI(org_config['MasterAccountId'],
                                import_job.configuration['aws_graph'],
                                org_config['Id'])
  transform_path = os.path.join(os.path.dirname(__file__), 'transforms')
  transforms = load_transforms(transform_path)
  account_paths = import_job.configuration['aws_graph']['accounts']
  account_ids = []
  for accounts in account_paths.values():
    for account in accounts:
      account_ids.append(account['Id'])
  fns = get_mapper_fns(account_ids, extra_fns)

  return Mapper(transforms,
                import_job.provider_account_id,
                division_uri,
                extra_fns=fns,
                extra_attrs=extra_attrs)


# Everything has a 'base' source, these are extra
AWS_SOURCES = ['credentialreport', 'logspolicies']


def map_import(db: Session, import_job_id: int, partition: str,
               spec: ImportSpec):
  import_job = db.query(ImportJob).get(import_job_id)
  if import_job is None:
    raise GFInternal('Lost ImportJob')
  ps = PathStack.from_import_job(import_job)
  mapper = _get_mapper(import_job)
  gate = service_gate(spec)
  for path, account in account_paths_for_import(db, import_job):
    uri_fn = get_arn_fn(account.scope, partition)
    ps = PathStack.from_import_job(import_job).scope(account.scope)
    map_resource_prefix(db, import_job, ps.path(), mapper, uri_fn)
    boto = None
    proxy = None
    if gate('iam') is not None:
      boto = load_boto_session(account)
      proxy = Proxy.build(boto)
      synthesize_account_root(proxy, db, import_job, ps.path(), account.scope,
                              partition)
    ec2_spec = gate('ec2')
    if ec2_spec is not None and resource_gate(ec2_spec, 'Images'):
      # Additional ec2 work
      if boto is None or proxy is None:
        boto = load_boto_session(account)
        proxy = Proxy.build(boto)
      adjunct_writer = db_import_writer(db,
                                        import_job.id,
                                        import_job.provider_account_id,
                                        'ec2',
                                        phase=1,
                                        source='base')
      find_adjunct_data(db, proxy, adjunct_writer, import_job, ps, import_job)

    logs_spec = gate('logs')
    if logs_spec is not None and resource_gate(logs_spec, 'ResourcePolicies'):
      if boto is None or proxy is None:
        boto = load_boto_session(account)
        proxy = Proxy.build(boto)
      region_cache = RegionCache(boto, partition)
      adjunct_writer = db_import_writer(db,
                                        import_job.id,
                                        import_job.provider_account_id,
                                        'logs',
                                        phase=1,
                                        source='logspolicies')
      add_logs_resource_policies(db, proxy, region_cache, adjunct_writer,
                                 import_job, ps, account.scope)

    for source in AWS_SOURCES:
      map_partial_prefix(db, mapper, import_job, source, ps.path(), uri_fn)
      map_partial_deletes(db, import_job, source, spec)
    # Re-map anything we've added
    map_resource_prefix(db, import_job, ps.path(), mapper, uri_fn)

    # Handle deletes
    map_resource_deletes(db, ps.path(), import_job, spec)

    found_relations = map_resource_relations(db, import_job, ps.path(), mapper,
                                             uri_fn)

    map_relation_deletes(db, import_job, ps.path(), found_relations, spec)

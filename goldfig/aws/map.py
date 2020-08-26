from goldfig.aws.iam import synthesize_account_root
from goldfig.error import GFInternal
import os
from typing import Dict, List, Optional

from sqlalchemy.orm import Session

from goldfig import PathStack, db_import_writer
from goldfig.aws import account_paths_for_import, ProxyBuilder, load_boto_session
from goldfig.aws.ec2_adjunct import find_adjunct_data
from goldfig.aws.elb_adjunct import synthesize_endpoints
from goldfig.aws.uri import get_arn_fn
from goldfig.delta.partial import map_partial_deletes, map_partial_prefix
from goldfig.delta.resource import map_relation_deletes, map_resource_deletes, map_resource_prefix, map_resource_relations
from goldfig.mapper import DivisionURI, load_transforms, Mapper
from goldfig.models import ImportJob


def _zone_to_region(zone: str, **_) -> str:
  return zone[:-1]


def _tag_list_to_object(tags: Optional[List[Dict[str, str]]],
                        **_) -> Dict[str, str]:
  if tags is None or len(tags) == 0:
    return {}
  return {item['Key']: item['Value'] for item in tags}


def _lambda_alias_relations(parent_uri, target_raw, **kwargs):
  initial_version = target_raw['FunctionVersion']
  fn_arn = target_raw['FunctionArn']

  def version_arn(v: str) -> str:
    return f'{fn_arn}:{v}'

  version_total = 0
  weights = target_raw.get('RoutingConfig', {}).get('AdditionalVersionWeights',
                                                    {})
  for version, weight in weights.items():
    version_total += weight
    target_uri = version_arn(version)
    yield parent_uri, 'forwards-to', version_arn(version), [{
        'name': 'weight',
        'value': weight
    }]
  remaining = 1.0 - version_total
  target_uri = version_arn(initial_version)
  yield parent_uri, 'forwards-to', version_arn(initial_version), [{
      'name':
      'weight',
      'value':
      remaining
  }]


AWS_TRANSFORMS = {
    'aws_zone_to_region': _zone_to_region,
    'aws_tags': _tag_list_to_object,
    'aws_lambda_alias': _lambda_alias_relations
}


def _get_aws_not_in_org(import_job: ImportJob):
  # TODO: rewrite this. pretty sure we have the list of accounts
  account_paths = import_job.configuration['aws_graph']['accounts']

  def _aws_not_in_org(account_id: str, **kwargs) -> bool:
    for accounts in account_paths.values():
      for account in accounts:
        if account['Id'] == account_id:
          return False
    return True

  return _aws_not_in_org


class AWSDivisionURI(DivisionURI):
  def __init__(self,
               master_account_id: str,
               org_id: str,
               partition: str = 'aws'):
    self._master_account_id = master_account_id
    self._org_id = org_id
    self._partition = partition

  def uri_for_path(self, path: str) -> str:
    assert path != ''
    # Remove any trailing region or other data
    org_path = path.split('$')[0]
    org_segments = org_path.split('/')
    # Since this is not for a division, expect this to be an
    # account id
    tail = org_segments[-1]
    arn = f'arn:{self._partition}:organizations::{self._master_account_id}:account/{self._org_id}/{tail}'
    return arn

  def uri_for_parent(self, path: str) -> str:
    # Only called for division, so no regions, just paths
    org_segments = path.split('/')
    assert len(org_segments) > 0
    org_segments.pop()
    if len(org_segments) == 0:
      # This was the root, and it's in the organization
      return f'arn:{self._partition}:organizations::{self._master_account_id}:organization/{self._org_id}'
    tail = org_segments[-1]
    if tail.startswith('r-'):
      # This is contained directly in the root
      return f'arn:{self._partition}:organizations::{self._master_account_id}:root/{self._org_id}/{tail}'
    elif tail.startswith('ou-'):
      # This is contained in an organizational unit
      return f'arn:{self._partition}:organizations::{self._master_account_id}:ou/{self._org_id}/{tail}'
    else:
      raise GFInternal(f'Unknown AWS graph node {tail}')


def _get_mapper(db: Session,
                import_job: ImportJob,
                extra_attrs=None,
                extra_fns=None) -> Mapper:
  org_config = import_job.configuration['aws_org']
  division_uri = AWSDivisionURI(org_config['MasterAccountId'],
                                org_config['Id'])
  transform_path = os.path.join(os.path.dirname(__file__), 'transforms')
  transforms = load_transforms(transform_path)
  fns = AWS_TRANSFORMS.copy()
  fns['aws_not_in_org'] = _get_aws_not_in_org(import_job)
  if extra_fns is not None:
    for fn, impl in extra_fns.items():
      fns[fn] = impl
  return Mapper(transforms,
                import_job.provider_account_id,
                division_uri,
                extra_fns=fns,
                extra_attrs=extra_attrs)


# Everything has a 'base' source, these are extra
AWS_SOURCES = ['credentialreport']


def map_import(db: Session, import_job_id: int, proxy_builder: ProxyBuilder):
  import_job: ImportJob = db.query(ImportJob).get(import_job_id)
  assert import_job.path_prefix == ''
  ps = PathStack.from_import_job(import_job)
  mapper = _get_mapper(db, import_job)
  adjunct_writer = db_import_writer(db,
                                    import_job.id,
                                    'ec2',
                                    phase=1,
                                    source='base')
  for path, account in account_paths_for_import(db, import_job):
    uri_fn = get_arn_fn(account.scope)
    map_resource_prefix(db, import_job, import_job.path_prefix, mapper, uri_fn)
    boto = load_boto_session(account)
    proxy = proxy_builder(boto)
    synthesize_account_root(proxy, db, import_job, path, account.scope)
    for source in AWS_SOURCES:
      map_partial_prefix(db, mapper, import_job, source,
                         import_job.path_prefix, uri_fn)
      map_partial_deletes(db, import_job, source)
    # Additional ec2 work
    find_adjunct_data(db, proxy, adjunct_writer, import_job, ps.scope(path),
                      import_job)
    # Additional elb work
    synthesize_endpoints(db, import_job)

    # Re-map anything we've added
    map_resource_prefix(db, import_job, import_job.path_prefix, mapper, uri_fn)

    # Handle deletes
    map_resource_deletes(db, ps.scope(path).path(), import_job, service=None)

    found_relations = map_resource_relations(db, import_job,
                                             import_job.path_prefix, mapper,
                                             uri_fn)

    map_relation_deletes(db, import_job, import_job.path_prefix,
                         found_relations)

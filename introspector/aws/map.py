import logging
import os
import re
from typing import Any, Dict, List, Optional, Union

from sqlalchemy.orm import Session

from introspector import PathStack, db_import_writer
from introspector.aws import account_paths_for_import, load_boto_session
from introspector.aws.ec2_adjunct import find_adjunct_data
from introspector.aws.fetch import Proxy
from introspector.aws.iam import synthesize_account_root
from introspector.aws.logs import add_logs_resource_policies
from introspector.aws.svc import ImportSpec, resource_gate, service_gate
from introspector.aws.region import RegionCache
from introspector.aws.uri import get_arn_fn
from introspector.delta.partial import map_partial_deletes, map_partial_prefix
from introspector.delta.resource import map_relation_deletes, map_resource_deletes, map_resource_prefix, map_resource_relations
from introspector.error import GFError, GFInternal
from introspector.mapper import DivisionURI, load_transforms, Mapper
from introspector.models import ImportJob

_log = logging.getLogger(__name__)


def _zone_to_region(zone: str, **_) -> str:
  return zone[:-1]


_KEY_ATTRS = ['Key', 'key', 'TagKey']


def _aws_tag_key(item: Dict) -> str:
  for attr in _KEY_ATTRS:
    key = item.get(attr)
    if key is not None:
      return key
  raise GFError(f'Cannot find tag key in {item}')


_VALUE_ATTRS = ['Value', 'value', 'TagValue']


def _aws_tag_value(item: Dict) -> str:
  for attr in _VALUE_ATTRS:
    value = item.get(attr)
    if value is not None:
      return value
  raise GFError(f'Cannot find tag value in {item}')


def _tag_list_to_object(tags: Optional[List[Dict[str, str]]],
                        **_) -> Dict[str, str]:
  if tags is None or len(tags) == 0:
    return {}
  return {_aws_tag_key(item): _aws_tag_value(item) for item in tags}


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


def _arrayize(inval: Union[str, List[str]]) -> List[str]:
  if isinstance(inval, str):
    return [inval]
  return sorted(inval)


ALL_DIGITS = re.compile(r'^[0-9]{10}[0-9]*$')


def _normalize_principal_map(
    raw: Union[str, Dict[str, Any]]) -> Dict[str, List[Any]]:
  result = {}
  if not isinstance(raw, dict):
    if raw != '*':
      _log.warn(f'Invalid string literal principal {raw}')
      return {}
    else:
      return {'AWS': ['*']}
  for key, value in raw.items():
    values = _arrayize(value)
    if key == 'AWS':
      # normalize account ids
      principals = []
      for principal in values:
        if ':' not in principal and ALL_DIGITS.match(principal) is not None:
          principals.append(f'arn:aws:iam::{principal}:root')
        else:
          principals.append(principal)
      values = principals
    result[key] = values
  return result


EFFECTS = {'allow': 'Allow', 'deny': 'Deny'}


def policy_statement(raw: Dict[str, Any]) -> Dict[str, Any]:
  result = {}
  lc = {k.lower(): v for k, v in raw.items()}

  def _normalize(s: str, fn):
    val = lc.get(s.lower())
    if val is not None:
      result[s] = fn(val)

  sid = lc.get('sid')
  if sid is not None:
    result['Sid'] = sid
  _normalize('Principal', _normalize_principal_map)
  _normalize('NotPrincipal', _normalize_principal_map)
  result['Effect'] = EFFECTS[lc['effect'].lower()]
  _normalize('Action', _arrayize)
  _normalize('NotAction', _arrayize)
  _normalize('Resource', _arrayize)
  _normalize('NotResource', _arrayize)
  condition = lc.get('condition')
  if condition is not None:
    # TODO: deeper normalization
    result['Condition'] = condition
  return result


EMPTY_POLICY = {'Version': '2012-10-17', 'Statement': []}


def _policy(policy: Optional[Dict[str, Any]]) -> Dict[str, Any]:
  if policy is None:
    return EMPTY_POLICY
  result = {}
  lc = {k.lower(): v for k, v in policy.items()}
  result['Version'] = lc.get('version', '2012-10-17')
  policy_id = lc.get('id')
  if policy_id is not None:
    result['Id'] = policy_id
  result['Statement'] = [policy_statement(s) for s in lc.get('statement', [])]
  return result


def _policy_map(m: Optional[Dict[str, Dict[str, Any]]]) -> Dict[str, Any]:
  if m is None or len(m) == 0:
    return EMPTY_POLICY
  policies = [_policy(policy) for policy in m.values()]
  statements = []
  for policy in policies:
    statements += policy.get('Statement', [])
  return {
      'Version': '2012-10-17',
      'Id': 'Synthesized from map',
      'Statement': statements
  }


AWS_TRANSFORMS = {
    'aws_zone_to_region': _zone_to_region,
    'aws_tags': _tag_list_to_object,
    'aws_lambda_alias': _lambda_alias_relations,
    'aws_policy': _policy,
    'aws_policy_map': _policy_map
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


def _get_mapper(import_job: ImportJob,
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
    map_resource_prefix(db, import_job, import_job.path_prefix, mapper, uri_fn)
    boto = None
    proxy = None
    if gate('iam') is not None:
      boto = load_boto_session(account)
      proxy = Proxy.build(boto)
      synthesize_account_root(proxy, db, import_job, import_job.path_prefix,
                              account.scope, partition)
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
      map_partial_prefix(db, mapper, import_job, source,
                         import_job.path_prefix, uri_fn)
      map_partial_deletes(db, import_job, source, spec)
    # Re-map anything we've added
    map_resource_prefix(db, import_job, import_job.path_prefix, mapper, uri_fn)

    # Handle deletes
    map_resource_deletes(db, ps.path(), import_job, spec)

    found_relations = map_resource_relations(db, import_job,
                                             import_job.path_prefix, mapper,
                                             uri_fn)

    map_relation_deletes(db, import_job, import_job.path_prefix,
                         found_relations, spec)

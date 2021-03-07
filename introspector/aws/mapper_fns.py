import logging
import re
from typing import Any, Dict, List, Optional, Union

from introspector.error import GFError

ALL_DIGITS = re.compile(r'^[0-9]{10}[0-9]*$')

_log = logging.getLogger(__name__)

def _zone_to_region(zone: str, **_) -> str:
  return zone[:-1]

def _arrayize(inval: Union[str, List[str]]) -> List[str]:
  if isinstance(inval, str):
    return [inval]
  return sorted(inval)

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

AWS_TRANSFORMS = {
    'aws_zone_to_region': _zone_to_region,
    'aws_tags': _tag_list_to_object,
    'aws_lambda_alias': _lambda_alias_relations,
    'aws_policy': _policy,
    'aws_policy_map': _policy_map
}

def _get_aws_not_in_org(account_ids: List[str]):
  def _aws_not_in_org(account_id: str, **kwargs) -> bool:
    return account_id in account_ids

  return _aws_not_in_org

def get_mapper_fns(account_ids: List[str], extra_fns=None):
  fns = AWS_TRANSFORMS.copy()
  fns['aws_not_in_org'] = _get_aws_not_in_org(account_ids)
  if extra_fns is not None:
    for fn, impl in extra_fns.items():
      fns[fn] = impl
  return fns
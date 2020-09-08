import json
import logging
from typing import Any, Dict, Iterator, Tuple

from botocore.exceptions import ClientError

from goldfig.aws.fetch import ServiceProxy
from goldfig.aws.svc import make_import_to_db, make_import_with_pool

_log = logging.getLogger(__name__)


def _import_key(proxy: ServiceProxy, key_id: str):
  key_data = proxy.get('describe_key', KeyId=key_id)['KeyMetadata']
  try:
    tags_resp = proxy.get('list_resource_tags', KeyId=key_id)
    if tags_resp is not None:
      key_data['Tags'] = tags_resp['Tags']
  except ClientError as e:
    code = e.response.get('Error', {}).get('Code')
    if code == 'AccessDeniedException' and key_data['KeyManager'] == 'AWS':
      key_data['Tags'] = []
    else:
      raise
  policy_resp = proxy.get('get_key_policy', KeyId=key_id, PolicyName='default')
  if policy_resp is not None:
    key_data['Policy'] = json.loads(policy_resp['Policy'])
  try:
    rotation_status = proxy.get('get_key_rotation_status', KeyId=key_id)
    key_data['KeyRotationEnabled'] = rotation_status['KeyRotationEnabled']
  except ClientError as e:
    code = e.response.get('Error', {}).get('Code')
    if code == 'AccessDeniedException' and key_data['KeyManager'] == 'AWS':
      pass
    else:
      raise
  return key_data


def _import_keys(proxy: ServiceProxy) -> Iterator[Tuple[str, Any]]:
  keys_resp = proxy.list('list_keys')
  if keys_resp is not None:
    key_list = keys_resp[1]['Keys']
    for key_spec in key_list:
      yield 'Key', _import_key(proxy, key_spec['KeyId'])


def _import_kms_region(proxy: ServiceProxy,
                       region: str) -> Iterator[Tuple[str, Any]]:
  _log.info(f'import kms in {region}')
  yield from _import_keys(proxy)


import_account_kms_region_to_db = make_import_to_db('kms', _import_kms_region)
import_account_kms_region_with_pool = make_import_with_pool(
    'kms', _import_kms_region)

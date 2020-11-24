import json
import logging
from typing import Any, Dict, Iterator, Tuple

from goldfig.aws.fetch import ServiceProxy
from goldfig.aws.svc import GlobalService

_log = logging.getLogger(__name__)


def _import_bucket(proxy: ServiceProxy, bucket_metadata) -> Dict:
  _log.info(f'Importing {bucket_metadata["Name"]}')
  result = bucket_metadata.copy()
  for op_name in proxy.resource_names():
    canonical_name = proxy.canonical_name(op_name)
    if op_name.startswith('list_'):
      list_result = proxy.list(op_name, Bucket=bucket_metadata['Name'])
      if list_result is not None:
        key = canonical_name[len('ListBucket'):]
        result[key] = list_result[1]
      continue
    attr_result = proxy.get(op_name, Bucket=bucket_metadata['Name'])
    if attr_result is not None:
      key = canonical_name[len('GetBucket'):]
      # TODO: enumerate these methods
      if key in attr_result:
        result[key] = attr_result[key]
      else:
        result[key] = attr_result
      if key in ('Policy', ):
        result[key] = json.loads(result[key])
    elif op_name == 'get_bucket_location':
      result['Location'] = {'LocationConstraint': 'us-east-1'}
  public_conf_resp = proxy.get('get_public_access_block',
                               Bucket=bucket_metadata['Name'])
  if public_conf_resp is not None:
    public_attrs = public_conf_resp['PublicAccessBlockConfiguration']
    result.update(public_attrs)
  return result


def _import_s3(service_proxy: ServiceProxy) -> Iterator[Tuple[str, Any]]:
  result = service_proxy.list('list_buckets')
  if result is not None:
    buckets = result[1]
    for bucket in buckets['Buckets']:
      yield 'Bucket', _import_bucket(service_proxy, bucket)


SVC = GlobalService('s3', _import_s3)

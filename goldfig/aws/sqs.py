import logging
from typing import Any, Dict, Generator, Tuple

from botocore.exceptions import ClientError

from goldfig.aws.fetch import ServiceProxy
from goldfig.aws.svc import make_import_to_db, make_import_with_pool
from goldfig.error import GFNoAccess

_log = logging.getLogger(__name__)


def _import_queue(proxy: ServiceProxy, queue_url: str) -> Dict[str, Any]:
  attrs_resp = proxy.get('get_queue_attributes',
                         QueueUrl=queue_url,
                         AttributeNames=['All'])
  if attrs_resp is None:
    raise GFNoAccess('sqs', 'get_queue_attributes')
  attrs = attrs_resp['Attributes']
  attrs['url'] = queue_url
  tags_resp = proxy.get('list_queue_tags', QueueUrl=queue_url)
  if tags_resp is not None:
    attrs['Tags'] = tags_resp['Tags']
  return attrs


def _import_queues(proxy: ServiceProxy, region: str):
  queues_resp = proxy.list('list_queues')
  if queues_resp is not None:
    queue_urls = queues_resp[1].get('QueueUrls', [])
    for queue_url in queue_urls:
      try:
        yield 'Queue', _import_queue(proxy, queue_url)
      except GFNoAccess as e:
        _log.error(f'sqs error {region}', exc_info=e)


def _import_sqs_region(proxy: ServiceProxy,
                       region: str) -> Generator[Tuple[str, Any], None, None]:
  _log.info(f'importing sqs Queues')
  yield from _import_queues(proxy, region)


import_account_sqs_region_to_db = make_import_to_db('sqs', _import_sqs_region)

import_account_sqs_region_with_pool = make_import_with_pool(
    'sqs', _import_sqs_region)
import logging
from typing import Any, Dict, Generator, Tuple

from goldfig.aws.fetch import ServiceProxy
from goldfig.aws.svc import make_import_to_db, make_import_with_pool

_log = logging.getLogger(__name__)


def _import_queue(proxy: ServiceProxy, queue_url: str) -> Dict[str, Any]:
  attrs = proxy.get('get_queue_attributes', QueueUrl=queue_url)['Attributes']
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
      yield 'Queue', _import_queue(proxy, queue_url)


def _import_sqs_region(proxy: ServiceProxy,
                       region: str) -> Generator[Tuple[str, Any], None, None]:
  _log.info(f'importing sqs Queues')
  yield from _import_queues(proxy, region)


import_account_sqs_region_to_db = make_import_to_db('sqs', _import_sqs_region)

import_account_sqs_region_with_pool = make_import_with_pool(
    'sqs', _import_sqs_region)
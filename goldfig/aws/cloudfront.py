from dis import dis
import logging
from typing import Any, Dict, Generator, Tuple

from goldfig.aws.fetch import ServiceProxy
from goldfig.aws.svc import make_global_import_to_db, make_global_import_with_pool

_log = logging.getLogger(__name__)


def _import_distribution(proxy: ServiceProxy, summary: Dict) -> Dict[str, Any]:
  arn = summary['ARN']
  distribution_id = summary['Id']
  distribution = proxy.get('get_distribution',
                           Id=distribution_id)['Distribution']
  config = proxy.get('get_distribution_config', Id=distribution_id)
  distribution.update(config)
  tags_resp = proxy.list('list_tags_for_resource', Resource=arn)
  if tags_resp is not None:
    distribution['Tags'] = tags_resp[1]['Tags']['Items']
  return distribution


def _import_distributions(proxy: ServiceProxy):
  distributions_resp = proxy.list('list_distributions')
  if distributions_resp is not None:
    distributions = distributions_resp[1].get('DistributionList',
                                              {}).get('Items', [])
    for summary in distributions:
      yield 'Distribution', _import_distribution(proxy, summary)


def _import_cloudfront(
    proxy: ServiceProxy) -> Generator[Tuple[str, Any], None, None]:
  _log.info(f'importing cloudfront distributions')
  yield from _import_distributions(proxy)


import_account_cloudfront_to_db = make_global_import_to_db(
    'cloudfront', [_import_cloudfront])

import_account_cloudfront_with_pool = make_global_import_with_pool(
    'cloudfront', [_import_cloudfront])
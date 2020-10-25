from dis import dis
import logging
from typing import Any, Dict, Generator, Tuple

from goldfig.aws.fetch import ServiceProxy
from goldfig.aws.svc import make_import_to_db, make_import_with_pool

_log = logging.getLogger(__name__)

ApiResources = [
    'stages',
    'routes',
    #'integrations', # Disabled, needs more permissions
    #'models' # Disabled, needs more permissions
]


def _import_api(proxy: ServiceProxy, api: Dict) -> Dict[str, Any]:
  api_id = api['ApiId']
  for resource in ApiResources:
    resp = proxy.list('get_' + resource, ApiId=api_id)
    if resp is not None:
      api[resource.capitalize()] = resp[1]['Items']
  return api


def _import_apis(proxy: ServiceProxy, region: str):
  apis_resp = proxy.list('get_apis')
  if apis_resp is not None:
    apis = apis_resp[1]['Items']
    for api in apis:
      yield 'Api', _import_api(proxy, api)


def _import_apigatewayv2_region(
    proxy: ServiceProxy,
    region: str) -> Generator[Tuple[str, Any], None, None]:
  _log.info(f'importing Apis')
  yield from _import_apis(proxy, region)


import_account_apigatewayv2_region_to_db = make_import_to_db(
    'apigatewayv2', _import_apigatewayv2_region)

import_account_apigatewayv2_region_with_pool = make_import_with_pool(
    'apigatewayv2', _import_apigatewayv2_region)
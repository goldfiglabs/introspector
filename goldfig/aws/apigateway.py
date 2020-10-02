from dis import dis
import logging
from typing import Any, Dict, Generator, Tuple

from goldfig.aws.fetch import ServiceProxy
from goldfig.aws.svc import make_import_to_db, make_import_with_pool

_log = logging.getLogger(__name__)

ApiResources = ['stages']


def _import_rest_api(proxy: ServiceProxy, api: Dict) -> Dict[str, Any]:
  api_id = api['id']
  for resource in ApiResources:
    resp = proxy.list('get_' + resource, restApiId=api_id)
    if resp is not None:
      api[resource.capitalize()] = resp[1]['item']
  return api


def _import_rest_apis(proxy: ServiceProxy, region: str):
  apis_resp = proxy.list('get_rest_apis')
  if apis_resp is not None:
    apis = apis_resp[1]['items']
    for api in apis:
      yield 'RestApi', _import_rest_api(proxy, api)


def _import_apigateway_region(
    proxy: ServiceProxy,
    region: str) -> Generator[Tuple[str, Any], None, None]:
  _log.info(f'importing RestApis')
  yield from _import_rest_apis(proxy, region)


import_account_apigateway_region_to_db = make_import_to_db(
    'apigateway', _import_apigateway_region)

import_account_apigateway_region_with_pool = make_import_with_pool(
    'apigateway', _import_apigateway_region)
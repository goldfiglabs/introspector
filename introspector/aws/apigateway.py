import logging
from typing import Any, Dict, Generator, Tuple

from introspector.aws.fetch import ServiceProxy
from introspector.aws.svc import RegionalService, ServiceSpec, resource_gate

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
    proxy: ServiceProxy, region: str,
    spec: ServiceSpec) -> Generator[Tuple[str, Any], None, None]:
  _log.info(f'importing RestApis')
  if resource_gate(spec, 'RestApi'):
    yield from _import_rest_apis(proxy, region)


SVC = RegionalService('apigateway', _import_apigateway_region)
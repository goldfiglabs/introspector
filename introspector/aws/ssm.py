import logging
from typing import Any, Dict, Generator, Tuple

from introspector.aws.fetch import ServiceProxy
from introspector.aws.svc import RegionalService, ServiceSpec, resource_gate

_log = logging.getLogger(__name__)


def _import_parameter(proxy: ServiceProxy, parameter_data: Dict):
  # TODO: bump permissions to get this value
  # resource_id = parameter_data['Name']
  # tags_result = proxy.get('list_tags_for_resource',
  #                         ResourceId=resource_id,
  #                         ResourceType='Parameter')
  # if tags_result is not None:
  #   tag_list = tags_result.get('TagList', [])
  #   parameter_data['Tags'] = tag_list
  return parameter_data


def _import_parameters(proxy: ServiceProxy, region: str):
  parameters_resp = proxy.list('describe_parameters')
  if parameters_resp is not None:
    parameters = parameters_resp[1]['Parameters']
    if parameters is not None:
      for parameter in parameters:
        yield 'Parameter', _import_parameter(proxy, parameter)


def _import_ssm_region(
    proxy: ServiceProxy, region: str,
    spec: ServiceSpec) -> Generator[Tuple[str, Any], None, None]:
  if resource_gate(spec, 'Parameter'):
    _log.info(f'importing describe_parameters {region}')
    yield from _import_parameters(proxy, region)


SVC = RegionalService('ssm', _import_ssm_region)
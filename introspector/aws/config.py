import logging
from typing import Any, Dict, Iterator, Tuple

from introspector.aws.fetch import ServiceProxy
from introspector.aws.svc import RegionalService, ServiceSpec, resource_gate

_log = logging.getLogger(__name__)


def _import_recorder(proxy: ServiceProxy, recorder_data: Dict):
  name = recorder_data['name']
  recorder_status_resp = proxy.list('describe_configuration_recorder_status',
                                    ConfigurationRecorderNames=[name])
  if recorder_status_resp is not None:
    statuses = recorder_status_resp[1]['ConfigurationRecordersStatus']
    if len(statuses) == 1:
      recorder_data.update(statuses[0])
    elif len(statuses) > 1:
      _log.warn(
          f'Received multiple statuses for configuration recorder {name}')
  return recorder_data


def _import_recorders(proxy: ServiceProxy):
  recorders_resp = proxy.list('describe_configuration_recorders')
  if recorders_resp is not None:
    recorders = recorders_resp[1]['ConfigurationRecorders']
    for recorder in recorders:
      yield 'ConfigurationRecorder', _import_recorder(proxy, recorder)


def _import_config_region(proxy: ServiceProxy, region: str,
                          spec: ServiceSpec) -> Iterator[Tuple[str, Any]]:
  _log.info(f'import config recorders in {region}')
  if resource_gate(spec, 'ConfigurationRecorder'):
    yield from _import_recorders(proxy)


SVC = RegionalService('config', _import_config_region)
import logging
from typing import Any, Dict, Iterator, Tuple

from introspector.aws.fetch import ServiceProxy
from introspector.aws.svc import RegionalService, ServiceSpec, resource_gate

_log = logging.getLogger(__name__)


def _import_log_group(proxy: ServiceProxy, group: Dict) -> Dict:
  name = group['logGroupName']
  tags_result = proxy.list('list_tags_log_group', logGroupName=name)
  if tags_result is not None:
    group['Tags'] = tags_result[1]['tags']
  filters_resp = proxy.list('describe_metric_filters', logGroupName=name)
  if filters_resp is not None:
    group['MetricFilters'] = filters_resp[1]['metricFilters']
  return group


def _import_log_groups(proxy: ServiceProxy):
  groups_resp = proxy.list('describe_log_groups')
  if groups_resp is not None:
    groups = groups_resp[1].get('logGroups', [])
    for group_data in groups:
      yield 'LogGroup', _import_log_group(proxy, group_data)


def _import_logs_region(proxy: ServiceProxy, region: str,
                        spec: ServiceSpec) -> Iterator[Tuple[str, Any]]:
  if resource_gate(spec, 'LogGroup'):
    _log.info(f'Import LogGroups in {region}')
    yield from _import_log_groups(proxy)


SVC = RegionalService('logs', _import_logs_region)
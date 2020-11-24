import logging
from typing import Any, Dict, Iterator, Tuple

from goldfig.aws.fetch import ServiceProxy
from goldfig.aws.svc import RegionalService

_log = logging.getLogger(__name__)


def _import_alarm(proxy: ServiceProxy, alarm_data: Dict):
  arn = alarm_data['AlarmArn']
  tags_result = proxy.list('list_tags_for_resource', ResourceARN=arn)
  if tags_result is not None:
    alarm_data['Tags'] = tags_result[1]['Tags']
  return alarm_data


def _import_alarms(proxy: ServiceProxy):
  alarms_resp = proxy.list('describe_alarms',
                           AlarmTypes=['MetricAlarm', 'CompositeAlarm'])
  if alarms_resp is not None:
    metric_alarms = alarms_resp[1]['MetricAlarms']
    for alarm in metric_alarms:
      yield 'MetricAlarm', _import_alarm(proxy, alarm)
    composite_alarms = alarms_resp[1]['CompositeAlarms']
    for alarm in composite_alarms:
      yield 'CompositeAlarm', _import_alarm(proxy, alarm)


def _import_metrics(proxy: ServiceProxy):
  metrics_resp = proxy.list('list_metrics')
  if metrics_resp is not None:
    metrics = metrics_resp[1]['Metrics']
    for metric in metrics:
      if not metric['Namespace'].startswith('AWS'):
        yield 'Metric', metric


def _import_cloudwatch_region(proxy: ServiceProxy,
                              region: str) -> Iterator[Tuple[str, Any]]:
  _log.info(f'import alarms in {region}')
  yield from _import_alarms(proxy)
  yield from _import_metrics(proxy)


SVC = RegionalService('cloudwatch', _import_cloudwatch_region)
import logging
from typing import Any, Iterator, Tuple

from introspector.aws.fetch import ServiceProxy
from introspector.aws.svc import RegionalService, ServiceSpec, resource_gate

_log = logging.getLogger(__name__)


def _import_launch_configurations(proxy: ServiceProxy):
  configs_resp = proxy.list('describe_launch_configurations')
  if configs_resp is not None:
    configs = configs_resp[1]['LaunchConfigurations']
    for config in configs:
      yield 'LaunchConfiguration', config


def _import_autoscaling_groups(proxy: ServiceProxy):
  groups_resp = proxy.list('describe_auto_scaling_groups')
  if groups_resp is not None:
    groups = groups_resp[1]['AutoScalingGroups']
    for group in groups:
      yield 'AutoScalingGroup', group


def _import_autoscaling_region(proxy: ServiceProxy, region: str,
                               spec: ServiceSpec) -> Iterator[Tuple[str, Any]]:
  _log.info(f'import autoscaling in {region}')
  if resource_gate(spec, 'AutoScalingGroup'):
    yield from _import_autoscaling_groups(proxy)
  if resource_gate(spec, 'LaunchConfiguration'):
    yield from _import_launch_configurations(proxy)


SVC = RegionalService('autoscaling', _import_autoscaling_region)
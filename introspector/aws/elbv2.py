import logging
from typing import Any, Dict, Generator, Tuple

from introspector.aws.fetch import ServiceProxy
from introspector.aws.svc import RegionalService, ServiceSpec, resource_gate

_log = logging.getLogger(__name__)

_to_bool = lambda s: s in ('true', 'True')

_TG_ATTR_TYPES = {
    'deregistration_delay_timeout_seconds': int,
    'stickiness_enabled': _to_bool,
    'stickiness_type': str,
    'load_balancing_algorithm_type': str,
    'slow_start_duration_seconds': int,
    'stickiness_lb_cookie_duration_seconds': int,
    'lambda_multi_value_headers_enabled': _to_bool,
    'proxy_protocol_v2_enabled': _to_bool,
}


def _import_target_group(proxy: ServiceProxy, target_group: Dict):
  arn = target_group['TargetGroupArn']
  attributes = proxy.get('describe_target_group_attributes',
                         TargetGroupArn=arn)['Attributes']
  for key, value in attributes:
    replaced = key.replace('.', '_')
    transform = _TG_ATTR_TYPES.get(replaced, str)
    transformed = transform(value)
    target_group[replaced] = transformed

  tags_resp = proxy.get('describe_tags', ResourceArns=[arn])
  tag_descs = tags_resp.get('TagDescriptions', [])
  if len(tag_descs) == 1:
    target_group['Tags'] = tag_descs[0]['Tags']
  return target_group


def _import_target_groups(proxy: ServiceProxy):
  target_groups_resp = proxy.list('describe_target_groups')
  if target_groups_resp is not None:
    target_groups = target_groups_resp[1].get('TargetGroups', [])
    for target_group in target_groups:
      yield 'TargetGroup', _import_target_group(proxy, target_group)


def _import_listeners(proxy: ServiceProxy, loadbalancer_arn: str):
  listeners_resp = proxy.list('describe_listeners',
                              LoadBalancerArn=[loadbalancer_arn])
  if listeners_resp is not None:
    listeners = listeners_resp[1].get('Listeners', [])
    for listener in listeners:
      yield 'Listener', listener


_LB_ATTR_TYPES = {
    'access_logs_s3_enabled': _to_bool,
    'access_logs_s3_bucket': str,
    'access_logs_s3_prefix': str,
    'deletion_protection_enabled': _to_bool,
    'idle_timeout_timeout_seconds': int,
    'routing_http_desync_mitigation_mode': str,
    'routing_http_drop_invalid_header_fields_enabled': _to_bool,
    'routing_http2_enabled': _to_bool,
    'load_balancing_cross_zone_enabled': _to_bool
}


def _import_loadbalancer(proxy: ServiceProxy, lb: Dict):
  arn = lb['LoadBalancerArn']
  attributes = proxy.get('describe_load_balancer_attributes',
                         LoadBalancerArn=arn)['Attributes']
  for key, value in attributes:
    replaced = key.replace('.', '_')
    transform = _LB_ATTR_TYPES.get(replaced, str)
    transformed = transform(value)
    lb[replaced] = transformed

  tags_resp = proxy.get('describe_tags', ResourceArns=[arn])
  tag_descs = tags_resp.get('TagDescriptions', [])
  if len(tag_descs) == 1:
    lb['Tags'] = tag_descs[0]['Tags']
  return lb


def _import_loadbalancers(proxy: ServiceProxy, spec: ServiceSpec):
  lbs_resp = proxy.list('describe_load_balancers')
  if lbs_resp is not None:
    lbs = lbs_resp[1].get('LoadBalancers', [])
    for lb in lbs:
      yield 'LoadBalancer', _import_loadbalancer(proxy, lb)
      if resource_gate(spec, 'Listener'):
        yield from _import_listeners(proxy, lb['LoadBalancerArn'])


def _import_elbv2_region(
    proxy: ServiceProxy, region: str,
    spec: ServiceSpec) -> Generator[Tuple[str, Any], None, None]:
  _log.info(f'importing elbv2 {region}')
  if resource_gate(spec, 'LoadBalancer'):
    yield from _import_loadbalancers(proxy, spec)
  if resource_gate(spec, 'TargetGroup'):
    yield from _import_target_groups(proxy)


SVC = RegionalService('elbv2', _import_elbv2_region)
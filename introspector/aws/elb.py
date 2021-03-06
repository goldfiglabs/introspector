import logging

from introspector.aws.fetch import ServiceProxy
from introspector.aws.svc import RegionalService, ServiceSpec, resource_gate

_log = logging.getLogger(__name__)


def import_elb(proxy: ServiceProxy, elb):
  result = elb.copy()
  elb_name = elb['LoadBalancerName']
  for resource in proxy.resource_names():
    canonical_name = proxy.canonical_name(resource)
    is_tags = canonical_name == 'DescribeTags'
    if is_tags:
      kwargs = {'LoadBalancerNames': [elb_name]}
    else:
      kwargs = {'LoadBalancerName': elb_name}
    list_result = proxy.list(resource, **kwargs)
    if list_result is not None:
      if is_tags:
        tag_descriptions = list_result[1]['TagDescriptions']
        if len(tag_descriptions) > 0:
          result['Tags'] = tag_descriptions[0]['Tags']
        else:
          result['Tags'] = []
      else:
        key = canonical_name[len('DescribeLoadBalancer'):]
        result[key] = list_result[1]
  return result


def _is_v2(arn) -> bool:
  return ':loadbalancer/net/' in arn or ':loadbalancer/app/' in arn


def _import_elb_region(proxy: ServiceProxy, region: str, spec: ServiceSpec):
  if resource_gate(spec, 'LoadBalancer'):
    _log.info(f'Importing {region} load balancers')
    result = proxy.list('describe_load_balancers')
    if result is not None:
      elbs = result[1]
      for elb in elbs.get('LoadBalancerDescriptions', []):
        if not _is_v2(elb['LoadBalancerName']):
          yield 'LoadBalancer', import_elb(proxy, elb)


SVC = RegionalService('elb', _import_elb_region)

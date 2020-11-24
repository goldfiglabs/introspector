from typing import Any, Dict, Iterator, Tuple

from goldfig.aws.fetch import ServiceProxy
from goldfig.aws.svc import GlobalService


def _import_hosted_zone(proxy: ServiceProxy, hosted_zone: Dict):
  zone_id = hosted_zone['Id']
  if zone_id.startswith('/hostedzone/'):
    zone_id = zone_id[len('/hostedzone/'):]
    hosted_zone['Id'] = zone_id
  query_logging_resp = proxy.list('list_query_logging_configs',
                                  HostedZoneId=zone_id)
  if query_logging_resp is not None:
    hosted_zone['QueryLoggingConfigs'] = query_logging_resp[1][
        'QueryLoggingConfigs']
  vpcs_resp = proxy.list('list_vpc_association_authorizations',
                         HostedZoneId=zone_id)
  if vpcs_resp is not None:
    hosted_zone['VPCs'] = vpcs_resp[1]['VPCs']
  traffic_policies_resp = proxy.list(
      'list_traffic_policy_instances_by_hosted_zone', HostedZoneId=zone_id)
  if traffic_policies_resp is not None:
    hosted_zone['TrafficPolicyInstances'] = traffic_policies_resp[1][
        'TrafficPolicyInstances']
  resource_record_sets_resp = proxy.list('list_resource_record_sets',
                                         HostedZoneId=zone_id)
  if resource_record_sets_resp is not None:
    hosted_zone['ResourceRecordSets'] = resource_record_sets_resp[1][
        'ResourceRecordSets']
  tags_resp = proxy.list('list_tags_for_resource',
                         ResourceType='hostedzone',
                         ResourceId=zone_id)
  if tags_resp is not None:
    hosted_zone['Tags'] = tags_resp[1]['ResourceTagSet']['Tags']
  return hosted_zone


def _import_route53(proxy: ServiceProxy) -> Iterator[Tuple[str, Any]]:
  zones_resp = proxy.list('list_hosted_zones')
  if zones_resp is not None:
    for zone in zones_resp[1]['HostedZones']:
      yield 'HostedZone', _import_hosted_zone(proxy, zone)


SVC = GlobalService('route53', _import_route53)
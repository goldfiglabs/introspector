from collections import defaultdict
import json
import logging
from typing import Any, Dict, List, Iterator, Iterable, Tuple

from sqlalchemy.orm import Session

from introspector import ImportWriter, PathStack
from introspector.aws.fetch import Proxy, ServiceProxy
from introspector.aws.region import RegionCache
from introspector.aws.svc import RegionalService, ServiceSpec, resource_gate
from introspector.models import ImportJob, Resource

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


def normalize_resource_policies(policies: List) -> Dict[str, List[Any]]:
  from introspector.aws.map import policy_statement
  resource_statements_map: Dict[str, List[Any]] = {}
  for policy_data in policies:
    name = policy_data.get('policyName', 'unnamed')
    document = json.loads(policy_data.get('policyDocument', '{}'))
    for statement in document.get('Statement', []):
      statement_common = policy_statement(statement)
      other_keys = [
          key for key in statement_common.keys()
          if key not in ('Resource', 'Sid')
      ]
      sid = statement_common.get('Sid', 'nosid')
      for resource in statement_common.get('Resource', []):
        to_add = {
            key: value
            for key, value in statement_common.items() if key in other_keys
        }
        to_add['Resource'] = [resource]
        to_add['Sid'] = '_'.join([name, sid])
        resource_statements = resource_statements_map.get(resource, [])
        resource_statements.append(to_add)
        resource_statements_map[resource] = resource_statements
  return resource_statements_map


def _import_resource_policies(proxy: ServiceProxy) -> Dict[str, List[Any]]:
  policies_resp = proxy.list('describe_resource_policies')
  if policies_resp is not None:
    policies = policies_resp[1].get('resourcePolicies', [])
    return normalize_resource_policies(policies)
  return {}


def _log_group_uris_by_prefix(db: Session, provider_account_id: int,
                              account_id: str, region: str, prefix: str) -> Iterable[str]:
  prefix_with_wildcards = prefix.replace('*', '%')
  # if the prefix has a spot for an account id, fill it in
  parts = prefix_with_wildcards.split(':')
  if len(parts) < 5:
    prefix_parts = ['arn', 'aws', 'logs', region, account_id, '%']
    for incoming, expected in zip(parts, prefix_parts):
      if incoming != expected and incoming != '%':
        return []
    # TODO: partition
    parts = ['arn', 'aws', 'logs', region, account_id, '%']
  else:
    parts[4] = account_id
    # Handle the case where the resource is 'arn:aws:logs:region:*'
    if len(parts) == 5:
      parts.append('%')
  resolved_prefix = ':'.join(parts)
  return map(lambda row: row[0], db.query(Resource.uri).filter(
      Resource.provider_account_id == provider_account_id,
      Resource.service == 'logs',
      Resource.provider_type == 'LogGroup',
      Resource.uri.like(resolved_prefix)).all())


def _make_policy(statements):
  return {'Version': '2012-10-17', 'Statement': statements}


def add_logs_resource_policies(db: Session, proxy: Proxy,
                               region_cache: RegionCache, writer: ImportWriter,
                               import_job: ImportJob, ps: PathStack,
                               account_id: str):
  for region in region_cache.regions_for_service('logs'):
    logs_proxy = proxy.service('logs', region)
    policies = _import_resource_policies(logs_proxy)
    synthesized = defaultdict(lambda: [])
    for prefix, statements in policies.items():
      for log_group_uri in _log_group_uris_by_prefix(
          db, import_job.provider_account_id, account_id, region, prefix):
        synthesized[log_group_uri] += statements
    for uri, statements in synthesized.items():
      policy = _make_policy(statements)
      writer(ps, 'ResourcePolicy', {
          'Policy': policy,
          'arn': uri
      }, {'region': region})


def _import_logs_region(proxy: ServiceProxy, region: str,
                        spec: ServiceSpec) -> Iterator[Tuple[str, Any]]:
  if resource_gate(spec, 'LogGroup'):
    _log.info(f'Import LogGroups in {region}')
    yield from _import_log_groups(proxy)


SVC = RegionalService('logs', _import_logs_region)
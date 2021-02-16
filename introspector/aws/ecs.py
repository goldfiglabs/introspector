import logging
from typing import Any, Dict, Generator, Tuple

from introspector.aws.fetch import ServiceProxy
from introspector.aws.svc import RegionalService, ServiceSpec, resource_gate
from introspector.error import GFInternal

_log = logging.getLogger(__name__)


def _import_cluster(proxy: ServiceProxy, cluster_arn: str) -> Dict[str, Any]:
  clusters_resp = proxy.list(
      'describe_clusters',
      clusters=[cluster_arn],
      include=["ATTACHMENTS", "SETTINGS", "STATISTICS", "TAGS"])
  if clusters_resp is None:
    raise GFInternal(f'Failed to fetch ecs cluster {cluster_arn}')
  cluster_list = clusters_resp[1].get('clusters', [])
  if len(cluster_list) != 1:
    raise GFInternal(
        f'Wrong number of clusters for {cluster_arn} {clusters_resp}')
  cluster = cluster_list[0]
  return cluster


def _import_service(proxy: ServiceProxy, cluster_arn: str, service_arn: str):
  services_resp = proxy.list('describe_services',
                             cluster=cluster_arn,
                             services=[service_arn],
                             include=['TAGS'])
  if services_resp is None:
    raise GFInternal(f'Failed to fetch ecs service {service_arn}')
  service_list = services_resp[1].get('services', [])
  if len(service_list) != 1:
    raise GFInternal(
        f'Wrong number of services for {service_arn} {services_resp}')
  service = service_list[0]
  return service


def _import_services(proxy: ServiceProxy, cluster_arn: str):
  services_resp = proxy.list('list_services', cluster=cluster_arn)
  if services_resp is not None:
    service_arns = services_resp[1].get('serviceArns', [])
    for service_arn in service_arns:
      yield 'Service', _import_service(proxy, cluster_arn, service_arn)


def _import_task(proxy: ServiceProxy, cluster_arn: str, task_arn: str):
  tasks_resp = proxy.list('describe_tasks',
                          cluster=cluster_arn,
                          tasks=[task_arn],
                          include=['TAGS'])
  if tasks_resp is None:
    raise GFInternal(f'Failed to fetch ecs task {task_arn}')
  task_list = tasks_resp[1].get('tasks', [])
  if len(task_list) != 1:
    raise GFInternal(f'Wrong number of tasks for {task_arn} {tasks_resp}')
  task = task_list[0]
  return task


def _import_tasks(proxy: ServiceProxy, cluster_arn: str):
  tasks_resp = proxy.list('list_tasks', cluster=cluster_arn)
  if tasks_resp is not None:
    task_arns = tasks_resp[1].get('taskArns', [])
    for task_arn in task_arns:
      yield 'Task', _import_task(proxy, cluster_arn, task_arn)


def _import_clusters(proxy: ServiceProxy, region: str, spec: ServiceSpec):
  clusters_resp = proxy.list('list_clusters')
  if clusters_resp is not None:
    cluster_arns = clusters_resp[1].get('clusterArns', [])
    for cluster_arn in cluster_arns:
      yield 'Cluster', _import_cluster(proxy, cluster_arn)
      if resource_gate(spec, 'Service'):
        yield from _import_services(proxy, cluster_arn)
      if resource_gate(spec, 'Task'):
        yield from _import_tasks(proxy, cluster_arn)


def _import_task_definition(proxy: ServiceProxy, definition_arn: str):
  definition = proxy.get('describe_task_definition',
                         taskDefinition=definition_arn,
                         include=['TAGS'])['taskDefinition']
  return definition


def _import_task_definitions(proxy: ServiceProxy):
  definitions_resp = proxy.list('list_task_definitions')
  if definitions_resp is not None:
    definition_arns = definitions_resp[1].get('taskDefinitionArns', [])
    for definition_arn in definition_arns:
      yield 'TaskDefinition', _import_task_definition(proxy, definition_arn)


def _import_ecs_region(
    proxy: ServiceProxy, region: str,
    spec: ServiceSpec) -> Generator[Tuple[str, Any], None, None]:
  if resource_gate(spec, 'Cluster'):
    _log.info(f'importing ecs clusters')
    yield from _import_clusters(proxy, region, spec)
  if resource_gate(spec, 'TaskDefinition'):
    yield from _import_task_definitions(proxy)


SVC = RegionalService('ecs', _import_ecs_region)
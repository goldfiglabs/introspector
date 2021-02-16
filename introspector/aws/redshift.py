import logging
from typing import Any, Dict, Generator, Tuple

from introspector.aws.fetch import ServiceProxy
from introspector.aws.svc import RegionalService, ServiceSpec, resource_gate

_log = logging.getLogger(__name__)


def _import_cluster(proxy: ServiceProxy, cluster: Dict) -> Dict[str, Any]:
  cluster_id = cluster['ClusterIdentifier']
  logging_status = proxy.get('describe_logging_status',
                             ClusterIdentifier=cluster_id)
  cluster['LoggingStatus'] = logging_status
  return cluster


def _import_clusters(proxy: ServiceProxy, region: str):
  clusters_resp = proxy.list('describe_clusters')
  if clusters_resp is not None:
    clusters = clusters_resp[1]['Clusters']
    for cluster in clusters:
      yield 'Cluster', _import_cluster(proxy, cluster)


def _import_redshift_region(
    proxy: ServiceProxy, region: str,
    spec: ServiceSpec) -> Generator[Tuple[str, Any], None, None]:
  if resource_gate(spec, 'Cluster'):
    _log.info(f'importing Redshift Clusters')
    yield from _import_clusters(proxy, region)


SVC = RegionalService('redshift', _import_redshift_region)
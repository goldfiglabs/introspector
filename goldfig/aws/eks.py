import logging
from typing import Any, Dict, Generator, Iterator, Tuple

from goldfig.aws.fetch import ServiceProxy
from goldfig.aws.svc import RegionalService
from goldfig.error import GFInternal

_log = logging.getLogger(__name__)


def _import_cluster(proxy: ServiceProxy, cluster_name: str) -> Dict[str, Any]:
  cluster_resp = proxy.get('describe_cluster', name=cluster_name)
  if cluster_resp is None:
    raise GFInternal(f'Failed to fetch eks cluster {cluster_name}')
  cluster = cluster_resp.get('cluster')
  # Tags included already
  # tags_resp = proxy.list('list_tags_for_resource', resourceArn=cluster['arn'])
  # if tags_resp is not None:
  #   cluster['Tags'] = tags_resp[1]['tags']
  return cluster


def _import_nodegroup(proxy: ServiceProxy, cluster_name: str,
                      nodegroup_name: str) -> Dict[str, Any]:
  nodegroup_resp = proxy.get('describe_nodegroup', name=nodegroup_name)
  return nodegroup_resp.get('nodegroup')


def _import_nodegroups(
    proxy: ServiceProxy,
    cluster_name: str) -> Iterator[Tuple[str, Dict[str, Any]]]:
  nodegroups_resp = proxy.list('list_nodegroups', name=cluster_name)
  if nodegroups_resp is not None:
    nodegroup_names = nodegroups_resp[1].get('nodegroups', [])
    for nodegroup_name in nodegroup_names:
      yield 'Nodegroup', _import_nodegroup(proxy, cluster_name, nodegroup_name)


def _import_clusters(proxy: ServiceProxy, region: str):
  clusters_resp = proxy.list('list_clusters')
  if clusters_resp is not None:
    cluster_names = clusters_resp[1].get('clusters', [])
    for cluster_name in cluster_names:
      yield 'Cluster', _import_cluster(proxy, cluster_name)
      yield from _import_nodegroups(proxy, cluster_name)


def _import_eks_region(proxy: ServiceProxy,
                       region: str) -> Generator[Tuple[str, Any], None, None]:
  _log.info(f'importing eks clusters {region}')
  yield from _import_clusters(proxy, region)


SVC = RegionalService('eks', _import_eks_region)
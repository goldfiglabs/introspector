import logging
from typing import Any, Dict, Generator, Tuple

from goldfig.aws.fetch import ServiceProxy
from goldfig.aws.svc import make_import_to_db, make_import_with_pool
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


def _import_clusters(proxy: ServiceProxy, region: str):
  clusters_resp = proxy.list('list_clusters')
  if clusters_resp is not None:
    cluster_arns = clusters_resp[1].get('clusters', [])
    for cluster_arn in cluster_arns:
      yield 'Cluster', _import_cluster(proxy, cluster_arn)


def _import_eks_region(proxy: ServiceProxy,
                       region: str) -> Generator[Tuple[str, Any], None, None]:
  _log.info(f'importing eks clusters')
  yield from _import_clusters(proxy, region)


import_account_eks_region_to_db = make_import_to_db('eks', _import_eks_region)

import_account_eks_region_with_pool = make_import_with_pool(
    'eks', _import_eks_region)
from dis import dis
import logging
from typing import Any, Dict, Generator, Tuple

from goldfig.aws.fetch import ServiceProxy
from goldfig.aws.svc import make_import_to_db, make_import_with_pool

_log = logging.getLogger(__name__)


def _import_cluster(proxy: ServiceProxy, cluster: Dict) -> Dict[str, Any]:
  return cluster


def _import_clusters(proxy: ServiceProxy, region: str):
  clusters_resp = proxy.list('describe_clusters')
  if clusters_resp is not None:
    clusters = clusters_resp[1]['Clusters']
    for cluster in clusters:
      yield 'Cluster', _import_cluster(proxy, cluster)


def _import_redshift_region(
    proxy: ServiceProxy,
    region: str) -> Generator[Tuple[str, Any], None, None]:
  _log.info(f'importing Redshift Clusters')
  yield from _import_clusters(proxy, region)


import_account_redshift_region_to_db = make_import_to_db(
    'redshift', _import_redshift_region)

import_account_redshift_region_with_pool = make_import_with_pool(
    'redshift', _import_redshift_region)
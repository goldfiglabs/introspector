import logging
from typing import Any, Dict, Generator, Iterator, List, Tuple

from introspector.aws.fetch import ServiceProxy
from introspector.aws.svc import RegionalService, ServiceSpec, resource_gate

_log = logging.getLogger(__name__)


def _import_db_snapshots(
    proxy: ServiceProxy) -> Iterator[Tuple[str, Dict[str, Any]]]:
  snapshots_resp = proxy.list('describe_db_snapshots')
  if snapshots_resp is not None:
    snapshots = snapshots_resp[1].get('DBSnapshots', [])
    for snapshot in snapshots:
      snapshot_id = snapshot['DBSnapshotIdentifier']
      attrs_resp = proxy.get('describe_db_snapshot_attributes',
                             DBSnapshotIdentifier=snapshot_id)
      attrs = attrs_resp['DBSnapshotAttributesResult'].get(
          'DBSnapshotAttributes', [])
      for attr in attrs:
        snapshot[attr['AttributeName']] = attr['AttributeValues']
      yield 'DBSnapshot', snapshot


def _import_db_cluster_snapshots(
    proxy: ServiceProxy) -> Iterator[Tuple[str, Dict[str, Any]]]:
  snapshots_resp = proxy.list('describe_db_cluster_snapshots')
  if snapshots_resp is not None:
    snapshots = snapshots_resp[1].get('DBClusterSnapshots', [])
    for snapshot in snapshots:
      snapshot_id = snapshot['DBClusterSnapshotIdentifier']
      attrs_resp = proxy.get('describe_db_cluster_snapshot_attributes',
                             DBClusterSnapshotIdentifier=snapshot_id)
      attrs = attrs_resp['DBClusterSnapshotAttributesResult'].get(
          'DBClusterSnapshotAttributes', [])
      for attr in attrs:
        snapshot[attr['AttributeName']] = attr['AttributeValues']
      yield 'DBClusterSnapshot', snapshot


def _import_db_clusters(
    proxy: ServiceProxy) -> Iterator[Tuple[str, List[Dict[str, Any]]]]:
  clusters_resp = proxy.list('describe_db_clusters')
  if clusters_resp is not None:
    clusters = clusters_resp[1].get('DBClusters', [])
    yield 'DBClusters', clusters


def _import_db_instances(
    proxy: ServiceProxy) -> Iterator[Tuple[str, List[Dict[str, Any]]]]:
  instances_resp = proxy.list('describe_db_instances')
  if instances_resp is not None:
    instances = instances_resp[1].get('DBInstances', [])
    yield 'DBInstances', instances


def _import_rds_region(
    proxy: ServiceProxy, region: str,
    spec: ServiceSpec) -> Generator[Tuple[str, Any], None, None]:
  if resource_gate(spec, 'DBCluster'):
    yield from _import_db_clusters(proxy)
  if resource_gate(spec, 'DBInstance'):
    yield from _import_db_instances(proxy)
  if resource_gate(spec, 'DBSnapshot'):
    yield from _import_db_snapshots(proxy)
  if resource_gate(spec, 'DBClusterSnapshot'):
    yield from _import_db_cluster_snapshots(proxy)


SVC = RegionalService('rds', _import_rds_region)
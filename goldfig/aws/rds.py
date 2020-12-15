import logging
from typing import Any, Dict, Generator, Iterator, Tuple

from goldfig.aws.fetch import ServiceProxy
from goldfig.aws.svc import RegionalService

_log = logging.getLogger(__name__)

HAS_TAGS = {
    #'describe_db_instances': 'DBInstanceArn',
    #'describe_db_clusters': 'DBClusterArn',
    #'describe_db_snapshots': 'DBSnapshotArn'
}


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


def _import_rds_region(proxy: ServiceProxy,
                       region: str) -> Generator[Tuple[str, Any], None, None]:

  for resource in proxy.resource_names():
    _log.info(f'Importing {resource} {region}')
    result = proxy.list(resource)
    if result is not None:
      resource_name, wrapper = result
      items = wrapper.get(resource_name, [])
      arn_for_tags = HAS_TAGS.get(resource)
      if arn_for_tags is not None:
        for item in items:
          arn = item[arn_for_tags]
          tags_result = proxy.list('list_tags_for_resource', ResourceName=arn)
          if tags_result is not None:
            item['Tags'] = tags_result[1].get('TagList', [])
      yield resource_name, items
    _log.info(f'Done with {resource}')
  yield from _import_db_snapshots(proxy)
  yield from _import_db_cluster_snapshots(proxy)


SVC = RegionalService('rds', _import_rds_region)
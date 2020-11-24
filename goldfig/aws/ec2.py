import logging
from typing import Any, Dict, Generator, Iterator, List, Tuple

from goldfig import ImportWriter, PathStack
from goldfig.aws.fetch import Proxy, ServiceProxy
from goldfig.aws.svc import RegionalService

_log = logging.getLogger(__name__)


def _synthesize_defaults(proxy: ServiceProxy,
                         region: str) -> Iterator[Tuple[str, Any]]:
  defaults = {'name': 'Defaults', 'uri': f'ec2/defaults/{region}'}
  # TODO: update permissions
  # key_id_resp = proxy.get('get_ebs_default_kms_key_id')
  # defaults['EbsDefaultKmsKeyId'] = key_id_resp.get('KmsKeyId')
  encryption_resp = proxy.get('get_ebs_encryption_by_default')
  defaults['EbsEncryptionByDefault'] = encryption_resp[
      'EbsEncryptionByDefault']
  yield 'Defaults', defaults


def _add_user_data(proxy: ServiceProxy, response: Dict):
  reservations = response.get('Reservations', [])
  for reservation in reservations:
    instances = reservation.get('Instances', [])
    for instance in instances:
      instance_id = instance['InstanceId']
      user_data = proxy.get('describe_instance_attribute',
                            InstanceId=instance_id,
                            Attribute='userData')
      instance['UserData'] = user_data['UserData'].get('Value')


def _add_launch_permissions(proxy: ServiceProxy, response: Dict):
  snapshots = response.get('Snapshots', [])
  for snapshot in snapshots:
    snapshot_id = snapshot['SnapshotId']
    permission_resp = proxy.get('describe_snapshot_attribute',
                                SnapshotId=snapshot_id,
                                Attribute='createVolumePermission')
    permissions = permission_resp.get('CreateVolumePermissions', [])
    snapshot['CreateVolumePermissions'] = permissions


# TODO: add to transform for snapshots


def _import_ec2_region(proxy: ServiceProxy,
                       region: str) -> Generator[Tuple[str, Any], None, None]:
  for resource in proxy.resource_names():
    _log.info(f'importing {resource}')
    result = proxy.list(resource)
    if result is not None:
      if resource == 'describe_instances':
        _add_user_data(proxy, result[1])
      elif resource == 'describe_snapshots':
        _add_launch_permissions(proxy, result[1])
      yield result[0], result[1]
    _log.info(f'done with {resource}')
  yield from _synthesize_defaults(proxy, region)


SVC = RegionalService('ec2', _import_ec2_region)


def add_amis_to_import_job(proxy: Proxy, writer: ImportWriter, ps: PathStack,
                           region: str, amis: List[str]) -> str:
  ps = ps.scope(region)
  service_proxy = proxy.service('ec2', region)
  result = service_proxy.list(
      'describe_images',
      ImageIds=amis,
      # Remove the default filters
      Filters=[])
  _log.debug(f'describe images result {result}')
  if result is not None:
    resource_name = result[0]
    raw_resources = result[1]
    writer(ps, resource_name, raw_resources, {'region': region})
  return ps.path()

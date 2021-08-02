import logging
from typing import Any, Dict, Generator, Iterator, List, Tuple

import botocore.exceptions

from introspector import ImportWriter, PathStack
from introspector.aws.fetch import Proxy, ServiceProxy
from introspector.aws.svc import RegionalService, ServiceSpec, resource_gate

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


def _add_security_group_references(proxy: ServiceProxy, response: Dict):
  security_groups = response.get('SecurityGroups', [])
  for security_group in security_groups:
    group_id = security_group['GroupId']
    result = proxy.list('describe_security_group_references', GroupId=group_id)
    if result is not None:
      # everything is mutable, sigh...
      security_group['references'] = result[1].get('SecurityGroupReferenceSet',
                                                   [])


def _add_user_data(proxy: ServiceProxy, response: Dict):
  reservations = response.get('Reservations', [])
  for reservation in reservations:
    instances = reservation.get('Instances', [])
    for instance in instances:
      instance_id = instance['InstanceId']
      try:
        user_data = proxy.get('describe_instance_attribute',
                              InstanceId=instance_id,
                              Attribute='userData')
        if user_data is not None:
          instance['UserData'] = user_data.get('UserData', {}).get('Value')
      except botocore.exceptions.ClientError:
        pass


def _add_launch_permissions(proxy: ServiceProxy, response: Dict):
  snapshots = response.get('Snapshots', [])
  for snapshot in snapshots:
    snapshot_id = snapshot['SnapshotId']
    permission_resp = proxy.get('describe_snapshot_attribute',
                                SnapshotId=snapshot_id,
                                Attribute='createVolumePermission')
    permissions = permission_resp.get('CreateVolumePermissions', [])
    snapshot['CreateVolumePermissions'] = permissions


def _add_image_attributes(proxy: ServiceProxy, response: Dict[str, Any]):
  images = response.get('Images', [])
  for image in images:
    launch_permission = proxy.get('describe_image_attribute',
                                  Attribute='launchPermission',
                                  ImageId=image['ImageId'])
    if launch_permission is not None:
      image['LaunchPermissions'] = launch_permission.get(
          'LaunchPermissions', [])
    else:
      image['LaunchPermissions'] = []


RESOURCES = [
    'Addresses', 'FlowLogs', 'Images', 'Instances', 'KeyPairs',
    'NetworkInterfaces', 'RouteTables', 'SecurityGroups', 'Snapshots',
    'Subnets', 'Volumes', 'VpcPeeringConnections', 'Vpcs'
]


def _import_ec2_region(
    proxy: ServiceProxy, region: str,
    spec: ServiceSpec) -> Generator[Tuple[str, Any], None, None]:
  for resource in proxy.resource_names():
    _log.info(f'importing {resource}')
    op_name = proxy._impl._client._PY_TO_OP_NAME[resource]
    op_resource = op_name[len('Describe'):]
    if op_resource in RESOURCES:
      if resource_gate(spec, op_resource):
        result = proxy.list(resource)
        if result is not None:
          if resource == 'describe_instances':
            _add_user_data(proxy, result[1])
          elif resource == 'describe_snapshots':
            _add_launch_permissions(proxy, result[1])
          elif resource == 'describe_images':
            _add_image_attributes(proxy, result[1])
          elif resource == 'describe_security_groups':
            _add_security_group_references(proxy, result[1])
          yield result[0], result[1]
        _log.info(f'done with {resource}')
  if resource_gate(spec, 'Defaults'):
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
    # We can't add launch permissions here because we don't own the images
    #_add_image_attributes(service_proxy, raw_resources)
    writer(ps, resource_name, raw_resources, {'region': region})
  return ps.path()

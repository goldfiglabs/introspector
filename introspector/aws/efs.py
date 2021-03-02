import json
import logging
from typing import Any, Dict, Iterator, Tuple

from botocore.exceptions import ClientError

from introspector.aws.fetch import ServiceProxy
from introspector.aws.svc import RegionalService, ServiceSpec, resource_gate

_log = logging.getLogger(__name__)


def _import_file_system(proxy: ServiceProxy, file_system: Dict[str, Any]):
  file_system_id = file_system['FileSystemId']
  try:
    policy_resp = proxy.get('describe_file_system_policy', FileSystemId=file_system_id)
    if policy_resp is not None:
      file_system['Policy'] = json.loads(policy_resp['Policy'])
  except ClientError as e:
    code = e.response.get('Error', {}).get('Code')
    if code != 'AccessDeniedException' or 'PolicyNotFound':
      raise
  return file_system


def _import_filesystems(proxy: ServiceProxy) -> Iterator[Tuple[str, Any]]:
  file_systems_resp = proxy.list('describe_file_systems')
  if file_systems_resp is not None:
    file_systems_list = file_systems_resp[1]['FileSystems']
    for file_system in file_systems_list:
      yield 'FileSystem', _import_file_system(proxy, file_system)


def _import_efs_region(proxy: ServiceProxy, region: str,
                       spec: ServiceSpec) -> Iterator[Tuple[str, Any]]:
  _log.info(f'import efs in {region}')
  if resource_gate(spec, 'FileSystem'):
    yield from _import_filesystems(proxy)


SVC = RegionalService('efs', _import_efs_region)
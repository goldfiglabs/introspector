import json
import logging
from typing import Any, Dict, Generator, Tuple

import botocore.exceptions

from introspector.aws.fetch import ServiceProxy
from introspector.aws.svc import RegionalService, ServiceSpec, resource_gate

_log = logging.getLogger(__name__)


def _import_repository(proxy: ServiceProxy,
                       repository: Dict) -> Dict[str, Any]:
  arn = repository['repositoryArn']
  name = repository['repositoryName']
  registry = repository['registryId']
  try:
    tags_resp = proxy.list('list_tags_for_resource', resourceArn=arn)
    if tags_resp is not None:
      repository['Tags'] = tags_resp[1]['tags']
  except botocore.exceptions.ClientError as e:
    code = e.response.get('Error', {}).get('Code')
    if code == 'AccessDeniedException':
      repository['Tags'] = None
    else:
      raise
  try:
    policy_resp = proxy.get('get_repository_policy',
                            repositoryName=name,
                            registryId=registry)
    if policy_resp is not None:
      repository['Policy'] = json.loads(policy_resp['policyText'])
  except botocore.exceptions.ClientError as e:
    code = e.response.get('Error', {}).get('Code')
    if code == 'RepositoryPolicyNotFoundException':
      repository['Policy'] = None
    else:
      raise
  return repository


def _import_repositories(proxy: ServiceProxy):
  repositories_resp = proxy.list('describe_repositories')
  if repositories_resp is not None:
    repositories = repositories_resp[1]['repositories']
    for repository in repositories:
      yield 'Repository', _import_repository(proxy, repository)


def _import_ecr_region(
    proxy: ServiceProxy, region: str,
    spec: ServiceSpec) -> Generator[Tuple[str, Any], None, None]:
  _log.info(f'importing repositories {region}')
  if resource_gate(spec, 'Repository'):
    yield from _import_repositories(proxy)


SVC = RegionalService('ecr', _import_ecr_region)
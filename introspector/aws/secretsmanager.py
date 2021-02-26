import json
import logging
from typing import Any, Dict, Iterator, Tuple

from introspector.aws.fetch import ServiceProxy
from introspector.aws.svc import RegionalService, ServiceSpec, resource_gate

_log = logging.getLogger(__name__)


def _import_secret(proxy: ServiceProxy, secret: Dict[str, Any]):
  arn = secret['ARN']
  policy_resp = proxy.get('get_resource_policy', SecretId=arn)
  if policy_resp is not None:
    policy_text = policy_resp.get('ResourcePolicy')
    if policy_text is not None:
      secret['Policy'] = json.loads(policy_text)
  return secret


def _import_secrets(proxy: ServiceProxy) -> Iterator[Tuple[str, Any]]:
  secrets_resp = proxy.list('list_secrets')
  if secrets_resp is not None:
    secrets_list = secrets_resp[1]['SecretList']
    for secret in secrets_list:
      yield 'Secret', _import_secret(proxy, secret)


def _import_secretsmanager_region(proxy: ServiceProxy, region: str,
                       spec: ServiceSpec) -> Iterator[Tuple[str, Any]]:
  _log.info(f'import secretsmanager in {region}')
  if resource_gate(spec, 'Secret'):
    yield from _import_secrets(proxy)


SVC = RegionalService('secretsmanager', _import_secretsmanager_region)
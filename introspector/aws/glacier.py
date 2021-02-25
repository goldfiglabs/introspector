import json
import logging
from typing import Any, Dict, Iterator, Tuple

from botocore.exceptions import ClientError

from introspector.aws.fetch import ServiceProxy
from introspector.aws.svc import RegionalService, ServiceSpec, resource_gate

_log = logging.getLogger(__name__)


def _import_vault(proxy: ServiceProxy, vault: Dict[str, Any]):
  vault_name = vault['VaultName']
  policy_resp = proxy.get('get_vault_access_policy', vaultName=vault_name, accountId='-')
  if policy_resp is not None:
    policy_text = policy_resp.get('policy', {}).get('Policy')
    if policy_text is not None:
      vault['Policy'] = json.loads(policy_text)
  tags_resp = proxy.get('list_tags_for_vault', vaultName=vault_name, accountId='-')
  if tags_resp is not None:
    vault['Tags'] = tags_resp['Tags']
  return vault


def _import_vaults(proxy: ServiceProxy) -> Iterator[Tuple[str, Any]]:
  vaults_resp = proxy.list('list_vaults', accountId='-')
  if vaults_resp is not None:
    vault_list = vaults_resp[1]['VaultList']
    for vault in vault_list:
      yield 'Vault', _import_vault(proxy, vault)


def _import_glacier_region(proxy: ServiceProxy, region: str,
                       spec: ServiceSpec) -> Iterator[Tuple[str, Any]]:
  _log.info(f'import glacier in {region}')
  if resource_gate(spec, 'Vault'):
    yield from _import_vaults(proxy)


SVC = RegionalService('glacier', _import_glacier_region)
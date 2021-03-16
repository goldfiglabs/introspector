import json
import logging
from typing import Any, Dict, Iterator, Tuple

from introspector.aws.fetch import ServiceProxy
from introspector.aws.svc import RegionalService, ServiceSpec, resource_gate

_log = logging.getLogger(__name__)


def _import_certificate_authority(proxy: ServiceProxy,
                                  certificate_authority: Dict[str, Any]):
  arn = certificate_authority['Arn']
  policy_resp = proxy.get('get_policy', ResourceArn=arn)
  if policy_resp is not None:
    certificate_authority['Policy'] = json.loads(policy_resp['Policy'])
  tags_resp = proxy.get('list_tags', CertificateAuthorityArn=arn)
  if tags_resp is not None:
    certificate_authority['Tags'] = tags_resp['Tags']
  return certificate_authority


def _import_certificate_authorities(
    proxy: ServiceProxy) -> Iterator[Tuple[str, Any]]:
  certificate_authorities_resp = proxy.list('list_certificate_authorities')
  if certificate_authorities_resp is not None:
    certificate_authorities = certificate_authorities_resp[1].get(
        'CertificateAuthorities', [])
    for certificate_authority in certificate_authorities:
      yield 'CertificateAuthority', _import_certificate_authority(
          proxy, certificate_authority)


def _import_acm_pca_region(proxy: ServiceProxy, region: str,
                           spec: ServiceSpec) -> Iterator[Tuple[str, Any]]:
  _log.info(f'import acm-pca in {region}')
  if resource_gate(spec, 'CertificateAuthority'):
    yield from _import_certificate_authorities(proxy)


SVC = RegionalService('acm-pca', _import_acm_pca_region)
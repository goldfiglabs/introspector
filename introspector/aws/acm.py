import logging
from typing import Any, Dict, Generator, Tuple

from introspector.aws.fetch import ServiceProxy
from introspector.aws.svc import RegionalService, ServiceSpec, resource_gate

_log = logging.getLogger(__name__)


def _import_certificate(proxy: ServiceProxy, summary: Dict) -> Dict[str, Any]:
  arn = summary['CertificateArn']
  certificate = proxy.get('describe_certificate',
                          CertificateArn=arn)['Certificate']
  tags_resp = proxy.list('list_tags_for_certificate', CertificateArn=arn)
  if tags_resp is not None:
    certificate['Tags'] = tags_resp[1]['Tags']
  return certificate


def _import_certificates(proxy: ServiceProxy):
  certificates_resp = proxy.list('list_certificates')
  if certificates_resp is not None:
    certificates = certificates_resp[1]['CertificateSummaryList']
    for certificate in certificates:
      yield 'Certificate', _import_certificate(proxy, certificate)


def _import_acm_region(
    proxy: ServiceProxy, region: str,
    spec: ServiceSpec) -> Generator[Tuple[str, Any], None, None]:
  _log.info(f'importing Certificates {region}')
  if resource_gate(spec, 'Certificate'):
    yield from _import_certificates(proxy)


SVC = RegionalService('acm', _import_acm_region)
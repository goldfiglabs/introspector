from dis import dis
import logging
from typing import Any, Dict, Generator, Tuple

from goldfig.aws.fetch import ServiceProxy
from goldfig.aws.svc import make_import_to_db, make_import_with_pool

_log = logging.getLogger(__name__)


def _import_certificate(proxy: ServiceProxy, summary: Dict) -> Dict[str, Any]:
  arn = summary['CertificateArn']
  certificate = proxy.get('describe_certificate',
                          CertificateArn=arn)['Certificate']
  tags_resp = proxy.list('list_tags_for_certificate', CertificateArn=arn)
  if tags_resp is not None:
    certificate['Tags'] = tags_resp[1]['Tags']
  return certificate


def _import_certificates(proxy: ServiceProxy, region: str):
  certificates_resp = proxy.list('list_certificates')
  if certificates_resp is not None:
    certificates = certificates_resp[1]['CertificateSummaryList']
    for certificate in certificates:
      yield 'Certificate', _import_certificate(proxy, certificate)


def _import_acm_region(proxy: ServiceProxy,
                       region: str) -> Generator[Tuple[str, Any], None, None]:
  _log.info(f'importing Certificates')
  yield from _import_certificates(proxy, region)


import_account_acm_region_to_db = make_import_to_db('acm', _import_acm_region)

import_account_acm_region_with_pool = make_import_with_pool(
    'acm', _import_acm_region)
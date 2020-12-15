import json
import logging
from typing import Any, Dict, Generator, Tuple

from goldfig.aws.fetch import ServiceProxy
from goldfig.aws.svc import RegionalService
from goldfig.error import GFNoAccess

_log = logging.getLogger(__name__)


def _import_domain(proxy: ServiceProxy, domain_name: str) -> Dict[str, Any]:
  domain_resp = proxy.get('describe_elasticsearch_domain',
                          DomainName=domain_name)
  if domain_resp is None:
    raise GFNoAccess('es', 'describe_elasticsearch_domain')
  domain = domain_resp['DomainStatus']
  domain['AccessPolicies'] = json.loads(domain.get('AccessPolicies', 'null'))
  tags_resp = proxy.get('list_tags', ARN=domain['ARN'])
  if tags_resp is not None:
    domain['Tags'] = tags_resp['TagList']
  return domain


def _import_domains(proxy: ServiceProxy, region: str):
  domain_names_resp = proxy.list('list_domain_names')
  if domain_names_resp is not None:
    domain_infos = domain_names_resp[1].get('DomainNames', [])
    for domain_info in domain_infos:
      yield 'Domain', _import_domain(proxy, domain_info['DomainName'])


def _import_es_region(proxy: ServiceProxy,
                      region: str) -> Generator[Tuple[str, Any], None, None]:
  _log.info(f'importing es domains in {region}')
  yield from _import_domains(proxy, region)


SVC = RegionalService('es', _import_es_region)

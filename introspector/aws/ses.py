import logging
from typing import Any, Dict, Generator, Tuple

from introspector.aws.fetch import ServiceProxy
from introspector.aws.svc import RegionalService, ServiceSpec, resource_gate

_log = logging.getLogger(__name__)


def _import_identity(proxy: ServiceProxy, identity_name: str) -> Dict:
  identity: Dict[str, Any] = {'id': identity_name}
  identities = [identity_name]
  dkim_resp = proxy.get('get_identity_dkim_attributes', Identities=identities)
  dkim_attrs = dkim_resp.get('DkimAttributes', {}).get(identity_name, {})
  identity.update(dkim_attrs)

  # TODO: Missing permissions
  # mail_resp = proxy.get('get_identity_mail_from_domain_atttributes', Identities=identities)
  # mail_attrs = mail_resp.get('MailFromDomainAttributes', {}).get(identity_name, {})
  # identity.update(mail_attrs)

  # notifications_resp = proxy.get('get_identity_notification_attributes', Identities=identities)
  # notification_attrs = notifications_resp.get('NotificationAttributes', {}).get(identity_name, {})
  # identity.update(notification_attrs)

  verification_resp = proxy.get('get_identity_verification_attributes',
                                Identities=identities)
  verification_attrs = verification_resp.get('VerificationAttributes',
                                             {}).get(identity_name, {})
  identity.update(verification_attrs)

  policies_list_resp = proxy.get('list_identity_policies',
                                 Identity=identity_name)
  policy_names = policies_list_resp.get('PolicyNames', [])
  policies = {}
  for i in range(0, len(policy_names), 20):
    names = policy_names[i:i + 20]
    policy_resp = proxy.get('get_identity_policies',
                            Identity=identity_name,
                            PolicyNames=names)
    policies.update(policy_resp.get('Policies', {}))
  identity['Policies'] = policies
  return identity


def _import_identities(proxy: ServiceProxy, region: str):
  identities_resp = proxy.list('list_identities')
  if identities_resp is not None:
    identities = identities_resp[1]['Identities']
    for identity in identities:
      yield 'Identity', _import_identity(proxy, identity)


def _import_ses_region(
    proxy: ServiceProxy, region: str,
    spec: ServiceSpec) -> Generator[Tuple[str, Any], None, None]:
  if resource_gate(spec, 'Identity'):
    _log.info(f'importing identities {region}')
    yield from _import_identities(proxy, region)


SVC = RegionalService('ses', _import_ses_region)
import logging
from typing import Any, Callable, Dict, Generator, List, Optional, Tuple

from botocore.parsers import parse_timestamp
import botocore.session as boto
from dateutil.tz import tzutc
from sqlalchemy.orm import Session

from goldfig.aws.fetch import Proxy
from goldfig.error import GFInternal
from goldfig.models import ImportJob, ProviderAccount, ProviderCredential

ProxyBuilder = Callable[[boto.Session], Proxy]
_log = logging.getLogger(__name__)


def make_proxy_builder(use_cache: bool = False,
                       patch_id: Optional[int] = None) -> ProxyBuilder:
  def _fn(boto: boto.Session) -> Proxy:
    if use_cache:
      return Proxy.build(boto, patch_id=patch_id)
    else:
      return Proxy.dummy(boto)

  return _fn


def _parse_timestamp(value) -> str:
  d = parse_timestamp(value).astimezone(tzutc())
  return d.isoformat()


def _patch_boto(session: boto.Session):
  parser_factory = session.get_component('response_parser_factory')
  parser_factory.set_parser_defaults(timestamp_parser=_parse_timestamp)


def get_boto_session() -> boto.Session:
  session = boto.get_session()
  _patch_boto(session)
  return session


def create_provider_and_credential(db: Session, proxy: Proxy,
                                   identity) -> ProviderAccount:
  org = proxy.service('organizations')
  org_resp = org.get('describe_organization')['Organization']
  org_id = org_resp['Id']
  provider = ProviderAccount(provider='aws', name=org_id)
  db.add(provider)
  db.flush()
  credential = ProviderCredential(scope=identity['Account'],
                                  principal_uri=identity['Arn'],
                                  config={'from_environment': True})
  credential.provider_id = provider.id
  db.add(credential)
  return provider


def walk_graph(org, graph) -> Generator[Tuple[str, str, Dict], None, None]:
  yield '', 'Organization', org
  ou_paths = graph['organizational_units']
  accounts = graph['accounts']
  for path, entries in ou_paths.items():
    for entry in entries:
      if path == '':
        entry_path = entry['Id']
        typ = 'Root'
      else:
        entry_path = f'{path}/{entry["Id"]}'
        typ = 'OrganizationalUnit'
      yield entry_path, typ, entry
      accounts_at_path = accounts.get(entry_path, [])
      for account in accounts_at_path:
        # No accounts at empty path, only the root is there
        yield f'{entry_path}/{account["Id"]}', 'Account', account


def load_boto_for_provider(db: Session,
                           provider: ProviderAccount) -> boto.Session:
  accounts = ProviderCredential.for_provider(db, provider.id)
  if len(accounts) != 1:
    raise NotImplementedError(
        'Currently only one AWS account per org is supported')
  account = accounts[0]
  return load_boto_session(account)


def build_aws_import_job(session: boto.Session,
                         proxy_builder: ProxyBuilder) -> Dict:
  proxy = proxy_builder(session)
  org, graph = _build_org_graph(proxy)
  sts = session.create_client('sts')
  identity = sts.get_caller_identity()
  return {
      'account': {
          'account_id': org['Id'],
          'provider': 'aws'
      },
      'principal': {
          'provider_id': identity['UserId'],
          'provider_uri': identity['Arn']
      },
      'aws_org': org,
      'aws_graph': graph
  }


def _require_resp(tup: Optional[Tuple[str, Dict[str, Any]]]) -> Dict[str, Any]:
  if tup is None:
    raise GFInternal(f'Missing response')
  else:
    return tup[1]


def _build_org_graph(proxy: Proxy):
  org = proxy.service('organizations')
  org_resp = org.get('describe_organization')['Organization']
  roots_resp = _require_resp(org.list('list_roots'))
  roots = roots_resp['Roots']
  accounts = {}
  organizational_units = {}

  def build_graph(parent_id: str, path: List[str]):
    accounts_resp = _require_resp(
        org.list('list_accounts_for_parent', ParentId=parent_id))
    next_path = [*path, parent_id]
    path_str = '/'.join(next_path)
    accounts[path_str] = accounts_resp['Accounts']
    organizational_units_resp = _require_resp(
        org.list('list_organizational_units_for_parent', ParentId=parent_id))
    ous = organizational_units_resp['OrganizationalUnits']
    if len(ous) > 0:
      organizational_units[path_str] = ous
      for ou in ous:
        build_graph(parent_id=ou['Id'], path=next_path)

  organizational_units[''] = roots
  for root in roots:
    build_graph(root['Id'], [])
  return org_resp, {
      'accounts': accounts,
      'organizational_units': organizational_units
  }


def load_boto_session_from_config(config: Dict[str, Any]) -> boto.Session:
  if config.get('from_environment', False):
    session = boto.get_session()
  else:
    access_key = config['access_key']
    secret_key = config['secret_key']
    session = boto.Session()
    session.set_credentials(access_key, secret_key)
  _patch_boto(session)
  return session


def load_boto_session(provider_credential: ProviderCredential) -> boto.Session:
  config = provider_credential.config
  return load_boto_session_from_config(config)


def account_paths_for_import(
    db: Session,
    import_job: ImportJob) -> List[Tuple[str, ProviderCredential]]:
  creds = db.query(ProviderCredential).filter(
      ProviderCredential.provider_id == import_job.provider_account_id).all()

  def find_credential(account_id: str) -> ProviderCredential:
    return next(cred for cred in creds if cred.scope == account_id)

  account_paths = import_job.aws_config.graph.accounts
  results = []
  for path, accounts in account_paths.items():
    for account in accounts:
      try:
        cred = find_credential(account.id)
        results.append((f'{path}/{cred.scope}', cred))
      except StopIteration:
        # If we don't have credentials, don't import it
        _log.info(f'Skipping account id {account.id}, no credentials')
        continue
  return results

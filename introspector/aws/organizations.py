import concurrent.futures as f
from typing import Dict, List, Tuple

from sqlalchemy.orm.session import Session

from introspector import ImportWriter, db_import_writer, PathStack
from introspector.aws import load_boto_session, walk_graph, account_paths_for_import
from introspector.aws.fetch import Proxy
from introspector.aws.svc import GlobalService, GlobalResourceSpec, GlobalPoolImportFn, GlobalDbImportFn, ServiceSpec, resource_gate
from introspector.bootstrap_db import import_session
from introspector.error import GFInternal
from introspector.models import ImportJob, ProviderCredential


class _AccountProxies:
  def __init__(self, credentials: List[ProviderCredential],
               master_account_arn: str):
    self._credentials = credentials
    self._master_account_arn = master_account_arn
    self._cache: Dict[str, Proxy] = {}

  def master_account_proxy(self):
    return self.account_proxy(self._master_account_arn)

  def account_proxy(self, arn: str) -> Proxy:
    cached = self._cache.get(arn)
    if cached is None:
      cached = self._make_proxy(arn)
    return cached

  def _make_proxy(self, arn: str) -> Proxy:
    creds = self.credentials_for_arn(arn)
    boto = load_boto_session(creds)
    proxy = Proxy.build(boto)
    self._cache[arn] = proxy
    return proxy

  def credentials_for_arn(self, arn: str) -> ProviderCredential:
    account_id = arn.split(':')[-1].split('/')[-1]
    return next(cred for cred in self._credentials if cred.scope == account_id)


def _import_organization(ps: PathStack, writer: ImportWriter,
                         organization: Dict):
  writer(ps, 'Organization', organization)


def _import_account(proxy: Proxy, master_account_proxy: Proxy, ps: PathStack,
                    writer: ImportWriter, account: Dict,
                    is_master_account: bool):
  if is_master_account:
    organizations = proxy.service('organizations')
    service_policies = organizations.list(
        'list_policies_for_target',
        TargetId=account['Id'],
        Filter='SERVICE_CONTROL_POLICY')[1]['Policies']
    account['ServiceControlPolicies'] = service_policies
    tag_policies = organizations.list('list_policies_for_target',
                                      TargetId=account['Id'],
                                      Filter='TAG_POLICY')[1]['Policies']
    account['TagPolicies'] = tag_policies
  organizations = master_account_proxy.service('organizations')
  tags = organizations.list('list_tags_for_resource',
                            ResourceId=account['Id'])[1]['Tags']
  account['Tags'] = tags
  writer(ps, 'Account', account)


def _import_root(proxy: Proxy, ps: PathStack, writer: ImportWriter,
                 root: Dict):
  organizations = proxy.service('organizations')
  service_policies = organizations.list(
      'list_policies_for_target',
      TargetId=root['Id'],
      Filter='SERVICE_CONTROL_POLICY')[1]['Policies']
  root['ServiceControlPolicies'] = service_policies
  tag_policies = organizations.list('list_policies_for_target',
                                    TargetId=root['Id'],
                                    Filter='TAG_POLICY')[1]['Policies']
  root['TagPolicies'] = tag_policies
  writer(ps, 'Root', root)


def _import_organizational_unit(proxy: Proxy, ps: PathStack,
                                writer: ImportWriter, ou: Dict):
  organizations = proxy.service('organizations')
  service_policies = organizations.list(
      'list_policies_for_target',
      TargetId=ou['Id'],
      Filter='SERVICE_CONTROL_POLICY')[1]['Policies']
  ou['ServiceControlPolicies'] = service_policies
  tag_policies = organizations.list('list_policies_for_target',
                                    TargetId=ou['Id'],
                                    Filter='TAG_POLICY')[1]['Policies']
  ou['TagPolicies'] = tag_policies
  writer(ps, 'OrganizationalUnit', ou)


def _import_graph(import_job: ImportJob, writer: ImportWriter,
                  account_credentials: List[ProviderCredential],
                  spec: ServiceSpec) -> List[f.Future]:
  config = import_job.configuration
  org = config['aws_org']
  is_mocked = org['Id'].startswith('OrgDummy')
  master_account_arn = org['MasterAccountArn']
  proxies = _AccountProxies(account_credentials, master_account_arn)
  ps = PathStack.from_import_job(import_job)
  results = []
  for path, typ, entry in walk_graph(org, config['aws_graph']):
    if is_mocked:
      writer(ps, typ, entry)
    elif typ == 'Organization':
      if resource_gate(spec, 'Organization'):
        _import_organization(ps, writer, entry)
    elif typ == 'Root':
      if resource_gate(spec, 'Root'):
        _import_root(proxies.master_account_proxy(), ps.scope(path), writer,
                     entry)
    elif typ == 'OrganizationalUnit':
      if resource_gate(spec, 'OrganizationalUnit'):
        _import_organizational_unit(proxies.master_account_proxy(),
                                    ps.scope(path), writer, entry)
    elif typ == 'Account':
      if resource_gate(spec, 'Account'):
        is_master_account = entry['Arn'] == master_account_arn
        proxy = proxies.master_account_proxy()
        _import_account(proxy, proxy, ps.scope(path), writer, entry,
                        is_master_account)
    else:
      raise GFInternal(f'Unknown AWS graph type {typ}')
  return results


def _async_proxy(import_job_id: int, svc_name: str, spec: ServiceSpec):
  db = import_session()
  import_job = db.query(ImportJob).get(import_job_id)
  if import_job is None:
    raise GFInternal('Lost ImportJob')
  writer = db_import_writer(db,
                            import_job_id,
                            import_job.provider_account_id,
                            svc_name,
                            phase=0,
                            source='base')
  accounts = list(map(lambda t: t[1], account_paths_for_import(db,
                                                               import_job)))
  _import_graph(import_job, writer, accounts, spec)
  db.commit()


class OrgImport(GlobalService):
  def __init__(self):
    super().__init__('organizations', [])

  def _make_global_import_with_pool(
      self, _: List[GlobalResourceSpec]) -> GlobalPoolImportFn:
    def import_with_pool(
        pool: f.ProcessPoolExecutor, import_job_id: int,
        provider_account_id: int, _: PathStack,
        __: List[Tuple[str, ProviderCredential]], spec: ServiceSpec) -> List[f.Future]:
      future = pool.submit(_async_proxy,
                           import_job_id=import_job_id,
                           svc_name=self.name, spec=spec)
      return [future]

    return import_with_pool

  def _make_global_import_to_db(
      self, _: List[GlobalResourceSpec]) -> GlobalDbImportFn:
    def import_to_db(db: Session, import_job_id: int, spec: ServiceSpec):
      job = db.query(ImportJob).get(import_job_id)
      if job is None:
        raise GFInternal('Lost ImportJob')
      writer = db_import_writer(db,
                                job.id,
                                job.provider_account_id,
                                self.name,
                                phase=0,
                                source='base')
      accounts = list(map(lambda t: t[1], account_paths_for_import(db, job)))
      _import_graph(job, writer, accounts, spec)

    return import_to_db


SVC = OrgImport()
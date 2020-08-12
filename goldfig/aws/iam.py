import concurrent.futures as f
import csv
from functools import partial
from io import StringIO
import time
from typing import Any, Callable, Dict, List, Optional, Tuple

from botocore.exceptions import ClientError
from sqlalchemy.orm import Session

from goldfig import ImportWriter, db_import_writer, PathStack
from goldfig.aws import load_boto_session, load_boto_session_from_config, account_paths_for_import, ProxyBuilder, make_proxy_builder, walk_graph
from goldfig.aws.fetch import Proxy, ServiceProxy
from goldfig.bootstrap_db import import_session
from goldfig.delta.resource import apply_mapped_attrs
from goldfig.error import GFError, GFInternal
from goldfig.models import ImportJob, ProviderCredential

_USER_ATTRS = {
    'AttachedPolicies': 'list_attached_user_policies',
    #  'Tags': 'list_user_tags', # Duplicate
    'AccessKeys': {
        'op': 'list_access_keys',
        'key': 'AccessKeyMetadata'
    },
    'Groups': 'list_groups_for_user',
    'MFADevices': 'list_mfa_devices',
    'SSHPublicKeys': 'list_ssh_public_keys',
    'ServiceSpecificCredentials': 'list_service_specific_credentials',
    'Certificates': 'list_signing_certificates'
}


def _import_password_policy(proxy: ServiceProxy, ps: PathStack,
                            writer: ImportWriter, account_id: str):
  result = proxy.get('get_account_password_policy')
  if result is not None:
    writer(ps, 'PasswordPolicy', result['PasswordPolicy'],
           {'account_id': account_id})


def _unpack(tup: Optional[Tuple[str, Dict]]) -> Dict:
  if tup is None:
    return {}
  else:
    return tup[1]


def _post_process_report_row(row: Dict[str, str]) -> Dict[str, Any]:
  result = {}
  for key, value in row.items():
    if value == 'true' or value == 'True':
      result[key] = True
    elif value == 'false' or value == 'False':
      result[key] = False
    elif value == 'N/A' or value.lower() == 'no_information':
      result[key] = None
    else:
      result[key] = value
  return result


def _import_credential_report(proxy: ServiceProxy, ps: PathStack,
                              writer: ImportWriter):
  writer = writer.for_source('credentialreport')
  # Kick off the report
  try:
    proxy.get('generate_credential_report')
  except ClientError as e:
    is_throttled = e.response.get('Error', {}).get('Code') == 'Throttling'
    # If we're throttled, we've at least kicked it off already
    if not is_throttled:
      raise
  attempts = 0
  report = None
  while attempts < 20 and report is None:
    try:
      report = proxy.get('get_credential_report')
    except:
      attempts += 1
      time.sleep(0.05)
  if report is None:
    raise GFError('Failed to fetch credential report')
  decoded = report['Content'].decode('utf-8')
  reader = csv.DictReader(StringIO(decoded))
  for row in reader:
    processed = _post_process_report_row(row)
    writer(ps, 'CredentialReport', processed)


def _import_users(proxy: ServiceProxy, ps: PathStack, writer: ImportWriter):
  users = _unpack(proxy.list('list_users'))
  for user in users['Users']:
    user_data = user.copy()
    name = user_data['UserName']
    for attr, op_desc in _USER_ATTRS.items():
      if isinstance(op_desc, str):
        op = op_desc
        field = attr
      else:
        op = op_desc['op']
        field = op_desc['key']
      op_result = proxy.list(op, UserName=name)
      if op_result is not None:
        user_data[attr] = op_result[1][field]
    user_data['PolicyList'] = _fetch_inline_policies(proxy, 'user', name)
    login_profile = proxy.get('get_login_profile', UserName=name)
    if login_profile is not None:
      login_profile = login_profile['LoginProfile']
    user_data['LoginProfile'] = login_profile
    writer(ps, 'user', user_data)


_GROUP_ATTRS = {'AttachedPolicies': 'list_attached_group_policies'}


def _import_groups(proxy: ServiceProxy, ps: PathStack, writer: ImportWriter):
  groups = _unpack(proxy.list('list_groups'))
  for group in groups.get('Groups'):
    group_data = group.copy()
    name = group_data['GroupName']
    for attr, op in _GROUP_ATTRS.items():
      op_result = proxy.list(op, GroupName=name)
      if op_result is not None:
        group_data[attr] = op_result[1][attr]
    group_data['PolicyList'] = _fetch_inline_policies(proxy, 'group', name)
    writer(ps, 'group', group_data)


def _import_policies(proxy: ServiceProxy, ps: PathStack, writer: ImportWriter):
  results = proxy.list('list_policies', Scope='Local')
  if results is not None:
    policies = results[1]
    for policy in policies['Policies']:
      policy_data = policy.copy()
      arn = policy_data['Arn']
      versions_result = _unpack(
          proxy.list('list_policy_versions', PolicyArn=arn))
      versions = []
      for version in versions_result.get('Versions', []):
        full_version = proxy.get('get_policy_version',
                                 PolicyArn=arn,
                                 VersionId=version['VersionId'])
        versions.append(full_version['PolicyVersion'])
      policy_data['Versions'] = versions

      op_result = proxy.list('list_entities_for_policy', PolicyArn=arn)
      if op_result is not None:
        for attr in ['PolicyGroups', 'PolicyUsers', 'PolicyRoles']:
          policy_data[attr] = op_result[1][attr]
      writer(ps, 'policy', policy_data)
  # TODO: fix this cut + paste
  aws_policies = proxy.list('list_policies', Scope='AWS', OnlyAttached=True)
  if aws_policies is not None:
    policies = aws_policies[1]
    for policy in policies['Policies']:
      policy_data = policy.copy()
      arn = policy_data['Arn']
      versions_result = _unpack(
          proxy.list('list_policy_versions', PolicyArn=arn))
      versions = []
      for version in versions_result.get('Versions', []):
        full_version = proxy.get('get_policy_version',
                                 PolicyArn=arn,
                                 VersionId=version['VersionId'])
        versions.append(full_version['PolicyVersion'])
      policy_data['Versions'] = versions
      op_result = proxy.list('list_entities_for_policy', PolicyArn=arn)
      if op_result is not None:
        for attr in ['PolicyGroups', 'PolicyUsers', 'PolicyRoles']:
          policy_data[attr] = op_result[1][attr]
      writer(ps, 'policy', policy_data)


def _import_instance_profiles(proxy: ServiceProxy, ps: PathStack,
                              writer: ImportWriter):
  profiles = _unpack(proxy.list('list_instance_profiles'))
  for profile in profiles['InstanceProfiles']:
    writer(ps, 'instance-profile', profile)


def _fetch_inline_policies(proxy: ServiceProxy, principal: str, name: str):
  kwargs = {f'{principal.capitalize()}Name': name}
  op = f'list_{principal}_policies'
  policies = _unpack(proxy.list(op, **kwargs))
  policy_op = f'get_{principal}_policy'
  results = []
  for policy_name in policies.get('PolicyNames', []):
    result = proxy.get(policy_op, PolicyName=policy_name, **kwargs)
    if result is None:
      raise GFInternal(
          f'Missing inline policy {policy_name} for {principal} {name}')
    results.append({
        'PolicyName': result['PolicyName'],
        'PolicyDocument': result['PolicyDocument']
    })
  return results


_ROLE_ATTRS = {
    'AttachedPolicies': 'list_attached_role_policies',
    'Tags': 'list_role_tags',
}


def _import_roles(proxy: ServiceProxy, ps: PathStack, writer: ImportWriter):
  roles = _unpack(proxy.list('list_roles'))
  for role in roles['Roles']:
    role_data = role.copy()
    name = role_data['RoleName']
    for attr, op in _ROLE_ATTRS.items():
      op_result = _unpack(proxy.list(op, RoleName=name))
      role_data[attr] = op_result.get(attr)
    role_data['PolicyList'] = _fetch_inline_policies(proxy, 'role', name)
    writer(ps, 'role', role_data)


_ACCOUNT_ATTRS: Dict[str, str] = {
    # TODO: these should probably be resources
    # 'AccountAliases': 'list_account_aliases',
    # 'OpenIDConnectProviderList': 'list_open_id_connect_providers',
    # 'SAMLProviderList': 'list_saml_providers',
    # 'ServerCertificateMetadataList': 'list_server_certificates',
    # 'VirtualMFADevices': 'list_virtual_mfa_devices',
}


def _import_account(proxy: Proxy, master_account_proxy: Proxy, ps: PathStack,
                    writer: ImportWriter, account: Dict,
                    is_master_account: bool):
  if is_master_account:
    iam = proxy.service('iam')
    for attr, op in _ACCOUNT_ATTRS.items():
      result = iam.list(op)
      if result is not None:
        account[attr] = result[1][attr]
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


def _import_organization(ps: PathStack, writer: ImportWriter,
                         organization: Dict):
  writer(ps, 'Organization', organization)


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


class _AccountProxies:
  def __init__(self, credentials: List[ProviderCredential],
               master_account_arn: str, proxy_builder: ProxyBuilder):
    self._proxy_builder = proxy_builder
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
    proxy = self._proxy_builder(boto)
    self._cache[arn] = proxy
    return proxy

  def credentials_for_arn(self, arn: str) -> ProviderCredential:
    account_id = arn.split(':')[-1].split('/')[-1]
    return next(cred for cred in self._credentials if cred.scope == account_id)


def _import_graph(
    proxy_builder: ProxyBuilder, import_job: ImportJob, writer: ImportWriter,
    account_credentials: List[ProviderCredential],
    import_iam_fn: Callable[[PathStack, ProviderCredential], List[f.Future]]
) -> List[f.Future]:
  config = import_job.configuration
  org = config['aws_org']
  master_account_arn = org['MasterAccountArn']
  proxies = _AccountProxies(account_credentials, master_account_arn,
                            proxy_builder)
  ps = PathStack.from_import_job(import_job)
  results = []
  for path, typ, entry in walk_graph(org, config['aws_graph']):
    if typ == 'Organization':
      _import_organization(ps, writer, entry)
    elif typ == 'Root':
      _import_root(proxies.master_account_proxy(), ps.scope(path), writer,
                   entry)
    elif typ == 'OrganizationalUnit':
      _import_organizational_unit(proxies.master_account_proxy(),
                                  ps.scope(path), writer, entry)
    elif typ == 'Account':
      is_master_account = entry['Arn'] == master_account_arn
      proxy = proxies.master_account_proxy()
      _import_account(proxy, proxy, ps.scope(path), writer, entry,
                      is_master_account)
      if is_master_account:
        results += import_iam_fn(ps.scope(path),
                                 proxies.credentials_for_arn(entry['Arn']))
    else:
      raise GFInternal(f'Unknown AWS graph type {typ}')
  return results


def _import_iam(iam: ServiceProxy, writer: ImportWriter, ps: PathStack,
                account_id: str):
  _import_credential_report(iam, ps, writer)
  _import_users(iam, ps, writer)
  _import_groups(iam, ps, writer)
  _import_policies(iam, ps, writer)
  _import_roles(iam, ps, writer)
  _import_instance_profiles(iam, ps, writer)
  _import_password_policy(iam, ps, writer, account_id)


def _async_proxy(ps: PathStack, proxy_builder_args, import_job_id: int,
                 config: Dict, f):
  db = import_session()
  proxy_builder = make_proxy_builder(*proxy_builder_args)
  boto = load_boto_session_from_config(config)
  proxy = proxy_builder(boto)
  writer = db_import_writer(db, import_job_id, 'iam', phase=0, source='base')
  service_proxy = proxy.service('iam')
  f(service_proxy, ps, writer)
  db.commit()


def _import_account_iam_with_pool(ps: PathStack, account: ProviderCredential,
                                  pool: f.ProcessPoolExecutor,
                                  proxy_builder_args, import_job_id):
  results: List[f.Future] = []

  def queue_job(fn):
    return pool.submit(_async_proxy,
                       ps=ps,
                       proxy_builder_args=proxy_builder_args,
                       import_job_id=import_job_id,
                       config=account.config,
                       f=fn)

  results = [
      queue_job(f)
      for f in (_import_credential_report, _import_roles, _import_users,
                _import_groups, _import_policies, _import_instance_profiles,
                partial(_import_password_policy, account_id=account.scope))
  ]
  return results


def import_account_iam_with_pool(
    pool: f.ProcessPoolExecutor, proxy_builder_args, import_job_id: int,
    ps: PathStack, account_paths: List[Tuple[str, ProviderCredential]]):
  def import_iam_fn(ps: PathStack, credential: ProviderCredential):
    return _import_account_iam_with_pool(ps, credential, pool,
                                         proxy_builder_args, import_job_id)

  proxy_builder = make_proxy_builder(*proxy_builder_args)
  db = import_session()
  writer = db_import_writer(db,
                            import_job_id,
                            'organizations',
                            phase=0,
                            source='base')
  import_job: ImportJob = db.query(ImportJob).get(import_job_id)
  accounts = list(map(lambda i: i[1], account_paths))
  results = _import_graph(proxy_builder, import_job, writer, accounts,
                          import_iam_fn)
  db.commit()
  return results


def import_account_iam_to_db(db: Session, import_job_id: int,
                             proxy_builder: ProxyBuilder):
  job: ImportJob = db.query(ImportJob).get(import_job_id)
  account_paths = account_paths_for_import(db, job)
  # drop the paths, we don't need them here
  accounts = list(map(lambda i: i[1], account_paths))
  writer = db_import_writer(db,
                            job.id,
                            'organizations',
                            phase=0,
                            source='base')

  def import_iam_fn(ps: PathStack, credential: ProviderCredential):
    boto = load_boto_session(credential)
    proxy = proxy_builder(boto)
    iam = proxy.service('iam')
    _import_iam(iam, writer, ps, credential.scope)
    return []

  _import_graph(proxy_builder, job, writer, accounts, import_iam_fn)


def synthesize_account_root(db: Session, import_job: ImportJob, path: str,
                            account_id: str):
  arn = f'arn:aws:iam::{account_id}:root'
  mapped = {
      'name': '<root account>',
      'uri': arn,
      'provider_type': 'RootAccount',
      'raw': {
          'Arn': arn
      },
      'service': 'iam'
  }
  attrs = [{'type': 'provider', 'name': 'Arn', 'value': arn}]
  apply_mapped_attrs(db,
                     import_job,
                     path,
                     mapped,
                     attrs,
                     source='base',
                     raw_import_id=None)

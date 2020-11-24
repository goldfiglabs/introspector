import csv
from goldfig import ImportWriter
from io import StringIO
import logging
import time
from typing import Any, Dict, Optional, Tuple

from botocore.exceptions import ClientError, SSLError
from sqlalchemy.orm import Session

from goldfig.aws.fetch import Proxy, ServiceProxy
from goldfig.aws.svc import GlobalService, GlobalResourceSpec

from goldfig.delta.resource import apply_mapped_attrs
from goldfig.error import GFError, GFInternal
from goldfig.models import ImportJob

_log = logging.getLogger(__name__)

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


def _import_password_policy(proxy: ServiceProxy):
  result = proxy.get('get_account_password_policy')
  if result is not None:
    yield 'PasswordPolicy', result['PasswordPolicy']


def _unpack(tup: Optional[Tuple[str, Dict]]) -> Dict:
  if tup is None:
    return {}
  else:
    return tup[1]


def _post_process_report_row(row: Dict[str, str]) -> Dict[str, Any]:
  result: Dict[str, Any] = {}
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


def _import_credential_report(proxy: ServiceProxy):
  #writer = writer.for_source('credentialreport')
  # Kick off the report
  started = False
  init_attempts = 0
  while not started:
    try:
      proxy.get('generate_credential_report')
      started = True
    except ClientError as e:
      is_throttled = e.response.get('Error', {}).get('Code') == 'Throttling'
      # If we're throttled, we've at least kicked it off already
      _log.error('credential report error', exc_info=e)
      if not is_throttled:
        raise
      else:
        started = True
    except SSLError:
      # wait and try again?
      init_attempts += 1
      if init_attempts >= 3:
        raise GFError('Failed to generate credential report, SSL Error')
      time.sleep(0.1)
  attempts = 0
  report = None
  while attempts < 20 and report is None:
    try:
      report = proxy.get('get_credential_report')
    except:
      attempts += 1
      time.sleep(0.1)
  if report is None:
    raise GFError('Failed to fetch credential report')
  decoded = report['Content'].decode('utf-8')
  reader = csv.DictReader(StringIO(decoded))
  for row in reader:
    processed = _post_process_report_row(row)
    #writer(ps, 'CredentialReport', processed)
    yield 'CredentialReport', processed


def _import_users(proxy: ServiceProxy):
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
    yield 'user', user_data


_GROUP_ATTRS = {'AttachedPolicies': 'list_attached_group_policies'}


def _import_groups(proxy: ServiceProxy):
  groups = _unpack(proxy.list('list_groups'))
  for group in groups.get('Groups'):
    group_data = group.copy()
    name = group_data['GroupName']
    for attr, op in _GROUP_ATTRS.items():
      op_result = proxy.list(op, GroupName=name)
      if op_result is not None:
        group_data[attr] = op_result[1][attr]
    group_data['PolicyList'] = _fetch_inline_policies(proxy, 'group', name)
    yield 'group', group_data


def _import_policies(proxy: ServiceProxy):
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
      yield 'policy', policy_data
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
      yield 'policy', policy_data


def _import_instance_profiles(proxy: ServiceProxy):
  profiles = _unpack(proxy.list('list_instance_profiles'))
  for profile in profiles['InstanceProfiles']:
    yield 'instance-profile', profile


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


def _import_roles(proxy: ServiceProxy):
  roles = _unpack(proxy.list('list_roles'))
  for role in roles['Roles']:
    role_data = proxy.get('get_role', RoleName=role['RoleName'])['Role']
    name = role_data['RoleName']
    for attr, op in _ROLE_ATTRS.items():
      op_result = _unpack(proxy.list(op, RoleName=name))
      role_data[attr] = op_result.get(attr)
    role_data['PolicyList'] = _fetch_inline_policies(proxy, 'role', name)
    yield 'role', role_data


def _credential_report_writer(writer: ImportWriter) -> ImportWriter:
  return writer.for_source('credentialreport')


SVC = GlobalService('iam', [
    GlobalResourceSpec(fn=_import_credential_report,
                       writer_transform=_credential_report_writer),
    _import_users, _import_groups, _import_policies, _import_roles,
    _import_instance_profiles, _import_password_policy
])


def synthesize_account_root(proxy: Proxy, db: Session, import_job: ImportJob,
                            path: str, account_id: str):
  service_proxy = proxy.service('iam')
  mfa_resp = service_proxy.list('list_virtual_mfa_devices')
  has_virtual_mfa = False
  if mfa_resp is not None:
    root_mfa_arn = f'arn:aws:iam::{account_id}:mfa/root-account-mfa-device'
    mfas = mfa_resp[1]['VirtualMFADevices']
    for mfa in mfas:
      if mfa['SerialNumber'] == root_mfa_arn:
        has_virtual_mfa = True
        break

  arn = f'arn:aws:iam::{account_id}:root'
  mapped = {
      'name': '<root account>',
      'uri': arn,
      'provider_type': 'RootAccount',
      'raw': {
          'Arn': arn,
          'has_virtual_mfa': has_virtual_mfa
      },
      'service': 'iam'
  }
  attrs = [{
      'type': 'provider',
      'name': 'Arn',
      'value': arn
  }, {
      'type': 'provider',
      'name': 'has_virtual_mfa',
      'value': has_virtual_mfa
  }]
  apply_mapped_attrs(db,
                     import_job,
                     path,
                     mapped,
                     attrs,
                     source='base',
                     raw_import_id=None)

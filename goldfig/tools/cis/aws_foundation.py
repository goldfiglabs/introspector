import sys
from typing import Any, List

from colr import color
from sqlalchemy.orm import Session

from goldfig.models.provider_account import ProviderAccount


class Foundation:
  def run_query(self, db: Session, provider_account_id: int) -> List[Any]:
    results = db.execute(self._sql(),
                         {'provider_account_id': provider_account_id})
    return results.fetchall()

  def run(self, db: Session, provider_account_id: int) -> bool:
    sys.stdout.write(color(self.__doc__, fore='cyan', style='bright') + '... ')
    results = self.run_query(db, provider_account_id)
    if len(results) == 0:
      sys.stdout.write(color('PASS\n', fore='green', style='bright'))
      return True

    sys.stdout.write(color('FAIL\n', fore='red', style='bright'))
    for row in results:
      print('\t' + self._contextualize_failure(row))
    return False

  def _sql(self) -> str:
    raise NotImplementedError('Base class')

  def _contextualize_failure(self, row: Any) -> str:
    raise NotImplementedError('Base class')


class MFAForConsoleUser(Foundation):
  '''Benchmark 1.2'''
  def _sql(self) -> str:
    return '''
      SELECT
        username,
        uri
      FROM
        aws_iam_user
      WHERE
        loginprofile IS NOT NULL
        AND jsonb_array_length(mfadevices) = 0
        AND provider_account_id = :provider_account_id
    '''

  def _contextualize_failure(self, row: Any) -> str:
    username = row['username']
    uri = row['uri']
    return f'User {username} ({uri}) does not have multi-factor auth enabled'


class RotatePasswordsAfter90Days(Foundation):
  '''Benchmark 1.3'''
  def _sql(self):
    return '''
      SELECT
        uri,
        (password_enabled = True AND
          (passwordlastused IS NULL AND age(password_last_changed) > interval '90 days')
          OR (age(passwordlastused) > interval '90 days' )
        ) AS password_violation,
        (
          access_key_1_active = True AND
          age(access_key_1_last_used_date) > interval '90 days'
        ) AS access_key_1_violation,
        (
          access_key_2_active = True AND
          age(access_key_2_last_used_date) > interval '90 days'
        ) AS access_key_2_violation
      FROM
        aws_iam_user
      WHERE
        provider_account_id = :provider_account_id
        AND (
          (password_enabled = True AND
            (passwordlastused IS NULL AND age(password_last_changed) > interval '90 days')
            OR (age(passwordlastused) > interval '90 days' )
          )
          OR
          (
            access_key_1_active = True AND
            age(access_key_1_last_used_date) > interval '90 days'
          )
          OR
          (
            access_key_2_active = True AND
            age(access_key_2_last_used_date) > interval '90 days'
          )
        )
    '''

  def _contextualize_failure(self, row: Any) -> str:
    uri = row['uri']
    lines = []
    if row['password_violation']:
      lines.append('current password has not been used in the last 90 days')
    if row['access_key_1_violation']:
      lines.append(
          'access_key_1 is stale and has not been used in the last 90 days')
    if row['access_key_2_violation']:
      lines.append(
          'access_key_2 is stale and has not been used in the last 90 days')
    return f'Credentials for {uri}: ' + ', '.join(lines)


class RotateAccessKeysAfter90Days(Foundation):
  '''Benchmark 1.4'''
  def _sql(self) -> str:
    return '''
      SELECT
        uri,
        (
          access_key_1_active = True AND
          age(access_key_1_last_rotated) > interval '90 days'
        ) AS access_key_1_violation,
        (
          access_key_2_active = True AND
          age(access_key_2_last_rotated) > interval '90 days'
        ) AS access_key_2_violation
      FROM
        aws_iam_user
      WHERE
        provider_account_id = :provider_account_id
        AND (
          (
            access_key_1_active = True AND
            age(access_key_1_last_rotated) > interval '90 days'
          )
          OR
          (
            access_key_2_active = True AND
            age(access_key_2_last_rotated) > interval '90 days'
          )
        )
    '''

  def _contextualize_failure(self, row: Any) -> str:
    uri = row['uri']
    lines = []
    if row['access_key_1_violation']:
      lines.append('access_key_1 has not been rotated in 90 days')
    if row['access_key_2_violation']:
      lines.append('access_key_2 has not been rotated in 90 days')
    return f'Access keys for {uri}: ' + ', '.join(lines)


class RequireUpperCaseInPassword(Foundation):
  '''Benchmark 1.5'''
  def _sql(self) -> str:
    return '''
      SELECT
        Account.uri,
        Account.id
      FROM
        aws_organizations_account AS Account
        LEFT JOIN aws_iam_passwordpolicy AS Policy
          ON Policy.uri = Account.id || '/PasswordPolicy'
      WHERE
        Account.provider_account_id = :provider_account_id
        AND NOT COALESCE(Policy.RequireUppercaseCharacters, False)
    '''

  def _contextualize_failure(self, row: Any) -> str:
    uri = row['uri']
    account_id = row['id']
    return f'Account {account_id} ({uri}) does not have a policy requiring an upper case character in passwords'


class RequireLowerCaseInPassword(Foundation):
  '''Benchmark 1.6'''
  def _sql(self) -> str:
    return '''
      SELECT
        Account.uri,
        Account.id
      FROM
        aws_organizations_account AS Account
        LEFT JOIN aws_iam_passwordpolicy AS Policy
          ON Policy.uri = Account.id || '/PasswordPolicy'
      WHERE
        Account.provider_account_id = :provider_account_id
        AND NOT COALESCE(Policy.RequireLowercaseCharacters, False)
    '''

  def _contextualize_failure(self, row: Any) -> str:
    uri = row['uri']
    account_id = row['id']
    return f'Account {account_id} ({uri}) does not have a policy requiring a lower case character in passwords'


class RequireSymbolInPassword(Foundation):
  '''Benchmark 1.7'''
  def _sql(self) -> str:
    return '''
      SELECT
        Account.uri,
        Account.id
      FROM
        aws_organizations_account AS Account
        LEFT JOIN aws_iam_passwordpolicy AS Policy
          ON Policy.uri = Account.id || '/PasswordPolicy'
      WHERE
        Account.provider_account_id = :provider_account_id
        AND NOT COALESCE(Policy.RequireSymbols, False)
    '''

  def _contextualize_failure(self, row: Any) -> str:
    uri = row['uri']
    account_id = row['id']
    return f'Account {account_id} ({uri}) does not have a policy requiring a symbol character in passwords'


class RequireNumberInPassword(Foundation):
  '''Benchmark 1.8'''
  def _sql(self) -> str:
    return '''
      SELECT
        Account.uri,
        Account.id
      FROM
        aws_organizations_account AS Account
        LEFT JOIN aws_iam_passwordpolicy AS Policy
          ON Policy.uri = Account.id || '/PasswordPolicy'
      WHERE
        Account.provider_account_id = :provider_account_id
        AND NOT COALESCE(Policy.RequireNumbers, False)
    '''

  def _contextualize_failure(self, row: Any) -> str:
    uri = row['uri']
    account_id = row['id']
    return f'Account {account_id} ({uri}) does not have a policy requiring a number in passwords'


class RequireMinimumLengthPasssword(Foundation):
  '''Benchmark 1.9'''
  def _sql(self) -> str:
    return '''
      SELECT
        Account.uri,
        Account.id
      FROM
        aws_organizations_account AS Account
        LEFT JOIN aws_iam_passwordpolicy AS Policy
          ON Policy.uri = Account.id || '/PasswordPolicy'
      WHERE
        Account.provider_account_id = :provider_account_id
        AND COALESCE(Policy.minimumpasswordlength, 0) < 14
      '''

  def _contextualize_failure(self, row: Any) -> str:
    uri = row['uri']
    account_id = row['id']
    return f'Account {account_id} ({uri}) does not have a policy requiring a minimum password length of at least 14'


class RequireNewPassswords(Foundation):
  '''Benchmark 1.10'''
  def _sql(self) -> str:
    return '''
      SELECT
        Account.uri,
        Account.id
      FROM
        aws_organizations_account AS Account
        LEFT JOIN aws_iam_passwordpolicy AS Policy
          ON Policy.uri = Account.id || '/PasswordPolicy'
      WHERE
        Account.provider_account_id = :provider_account_id
        AND COALESCE(Policy.passwordreuseprevention, 0) < 24
      '''

  def _contextualize_failure(self, row: Any) -> str:
    uri = row['uri']
    account_id = row['id']
    return f'Account {account_id} ({uri}) does not have a policy requiring passwords the most recent 24 passwords not be reused'


class RequireMaximumAgePassswords(Foundation):
  '''Benchmark 1.11'''
  def _sql(self) -> str:
    return '''
      SELECT
        Account.uri,
        Account.id
      FROM
        aws_organizations_account AS Account
        LEFT JOIN aws_iam_passwordpolicy AS Policy
          ON Policy.uri = Account.id || '/PasswordPolicy'
      WHERE
        Account.provider_account_id = :provider_account_id
        AND COALESCE(Policy.maxpasswordage, 0) < 90
      '''

  def _contextualize_failure(self, row: Any) -> str:
    uri = row['uri']
    account_id = row['id']
    return f'Account {account_id} ({uri}) does not have a policy requiring passwords be changed every 90 days'


class NoRootAccessKeys(Foundation):
  '''Benchmark 1.12'''
  def _sql(self) -> str:
    return '''
      SELECT
        uri
      FROM
        aws_iam_rootaccount
      WHERE
        provider_account_id = :provider_account_id
        AND (
          access_key_1_active = True
          OR access_key_2_active = True
        )
    '''

  def _contextualize_failure(self, row: Any) -> str:
    uri = row['uri']
    return f'Root Account {uri} has an active access key'


class RootAccountHasMFA(Foundation):
  '''Benchmark 1.13'''
  def _sql(self) -> str:
    return '''
      SELECT
        uri
      FROM
        aws_iam_rootaccount
      WHERE
        mfa_active = False
        AND provider_account_id = :provider_account_id
    '''

  def _contextualize_failure(self, row: Any) -> str:
    uri = row['uri']
    return f'Root Account {uri} does not have multi factor auth enabled'


class NoPoliciesAttachedToUsers(Foundation):
  '''Benchmark 1.16'''
  def _sql(self) -> str:
    return '''
      WITH attached_policies AS (
        SELECT
          U.resource_id,
          ARRAY_AGG(Policy.uri) AS policies
        FROM
          aws_iam_user AS U
          LEFT JOIN resource_relation AS Targeted
            ON Targeted.target_id = U.resource_id
            AND Targeted.relation = 'manages'
          INNER JOIN aws_iam_policy AS Policy
            ON Targeted.resource_id = Policy.resource_id
        WHERE
          U.provider_account_id = :provider_account_id
        GROUP BY U.resource_id
      ), inline_policies AS (
        SELECT
          U.resource_id,
          ARRAY_AGG(Policy.uri) AS policies
        FROM
          aws_iam_user AS U
          LEFT JOIN resource_relation AS Targeted
            ON Targeted.target_id = U.resource_id
            AND Targeted.relation = 'manages'
          INNER JOIN aws_iam_userpolicy AS Policy
            ON Targeted.resource_id = Policy.resource_id
        WHERE
          U.provider_account_id = :provider_account_id
        GROUP BY U.resource_id
      )
      SELECT
        U.uri,
        COALESCE(attached.policies, '{}') AS attached_policies,
        COALESCE(inline.policies, '{}') AS inline_policies
      FROM
        aws_iam_user AS U
        LEFT JOIN attached_policies AS attached
          ON U.resource_id = attached.resource_id
        LEFT JOIN inline_policies AS inline
          ON U.resource_id = inline.resource_id
      WHERE
        ARRAY_LENGTH(attached.policies, 1) > 0
        OR ARRAY_LENGTH(inline.policies, 1) > 0
    '''

  def _contextualize_failure(self, row: Any) -> str:
    uri = row['uri']
    attached = row['attached_policies']
    inline = row['inline_policies']
    lines = []
    if len(attached) > 0:
      lines.append('Attached: ' + ', '.join(attached))
    if len(inline) > 0:
      lines.append('Inline: ' + ', '.join(inline))
    return f'User {uri} has policies directly attached or inline, rather than via role or group: ' + ', '.join(
        lines)


class SupportPolicyExists(Foundation):
  '''Benchmark 1.20'''
  def _sql(self) -> str:
    return '''
      WITH user_support AS (
        SELECT
          U.uri
        FROM
          aws_iam_policy AS Policy
          LEFT JOIN resource_relation AS Manages
            ON Policy.resource_id = Manages.resource_id
            AND Manages.relation = 'manages'
          INNER JOIN aws_iam_user AS U
            ON U.resource_id = Manages.target_id
        WHERE
          Policy.uri = 'arn:aws:iam::aws:policy/AWSSupportAccess'
          AND U.provider_account_id = :provider_account_id
      ), group_support AS (
          SELECT
          G.uri
        FROM
          aws_iam_policy AS Policy
          LEFT JOIN resource_relation AS Manages
            ON Policy.resource_id = Manages.resource_id
            AND Manages.relation = 'manages'
          INNER JOIN aws_iam_group AS G
            ON G.resource_id = Manages.target_id
        WHERE
          Policy.uri = 'arn:aws:iam::aws:policy/AWSSupportAccess'
          AND G.provider_account_id = :provider_account_id
      ), role_support AS (
        SELECT
          Role.uri
        FROM
          aws_iam_policy AS Policy
          LEFT JOIN resource_relation AS Manages
            ON Policy.resource_id = Manages.resource_id
            AND Manages.relation = 'manages'
          INNER JOIN aws_iam_role AS Role
            ON Role.resource_id = Manages.target_id
        WHERE
          Policy.uri = 'arn:aws:iam::aws:policy/AWSSupportAccess'
          AND Role.provider_account_id = :provider_account_id
      )
      SELECT
        total
      FROM
        (SELECT
          support_role.cnt + support_group.cnt + support_user.cnt AS total
        FROM
          (
            SELECT
              COUNT(*) AS cnt
            FROM
              role_support
          ) AS support_role,
          (
            SELECT
              COUNT(*) AS cnt
            FROM
              user_support
          ) as support_user,
          (
            SELECT
              COUNT(*) AS cnt
            FROM
              group_support
          ) as support_group
        ) AS totals
      WHERE total = 0
    '''

  def _contextualize_failure(self, row: Any) -> str:
    return 'Account is missing a user, role, or group with the AWSSupportAccess role'


class NoAutoCreatedAccessKeys(Foundation):
  '''Benchmark 1.21'''
  def _sql(self) -> str:
    return '''
      WITH access_keys AS (
        SELECT
          uri,
          loginprofile IS NOT NULL AS has_login,
          key ->> 'AccessKeyId' as KeyId,
          key ->> 'Status' AS status,
          (to_timestamp(key->>'CreateDate'::text, 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00' - createdate) as delta
        FROM
          aws_iam_user
          CROSS JOIN LATERAL jsonb_array_elements(accesskeys) AS key
        WHERE
          provider_account_id = :provider_account_id
      )
      SELECT
        uri,
        keyId
      FROM
        access_keys
      WHERE
        delta < interval '2 minutes'
        AND status = 'Active'
        AND has_login
    '''

  def _contextualize_failure(self, row: Any) -> str:
    uri = row['uri']
    key_id = row['keyid']
    return f'User {uri} has an auto-creaded access key {key_id}'


class NoAdminAccess(Foundation):
  '''Benchmark 1.22'''
  def _sql(self) -> str:
    return '''
    WITH policies AS (
      SELECT
        resource_id,
        uri || ':' || defaultversionid AS version_uri
      FROM
        aws_iam_policy
      WHERE
        provider_account_id = :provider_account_id
    ), policy_documents AS (
      SELECT
        P.resource_id,
        P.version_uri,
        PV.document::jsonb AS document
      FROM
        policies AS P
        LEFT JOIN aws_iam_policyversion AS PV
          ON PV.uri = P.version_uri
    )
    SELECT
      PD.version_uri,
      s.value,
      Manages.target_id,
      R.uri AS role_uri,
      G.uri AS group_uri,
      U.uri AS user_uri
    FROM
      policy_documents AS PD
      CROSS JOIN LATERAL jsonb_array_elements(PD.document->'Statement') AS s
      LEFT JOIN resource_relation AS Manages
        ON Manages.resource_id = PD.resource_id
        AND Manages.relation = 'manages'
      LEFT JOIN aws_iam_role AS R
        ON R.resource_id = Manages.target_id
      LEFT JOIN aws_iam_user AS U
        ON U.resource_id = Manages.target_id
      LEFT JOIN aws_iam_group AS G
        ON G.resource_id = Manages.target_id
    WHERE
      s.value ->> 'Effect' = 'Allow'
      AND s.value -> 'Resource' ? '*'
      AND s.value -> 'Action' ? '*'
    '''

  def _contextualize_failure(self, row: Any) -> str:
    entities = [
        row[attr] for attr in ('role_uri', 'group_uri', 'user_uri')
        if row[attr] is not None
    ]
    policy_uri = row['version_uri']
    return f'Policy {policy_uri} allows admin access to these entities: ' + ', '.join(
        entities)


class NoSSHFromEverywhere(Foundation):
  '''Benchmark 4.1'''
  def _sql(self) -> str:
    return '''
      SELECT
        SG.uri
      FROM
        aws_ec2_securitygroup AS SG
        CROSS JOIN LATERAL jsonb_array_elements(SG.ippermissions) AS IPP
        CROSS JOIN LATERAL jsonb_array_elements(IPP->'IpRanges') AS R
      WHERE
        (IPP.value ->> 'ToPort')::integer = 22
        AND (R.value->>'CidrIp')::inet = inet '0.0.0.0/0'
        AND SG.provider_account_id = :provider_account_id
    '''

  def _contextualize_failure(self, row: Any) -> str:
    uri = row['uri']
    return f'Security Group {uri} allows SSH access from anywhere'


class NoRDPFromEverywhere(Foundation):
  '''Benchmark 4.2'''
  def _sql(self) -> str:
    return '''
      SELECT
        SG.uri
      FROM
        aws_ec2_securitygroup AS SG
        CROSS JOIN LATERAL jsonb_array_elements(SG.ippermissions) AS IPP
        CROSS JOIN LATERAL jsonb_array_elements(IPP->'IpRanges') AS R
      WHERE
        (IPP.value ->> 'ToPort')::integer = 3389
        AND (R.value->>'CidrIp')::inet = inet '0.0.0.0/0'
        AND SG.provider_account_id = :provider_account_id
    '''

  def _contextualize_failure(self, row: Any) -> str:
    uri = row['uri']
    return f'Security Group {uri} allows Remote Desktop access from anywhere'


class DefaultSecurityGroupAllowsNothing(Foundation):
  '''Benchmark 4.3'''
  def _sql(self) -> str:
    return '''
      SELECT
        VPC.uri AS vpc,
        SG.uri AS security_group,
        Perms.value -> 'IpRanges' AS allowed_ip_ranges
      FROM
        aws_ec2_vpc AS VPC
        LEFT JOIN aws_ec2_securitygroup AS SG
          ON SG._vpc_id = VPC.resource_id
        CROSS JOIN LATERAL jsonb_array_elements(SG.ippermissions) AS Perms
      WHERE
        VPC.provider_account_id = :provider_account_id
        AND SG.groupname = 'default'
        AND jsonb_array_length(Perms.value -> 'IpRanges') > 0
    '''

  def _contextualize_failure(self, row: Any) -> str:
    sg = row['security_group']
    vpc = row['vpc']
    ip_ranges = row['ip_ranges']
    return f'Default Security Group ({sg}) for VPC {vpc} allows connections from {ip_ranges}'


def run(db: Session, provider_account: ProviderAccount):
  # 1
  MFAForConsoleUser().run(db, provider_account.id)
  RotatePasswordsAfter90Days().run(db, provider_account.id)
  RotateAccessKeysAfter90Days().run(db, provider_account.id)
  RequireUpperCaseInPassword().run(db, provider_account.id)
  RequireLowerCaseInPassword().run(db, provider_account.id)
  RequireSymbolInPassword().run(db, provider_account.id)
  RequireNumberInPassword().run(db, provider_account.id)
  RequireMinimumLengthPasssword().run(db, provider_account.id)
  RequireNewPassswords().run(db, provider_account.id)
  RequireMaximumAgePassswords().run(db, provider_account.id)
  NoRootAccessKeys().run(db, provider_account.id)
  RootAccountHasMFA().run(db, provider_account.id)
  NoPoliciesAttachedToUsers().run(db, provider_account.id)
  SupportPolicyExists().run(db, provider_account.id)
  NoAutoCreatedAccessKeys().run(db, provider_account.id)
  NoAdminAccess().run(db, provider_account.id)
  # 4
  NoSSHFromEverywhere().run(db, provider_account.id)
  NoRDPFromEverywhere().run(db, provider_account.id)
  DefaultSecurityGroupAllowsNothing().run(db, provider_account.id)
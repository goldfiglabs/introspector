from dataclasses import dataclass
from enum import Enum, auto
import sys
from typing import Any, Dict, List, Optional

from colr import color
from sqlalchemy.orm import Session

from goldfig.models.provider_account import ProviderAccount


class Status(Enum):
  INFO = auto()
  PASS = auto()
  FAIL = auto()

  def color_args(self) -> Dict[str, str]:
    if self == Status.INFO:
      fore = 'cyan'
      style = 'bright'
    elif self == Status.PASS:
      fore = 'green'
      style = 'bright'
    elif self == Status.FAIL:
      fore = 'red'
      style = 'bright'
    else:
      raise ValueError(f'Unknown status {self}')
    return {'fore': fore, 'style': style}


@dataclass
class Result:
  benchmark: str
  severity: str
  status: Status
  summary: str
  region: str
  notes: Optional[str] = None


@dataclass
class QueryResult:
  status: Status
  region: str
  notes: Optional[str] = None


def console_writer(result: Result):
  pass


def csv_writer(result: Result):
  pass


class Foundation:
  benchmark: str
  severity: str
  summary: str

  def run_query(self, db: Session, provider_account_id: int) -> List[Any]:
    results = db.execute(self._sql(),
                         {'provider_account_id': provider_account_id})
    return results.fetchall()

  def _sql(self) -> str:
    raise NotImplementedError('Base class')

  def _rows_to_query_result(self, rows: List[Any]) -> QueryResult:
    raise NotImplementedError('TODO')

  def run_check(self, db: Session, provider_account_id: int) -> Result:
    rows = self.run_query(db, provider_account_id)
    query_result = self._rows_to_query_result(rows)
    return Result(benchmark=self.benchmark,
                  severity=self.severity,
                  status=query_result.status,
                  summary=self.summary,
                  region=query_result.region,
                  notes=query_result.notes)


class Info(Foundation):
  def run(self, db: Session, provider_account_id: int):
    sys.stdout.write(color(self.__doc__, fore='cyan', style='bright') + '... ')
    results = self.run_query(db, provider_account_id)
    sys.stdout.write(color('INFO\n', fore='yellow', style='bright'))
    print('\t' + self._contextualize_results(results))

  # def run_check(self, db: Session, provider_account_id: int) -> Result:
  #   #sys.stdout.write(color(self.__doc__, fore='cyan', style='bright') + '... ')
  #   results = self.run_query(db, provider_account_id)
  #   #sys.stdout.write(color('INFO\n', fore='yellow', style='bright'))
  #   #print('\t' + self._contextualize_results(results))
  #   return Result(self.benchmark, self.severity, Status.INFO, self.summary,
  #                 results.region, results.notes)

  def _rows_to_query_result(self, rows: List[Any]) -> QueryResult:
    return QueryResult(status=Status.INFO,
                       region='*',
                       notes=self._contextualize_results(rows))

  def _contextualize_results(self, rows: List[Any]) -> str:
    return '\n\t'.join([self._contextualize_result(row) for row in rows])

  def _contextualize_result(self, row: Any) -> str:
    raise NotImplementedError('Base class')


class Check(Foundation):
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

  def _contextualize_failure(self, row: Any) -> str:
    raise NotImplementedError('Base class')


class RootAccountUsage(Info):
  '''Benchmark 1.1'''

  benchmark = '1.1'
  severity = 'high'
  region = 'global'

  def _sql(self) -> str:
    return f'''
      SELECT
        uri,
        age(password_last_used) AS last_login
      FROM
        aws_iam_rootaccount
      WHERE
        provider_account_id = :provider_account_id
    '''

  def _contextualize_result(self, row: Any) -> str:
    last_login = row['last_login']
    uri = row['uri']
    return f'Last login for {uri} was {last_login} ago'


class MFAForConsoleUser(Check):
  '''Benchmark 1.2'''
  benchmark = '1.2'
  severity = 'high'
  region = 'global'

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


class RotatePasswordsAfter90Days(Check):
  '''Benchmark 1.3'''
  benchmark = '1.3'
  severity = 'high'
  region = 'global'

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


class RotateAccessKeysAfter90Days(Check):
  '''Benchmark 1.4'''
  benchmark = '1.4'
  severity = 'medium'
  region = 'global'

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


class RequireUpperCaseInPassword(Check):
  '''Benchmark 1.5'''
  benchmark = '1.5'
  severity = 'low'
  region = 'global'

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


class RequireLowerCaseInPassword(Check):
  '''Benchmark 1.6'''
  benchmark = '1.6'
  severity = 'low'
  region = 'global'

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


class RequireSymbolInPassword(Check):
  '''Benchmark 1.7'''
  benchmark = '1.7'
  severity = 'low'
  region = 'global'

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


class RequireNumberInPassword(Check):
  '''Benchmark 1.8'''
  benchmark = '1.8'
  severity = 'low'
  region = 'global'

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


class RequireMinimumLengthPasssword(Check):
  '''Benchmark 1.9'''
  benchmark = '1.9'
  severity = 'low'
  region = 'global'

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


class RequireNewPassswords(Check):
  '''Benchmark 1.10'''
  benchmark = '1.10'
  severity = 'low'
  region = 'global'

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


class RequireMaximumAgePassswords(Check):
  '''Benchmark 1.11'''
  benchmark = '1.11'
  severity = 'low'
  region = 'global'

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


class NoRootAccessKeys(Check):
  '''Benchmark 1.12'''
  benchmark = '1.12'
  severity = 'high'
  region = 'global'

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


class RootAccountHasMFA(Check):
  '''Benchmark 1.13'''
  benchmark = '1.13'
  severity = 'low'
  region = 'global'

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


class RootAccountHasHardwareMFA(Check):
  '''Benchmark 1.14'''
  benchmark = '1.14'
  severity = 'low'
  region = 'global'

  def _sql(self) -> str:
    return '''
      SELECT
        uri
      FROM
        aws_iam_rootaccount
      WHERE
        provider_account_id = :provider_account_id
        AND mfa_active = True
        AND has_virtual_mfa = True
    '''

  def _contextualize_failure(self, row: Any) -> str:
    uri = row['uri']
    return f'Root account {uri} has MFA enabled, but is using a virtual device instead of a hardware token'


class SecurityQuestionsRegistered(Info):
  '''Benchmark 1.15'''
  benchmark = '1.15'
  severity = 'low'
  region = 'global'

  def _sql(self) -> str:
    return '''SELECT 1'''

  def _contextualize_results(self, rows: List[Any]) -> str:
    return 'Ensure that security questions are registered for the root account in the AWS Console under "My Account"'


class NoPoliciesAttachedToUsers(Check):
  '''Benchmark 1.16'''
  benchmark = '1.16'
  severity = 'low'
  region = 'global'

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


class ContactInfoUpToDate(Info):
  '''Benchmark 1.17'''
  benchmark = '1.17'
  severity = 'low'
  region = 'global'

  def _sql(self) -> str:
    return '''SELECT 1'''

  def _contextualize_results(self, rows: List[Any]) -> str:
    return 'Ensure that contact information for the root account in the AWS Console under "My Account" is up-to-date'


class SecurityContactInfoUpToDate(Info):
  '''Benchmark 1.18'''
  benchmark = '1.18'
  severity = 'low'
  region = 'global'

  def _sql(self) -> str:
    return '''SELECT 1'''

  def _contextualize_results(self, rows: List[Any]) -> str:
    return 'Ensure that security contact information for the root account in the AWS Console under "My Account / Alternate Contacts / Security" is up-to-date'


class InstancesUseInstanceProfiles(Info):
  '''Benchmark 1.19'''
  benchmark = '1.19'
  severity = 'low'

  def _sql(self) -> str:
    return '''SELECT 1'''

  # TODO: consider listing instances that have no instance profile
  def _contextualize_results(self, rows: List[Any]) -> str:
    return 'Verify that applications are not embedding AWS credentials and are instead making use of InstanceProfiles'


class SupportPolicyExists(Check):
  '''Benchmark 1.20'''
  benchmark = '1.20'
  severity = 'low'
  region = 'global'

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


class NoAutoCreatedAccessKeys(Check):
  '''Benchmark 1.21'''
  benchmark = '1.21'
  severity = 'medium'
  region = 'global'

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
        AND has_login = True
    '''

  def _contextualize_failure(self, row: Any) -> str:
    uri = row['uri']
    key_id = row['keyid']
    return f'User {uri} has an auto-created access key {key_id}'


class NoAdminAccess(Check):
  '''Benchmark 1.22'''
  benchmark = '1.22'
  severity = 'low'
  region = 'global'

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


class CloudtrailEnabledEverywhere(Check):
  '''Benchmark 2.1'''
  benchmark = '2.1'
  severity = 'medium'
  region = 'global'

  def _sql(self) -> str:
    return '''
      SELECT
        True
      FROM
        (
          SELECT
            COUNT(*) AS cnt
          FROM
            aws_cloudtrail_trail
          WHERE
            ismultiregiontrail = True
            AND provider_account_id = :provider_account_id
        ) AS multi_region_trails
      WHERE
        multi_region_trails.cnt = 0
    '''

  def _contextualize_failure(self, row: Any) -> str:
    return 'No multi-region cloudtrail instance found'


class CloudtrailLogFileValidationEnabled(Check):
  '''Benchmark 2.2'''
  # Level 2
  benchmark = '2.2'
  severity = 'low'
  region = 'global'

  def _sql(self) -> str:
    return '''
      SELECT
        uri
      FROM
        aws_cloudtrail_trail
      WHERE
        logfilevalidationenabled = False
        AND provider_account_id = :provider_account_id
    '''

  def _contextualize_failure(self, row: Any) -> str:
    uri = row['uri']
    return f'Cloudtrail {uri} does not have log file validation enabled'


class CloudtrailBucketIsPrivate(Check):
  '''Benchmark 2.3'''
  benchmark = '2.3'
  severity = 'high'
  region = 'global'

  def _sql(self) -> str:
    return '''
      WITH acl_public AS (
        SELECT
          B.uri
        FROM
          aws_s3_bucket AS B
          CROSS JOIN LATERAL jsonb_array_elements(B.acl->'Grants') AS G
        WHERE
          G.value->'Grantee'->>'Type' = 'Group'
          AND G.value->'Grantee'->>'URI' IN ('http://acs.amazonaws.com/groups/global/AuthenticatedUsers', 'http://acs.amazonaws.com/groups/global/AllUsers')
      ), policy_public AS (
        SELECT
          B.uri
        FROM
          aws_s3_bucket AS B
          CROSS JOIN LATERAL jsonb_array_elements(B.policy::jsonb->'Statement') AS S
        WHERE
          S.value->>'Effect' = 'Allow'
          AND S.value->'Principal' IN ('"*"'::jsonb, '{"AWS": "*"}'::jsonb)
      )
      SELECT
        T.uri AS trail,
        B.uri AS bucket
      FROM
        aws_cloudtrail_trail AS T
        INNER JOIN aws_s3_bucket AS B
          ON T._s3_bucket_id = B.resource_id
      WHERE
        T.provider_account_id = :provider_account_id
        AND (
          EXISTS (SELECT uri FROM policy_public AS PP WHERE PP.uri = B.uri)
          OR EXISTS (SELECT uri FROM acl_public AS PP WHERE PP.uri = B.uri)
        )
    '''

  def _contextualize_failure(self, row: Any) -> str:
    trail = row['trail']
    bucket = row['bucket']
    return f'Cloudtrail {trail} writes to public bucket {bucket}'


class CloudwatchLogsUpToDate(Check):
  '''Benchmark 2.4'''
  benchmark = '2.4'
  severity = 'high'
  region = 'global'

  def _sql(self) -> str:
    return '''
      SELECT
        uri,
        COALESCE(
          age(latestcloudwatchlogsdeliverytime) > interval '1 day',
          True
        ) AS stale_logs,
        cloudwatchlogsloggrouparn IS NULL AS no_log_group
      FROM
        aws_cloudtrail_trail
      WHERE
        provider_account_id = :provider_account_id
        AND (
          cloudwatchlogsloggrouparn IS NULL
          OR
          COALESCE(
            age(latestcloudwatchlogsdeliverytime) > interval '1 day',
            True
          )
        )
    '''

  def _contextualize_failure(self, row: Any) -> str:
    uri = row['uri']
    if row['no_log_group']:
      return f'Cloudtrail {uri} has no associated cloudwatch logs'
    else:
      return f'Cloudtrail {uri} has not received cloudwatch logs in over a day'


class ConfigEnabledInAllRegions(Check):
  '''Benchmark 2.5'''
  benchmark = '2.5'
  severity = 'low'
  region = '*'

  def _sql(self) -> str:
    return '''
      SELECT
        1
      FROM
        (SELECT
          COUNT(*) AS global_recorders_count
        FROM
          aws_config_configurationrecorder
        WHERE
          provider_account_id = :provider_account_id
          AND allsupported = True
          AND includeglobalresourcetypes = True
        ) AS recorders_count
      WHERE
        recorders_count.global_recorders_count = 0
    '''

  def _contextualize_failure(self, row: Any) -> str:
    return 'Could not find a ConfigurationRecorder configured to record from all regions, including global events'


class CloudtrailBucketLoggingIsEnable(Check):
  '''Benchmark 2.6'''
  benchmark = '2.6'
  severity = 'low'
  region = 'global'

  def _sql(self) -> str:
    return '''
      SELECT
        T.uri AS trail,
        B.uri AS bucket
      FROM
        aws_cloudtrail_trail AS T
        INNER JOIN aws_s3_bucket AS B
          ON T._s3_bucket_id = B.resource_id
      WHERE
        B.logging -> 'LoggingEnabled' IS NULL
        AND T.provider_account_id = :provider_account_id
    '''

  def _contextualize_failure(self, row: Any) -> str:
    trail = row['trail']
    bucket = row['bucket']
    return f'Cloudtrail {trail} writes to bucket {bucket} which does not have access logging enabled'


class CloudtrailEncryptedAtRestWithCMK(Check):
  '''Benchmark 2.7'''
  benchmark = '2.7'
  severity = 'low'
  region = 'global'

  # Level 2
  def _sql(self) -> str:
    return '''
      SELECT
        uri
      FROM
        aws_cloudtrail_trail
      WHERE
        kmskeyid IS NULL
        AND provider_account_id = :provider_account_id
    '''

  def _contextualize_failure(self, row: Any) -> str:
    uri = row['uri']
    return f'CloudTrail {uri} is not set to encrypt log files with a CMK'


class CustomerKeysHaveRotationEnabled(Check):
  '''Benchmark 2.8'''
  benchmark = '2.8'
  severity = 'low'
  region = '*'

  def _sql(self) -> str:
    return '''
    SELECT
      uri
    FROM
      aws_kms_key
    WHERE
      provider_account_id = :provider_account_id
      AND keyrotationenabled = False
    '''

  def _contextualize_failure(self, row: Any) -> str:
    uri = row['uri']
    return f'KMS Key {uri} does not have key rotation enabled'


class VPCsHaveFlowLogs(Check):
  '''Benchmark 2.9'''
  benchmark = '2.9'
  severity = 'low'
  region = '*'

  def _sql(self) -> str:
    return '''
      SELECT
        VPC.uri
      FROM
        aws_ec2_vpc AS VPC
      WHERE
        VPC.provider_account_id = :provider_account_id
        AND VPC.resource_id NOT IN (
          SELECT
            _vpc_id
          FROM
            aws_ec2_flowlog
          WHERE
            provider_account_id = :provider_account_id
            AND flowlogstatus = 'ACTIVE'
            AND (traffictype = 'ALL' OR traffictype = 'REJECT')
        )
    '''

  def _contextualize_failure(self, row: Any) -> str:
    uri = row['uri']
    return f'VPC {uri} has no flow log. A log at least captuing rejected traffic is recommended'


class AlertOnUnauthorizedAPICalls(Check):
  '''Benchmark 3.1'''
  benchmark = '3.1'
  severity = 'low'
  region = 'global'

  def _sql(self) -> str:
    return '''
      SELECT 1 FROM (
        SELECT
          COUNT(*) AS count
        FROM (
          SELECT
            Trail.uri,
            Metric.uri,
            Alarm.uri,
            Topic.subscriptionsconfirmed
          FROM
            aws_cloudtrail_trail AS Trail
            LEFT JOIN aws_logs_loggroup AS LogGroup
              ON LogGroup.resource_id = Trail._logs_loggroup_id
            LEFT JOIN aws_logs_metricfilter AS MetricFilter
              ON MetricFilter._loggroup_id = LogGroup.resource_id
            LEFT JOIN aws_logs_metricfilter_metric AS filter2metric
              ON filter2metric.metricfilter_id = MetricFilter.resource_id
            LEFT JOIN aws_logs_metric AS Metric
              ON filter2metric.metric_id = Metric.resource_id
            LEFT JOIN aws_cloudwatch_metricalarm AS Alarm
              ON Alarm._logs_metric_id = Metric.resource_id
            LEFT JOIN aws_cloudwatch_metricalarm_sns_topic AS Alarm2Topic
              ON Alarm2Topic.metricalarm_id = Alarm.resource_id
            LEFT JOIN aws_sns_topic AS Topic
              ON Alarm2Topic.topic_id = Topic.resource_id,
            LATERAL jsonb_array_elements(Trail.eventselectors) AS Selector
          WHERE
            Trail.provider_account_id = :provider_account_id
            AND Trail.ismultiregiontrail = True
            AND Trail.islogging = True
            AND (Selector.value #>> '{IncludeManagementEvents}')::bool = True
            AND Selector.value ->> 'ReadWriteType' = 'All'
            AND Alarm.actionsenabled = True
            AND aws_logs_metricfilter_pattern_matches(
              '{ ($.errorCode = "*UnauthorizedOperation") || ($.errorCode = "AccessDenied*") }',
              MetricFilter.filterpattern
            )
          ) AS unauthorized_api_alerts
        ) AS unauthorized_api_alert_count
      WHERE
        count = 0
      '''

  def _contextualize_failure(self, row: Any) -> str:
    return 'Could not find a live alert for unauthorized AWS API calls'


class AlertOnNoMFAConsoleSignin(Check):
  '''Benchmark 3.2'''
  benchmark = '3.2'
  severity = 'low'
  region = 'global'

  def _sql(self) -> str:
    return '''
      SELECT 1 FROM (
        SELECT
          COUNT(*) AS count
        FROM (
          SELECT
            Trail.uri,
            Metric.uri,
            Alarm.uri,
            Topic.subscriptionsconfirmed
          FROM
            aws_cloudtrail_trail AS Trail
            LEFT JOIN aws_logs_loggroup AS LogGroup
              ON LogGroup.resource_id = Trail._logs_loggroup_id
            LEFT JOIN aws_logs_metricfilter AS MetricFilter
              ON MetricFilter._loggroup_id = LogGroup.resource_id
            LEFT JOIN aws_logs_metricfilter_metric AS filter2metric
              ON filter2metric.metricfilter_id = MetricFilter.resource_id
            LEFT JOIN aws_logs_metric AS Metric
              ON filter2metric.metric_id = Metric.resource_id
            LEFT JOIN aws_cloudwatch_metricalarm AS Alarm
              ON Alarm._logs_metric_id = Metric.resource_id
            LEFT JOIN aws_cloudwatch_metricalarm_sns_topic AS Alarm2Topic
              ON Alarm2Topic.metricalarm_id = Alarm.resource_id
            LEFT JOIN aws_sns_topic AS Topic
              ON Alarm2Topic.topic_id = Topic.resource_id,
            LATERAL jsonb_array_elements(Trail.eventselectors) AS Selector
          WHERE
            Trail.provider_account_id = :provider_account_id
            AND Trail.ismultiregiontrail = True
            AND Trail.islogging = True
            AND (Selector.value #>> '{IncludeManagementEvents}')::bool = True
            AND Selector.value ->> 'ReadWriteType' = 'All'
            AND Alarm.actionsenabled = True
            AND aws_logs_metricfilter_pattern_matches(
              '{ ($.eventName = "ConsoleLogin") && ($.additionalEventData.MFAUsed != "Yes") }',
              MetricFilter.filterpattern
            )
          ) AS unauthorized_api_alerts
        ) AS unauthorized_api_alert_count
      WHERE
        count = 0
      '''

  def _contextualize_failure(self, row: Any) -> str:
    return 'Could not find a live alert for AWS console signins without multi-factor auth'


class AlertOnRootAccountUsage(Check):
  '''Benchmark 3.3'''
  benchmark = '3.3'
  severity = 'low'
  region = 'global'

  def _sql(self) -> str:
    return '''
      SELECT 1 FROM (
        SELECT
          COUNT(*) AS count
        FROM (
          SELECT
            Trail.uri,
            Metric.uri,
            Alarm.uri,
            Topic.subscriptionsconfirmed
          FROM
            aws_cloudtrail_trail AS Trail
            LEFT JOIN aws_logs_loggroup AS LogGroup
              ON LogGroup.resource_id = Trail._logs_loggroup_id
            LEFT JOIN aws_logs_metricfilter AS MetricFilter
              ON MetricFilter._loggroup_id = LogGroup.resource_id
            LEFT JOIN aws_logs_metricfilter_metric AS filter2metric
              ON filter2metric.metricfilter_id = MetricFilter.resource_id
            LEFT JOIN aws_logs_metric AS Metric
              ON filter2metric.metric_id = Metric.resource_id
            LEFT JOIN aws_cloudwatch_metricalarm AS Alarm
              ON Alarm._logs_metric_id = Metric.resource_id
            LEFT JOIN aws_cloudwatch_metricalarm_sns_topic AS Alarm2Topic
              ON Alarm2Topic.metricalarm_id = Alarm.resource_id
            LEFT JOIN aws_sns_topic AS Topic
              ON Alarm2Topic.topic_id = Topic.resource_id,
            LATERAL jsonb_array_elements(Trail.eventselectors) AS Selector
          WHERE
            Trail.provider_account_id = :provider_account_id
            AND Trail.ismultiregiontrail = True
            AND Trail.islogging = True
            AND (Selector.value #>> '{IncludeManagementEvents}')::bool = True
            AND Selector.value ->> 'ReadWriteType' = 'All'
            AND Alarm.actionsenabled = True
            AND aws_logs_metricfilter_pattern_matches(
              '{ $.userIdentity.type = "Root" && $.userIdentity.invokedBy NOT EXISTS && $.eventType != "AwsServiceEvent" }',
              MetricFilter.filterpattern
            )
          ) AS unauthorized_api_alerts
        ) AS unauthorized_api_alert_count
      WHERE
        count = 0
      '''

  def _contextualize_failure(self, row: Any) -> str:
    return 'Could not find a live alert for usage of the root account'


class AlertOnIAMPolicyChanges(Check):
  '''Benchmark 3.4'''
  benchmark = '3.4'
  severity = 'low'
  region = 'global'

  def _sql(self) -> str:
    filter_terms = [
        '($.eventName=DeleteGroupPolicy)', '($.eventName=DeleteRolePolicy)',
        '($.eventName=DeleteUserPolicy)', '($.eventName=PutGroupPolicy)',
        '($.eventName=PutRolePolicy)', '($.eventName=PutUserPolicy)',
        '($.eventName=CreatePolicy)', '($.eventName=DeletePolicy)',
        '($.eventName=CreatePolicyVersion)',
        '($.eventName=DeletePolicyVersion)', '($.eventName=AttachRolePolicy)',
        '($.eventName=DetachRolePolicy)', '($.eventName=AttachUserPolicy)',
        '($.eventName=DetachUserPolicy)', '($.eventName=AttachGroupPolicy)',
        '($.eventName=DetachGroupPolicy)'
    ]
    return f'''
      SELECT 1 FROM (
        SELECT
          COUNT(*) AS count
        FROM (
          SELECT
            Trail.uri,
            Metric.uri,
            Alarm.uri,
            Topic.subscriptionsconfirmed
          FROM
            aws_cloudtrail_trail AS Trail
            LEFT JOIN aws_logs_loggroup AS LogGroup
              ON LogGroup.resource_id = Trail._logs_loggroup_id
            LEFT JOIN aws_logs_metricfilter AS MetricFilter
              ON MetricFilter._loggroup_id = LogGroup.resource_id
            LEFT JOIN aws_logs_metricfilter_metric AS filter2metric
              ON filter2metric.metricfilter_id = MetricFilter.resource_id
            LEFT JOIN aws_logs_metric AS Metric
              ON filter2metric.metric_id = Metric.resource_id
            LEFT JOIN aws_cloudwatch_metricalarm AS Alarm
              ON Alarm._logs_metric_id = Metric.resource_id
            LEFT JOIN aws_cloudwatch_metricalarm_sns_topic AS Alarm2Topic
              ON Alarm2Topic.metricalarm_id = Alarm.resource_id
            LEFT JOIN aws_sns_topic AS Topic
              ON Alarm2Topic.topic_id = Topic.resource_id,
            LATERAL jsonb_array_elements(Trail.eventselectors) AS Selector
          WHERE
            Trail.provider_account_id = :provider_account_id
            AND Trail.ismultiregiontrail = True
            AND Trail.islogging = True
            AND (Selector.value #>> '{{IncludeManagementEvents}}')::bool = True
            AND Selector.value ->> 'ReadWriteType' = 'All'
            AND Alarm.actionsenabled = True
            AND aws_logs_metricfilter_pattern_matches(
              '{{ {"||".join(filter_terms)} }}',
              MetricFilter.filterpattern
            )
          ) AS unauthorized_api_alerts
        ) AS unauthorized_api_alert_count
      WHERE
        count = 0
      '''

  def _contextualize_failure(self, row: Any) -> str:
    return 'Could not find a live alert for changes to IAM Policies'


class AlertOnCloudTrailConfigurationChanges(Check):
  '''Benchmark 3.5'''
  benchmark = '3.5'
  severity = 'low'
  region = 'global'

  def _sql(self) -> str:
    filter_terms = [
        '($.eventName = CreateTrail)', '($.eventName = UpdateTrail)',
        '($.eventName = DeleteTrail)', '($.eventName = StartLogging)',
        '($.eventName = StopLogging)'
    ]
    return f'''
      SELECT 1 FROM (
        SELECT
          COUNT(*) AS count
        FROM (
          SELECT
            Trail.uri,
            Metric.uri,
            Alarm.uri,
            Topic.subscriptionsconfirmed
          FROM
            aws_cloudtrail_trail AS Trail
            LEFT JOIN aws_logs_loggroup AS LogGroup
              ON LogGroup.resource_id = Trail._logs_loggroup_id
            LEFT JOIN aws_logs_metricfilter AS MetricFilter
              ON MetricFilter._loggroup_id = LogGroup.resource_id
            LEFT JOIN aws_logs_metricfilter_metric AS filter2metric
              ON filter2metric.metricfilter_id = MetricFilter.resource_id
            LEFT JOIN aws_logs_metric AS Metric
              ON filter2metric.metric_id = Metric.resource_id
            LEFT JOIN aws_cloudwatch_metricalarm AS Alarm
              ON Alarm._logs_metric_id = Metric.resource_id
            LEFT JOIN aws_cloudwatch_metricalarm_sns_topic AS Alarm2Topic
              ON Alarm2Topic.metricalarm_id = Alarm.resource_id
            LEFT JOIN aws_sns_topic AS Topic
              ON Alarm2Topic.topic_id = Topic.resource_id,
            LATERAL jsonb_array_elements(Trail.eventselectors) AS Selector
          WHERE
            Trail.provider_account_id = :provider_account_id
            AND Trail.ismultiregiontrail = True
            AND Trail.islogging = True
            AND (Selector.value #>> '{{IncludeManagementEvents}}')::bool = True
            AND Selector.value ->> 'ReadWriteType' = 'All'
            AND Alarm.actionsenabled = True
            AND aws_logs_metricfilter_pattern_matches(
              '{{ {"||".join(filter_terms)} }}',
              MetricFilter.filterpattern
            )
          ) AS unauthorized_api_alerts
        ) AS unauthorized_api_alert_count
      WHERE
        count = 0
      '''

  def _contextualize_failure(self, row: Any) -> str:
    return 'Could not find a live alert for changes to Cloudtrail Configuration'


class AlertOnFailedConsoleAuthentication(Check):
  '''Benchmark 3.6'''
  benchmark = '3.6'
  severity = 'low'
  region = 'global'

  def _sql(self) -> str:
    return '''
      SELECT 1 FROM (
        SELECT
          COUNT(*) AS count
        FROM (
          SELECT
            Trail.uri,
            Metric.uri,
            Alarm.uri,
            Topic.subscriptionsconfirmed
          FROM
            aws_cloudtrail_trail AS Trail
            LEFT JOIN aws_logs_loggroup AS LogGroup
              ON LogGroup.resource_id = Trail._logs_loggroup_id
            LEFT JOIN aws_logs_metricfilter AS MetricFilter
              ON MetricFilter._loggroup_id = LogGroup.resource_id
            LEFT JOIN aws_logs_metricfilter_metric AS filter2metric
              ON filter2metric.metricfilter_id = MetricFilter.resource_id
            LEFT JOIN aws_logs_metric AS Metric
              ON filter2metric.metric_id = Metric.resource_id
            LEFT JOIN aws_cloudwatch_metricalarm AS Alarm
              ON Alarm._logs_metric_id = Metric.resource_id
            LEFT JOIN aws_cloudwatch_metricalarm_sns_topic AS Alarm2Topic
              ON Alarm2Topic.metricalarm_id = Alarm.resource_id
            LEFT JOIN aws_sns_topic AS Topic
              ON Alarm2Topic.topic_id = Topic.resource_id,
            LATERAL jsonb_array_elements(Trail.eventselectors) AS Selector
          WHERE
            Trail.provider_account_id = :provider_account_id
            AND Trail.ismultiregiontrail = True
            AND Trail.islogging = True
            AND (Selector.value #>> '{IncludeManagementEvents}')::bool = True
            AND Selector.value ->> 'ReadWriteType' = 'All'
            AND Alarm.actionsenabled = True
            AND aws_logs_metricfilter_pattern_matches(
              '{ ($.eventName = ConsoleLogin) && ($.errorMessage = "Failed authentication") }',
              MetricFilter.filterpattern
            )
          ) AS unauthorized_api_alerts
        ) AS unauthorized_api_alert_count
      WHERE
        count = 0
      '''

  def _contextualize_failure(self, row: Any) -> str:
    return 'Could not find a live alert for failed console logins'


class AlertOnCMKDisablingOrScheduledDeletion(Check):
  '''Benchmark 3.7'''
  benchmark = '3.7'
  severity = 'low'
  region = 'global'

  def _sql(self) -> str:
    return '''
      SELECT 1 FROM (
        SELECT
          COUNT(*) AS count
        FROM (
          SELECT
            Trail.uri,
            Metric.uri,
            Alarm.uri,
            Topic.subscriptionsconfirmed
          FROM
            aws_cloudtrail_trail AS Trail
            LEFT JOIN aws_logs_loggroup AS LogGroup
              ON LogGroup.resource_id = Trail._logs_loggroup_id
            LEFT JOIN aws_logs_metricfilter AS MetricFilter
              ON MetricFilter._loggroup_id = LogGroup.resource_id
            LEFT JOIN aws_logs_metricfilter_metric AS filter2metric
              ON filter2metric.metricfilter_id = MetricFilter.resource_id
            LEFT JOIN aws_logs_metric AS Metric
              ON filter2metric.metric_id = Metric.resource_id
            LEFT JOIN aws_cloudwatch_metricalarm AS Alarm
              ON Alarm._logs_metric_id = Metric.resource_id
            LEFT JOIN aws_cloudwatch_metricalarm_sns_topic AS Alarm2Topic
              ON Alarm2Topic.metricalarm_id = Alarm.resource_id
            LEFT JOIN aws_sns_topic AS Topic
              ON Alarm2Topic.topic_id = Topic.resource_id,
            LATERAL jsonb_array_elements(Trail.eventselectors) AS Selector
          WHERE
            Trail.provider_account_id = :provider_account_id
            AND Trail.ismultiregiontrail = True
            AND Trail.islogging = True
            AND (Selector.value #>> '{IncludeManagementEvents}')::bool = True
            AND Selector.value ->> 'ReadWriteType' = 'All'
            AND Alarm.actionsenabled = True
            AND aws_logs_metricfilter_pattern_matches(
              '{($.eventSource = kms.amazonaws.com) && (($.eventName=DisableKey)||($.eventName=ScheduleKeyDeletion)) }',
              MetricFilter.filterpattern
            )
          ) AS unauthorized_api_alerts
        ) AS unauthorized_api_alert_count
      WHERE
        count = 0
      '''

  def _contextualize_failure(self, row: Any) -> str:
    return 'Could not find a live alert for disabling or scheduled deletion of customer-created CMKs'


class AlertOnS3BucketPolicyChanges(Check):
  '''Benchmark 3.8'''
  benchmark = '3.8'
  severity = 'low'
  region = 'global'

  def _sql(self) -> str:
    or_filters = [
        '($.eventName = PutBucketAcl)', '($.eventName = PutBucketPolicy)',
        '($.eventName = PutBucketCors)', '($.eventName = PutBucketLifecycle)',
        '($.eventName = PutBucketReplication)',
        '($.eventName = DeleteBucketPolicy)',
        '($.eventName = DeleteBucketCors)',
        '($.eventName = DeleteBucketLifecycle)',
        '($.eventName = DeleteBucketReplication)'
    ]

    policy_filter = f'{{ ($.eventSource = s3.amazonaws.com) && ({" || ".join(or_filters)}) }}'
    return f'''
      SELECT 1 FROM (
        SELECT
          COUNT(*) AS count
        FROM (
          SELECT
            Trail.uri,
            Metric.uri,
            Alarm.uri,
            Topic.subscriptionsconfirmed
          FROM
            aws_cloudtrail_trail AS Trail
            LEFT JOIN aws_logs_loggroup AS LogGroup
              ON LogGroup.resource_id = Trail._logs_loggroup_id
            LEFT JOIN aws_logs_metricfilter AS MetricFilter
              ON MetricFilter._loggroup_id = LogGroup.resource_id
            LEFT JOIN aws_logs_metricfilter_metric AS filter2metric
              ON filter2metric.metricfilter_id = MetricFilter.resource_id
            LEFT JOIN aws_logs_metric AS Metric
              ON filter2metric.metric_id = Metric.resource_id
            LEFT JOIN aws_cloudwatch_metricalarm AS Alarm
              ON Alarm._logs_metric_id = Metric.resource_id
            LEFT JOIN aws_cloudwatch_metricalarm_sns_topic AS Alarm2Topic
              ON Alarm2Topic.metricalarm_id = Alarm.resource_id
            LEFT JOIN aws_sns_topic AS Topic
              ON Alarm2Topic.topic_id = Topic.resource_id,
            LATERAL jsonb_array_elements(Trail.eventselectors) AS Selector
          WHERE
            Trail.provider_account_id = :provider_account_id
            AND Trail.ismultiregiontrail = True
            AND Trail.islogging = True
            AND (Selector.value #>> '{{IncludeManagementEvents}}')::bool = True
            AND Selector.value ->> 'ReadWriteType' = 'All'
            AND Alarm.actionsenabled = True
            AND aws_logs_metricfilter_pattern_matches(
              '{policy_filter}',
              MetricFilter.filterpattern
            )
          ) AS unauthorized_api_alerts
        ) AS unauthorized_api_alert_count
      WHERE
        count = 0
      '''

  def _contextualize_failure(self, row: Any) -> str:
    return 'Could not find a live alert for S3 bucket policy changes'


class AlertOnConfigConfigurationChanges(Check):
  '''Benchmark 3.9'''
  benchmark = '3.9'
  severity = 'low'
  region = 'global'

  def _sql(self) -> str:
    or_filters = [
        '($.eventName=StopConfigurationRecorder)',
        '($.eventName=DeleteDeliveryChannel)',
        '($.eventName=PutDeliveryChannel)',
        '($.eventName=PutConfigurationRecorder)'
    ]

    policy_filter = f'{{ ($.eventSource = config.amazonaws.com) && ({" || ".join(or_filters)}) }}'
    return f'''
      SELECT 1 FROM (
        SELECT
          COUNT(*) AS count
        FROM (
          SELECT
            Trail.uri,
            Metric.uri,
            Alarm.uri,
            Topic.subscriptionsconfirmed
          FROM
            aws_cloudtrail_trail AS Trail
            LEFT JOIN aws_logs_loggroup AS LogGroup
              ON LogGroup.resource_id = Trail._logs_loggroup_id
            LEFT JOIN aws_logs_metricfilter AS MetricFilter
              ON MetricFilter._loggroup_id = LogGroup.resource_id
            LEFT JOIN aws_logs_metricfilter_metric AS filter2metric
              ON filter2metric.metricfilter_id = MetricFilter.resource_id
            LEFT JOIN aws_logs_metric AS Metric
              ON filter2metric.metric_id = Metric.resource_id
            LEFT JOIN aws_cloudwatch_metricalarm AS Alarm
              ON Alarm._logs_metric_id = Metric.resource_id
            LEFT JOIN aws_cloudwatch_metricalarm_sns_topic AS Alarm2Topic
              ON Alarm2Topic.metricalarm_id = Alarm.resource_id
            LEFT JOIN aws_sns_topic AS Topic
              ON Alarm2Topic.topic_id = Topic.resource_id,
            LATERAL jsonb_array_elements(Trail.eventselectors) AS Selector
          WHERE
            Trail.provider_account_id = :provider_account_id
            AND Trail.ismultiregiontrail = True
            AND Trail.islogging = True
            AND (Selector.value #>> '{{IncludeManagementEvents}}')::bool = True
            AND Selector.value ->> 'ReadWriteType' = 'All'
            AND Alarm.actionsenabled = True
            AND aws_logs_metricfilter_pattern_matches(
              '{policy_filter}',
              MetricFilter.filterpattern
            )
          ) AS unauthorized_api_alerts
        ) AS unauthorized_api_alert_count
      WHERE
        count = 0
      '''

  def _contextualize_failure(self, row: Any) -> str:
    return 'Could not find a live alert for AWS Config configuration changes'


class AlertOnSecurityGroupChanges(Check):
  '''Benchmark 3.10'''
  benchmark = '3.10'
  severity = 'low'
  region = 'global'

  def _sql(self) -> str:
    or_filters = [
        '($.eventName = AuthorizeSecurityGroupIngress)',
        '($.eventName = AuthorizeSecurityGroupEgress)',
        '($.eventName = RevokeSecurityGroupIngress)',
        '($.eventName = RevokeSecurityGroupEgress)',
        '($.eventName = CreateSecurityGroup)',
        '($.eventName = DeleteSecurityGroup)'
    ]

    policy_filter = f'{{ {" || ".join(or_filters)} }}'
    return f'''
      SELECT 1 FROM (
        SELECT
          COUNT(*) AS count
        FROM (
          SELECT
            Trail.uri,
            Metric.uri,
            Alarm.uri,
            Topic.subscriptionsconfirmed
          FROM
            aws_cloudtrail_trail AS Trail
            LEFT JOIN aws_logs_loggroup AS LogGroup
              ON LogGroup.resource_id = Trail._logs_loggroup_id
            LEFT JOIN aws_logs_metricfilter AS MetricFilter
              ON MetricFilter._loggroup_id = LogGroup.resource_id
            LEFT JOIN aws_logs_metricfilter_metric AS filter2metric
              ON filter2metric.metricfilter_id = MetricFilter.resource_id
            LEFT JOIN aws_logs_metric AS Metric
              ON filter2metric.metric_id = Metric.resource_id
            LEFT JOIN aws_cloudwatch_metricalarm AS Alarm
              ON Alarm._logs_metric_id = Metric.resource_id
            LEFT JOIN aws_cloudwatch_metricalarm_sns_topic AS Alarm2Topic
              ON Alarm2Topic.metricalarm_id = Alarm.resource_id
            LEFT JOIN aws_sns_topic AS Topic
              ON Alarm2Topic.topic_id = Topic.resource_id,
            LATERAL jsonb_array_elements(Trail.eventselectors) AS Selector
          WHERE
            Trail.provider_account_id = :provider_account_id
            AND Trail.ismultiregiontrail = True
            AND Trail.islogging = True
            AND (Selector.value #>> '{{IncludeManagementEvents}}')::bool = True
            AND Selector.value ->> 'ReadWriteType' = 'All'
            AND Alarm.actionsenabled = True
            AND aws_logs_metricfilter_pattern_matches(
              '{policy_filter}',
              MetricFilter.filterpattern
            )
          ) AS unauthorized_api_alerts
        ) AS unauthorized_api_alert_count
      WHERE
        count = 0
      '''

  def _contextualize_failure(self, row: Any) -> str:
    return 'Could not find a live alert for Security Group changes'


class AlertOnNetworkACLChanges(Check):
  '''Benchmark 3.11'''
  benchmark = '3.11'
  severity = 'low'
  region = 'global'

  def _sql(self) -> str:
    or_filters = [
        '($.eventName = CreateNetworkAcl)',
        '($.eventName = CreateNetworkAclEntry)',
        '($.eventName = DeleteNetworkAcl)',
        '($.eventName = DeleteNetworkAclEntry)',
        '($.eventName = ReplaceNetworkAclEntry)',
        '($.eventName = ReplaceNetworkAclAssociation)'
    ]

    policy_filter = f'{{ {" || ".join(or_filters)} }}'
    return f'''
      SELECT 1 FROM (
        SELECT
          COUNT(*) AS count
        FROM (
          SELECT
            Trail.uri,
            Metric.uri,
            Alarm.uri,
            Topic.subscriptionsconfirmed
          FROM
            aws_cloudtrail_trail AS Trail
            LEFT JOIN aws_logs_loggroup AS LogGroup
              ON LogGroup.resource_id = Trail._logs_loggroup_id
            LEFT JOIN aws_logs_metricfilter AS MetricFilter
              ON MetricFilter._loggroup_id = LogGroup.resource_id
            LEFT JOIN aws_logs_metricfilter_metric AS filter2metric
              ON filter2metric.metricfilter_id = MetricFilter.resource_id
            LEFT JOIN aws_logs_metric AS Metric
              ON filter2metric.metric_id = Metric.resource_id
            LEFT JOIN aws_cloudwatch_metricalarm AS Alarm
              ON Alarm._logs_metric_id = Metric.resource_id
            LEFT JOIN aws_cloudwatch_metricalarm_sns_topic AS Alarm2Topic
              ON Alarm2Topic.metricalarm_id = Alarm.resource_id
            LEFT JOIN aws_sns_topic AS Topic
              ON Alarm2Topic.topic_id = Topic.resource_id,
            LATERAL jsonb_array_elements(Trail.eventselectors) AS Selector
          WHERE
            Trail.provider_account_id = :provider_account_id
            AND Trail.ismultiregiontrail = True
            AND Trail.islogging = True
            AND (Selector.value #>> '{{IncludeManagementEvents}}')::bool = True
            AND Selector.value ->> 'ReadWriteType' = 'All'
            AND Alarm.actionsenabled = True
            AND aws_logs_metricfilter_pattern_matches(
              '{policy_filter}',
              MetricFilter.filterpattern
            )
          ) AS unauthorized_api_alerts
        ) AS unauthorized_api_alert_count
      WHERE
        count = 0
      '''

  def _contextualize_failure(self, row: Any) -> str:
    return 'Could not find a live alert for Network ACL changes'


class AlertOnNetworkGatewayChanges(Check):
  '''Benchmark 3.12'''
  benchmark = '3.12'
  severity = 'low'
  region = 'global'

  def _sql(self) -> str:
    or_filters = [
        '($.eventName = CreateCustomerGateway)',
        '($.eventName = DeleteCustomerGateway)',
        '($.eventName = AttachInternetGateway)',
        '($.eventName = CreateInternetGateway)',
        '($.eventName = DeleteInternetGateway)',
        '($.eventName = DetachInternetGateway)'
    ]

    policy_filter = f'{{ {" || ".join(or_filters)} }}'
    return f'''
      SELECT 1 FROM (
        SELECT
          COUNT(*) AS count
        FROM (
          SELECT
            Trail.uri,
            Metric.uri,
            Alarm.uri,
            Topic.subscriptionsconfirmed
          FROM
            aws_cloudtrail_trail AS Trail
            LEFT JOIN aws_logs_loggroup AS LogGroup
              ON LogGroup.resource_id = Trail._logs_loggroup_id
            LEFT JOIN aws_logs_metricfilter AS MetricFilter
              ON MetricFilter._loggroup_id = LogGroup.resource_id
            LEFT JOIN aws_logs_metricfilter_metric AS filter2metric
              ON filter2metric.metricfilter_id = MetricFilter.resource_id
            LEFT JOIN aws_logs_metric AS Metric
              ON filter2metric.metric_id = Metric.resource_id
            LEFT JOIN aws_cloudwatch_metricalarm AS Alarm
              ON Alarm._logs_metric_id = Metric.resource_id
            LEFT JOIN aws_cloudwatch_metricalarm_sns_topic AS Alarm2Topic
              ON Alarm2Topic.metricalarm_id = Alarm.resource_id
            LEFT JOIN aws_sns_topic AS Topic
              ON Alarm2Topic.topic_id = Topic.resource_id,
            LATERAL jsonb_array_elements(Trail.eventselectors) AS Selector
          WHERE
            Trail.provider_account_id = :provider_account_id
            AND Trail.ismultiregiontrail = True
            AND Trail.islogging = True
            AND (Selector.value #>> '{{IncludeManagementEvents}}')::bool = True
            AND Selector.value ->> 'ReadWriteType' = 'All'
            AND Alarm.actionsenabled = True
            AND aws_logs_metricfilter_pattern_matches(
              '{policy_filter}',
              MetricFilter.filterpattern
            )
          ) AS unauthorized_api_alerts
        ) AS unauthorized_api_alert_count
      WHERE
        count = 0
      '''

  def _contextualize_failure(self, row: Any) -> str:
    return 'Could not find a live alert for Network Gateway changes'


class AlertOnRouteTableChanges(Check):
  '''Benchmark 3.13'''
  benchmark = '3.13'
  severity = 'low'
  region = 'global'

  def _sql(self) -> str:
    or_filters = [
        '($.eventName = CreateRoute)', '($.eventName = CreateRouteTable)',
        '($.eventName = ReplaceRoute)',
        '($.eventName = ReplaceRouteTableAssociation)',
        '($.eventName = DeleteRouteTable)', '($.eventName = DeleteRoute)',
        '($.eventName = DisassociateRouteTable)'
    ]

    policy_filter = f'{{ {" || ".join(or_filters)} }}'
    return f'''
      SELECT 1 FROM (
        SELECT
          COUNT(*) AS count
        FROM (
          SELECT
            Trail.uri,
            Metric.uri,
            Alarm.uri,
            Topic.subscriptionsconfirmed
          FROM
            aws_cloudtrail_trail AS Trail
            LEFT JOIN aws_logs_loggroup AS LogGroup
              ON LogGroup.resource_id = Trail._logs_loggroup_id
            LEFT JOIN aws_logs_metricfilter AS MetricFilter
              ON MetricFilter._loggroup_id = LogGroup.resource_id
            LEFT JOIN aws_logs_metricfilter_metric AS filter2metric
              ON filter2metric.metricfilter_id = MetricFilter.resource_id
            LEFT JOIN aws_logs_metric AS Metric
              ON filter2metric.metric_id = Metric.resource_id
            LEFT JOIN aws_cloudwatch_metricalarm AS Alarm
              ON Alarm._logs_metric_id = Metric.resource_id
            LEFT JOIN aws_cloudwatch_metricalarm_sns_topic AS Alarm2Topic
              ON Alarm2Topic.metricalarm_id = Alarm.resource_id
            LEFT JOIN aws_sns_topic AS Topic
              ON Alarm2Topic.topic_id = Topic.resource_id,
            LATERAL jsonb_array_elements(Trail.eventselectors) AS Selector
          WHERE
            Trail.provider_account_id = :provider_account_id
            AND Trail.ismultiregiontrail = True
            AND Trail.islogging = True
            AND (Selector.value #>> '{{IncludeManagementEvents}}')::bool = True
            AND Selector.value ->> 'ReadWriteType' = 'All'
            AND Alarm.actionsenabled = True
            AND aws_logs_metricfilter_pattern_matches(
              '{policy_filter}',
              MetricFilter.filterpattern
            )
          ) AS unauthorized_api_alerts
        ) AS unauthorized_api_alert_count
      WHERE
        count = 0
      '''

  def _contextualize_failure(self, row: Any) -> str:
    return 'Could not find a live alert for Route Table changes'


class AlertOnVPCChanges(Check):
  '''Benchmark 3.14'''
  benchmark = '3.14'
  severity = 'low'
  region = 'global'

  def _sql(self) -> str:
    or_filters = [
        '($.eventName = CreateVpc)', '($.eventName = DeleteVpc)',
        '($.eventName = ModifyVpcAttribute)',
        '($.eventName = AcceptVpcPeeringConnection)',
        '($.eventName = CreateVpcPeeringConnection)',
        '($.eventName = DeleteVpcPeeringConnection)',
        '($.eventName = RejectVpcPeeringConnection)',
        '($.eventName = AttachClassicLinkVpc)',
        '($.eventName = DetachClassicLinkVpc)',
        '($.eventName = DisableVpcClassicLink)',
        '($.eventName = EnableVpcClassicLink)'
    ]

    policy_filter = f'{{ {" || ".join(or_filters)} }}'
    return f'''
      SELECT 1 FROM (
        SELECT
          COUNT(*) AS count
        FROM (
          SELECT
            Trail.uri,
            Metric.uri,
            Alarm.uri,
            Topic.subscriptionsconfirmed
          FROM
            aws_cloudtrail_trail AS Trail
            LEFT JOIN aws_logs_loggroup AS LogGroup
              ON LogGroup.resource_id = Trail._logs_loggroup_id
            LEFT JOIN aws_logs_metricfilter AS MetricFilter
              ON MetricFilter._loggroup_id = LogGroup.resource_id
            LEFT JOIN aws_logs_metricfilter_metric AS filter2metric
              ON filter2metric.metricfilter_id = MetricFilter.resource_id
            LEFT JOIN aws_logs_metric AS Metric
              ON filter2metric.metric_id = Metric.resource_id
            LEFT JOIN aws_cloudwatch_metricalarm AS Alarm
              ON Alarm._logs_metric_id = Metric.resource_id
            LEFT JOIN aws_cloudwatch_metricalarm_sns_topic AS Alarm2Topic
              ON Alarm2Topic.metricalarm_id = Alarm.resource_id
            LEFT JOIN aws_sns_topic AS Topic
              ON Alarm2Topic.topic_id = Topic.resource_id,
            LATERAL jsonb_array_elements(Trail.eventselectors) AS Selector
          WHERE
            Trail.provider_account_id = :provider_account_id
            AND Trail.ismultiregiontrail = True
            AND Trail.islogging = True
            AND (Selector.value #>> '{{IncludeManagementEvents}}')::bool = True
            AND Selector.value ->> 'ReadWriteType' = 'All'
            AND Alarm.actionsenabled = True
            AND aws_logs_metricfilter_pattern_matches(
              '{policy_filter}',
              MetricFilter.filterpattern
            )
          ) AS unauthorized_api_alerts
        ) AS unauthorized_api_alert_count
      WHERE
        count = 0
      '''

  def _contextualize_failure(self, row: Any) -> str:
    return 'Could not find a live alert for VPC changes'


class NoSSHFromEverywhere(Check):
  '''Benchmark 4.1'''
  benchmark = '4.1'
  severity = 'low'
  region = '*'

  def _sql(self) -> str:
    return '''
      SELECT
        DISTINCT(SG.uri)
      FROM
        aws_ec2_securitygroup AS SG
        CROSS JOIN LATERAL jsonb_array_elements(SG.ippermissions) AS IPP
        CROSS JOIN LATERAL jsonb_array_elements(IPP->'IpRanges') AS R
      WHERE
        22 BETWEEN COALESCE((IPP ->> 'FromPort')::integer, 22) AND COALESCE((IPP.value ->> 'ToPort')::integer, 22)
        AND (R.value->>'CidrIp')::inet = inet '0.0.0.0/0'
        AND SG.provider_account_id = :provider_account_id
    '''

  def _contextualize_failure(self, row: Any) -> str:
    uri = row['uri']
    return f'Security Group {uri} allows SSH access from anywhere'


class NoRDPFromEverywhere(Check):
  '''Benchmark 4.2'''
  benchmark = '4.2'
  severity = 'low'
  region = '*'

  def _sql(self) -> str:
    return '''
      SELECT
        SG.uri
      FROM
        aws_ec2_securitygroup AS SG
        CROSS JOIN LATERAL jsonb_array_elements(SG.ippermissions) AS IPP
        CROSS JOIN LATERAL jsonb_array_elements(IPP->'IpRanges') AS R
      WHERE
        3389 BETWEEN COALESCE((IPP ->> 'FromPort')::integer, 3389) AND COALESCE((IPP.value ->> 'ToPort')::integer, 3389)
        AND (R.value->>'CidrIp')::inet = inet '0.0.0.0/0'
        AND SG.provider_account_id = :provider_account_id
    '''

  def _contextualize_failure(self, row: Any) -> str:
    uri = row['uri']
    return f'Security Group {uri} allows Remote Desktop access from anywhere'


class DefaultSecurityGroupAllowsNothing(Check):
  '''Benchmark 4.3'''
  benchmark = '4.3'
  severity = 'low'
  region = '*'

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
    ip_ranges = row['allowed_ip_ranges']
    return f'Default Security Group ({sg}) for VPC {vpc} allows connections from {ip_ranges}'


# TODO: consider mapping between vpcs with a join table
class ReviewPeeringConnections(Info):
  '''Benchmark 4.4'''
  benchmark = '4.4'
  severity = 'low'
  region = '*'

  def _sql(self) -> str:
    return '''
      SELECT
        RT.uri,
        (Route.value ->> 'DestinationCidrBlock')::inet AS destination,
        Route.value ->> 'GatewayId' AS gateway
      FROM
        aws_ec2_routetable AS RT
        CROSS JOIN LATERAL jsonb_array_elements(RT.routes) AS Route
      WHERE
        RT.provider_account_id = :provider_account_id
        AND Route.value->> 'State' = 'active'
        AND Route.value ->> 'GatewayId' LIKE 'pcx-%'
    '''

  def _contextualize_results(self, rows: List[Any]) -> str:
    if len(rows) == 0:
      return 'No peering connections found'
    else:
      return super()._contextualize_results(rows)

  def _contextualize_result(self, row: Any) -> str:
    uri = row['uri']
    destination = row['destination']
    gateway = row['gateway']
    return f'Verify that route table {uri} is scoped as narrowly as possible. It currently routes via {gateway} to {destination}'


def run(db: Session, provider_account: ProviderAccount):
  # 1
  RootAccountUsage().run(db, provider_account.id)
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
  RootAccountHasHardwareMFA().run(db, provider_account.id)
  SecurityQuestionsRegistered().run(db, provider_account.id)
  NoPoliciesAttachedToUsers().run(db, provider_account.id)
  ContactInfoUpToDate().run(db, provider_account.id)
  SecurityContactInfoUpToDate().run(db, provider_account.id)
  InstancesUseInstanceProfiles().run(db, provider_account.id)
  SupportPolicyExists().run(db, provider_account.id)
  NoAutoCreatedAccessKeys().run(db, provider_account.id)
  NoAdminAccess().run(db, provider_account.id)
  # 2
  CloudtrailEnabledEverywhere().run(db, provider_account.id)
  CloudtrailLogFileValidationEnabled().run(db, provider_account.id)
  CloudtrailBucketIsPrivate().run(db, provider_account.id)
  CloudwatchLogsUpToDate().run(db, provider_account.id)
  ConfigEnabledInAllRegions().run(db, provider_account.id)
  CloudtrailBucketLoggingIsEnable().run(db, provider_account.id)
  CloudtrailEncryptedAtRestWithCMK().run(db, provider_account.id)
  CustomerKeysHaveRotationEnabled().run(db, provider_account.id)
  VPCsHaveFlowLogs().run(db, provider_account.id)
  # 3 - Complete
  AlertOnUnauthorizedAPICalls().run(db, provider_account.id)
  AlertOnNoMFAConsoleSignin().run(db, provider_account.id)
  AlertOnRootAccountUsage().run(db, provider_account.id)
  AlertOnIAMPolicyChanges().run(db, provider_account.id)
  AlertOnCloudTrailConfigurationChanges().run(db, provider_account.id)
  AlertOnFailedConsoleAuthentication().run(db, provider_account.id)
  AlertOnCMKDisablingOrScheduledDeletion().run(db, provider_account.id)
  AlertOnS3BucketPolicyChanges().run(db, provider_account.id)
  AlertOnConfigConfigurationChanges().run(db, provider_account.id)
  AlertOnSecurityGroupChanges().run(db, provider_account.id)
  AlertOnNetworkACLChanges().run(db, provider_account.id)
  AlertOnNetworkGatewayChanges().run(db, provider_account.id)
  AlertOnRouteTableChanges().run(db, provider_account.id)
  AlertOnVPCChanges().run(db, provider_account.id)
  # 4
  NoSSHFromEverywhere().run(db, provider_account.id)
  NoRDPFromEverywhere().run(db, provider_account.id)
  DefaultSecurityGroupAllowsNothing().run(db, provider_account.id)
  ReviewPeeringConnections().run(db, provider_account.id)
DROP MATERIALIZED VIEW IF EXISTS aws_iam_policy CASCADE;

CREATE MATERIALIZED VIEW aws_iam_policy AS
SELECT
  R.id AS resource_id,
  R.uri,
  R.provider_account_id,
  policyname.attr_value #>> '{}' AS policyname,
  policyid.attr_value #>> '{}' AS policyid,
  arn.attr_value #>> '{}' AS arn,
  path.attr_value #>> '{}' AS path,
  defaultversionid.attr_value #>> '{}' AS defaultversionid,
  (attachmentcount.attr_value #>> '{}')::integer AS attachmentcount,
  (permissionsboundaryusagecount.attr_value #>> '{}')::integer AS permissionsboundaryusagecount,
  (isattachable.attr_value #>> '{}')::boolean AS isattachable,
  description.attr_value #>> '{}' AS description,
  (TO_TIMESTAMP(createdate.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS createdate,
  (TO_TIMESTAMP(updatedate.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS updatedate,
  policygroups.attr_value::jsonb AS policygroups,
  policyusers.attr_value::jsonb AS policyusers,
  policyroles.attr_value::jsonb AS policyroles,
  versions.attr_value::jsonb AS versions,
  
    _default_policyversion_id.target_id AS _default_policyversion_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN resource_attribute AS policyname
    ON policyname.resource_id = R.id
    AND policyname.type = 'provider'
    AND lower(policyname.attr_name) = 'policyname'
  LEFT JOIN resource_attribute AS policyid
    ON policyid.resource_id = R.id
    AND policyid.type = 'provider'
    AND lower(policyid.attr_name) = 'policyid'
  LEFT JOIN resource_attribute AS arn
    ON arn.resource_id = R.id
    AND arn.type = 'provider'
    AND lower(arn.attr_name) = 'arn'
  LEFT JOIN resource_attribute AS path
    ON path.resource_id = R.id
    AND path.type = 'provider'
    AND lower(path.attr_name) = 'path'
  LEFT JOIN resource_attribute AS defaultversionid
    ON defaultversionid.resource_id = R.id
    AND defaultversionid.type = 'provider'
    AND lower(defaultversionid.attr_name) = 'defaultversionid'
  LEFT JOIN resource_attribute AS attachmentcount
    ON attachmentcount.resource_id = R.id
    AND attachmentcount.type = 'provider'
    AND lower(attachmentcount.attr_name) = 'attachmentcount'
  LEFT JOIN resource_attribute AS permissionsboundaryusagecount
    ON permissionsboundaryusagecount.resource_id = R.id
    AND permissionsboundaryusagecount.type = 'provider'
    AND lower(permissionsboundaryusagecount.attr_name) = 'permissionsboundaryusagecount'
  LEFT JOIN resource_attribute AS isattachable
    ON isattachable.resource_id = R.id
    AND isattachable.type = 'provider'
    AND lower(isattachable.attr_name) = 'isattachable'
  LEFT JOIN resource_attribute AS description
    ON description.resource_id = R.id
    AND description.type = 'provider'
    AND lower(description.attr_name) = 'description'
  LEFT JOIN resource_attribute AS createdate
    ON createdate.resource_id = R.id
    AND createdate.type = 'provider'
    AND lower(createdate.attr_name) = 'createdate'
  LEFT JOIN resource_attribute AS updatedate
    ON updatedate.resource_id = R.id
    AND updatedate.type = 'provider'
    AND lower(updatedate.attr_name) = 'updatedate'
  LEFT JOIN resource_attribute AS policygroups
    ON policygroups.resource_id = R.id
    AND policygroups.type = 'provider'
    AND lower(policygroups.attr_name) = 'policygroups'
  LEFT JOIN resource_attribute AS policyusers
    ON policyusers.resource_id = R.id
    AND policyusers.type = 'provider'
    AND lower(policyusers.attr_name) = 'policyusers'
  LEFT JOIN resource_attribute AS policyroles
    ON policyroles.resource_id = R.id
    AND policyroles.type = 'provider'
    AND lower(policyroles.attr_name) = 'policyroles'
  LEFT JOIN resource_attribute AS versions
    ON versions.resource_id = R.id
    AND versions.type = 'provider'
    AND lower(versions.attr_name) = 'versions'
  LEFT JOIN (
    SELECT
      _aws_iam_policyversion_relation.resource_id AS resource_id,
      _aws_iam_policyversion.id AS target_id
    FROM
      resource_relation AS _aws_iam_policyversion_relation
      INNER JOIN resource AS _aws_iam_policyversion
        ON _aws_iam_policyversion_relation.target_id = _aws_iam_policyversion.id
        AND _aws_iam_policyversion.provider_type = 'PolicyVersion'
        AND _aws_iam_policyversion.service = 'iam'
    WHERE
      _aws_iam_policyversion_relation.relation = 'default-version'
  ) AS _default_policyversion_id ON _default_policyversion_id.resource_id = R.id
  LEFT JOIN (
    SELECT
      _aws_organizations_account_relation.resource_id AS resource_id,
      _aws_organizations_account.id AS target_id
    FROM
      resource_relation AS _aws_organizations_account_relation
      INNER JOIN resource AS _aws_organizations_account
        ON _aws_organizations_account_relation.target_id = _aws_organizations_account.id
        AND _aws_organizations_account.provider_type = 'Account'
        AND _aws_organizations_account.service = 'organizations'
    WHERE
      _aws_organizations_account_relation.relation = 'in'
  ) AS _account_id ON _account_id.resource_id = R.id
  WHERE
  PA.provider = 'aws'
  AND LOWER(R.provider_type) = 'policy'
  AND R.service = 'iam'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_iam_policy;

COMMENT ON MATERIALIZED VIEW aws_iam_policy IS 'iam policy resources and their associated attributes.';



DROP MATERIALIZED VIEW IF EXISTS aws_iam_policy_group CASCADE;

CREATE MATERIALIZED VIEW aws_iam_policy_group AS
SELECT
  aws_iam_policy.id AS policy_id,
  aws_iam_group.id AS group_id
FROM
  resource AS aws_iam_policy
  INNER JOIN resource_relation AS RR
    ON RR.resource_id = aws_iam_policy.id
    AND RR.relation = 'manages'
  INNER JOIN resource AS aws_iam_group
    ON aws_iam_group.id = RR.target_id
    AND aws_iam_group.provider_type = 'Group'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_iam_policy_group;


DROP MATERIALIZED VIEW IF EXISTS aws_iam_policy_role CASCADE;

CREATE MATERIALIZED VIEW aws_iam_policy_role AS
SELECT
  aws_iam_policy.id AS policy_id,
  aws_iam_role.id AS role_id
FROM
  resource AS aws_iam_policy
  INNER JOIN resource_relation AS RR
    ON RR.resource_id = aws_iam_policy.id
    AND RR.relation = 'manages'
  INNER JOIN resource AS aws_iam_role
    ON aws_iam_role.id = RR.target_id
    AND aws_iam_role.provider_type = 'Role'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_iam_policy_role;


DROP MATERIALIZED VIEW IF EXISTS aws_iam_policy_user CASCADE;

CREATE MATERIALIZED VIEW aws_iam_policy_user AS
SELECT
  aws_iam_policy.id AS policy_id,
  aws_iam_user.id AS user_id
FROM
  resource AS aws_iam_policy
  INNER JOIN resource_relation AS RR
    ON RR.resource_id = aws_iam_policy.id
    AND RR.relation = 'manages'
  INNER JOIN resource AS aws_iam_user
    ON aws_iam_user.id = RR.target_id
    AND aws_iam_user.provider_type = 'User'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_iam_policy_user;

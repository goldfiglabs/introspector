DROP MATERIALIZED VIEW IF EXISTS aws_iam_policy CASCADE;

CREATE MATERIALIZED VIEW aws_iam_policy AS
WITH attrs AS (
  SELECT
    R.id,
    LOWER(RA.attr_name) AS attr_name,
    RA.attr_value
  FROM
    resource AS R
    INNER JOIN resource_attribute AS RA
      ON RA.resource_id = R.id
  WHERE
    RA.type = 'provider'
)
SELECT
  R.id AS resource_id,
  R.uri,
  R.provider_account_id,
  policyname.attr_value #>> '{}' AS policyname,
  policyid.attr_value #>> '{}' AS policyid,
  arn.attr_value #>> '{}' AS arn,
  path.attr_value #>> '{}' AS path,
  defaultversionid.attr_value #>> '{}' AS defaultversionid,
  attachmentcount.attr_value::integer AS attachmentcount,
  permissionsboundaryusagecount.attr_value::integer AS permissionsboundaryusagecount,
  isattachable.attr_value::boolean AS isattachable,
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
  LEFT JOIN attrs AS policyname
    ON policyname.id = R.id
    AND policyname.attr_name = 'policyname'
  LEFT JOIN attrs AS policyid
    ON policyid.id = R.id
    AND policyid.attr_name = 'policyid'
  LEFT JOIN attrs AS arn
    ON arn.id = R.id
    AND arn.attr_name = 'arn'
  LEFT JOIN attrs AS path
    ON path.id = R.id
    AND path.attr_name = 'path'
  LEFT JOIN attrs AS defaultversionid
    ON defaultversionid.id = R.id
    AND defaultversionid.attr_name = 'defaultversionid'
  LEFT JOIN attrs AS attachmentcount
    ON attachmentcount.id = R.id
    AND attachmentcount.attr_name = 'attachmentcount'
  LEFT JOIN attrs AS permissionsboundaryusagecount
    ON permissionsboundaryusagecount.id = R.id
    AND permissionsboundaryusagecount.attr_name = 'permissionsboundaryusagecount'
  LEFT JOIN attrs AS isattachable
    ON isattachable.id = R.id
    AND isattachable.attr_name = 'isattachable'
  LEFT JOIN attrs AS description
    ON description.id = R.id
    AND description.attr_name = 'description'
  LEFT JOIN attrs AS createdate
    ON createdate.id = R.id
    AND createdate.attr_name = 'createdate'
  LEFT JOIN attrs AS updatedate
    ON updatedate.id = R.id
    AND updatedate.attr_name = 'updatedate'
  LEFT JOIN attrs AS policygroups
    ON policygroups.id = R.id
    AND policygroups.attr_name = 'policygroups'
  LEFT JOIN attrs AS policyusers
    ON policyusers.id = R.id
    AND policyusers.attr_name = 'policyusers'
  LEFT JOIN attrs AS policyroles
    ON policyroles.id = R.id
    AND policyroles.attr_name = 'policyroles'
  LEFT JOIN attrs AS versions
    ON versions.id = R.id
    AND versions.attr_name = 'versions'
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

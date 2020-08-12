DROP MATERIALIZED VIEW IF EXISTS aws_iam_group CASCADE;

CREATE MATERIALIZED VIEW aws_iam_group AS
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
  path.attr_value #>> '{}' AS path,
  groupname.attr_value #>> '{}' AS groupname,
  groupid.attr_value #>> '{}' AS groupid,
  arn.attr_value #>> '{}' AS arn,
  (TO_TIMESTAMP(createdate.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS createdate,
  policylist.attr_value::jsonb AS policylist,
  attachedpolicies.attr_value::jsonb AS attachedpolicies,
  
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN attrs AS path
    ON path.id = R.id
    AND path.attr_name = 'path'
  LEFT JOIN attrs AS groupname
    ON groupname.id = R.id
    AND groupname.attr_name = 'groupname'
  LEFT JOIN attrs AS groupid
    ON groupid.id = R.id
    AND groupid.attr_name = 'groupid'
  LEFT JOIN attrs AS arn
    ON arn.id = R.id
    AND arn.attr_name = 'arn'
  LEFT JOIN attrs AS createdate
    ON createdate.id = R.id
    AND createdate.attr_name = 'createdate'
  LEFT JOIN attrs AS policylist
    ON policylist.id = R.id
    AND policylist.attr_name = 'policylist'
  LEFT JOIN attrs AS attachedpolicies
    ON attachedpolicies.id = R.id
    AND attachedpolicies.attr_name = 'attachedpolicies'
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
  AND LOWER(R.provider_type) = 'group'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_iam_group;

COMMENT ON MATERIALIZED VIEW aws_iam_group IS 'iam group resources and their associated attributes.';



DROP MATERIALIZED VIEW IF EXISTS aws_iam_group_user CASCADE;

CREATE MATERIALIZED VIEW aws_iam_group_user AS
SELECT
  aws_iam_group.id AS group_id,
  aws_iam_user.id AS user_id
FROM
  resource AS aws_iam_group
  INNER JOIN resource_relation AS RR
    ON RR.resource_id = aws_iam_group.id
    AND RR.relation = 'contains'
  INNER JOIN resource AS aws_iam_user
    ON aws_iam_user.id = RR.target_id
    AND aws_iam_user.provider_type = 'User'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_iam_group_user;

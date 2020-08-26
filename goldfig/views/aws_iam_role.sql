DROP MATERIALIZED VIEW IF EXISTS aws_iam_role CASCADE;

CREATE MATERIALIZED VIEW aws_iam_role AS
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
  rolename.attr_value #>> '{}' AS rolename,
  roleid.attr_value #>> '{}' AS roleid,
  arn.attr_value #>> '{}' AS arn,
  (TO_TIMESTAMP(createdate.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS createdate,
  assumerolepolicydocument.attr_value #>> '{}' AS assumerolepolicydocument,
  description.attr_value #>> '{}' AS description,
  (maxsessionduration.attr_value #>> '{}')::integer AS maxsessionduration,
  permissionsboundary.attr_value::jsonb AS permissionsboundary,
  tags.attr_value::jsonb AS tags,
  rolelastused.attr_value::jsonb AS rolelastused,
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
  LEFT JOIN attrs AS rolename
    ON rolename.id = R.id
    AND rolename.attr_name = 'rolename'
  LEFT JOIN attrs AS roleid
    ON roleid.id = R.id
    AND roleid.attr_name = 'roleid'
  LEFT JOIN attrs AS arn
    ON arn.id = R.id
    AND arn.attr_name = 'arn'
  LEFT JOIN attrs AS createdate
    ON createdate.id = R.id
    AND createdate.attr_name = 'createdate'
  LEFT JOIN attrs AS assumerolepolicydocument
    ON assumerolepolicydocument.id = R.id
    AND assumerolepolicydocument.attr_name = 'assumerolepolicydocument'
  LEFT JOIN attrs AS description
    ON description.id = R.id
    AND description.attr_name = 'description'
  LEFT JOIN attrs AS maxsessionduration
    ON maxsessionduration.id = R.id
    AND maxsessionduration.attr_name = 'maxsessionduration'
  LEFT JOIN attrs AS permissionsboundary
    ON permissionsboundary.id = R.id
    AND permissionsboundary.attr_name = 'permissionsboundary'
  LEFT JOIN attrs AS tags
    ON tags.id = R.id
    AND tags.attr_name = 'tags'
  LEFT JOIN attrs AS rolelastused
    ON rolelastused.id = R.id
    AND rolelastused.attr_name = 'rolelastused'
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
  AND LOWER(R.provider_type) = 'role'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_iam_role;

COMMENT ON MATERIALIZED VIEW aws_iam_role IS 'iam role resources and their associated attributes.';


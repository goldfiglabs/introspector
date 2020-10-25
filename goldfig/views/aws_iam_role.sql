DROP MATERIALIZED VIEW IF EXISTS aws_iam_role CASCADE;

CREATE MATERIALIZED VIEW aws_iam_role AS
SELECT
  R.id AS resource_id,
  R.uri,
  R.provider_account_id,
  path.attr_value #>> '{}' AS path,
  rolename.attr_value #>> '{}' AS rolename,
  roleid.attr_value #>> '{}' AS roleid,
  arn.attr_value #>> '{}' AS arn,
  (TO_TIMESTAMP(createdate.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS createdate,
  assumerolepolicydocument.attr_value::jsonb AS assumerolepolicydocument,
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
  LEFT JOIN resource_attribute AS path
    ON path.resource_id = R.id
    AND path.type = 'provider'
    AND lower(path.attr_name) = 'path'
  LEFT JOIN resource_attribute AS rolename
    ON rolename.resource_id = R.id
    AND rolename.type = 'provider'
    AND lower(rolename.attr_name) = 'rolename'
  LEFT JOIN resource_attribute AS roleid
    ON roleid.resource_id = R.id
    AND roleid.type = 'provider'
    AND lower(roleid.attr_name) = 'roleid'
  LEFT JOIN resource_attribute AS arn
    ON arn.resource_id = R.id
    AND arn.type = 'provider'
    AND lower(arn.attr_name) = 'arn'
  LEFT JOIN resource_attribute AS createdate
    ON createdate.resource_id = R.id
    AND createdate.type = 'provider'
    AND lower(createdate.attr_name) = 'createdate'
  LEFT JOIN resource_attribute AS assumerolepolicydocument
    ON assumerolepolicydocument.resource_id = R.id
    AND assumerolepolicydocument.type = 'provider'
    AND lower(assumerolepolicydocument.attr_name) = 'assumerolepolicydocument'
  LEFT JOIN resource_attribute AS description
    ON description.resource_id = R.id
    AND description.type = 'provider'
    AND lower(description.attr_name) = 'description'
  LEFT JOIN resource_attribute AS maxsessionduration
    ON maxsessionduration.resource_id = R.id
    AND maxsessionduration.type = 'provider'
    AND lower(maxsessionduration.attr_name) = 'maxsessionduration'
  LEFT JOIN resource_attribute AS permissionsboundary
    ON permissionsboundary.resource_id = R.id
    AND permissionsboundary.type = 'provider'
    AND lower(permissionsboundary.attr_name) = 'permissionsboundary'
  LEFT JOIN resource_attribute AS tags
    ON tags.resource_id = R.id
    AND tags.type = 'provider'
    AND lower(tags.attr_name) = 'tags'
  LEFT JOIN resource_attribute AS rolelastused
    ON rolelastused.resource_id = R.id
    AND rolelastused.type = 'provider'
    AND lower(rolelastused.attr_name) = 'rolelastused'
  LEFT JOIN resource_attribute AS policylist
    ON policylist.resource_id = R.id
    AND policylist.type = 'provider'
    AND lower(policylist.attr_name) = 'policylist'
  LEFT JOIN resource_attribute AS attachedpolicies
    ON attachedpolicies.resource_id = R.id
    AND attachedpolicies.type = 'provider'
    AND lower(attachedpolicies.attr_name) = 'attachedpolicies'
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
  AND R.provider_type = 'Role'
  AND R.service = 'iam'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_iam_role;

COMMENT ON MATERIALIZED VIEW aws_iam_role IS 'iam Role resources and their associated attributes.';


WITH attrs AS (
  SELECT
    resource_id,
    jsonb_object_agg(attr_name, attr_value) FILTER (WHERE type = 'provider') AS provider,
    jsonb_object_agg(attr_name, attr_value) FILTER (WHERE type = 'Metadata') AS metadata
  FROM
    resource_attribute
  WHERE
    provider_account_id = :provider_account_id
  GROUP BY resource_id
)
INSERT INTO aws_iam_role (
  _id,
  uri,
  provider_account_id,
  path,
  rolename,
  roleid,
  arn,
  createdate,
  assumerolepolicydocument,
  description,
  maxsessionduration,
  permissionsboundary,
  tags,
  rolelastused,
  policylist,
  attachedpolicies,
  _tags,
  _policy,
  _account_id
)
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  attrs.provider ->> 'Path' AS path,
  attrs.provider ->> 'RoleName' AS rolename,
  attrs.provider ->> 'RoleId' AS roleid,
  attrs.provider ->> 'Arn' AS arn,
  (TO_TIMESTAMP(attrs.provider ->> 'CreateDate', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS createdate,
  attrs.provider -> 'AssumeRolePolicyDocument' AS assumerolepolicydocument,
  attrs.provider ->> 'Description' AS description,
  (attrs.provider ->> 'MaxSessionDuration')::integer AS maxsessionduration,
  attrs.provider -> 'PermissionsBoundary' AS permissionsboundary,
  attrs.provider -> 'Tags' AS tags,
  attrs.provider -> 'RoleLastUsed' AS rolelastused,
  attrs.provider -> 'PolicyList' AS policylist,
  attrs.provider -> 'AttachedPolicies' AS attachedpolicies,
  attrs.metadata -> 'Tags' AS tags,
  attrs.metadata -> 'Policy' AS policy,
  
    _account_id.target_id AS _account_id
FROM
  resource AS R
  LEFT JOIN attrs ON
    attrs.resource_id = R.id
  LEFT JOIN (
    SELECT
      unique_account_mapping.resource_id,
      unique_account_mapping.target_ids[1] as target_id
    FROM
      (
        SELECT
          ARRAY_AGG(_aws_organizations_account_relation.target_id) AS target_ids,
          _aws_organizations_account_relation.resource_id
        FROM
          resource AS _aws_organizations_account
          INNER JOIN resource_relation AS _aws_organizations_account_relation
            ON _aws_organizations_account_relation.target_id = _aws_organizations_account.id
        WHERE
          _aws_organizations_account.provider_type = 'Account'
          AND _aws_organizations_account.service = 'organizations'
          AND _aws_organizations_account.provider_account_id = :provider_account_id
          AND _aws_organizations_account_relation.relation = 'in'
          AND _aws_organizations_account_relation.provider_account_id = :provider_account_id
        GROUP BY _aws_organizations_account_relation.resource_id
        HAVING COUNT(*) = 1
      ) AS unique_account_mapping
  ) AS _account_id ON _account_id.resource_id = R.id
  WHERE
  R.provider_account_id = :provider_account_id
  AND R.provider_type = 'Role'
  AND R.service = 'iam'
ON CONFLICT (_id) DO UPDATE
SET
    Path = EXCLUDED.Path,
    RoleName = EXCLUDED.RoleName,
    RoleId = EXCLUDED.RoleId,
    Arn = EXCLUDED.Arn,
    CreateDate = EXCLUDED.CreateDate,
    AssumeRolePolicyDocument = EXCLUDED.AssumeRolePolicyDocument,
    Description = EXCLUDED.Description,
    MaxSessionDuration = EXCLUDED.MaxSessionDuration,
    PermissionsBoundary = EXCLUDED.PermissionsBoundary,
    Tags = EXCLUDED.Tags,
    RoleLastUsed = EXCLUDED.RoleLastUsed,
    PolicyList = EXCLUDED.PolicyList,
    AttachedPolicies = EXCLUDED.AttachedPolicies,
    _tags = EXCLUDED._tags,
    _policy = EXCLUDED._policy,
    _account_id = EXCLUDED._account_id
  ;


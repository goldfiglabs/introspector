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
INSERT INTO aws_iam_policy (
  _id,
  uri,
  provider_account_id,
  policyname,
  policyid,
  arn,
  path,
  defaultversionid,
  attachmentcount,
  permissionsboundaryusagecount,
  isattachable,
  description,
  createdate,
  updatedate,
  policygroups,
  policyusers,
  policyroles,
  versions,
  _account_id
)
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  attrs.provider ->> 'PolicyName' AS policyname,
  attrs.provider ->> 'PolicyId' AS policyid,
  attrs.provider ->> 'Arn' AS arn,
  attrs.provider ->> 'Path' AS path,
  attrs.provider ->> 'DefaultVersionId' AS defaultversionid,
  (attrs.provider ->> 'AttachmentCount')::integer AS attachmentcount,
  (attrs.provider ->> 'PermissionsBoundaryUsageCount')::integer AS permissionsboundaryusagecount,
  (attrs.provider ->> 'IsAttachable')::boolean AS isattachable,
  attrs.provider ->> 'Description' AS description,
  (TO_TIMESTAMP(attrs.provider ->> 'CreateDate', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS createdate,
  (TO_TIMESTAMP(attrs.provider ->> 'UpdateDate', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS updatedate,
  attrs.provider -> 'PolicyGroups' AS policygroups,
  attrs.provider -> 'PolicyUsers' AS policyusers,
  attrs.provider -> 'PolicyRoles' AS policyroles,
  attrs.provider -> 'Versions' AS versions,
  
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
          AND _aws_organizations_account_relation.provider_account_id = 8
        GROUP BY _aws_organizations_account_relation.resource_id
        HAVING COUNT(*) = 1
      ) AS unique_account_mapping
  ) AS _account_id ON _account_id.resource_id = R.id
  WHERE
  R.provider_account_id = :provider_account_id
  AND R.provider_type = 'Policy'
  AND R.service = 'iam'
ON CONFLICT (_id) DO UPDATE
SET
    PolicyName = EXCLUDED.PolicyName,
    PolicyId = EXCLUDED.PolicyId,
    Arn = EXCLUDED.Arn,
    Path = EXCLUDED.Path,
    DefaultVersionId = EXCLUDED.DefaultVersionId,
    AttachmentCount = EXCLUDED.AttachmentCount,
    PermissionsBoundaryUsageCount = EXCLUDED.PermissionsBoundaryUsageCount,
    IsAttachable = EXCLUDED.IsAttachable,
    Description = EXCLUDED.Description,
    CreateDate = EXCLUDED.CreateDate,
    UpdateDate = EXCLUDED.UpdateDate,
    PolicyGroups = EXCLUDED.PolicyGroups,
    PolicyUsers = EXCLUDED.PolicyUsers,
    PolicyRoles = EXCLUDED.PolicyRoles,
    Versions = EXCLUDED.Versions,
    _account_id = EXCLUDED._account_id
  ;



INSERT INTO aws_iam_policy_user
SELECT
  aws_iam_policy.id AS policy_id,
  aws_iam_user.id AS user_id,
  aws_iam_policy.provider_account_id AS provider_account_id
FROM
  resource AS aws_iam_policy
  INNER JOIN resource_relation AS RR
    ON RR.resource_id = aws_iam_policy.id
    AND RR.relation = 'manages'
  INNER JOIN resource AS aws_iam_user
    ON aws_iam_user.id = RR.target_id
    AND aws_iam_user.provider_type = 'User'
    AND aws_iam_user.service = 'iam'
    AND aws_iam_user.provider_account_id = :provider_account_id
  WHERE
    aws_iam_policy.provider_account_id = :provider_account_id
    AND aws_iam_policy.provider_type = 'Policy'
    AND aws_iam_policy.service = 'iam'
ON CONFLICT (policy_id, user_id)
DO NOTHING
;


INSERT INTO aws_iam_policy_role
SELECT
  aws_iam_policy.id AS policy_id,
  aws_iam_role.id AS role_id,
  aws_iam_policy.provider_account_id AS provider_account_id
FROM
  resource AS aws_iam_policy
  INNER JOIN resource_relation AS RR
    ON RR.resource_id = aws_iam_policy.id
    AND RR.relation = 'manages'
  INNER JOIN resource AS aws_iam_role
    ON aws_iam_role.id = RR.target_id
    AND aws_iam_role.provider_type = 'Role'
    AND aws_iam_role.service = 'iam'
    AND aws_iam_role.provider_account_id = :provider_account_id
  WHERE
    aws_iam_policy.provider_account_id = :provider_account_id
    AND aws_iam_policy.provider_type = 'Policy'
    AND aws_iam_policy.service = 'iam'
ON CONFLICT (policy_id, role_id)
DO NOTHING
;


INSERT INTO aws_iam_policy_group
SELECT
  aws_iam_policy.id AS policy_id,
  aws_iam_group.id AS group_id,
  aws_iam_policy.provider_account_id AS provider_account_id
FROM
  resource AS aws_iam_policy
  INNER JOIN resource_relation AS RR
    ON RR.resource_id = aws_iam_policy.id
    AND RR.relation = 'manages'
  INNER JOIN resource AS aws_iam_group
    ON aws_iam_group.id = RR.target_id
    AND aws_iam_group.provider_type = 'Group'
    AND aws_iam_group.service = 'iam'
    AND aws_iam_group.provider_account_id = :provider_account_id
  WHERE
    aws_iam_policy.provider_account_id = :provider_account_id
    AND aws_iam_policy.provider_type = 'Policy'
    AND aws_iam_policy.service = 'iam'
ON CONFLICT (policy_id, group_id)
DO NOTHING
;

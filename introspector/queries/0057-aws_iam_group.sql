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
INSERT INTO aws_iam_group (
  _id,
  uri,
  provider_account_id,
  path,
  groupname,
  groupid,
  arn,
  createdate,
  policylist,
  attachedpolicies,
  _account_id
)
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  attrs.provider ->> 'Path' AS path,
  attrs.provider ->> 'GroupName' AS groupname,
  attrs.provider ->> 'GroupId' AS groupid,
  attrs.provider ->> 'Arn' AS arn,
  (TO_TIMESTAMP(attrs.provider ->> 'CreateDate', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS createdate,
  attrs.provider -> 'PolicyList' AS policylist,
  attrs.provider -> 'AttachedPolicies' AS attachedpolicies,
  
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
  AND R.provider_type = 'Group'
  AND R.service = 'iam'
ON CONFLICT (_id) DO UPDATE
SET
    Path = EXCLUDED.Path,
    GroupName = EXCLUDED.GroupName,
    GroupId = EXCLUDED.GroupId,
    Arn = EXCLUDED.Arn,
    CreateDate = EXCLUDED.CreateDate,
    PolicyList = EXCLUDED.PolicyList,
    AttachedPolicies = EXCLUDED.AttachedPolicies,
    _account_id = EXCLUDED._account_id
  ;



INSERT INTO aws_iam_group_user
SELECT
  aws_iam_group.id AS group_id,
  aws_iam_user.id AS user_id,
  aws_iam_group.provider_account_id AS provider_account_id
FROM
  resource AS aws_iam_group
  INNER JOIN resource_relation AS RR
    ON RR.resource_id = aws_iam_group.id
    AND RR.relation = 'contains'
  INNER JOIN resource AS aws_iam_user
    ON aws_iam_user.id = RR.target_id
    AND aws_iam_user.provider_type = 'User'
    AND aws_iam_user.service = 'iam'
    AND aws_iam_user.provider_account_id = :provider_account_id
  WHERE
    aws_iam_group.provider_account_id = :provider_account_id
    AND aws_iam_group.provider_type = 'Group'
    AND aws_iam_group.service = 'iam'
ON CONFLICT (group_id, user_id)
DO NOTHING
;

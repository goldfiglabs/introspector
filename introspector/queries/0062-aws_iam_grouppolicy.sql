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
INSERT INTO aws_iam_grouppolicy (
  _id,
  uri,
  provider_account_id,
  groupname,
  policyname,
  policydocument,
  _group_id,_account_id
)
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  attrs.provider ->> 'GroupName' AS groupname,
  attrs.provider ->> 'PolicyName' AS policyname,
  attrs.provider -> 'PolicyDocument' AS policydocument,
  
    _group_id.target_id AS _group_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  LEFT JOIN attrs ON
    attrs.resource_id = R.id
  LEFT JOIN (
    SELECT
      _aws_iam_group_relation.resource_id AS resource_id,
      _aws_iam_group.id AS target_id
    FROM
      resource_relation AS _aws_iam_group_relation
      INNER JOIN resource AS _aws_iam_group
        ON _aws_iam_group_relation.target_id = _aws_iam_group.id
        AND _aws_iam_group.provider_type = 'Group'
        AND _aws_iam_group.service = 'iam'
        AND _aws_iam_group.provider_account_id = :provider_account_id
    WHERE
      _aws_iam_group_relation.relation = 'manages'
      AND _aws_iam_group_relation.provider_account_id = :provider_account_id
  ) AS _group_id ON _group_id.resource_id = R.id
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
  AND R.provider_type = 'GroupPolicy'
  AND R.service = 'iam'
ON CONFLICT (_id) DO UPDATE
SET
    GroupName = EXCLUDED.GroupName,
    PolicyName = EXCLUDED.PolicyName,
    PolicyDocument = EXCLUDED.PolicyDocument,
    _group_id = EXCLUDED._group_id,
    _account_id = EXCLUDED._account_id
  ;


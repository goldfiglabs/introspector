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
INSERT INTO aws_iam_policyversion (
  _id,
  uri,
  provider_account_id,
  document,
  versionid,
  isdefaultversion,
  createdate,
  _policy_id,_account_id
)
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  attrs.provider -> 'Document' AS document,
  attrs.provider ->> 'VersionId' AS versionid,
  (attrs.provider ->> 'IsDefaultVersion')::boolean AS isdefaultversion,
  (TO_TIMESTAMP(attrs.provider ->> 'CreateDate', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS createdate,
  
    _policy_id.target_id AS _policy_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  LEFT JOIN attrs ON
    attrs.resource_id = R.id
  LEFT JOIN (
    SELECT
      _aws_iam_policy_relation.resource_id AS resource_id,
      _aws_iam_policy.id AS target_id
    FROM
      resource_relation AS _aws_iam_policy_relation
      INNER JOIN resource AS _aws_iam_policy
        ON _aws_iam_policy_relation.target_id = _aws_iam_policy.id
        AND _aws_iam_policy.provider_type = 'Policy'
        AND _aws_iam_policy.service = 'iam'
        AND _aws_iam_policy.provider_account_id = :provider_account_id
    WHERE
      _aws_iam_policy_relation.relation = 'contains-version'
      AND _aws_iam_policy_relation.provider_account_id = :provider_account_id
  ) AS _policy_id ON _policy_id.resource_id = R.id
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
  AND R.provider_type = 'PolicyVersion'
  AND R.service = 'iam'
ON CONFLICT (_id) DO UPDATE
SET
    Document = EXCLUDED.Document,
    VersionId = EXCLUDED.VersionId,
    IsDefaultVersion = EXCLUDED.IsDefaultVersion,
    CreateDate = EXCLUDED.CreateDate,
    _policy_id = EXCLUDED._policy_id,
    _account_id = EXCLUDED._account_id
  ;


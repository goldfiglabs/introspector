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
INSERT INTO aws_iam_rootaccount (
  _id,
  uri,
  provider_account_id,
  arn,
  has_virtual_mfa,
  mfa_active,
  access_key_1_active,
  access_key_2_active,
  cert_1_active,
  cert_2_active,
  password_last_used,
  _account_id
)
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  attrs.provider ->> 'Arn' AS arn,
  (attrs.provider ->> 'has_virtual_mfa')::boolean AS has_virtual_mfa,
  (attrs.provider ->> 'mfa_active')::boolean AS mfa_active,
  (attrs.provider ->> 'access_key_1_active')::boolean AS access_key_1_active,
  (attrs.provider ->> 'access_key_2_active')::boolean AS access_key_2_active,
  (attrs.provider ->> 'cert_1_active')::boolean AS cert_1_active,
  (attrs.provider ->> 'cert_2_active')::boolean AS cert_2_active,
  (TO_TIMESTAMP(attrs.provider ->> 'password_last_used', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS password_last_used,
  
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
  AND R.provider_type = 'RootAccount'
  AND R.service = 'iam'
ON CONFLICT (_id) DO UPDATE
SET
    Arn = EXCLUDED.Arn,
    has_virtual_mfa = EXCLUDED.has_virtual_mfa,
    mfa_active = EXCLUDED.mfa_active,
    access_key_1_active = EXCLUDED.access_key_1_active,
    access_key_2_active = EXCLUDED.access_key_2_active,
    cert_1_active = EXCLUDED.cert_1_active,
    cert_2_active = EXCLUDED.cert_2_active,
    password_last_used = EXCLUDED.password_last_used,
    _account_id = EXCLUDED._account_id
  ;


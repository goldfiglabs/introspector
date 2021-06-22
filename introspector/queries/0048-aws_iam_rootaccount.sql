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
  Arn.attr_value #>> '{}' AS arn,
  (has_virtual_mfa.attr_value #>> '{}')::boolean AS has_virtual_mfa,
  (mfa_active.attr_value #>> '{}')::boolean AS mfa_active,
  (access_key_1_active.attr_value #>> '{}')::boolean AS access_key_1_active,
  (access_key_2_active.attr_value #>> '{}')::boolean AS access_key_2_active,
  (cert_1_active.attr_value #>> '{}')::boolean AS cert_1_active,
  (cert_2_active.attr_value #>> '{}')::boolean AS cert_2_active,
  (TO_TIMESTAMP(password_last_used.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS password_last_used,
  
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN resource_attribute AS Arn
    ON Arn.resource_id = R.id
    AND Arn.type = 'provider'
    AND lower(Arn.attr_name) = 'arn'
    AND Arn.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS has_virtual_mfa
    ON has_virtual_mfa.resource_id = R.id
    AND has_virtual_mfa.type = 'provider'
    AND lower(has_virtual_mfa.attr_name) = 'has_virtual_mfa'
    AND has_virtual_mfa.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS mfa_active
    ON mfa_active.resource_id = R.id
    AND mfa_active.type = 'provider'
    AND lower(mfa_active.attr_name) = 'mfa_active'
    AND mfa_active.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS access_key_1_active
    ON access_key_1_active.resource_id = R.id
    AND access_key_1_active.type = 'provider'
    AND lower(access_key_1_active.attr_name) = 'access_key_1_active'
    AND access_key_1_active.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS access_key_2_active
    ON access_key_2_active.resource_id = R.id
    AND access_key_2_active.type = 'provider'
    AND lower(access_key_2_active.attr_name) = 'access_key_2_active'
    AND access_key_2_active.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS cert_1_active
    ON cert_1_active.resource_id = R.id
    AND cert_1_active.type = 'provider'
    AND lower(cert_1_active.attr_name) = 'cert_1_active'
    AND cert_1_active.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS cert_2_active
    ON cert_2_active.resource_id = R.id
    AND cert_2_active.type = 'provider'
    AND lower(cert_2_active.attr_name) = 'cert_2_active'
    AND cert_2_active.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS password_last_used
    ON password_last_used.resource_id = R.id
    AND password_last_used.type = 'provider'
    AND lower(password_last_used.attr_name) = 'password_last_used'
    AND password_last_used.provider_account_id = R.provider_account_id
  LEFT JOIN (
    SELECT
      _aws_organizations_account_relation.resource_id AS resource_id,
      _aws_organizations_account.id AS target_id
    FROM
    (
      SELECT
        _aws_organizations_account_relation.resource_id AS resource_id
      FROM
        resource_relation AS _aws_organizations_account_relation
        INNER JOIN resource AS _aws_organizations_account
          ON _aws_organizations_account_relation.target_id = _aws_organizations_account.id
          AND _aws_organizations_account.provider_type = 'Account'
          AND _aws_organizations_account.service = 'organizations'
      WHERE
        _aws_organizations_account_relation.relation = 'in'
        AND _aws_organizations_account_relation.provider_account_id = :provider_account_id
      GROUP BY _aws_organizations_account_relation.resource_id
      HAVING COUNT(*) = 1
    ) AS unique_account_mapping
    INNER JOIN resource_relation AS _aws_organizations_account_relation
      ON _aws_organizations_account_relation.resource_id = unique_account_mapping.resource_id
    INNER JOIN resource AS _aws_organizations_account
      ON _aws_organizations_account_relation.target_id = _aws_organizations_account.id
      AND _aws_organizations_account.provider_type = 'Account'
      AND _aws_organizations_account.service = 'organizations'
      AND _aws_organizations_account_relation.provider_account_id = :provider_account_id
    WHERE
        _aws_organizations_account_relation.relation = 'in'
        AND _aws_organizations_account_relation.provider_account_id = :provider_account_id
  ) AS _account_id ON _account_id.resource_id = R.id
  WHERE
  R.provider_account_id = :provider_account_id
  AND PA.provider = 'aws'
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


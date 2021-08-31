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
INSERT INTO aws_acmpca_certificateauthority (
  _id,
  uri,
  provider_account_id,
  arn,
  owneraccount,
  createdat,
  laststatechangeat,
  type,
  serial,
  status,
  notbefore,
  notafter,
  failurereason,
  certificateauthorityconfiguration,
  revocationconfiguration,
  restorableuntil,
  policy,
  tags,
  _tags,
  _policy,
  _account_id
)
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  attrs.provider ->> 'Arn' AS arn,
  attrs.provider ->> 'OwnerAccount' AS owneraccount,
  (TO_TIMESTAMP(attrs.provider ->> 'CreatedAt', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS createdat,
  (TO_TIMESTAMP(attrs.provider ->> 'LastStateChangeAt', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS laststatechangeat,
  attrs.provider ->> 'Type' AS type,
  attrs.provider ->> 'Serial' AS serial,
  attrs.provider ->> 'Status' AS status,
  (TO_TIMESTAMP(attrs.provider ->> 'NotBefore', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS notbefore,
  (TO_TIMESTAMP(attrs.provider ->> 'NotAfter', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS notafter,
  attrs.provider ->> 'FailureReason' AS failurereason,
  attrs.provider -> 'CertificateAuthorityConfiguration' AS certificateauthorityconfiguration,
  attrs.provider -> 'RevocationConfiguration' AS revocationconfiguration,
  (TO_TIMESTAMP(attrs.provider ->> 'RestorableUntil', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS restorableuntil,
  attrs.provider -> 'Policy' AS policy,
  attrs.provider -> 'Tags' AS tags,
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
  AND R.provider_type = 'CertificateAuthority'
  AND R.service = 'acm-pca'
ON CONFLICT (_id) DO UPDATE
SET
    Arn = EXCLUDED.Arn,
    OwnerAccount = EXCLUDED.OwnerAccount,
    CreatedAt = EXCLUDED.CreatedAt,
    LastStateChangeAt = EXCLUDED.LastStateChangeAt,
    Type = EXCLUDED.Type,
    Serial = EXCLUDED.Serial,
    Status = EXCLUDED.Status,
    NotBefore = EXCLUDED.NotBefore,
    NotAfter = EXCLUDED.NotAfter,
    FailureReason = EXCLUDED.FailureReason,
    CertificateAuthorityConfiguration = EXCLUDED.CertificateAuthorityConfiguration,
    RevocationConfiguration = EXCLUDED.RevocationConfiguration,
    RestorableUntil = EXCLUDED.RestorableUntil,
    Policy = EXCLUDED.Policy,
    Tags = EXCLUDED.Tags,
    _tags = EXCLUDED._tags,
    _policy = EXCLUDED._policy,
    _account_id = EXCLUDED._account_id
  ;


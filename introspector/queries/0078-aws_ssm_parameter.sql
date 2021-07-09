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
INSERT INTO aws_ssm_parameter (
  _id,
  uri,
  provider_account_id,
  name,
  type,
  keyid,
  lastmodifieddate,
  lastmodifieduser,
  description,
  allowedpattern,
  version,
  tier,
  policies,
  datatype,
  tags,
  _tags,
  _kms_key_id,_account_id
)
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  attrs.provider ->> 'Name' AS name,
  attrs.provider ->> 'Type' AS type,
  attrs.provider ->> 'KeyId' AS keyid,
  (TO_TIMESTAMP(attrs.provider ->> 'LastModifiedDate', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS lastmodifieddate,
  attrs.provider ->> 'LastModifiedUser' AS lastmodifieduser,
  attrs.provider ->> 'Description' AS description,
  attrs.provider ->> 'AllowedPattern' AS allowedpattern,
  (attrs.provider ->> 'Version')::bigint AS version,
  attrs.provider ->> 'Tier' AS tier,
  attrs.provider -> 'Policies' AS policies,
  attrs.provider ->> 'DataType' AS datatype,
  attrs.provider -> 'Tags' AS tags,
  attrs.metadata -> 'Tags' AS tags,
  
    _kms_key_id.target_id AS _kms_key_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  LEFT JOIN attrs ON
    attrs.resource_id = R.id
  LEFT JOIN (
    SELECT
      _aws_kms_key_relation.resource_id AS resource_id,
      _aws_kms_key.id AS target_id
    FROM
      resource_relation AS _aws_kms_key_relation
      INNER JOIN resource AS _aws_kms_key
        ON _aws_kms_key_relation.target_id = _aws_kms_key.id
        AND _aws_kms_key.provider_type = 'Key'
        AND _aws_kms_key.service = 'kms'
        AND _aws_kms_key.provider_account_id = :provider_account_id
    WHERE
      _aws_kms_key_relation.relation = 'secured-by'
      AND _aws_kms_key_relation.provider_account_id = :provider_account_id
  ) AS _kms_key_id ON _kms_key_id.resource_id = R.id
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
  AND R.provider_type = 'Parameter'
  AND R.service = 'ssm'
ON CONFLICT (_id) DO UPDATE
SET
    Name = EXCLUDED.Name,
    Type = EXCLUDED.Type,
    KeyId = EXCLUDED.KeyId,
    LastModifiedDate = EXCLUDED.LastModifiedDate,
    LastModifiedUser = EXCLUDED.LastModifiedUser,
    Description = EXCLUDED.Description,
    AllowedPattern = EXCLUDED.AllowedPattern,
    Version = EXCLUDED.Version,
    Tier = EXCLUDED.Tier,
    Policies = EXCLUDED.Policies,
    DataType = EXCLUDED.DataType,
    Tags = EXCLUDED.Tags,
    _tags = EXCLUDED._tags,
    _kms_key_id = EXCLUDED._kms_key_id,
    _account_id = EXCLUDED._account_id
  ;


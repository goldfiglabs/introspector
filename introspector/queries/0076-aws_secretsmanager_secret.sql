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
INSERT INTO aws_secretsmanager_secret (
  _id,
  uri,
  provider_account_id,
  arn,
  name,
  description,
  kmskeyid,
  rotationenabled,
  rotationlambdaarn,
  rotationrules,
  lastrotateddate,
  lastchangeddate,
  lastaccesseddate,
  deleteddate,
  tags,
  secretversionstostages,
  owningservice,
  createddate,
  _tags,
  _policy,
  _kms_key_id,_account_id
)
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  attrs.provider ->> 'ARN' AS arn,
  attrs.provider ->> 'Name' AS name,
  attrs.provider ->> 'Description' AS description,
  attrs.provider ->> 'KmsKeyId' AS kmskeyid,
  (attrs.provider ->> 'RotationEnabled')::boolean AS rotationenabled,
  attrs.provider ->> 'RotationLambdaARN' AS rotationlambdaarn,
  attrs.provider -> 'RotationRules' AS rotationrules,
  (TO_TIMESTAMP(attrs.provider ->> 'LastRotatedDate', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS lastrotateddate,
  (TO_TIMESTAMP(attrs.provider ->> 'LastChangedDate', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS lastchangeddate,
  (TO_TIMESTAMP(attrs.provider ->> 'LastAccessedDate', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS lastaccesseddate,
  (TO_TIMESTAMP(attrs.provider ->> 'DeletedDate', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS deleteddate,
  attrs.provider -> 'Tags' AS tags,
  attrs.provider -> 'SecretVersionsToStages' AS secretversionstostages,
  attrs.provider ->> 'OwningService' AS owningservice,
  (TO_TIMESTAMP(attrs.provider ->> 'CreatedDate', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS createddate,
  attrs.metadata -> 'Tags' AS tags,
  attrs.metadata -> 'Policy' AS policy,
  
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
      _aws_kms_key_relation.relation = 'encrypted-by'
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
          AND _aws_organizations_account_relation.provider_account_id = :provider_account_id
        GROUP BY _aws_organizations_account_relation.resource_id
        HAVING COUNT(*) = 1
      ) AS unique_account_mapping
  ) AS _account_id ON _account_id.resource_id = R.id
  WHERE
  R.provider_account_id = :provider_account_id
  AND R.provider_type = 'Secret'
  AND R.service = 'secretsmanager'
ON CONFLICT (_id) DO UPDATE
SET
    ARN = EXCLUDED.ARN,
    Name = EXCLUDED.Name,
    Description = EXCLUDED.Description,
    KmsKeyId = EXCLUDED.KmsKeyId,
    RotationEnabled = EXCLUDED.RotationEnabled,
    RotationLambdaARN = EXCLUDED.RotationLambdaARN,
    RotationRules = EXCLUDED.RotationRules,
    LastRotatedDate = EXCLUDED.LastRotatedDate,
    LastChangedDate = EXCLUDED.LastChangedDate,
    LastAccessedDate = EXCLUDED.LastAccessedDate,
    DeletedDate = EXCLUDED.DeletedDate,
    Tags = EXCLUDED.Tags,
    SecretVersionsToStages = EXCLUDED.SecretVersionsToStages,
    OwningService = EXCLUDED.OwningService,
    CreatedDate = EXCLUDED.CreatedDate,
    _tags = EXCLUDED._tags,
    _policy = EXCLUDED._policy,
    _kms_key_id = EXCLUDED._kms_key_id,
    _account_id = EXCLUDED._account_id
  ;


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
INSERT INTO aws_kms_key (
  _id,
  uri,
  provider_account_id,
  awsaccountid,
  keyid,
  arn,
  creationdate,
  enabled,
  description,
  keyusage,
  keystate,
  deletiondate,
  validto,
  origin,
  customkeystoreid,
  cloudhsmclusterid,
  expirationmodel,
  keymanager,
  customermasterkeyspec,
  encryptionalgorithms,
  signingalgorithms,
  tags,
  keyrotationenabled,
  policy,
  _tags,
  _policy,
  _account_id
)
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  attrs.provider ->> 'AWSAccountId' AS awsaccountid,
  attrs.provider ->> 'KeyId' AS keyid,
  attrs.provider ->> 'Arn' AS arn,
  (TO_TIMESTAMP(attrs.provider ->> 'CreationDate', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS creationdate,
  (attrs.provider ->> 'Enabled')::boolean AS enabled,
  attrs.provider ->> 'Description' AS description,
  attrs.provider ->> 'KeyUsage' AS keyusage,
  attrs.provider ->> 'KeyState' AS keystate,
  (TO_TIMESTAMP(attrs.provider ->> 'DeletionDate', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS deletiondate,
  (TO_TIMESTAMP(attrs.provider ->> 'ValidTo', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS validto,
  attrs.provider ->> 'Origin' AS origin,
  attrs.provider ->> 'CustomKeyStoreId' AS customkeystoreid,
  attrs.provider ->> 'CloudHsmClusterId' AS cloudhsmclusterid,
  attrs.provider ->> 'ExpirationModel' AS expirationmodel,
  attrs.provider ->> 'KeyManager' AS keymanager,
  attrs.provider ->> 'CustomerMasterKeySpec' AS customermasterkeyspec,
  attrs.provider -> 'EncryptionAlgorithms' AS encryptionalgorithms,
  attrs.provider -> 'SigningAlgorithms' AS signingalgorithms,
  attrs.provider -> 'Tags' AS tags,
  (attrs.provider ->> 'KeyRotationEnabled')::boolean AS keyrotationenabled,
  attrs.provider -> 'Policy' AS policy,
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
          AND _aws_organizations_account_relation.provider_account_id = 8
        GROUP BY _aws_organizations_account_relation.resource_id
        HAVING COUNT(*) = 1
      ) AS unique_account_mapping
  ) AS _account_id ON _account_id.resource_id = R.id
  WHERE
  R.provider_account_id = :provider_account_id
  AND R.provider_type = 'Key'
  AND R.service = 'kms'
ON CONFLICT (_id) DO UPDATE
SET
    AWSAccountId = EXCLUDED.AWSAccountId,
    KeyId = EXCLUDED.KeyId,
    Arn = EXCLUDED.Arn,
    CreationDate = EXCLUDED.CreationDate,
    Enabled = EXCLUDED.Enabled,
    Description = EXCLUDED.Description,
    KeyUsage = EXCLUDED.KeyUsage,
    KeyState = EXCLUDED.KeyState,
    DeletionDate = EXCLUDED.DeletionDate,
    ValidTo = EXCLUDED.ValidTo,
    Origin = EXCLUDED.Origin,
    CustomKeyStoreId = EXCLUDED.CustomKeyStoreId,
    CloudHsmClusterId = EXCLUDED.CloudHsmClusterId,
    ExpirationModel = EXCLUDED.ExpirationModel,
    KeyManager = EXCLUDED.KeyManager,
    CustomerMasterKeySpec = EXCLUDED.CustomerMasterKeySpec,
    EncryptionAlgorithms = EXCLUDED.EncryptionAlgorithms,
    SigningAlgorithms = EXCLUDED.SigningAlgorithms,
    Tags = EXCLUDED.Tags,
    KeyRotationEnabled = EXCLUDED.KeyRotationEnabled,
    Policy = EXCLUDED.Policy,
    _tags = EXCLUDED._tags,
    _policy = EXCLUDED._policy,
    _account_id = EXCLUDED._account_id
  ;


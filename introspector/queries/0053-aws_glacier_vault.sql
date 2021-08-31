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
INSERT INTO aws_glacier_vault (
  _id,
  uri,
  provider_account_id,
  vaultarn,
  vaultname,
  creationdate,
  lastinventorydate,
  numberofarchives,
  sizeinbytes,
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
  attrs.provider ->> 'VaultARN' AS vaultarn,
  attrs.provider ->> 'VaultName' AS vaultname,
  attrs.provider ->> 'CreationDate' AS creationdate,
  attrs.provider ->> 'LastInventoryDate' AS lastinventorydate,
  (attrs.provider ->> 'NumberOfArchives')::bigint AS numberofarchives,
  (attrs.provider ->> 'SizeInBytes')::bigint AS sizeinbytes,
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
  AND R.provider_type = 'Vault'
  AND R.service = 'glacier'
ON CONFLICT (_id) DO UPDATE
SET
    VaultARN = EXCLUDED.VaultARN,
    VaultName = EXCLUDED.VaultName,
    CreationDate = EXCLUDED.CreationDate,
    LastInventoryDate = EXCLUDED.LastInventoryDate,
    NumberOfArchives = EXCLUDED.NumberOfArchives,
    SizeInBytes = EXCLUDED.SizeInBytes,
    Policy = EXCLUDED.Policy,
    Tags = EXCLUDED.Tags,
    _tags = EXCLUDED._tags,
    _policy = EXCLUDED._policy,
    _account_id = EXCLUDED._account_id
  ;


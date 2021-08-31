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
INSERT INTO aws_dynamodb_backup (
  _id,
  uri,
  provider_account_id,
  tablename,
  tableid,
  tablearn,
  backuparn,
  backupname,
  backupcreationdatetime,
  backupexpirydatetime,
  backupstatus,
  backuptype,
  backupsizebytes,
  _table_id,_account_id
)
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  attrs.provider ->> 'TableName' AS tablename,
  attrs.provider ->> 'TableId' AS tableid,
  attrs.provider ->> 'TableArn' AS tablearn,
  attrs.provider ->> 'BackupArn' AS backuparn,
  attrs.provider ->> 'BackupName' AS backupname,
  (TO_TIMESTAMP(attrs.provider ->> 'BackupCreationDateTime', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS backupcreationdatetime,
  (TO_TIMESTAMP(attrs.provider ->> 'BackupExpiryDateTime', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS backupexpirydatetime,
  attrs.provider ->> 'BackupStatus' AS backupstatus,
  attrs.provider ->> 'BackupType' AS backuptype,
  (attrs.provider ->> 'BackupSizeBytes')::bigint AS backupsizebytes,
  
    _table_id.target_id AS _table_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  LEFT JOIN attrs ON
    attrs.resource_id = R.id
  LEFT JOIN (
    SELECT
      _aws_dynamodb_table_relation.resource_id AS resource_id,
      _aws_dynamodb_table.id AS target_id
    FROM
      resource_relation AS _aws_dynamodb_table_relation
      INNER JOIN resource AS _aws_dynamodb_table
        ON _aws_dynamodb_table_relation.target_id = _aws_dynamodb_table.id
        AND _aws_dynamodb_table.provider_type = 'Table'
        AND _aws_dynamodb_table.service = 'dynamodb'
        AND _aws_dynamodb_table.provider_account_id = :provider_account_id
    WHERE
      _aws_dynamodb_table_relation.relation = 'backup-of'
      AND _aws_dynamodb_table_relation.provider_account_id = :provider_account_id
  ) AS _table_id ON _table_id.resource_id = R.id
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
  AND R.provider_type = 'Backup'
  AND R.service = 'dynamodb'
ON CONFLICT (_id) DO UPDATE
SET
    TableName = EXCLUDED.TableName,
    TableId = EXCLUDED.TableId,
    TableArn = EXCLUDED.TableArn,
    BackupArn = EXCLUDED.BackupArn,
    BackupName = EXCLUDED.BackupName,
    BackupCreationDateTime = EXCLUDED.BackupCreationDateTime,
    BackupExpiryDateTime = EXCLUDED.BackupExpiryDateTime,
    BackupStatus = EXCLUDED.BackupStatus,
    BackupType = EXCLUDED.BackupType,
    BackupSizeBytes = EXCLUDED.BackupSizeBytes,
    _table_id = EXCLUDED._table_id,
    _account_id = EXCLUDED._account_id
  ;


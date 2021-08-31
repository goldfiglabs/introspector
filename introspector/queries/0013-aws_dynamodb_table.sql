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
INSERT INTO aws_dynamodb_table (
  _id,
  uri,
  provider_account_id,
  attributedefinitions,
  tablename,
  keyschema,
  tablestatus,
  creationdatetime,
  provisionedthroughput,
  tablesizebytes,
  itemcount,
  tablearn,
  tableid,
  billingmodesummary,
  localsecondaryindexes,
  globalsecondaryindexes,
  streamspecification,
  lateststreamlabel,
  lateststreamarn,
  globaltableversion,
  replicas,
  restoresummary,
  ssedescription,
  archivalsummary,
  continuousbackupsstatus,
  pointintimerecoverydescription,
  tags,
  _tags,
  _account_id
)
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  attrs.provider -> 'AttributeDefinitions' AS attributedefinitions,
  attrs.provider ->> 'TableName' AS tablename,
  attrs.provider -> 'KeySchema' AS keyschema,
  attrs.provider ->> 'TableStatus' AS tablestatus,
  (TO_TIMESTAMP(attrs.provider ->> 'CreationDateTime', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS creationdatetime,
  attrs.provider -> 'ProvisionedThroughput' AS provisionedthroughput,
  (attrs.provider ->> 'TableSizeBytes')::bigint AS tablesizebytes,
  (attrs.provider ->> 'ItemCount')::bigint AS itemcount,
  attrs.provider ->> 'TableArn' AS tablearn,
  attrs.provider ->> 'TableId' AS tableid,
  attrs.provider -> 'BillingModeSummary' AS billingmodesummary,
  attrs.provider -> 'LocalSecondaryIndexes' AS localsecondaryindexes,
  attrs.provider -> 'GlobalSecondaryIndexes' AS globalsecondaryindexes,
  attrs.provider -> 'StreamSpecification' AS streamspecification,
  attrs.provider ->> 'LatestStreamLabel' AS lateststreamlabel,
  attrs.provider ->> 'LatestStreamArn' AS lateststreamarn,
  attrs.provider ->> 'GlobalTableVersion' AS globaltableversion,
  attrs.provider -> 'Replicas' AS replicas,
  attrs.provider -> 'RestoreSummary' AS restoresummary,
  attrs.provider -> 'SSEDescription' AS ssedescription,
  attrs.provider -> 'ArchivalSummary' AS archivalsummary,
  attrs.provider ->> 'ContinuousBackupsStatus' AS continuousbackupsstatus,
  attrs.provider -> 'PointInTimeRecoveryDescription' AS pointintimerecoverydescription,
  attrs.provider -> 'Tags' AS tags,
  attrs.metadata -> 'Tags' AS tags,
  
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
  AND R.provider_type = 'Table'
  AND R.service = 'dynamodb'
ON CONFLICT (_id) DO UPDATE
SET
    AttributeDefinitions = EXCLUDED.AttributeDefinitions,
    TableName = EXCLUDED.TableName,
    KeySchema = EXCLUDED.KeySchema,
    TableStatus = EXCLUDED.TableStatus,
    CreationDateTime = EXCLUDED.CreationDateTime,
    ProvisionedThroughput = EXCLUDED.ProvisionedThroughput,
    TableSizeBytes = EXCLUDED.TableSizeBytes,
    ItemCount = EXCLUDED.ItemCount,
    TableArn = EXCLUDED.TableArn,
    TableId = EXCLUDED.TableId,
    BillingModeSummary = EXCLUDED.BillingModeSummary,
    LocalSecondaryIndexes = EXCLUDED.LocalSecondaryIndexes,
    GlobalSecondaryIndexes = EXCLUDED.GlobalSecondaryIndexes,
    StreamSpecification = EXCLUDED.StreamSpecification,
    LatestStreamLabel = EXCLUDED.LatestStreamLabel,
    LatestStreamArn = EXCLUDED.LatestStreamArn,
    GlobalTableVersion = EXCLUDED.GlobalTableVersion,
    Replicas = EXCLUDED.Replicas,
    RestoreSummary = EXCLUDED.RestoreSummary,
    SSEDescription = EXCLUDED.SSEDescription,
    ArchivalSummary = EXCLUDED.ArchivalSummary,
    ContinuousBackupsStatus = EXCLUDED.ContinuousBackupsStatus,
    PointInTimeRecoveryDescription = EXCLUDED.PointInTimeRecoveryDescription,
    Tags = EXCLUDED.Tags,
    _tags = EXCLUDED._tags,
    _account_id = EXCLUDED._account_id
  ;


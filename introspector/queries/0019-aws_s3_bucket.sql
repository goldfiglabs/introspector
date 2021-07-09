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
INSERT INTO aws_s3_bucket (
  _id,
  uri,
  provider_account_id,
  name,
  creationdate,
  analyticsconfigurations,
  inventoryconfigurations,
  metricsconfigurations,
  accelerateconfiguration,
  acl,
  cors,
  encryption,
  lifecycleconfiguration,
  location,
  logging,
  notificationconfiguration,
  policy,
  policystatus,
  replication,
  requestpayment,
  tagging,
  versioning,
  website,
  blockpublicacls,
  ignorepublicacls,
  blockpublicpolicy,
  restrictpublicbuckets,
  _tags,
  _policy,
  _account_id
)
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  attrs.provider ->> 'Name' AS name,
  (TO_TIMESTAMP(attrs.provider ->> 'CreationDate', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS creationdate,
  attrs.provider -> 'AnalyticsConfigurations' AS analyticsconfigurations,
  attrs.provider -> 'InventoryConfigurations' AS inventoryconfigurations,
  attrs.provider -> 'MetricsConfigurations' AS metricsconfigurations,
  attrs.provider ->> 'AccelerateConfiguration' AS accelerateconfiguration,
  attrs.provider -> 'Acl' AS acl,
  attrs.provider -> 'Cors' AS cors,
  attrs.provider -> 'Encryption' AS encryption,
  attrs.provider -> 'LifecycleConfiguration' AS lifecycleconfiguration,
  attrs.provider ->> 'Location' AS location,
  attrs.provider -> 'Logging' AS logging,
  attrs.provider -> 'NotificationConfiguration' AS notificationconfiguration,
  attrs.provider -> 'Policy' AS policy,
  attrs.provider -> 'PolicyStatus' AS policystatus,
  attrs.provider -> 'Replication' AS replication,
  attrs.provider -> 'RequestPayment' AS requestpayment,
  attrs.provider -> 'Tagging' AS tagging,
  attrs.provider -> 'Versioning' AS versioning,
  attrs.provider -> 'Website' AS website,
  (attrs.provider ->> 'BlockPublicAcls')::boolean AS blockpublicacls,
  (attrs.provider ->> 'IgnorePublicAcls')::boolean AS ignorepublicacls,
  (attrs.provider ->> 'BlockPublicPolicy')::boolean AS blockpublicpolicy,
  (attrs.provider ->> 'RestrictPublicBuckets')::boolean AS restrictpublicbuckets,
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
  AND R.provider_type = 'Bucket'
  AND R.service = 's3'
ON CONFLICT (_id) DO UPDATE
SET
    Name = EXCLUDED.Name,
    CreationDate = EXCLUDED.CreationDate,
    AnalyticsConfigurations = EXCLUDED.AnalyticsConfigurations,
    InventoryConfigurations = EXCLUDED.InventoryConfigurations,
    MetricsConfigurations = EXCLUDED.MetricsConfigurations,
    AccelerateConfiguration = EXCLUDED.AccelerateConfiguration,
    Acl = EXCLUDED.Acl,
    Cors = EXCLUDED.Cors,
    Encryption = EXCLUDED.Encryption,
    LifecycleConfiguration = EXCLUDED.LifecycleConfiguration,
    Location = EXCLUDED.Location,
    Logging = EXCLUDED.Logging,
    NotificationConfiguration = EXCLUDED.NotificationConfiguration,
    Policy = EXCLUDED.Policy,
    PolicyStatus = EXCLUDED.PolicyStatus,
    Replication = EXCLUDED.Replication,
    RequestPayment = EXCLUDED.RequestPayment,
    Tagging = EXCLUDED.Tagging,
    Versioning = EXCLUDED.Versioning,
    Website = EXCLUDED.Website,
    BlockPublicAcls = EXCLUDED.BlockPublicAcls,
    IgnorePublicAcls = EXCLUDED.IgnorePublicAcls,
    BlockPublicPolicy = EXCLUDED.BlockPublicPolicy,
    RestrictPublicBuckets = EXCLUDED.RestrictPublicBuckets,
    _tags = EXCLUDED._tags,
    _policy = EXCLUDED._policy,
    _account_id = EXCLUDED._account_id
  ;


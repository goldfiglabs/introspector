DROP MATERIALIZED VIEW IF EXISTS aws_s3_bucket CASCADE;

CREATE MATERIALIZED VIEW aws_s3_bucket AS
SELECT
  R.id AS resource_id,
  R.uri,
  R.provider_account_id,
  name.attr_value #>> '{}' AS name,
  (TO_TIMESTAMP(creationdate.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS creationdate,
  analyticsconfigurations.attr_value::jsonb AS analyticsconfigurations,
  inventoryconfigurations.attr_value::jsonb AS inventoryconfigurations,
  metricsconfigurations.attr_value::jsonb AS metricsconfigurations,
  accelerateconfiguration.attr_value #>> '{}' AS accelerateconfiguration,
  acl.attr_value::jsonb AS acl,
  cors.attr_value::jsonb AS cors,
  encryption.attr_value::jsonb AS encryption,
  lifecycleconfiguration.attr_value::jsonb AS lifecycleconfiguration,
  location.attr_value #>> '{}' AS location,
  logging.attr_value::jsonb AS logging,
  notificationconfiguration.attr_value::jsonb AS notificationconfiguration,
  policy.attr_value::jsonb AS policy,
  policystatus.attr_value::jsonb AS policystatus,
  replication.attr_value::jsonb AS replication,
  requestpayment.attr_value #>> '{}' AS requestpayment,
  tagging.attr_value::jsonb AS tagging,
  versioning.attr_value::jsonb AS versioning,
  website.attr_value::jsonb AS website,
  
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN resource_attribute AS name
    ON name.resource_id = R.id
    AND name.type = 'provider'
    AND lower(name.attr_name) = 'name'
  LEFT JOIN resource_attribute AS creationdate
    ON creationdate.resource_id = R.id
    AND creationdate.type = 'provider'
    AND lower(creationdate.attr_name) = 'creationdate'
  LEFT JOIN resource_attribute AS analyticsconfigurations
    ON analyticsconfigurations.resource_id = R.id
    AND analyticsconfigurations.type = 'provider'
    AND lower(analyticsconfigurations.attr_name) = 'analyticsconfigurations'
  LEFT JOIN resource_attribute AS inventoryconfigurations
    ON inventoryconfigurations.resource_id = R.id
    AND inventoryconfigurations.type = 'provider'
    AND lower(inventoryconfigurations.attr_name) = 'inventoryconfigurations'
  LEFT JOIN resource_attribute AS metricsconfigurations
    ON metricsconfigurations.resource_id = R.id
    AND metricsconfigurations.type = 'provider'
    AND lower(metricsconfigurations.attr_name) = 'metricsconfigurations'
  LEFT JOIN resource_attribute AS accelerateconfiguration
    ON accelerateconfiguration.resource_id = R.id
    AND accelerateconfiguration.type = 'provider'
    AND lower(accelerateconfiguration.attr_name) = 'accelerateconfiguration'
  LEFT JOIN resource_attribute AS acl
    ON acl.resource_id = R.id
    AND acl.type = 'provider'
    AND lower(acl.attr_name) = 'acl'
  LEFT JOIN resource_attribute AS cors
    ON cors.resource_id = R.id
    AND cors.type = 'provider'
    AND lower(cors.attr_name) = 'cors'
  LEFT JOIN resource_attribute AS encryption
    ON encryption.resource_id = R.id
    AND encryption.type = 'provider'
    AND lower(encryption.attr_name) = 'encryption'
  LEFT JOIN resource_attribute AS lifecycleconfiguration
    ON lifecycleconfiguration.resource_id = R.id
    AND lifecycleconfiguration.type = 'provider'
    AND lower(lifecycleconfiguration.attr_name) = 'lifecycleconfiguration'
  LEFT JOIN resource_attribute AS location
    ON location.resource_id = R.id
    AND location.type = 'provider'
    AND lower(location.attr_name) = 'location'
  LEFT JOIN resource_attribute AS logging
    ON logging.resource_id = R.id
    AND logging.type = 'provider'
    AND lower(logging.attr_name) = 'logging'
  LEFT JOIN resource_attribute AS notificationconfiguration
    ON notificationconfiguration.resource_id = R.id
    AND notificationconfiguration.type = 'provider'
    AND lower(notificationconfiguration.attr_name) = 'notificationconfiguration'
  LEFT JOIN resource_attribute AS policy
    ON policy.resource_id = R.id
    AND policy.type = 'provider'
    AND lower(policy.attr_name) = 'policy'
  LEFT JOIN resource_attribute AS policystatus
    ON policystatus.resource_id = R.id
    AND policystatus.type = 'provider'
    AND lower(policystatus.attr_name) = 'policystatus'
  LEFT JOIN resource_attribute AS replication
    ON replication.resource_id = R.id
    AND replication.type = 'provider'
    AND lower(replication.attr_name) = 'replication'
  LEFT JOIN resource_attribute AS requestpayment
    ON requestpayment.resource_id = R.id
    AND requestpayment.type = 'provider'
    AND lower(requestpayment.attr_name) = 'requestpayment'
  LEFT JOIN resource_attribute AS tagging
    ON tagging.resource_id = R.id
    AND tagging.type = 'provider'
    AND lower(tagging.attr_name) = 'tagging'
  LEFT JOIN resource_attribute AS versioning
    ON versioning.resource_id = R.id
    AND versioning.type = 'provider'
    AND lower(versioning.attr_name) = 'versioning'
  LEFT JOIN resource_attribute AS website
    ON website.resource_id = R.id
    AND website.type = 'provider'
    AND lower(website.attr_name) = 'website'
  LEFT JOIN (
    SELECT
      _aws_organizations_account_relation.resource_id AS resource_id,
      _aws_organizations_account.id AS target_id
    FROM
      resource_relation AS _aws_organizations_account_relation
      INNER JOIN resource AS _aws_organizations_account
        ON _aws_organizations_account_relation.target_id = _aws_organizations_account.id
        AND _aws_organizations_account.provider_type = 'Account'
        AND _aws_organizations_account.service = 'organizations'
    WHERE
      _aws_organizations_account_relation.relation = 'in'
  ) AS _account_id ON _account_id.resource_id = R.id
  WHERE
  PA.provider = 'aws'
  AND R.provider_type = 'Bucket'
  AND R.service = 's3'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_s3_bucket;

COMMENT ON MATERIALIZED VIEW aws_s3_bucket IS 's3 Bucket resources and their associated attributes.';


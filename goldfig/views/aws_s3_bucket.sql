DROP MATERIALIZED VIEW IF EXISTS aws_s3_bucket CASCADE;

CREATE MATERIALIZED VIEW aws_s3_bucket AS
WITH attrs AS (
  SELECT
    R.id,
    LOWER(RA.attr_name) AS attr_name,
    RA.attr_value
  FROM
    resource AS R
    INNER JOIN resource_attribute AS RA
      ON RA.resource_id = R.id
  WHERE
    RA.type = 'provider'
)
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
  policy.attr_value #>> '{}' AS policy,
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
  LEFT JOIN attrs AS name
    ON name.id = R.id
    AND name.attr_name = 'name'
  LEFT JOIN attrs AS creationdate
    ON creationdate.id = R.id
    AND creationdate.attr_name = 'creationdate'
  LEFT JOIN attrs AS analyticsconfigurations
    ON analyticsconfigurations.id = R.id
    AND analyticsconfigurations.attr_name = 'analyticsconfigurations'
  LEFT JOIN attrs AS inventoryconfigurations
    ON inventoryconfigurations.id = R.id
    AND inventoryconfigurations.attr_name = 'inventoryconfigurations'
  LEFT JOIN attrs AS metricsconfigurations
    ON metricsconfigurations.id = R.id
    AND metricsconfigurations.attr_name = 'metricsconfigurations'
  LEFT JOIN attrs AS accelerateconfiguration
    ON accelerateconfiguration.id = R.id
    AND accelerateconfiguration.attr_name = 'accelerateconfiguration'
  LEFT JOIN attrs AS acl
    ON acl.id = R.id
    AND acl.attr_name = 'acl'
  LEFT JOIN attrs AS cors
    ON cors.id = R.id
    AND cors.attr_name = 'cors'
  LEFT JOIN attrs AS encryption
    ON encryption.id = R.id
    AND encryption.attr_name = 'encryption'
  LEFT JOIN attrs AS lifecycleconfiguration
    ON lifecycleconfiguration.id = R.id
    AND lifecycleconfiguration.attr_name = 'lifecycleconfiguration'
  LEFT JOIN attrs AS location
    ON location.id = R.id
    AND location.attr_name = 'location'
  LEFT JOIN attrs AS logging
    ON logging.id = R.id
    AND logging.attr_name = 'logging'
  LEFT JOIN attrs AS notificationconfiguration
    ON notificationconfiguration.id = R.id
    AND notificationconfiguration.attr_name = 'notificationconfiguration'
  LEFT JOIN attrs AS policy
    ON policy.id = R.id
    AND policy.attr_name = 'policy'
  LEFT JOIN attrs AS policystatus
    ON policystatus.id = R.id
    AND policystatus.attr_name = 'policystatus'
  LEFT JOIN attrs AS replication
    ON replication.id = R.id
    AND replication.attr_name = 'replication'
  LEFT JOIN attrs AS requestpayment
    ON requestpayment.id = R.id
    AND requestpayment.attr_name = 'requestpayment'
  LEFT JOIN attrs AS tagging
    ON tagging.id = R.id
    AND tagging.attr_name = 'tagging'
  LEFT JOIN attrs AS versioning
    ON versioning.id = R.id
    AND versioning.attr_name = 'versioning'
  LEFT JOIN attrs AS website
    ON website.id = R.id
    AND website.attr_name = 'website'
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
  AND LOWER(R.provider_type) = 'bucket'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_s3_bucket;

COMMENT ON MATERIALIZED VIEW aws_s3_bucket IS 's3 bucket resources and their associated attributes.';


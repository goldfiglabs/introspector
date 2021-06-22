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
  requestpayment.attr_value::jsonb AS requestpayment,
  tagging.attr_value::jsonb AS tagging,
  versioning.attr_value::jsonb AS versioning,
  website.attr_value::jsonb AS website,
  (blockpublicacls.attr_value #>> '{}')::boolean AS blockpublicacls,
  (ignorepublicacls.attr_value #>> '{}')::boolean AS ignorepublicacls,
  (blockpublicpolicy.attr_value #>> '{}')::boolean AS blockpublicpolicy,
  (restrictpublicbuckets.attr_value #>> '{}')::boolean AS restrictpublicbuckets,
  _tags.attr_value::jsonb AS _tags,
  _policy.attr_value::jsonb AS _policy,
  
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN resource_attribute AS name
    ON name.resource_id = R.id
    AND name.type = 'provider'
    AND lower(name.attr_name) = 'name'
    AND name.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS creationdate
    ON creationdate.resource_id = R.id
    AND creationdate.type = 'provider'
    AND lower(creationdate.attr_name) = 'creationdate'
    AND creationdate.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS analyticsconfigurations
    ON analyticsconfigurations.resource_id = R.id
    AND analyticsconfigurations.type = 'provider'
    AND lower(analyticsconfigurations.attr_name) = 'analyticsconfigurations'
    AND analyticsconfigurations.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS inventoryconfigurations
    ON inventoryconfigurations.resource_id = R.id
    AND inventoryconfigurations.type = 'provider'
    AND lower(inventoryconfigurations.attr_name) = 'inventoryconfigurations'
    AND inventoryconfigurations.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS metricsconfigurations
    ON metricsconfigurations.resource_id = R.id
    AND metricsconfigurations.type = 'provider'
    AND lower(metricsconfigurations.attr_name) = 'metricsconfigurations'
    AND metricsconfigurations.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS accelerateconfiguration
    ON accelerateconfiguration.resource_id = R.id
    AND accelerateconfiguration.type = 'provider'
    AND lower(accelerateconfiguration.attr_name) = 'accelerateconfiguration'
    AND accelerateconfiguration.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS acl
    ON acl.resource_id = R.id
    AND acl.type = 'provider'
    AND lower(acl.attr_name) = 'acl'
    AND acl.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS cors
    ON cors.resource_id = R.id
    AND cors.type = 'provider'
    AND lower(cors.attr_name) = 'cors'
    AND cors.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS encryption
    ON encryption.resource_id = R.id
    AND encryption.type = 'provider'
    AND lower(encryption.attr_name) = 'encryption'
    AND encryption.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS lifecycleconfiguration
    ON lifecycleconfiguration.resource_id = R.id
    AND lifecycleconfiguration.type = 'provider'
    AND lower(lifecycleconfiguration.attr_name) = 'lifecycleconfiguration'
    AND lifecycleconfiguration.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS location
    ON location.resource_id = R.id
    AND location.type = 'provider'
    AND lower(location.attr_name) = 'location'
    AND location.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS logging
    ON logging.resource_id = R.id
    AND logging.type = 'provider'
    AND lower(logging.attr_name) = 'logging'
    AND logging.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS notificationconfiguration
    ON notificationconfiguration.resource_id = R.id
    AND notificationconfiguration.type = 'provider'
    AND lower(notificationconfiguration.attr_name) = 'notificationconfiguration'
    AND notificationconfiguration.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS policy
    ON policy.resource_id = R.id
    AND policy.type = 'provider'
    AND lower(policy.attr_name) = 'policy'
    AND policy.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS policystatus
    ON policystatus.resource_id = R.id
    AND policystatus.type = 'provider'
    AND lower(policystatus.attr_name) = 'policystatus'
    AND policystatus.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS replication
    ON replication.resource_id = R.id
    AND replication.type = 'provider'
    AND lower(replication.attr_name) = 'replication'
    AND replication.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS requestpayment
    ON requestpayment.resource_id = R.id
    AND requestpayment.type = 'provider'
    AND lower(requestpayment.attr_name) = 'requestpayment'
    AND requestpayment.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS tagging
    ON tagging.resource_id = R.id
    AND tagging.type = 'provider'
    AND lower(tagging.attr_name) = 'tagging'
    AND tagging.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS versioning
    ON versioning.resource_id = R.id
    AND versioning.type = 'provider'
    AND lower(versioning.attr_name) = 'versioning'
    AND versioning.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS website
    ON website.resource_id = R.id
    AND website.type = 'provider'
    AND lower(website.attr_name) = 'website'
    AND website.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS blockpublicacls
    ON blockpublicacls.resource_id = R.id
    AND blockpublicacls.type = 'provider'
    AND lower(blockpublicacls.attr_name) = 'blockpublicacls'
    AND blockpublicacls.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS ignorepublicacls
    ON ignorepublicacls.resource_id = R.id
    AND ignorepublicacls.type = 'provider'
    AND lower(ignorepublicacls.attr_name) = 'ignorepublicacls'
    AND ignorepublicacls.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS blockpublicpolicy
    ON blockpublicpolicy.resource_id = R.id
    AND blockpublicpolicy.type = 'provider'
    AND lower(blockpublicpolicy.attr_name) = 'blockpublicpolicy'
    AND blockpublicpolicy.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS restrictpublicbuckets
    ON restrictpublicbuckets.resource_id = R.id
    AND restrictpublicbuckets.type = 'provider'
    AND lower(restrictpublicbuckets.attr_name) = 'restrictpublicbuckets'
    AND restrictpublicbuckets.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS _tags
    ON _tags.resource_id = R.id
    AND _tags.type = 'Metadata'
    AND lower(_tags.attr_name) = 'tags'
    AND _tags.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS _policy
    ON _policy.resource_id = R.id
    AND _policy.type = 'Metadata'
    AND lower(_policy.attr_name) = 'policy'
    AND _policy.provider_account_id = R.provider_account_id
  LEFT JOIN (
    SELECT
      _aws_organizations_account_relation.resource_id AS resource_id,
      _aws_organizations_account.id AS target_id
    FROM
    (
      SELECT
        _aws_organizations_account_relation.resource_id AS resource_id
      FROM
        resource_relation AS _aws_organizations_account_relation
        INNER JOIN resource AS _aws_organizations_account
          ON _aws_organizations_account_relation.target_id = _aws_organizations_account.id
          AND _aws_organizations_account.provider_type = 'Account'
          AND _aws_organizations_account.service = 'organizations'
      WHERE
        _aws_organizations_account_relation.relation = 'in'
        AND _aws_organizations_account_relation.provider_account_id = :provider_account_id
      GROUP BY _aws_organizations_account_relation.resource_id
      HAVING COUNT(*) = 1
    ) AS unique_account_mapping
    INNER JOIN resource_relation AS _aws_organizations_account_relation
      ON _aws_organizations_account_relation.resource_id = unique_account_mapping.resource_id
    INNER JOIN resource AS _aws_organizations_account
      ON _aws_organizations_account_relation.target_id = _aws_organizations_account.id
      AND _aws_organizations_account.provider_type = 'Account'
      AND _aws_organizations_account.service = 'organizations'
      AND _aws_organizations_account_relation.provider_account_id = :provider_account_id
    WHERE
        _aws_organizations_account_relation.relation = 'in'
        AND _aws_organizations_account_relation.provider_account_id = :provider_account_id
  ) AS _account_id ON _account_id.resource_id = R.id
  WHERE
  R.provider_account_id = :provider_account_id
  AND PA.provider = 'aws'
  AND R.provider_type = 'Bucket'
  AND R.service = 's3'
ON CONFLICT (_id) DO UPDATE
SET
    name = EXCLUDED.name,
    creationdate = EXCLUDED.creationdate,
    analyticsconfigurations = EXCLUDED.analyticsconfigurations,
    inventoryconfigurations = EXCLUDED.inventoryconfigurations,
    metricsconfigurations = EXCLUDED.metricsconfigurations,
    accelerateconfiguration = EXCLUDED.accelerateconfiguration,
    acl = EXCLUDED.acl,
    cors = EXCLUDED.cors,
    encryption = EXCLUDED.encryption,
    lifecycleconfiguration = EXCLUDED.lifecycleconfiguration,
    location = EXCLUDED.location,
    logging = EXCLUDED.logging,
    notificationconfiguration = EXCLUDED.notificationconfiguration,
    policy = EXCLUDED.policy,
    policystatus = EXCLUDED.policystatus,
    replication = EXCLUDED.replication,
    requestpayment = EXCLUDED.requestpayment,
    tagging = EXCLUDED.tagging,
    versioning = EXCLUDED.versioning,
    website = EXCLUDED.website,
    blockpublicacls = EXCLUDED.blockpublicacls,
    ignorepublicacls = EXCLUDED.ignorepublicacls,
    blockpublicpolicy = EXCLUDED.blockpublicpolicy,
    restrictpublicbuckets = EXCLUDED.restrictpublicbuckets,
    _tags = EXCLUDED._tags,
    _policy = EXCLUDED._policy,
    _account_id = EXCLUDED._account_id
  ;


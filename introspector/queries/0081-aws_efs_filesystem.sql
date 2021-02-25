INSERT INTO aws_efs_filesystem (
  _id,
  uri,
  provider_account_id,
  ownerid,
  creationtoken,
  filesystemid,
  filesystemarn,
  creationtime,
  lifecyclestate,
  name,
  numberofmounttargets,
  sizeinbytes,
  performancemode,
  encrypted,
  kmskeyid,
  throughputmode,
  provisionedthroughputinmibps,
  tags,
  policy,
  _tags,
  _policy,
  _kms_key_id,_account_id
)
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  ownerid.attr_value #>> '{}' AS ownerid,
  creationtoken.attr_value #>> '{}' AS creationtoken,
  filesystemid.attr_value #>> '{}' AS filesystemid,
  filesystemarn.attr_value #>> '{}' AS filesystemarn,
  (TO_TIMESTAMP(creationtime.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS creationtime,
  lifecyclestate.attr_value #>> '{}' AS lifecyclestate,
  name.attr_value #>> '{}' AS name,
  (numberofmounttargets.attr_value #>> '{}')::integer AS numberofmounttargets,
  sizeinbytes.attr_value::jsonb AS sizeinbytes,
  performancemode.attr_value #>> '{}' AS performancemode,
  (encrypted.attr_value #>> '{}')::boolean AS encrypted,
  kmskeyid.attr_value #>> '{}' AS kmskeyid,
  throughputmode.attr_value #>> '{}' AS throughputmode,
  (provisionedthroughputinmibps.attr_value #>> '{}')::double precision AS provisionedthroughputinmibps,
  tags.attr_value::jsonb AS tags,
  policy.attr_value::jsonb AS policy,
  _tags.attr_value::jsonb AS _tags,
  _policy.attr_value::jsonb AS _policy,
  
    _kms_key_id.target_id AS _kms_key_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN resource_attribute AS ownerid
    ON ownerid.resource_id = R.id
    AND ownerid.type = 'provider'
    AND lower(ownerid.attr_name) = 'ownerid'
  LEFT JOIN resource_attribute AS creationtoken
    ON creationtoken.resource_id = R.id
    AND creationtoken.type = 'provider'
    AND lower(creationtoken.attr_name) = 'creationtoken'
  LEFT JOIN resource_attribute AS filesystemid
    ON filesystemid.resource_id = R.id
    AND filesystemid.type = 'provider'
    AND lower(filesystemid.attr_name) = 'filesystemid'
  LEFT JOIN resource_attribute AS filesystemarn
    ON filesystemarn.resource_id = R.id
    AND filesystemarn.type = 'provider'
    AND lower(filesystemarn.attr_name) = 'filesystemarn'
  LEFT JOIN resource_attribute AS creationtime
    ON creationtime.resource_id = R.id
    AND creationtime.type = 'provider'
    AND lower(creationtime.attr_name) = 'creationtime'
  LEFT JOIN resource_attribute AS lifecyclestate
    ON lifecyclestate.resource_id = R.id
    AND lifecyclestate.type = 'provider'
    AND lower(lifecyclestate.attr_name) = 'lifecyclestate'
  LEFT JOIN resource_attribute AS name
    ON name.resource_id = R.id
    AND name.type = 'provider'
    AND lower(name.attr_name) = 'name'
  LEFT JOIN resource_attribute AS numberofmounttargets
    ON numberofmounttargets.resource_id = R.id
    AND numberofmounttargets.type = 'provider'
    AND lower(numberofmounttargets.attr_name) = 'numberofmounttargets'
  LEFT JOIN resource_attribute AS sizeinbytes
    ON sizeinbytes.resource_id = R.id
    AND sizeinbytes.type = 'provider'
    AND lower(sizeinbytes.attr_name) = 'sizeinbytes'
  LEFT JOIN resource_attribute AS performancemode
    ON performancemode.resource_id = R.id
    AND performancemode.type = 'provider'
    AND lower(performancemode.attr_name) = 'performancemode'
  LEFT JOIN resource_attribute AS encrypted
    ON encrypted.resource_id = R.id
    AND encrypted.type = 'provider'
    AND lower(encrypted.attr_name) = 'encrypted'
  LEFT JOIN resource_attribute AS kmskeyid
    ON kmskeyid.resource_id = R.id
    AND kmskeyid.type = 'provider'
    AND lower(kmskeyid.attr_name) = 'kmskeyid'
  LEFT JOIN resource_attribute AS throughputmode
    ON throughputmode.resource_id = R.id
    AND throughputmode.type = 'provider'
    AND lower(throughputmode.attr_name) = 'throughputmode'
  LEFT JOIN resource_attribute AS provisionedthroughputinmibps
    ON provisionedthroughputinmibps.resource_id = R.id
    AND provisionedthroughputinmibps.type = 'provider'
    AND lower(provisionedthroughputinmibps.attr_name) = 'provisionedthroughputinmibps'
  LEFT JOIN resource_attribute AS tags
    ON tags.resource_id = R.id
    AND tags.type = 'provider'
    AND lower(tags.attr_name) = 'tags'
  LEFT JOIN resource_attribute AS policy
    ON policy.resource_id = R.id
    AND policy.type = 'provider'
    AND lower(policy.attr_name) = 'policy'
  LEFT JOIN resource_attribute AS _tags
    ON _tags.resource_id = R.id
    AND _tags.type = 'Metadata'
    AND lower(_tags.attr_name) = 'tags'
  LEFT JOIN resource_attribute AS _policy
    ON _policy.resource_id = R.id
    AND _policy.type = 'Metadata'
    AND lower(_policy.attr_name) = 'policy'
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
    WHERE
      _aws_kms_key_relation.relation = 'encrypted-by'
  ) AS _kms_key_id ON _kms_key_id.resource_id = R.id
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
  AND R.provider_type = 'FileSystem'
  AND R.service = 'efs'
ON CONFLICT (_id) DO UPDATE
SET
    ownerid = EXCLUDED.ownerid,
    creationtoken = EXCLUDED.creationtoken,
    filesystemid = EXCLUDED.filesystemid,
    filesystemarn = EXCLUDED.filesystemarn,
    creationtime = EXCLUDED.creationtime,
    lifecyclestate = EXCLUDED.lifecyclestate,
    name = EXCLUDED.name,
    numberofmounttargets = EXCLUDED.numberofmounttargets,
    sizeinbytes = EXCLUDED.sizeinbytes,
    performancemode = EXCLUDED.performancemode,
    encrypted = EXCLUDED.encrypted,
    kmskeyid = EXCLUDED.kmskeyid,
    throughputmode = EXCLUDED.throughputmode,
    provisionedthroughputinmibps = EXCLUDED.provisionedthroughputinmibps,
    tags = EXCLUDED.tags,
    policy = EXCLUDED.policy,
    _tags = EXCLUDED._tags,
    _policy = EXCLUDED._policy,
    _kms_key_id = EXCLUDED._kms_key_id,
    _account_id = EXCLUDED._account_id
  ;


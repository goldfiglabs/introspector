INSERT INTO aws_ec2_volume (
  _id,
  uri,
  provider_account_id,
  attachments,
  availabilityzone,
  createtime,
  encrypted,
  kmskeyid,
  outpostarn,
  size,
  snapshotid,
  state,
  volumeid,
  iops,
  tags,
  volumetype,
  fastrestored,
  multiattachenabled,
  _tags,
  _account_id
)
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  attachments.attr_value::jsonb AS attachments,
  availabilityzone.attr_value #>> '{}' AS availabilityzone,
  (TO_TIMESTAMP(createtime.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS createtime,
  (encrypted.attr_value #>> '{}')::boolean AS encrypted,
  kmskeyid.attr_value #>> '{}' AS kmskeyid,
  outpostarn.attr_value #>> '{}' AS outpostarn,
  (size.attr_value #>> '{}')::integer AS size,
  snapshotid.attr_value #>> '{}' AS snapshotid,
  state.attr_value #>> '{}' AS state,
  volumeid.attr_value #>> '{}' AS volumeid,
  (iops.attr_value #>> '{}')::integer AS iops,
  tags.attr_value::jsonb AS tags,
  volumetype.attr_value #>> '{}' AS volumetype,
  (fastrestored.attr_value #>> '{}')::boolean AS fastrestored,
  (multiattachenabled.attr_value #>> '{}')::boolean AS multiattachenabled,
  _tags.attr_value::jsonb AS _tags,
  
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN resource_attribute AS attachments
    ON attachments.resource_id = R.id
    AND attachments.type = 'provider'
    AND lower(attachments.attr_name) = 'attachments'
  LEFT JOIN resource_attribute AS availabilityzone
    ON availabilityzone.resource_id = R.id
    AND availabilityzone.type = 'provider'
    AND lower(availabilityzone.attr_name) = 'availabilityzone'
  LEFT JOIN resource_attribute AS createtime
    ON createtime.resource_id = R.id
    AND createtime.type = 'provider'
    AND lower(createtime.attr_name) = 'createtime'
  LEFT JOIN resource_attribute AS encrypted
    ON encrypted.resource_id = R.id
    AND encrypted.type = 'provider'
    AND lower(encrypted.attr_name) = 'encrypted'
  LEFT JOIN resource_attribute AS kmskeyid
    ON kmskeyid.resource_id = R.id
    AND kmskeyid.type = 'provider'
    AND lower(kmskeyid.attr_name) = 'kmskeyid'
  LEFT JOIN resource_attribute AS outpostarn
    ON outpostarn.resource_id = R.id
    AND outpostarn.type = 'provider'
    AND lower(outpostarn.attr_name) = 'outpostarn'
  LEFT JOIN resource_attribute AS size
    ON size.resource_id = R.id
    AND size.type = 'provider'
    AND lower(size.attr_name) = 'size'
  LEFT JOIN resource_attribute AS snapshotid
    ON snapshotid.resource_id = R.id
    AND snapshotid.type = 'provider'
    AND lower(snapshotid.attr_name) = 'snapshotid'
  LEFT JOIN resource_attribute AS state
    ON state.resource_id = R.id
    AND state.type = 'provider'
    AND lower(state.attr_name) = 'state'
  LEFT JOIN resource_attribute AS volumeid
    ON volumeid.resource_id = R.id
    AND volumeid.type = 'provider'
    AND lower(volumeid.attr_name) = 'volumeid'
  LEFT JOIN resource_attribute AS iops
    ON iops.resource_id = R.id
    AND iops.type = 'provider'
    AND lower(iops.attr_name) = 'iops'
  LEFT JOIN resource_attribute AS tags
    ON tags.resource_id = R.id
    AND tags.type = 'provider'
    AND lower(tags.attr_name) = 'tags'
  LEFT JOIN resource_attribute AS volumetype
    ON volumetype.resource_id = R.id
    AND volumetype.type = 'provider'
    AND lower(volumetype.attr_name) = 'volumetype'
  LEFT JOIN resource_attribute AS fastrestored
    ON fastrestored.resource_id = R.id
    AND fastrestored.type = 'provider'
    AND lower(fastrestored.attr_name) = 'fastrestored'
  LEFT JOIN resource_attribute AS multiattachenabled
    ON multiattachenabled.resource_id = R.id
    AND multiattachenabled.type = 'provider'
    AND lower(multiattachenabled.attr_name) = 'multiattachenabled'
  LEFT JOIN resource_attribute AS _tags
    ON _tags.resource_id = R.id
    AND _tags.type = 'Metadata'
    AND lower(_tags.attr_name) = '_tags'
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
  AND R.provider_type = 'Volume'
  AND R.service = 'ec2'
ON CONFLICT (_id) DO UPDATE
SET
    attachments = EXCLUDED.attachments,
    availabilityzone = EXCLUDED.availabilityzone,
    createtime = EXCLUDED.createtime,
    encrypted = EXCLUDED.encrypted,
    kmskeyid = EXCLUDED.kmskeyid,
    outpostarn = EXCLUDED.outpostarn,
    size = EXCLUDED.size,
    snapshotid = EXCLUDED.snapshotid,
    state = EXCLUDED.state,
    volumeid = EXCLUDED.volumeid,
    iops = EXCLUDED.iops,
    tags = EXCLUDED.tags,
    volumetype = EXCLUDED.volumetype,
    fastrestored = EXCLUDED.fastrestored,
    multiattachenabled = EXCLUDED.multiattachenabled,
    _tags = EXCLUDED._tags,
    _account_id = EXCLUDED._account_id
  ;


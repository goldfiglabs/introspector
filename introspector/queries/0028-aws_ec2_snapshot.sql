INSERT INTO aws_ec2_snapshot (
  _id,
  uri,
  provider_account_id,
  dataencryptionkeyid,
  description,
  encrypted,
  kmskeyid,
  ownerid,
  progress,
  snapshotid,
  starttime,
  state,
  statemessage,
  volumeid,
  volumesize,
  owneralias,
  tags,
  createvolumepermissions,
  _tags,
  _kms_key_id,_volume_id,_account_id
)
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  dataencryptionkeyid.attr_value #>> '{}' AS dataencryptionkeyid,
  description.attr_value #>> '{}' AS description,
  (encrypted.attr_value #>> '{}')::boolean AS encrypted,
  kmskeyid.attr_value #>> '{}' AS kmskeyid,
  ownerid.attr_value #>> '{}' AS ownerid,
  progress.attr_value #>> '{}' AS progress,
  snapshotid.attr_value #>> '{}' AS snapshotid,
  (TO_TIMESTAMP(starttime.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS starttime,
  state.attr_value #>> '{}' AS state,
  statemessage.attr_value #>> '{}' AS statemessage,
  volumeid.attr_value #>> '{}' AS volumeid,
  (volumesize.attr_value #>> '{}')::integer AS volumesize,
  owneralias.attr_value #>> '{}' AS owneralias,
  tags.attr_value::jsonb AS tags,
  createvolumepermissions.attr_value::jsonb AS createvolumepermissions,
  _tags.attr_value::jsonb AS _tags,
  
    _kms_key_id.target_id AS _kms_key_id,
    _volume_id.target_id AS _volume_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN resource_attribute AS dataencryptionkeyid
    ON dataencryptionkeyid.resource_id = R.id
    AND dataencryptionkeyid.type = 'provider'
    AND lower(dataencryptionkeyid.attr_name) = 'dataencryptionkeyid'
    AND dataencryptionkeyid.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS description
    ON description.resource_id = R.id
    AND description.type = 'provider'
    AND lower(description.attr_name) = 'description'
    AND description.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS encrypted
    ON encrypted.resource_id = R.id
    AND encrypted.type = 'provider'
    AND lower(encrypted.attr_name) = 'encrypted'
    AND encrypted.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS kmskeyid
    ON kmskeyid.resource_id = R.id
    AND kmskeyid.type = 'provider'
    AND lower(kmskeyid.attr_name) = 'kmskeyid'
    AND kmskeyid.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS ownerid
    ON ownerid.resource_id = R.id
    AND ownerid.type = 'provider'
    AND lower(ownerid.attr_name) = 'ownerid'
    AND ownerid.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS progress
    ON progress.resource_id = R.id
    AND progress.type = 'provider'
    AND lower(progress.attr_name) = 'progress'
    AND progress.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS snapshotid
    ON snapshotid.resource_id = R.id
    AND snapshotid.type = 'provider'
    AND lower(snapshotid.attr_name) = 'snapshotid'
    AND snapshotid.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS starttime
    ON starttime.resource_id = R.id
    AND starttime.type = 'provider'
    AND lower(starttime.attr_name) = 'starttime'
    AND starttime.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS state
    ON state.resource_id = R.id
    AND state.type = 'provider'
    AND lower(state.attr_name) = 'state'
    AND state.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS statemessage
    ON statemessage.resource_id = R.id
    AND statemessage.type = 'provider'
    AND lower(statemessage.attr_name) = 'statemessage'
    AND statemessage.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS volumeid
    ON volumeid.resource_id = R.id
    AND volumeid.type = 'provider'
    AND lower(volumeid.attr_name) = 'volumeid'
    AND volumeid.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS volumesize
    ON volumesize.resource_id = R.id
    AND volumesize.type = 'provider'
    AND lower(volumesize.attr_name) = 'volumesize'
    AND volumesize.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS owneralias
    ON owneralias.resource_id = R.id
    AND owneralias.type = 'provider'
    AND lower(owneralias.attr_name) = 'owneralias'
    AND owneralias.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS tags
    ON tags.resource_id = R.id
    AND tags.type = 'provider'
    AND lower(tags.attr_name) = 'tags'
    AND tags.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS createvolumepermissions
    ON createvolumepermissions.resource_id = R.id
    AND createvolumepermissions.type = 'provider'
    AND lower(createvolumepermissions.attr_name) = 'createvolumepermissions'
    AND createvolumepermissions.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS _tags
    ON _tags.resource_id = R.id
    AND _tags.type = 'Metadata'
    AND lower(_tags.attr_name) = 'tags'
    AND _tags.provider_account_id = R.provider_account_id
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
        AND _aws_kms_key.provider_account_id = :provider_account_id
    WHERE
      _aws_kms_key_relation.relation = 'encrypted-using'
      AND _aws_kms_key_relation.provider_account_id = :provider_account_id
  ) AS _kms_key_id ON _kms_key_id.resource_id = R.id
  LEFT JOIN (
    SELECT
      _aws_ec2_volume_relation.resource_id AS resource_id,
      _aws_ec2_volume.id AS target_id
    FROM
      resource_relation AS _aws_ec2_volume_relation
      INNER JOIN resource AS _aws_ec2_volume
        ON _aws_ec2_volume_relation.target_id = _aws_ec2_volume.id
        AND _aws_ec2_volume.provider_type = 'Volume'
        AND _aws_ec2_volume.service = 'ec2'
        AND _aws_ec2_volume.provider_account_id = :provider_account_id
    WHERE
      _aws_ec2_volume_relation.relation = 'imaged'
      AND _aws_ec2_volume_relation.provider_account_id = :provider_account_id
  ) AS _volume_id ON _volume_id.resource_id = R.id
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
  AND R.provider_type = 'Snapshot'
  AND R.service = 'ec2'
ON CONFLICT (_id) DO UPDATE
SET
    dataencryptionkeyid = EXCLUDED.dataencryptionkeyid,
    description = EXCLUDED.description,
    encrypted = EXCLUDED.encrypted,
    kmskeyid = EXCLUDED.kmskeyid,
    ownerid = EXCLUDED.ownerid,
    progress = EXCLUDED.progress,
    snapshotid = EXCLUDED.snapshotid,
    starttime = EXCLUDED.starttime,
    state = EXCLUDED.state,
    statemessage = EXCLUDED.statemessage,
    volumeid = EXCLUDED.volumeid,
    volumesize = EXCLUDED.volumesize,
    owneralias = EXCLUDED.owneralias,
    tags = EXCLUDED.tags,
    createvolumepermissions = EXCLUDED.createvolumepermissions,
    _tags = EXCLUDED._tags,
    _kms_key_id = EXCLUDED._kms_key_id,
    _volume_id = EXCLUDED._volume_id,
    _account_id = EXCLUDED._account_id
  ;


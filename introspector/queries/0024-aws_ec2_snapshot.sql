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
  attrs.provider ->> 'DataEncryptionKeyId' AS dataencryptionkeyid,
  attrs.provider ->> 'Description' AS description,
  (attrs.provider ->> 'Encrypted')::boolean AS encrypted,
  attrs.provider ->> 'KmsKeyId' AS kmskeyid,
  attrs.provider ->> 'OwnerId' AS ownerid,
  attrs.provider ->> 'Progress' AS progress,
  attrs.provider ->> 'SnapshotId' AS snapshotid,
  (TO_TIMESTAMP(attrs.provider ->> 'StartTime', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS starttime,
  attrs.provider ->> 'State' AS state,
  attrs.provider ->> 'StateMessage' AS statemessage,
  attrs.provider ->> 'VolumeId' AS volumeid,
  (attrs.provider ->> 'VolumeSize')::integer AS volumesize,
  attrs.provider ->> 'OwnerAlias' AS owneralias,
  attrs.provider -> 'Tags' AS tags,
  attrs.provider -> 'CreateVolumePermissions' AS createvolumepermissions,
  attrs.metadata -> 'Tags' AS tags,
  
    _kms_key_id.target_id AS _kms_key_id,
    _volume_id.target_id AS _volume_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  LEFT JOIN attrs ON
    attrs.resource_id = R.id
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
  AND R.provider_type = 'Snapshot'
  AND R.service = 'ec2'
ON CONFLICT (_id) DO UPDATE
SET
    DataEncryptionKeyId = EXCLUDED.DataEncryptionKeyId,
    Description = EXCLUDED.Description,
    Encrypted = EXCLUDED.Encrypted,
    KmsKeyId = EXCLUDED.KmsKeyId,
    OwnerId = EXCLUDED.OwnerId,
    Progress = EXCLUDED.Progress,
    SnapshotId = EXCLUDED.SnapshotId,
    StartTime = EXCLUDED.StartTime,
    State = EXCLUDED.State,
    StateMessage = EXCLUDED.StateMessage,
    VolumeId = EXCLUDED.VolumeId,
    VolumeSize = EXCLUDED.VolumeSize,
    OwnerAlias = EXCLUDED.OwnerAlias,
    Tags = EXCLUDED.Tags,
    CreateVolumePermissions = EXCLUDED.CreateVolumePermissions,
    _tags = EXCLUDED._tags,
    _kms_key_id = EXCLUDED._kms_key_id,
    _volume_id = EXCLUDED._volume_id,
    _account_id = EXCLUDED._account_id
  ;


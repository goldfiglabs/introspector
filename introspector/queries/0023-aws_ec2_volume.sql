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
  throughput,
  _tags,
  _account_id
)
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  attrs.provider -> 'Attachments' AS attachments,
  attrs.provider ->> 'AvailabilityZone' AS availabilityzone,
  (TO_TIMESTAMP(attrs.provider ->> 'CreateTime', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS createtime,
  (attrs.provider ->> 'Encrypted')::boolean AS encrypted,
  attrs.provider ->> 'KmsKeyId' AS kmskeyid,
  attrs.provider ->> 'OutpostArn' AS outpostarn,
  (attrs.provider ->> 'Size')::integer AS size,
  attrs.provider ->> 'SnapshotId' AS snapshotid,
  attrs.provider ->> 'State' AS state,
  attrs.provider ->> 'VolumeId' AS volumeid,
  (attrs.provider ->> 'Iops')::integer AS iops,
  attrs.provider -> 'Tags' AS tags,
  attrs.provider ->> 'VolumeType' AS volumetype,
  (attrs.provider ->> 'FastRestored')::boolean AS fastrestored,
  (attrs.provider ->> 'MultiAttachEnabled')::boolean AS multiattachenabled,
  (attrs.provider ->> 'Throughput')::integer AS throughput,
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
  AND R.provider_type = 'Volume'
  AND R.service = 'ec2'
ON CONFLICT (_id) DO UPDATE
SET
    Attachments = EXCLUDED.Attachments,
    AvailabilityZone = EXCLUDED.AvailabilityZone,
    CreateTime = EXCLUDED.CreateTime,
    Encrypted = EXCLUDED.Encrypted,
    KmsKeyId = EXCLUDED.KmsKeyId,
    OutpostArn = EXCLUDED.OutpostArn,
    Size = EXCLUDED.Size,
    SnapshotId = EXCLUDED.SnapshotId,
    State = EXCLUDED.State,
    VolumeId = EXCLUDED.VolumeId,
    Iops = EXCLUDED.Iops,
    Tags = EXCLUDED.Tags,
    VolumeType = EXCLUDED.VolumeType,
    FastRestored = EXCLUDED.FastRestored,
    MultiAttachEnabled = EXCLUDED.MultiAttachEnabled,
    Throughput = EXCLUDED.Throughput,
    _tags = EXCLUDED._tags,
    _account_id = EXCLUDED._account_id
  ;


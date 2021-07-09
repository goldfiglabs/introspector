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
INSERT INTO aws_rds_dbclustersnapshot (
  _id,
  uri,
  provider_account_id,
  availabilityzones,
  dbclustersnapshotidentifier,
  dbclusteridentifier,
  snapshotcreatetime,
  engine,
  allocatedstorage,
  status,
  port,
  vpcid,
  clustercreatetime,
  masterusername,
  engineversion,
  licensemodel,
  snapshottype,
  percentprogress,
  storageencrypted,
  kmskeyid,
  dbclustersnapshotarn,
  sourcedbclustersnapshotarn,
  iamdatabaseauthenticationenabled,
  taglist,
  restore,
  _tags,
  _kms_key_id,_ec2_vpc_id,_dbcluster_id,_account_id
)
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  attrs.provider -> 'AvailabilityZones' AS availabilityzones,
  attrs.provider ->> 'DBClusterSnapshotIdentifier' AS dbclustersnapshotidentifier,
  attrs.provider ->> 'DBClusterIdentifier' AS dbclusteridentifier,
  (TO_TIMESTAMP(attrs.provider ->> 'SnapshotCreateTime', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS snapshotcreatetime,
  attrs.provider ->> 'Engine' AS engine,
  (attrs.provider ->> 'AllocatedStorage')::integer AS allocatedstorage,
  attrs.provider ->> 'Status' AS status,
  (attrs.provider ->> 'Port')::integer AS port,
  attrs.provider ->> 'VpcId' AS vpcid,
  (TO_TIMESTAMP(attrs.provider ->> 'ClusterCreateTime', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS clustercreatetime,
  attrs.provider ->> 'MasterUsername' AS masterusername,
  attrs.provider ->> 'EngineVersion' AS engineversion,
  attrs.provider ->> 'LicenseModel' AS licensemodel,
  attrs.provider ->> 'SnapshotType' AS snapshottype,
  (attrs.provider ->> 'PercentProgress')::integer AS percentprogress,
  (attrs.provider ->> 'StorageEncrypted')::boolean AS storageencrypted,
  attrs.provider ->> 'KmsKeyId' AS kmskeyid,
  attrs.provider ->> 'DBClusterSnapshotArn' AS dbclustersnapshotarn,
  attrs.provider ->> 'SourceDBClusterSnapshotArn' AS sourcedbclustersnapshotarn,
  (attrs.provider ->> 'IAMDatabaseAuthenticationEnabled')::boolean AS iamdatabaseauthenticationenabled,
  attrs.provider -> 'TagList' AS taglist,
  attrs.provider -> 'restore' AS restore,
  attrs.metadata -> 'Tags' AS tags,
  
    _kms_key_id.target_id AS _kms_key_id,
    _ec2_vpc_id.target_id AS _ec2_vpc_id,
    _dbcluster_id.target_id AS _dbcluster_id,
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
      _aws_kms_key_relation.relation = 'encrypted-with'
      AND _aws_kms_key_relation.provider_account_id = :provider_account_id
  ) AS _kms_key_id ON _kms_key_id.resource_id = R.id
  LEFT JOIN (
    SELECT
      _aws_ec2_vpc_relation.resource_id AS resource_id,
      _aws_ec2_vpc.id AS target_id
    FROM
      resource_relation AS _aws_ec2_vpc_relation
      INNER JOIN resource AS _aws_ec2_vpc
        ON _aws_ec2_vpc_relation.target_id = _aws_ec2_vpc.id
        AND _aws_ec2_vpc.provider_type = 'Vpc'
        AND _aws_ec2_vpc.service = 'ec2'
        AND _aws_ec2_vpc.provider_account_id = :provider_account_id
    WHERE
      _aws_ec2_vpc_relation.relation = 'in'
      AND _aws_ec2_vpc_relation.provider_account_id = :provider_account_id
  ) AS _ec2_vpc_id ON _ec2_vpc_id.resource_id = R.id
  LEFT JOIN (
    SELECT
      _aws_rds_dbcluster_relation.resource_id AS resource_id,
      _aws_rds_dbcluster.id AS target_id
    FROM
      resource_relation AS _aws_rds_dbcluster_relation
      INNER JOIN resource AS _aws_rds_dbcluster
        ON _aws_rds_dbcluster_relation.target_id = _aws_rds_dbcluster.id
        AND _aws_rds_dbcluster.provider_type = 'DBCluster'
        AND _aws_rds_dbcluster.service = 'rds'
        AND _aws_rds_dbcluster.provider_account_id = :provider_account_id
    WHERE
      _aws_rds_dbcluster_relation.relation = 'imaged'
      AND _aws_rds_dbcluster_relation.provider_account_id = :provider_account_id
  ) AS _dbcluster_id ON _dbcluster_id.resource_id = R.id
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
  AND R.provider_type = 'DBClusterSnapshot'
  AND R.service = 'rds'
ON CONFLICT (_id) DO UPDATE
SET
    AvailabilityZones = EXCLUDED.AvailabilityZones,
    DBClusterSnapshotIdentifier = EXCLUDED.DBClusterSnapshotIdentifier,
    DBClusterIdentifier = EXCLUDED.DBClusterIdentifier,
    SnapshotCreateTime = EXCLUDED.SnapshotCreateTime,
    Engine = EXCLUDED.Engine,
    AllocatedStorage = EXCLUDED.AllocatedStorage,
    Status = EXCLUDED.Status,
    Port = EXCLUDED.Port,
    VpcId = EXCLUDED.VpcId,
    ClusterCreateTime = EXCLUDED.ClusterCreateTime,
    MasterUsername = EXCLUDED.MasterUsername,
    EngineVersion = EXCLUDED.EngineVersion,
    LicenseModel = EXCLUDED.LicenseModel,
    SnapshotType = EXCLUDED.SnapshotType,
    PercentProgress = EXCLUDED.PercentProgress,
    StorageEncrypted = EXCLUDED.StorageEncrypted,
    KmsKeyId = EXCLUDED.KmsKeyId,
    DBClusterSnapshotArn = EXCLUDED.DBClusterSnapshotArn,
    SourceDBClusterSnapshotArn = EXCLUDED.SourceDBClusterSnapshotArn,
    IAMDatabaseAuthenticationEnabled = EXCLUDED.IAMDatabaseAuthenticationEnabled,
    TagList = EXCLUDED.TagList,
    restore = EXCLUDED.restore,
    _tags = EXCLUDED._tags,
    _kms_key_id = EXCLUDED._kms_key_id,
    _ec2_vpc_id = EXCLUDED._ec2_vpc_id,
    _dbcluster_id = EXCLUDED._dbcluster_id,
    _account_id = EXCLUDED._account_id
  ;


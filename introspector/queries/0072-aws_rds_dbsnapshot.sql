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
INSERT INTO aws_rds_dbsnapshot (
  _id,
  uri,
  provider_account_id,
  dbsnapshotidentifier,
  dbinstanceidentifier,
  snapshotcreatetime,
  engine,
  allocatedstorage,
  status,
  port,
  availabilityzone,
  vpcid,
  instancecreatetime,
  masterusername,
  engineversion,
  licensemodel,
  snapshottype,
  iops,
  optiongroupname,
  percentprogress,
  sourceregion,
  sourcedbsnapshotidentifier,
  storagetype,
  tdecredentialarn,
  encrypted,
  kmskeyid,
  dbsnapshotarn,
  timezone,
  iamdatabaseauthenticationenabled,
  processorfeatures,
  dbiresourceid,
  taglist,
  restore,
  _tags,
  _kms_key_id,_ec2_vpc_id,_dbinstance_id,_account_id
)
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  attrs.provider ->> 'DBSnapshotIdentifier' AS dbsnapshotidentifier,
  attrs.provider ->> 'DBInstanceIdentifier' AS dbinstanceidentifier,
  (TO_TIMESTAMP(attrs.provider ->> 'SnapshotCreateTime', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS snapshotcreatetime,
  attrs.provider ->> 'Engine' AS engine,
  (attrs.provider ->> 'AllocatedStorage')::integer AS allocatedstorage,
  attrs.provider ->> 'Status' AS status,
  (attrs.provider ->> 'Port')::integer AS port,
  attrs.provider ->> 'AvailabilityZone' AS availabilityzone,
  attrs.provider ->> 'VpcId' AS vpcid,
  (TO_TIMESTAMP(attrs.provider ->> 'InstanceCreateTime', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS instancecreatetime,
  attrs.provider ->> 'MasterUsername' AS masterusername,
  attrs.provider ->> 'EngineVersion' AS engineversion,
  attrs.provider ->> 'LicenseModel' AS licensemodel,
  attrs.provider ->> 'SnapshotType' AS snapshottype,
  (attrs.provider ->> 'Iops')::integer AS iops,
  attrs.provider ->> 'OptionGroupName' AS optiongroupname,
  (attrs.provider ->> 'PercentProgress')::integer AS percentprogress,
  attrs.provider ->> 'SourceRegion' AS sourceregion,
  attrs.provider ->> 'SourceDBSnapshotIdentifier' AS sourcedbsnapshotidentifier,
  attrs.provider ->> 'StorageType' AS storagetype,
  attrs.provider ->> 'TdeCredentialArn' AS tdecredentialarn,
  (attrs.provider ->> 'Encrypted')::boolean AS encrypted,
  attrs.provider ->> 'KmsKeyId' AS kmskeyid,
  attrs.provider ->> 'DBSnapshotArn' AS dbsnapshotarn,
  attrs.provider ->> 'Timezone' AS timezone,
  (attrs.provider ->> 'IAMDatabaseAuthenticationEnabled')::boolean AS iamdatabaseauthenticationenabled,
  attrs.provider -> 'ProcessorFeatures' AS processorfeatures,
  attrs.provider ->> 'DbiResourceId' AS dbiresourceid,
  attrs.provider -> 'TagList' AS taglist,
  attrs.provider -> 'restore' AS restore,
  attrs.metadata -> 'Tags' AS tags,
  
    _kms_key_id.target_id AS _kms_key_id,
    _ec2_vpc_id.target_id AS _ec2_vpc_id,
    _dbinstance_id.target_id AS _dbinstance_id,
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
      _aws_rds_dbinstance_relation.resource_id AS resource_id,
      _aws_rds_dbinstance.id AS target_id
    FROM
      resource_relation AS _aws_rds_dbinstance_relation
      INNER JOIN resource AS _aws_rds_dbinstance
        ON _aws_rds_dbinstance_relation.target_id = _aws_rds_dbinstance.id
        AND _aws_rds_dbinstance.provider_type = 'DBInstance'
        AND _aws_rds_dbinstance.service = 'rds'
        AND _aws_rds_dbinstance.provider_account_id = :provider_account_id
    WHERE
      _aws_rds_dbinstance_relation.relation = 'imaged'
      AND _aws_rds_dbinstance_relation.provider_account_id = :provider_account_id
  ) AS _dbinstance_id ON _dbinstance_id.resource_id = R.id
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
  AND R.provider_type = 'DBSnapshot'
  AND R.service = 'rds'
ON CONFLICT (_id) DO UPDATE
SET
    DBSnapshotIdentifier = EXCLUDED.DBSnapshotIdentifier,
    DBInstanceIdentifier = EXCLUDED.DBInstanceIdentifier,
    SnapshotCreateTime = EXCLUDED.SnapshotCreateTime,
    Engine = EXCLUDED.Engine,
    AllocatedStorage = EXCLUDED.AllocatedStorage,
    Status = EXCLUDED.Status,
    Port = EXCLUDED.Port,
    AvailabilityZone = EXCLUDED.AvailabilityZone,
    VpcId = EXCLUDED.VpcId,
    InstanceCreateTime = EXCLUDED.InstanceCreateTime,
    MasterUsername = EXCLUDED.MasterUsername,
    EngineVersion = EXCLUDED.EngineVersion,
    LicenseModel = EXCLUDED.LicenseModel,
    SnapshotType = EXCLUDED.SnapshotType,
    Iops = EXCLUDED.Iops,
    OptionGroupName = EXCLUDED.OptionGroupName,
    PercentProgress = EXCLUDED.PercentProgress,
    SourceRegion = EXCLUDED.SourceRegion,
    SourceDBSnapshotIdentifier = EXCLUDED.SourceDBSnapshotIdentifier,
    StorageType = EXCLUDED.StorageType,
    TdeCredentialArn = EXCLUDED.TdeCredentialArn,
    Encrypted = EXCLUDED.Encrypted,
    KmsKeyId = EXCLUDED.KmsKeyId,
    DBSnapshotArn = EXCLUDED.DBSnapshotArn,
    Timezone = EXCLUDED.Timezone,
    IAMDatabaseAuthenticationEnabled = EXCLUDED.IAMDatabaseAuthenticationEnabled,
    ProcessorFeatures = EXCLUDED.ProcessorFeatures,
    DbiResourceId = EXCLUDED.DbiResourceId,
    TagList = EXCLUDED.TagList,
    restore = EXCLUDED.restore,
    _tags = EXCLUDED._tags,
    _kms_key_id = EXCLUDED._kms_key_id,
    _ec2_vpc_id = EXCLUDED._ec2_vpc_id,
    _dbinstance_id = EXCLUDED._dbinstance_id,
    _account_id = EXCLUDED._account_id
  ;


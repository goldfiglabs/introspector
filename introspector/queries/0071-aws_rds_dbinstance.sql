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
INSERT INTO aws_rds_dbinstance (
  _id,
  uri,
  provider_account_id,
  dbinstanceidentifier,
  dbinstanceclass,
  engine,
  dbinstancestatus,
  masterusername,
  dbname,
  endpoint,
  allocatedstorage,
  instancecreatetime,
  preferredbackupwindow,
  backupretentionperiod,
  dbsecuritygroups,
  vpcsecuritygroups,
  dbparametergroups,
  availabilityzone,
  dbsubnetgroup,
  preferredmaintenancewindow,
  pendingmodifiedvalues,
  latestrestorabletime,
  multiaz,
  engineversion,
  autominorversionupgrade,
  readreplicasourcedbinstanceidentifier,
  readreplicadbinstanceidentifiers,
  readreplicadbclusteridentifiers,
  replicamode,
  licensemodel,
  iops,
  optiongroupmemberships,
  charactersetname,
  ncharcharactersetname,
  secondaryavailabilityzone,
  publiclyaccessible,
  statusinfos,
  storagetype,
  tdecredentialarn,
  dbinstanceport,
  dbclusteridentifier,
  storageencrypted,
  kmskeyid,
  dbiresourceid,
  cacertificateidentifier,
  domainmemberships,
  copytagstosnapshot,
  monitoringinterval,
  enhancedmonitoringresourcearn,
  monitoringrolearn,
  promotiontier,
  dbinstancearn,
  timezone,
  iamdatabaseauthenticationenabled,
  performanceinsightsenabled,
  performanceinsightskmskeyid,
  performanceinsightsretentionperiod,
  enabledcloudwatchlogsexports,
  processorfeatures,
  deletionprotection,
  associatedroles,
  listenerendpoint,
  maxallocatedstorage,
  taglist,
  dbinstanceautomatedbackupsreplications,
  customerownedipenabled,
  _tags,
  _dbcluster_id,_account_id
)
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  attrs.provider ->> 'DBInstanceIdentifier' AS dbinstanceidentifier,
  attrs.provider ->> 'DBInstanceClass' AS dbinstanceclass,
  attrs.provider ->> 'Engine' AS engine,
  attrs.provider ->> 'DBInstanceStatus' AS dbinstancestatus,
  attrs.provider ->> 'MasterUsername' AS masterusername,
  attrs.provider ->> 'DBName' AS dbname,
  attrs.provider -> 'Endpoint' AS endpoint,
  (attrs.provider ->> 'AllocatedStorage')::integer AS allocatedstorage,
  (TO_TIMESTAMP(attrs.provider ->> 'InstanceCreateTime', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS instancecreatetime,
  attrs.provider ->> 'PreferredBackupWindow' AS preferredbackupwindow,
  (attrs.provider ->> 'BackupRetentionPeriod')::integer AS backupretentionperiod,
  attrs.provider -> 'DBSecurityGroups' AS dbsecuritygroups,
  attrs.provider -> 'VpcSecurityGroups' AS vpcsecuritygroups,
  attrs.provider -> 'DBParameterGroups' AS dbparametergroups,
  attrs.provider ->> 'AvailabilityZone' AS availabilityzone,
  attrs.provider -> 'DBSubnetGroup' AS dbsubnetgroup,
  attrs.provider ->> 'PreferredMaintenanceWindow' AS preferredmaintenancewindow,
  attrs.provider -> 'PendingModifiedValues' AS pendingmodifiedvalues,
  (TO_TIMESTAMP(attrs.provider ->> 'LatestRestorableTime', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS latestrestorabletime,
  (attrs.provider ->> 'MultiAZ')::boolean AS multiaz,
  attrs.provider ->> 'EngineVersion' AS engineversion,
  (attrs.provider ->> 'AutoMinorVersionUpgrade')::boolean AS autominorversionupgrade,
  attrs.provider ->> 'ReadReplicaSourceDBInstanceIdentifier' AS readreplicasourcedbinstanceidentifier,
  attrs.provider -> 'ReadReplicaDBInstanceIdentifiers' AS readreplicadbinstanceidentifiers,
  attrs.provider -> 'ReadReplicaDBClusterIdentifiers' AS readreplicadbclusteridentifiers,
  attrs.provider ->> 'ReplicaMode' AS replicamode,
  attrs.provider ->> 'LicenseModel' AS licensemodel,
  (attrs.provider ->> 'Iops')::integer AS iops,
  attrs.provider -> 'OptionGroupMemberships' AS optiongroupmemberships,
  attrs.provider ->> 'CharacterSetName' AS charactersetname,
  attrs.provider ->> 'NcharCharacterSetName' AS ncharcharactersetname,
  attrs.provider ->> 'SecondaryAvailabilityZone' AS secondaryavailabilityzone,
  (attrs.provider ->> 'PubliclyAccessible')::boolean AS publiclyaccessible,
  attrs.provider -> 'StatusInfos' AS statusinfos,
  attrs.provider ->> 'StorageType' AS storagetype,
  attrs.provider ->> 'TdeCredentialArn' AS tdecredentialarn,
  (attrs.provider ->> 'DbInstancePort')::integer AS dbinstanceport,
  attrs.provider ->> 'DBClusterIdentifier' AS dbclusteridentifier,
  (attrs.provider ->> 'StorageEncrypted')::boolean AS storageencrypted,
  attrs.provider ->> 'KmsKeyId' AS kmskeyid,
  attrs.provider ->> 'DbiResourceId' AS dbiresourceid,
  attrs.provider ->> 'CACertificateIdentifier' AS cacertificateidentifier,
  attrs.provider -> 'DomainMemberships' AS domainmemberships,
  (attrs.provider ->> 'CopyTagsToSnapshot')::boolean AS copytagstosnapshot,
  (attrs.provider ->> 'MonitoringInterval')::integer AS monitoringinterval,
  attrs.provider ->> 'EnhancedMonitoringResourceArn' AS enhancedmonitoringresourcearn,
  attrs.provider ->> 'MonitoringRoleArn' AS monitoringrolearn,
  (attrs.provider ->> 'PromotionTier')::integer AS promotiontier,
  attrs.provider ->> 'DBInstanceArn' AS dbinstancearn,
  attrs.provider ->> 'Timezone' AS timezone,
  (attrs.provider ->> 'IAMDatabaseAuthenticationEnabled')::boolean AS iamdatabaseauthenticationenabled,
  (attrs.provider ->> 'PerformanceInsightsEnabled')::boolean AS performanceinsightsenabled,
  attrs.provider ->> 'PerformanceInsightsKMSKeyId' AS performanceinsightskmskeyid,
  (attrs.provider ->> 'PerformanceInsightsRetentionPeriod')::integer AS performanceinsightsretentionperiod,
  attrs.provider -> 'EnabledCloudwatchLogsExports' AS enabledcloudwatchlogsexports,
  attrs.provider -> 'ProcessorFeatures' AS processorfeatures,
  (attrs.provider ->> 'DeletionProtection')::boolean AS deletionprotection,
  attrs.provider -> 'AssociatedRoles' AS associatedroles,
  attrs.provider -> 'ListenerEndpoint' AS listenerendpoint,
  (attrs.provider ->> 'MaxAllocatedStorage')::integer AS maxallocatedstorage,
  attrs.provider -> 'TagList' AS taglist,
  attrs.provider -> 'DBInstanceAutomatedBackupsReplications' AS dbinstanceautomatedbackupsreplications,
  (attrs.provider ->> 'CustomerOwnedIpEnabled')::boolean AS customerownedipenabled,
  attrs.metadata -> 'Tags' AS tags,
  
    _dbcluster_id.target_id AS _dbcluster_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  LEFT JOIN attrs ON
    attrs.resource_id = R.id
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
      _aws_rds_dbcluster_relation.relation = 'in'
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
          AND _aws_organizations_account_relation.provider_account_id = :provider_account_id
        GROUP BY _aws_organizations_account_relation.resource_id
        HAVING COUNT(*) = 1
      ) AS unique_account_mapping
  ) AS _account_id ON _account_id.resource_id = R.id
  WHERE
  R.provider_account_id = :provider_account_id
  AND R.provider_type = 'DBInstance'
  AND R.service = 'rds'
ON CONFLICT (_id) DO UPDATE
SET
    DBInstanceIdentifier = EXCLUDED.DBInstanceIdentifier,
    DBInstanceClass = EXCLUDED.DBInstanceClass,
    Engine = EXCLUDED.Engine,
    DBInstanceStatus = EXCLUDED.DBInstanceStatus,
    MasterUsername = EXCLUDED.MasterUsername,
    DBName = EXCLUDED.DBName,
    Endpoint = EXCLUDED.Endpoint,
    AllocatedStorage = EXCLUDED.AllocatedStorage,
    InstanceCreateTime = EXCLUDED.InstanceCreateTime,
    PreferredBackupWindow = EXCLUDED.PreferredBackupWindow,
    BackupRetentionPeriod = EXCLUDED.BackupRetentionPeriod,
    DBSecurityGroups = EXCLUDED.DBSecurityGroups,
    VpcSecurityGroups = EXCLUDED.VpcSecurityGroups,
    DBParameterGroups = EXCLUDED.DBParameterGroups,
    AvailabilityZone = EXCLUDED.AvailabilityZone,
    DBSubnetGroup = EXCLUDED.DBSubnetGroup,
    PreferredMaintenanceWindow = EXCLUDED.PreferredMaintenanceWindow,
    PendingModifiedValues = EXCLUDED.PendingModifiedValues,
    LatestRestorableTime = EXCLUDED.LatestRestorableTime,
    MultiAZ = EXCLUDED.MultiAZ,
    EngineVersion = EXCLUDED.EngineVersion,
    AutoMinorVersionUpgrade = EXCLUDED.AutoMinorVersionUpgrade,
    ReadReplicaSourceDBInstanceIdentifier = EXCLUDED.ReadReplicaSourceDBInstanceIdentifier,
    ReadReplicaDBInstanceIdentifiers = EXCLUDED.ReadReplicaDBInstanceIdentifiers,
    ReadReplicaDBClusterIdentifiers = EXCLUDED.ReadReplicaDBClusterIdentifiers,
    ReplicaMode = EXCLUDED.ReplicaMode,
    LicenseModel = EXCLUDED.LicenseModel,
    Iops = EXCLUDED.Iops,
    OptionGroupMemberships = EXCLUDED.OptionGroupMemberships,
    CharacterSetName = EXCLUDED.CharacterSetName,
    NcharCharacterSetName = EXCLUDED.NcharCharacterSetName,
    SecondaryAvailabilityZone = EXCLUDED.SecondaryAvailabilityZone,
    PubliclyAccessible = EXCLUDED.PubliclyAccessible,
    StatusInfos = EXCLUDED.StatusInfos,
    StorageType = EXCLUDED.StorageType,
    TdeCredentialArn = EXCLUDED.TdeCredentialArn,
    DbInstancePort = EXCLUDED.DbInstancePort,
    DBClusterIdentifier = EXCLUDED.DBClusterIdentifier,
    StorageEncrypted = EXCLUDED.StorageEncrypted,
    KmsKeyId = EXCLUDED.KmsKeyId,
    DbiResourceId = EXCLUDED.DbiResourceId,
    CACertificateIdentifier = EXCLUDED.CACertificateIdentifier,
    DomainMemberships = EXCLUDED.DomainMemberships,
    CopyTagsToSnapshot = EXCLUDED.CopyTagsToSnapshot,
    MonitoringInterval = EXCLUDED.MonitoringInterval,
    EnhancedMonitoringResourceArn = EXCLUDED.EnhancedMonitoringResourceArn,
    MonitoringRoleArn = EXCLUDED.MonitoringRoleArn,
    PromotionTier = EXCLUDED.PromotionTier,
    DBInstanceArn = EXCLUDED.DBInstanceArn,
    Timezone = EXCLUDED.Timezone,
    IAMDatabaseAuthenticationEnabled = EXCLUDED.IAMDatabaseAuthenticationEnabled,
    PerformanceInsightsEnabled = EXCLUDED.PerformanceInsightsEnabled,
    PerformanceInsightsKMSKeyId = EXCLUDED.PerformanceInsightsKMSKeyId,
    PerformanceInsightsRetentionPeriod = EXCLUDED.PerformanceInsightsRetentionPeriod,
    EnabledCloudwatchLogsExports = EXCLUDED.EnabledCloudwatchLogsExports,
    ProcessorFeatures = EXCLUDED.ProcessorFeatures,
    DeletionProtection = EXCLUDED.DeletionProtection,
    AssociatedRoles = EXCLUDED.AssociatedRoles,
    ListenerEndpoint = EXCLUDED.ListenerEndpoint,
    MaxAllocatedStorage = EXCLUDED.MaxAllocatedStorage,
    TagList = EXCLUDED.TagList,
    DBInstanceAutomatedBackupsReplications = EXCLUDED.DBInstanceAutomatedBackupsReplications,
    CustomerOwnedIpEnabled = EXCLUDED.CustomerOwnedIpEnabled,
    _tags = EXCLUDED._tags,
    _dbcluster_id = EXCLUDED._dbcluster_id,
    _account_id = EXCLUDED._account_id
  ;



INSERT INTO aws_rds_dbinstance_ec2_securitygroup
SELECT
  aws_rds_dbinstance.id AS dbinstance_id,
  aws_ec2_securitygroup.id AS securitygroup_id,
  aws_rds_dbinstance.provider_account_id AS provider_account_id
FROM
  resource AS aws_rds_dbinstance
  INNER JOIN resource_relation AS RR
    ON RR.resource_id = aws_rds_dbinstance.id
    AND RR.relation = 'in'
  INNER JOIN resource AS aws_ec2_securitygroup
    ON aws_ec2_securitygroup.id = RR.target_id
    AND aws_ec2_securitygroup.provider_type = 'SecurityGroup'
    AND aws_ec2_securitygroup.service = 'ec2'
    AND aws_ec2_securitygroup.provider_account_id = :provider_account_id
  WHERE
    aws_rds_dbinstance.provider_account_id = :provider_account_id
    AND aws_rds_dbinstance.provider_type = 'DBInstance'
    AND aws_rds_dbinstance.service = 'rds'
ON CONFLICT (dbinstance_id, securitygroup_id)
DO NOTHING
;

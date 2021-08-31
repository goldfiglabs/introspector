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
INSERT INTO aws_rds_dbcluster (
  _id,
  uri,
  provider_account_id,
  allocatedstorage,
  availabilityzones,
  backupretentionperiod,
  charactersetname,
  databasename,
  dbclusteridentifier,
  dbclusterparametergroup,
  dbsubnetgroup,
  status,
  percentprogress,
  earliestrestorabletime,
  endpoint,
  readerendpoint,
  customendpoints,
  multiaz,
  engine,
  engineversion,
  latestrestorabletime,
  port,
  masterusername,
  dbclusteroptiongroupmemberships,
  preferredbackupwindow,
  preferredmaintenancewindow,
  replicationsourceidentifier,
  readreplicaidentifiers,
  dbclustermembers,
  vpcsecuritygroups,
  hostedzoneid,
  storageencrypted,
  kmskeyid,
  dbclusterresourceid,
  dbclusterarn,
  associatedroles,
  iamdatabaseauthenticationenabled,
  clonegroupid,
  clustercreatetime,
  earliestbacktracktime,
  backtrackwindow,
  backtrackconsumedchangerecords,
  enabledcloudwatchlogsexports,
  capacity,
  enginemode,
  scalingconfigurationinfo,
  deletionprotection,
  httpendpointenabled,
  activitystreammode,
  activitystreamstatus,
  activitystreamkmskeyid,
  activitystreamkinesisstreamname,
  copytagstosnapshot,
  crossaccountclone,
  domainmemberships,
  taglist,
  globalwriteforwardingstatus,
  globalwriteforwardingrequested,
  pendingmodifiedvalues,
  _tags,
  _account_id
)
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  (attrs.provider ->> 'AllocatedStorage')::integer AS allocatedstorage,
  attrs.provider -> 'AvailabilityZones' AS availabilityzones,
  (attrs.provider ->> 'BackupRetentionPeriod')::integer AS backupretentionperiod,
  attrs.provider ->> 'CharacterSetName' AS charactersetname,
  attrs.provider ->> 'DatabaseName' AS databasename,
  attrs.provider ->> 'DBClusterIdentifier' AS dbclusteridentifier,
  attrs.provider ->> 'DBClusterParameterGroup' AS dbclusterparametergroup,
  attrs.provider ->> 'DBSubnetGroup' AS dbsubnetgroup,
  attrs.provider ->> 'Status' AS status,
  attrs.provider ->> 'PercentProgress' AS percentprogress,
  (TO_TIMESTAMP(attrs.provider ->> 'EarliestRestorableTime', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS earliestrestorabletime,
  attrs.provider ->> 'Endpoint' AS endpoint,
  attrs.provider ->> 'ReaderEndpoint' AS readerendpoint,
  attrs.provider -> 'CustomEndpoints' AS customendpoints,
  (attrs.provider ->> 'MultiAZ')::boolean AS multiaz,
  attrs.provider ->> 'Engine' AS engine,
  attrs.provider ->> 'EngineVersion' AS engineversion,
  (TO_TIMESTAMP(attrs.provider ->> 'LatestRestorableTime', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS latestrestorabletime,
  (attrs.provider ->> 'Port')::integer AS port,
  attrs.provider ->> 'MasterUsername' AS masterusername,
  attrs.provider -> 'DBClusterOptionGroupMemberships' AS dbclusteroptiongroupmemberships,
  attrs.provider ->> 'PreferredBackupWindow' AS preferredbackupwindow,
  attrs.provider ->> 'PreferredMaintenanceWindow' AS preferredmaintenancewindow,
  attrs.provider ->> 'ReplicationSourceIdentifier' AS replicationsourceidentifier,
  attrs.provider -> 'ReadReplicaIdentifiers' AS readreplicaidentifiers,
  attrs.provider -> 'DBClusterMembers' AS dbclustermembers,
  attrs.provider -> 'VpcSecurityGroups' AS vpcsecuritygroups,
  attrs.provider ->> 'HostedZoneId' AS hostedzoneid,
  (attrs.provider ->> 'StorageEncrypted')::boolean AS storageencrypted,
  attrs.provider ->> 'KmsKeyId' AS kmskeyid,
  attrs.provider ->> 'DbClusterResourceId' AS dbclusterresourceid,
  attrs.provider ->> 'DBClusterArn' AS dbclusterarn,
  attrs.provider -> 'AssociatedRoles' AS associatedroles,
  (attrs.provider ->> 'IAMDatabaseAuthenticationEnabled')::boolean AS iamdatabaseauthenticationenabled,
  attrs.provider ->> 'CloneGroupId' AS clonegroupid,
  (TO_TIMESTAMP(attrs.provider ->> 'ClusterCreateTime', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS clustercreatetime,
  (TO_TIMESTAMP(attrs.provider ->> 'EarliestBacktrackTime', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS earliestbacktracktime,
  (attrs.provider ->> 'BacktrackWindow')::bigint AS backtrackwindow,
  (attrs.provider ->> 'BacktrackConsumedChangeRecords')::bigint AS backtrackconsumedchangerecords,
  attrs.provider -> 'EnabledCloudwatchLogsExports' AS enabledcloudwatchlogsexports,
  (attrs.provider ->> 'Capacity')::integer AS capacity,
  attrs.provider ->> 'EngineMode' AS enginemode,
  attrs.provider -> 'ScalingConfigurationInfo' AS scalingconfigurationinfo,
  (attrs.provider ->> 'DeletionProtection')::boolean AS deletionprotection,
  (attrs.provider ->> 'HttpEndpointEnabled')::boolean AS httpendpointenabled,
  attrs.provider ->> 'ActivityStreamMode' AS activitystreammode,
  attrs.provider ->> 'ActivityStreamStatus' AS activitystreamstatus,
  attrs.provider ->> 'ActivityStreamKmsKeyId' AS activitystreamkmskeyid,
  attrs.provider ->> 'ActivityStreamKinesisStreamName' AS activitystreamkinesisstreamname,
  (attrs.provider ->> 'CopyTagsToSnapshot')::boolean AS copytagstosnapshot,
  (attrs.provider ->> 'CrossAccountClone')::boolean AS crossaccountclone,
  attrs.provider -> 'DomainMemberships' AS domainmemberships,
  attrs.provider -> 'TagList' AS taglist,
  attrs.provider ->> 'GlobalWriteForwardingStatus' AS globalwriteforwardingstatus,
  (attrs.provider ->> 'GlobalWriteForwardingRequested')::boolean AS globalwriteforwardingrequested,
  attrs.provider -> 'PendingModifiedValues' AS pendingmodifiedvalues,
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
  AND R.provider_type = 'DBCluster'
  AND R.service = 'rds'
ON CONFLICT (_id) DO UPDATE
SET
    AllocatedStorage = EXCLUDED.AllocatedStorage,
    AvailabilityZones = EXCLUDED.AvailabilityZones,
    BackupRetentionPeriod = EXCLUDED.BackupRetentionPeriod,
    CharacterSetName = EXCLUDED.CharacterSetName,
    DatabaseName = EXCLUDED.DatabaseName,
    DBClusterIdentifier = EXCLUDED.DBClusterIdentifier,
    DBClusterParameterGroup = EXCLUDED.DBClusterParameterGroup,
    DBSubnetGroup = EXCLUDED.DBSubnetGroup,
    Status = EXCLUDED.Status,
    PercentProgress = EXCLUDED.PercentProgress,
    EarliestRestorableTime = EXCLUDED.EarliestRestorableTime,
    Endpoint = EXCLUDED.Endpoint,
    ReaderEndpoint = EXCLUDED.ReaderEndpoint,
    CustomEndpoints = EXCLUDED.CustomEndpoints,
    MultiAZ = EXCLUDED.MultiAZ,
    Engine = EXCLUDED.Engine,
    EngineVersion = EXCLUDED.EngineVersion,
    LatestRestorableTime = EXCLUDED.LatestRestorableTime,
    Port = EXCLUDED.Port,
    MasterUsername = EXCLUDED.MasterUsername,
    DBClusterOptionGroupMemberships = EXCLUDED.DBClusterOptionGroupMemberships,
    PreferredBackupWindow = EXCLUDED.PreferredBackupWindow,
    PreferredMaintenanceWindow = EXCLUDED.PreferredMaintenanceWindow,
    ReplicationSourceIdentifier = EXCLUDED.ReplicationSourceIdentifier,
    ReadReplicaIdentifiers = EXCLUDED.ReadReplicaIdentifiers,
    DBClusterMembers = EXCLUDED.DBClusterMembers,
    VpcSecurityGroups = EXCLUDED.VpcSecurityGroups,
    HostedZoneId = EXCLUDED.HostedZoneId,
    StorageEncrypted = EXCLUDED.StorageEncrypted,
    KmsKeyId = EXCLUDED.KmsKeyId,
    DbClusterResourceId = EXCLUDED.DbClusterResourceId,
    DBClusterArn = EXCLUDED.DBClusterArn,
    AssociatedRoles = EXCLUDED.AssociatedRoles,
    IAMDatabaseAuthenticationEnabled = EXCLUDED.IAMDatabaseAuthenticationEnabled,
    CloneGroupId = EXCLUDED.CloneGroupId,
    ClusterCreateTime = EXCLUDED.ClusterCreateTime,
    EarliestBacktrackTime = EXCLUDED.EarliestBacktrackTime,
    BacktrackWindow = EXCLUDED.BacktrackWindow,
    BacktrackConsumedChangeRecords = EXCLUDED.BacktrackConsumedChangeRecords,
    EnabledCloudwatchLogsExports = EXCLUDED.EnabledCloudwatchLogsExports,
    Capacity = EXCLUDED.Capacity,
    EngineMode = EXCLUDED.EngineMode,
    ScalingConfigurationInfo = EXCLUDED.ScalingConfigurationInfo,
    DeletionProtection = EXCLUDED.DeletionProtection,
    HttpEndpointEnabled = EXCLUDED.HttpEndpointEnabled,
    ActivityStreamMode = EXCLUDED.ActivityStreamMode,
    ActivityStreamStatus = EXCLUDED.ActivityStreamStatus,
    ActivityStreamKmsKeyId = EXCLUDED.ActivityStreamKmsKeyId,
    ActivityStreamKinesisStreamName = EXCLUDED.ActivityStreamKinesisStreamName,
    CopyTagsToSnapshot = EXCLUDED.CopyTagsToSnapshot,
    CrossAccountClone = EXCLUDED.CrossAccountClone,
    DomainMemberships = EXCLUDED.DomainMemberships,
    TagList = EXCLUDED.TagList,
    GlobalWriteForwardingStatus = EXCLUDED.GlobalWriteForwardingStatus,
    GlobalWriteForwardingRequested = EXCLUDED.GlobalWriteForwardingRequested,
    PendingModifiedValues = EXCLUDED.PendingModifiedValues,
    _tags = EXCLUDED._tags,
    _account_id = EXCLUDED._account_id
  ;



INSERT INTO aws_rds_dbcluster_ec2_securitygroup
SELECT
  aws_rds_dbcluster.id AS dbcluster_id,
  aws_ec2_securitygroup.id AS securitygroup_id,
  aws_rds_dbcluster.provider_account_id AS provider_account_id
FROM
  resource AS aws_rds_dbcluster
  INNER JOIN resource_relation AS RR
    ON RR.resource_id = aws_rds_dbcluster.id
    AND RR.relation = 'in'
  INNER JOIN resource AS aws_ec2_securitygroup
    ON aws_ec2_securitygroup.id = RR.target_id
    AND aws_ec2_securitygroup.provider_type = 'SecurityGroup'
    AND aws_ec2_securitygroup.service = 'ec2'
    AND aws_ec2_securitygroup.provider_account_id = :provider_account_id
  WHERE
    aws_rds_dbcluster.provider_account_id = :provider_account_id
    AND aws_rds_dbcluster.provider_type = 'DBCluster'
    AND aws_rds_dbcluster.service = 'rds'
ON CONFLICT (dbcluster_id, securitygroup_id)
DO NOTHING
;

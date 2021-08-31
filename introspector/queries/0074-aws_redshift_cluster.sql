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
INSERT INTO aws_redshift_cluster (
  _id,
  uri,
  provider_account_id,
  clusteridentifier,
  nodetype,
  clusterstatus,
  clusteravailabilitystatus,
  modifystatus,
  masterusername,
  dbname,
  endpoint,
  clustercreatetime,
  automatedsnapshotretentionperiod,
  manualsnapshotretentionperiod,
  clustersecuritygroups,
  vpcsecuritygroups,
  clusterparametergroups,
  clustersubnetgroupname,
  vpcid,
  availabilityzone,
  preferredmaintenancewindow,
  pendingmodifiedvalues,
  clusterversion,
  allowversionupgrade,
  numberofnodes,
  publiclyaccessible,
  encrypted,
  restorestatus,
  datatransferprogress,
  hsmstatus,
  clustersnapshotcopystatus,
  clusterpublickey,
  clusternodes,
  elasticipstatus,
  clusterrevisionnumber,
  tags,
  kmskeyid,
  enhancedvpcrouting,
  iamroles,
  pendingactions,
  maintenancetrackname,
  elasticresizenumberofnodeoptions,
  deferredmaintenancewindows,
  snapshotscheduleidentifier,
  snapshotschedulestate,
  expectednextsnapshotscheduletime,
  expectednextsnapshotscheduletimestatus,
  nextmaintenancewindowstarttime,
  resizeinfo,
  availabilityzonerelocationstatus,
  clusternamespacearn,
  loggingstatus,
  _tags,
  _kms_key_id,_ec2_vpc_id,_account_id
)
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  attrs.provider ->> 'ClusterIdentifier' AS clusteridentifier,
  attrs.provider ->> 'NodeType' AS nodetype,
  attrs.provider ->> 'ClusterStatus' AS clusterstatus,
  attrs.provider ->> 'ClusterAvailabilityStatus' AS clusteravailabilitystatus,
  attrs.provider ->> 'ModifyStatus' AS modifystatus,
  attrs.provider ->> 'MasterUsername' AS masterusername,
  attrs.provider ->> 'DBName' AS dbname,
  attrs.provider -> 'Endpoint' AS endpoint,
  (TO_TIMESTAMP(attrs.provider ->> 'ClusterCreateTime', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS clustercreatetime,
  (attrs.provider ->> 'AutomatedSnapshotRetentionPeriod')::integer AS automatedsnapshotretentionperiod,
  (attrs.provider ->> 'ManualSnapshotRetentionPeriod')::integer AS manualsnapshotretentionperiod,
  attrs.provider -> 'ClusterSecurityGroups' AS clustersecuritygroups,
  attrs.provider -> 'VpcSecurityGroups' AS vpcsecuritygroups,
  attrs.provider -> 'ClusterParameterGroups' AS clusterparametergroups,
  attrs.provider ->> 'ClusterSubnetGroupName' AS clustersubnetgroupname,
  attrs.provider ->> 'VpcId' AS vpcid,
  attrs.provider ->> 'AvailabilityZone' AS availabilityzone,
  attrs.provider ->> 'PreferredMaintenanceWindow' AS preferredmaintenancewindow,
  attrs.provider -> 'PendingModifiedValues' AS pendingmodifiedvalues,
  attrs.provider ->> 'ClusterVersion' AS clusterversion,
  (attrs.provider ->> 'AllowVersionUpgrade')::boolean AS allowversionupgrade,
  (attrs.provider ->> 'NumberOfNodes')::integer AS numberofnodes,
  (attrs.provider ->> 'PubliclyAccessible')::boolean AS publiclyaccessible,
  (attrs.provider ->> 'Encrypted')::boolean AS encrypted,
  attrs.provider -> 'RestoreStatus' AS restorestatus,
  attrs.provider -> 'DataTransferProgress' AS datatransferprogress,
  attrs.provider -> 'HsmStatus' AS hsmstatus,
  attrs.provider -> 'ClusterSnapshotCopyStatus' AS clustersnapshotcopystatus,
  attrs.provider ->> 'ClusterPublicKey' AS clusterpublickey,
  attrs.provider -> 'ClusterNodes' AS clusternodes,
  attrs.provider -> 'ElasticIpStatus' AS elasticipstatus,
  attrs.provider ->> 'ClusterRevisionNumber' AS clusterrevisionnumber,
  attrs.provider -> 'Tags' AS tags,
  attrs.provider ->> 'KmsKeyId' AS kmskeyid,
  (attrs.provider ->> 'EnhancedVpcRouting')::boolean AS enhancedvpcrouting,
  attrs.provider -> 'IamRoles' AS iamroles,
  attrs.provider -> 'PendingActions' AS pendingactions,
  attrs.provider ->> 'MaintenanceTrackName' AS maintenancetrackname,
  attrs.provider ->> 'ElasticResizeNumberOfNodeOptions' AS elasticresizenumberofnodeoptions,
  attrs.provider -> 'DeferredMaintenanceWindows' AS deferredmaintenancewindows,
  attrs.provider ->> 'SnapshotScheduleIdentifier' AS snapshotscheduleidentifier,
  attrs.provider ->> 'SnapshotScheduleState' AS snapshotschedulestate,
  (TO_TIMESTAMP(attrs.provider ->> 'ExpectedNextSnapshotScheduleTime', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS expectednextsnapshotscheduletime,
  attrs.provider ->> 'ExpectedNextSnapshotScheduleTimeStatus' AS expectednextsnapshotscheduletimestatus,
  (TO_TIMESTAMP(attrs.provider ->> 'NextMaintenanceWindowStartTime', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS nextmaintenancewindowstarttime,
  attrs.provider -> 'ResizeInfo' AS resizeinfo,
  attrs.provider ->> 'AvailabilityZoneRelocationStatus' AS availabilityzonerelocationstatus,
  attrs.provider ->> 'ClusterNamespaceArn' AS clusternamespacearn,
  attrs.provider -> 'LoggingStatus' AS loggingstatus,
  attrs.metadata -> 'Tags' AS tags,
  
    _kms_key_id.target_id AS _kms_key_id,
    _ec2_vpc_id.target_id AS _ec2_vpc_id,
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
      _aws_kms_key_relation.relation = 'encrypts'
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
  AND R.provider_type = 'Cluster'
  AND R.service = 'redshift'
ON CONFLICT (_id) DO UPDATE
SET
    ClusterIdentifier = EXCLUDED.ClusterIdentifier,
    NodeType = EXCLUDED.NodeType,
    ClusterStatus = EXCLUDED.ClusterStatus,
    ClusterAvailabilityStatus = EXCLUDED.ClusterAvailabilityStatus,
    ModifyStatus = EXCLUDED.ModifyStatus,
    MasterUsername = EXCLUDED.MasterUsername,
    DBName = EXCLUDED.DBName,
    Endpoint = EXCLUDED.Endpoint,
    ClusterCreateTime = EXCLUDED.ClusterCreateTime,
    AutomatedSnapshotRetentionPeriod = EXCLUDED.AutomatedSnapshotRetentionPeriod,
    ManualSnapshotRetentionPeriod = EXCLUDED.ManualSnapshotRetentionPeriod,
    ClusterSecurityGroups = EXCLUDED.ClusterSecurityGroups,
    VpcSecurityGroups = EXCLUDED.VpcSecurityGroups,
    ClusterParameterGroups = EXCLUDED.ClusterParameterGroups,
    ClusterSubnetGroupName = EXCLUDED.ClusterSubnetGroupName,
    VpcId = EXCLUDED.VpcId,
    AvailabilityZone = EXCLUDED.AvailabilityZone,
    PreferredMaintenanceWindow = EXCLUDED.PreferredMaintenanceWindow,
    PendingModifiedValues = EXCLUDED.PendingModifiedValues,
    ClusterVersion = EXCLUDED.ClusterVersion,
    AllowVersionUpgrade = EXCLUDED.AllowVersionUpgrade,
    NumberOfNodes = EXCLUDED.NumberOfNodes,
    PubliclyAccessible = EXCLUDED.PubliclyAccessible,
    Encrypted = EXCLUDED.Encrypted,
    RestoreStatus = EXCLUDED.RestoreStatus,
    DataTransferProgress = EXCLUDED.DataTransferProgress,
    HsmStatus = EXCLUDED.HsmStatus,
    ClusterSnapshotCopyStatus = EXCLUDED.ClusterSnapshotCopyStatus,
    ClusterPublicKey = EXCLUDED.ClusterPublicKey,
    ClusterNodes = EXCLUDED.ClusterNodes,
    ElasticIpStatus = EXCLUDED.ElasticIpStatus,
    ClusterRevisionNumber = EXCLUDED.ClusterRevisionNumber,
    Tags = EXCLUDED.Tags,
    KmsKeyId = EXCLUDED.KmsKeyId,
    EnhancedVpcRouting = EXCLUDED.EnhancedVpcRouting,
    IamRoles = EXCLUDED.IamRoles,
    PendingActions = EXCLUDED.PendingActions,
    MaintenanceTrackName = EXCLUDED.MaintenanceTrackName,
    ElasticResizeNumberOfNodeOptions = EXCLUDED.ElasticResizeNumberOfNodeOptions,
    DeferredMaintenanceWindows = EXCLUDED.DeferredMaintenanceWindows,
    SnapshotScheduleIdentifier = EXCLUDED.SnapshotScheduleIdentifier,
    SnapshotScheduleState = EXCLUDED.SnapshotScheduleState,
    ExpectedNextSnapshotScheduleTime = EXCLUDED.ExpectedNextSnapshotScheduleTime,
    ExpectedNextSnapshotScheduleTimeStatus = EXCLUDED.ExpectedNextSnapshotScheduleTimeStatus,
    NextMaintenanceWindowStartTime = EXCLUDED.NextMaintenanceWindowStartTime,
    ResizeInfo = EXCLUDED.ResizeInfo,
    AvailabilityZoneRelocationStatus = EXCLUDED.AvailabilityZoneRelocationStatus,
    ClusterNamespaceArn = EXCLUDED.ClusterNamespaceArn,
    LoggingStatus = EXCLUDED.LoggingStatus,
    _tags = EXCLUDED._tags,
    _kms_key_id = EXCLUDED._kms_key_id,
    _ec2_vpc_id = EXCLUDED._ec2_vpc_id,
    _account_id = EXCLUDED._account_id
  ;



INSERT INTO aws_redshift_cluster_ec2_securitygroup
SELECT
  aws_redshift_cluster.id AS cluster_id,
  aws_ec2_securitygroup.id AS securitygroup_id,
  aws_redshift_cluster.provider_account_id AS provider_account_id,
  Status.value #>> '{}' AS status
FROM
  resource AS aws_redshift_cluster
  INNER JOIN resource_relation AS RR
    ON RR.resource_id = aws_redshift_cluster.id
    AND RR.relation = 'in'
  INNER JOIN resource AS aws_ec2_securitygroup
    ON aws_ec2_securitygroup.id = RR.target_id
    AND aws_ec2_securitygroup.provider_type = 'SecurityGroup'
    AND aws_ec2_securitygroup.service = 'ec2'
    AND aws_ec2_securitygroup.provider_account_id = :provider_account_id
  LEFT JOIN resource_relation_attribute AS Status
    ON Status.relation_id = RR.id
    AND Status.name = 'Status'
  WHERE
    aws_redshift_cluster.provider_account_id = :provider_account_id
    AND aws_redshift_cluster.provider_type = 'Cluster'
    AND aws_redshift_cluster.service = 'redshift'
ON CONFLICT (cluster_id, securitygroup_id)

DO UPDATE
SET
  
  Status = EXCLUDED.Status;

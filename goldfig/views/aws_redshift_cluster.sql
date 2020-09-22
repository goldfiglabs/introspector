DROP MATERIALIZED VIEW IF EXISTS aws_redshift_cluster CASCADE;

CREATE MATERIALIZED VIEW aws_redshift_cluster AS
WITH attrs AS (
  SELECT
    R.id,
    LOWER(RA.attr_name) AS attr_name,
    RA.attr_value
  FROM
    resource AS R
    INNER JOIN resource_attribute AS RA
      ON RA.resource_id = R.id
  WHERE
    RA.type = 'provider'
)
SELECT
  R.id AS resource_id,
  R.uri,
  R.provider_account_id,
  clusteridentifier.attr_value #>> '{}' AS clusteridentifier,
  nodetype.attr_value #>> '{}' AS nodetype,
  clusterstatus.attr_value #>> '{}' AS clusterstatus,
  clusteravailabilitystatus.attr_value #>> '{}' AS clusteravailabilitystatus,
  modifystatus.attr_value #>> '{}' AS modifystatus,
  masterusername.attr_value #>> '{}' AS masterusername,
  dbname.attr_value #>> '{}' AS dbname,
  endpoint.attr_value::jsonb AS endpoint,
  (TO_TIMESTAMP(clustercreatetime.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS clustercreatetime,
  (automatedsnapshotretentionperiod.attr_value #>> '{}')::integer AS automatedsnapshotretentionperiod,
  (manualsnapshotretentionperiod.attr_value #>> '{}')::integer AS manualsnapshotretentionperiod,
  clustersecuritygroups.attr_value::jsonb AS clustersecuritygroups,
  vpcsecuritygroups.attr_value::jsonb AS vpcsecuritygroups,
  clusterparametergroups.attr_value::jsonb AS clusterparametergroups,
  clustersubnetgroupname.attr_value #>> '{}' AS clustersubnetgroupname,
  vpcid.attr_value #>> '{}' AS vpcid,
  availabilityzone.attr_value #>> '{}' AS availabilityzone,
  preferredmaintenancewindow.attr_value #>> '{}' AS preferredmaintenancewindow,
  pendingmodifiedvalues.attr_value::jsonb AS pendingmodifiedvalues,
  clusterversion.attr_value #>> '{}' AS clusterversion,
  (allowversionupgrade.attr_value #>> '{}')::boolean AS allowversionupgrade,
  (numberofnodes.attr_value #>> '{}')::integer AS numberofnodes,
  (publiclyaccessible.attr_value #>> '{}')::boolean AS publiclyaccessible,
  (encrypted.attr_value #>> '{}')::boolean AS encrypted,
  restorestatus.attr_value::jsonb AS restorestatus,
  datatransferprogress.attr_value::jsonb AS datatransferprogress,
  hsmstatus.attr_value::jsonb AS hsmstatus,
  clustersnapshotcopystatus.attr_value::jsonb AS clustersnapshotcopystatus,
  clusterpublickey.attr_value #>> '{}' AS clusterpublickey,
  clusternodes.attr_value::jsonb AS clusternodes,
  elasticipstatus.attr_value::jsonb AS elasticipstatus,
  clusterrevisionnumber.attr_value #>> '{}' AS clusterrevisionnumber,
  tags.attr_value::jsonb AS tags,
  kmskeyid.attr_value #>> '{}' AS kmskeyid,
  (enhancedvpcrouting.attr_value #>> '{}')::boolean AS enhancedvpcrouting,
  iamroles.attr_value::jsonb AS iamroles,
  pendingactions.attr_value::jsonb AS pendingactions,
  maintenancetrackname.attr_value #>> '{}' AS maintenancetrackname,
  elasticresizenumberofnodeoptions.attr_value #>> '{}' AS elasticresizenumberofnodeoptions,
  deferredmaintenancewindows.attr_value::jsonb AS deferredmaintenancewindows,
  snapshotscheduleidentifier.attr_value #>> '{}' AS snapshotscheduleidentifier,
  snapshotschedulestate.attr_value #>> '{}' AS snapshotschedulestate,
  (TO_TIMESTAMP(expectednextsnapshotscheduletime.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS expectednextsnapshotscheduletime,
  expectednextsnapshotscheduletimestatus.attr_value #>> '{}' AS expectednextsnapshotscheduletimestatus,
  (TO_TIMESTAMP(nextmaintenancewindowstarttime.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS nextmaintenancewindowstarttime,
  resizeinfo.attr_value::jsonb AS resizeinfo,
  
    _kms_key_id.target_id AS _kms_key_id,
    _ec2_vpc_id.target_id AS _ec2_vpc_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN attrs AS clusteridentifier
    ON clusteridentifier.id = R.id
    AND clusteridentifier.attr_name = 'clusteridentifier'
  LEFT JOIN attrs AS nodetype
    ON nodetype.id = R.id
    AND nodetype.attr_name = 'nodetype'
  LEFT JOIN attrs AS clusterstatus
    ON clusterstatus.id = R.id
    AND clusterstatus.attr_name = 'clusterstatus'
  LEFT JOIN attrs AS clusteravailabilitystatus
    ON clusteravailabilitystatus.id = R.id
    AND clusteravailabilitystatus.attr_name = 'clusteravailabilitystatus'
  LEFT JOIN attrs AS modifystatus
    ON modifystatus.id = R.id
    AND modifystatus.attr_name = 'modifystatus'
  LEFT JOIN attrs AS masterusername
    ON masterusername.id = R.id
    AND masterusername.attr_name = 'masterusername'
  LEFT JOIN attrs AS dbname
    ON dbname.id = R.id
    AND dbname.attr_name = 'dbname'
  LEFT JOIN attrs AS endpoint
    ON endpoint.id = R.id
    AND endpoint.attr_name = 'endpoint'
  LEFT JOIN attrs AS clustercreatetime
    ON clustercreatetime.id = R.id
    AND clustercreatetime.attr_name = 'clustercreatetime'
  LEFT JOIN attrs AS automatedsnapshotretentionperiod
    ON automatedsnapshotretentionperiod.id = R.id
    AND automatedsnapshotretentionperiod.attr_name = 'automatedsnapshotretentionperiod'
  LEFT JOIN attrs AS manualsnapshotretentionperiod
    ON manualsnapshotretentionperiod.id = R.id
    AND manualsnapshotretentionperiod.attr_name = 'manualsnapshotretentionperiod'
  LEFT JOIN attrs AS clustersecuritygroups
    ON clustersecuritygroups.id = R.id
    AND clustersecuritygroups.attr_name = 'clustersecuritygroups'
  LEFT JOIN attrs AS vpcsecuritygroups
    ON vpcsecuritygroups.id = R.id
    AND vpcsecuritygroups.attr_name = 'vpcsecuritygroups'
  LEFT JOIN attrs AS clusterparametergroups
    ON clusterparametergroups.id = R.id
    AND clusterparametergroups.attr_name = 'clusterparametergroups'
  LEFT JOIN attrs AS clustersubnetgroupname
    ON clustersubnetgroupname.id = R.id
    AND clustersubnetgroupname.attr_name = 'clustersubnetgroupname'
  LEFT JOIN attrs AS vpcid
    ON vpcid.id = R.id
    AND vpcid.attr_name = 'vpcid'
  LEFT JOIN attrs AS availabilityzone
    ON availabilityzone.id = R.id
    AND availabilityzone.attr_name = 'availabilityzone'
  LEFT JOIN attrs AS preferredmaintenancewindow
    ON preferredmaintenancewindow.id = R.id
    AND preferredmaintenancewindow.attr_name = 'preferredmaintenancewindow'
  LEFT JOIN attrs AS pendingmodifiedvalues
    ON pendingmodifiedvalues.id = R.id
    AND pendingmodifiedvalues.attr_name = 'pendingmodifiedvalues'
  LEFT JOIN attrs AS clusterversion
    ON clusterversion.id = R.id
    AND clusterversion.attr_name = 'clusterversion'
  LEFT JOIN attrs AS allowversionupgrade
    ON allowversionupgrade.id = R.id
    AND allowversionupgrade.attr_name = 'allowversionupgrade'
  LEFT JOIN attrs AS numberofnodes
    ON numberofnodes.id = R.id
    AND numberofnodes.attr_name = 'numberofnodes'
  LEFT JOIN attrs AS publiclyaccessible
    ON publiclyaccessible.id = R.id
    AND publiclyaccessible.attr_name = 'publiclyaccessible'
  LEFT JOIN attrs AS encrypted
    ON encrypted.id = R.id
    AND encrypted.attr_name = 'encrypted'
  LEFT JOIN attrs AS restorestatus
    ON restorestatus.id = R.id
    AND restorestatus.attr_name = 'restorestatus'
  LEFT JOIN attrs AS datatransferprogress
    ON datatransferprogress.id = R.id
    AND datatransferprogress.attr_name = 'datatransferprogress'
  LEFT JOIN attrs AS hsmstatus
    ON hsmstatus.id = R.id
    AND hsmstatus.attr_name = 'hsmstatus'
  LEFT JOIN attrs AS clustersnapshotcopystatus
    ON clustersnapshotcopystatus.id = R.id
    AND clustersnapshotcopystatus.attr_name = 'clustersnapshotcopystatus'
  LEFT JOIN attrs AS clusterpublickey
    ON clusterpublickey.id = R.id
    AND clusterpublickey.attr_name = 'clusterpublickey'
  LEFT JOIN attrs AS clusternodes
    ON clusternodes.id = R.id
    AND clusternodes.attr_name = 'clusternodes'
  LEFT JOIN attrs AS elasticipstatus
    ON elasticipstatus.id = R.id
    AND elasticipstatus.attr_name = 'elasticipstatus'
  LEFT JOIN attrs AS clusterrevisionnumber
    ON clusterrevisionnumber.id = R.id
    AND clusterrevisionnumber.attr_name = 'clusterrevisionnumber'
  LEFT JOIN attrs AS tags
    ON tags.id = R.id
    AND tags.attr_name = 'tags'
  LEFT JOIN attrs AS kmskeyid
    ON kmskeyid.id = R.id
    AND kmskeyid.attr_name = 'kmskeyid'
  LEFT JOIN attrs AS enhancedvpcrouting
    ON enhancedvpcrouting.id = R.id
    AND enhancedvpcrouting.attr_name = 'enhancedvpcrouting'
  LEFT JOIN attrs AS iamroles
    ON iamroles.id = R.id
    AND iamroles.attr_name = 'iamroles'
  LEFT JOIN attrs AS pendingactions
    ON pendingactions.id = R.id
    AND pendingactions.attr_name = 'pendingactions'
  LEFT JOIN attrs AS maintenancetrackname
    ON maintenancetrackname.id = R.id
    AND maintenancetrackname.attr_name = 'maintenancetrackname'
  LEFT JOIN attrs AS elasticresizenumberofnodeoptions
    ON elasticresizenumberofnodeoptions.id = R.id
    AND elasticresizenumberofnodeoptions.attr_name = 'elasticresizenumberofnodeoptions'
  LEFT JOIN attrs AS deferredmaintenancewindows
    ON deferredmaintenancewindows.id = R.id
    AND deferredmaintenancewindows.attr_name = 'deferredmaintenancewindows'
  LEFT JOIN attrs AS snapshotscheduleidentifier
    ON snapshotscheduleidentifier.id = R.id
    AND snapshotscheduleidentifier.attr_name = 'snapshotscheduleidentifier'
  LEFT JOIN attrs AS snapshotschedulestate
    ON snapshotschedulestate.id = R.id
    AND snapshotschedulestate.attr_name = 'snapshotschedulestate'
  LEFT JOIN attrs AS expectednextsnapshotscheduletime
    ON expectednextsnapshotscheduletime.id = R.id
    AND expectednextsnapshotscheduletime.attr_name = 'expectednextsnapshotscheduletime'
  LEFT JOIN attrs AS expectednextsnapshotscheduletimestatus
    ON expectednextsnapshotscheduletimestatus.id = R.id
    AND expectednextsnapshotscheduletimestatus.attr_name = 'expectednextsnapshotscheduletimestatus'
  LEFT JOIN attrs AS nextmaintenancewindowstarttime
    ON nextmaintenancewindowstarttime.id = R.id
    AND nextmaintenancewindowstarttime.attr_name = 'nextmaintenancewindowstarttime'
  LEFT JOIN attrs AS resizeinfo
    ON resizeinfo.id = R.id
    AND resizeinfo.attr_name = 'resizeinfo'
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
      _aws_kms_key_relation.relation = 'encrypts'
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
    WHERE
      _aws_ec2_vpc_relation.relation = 'in'
  ) AS _ec2_vpc_id ON _ec2_vpc_id.resource_id = R.id
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
  AND LOWER(R.provider_type) = 'cluster'
  AND R.service = 'redshift'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_redshift_cluster;

COMMENT ON MATERIALIZED VIEW aws_redshift_cluster IS 'redshift cluster resources and their associated attributes.';



DROP MATERIALIZED VIEW IF EXISTS aws_redshift_cluster_ec2_securitygroup CASCADE;

CREATE MATERIALIZED VIEW aws_redshift_cluster_ec2_securitygroup AS
SELECT
  aws_redshift_cluster.id AS cluster_id,
  aws_ec2_securitygroup.id AS securitygroup_id,
  Status.value #>> '{}' AS status
FROM
  resource AS aws_redshift_cluster
  INNER JOIN resource_relation AS RR
    ON RR.resource_id = aws_redshift_cluster.id
    AND RR.relation = 'in'
  INNER JOIN resource AS aws_ec2_securitygroup
    ON aws_ec2_securitygroup.id = RR.target_id
    AND aws_ec2_securitygroup.provider_type = 'SecurityGroup'
  LEFT JOIN resource_relation_attribute AS Status
    ON Status.relation_id = RR.id
    AND Status.name = 'Status'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_redshift_cluster_ec2_securitygroup;

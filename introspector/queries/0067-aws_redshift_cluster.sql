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
  clusternamespacearn,
  loggingstatus,
  _tags,
  _kms_key_id,_ec2_vpc_id,_account_id
)
SELECT
  R.id AS _id,
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
  clusternamespacearn.attr_value #>> '{}' AS clusternamespacearn,
  loggingstatus.attr_value::jsonb AS loggingstatus,
  _tags.attr_value::jsonb AS _tags,
  
    _kms_key_id.target_id AS _kms_key_id,
    _ec2_vpc_id.target_id AS _ec2_vpc_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN resource_attribute AS clusteridentifier
    ON clusteridentifier.resource_id = R.id
    AND clusteridentifier.type = 'provider'
    AND lower(clusteridentifier.attr_name) = 'clusteridentifier'
  LEFT JOIN resource_attribute AS nodetype
    ON nodetype.resource_id = R.id
    AND nodetype.type = 'provider'
    AND lower(nodetype.attr_name) = 'nodetype'
  LEFT JOIN resource_attribute AS clusterstatus
    ON clusterstatus.resource_id = R.id
    AND clusterstatus.type = 'provider'
    AND lower(clusterstatus.attr_name) = 'clusterstatus'
  LEFT JOIN resource_attribute AS clusteravailabilitystatus
    ON clusteravailabilitystatus.resource_id = R.id
    AND clusteravailabilitystatus.type = 'provider'
    AND lower(clusteravailabilitystatus.attr_name) = 'clusteravailabilitystatus'
  LEFT JOIN resource_attribute AS modifystatus
    ON modifystatus.resource_id = R.id
    AND modifystatus.type = 'provider'
    AND lower(modifystatus.attr_name) = 'modifystatus'
  LEFT JOIN resource_attribute AS masterusername
    ON masterusername.resource_id = R.id
    AND masterusername.type = 'provider'
    AND lower(masterusername.attr_name) = 'masterusername'
  LEFT JOIN resource_attribute AS dbname
    ON dbname.resource_id = R.id
    AND dbname.type = 'provider'
    AND lower(dbname.attr_name) = 'dbname'
  LEFT JOIN resource_attribute AS endpoint
    ON endpoint.resource_id = R.id
    AND endpoint.type = 'provider'
    AND lower(endpoint.attr_name) = 'endpoint'
  LEFT JOIN resource_attribute AS clustercreatetime
    ON clustercreatetime.resource_id = R.id
    AND clustercreatetime.type = 'provider'
    AND lower(clustercreatetime.attr_name) = 'clustercreatetime'
  LEFT JOIN resource_attribute AS automatedsnapshotretentionperiod
    ON automatedsnapshotretentionperiod.resource_id = R.id
    AND automatedsnapshotretentionperiod.type = 'provider'
    AND lower(automatedsnapshotretentionperiod.attr_name) = 'automatedsnapshotretentionperiod'
  LEFT JOIN resource_attribute AS manualsnapshotretentionperiod
    ON manualsnapshotretentionperiod.resource_id = R.id
    AND manualsnapshotretentionperiod.type = 'provider'
    AND lower(manualsnapshotretentionperiod.attr_name) = 'manualsnapshotretentionperiod'
  LEFT JOIN resource_attribute AS clustersecuritygroups
    ON clustersecuritygroups.resource_id = R.id
    AND clustersecuritygroups.type = 'provider'
    AND lower(clustersecuritygroups.attr_name) = 'clustersecuritygroups'
  LEFT JOIN resource_attribute AS vpcsecuritygroups
    ON vpcsecuritygroups.resource_id = R.id
    AND vpcsecuritygroups.type = 'provider'
    AND lower(vpcsecuritygroups.attr_name) = 'vpcsecuritygroups'
  LEFT JOIN resource_attribute AS clusterparametergroups
    ON clusterparametergroups.resource_id = R.id
    AND clusterparametergroups.type = 'provider'
    AND lower(clusterparametergroups.attr_name) = 'clusterparametergroups'
  LEFT JOIN resource_attribute AS clustersubnetgroupname
    ON clustersubnetgroupname.resource_id = R.id
    AND clustersubnetgroupname.type = 'provider'
    AND lower(clustersubnetgroupname.attr_name) = 'clustersubnetgroupname'
  LEFT JOIN resource_attribute AS vpcid
    ON vpcid.resource_id = R.id
    AND vpcid.type = 'provider'
    AND lower(vpcid.attr_name) = 'vpcid'
  LEFT JOIN resource_attribute AS availabilityzone
    ON availabilityzone.resource_id = R.id
    AND availabilityzone.type = 'provider'
    AND lower(availabilityzone.attr_name) = 'availabilityzone'
  LEFT JOIN resource_attribute AS preferredmaintenancewindow
    ON preferredmaintenancewindow.resource_id = R.id
    AND preferredmaintenancewindow.type = 'provider'
    AND lower(preferredmaintenancewindow.attr_name) = 'preferredmaintenancewindow'
  LEFT JOIN resource_attribute AS pendingmodifiedvalues
    ON pendingmodifiedvalues.resource_id = R.id
    AND pendingmodifiedvalues.type = 'provider'
    AND lower(pendingmodifiedvalues.attr_name) = 'pendingmodifiedvalues'
  LEFT JOIN resource_attribute AS clusterversion
    ON clusterversion.resource_id = R.id
    AND clusterversion.type = 'provider'
    AND lower(clusterversion.attr_name) = 'clusterversion'
  LEFT JOIN resource_attribute AS allowversionupgrade
    ON allowversionupgrade.resource_id = R.id
    AND allowversionupgrade.type = 'provider'
    AND lower(allowversionupgrade.attr_name) = 'allowversionupgrade'
  LEFT JOIN resource_attribute AS numberofnodes
    ON numberofnodes.resource_id = R.id
    AND numberofnodes.type = 'provider'
    AND lower(numberofnodes.attr_name) = 'numberofnodes'
  LEFT JOIN resource_attribute AS publiclyaccessible
    ON publiclyaccessible.resource_id = R.id
    AND publiclyaccessible.type = 'provider'
    AND lower(publiclyaccessible.attr_name) = 'publiclyaccessible'
  LEFT JOIN resource_attribute AS encrypted
    ON encrypted.resource_id = R.id
    AND encrypted.type = 'provider'
    AND lower(encrypted.attr_name) = 'encrypted'
  LEFT JOIN resource_attribute AS restorestatus
    ON restorestatus.resource_id = R.id
    AND restorestatus.type = 'provider'
    AND lower(restorestatus.attr_name) = 'restorestatus'
  LEFT JOIN resource_attribute AS datatransferprogress
    ON datatransferprogress.resource_id = R.id
    AND datatransferprogress.type = 'provider'
    AND lower(datatransferprogress.attr_name) = 'datatransferprogress'
  LEFT JOIN resource_attribute AS hsmstatus
    ON hsmstatus.resource_id = R.id
    AND hsmstatus.type = 'provider'
    AND lower(hsmstatus.attr_name) = 'hsmstatus'
  LEFT JOIN resource_attribute AS clustersnapshotcopystatus
    ON clustersnapshotcopystatus.resource_id = R.id
    AND clustersnapshotcopystatus.type = 'provider'
    AND lower(clustersnapshotcopystatus.attr_name) = 'clustersnapshotcopystatus'
  LEFT JOIN resource_attribute AS clusterpublickey
    ON clusterpublickey.resource_id = R.id
    AND clusterpublickey.type = 'provider'
    AND lower(clusterpublickey.attr_name) = 'clusterpublickey'
  LEFT JOIN resource_attribute AS clusternodes
    ON clusternodes.resource_id = R.id
    AND clusternodes.type = 'provider'
    AND lower(clusternodes.attr_name) = 'clusternodes'
  LEFT JOIN resource_attribute AS elasticipstatus
    ON elasticipstatus.resource_id = R.id
    AND elasticipstatus.type = 'provider'
    AND lower(elasticipstatus.attr_name) = 'elasticipstatus'
  LEFT JOIN resource_attribute AS clusterrevisionnumber
    ON clusterrevisionnumber.resource_id = R.id
    AND clusterrevisionnumber.type = 'provider'
    AND lower(clusterrevisionnumber.attr_name) = 'clusterrevisionnumber'
  LEFT JOIN resource_attribute AS tags
    ON tags.resource_id = R.id
    AND tags.type = 'provider'
    AND lower(tags.attr_name) = 'tags'
  LEFT JOIN resource_attribute AS kmskeyid
    ON kmskeyid.resource_id = R.id
    AND kmskeyid.type = 'provider'
    AND lower(kmskeyid.attr_name) = 'kmskeyid'
  LEFT JOIN resource_attribute AS enhancedvpcrouting
    ON enhancedvpcrouting.resource_id = R.id
    AND enhancedvpcrouting.type = 'provider'
    AND lower(enhancedvpcrouting.attr_name) = 'enhancedvpcrouting'
  LEFT JOIN resource_attribute AS iamroles
    ON iamroles.resource_id = R.id
    AND iamroles.type = 'provider'
    AND lower(iamroles.attr_name) = 'iamroles'
  LEFT JOIN resource_attribute AS pendingactions
    ON pendingactions.resource_id = R.id
    AND pendingactions.type = 'provider'
    AND lower(pendingactions.attr_name) = 'pendingactions'
  LEFT JOIN resource_attribute AS maintenancetrackname
    ON maintenancetrackname.resource_id = R.id
    AND maintenancetrackname.type = 'provider'
    AND lower(maintenancetrackname.attr_name) = 'maintenancetrackname'
  LEFT JOIN resource_attribute AS elasticresizenumberofnodeoptions
    ON elasticresizenumberofnodeoptions.resource_id = R.id
    AND elasticresizenumberofnodeoptions.type = 'provider'
    AND lower(elasticresizenumberofnodeoptions.attr_name) = 'elasticresizenumberofnodeoptions'
  LEFT JOIN resource_attribute AS deferredmaintenancewindows
    ON deferredmaintenancewindows.resource_id = R.id
    AND deferredmaintenancewindows.type = 'provider'
    AND lower(deferredmaintenancewindows.attr_name) = 'deferredmaintenancewindows'
  LEFT JOIN resource_attribute AS snapshotscheduleidentifier
    ON snapshotscheduleidentifier.resource_id = R.id
    AND snapshotscheduleidentifier.type = 'provider'
    AND lower(snapshotscheduleidentifier.attr_name) = 'snapshotscheduleidentifier'
  LEFT JOIN resource_attribute AS snapshotschedulestate
    ON snapshotschedulestate.resource_id = R.id
    AND snapshotschedulestate.type = 'provider'
    AND lower(snapshotschedulestate.attr_name) = 'snapshotschedulestate'
  LEFT JOIN resource_attribute AS expectednextsnapshotscheduletime
    ON expectednextsnapshotscheduletime.resource_id = R.id
    AND expectednextsnapshotscheduletime.type = 'provider'
    AND lower(expectednextsnapshotscheduletime.attr_name) = 'expectednextsnapshotscheduletime'
  LEFT JOIN resource_attribute AS expectednextsnapshotscheduletimestatus
    ON expectednextsnapshotscheduletimestatus.resource_id = R.id
    AND expectednextsnapshotscheduletimestatus.type = 'provider'
    AND lower(expectednextsnapshotscheduletimestatus.attr_name) = 'expectednextsnapshotscheduletimestatus'
  LEFT JOIN resource_attribute AS nextmaintenancewindowstarttime
    ON nextmaintenancewindowstarttime.resource_id = R.id
    AND nextmaintenancewindowstarttime.type = 'provider'
    AND lower(nextmaintenancewindowstarttime.attr_name) = 'nextmaintenancewindowstarttime'
  LEFT JOIN resource_attribute AS resizeinfo
    ON resizeinfo.resource_id = R.id
    AND resizeinfo.type = 'provider'
    AND lower(resizeinfo.attr_name) = 'resizeinfo'
  LEFT JOIN resource_attribute AS clusternamespacearn
    ON clusternamespacearn.resource_id = R.id
    AND clusternamespacearn.type = 'provider'
    AND lower(clusternamespacearn.attr_name) = 'clusternamespacearn'
  LEFT JOIN resource_attribute AS loggingstatus
    ON loggingstatus.resource_id = R.id
    AND loggingstatus.type = 'provider'
    AND lower(loggingstatus.attr_name) = 'loggingstatus'
  LEFT JOIN resource_attribute AS _tags
    ON _tags.resource_id = R.id
    AND _tags.type = 'Metadata'
    AND lower(_tags.attr_name) = '_tags'
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
  AND R.provider_type = 'Cluster'
  AND R.service = 'redshift'
ON CONFLICT (_id) DO UPDATE
SET
    clusteridentifier = EXCLUDED.clusteridentifier,
    nodetype = EXCLUDED.nodetype,
    clusterstatus = EXCLUDED.clusterstatus,
    clusteravailabilitystatus = EXCLUDED.clusteravailabilitystatus,
    modifystatus = EXCLUDED.modifystatus,
    masterusername = EXCLUDED.masterusername,
    dbname = EXCLUDED.dbname,
    endpoint = EXCLUDED.endpoint,
    clustercreatetime = EXCLUDED.clustercreatetime,
    automatedsnapshotretentionperiod = EXCLUDED.automatedsnapshotretentionperiod,
    manualsnapshotretentionperiod = EXCLUDED.manualsnapshotretentionperiod,
    clustersecuritygroups = EXCLUDED.clustersecuritygroups,
    vpcsecuritygroups = EXCLUDED.vpcsecuritygroups,
    clusterparametergroups = EXCLUDED.clusterparametergroups,
    clustersubnetgroupname = EXCLUDED.clustersubnetgroupname,
    vpcid = EXCLUDED.vpcid,
    availabilityzone = EXCLUDED.availabilityzone,
    preferredmaintenancewindow = EXCLUDED.preferredmaintenancewindow,
    pendingmodifiedvalues = EXCLUDED.pendingmodifiedvalues,
    clusterversion = EXCLUDED.clusterversion,
    allowversionupgrade = EXCLUDED.allowversionupgrade,
    numberofnodes = EXCLUDED.numberofnodes,
    publiclyaccessible = EXCLUDED.publiclyaccessible,
    encrypted = EXCLUDED.encrypted,
    restorestatus = EXCLUDED.restorestatus,
    datatransferprogress = EXCLUDED.datatransferprogress,
    hsmstatus = EXCLUDED.hsmstatus,
    clustersnapshotcopystatus = EXCLUDED.clustersnapshotcopystatus,
    clusterpublickey = EXCLUDED.clusterpublickey,
    clusternodes = EXCLUDED.clusternodes,
    elasticipstatus = EXCLUDED.elasticipstatus,
    clusterrevisionnumber = EXCLUDED.clusterrevisionnumber,
    tags = EXCLUDED.tags,
    kmskeyid = EXCLUDED.kmskeyid,
    enhancedvpcrouting = EXCLUDED.enhancedvpcrouting,
    iamroles = EXCLUDED.iamroles,
    pendingactions = EXCLUDED.pendingactions,
    maintenancetrackname = EXCLUDED.maintenancetrackname,
    elasticresizenumberofnodeoptions = EXCLUDED.elasticresizenumberofnodeoptions,
    deferredmaintenancewindows = EXCLUDED.deferredmaintenancewindows,
    snapshotscheduleidentifier = EXCLUDED.snapshotscheduleidentifier,
    snapshotschedulestate = EXCLUDED.snapshotschedulestate,
    expectednextsnapshotscheduletime = EXCLUDED.expectednextsnapshotscheduletime,
    expectednextsnapshotscheduletimestatus = EXCLUDED.expectednextsnapshotscheduletimestatus,
    nextmaintenancewindowstarttime = EXCLUDED.nextmaintenancewindowstarttime,
    resizeinfo = EXCLUDED.resizeinfo,
    clusternamespacearn = EXCLUDED.clusternamespacearn,
    loggingstatus = EXCLUDED.loggingstatus,
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
  LEFT JOIN resource_relation_attribute AS Status
    ON Status.relation_id = RR.id
    AND Status.name = 'Status'
  WHERE
    aws_redshift_cluster.provider_type = 'Cluster'
    AND aws_redshift_cluster.service = 'redshift'
ON CONFLICT (cluster_id, securitygroup_id)

DO UPDATE
SET
  
  Status = EXCLUDED.Status;

DROP MATERIALIZED VIEW IF EXISTS aws_rds_dbinstance CASCADE;

CREATE MATERIALIZED VIEW aws_rds_dbinstance AS
SELECT
  R.id AS resource_id,
  R.uri,
  R.provider_account_id,
  dbinstanceidentifier.attr_value #>> '{}' AS dbinstanceidentifier,
  dbinstanceclass.attr_value #>> '{}' AS dbinstanceclass,
  engine.attr_value #>> '{}' AS engine,
  dbinstancestatus.attr_value #>> '{}' AS dbinstancestatus,
  masterusername.attr_value #>> '{}' AS masterusername,
  dbname.attr_value #>> '{}' AS dbname,
  endpoint.attr_value::jsonb AS endpoint,
  (allocatedstorage.attr_value #>> '{}')::integer AS allocatedstorage,
  (TO_TIMESTAMP(instancecreatetime.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS instancecreatetime,
  preferredbackupwindow.attr_value #>> '{}' AS preferredbackupwindow,
  (backupretentionperiod.attr_value #>> '{}')::integer AS backupretentionperiod,
  dbsecuritygroups.attr_value::jsonb AS dbsecuritygroups,
  vpcsecuritygroups.attr_value::jsonb AS vpcsecuritygroups,
  dbparametergroups.attr_value::jsonb AS dbparametergroups,
  availabilityzone.attr_value #>> '{}' AS availabilityzone,
  dbsubnetgroup.attr_value::jsonb AS dbsubnetgroup,
  preferredmaintenancewindow.attr_value #>> '{}' AS preferredmaintenancewindow,
  pendingmodifiedvalues.attr_value::jsonb AS pendingmodifiedvalues,
  (TO_TIMESTAMP(latestrestorabletime.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS latestrestorabletime,
  (multiaz.attr_value #>> '{}')::boolean AS multiaz,
  engineversion.attr_value #>> '{}' AS engineversion,
  (autominorversionupgrade.attr_value #>> '{}')::boolean AS autominorversionupgrade,
  readreplicasourcedbinstanceidentifier.attr_value #>> '{}' AS readreplicasourcedbinstanceidentifier,
  readreplicadbinstanceidentifiers.attr_value::jsonb AS readreplicadbinstanceidentifiers,
  readreplicadbclusteridentifiers.attr_value::jsonb AS readreplicadbclusteridentifiers,
  replicamode.attr_value #>> '{}' AS replicamode,
  licensemodel.attr_value #>> '{}' AS licensemodel,
  (iops.attr_value #>> '{}')::integer AS iops,
  optiongroupmemberships.attr_value::jsonb AS optiongroupmemberships,
  charactersetname.attr_value #>> '{}' AS charactersetname,
  ncharcharactersetname.attr_value #>> '{}' AS ncharcharactersetname,
  secondaryavailabilityzone.attr_value #>> '{}' AS secondaryavailabilityzone,
  (publiclyaccessible.attr_value #>> '{}')::boolean AS publiclyaccessible,
  statusinfos.attr_value::jsonb AS statusinfos,
  storagetype.attr_value #>> '{}' AS storagetype,
  tdecredentialarn.attr_value #>> '{}' AS tdecredentialarn,
  (dbinstanceport.attr_value #>> '{}')::integer AS dbinstanceport,
  dbclusteridentifier.attr_value #>> '{}' AS dbclusteridentifier,
  (storageencrypted.attr_value #>> '{}')::boolean AS storageencrypted,
  kmskeyid.attr_value #>> '{}' AS kmskeyid,
  dbiresourceid.attr_value #>> '{}' AS dbiresourceid,
  cacertificateidentifier.attr_value #>> '{}' AS cacertificateidentifier,
  domainmemberships.attr_value::jsonb AS domainmemberships,
  (copytagstosnapshot.attr_value #>> '{}')::boolean AS copytagstosnapshot,
  (monitoringinterval.attr_value #>> '{}')::integer AS monitoringinterval,
  enhancedmonitoringresourcearn.attr_value #>> '{}' AS enhancedmonitoringresourcearn,
  monitoringrolearn.attr_value #>> '{}' AS monitoringrolearn,
  (promotiontier.attr_value #>> '{}')::integer AS promotiontier,
  dbinstancearn.attr_value #>> '{}' AS dbinstancearn,
  timezone.attr_value #>> '{}' AS timezone,
  (iamdatabaseauthenticationenabled.attr_value #>> '{}')::boolean AS iamdatabaseauthenticationenabled,
  (performanceinsightsenabled.attr_value #>> '{}')::boolean AS performanceinsightsenabled,
  performanceinsightskmskeyid.attr_value #>> '{}' AS performanceinsightskmskeyid,
  (performanceinsightsretentionperiod.attr_value #>> '{}')::integer AS performanceinsightsretentionperiod,
  enabledcloudwatchlogsexports.attr_value::jsonb AS enabledcloudwatchlogsexports,
  processorfeatures.attr_value::jsonb AS processorfeatures,
  (deletionprotection.attr_value #>> '{}')::boolean AS deletionprotection,
  associatedroles.attr_value::jsonb AS associatedroles,
  listenerendpoint.attr_value::jsonb AS listenerendpoint,
  (maxallocatedstorage.attr_value #>> '{}')::integer AS maxallocatedstorage,
  taglist.attr_value::jsonb AS taglist,
  
    _dbcluster_id.target_id AS _dbcluster_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN resource_attribute AS dbinstanceidentifier
    ON dbinstanceidentifier.resource_id = R.id
    AND dbinstanceidentifier.type = 'provider'
    AND lower(dbinstanceidentifier.attr_name) = 'dbinstanceidentifier'
  LEFT JOIN resource_attribute AS dbinstanceclass
    ON dbinstanceclass.resource_id = R.id
    AND dbinstanceclass.type = 'provider'
    AND lower(dbinstanceclass.attr_name) = 'dbinstanceclass'
  LEFT JOIN resource_attribute AS engine
    ON engine.resource_id = R.id
    AND engine.type = 'provider'
    AND lower(engine.attr_name) = 'engine'
  LEFT JOIN resource_attribute AS dbinstancestatus
    ON dbinstancestatus.resource_id = R.id
    AND dbinstancestatus.type = 'provider'
    AND lower(dbinstancestatus.attr_name) = 'dbinstancestatus'
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
  LEFT JOIN resource_attribute AS allocatedstorage
    ON allocatedstorage.resource_id = R.id
    AND allocatedstorage.type = 'provider'
    AND lower(allocatedstorage.attr_name) = 'allocatedstorage'
  LEFT JOIN resource_attribute AS instancecreatetime
    ON instancecreatetime.resource_id = R.id
    AND instancecreatetime.type = 'provider'
    AND lower(instancecreatetime.attr_name) = 'instancecreatetime'
  LEFT JOIN resource_attribute AS preferredbackupwindow
    ON preferredbackupwindow.resource_id = R.id
    AND preferredbackupwindow.type = 'provider'
    AND lower(preferredbackupwindow.attr_name) = 'preferredbackupwindow'
  LEFT JOIN resource_attribute AS backupretentionperiod
    ON backupretentionperiod.resource_id = R.id
    AND backupretentionperiod.type = 'provider'
    AND lower(backupretentionperiod.attr_name) = 'backupretentionperiod'
  LEFT JOIN resource_attribute AS dbsecuritygroups
    ON dbsecuritygroups.resource_id = R.id
    AND dbsecuritygroups.type = 'provider'
    AND lower(dbsecuritygroups.attr_name) = 'dbsecuritygroups'
  LEFT JOIN resource_attribute AS vpcsecuritygroups
    ON vpcsecuritygroups.resource_id = R.id
    AND vpcsecuritygroups.type = 'provider'
    AND lower(vpcsecuritygroups.attr_name) = 'vpcsecuritygroups'
  LEFT JOIN resource_attribute AS dbparametergroups
    ON dbparametergroups.resource_id = R.id
    AND dbparametergroups.type = 'provider'
    AND lower(dbparametergroups.attr_name) = 'dbparametergroups'
  LEFT JOIN resource_attribute AS availabilityzone
    ON availabilityzone.resource_id = R.id
    AND availabilityzone.type = 'provider'
    AND lower(availabilityzone.attr_name) = 'availabilityzone'
  LEFT JOIN resource_attribute AS dbsubnetgroup
    ON dbsubnetgroup.resource_id = R.id
    AND dbsubnetgroup.type = 'provider'
    AND lower(dbsubnetgroup.attr_name) = 'dbsubnetgroup'
  LEFT JOIN resource_attribute AS preferredmaintenancewindow
    ON preferredmaintenancewindow.resource_id = R.id
    AND preferredmaintenancewindow.type = 'provider'
    AND lower(preferredmaintenancewindow.attr_name) = 'preferredmaintenancewindow'
  LEFT JOIN resource_attribute AS pendingmodifiedvalues
    ON pendingmodifiedvalues.resource_id = R.id
    AND pendingmodifiedvalues.type = 'provider'
    AND lower(pendingmodifiedvalues.attr_name) = 'pendingmodifiedvalues'
  LEFT JOIN resource_attribute AS latestrestorabletime
    ON latestrestorabletime.resource_id = R.id
    AND latestrestorabletime.type = 'provider'
    AND lower(latestrestorabletime.attr_name) = 'latestrestorabletime'
  LEFT JOIN resource_attribute AS multiaz
    ON multiaz.resource_id = R.id
    AND multiaz.type = 'provider'
    AND lower(multiaz.attr_name) = 'multiaz'
  LEFT JOIN resource_attribute AS engineversion
    ON engineversion.resource_id = R.id
    AND engineversion.type = 'provider'
    AND lower(engineversion.attr_name) = 'engineversion'
  LEFT JOIN resource_attribute AS autominorversionupgrade
    ON autominorversionupgrade.resource_id = R.id
    AND autominorversionupgrade.type = 'provider'
    AND lower(autominorversionupgrade.attr_name) = 'autominorversionupgrade'
  LEFT JOIN resource_attribute AS readreplicasourcedbinstanceidentifier
    ON readreplicasourcedbinstanceidentifier.resource_id = R.id
    AND readreplicasourcedbinstanceidentifier.type = 'provider'
    AND lower(readreplicasourcedbinstanceidentifier.attr_name) = 'readreplicasourcedbinstanceidentifier'
  LEFT JOIN resource_attribute AS readreplicadbinstanceidentifiers
    ON readreplicadbinstanceidentifiers.resource_id = R.id
    AND readreplicadbinstanceidentifiers.type = 'provider'
    AND lower(readreplicadbinstanceidentifiers.attr_name) = 'readreplicadbinstanceidentifiers'
  LEFT JOIN resource_attribute AS readreplicadbclusteridentifiers
    ON readreplicadbclusteridentifiers.resource_id = R.id
    AND readreplicadbclusteridentifiers.type = 'provider'
    AND lower(readreplicadbclusteridentifiers.attr_name) = 'readreplicadbclusteridentifiers'
  LEFT JOIN resource_attribute AS replicamode
    ON replicamode.resource_id = R.id
    AND replicamode.type = 'provider'
    AND lower(replicamode.attr_name) = 'replicamode'
  LEFT JOIN resource_attribute AS licensemodel
    ON licensemodel.resource_id = R.id
    AND licensemodel.type = 'provider'
    AND lower(licensemodel.attr_name) = 'licensemodel'
  LEFT JOIN resource_attribute AS iops
    ON iops.resource_id = R.id
    AND iops.type = 'provider'
    AND lower(iops.attr_name) = 'iops'
  LEFT JOIN resource_attribute AS optiongroupmemberships
    ON optiongroupmemberships.resource_id = R.id
    AND optiongroupmemberships.type = 'provider'
    AND lower(optiongroupmemberships.attr_name) = 'optiongroupmemberships'
  LEFT JOIN resource_attribute AS charactersetname
    ON charactersetname.resource_id = R.id
    AND charactersetname.type = 'provider'
    AND lower(charactersetname.attr_name) = 'charactersetname'
  LEFT JOIN resource_attribute AS ncharcharactersetname
    ON ncharcharactersetname.resource_id = R.id
    AND ncharcharactersetname.type = 'provider'
    AND lower(ncharcharactersetname.attr_name) = 'ncharcharactersetname'
  LEFT JOIN resource_attribute AS secondaryavailabilityzone
    ON secondaryavailabilityzone.resource_id = R.id
    AND secondaryavailabilityzone.type = 'provider'
    AND lower(secondaryavailabilityzone.attr_name) = 'secondaryavailabilityzone'
  LEFT JOIN resource_attribute AS publiclyaccessible
    ON publiclyaccessible.resource_id = R.id
    AND publiclyaccessible.type = 'provider'
    AND lower(publiclyaccessible.attr_name) = 'publiclyaccessible'
  LEFT JOIN resource_attribute AS statusinfos
    ON statusinfos.resource_id = R.id
    AND statusinfos.type = 'provider'
    AND lower(statusinfos.attr_name) = 'statusinfos'
  LEFT JOIN resource_attribute AS storagetype
    ON storagetype.resource_id = R.id
    AND storagetype.type = 'provider'
    AND lower(storagetype.attr_name) = 'storagetype'
  LEFT JOIN resource_attribute AS tdecredentialarn
    ON tdecredentialarn.resource_id = R.id
    AND tdecredentialarn.type = 'provider'
    AND lower(tdecredentialarn.attr_name) = 'tdecredentialarn'
  LEFT JOIN resource_attribute AS dbinstanceport
    ON dbinstanceport.resource_id = R.id
    AND dbinstanceport.type = 'provider'
    AND lower(dbinstanceport.attr_name) = 'dbinstanceport'
  LEFT JOIN resource_attribute AS dbclusteridentifier
    ON dbclusteridentifier.resource_id = R.id
    AND dbclusteridentifier.type = 'provider'
    AND lower(dbclusteridentifier.attr_name) = 'dbclusteridentifier'
  LEFT JOIN resource_attribute AS storageencrypted
    ON storageencrypted.resource_id = R.id
    AND storageencrypted.type = 'provider'
    AND lower(storageencrypted.attr_name) = 'storageencrypted'
  LEFT JOIN resource_attribute AS kmskeyid
    ON kmskeyid.resource_id = R.id
    AND kmskeyid.type = 'provider'
    AND lower(kmskeyid.attr_name) = 'kmskeyid'
  LEFT JOIN resource_attribute AS dbiresourceid
    ON dbiresourceid.resource_id = R.id
    AND dbiresourceid.type = 'provider'
    AND lower(dbiresourceid.attr_name) = 'dbiresourceid'
  LEFT JOIN resource_attribute AS cacertificateidentifier
    ON cacertificateidentifier.resource_id = R.id
    AND cacertificateidentifier.type = 'provider'
    AND lower(cacertificateidentifier.attr_name) = 'cacertificateidentifier'
  LEFT JOIN resource_attribute AS domainmemberships
    ON domainmemberships.resource_id = R.id
    AND domainmemberships.type = 'provider'
    AND lower(domainmemberships.attr_name) = 'domainmemberships'
  LEFT JOIN resource_attribute AS copytagstosnapshot
    ON copytagstosnapshot.resource_id = R.id
    AND copytagstosnapshot.type = 'provider'
    AND lower(copytagstosnapshot.attr_name) = 'copytagstosnapshot'
  LEFT JOIN resource_attribute AS monitoringinterval
    ON monitoringinterval.resource_id = R.id
    AND monitoringinterval.type = 'provider'
    AND lower(monitoringinterval.attr_name) = 'monitoringinterval'
  LEFT JOIN resource_attribute AS enhancedmonitoringresourcearn
    ON enhancedmonitoringresourcearn.resource_id = R.id
    AND enhancedmonitoringresourcearn.type = 'provider'
    AND lower(enhancedmonitoringresourcearn.attr_name) = 'enhancedmonitoringresourcearn'
  LEFT JOIN resource_attribute AS monitoringrolearn
    ON monitoringrolearn.resource_id = R.id
    AND monitoringrolearn.type = 'provider'
    AND lower(monitoringrolearn.attr_name) = 'monitoringrolearn'
  LEFT JOIN resource_attribute AS promotiontier
    ON promotiontier.resource_id = R.id
    AND promotiontier.type = 'provider'
    AND lower(promotiontier.attr_name) = 'promotiontier'
  LEFT JOIN resource_attribute AS dbinstancearn
    ON dbinstancearn.resource_id = R.id
    AND dbinstancearn.type = 'provider'
    AND lower(dbinstancearn.attr_name) = 'dbinstancearn'
  LEFT JOIN resource_attribute AS timezone
    ON timezone.resource_id = R.id
    AND timezone.type = 'provider'
    AND lower(timezone.attr_name) = 'timezone'
  LEFT JOIN resource_attribute AS iamdatabaseauthenticationenabled
    ON iamdatabaseauthenticationenabled.resource_id = R.id
    AND iamdatabaseauthenticationenabled.type = 'provider'
    AND lower(iamdatabaseauthenticationenabled.attr_name) = 'iamdatabaseauthenticationenabled'
  LEFT JOIN resource_attribute AS performanceinsightsenabled
    ON performanceinsightsenabled.resource_id = R.id
    AND performanceinsightsenabled.type = 'provider'
    AND lower(performanceinsightsenabled.attr_name) = 'performanceinsightsenabled'
  LEFT JOIN resource_attribute AS performanceinsightskmskeyid
    ON performanceinsightskmskeyid.resource_id = R.id
    AND performanceinsightskmskeyid.type = 'provider'
    AND lower(performanceinsightskmskeyid.attr_name) = 'performanceinsightskmskeyid'
  LEFT JOIN resource_attribute AS performanceinsightsretentionperiod
    ON performanceinsightsretentionperiod.resource_id = R.id
    AND performanceinsightsretentionperiod.type = 'provider'
    AND lower(performanceinsightsretentionperiod.attr_name) = 'performanceinsightsretentionperiod'
  LEFT JOIN resource_attribute AS enabledcloudwatchlogsexports
    ON enabledcloudwatchlogsexports.resource_id = R.id
    AND enabledcloudwatchlogsexports.type = 'provider'
    AND lower(enabledcloudwatchlogsexports.attr_name) = 'enabledcloudwatchlogsexports'
  LEFT JOIN resource_attribute AS processorfeatures
    ON processorfeatures.resource_id = R.id
    AND processorfeatures.type = 'provider'
    AND lower(processorfeatures.attr_name) = 'processorfeatures'
  LEFT JOIN resource_attribute AS deletionprotection
    ON deletionprotection.resource_id = R.id
    AND deletionprotection.type = 'provider'
    AND lower(deletionprotection.attr_name) = 'deletionprotection'
  LEFT JOIN resource_attribute AS associatedroles
    ON associatedroles.resource_id = R.id
    AND associatedroles.type = 'provider'
    AND lower(associatedroles.attr_name) = 'associatedroles'
  LEFT JOIN resource_attribute AS listenerendpoint
    ON listenerendpoint.resource_id = R.id
    AND listenerendpoint.type = 'provider'
    AND lower(listenerendpoint.attr_name) = 'listenerendpoint'
  LEFT JOIN resource_attribute AS maxallocatedstorage
    ON maxallocatedstorage.resource_id = R.id
    AND maxallocatedstorage.type = 'provider'
    AND lower(maxallocatedstorage.attr_name) = 'maxallocatedstorage'
  LEFT JOIN resource_attribute AS taglist
    ON taglist.resource_id = R.id
    AND taglist.type = 'provider'
    AND lower(taglist.attr_name) = 'taglist'
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
    WHERE
      _aws_rds_dbcluster_relation.relation = 'in'
  ) AS _dbcluster_id ON _dbcluster_id.resource_id = R.id
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
  AND R.provider_type = 'DBInstance'
  AND R.service = 'rds'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_rds_dbinstance;

COMMENT ON MATERIALIZED VIEW aws_rds_dbinstance IS 'rds DBInstance resources and their associated attributes.';



DROP MATERIALIZED VIEW IF EXISTS aws_rds_dbinstance_ec2_securitygroup CASCADE;

CREATE MATERIALIZED VIEW aws_rds_dbinstance_ec2_securitygroup AS
SELECT
  aws_rds_dbinstance.id AS dbinstance_id,
  aws_ec2_securitygroup.id AS securitygroup_id
FROM
  resource AS aws_rds_dbinstance
  INNER JOIN resource_relation AS RR
    ON RR.resource_id = aws_rds_dbinstance.id
    AND RR.relation = 'in'
  INNER JOIN resource AS aws_ec2_securitygroup
    ON aws_ec2_securitygroup.id = RR.target_id
    AND aws_ec2_securitygroup.provider_type = 'SecurityGroup'
    AND aws_ec2_securitygroup.service = 'ec2'
  WHERE
    aws_rds_dbinstance.provider_type = 'DBInstance'
    AND aws_rds_dbinstance.service = 'rds'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_rds_dbinstance_ec2_securitygroup;

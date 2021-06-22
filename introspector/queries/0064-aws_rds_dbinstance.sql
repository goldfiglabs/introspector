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
  dbinstanceautomatedbackupsreplications.attr_value::jsonb AS dbinstanceautomatedbackupsreplications,
  (customerownedipenabled.attr_value #>> '{}')::boolean AS customerownedipenabled,
  _tags.attr_value::jsonb AS _tags,
  
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
    AND dbinstanceidentifier.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS dbinstanceclass
    ON dbinstanceclass.resource_id = R.id
    AND dbinstanceclass.type = 'provider'
    AND lower(dbinstanceclass.attr_name) = 'dbinstanceclass'
    AND dbinstanceclass.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS engine
    ON engine.resource_id = R.id
    AND engine.type = 'provider'
    AND lower(engine.attr_name) = 'engine'
    AND engine.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS dbinstancestatus
    ON dbinstancestatus.resource_id = R.id
    AND dbinstancestatus.type = 'provider'
    AND lower(dbinstancestatus.attr_name) = 'dbinstancestatus'
    AND dbinstancestatus.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS masterusername
    ON masterusername.resource_id = R.id
    AND masterusername.type = 'provider'
    AND lower(masterusername.attr_name) = 'masterusername'
    AND masterusername.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS dbname
    ON dbname.resource_id = R.id
    AND dbname.type = 'provider'
    AND lower(dbname.attr_name) = 'dbname'
    AND dbname.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS endpoint
    ON endpoint.resource_id = R.id
    AND endpoint.type = 'provider'
    AND lower(endpoint.attr_name) = 'endpoint'
    AND endpoint.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS allocatedstorage
    ON allocatedstorage.resource_id = R.id
    AND allocatedstorage.type = 'provider'
    AND lower(allocatedstorage.attr_name) = 'allocatedstorage'
    AND allocatedstorage.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS instancecreatetime
    ON instancecreatetime.resource_id = R.id
    AND instancecreatetime.type = 'provider'
    AND lower(instancecreatetime.attr_name) = 'instancecreatetime'
    AND instancecreatetime.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS preferredbackupwindow
    ON preferredbackupwindow.resource_id = R.id
    AND preferredbackupwindow.type = 'provider'
    AND lower(preferredbackupwindow.attr_name) = 'preferredbackupwindow'
    AND preferredbackupwindow.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS backupretentionperiod
    ON backupretentionperiod.resource_id = R.id
    AND backupretentionperiod.type = 'provider'
    AND lower(backupretentionperiod.attr_name) = 'backupretentionperiod'
    AND backupretentionperiod.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS dbsecuritygroups
    ON dbsecuritygroups.resource_id = R.id
    AND dbsecuritygroups.type = 'provider'
    AND lower(dbsecuritygroups.attr_name) = 'dbsecuritygroups'
    AND dbsecuritygroups.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS vpcsecuritygroups
    ON vpcsecuritygroups.resource_id = R.id
    AND vpcsecuritygroups.type = 'provider'
    AND lower(vpcsecuritygroups.attr_name) = 'vpcsecuritygroups'
    AND vpcsecuritygroups.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS dbparametergroups
    ON dbparametergroups.resource_id = R.id
    AND dbparametergroups.type = 'provider'
    AND lower(dbparametergroups.attr_name) = 'dbparametergroups'
    AND dbparametergroups.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS availabilityzone
    ON availabilityzone.resource_id = R.id
    AND availabilityzone.type = 'provider'
    AND lower(availabilityzone.attr_name) = 'availabilityzone'
    AND availabilityzone.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS dbsubnetgroup
    ON dbsubnetgroup.resource_id = R.id
    AND dbsubnetgroup.type = 'provider'
    AND lower(dbsubnetgroup.attr_name) = 'dbsubnetgroup'
    AND dbsubnetgroup.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS preferredmaintenancewindow
    ON preferredmaintenancewindow.resource_id = R.id
    AND preferredmaintenancewindow.type = 'provider'
    AND lower(preferredmaintenancewindow.attr_name) = 'preferredmaintenancewindow'
    AND preferredmaintenancewindow.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS pendingmodifiedvalues
    ON pendingmodifiedvalues.resource_id = R.id
    AND pendingmodifiedvalues.type = 'provider'
    AND lower(pendingmodifiedvalues.attr_name) = 'pendingmodifiedvalues'
    AND pendingmodifiedvalues.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS latestrestorabletime
    ON latestrestorabletime.resource_id = R.id
    AND latestrestorabletime.type = 'provider'
    AND lower(latestrestorabletime.attr_name) = 'latestrestorabletime'
    AND latestrestorabletime.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS multiaz
    ON multiaz.resource_id = R.id
    AND multiaz.type = 'provider'
    AND lower(multiaz.attr_name) = 'multiaz'
    AND multiaz.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS engineversion
    ON engineversion.resource_id = R.id
    AND engineversion.type = 'provider'
    AND lower(engineversion.attr_name) = 'engineversion'
    AND engineversion.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS autominorversionupgrade
    ON autominorversionupgrade.resource_id = R.id
    AND autominorversionupgrade.type = 'provider'
    AND lower(autominorversionupgrade.attr_name) = 'autominorversionupgrade'
    AND autominorversionupgrade.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS readreplicasourcedbinstanceidentifier
    ON readreplicasourcedbinstanceidentifier.resource_id = R.id
    AND readreplicasourcedbinstanceidentifier.type = 'provider'
    AND lower(readreplicasourcedbinstanceidentifier.attr_name) = 'readreplicasourcedbinstanceidentifier'
    AND readreplicasourcedbinstanceidentifier.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS readreplicadbinstanceidentifiers
    ON readreplicadbinstanceidentifiers.resource_id = R.id
    AND readreplicadbinstanceidentifiers.type = 'provider'
    AND lower(readreplicadbinstanceidentifiers.attr_name) = 'readreplicadbinstanceidentifiers'
    AND readreplicadbinstanceidentifiers.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS readreplicadbclusteridentifiers
    ON readreplicadbclusteridentifiers.resource_id = R.id
    AND readreplicadbclusteridentifiers.type = 'provider'
    AND lower(readreplicadbclusteridentifiers.attr_name) = 'readreplicadbclusteridentifiers'
    AND readreplicadbclusteridentifiers.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS replicamode
    ON replicamode.resource_id = R.id
    AND replicamode.type = 'provider'
    AND lower(replicamode.attr_name) = 'replicamode'
    AND replicamode.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS licensemodel
    ON licensemodel.resource_id = R.id
    AND licensemodel.type = 'provider'
    AND lower(licensemodel.attr_name) = 'licensemodel'
    AND licensemodel.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS iops
    ON iops.resource_id = R.id
    AND iops.type = 'provider'
    AND lower(iops.attr_name) = 'iops'
    AND iops.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS optiongroupmemberships
    ON optiongroupmemberships.resource_id = R.id
    AND optiongroupmemberships.type = 'provider'
    AND lower(optiongroupmemberships.attr_name) = 'optiongroupmemberships'
    AND optiongroupmemberships.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS charactersetname
    ON charactersetname.resource_id = R.id
    AND charactersetname.type = 'provider'
    AND lower(charactersetname.attr_name) = 'charactersetname'
    AND charactersetname.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS ncharcharactersetname
    ON ncharcharactersetname.resource_id = R.id
    AND ncharcharactersetname.type = 'provider'
    AND lower(ncharcharactersetname.attr_name) = 'ncharcharactersetname'
    AND ncharcharactersetname.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS secondaryavailabilityzone
    ON secondaryavailabilityzone.resource_id = R.id
    AND secondaryavailabilityzone.type = 'provider'
    AND lower(secondaryavailabilityzone.attr_name) = 'secondaryavailabilityzone'
    AND secondaryavailabilityzone.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS publiclyaccessible
    ON publiclyaccessible.resource_id = R.id
    AND publiclyaccessible.type = 'provider'
    AND lower(publiclyaccessible.attr_name) = 'publiclyaccessible'
    AND publiclyaccessible.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS statusinfos
    ON statusinfos.resource_id = R.id
    AND statusinfos.type = 'provider'
    AND lower(statusinfos.attr_name) = 'statusinfos'
    AND statusinfos.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS storagetype
    ON storagetype.resource_id = R.id
    AND storagetype.type = 'provider'
    AND lower(storagetype.attr_name) = 'storagetype'
    AND storagetype.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS tdecredentialarn
    ON tdecredentialarn.resource_id = R.id
    AND tdecredentialarn.type = 'provider'
    AND lower(tdecredentialarn.attr_name) = 'tdecredentialarn'
    AND tdecredentialarn.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS dbinstanceport
    ON dbinstanceport.resource_id = R.id
    AND dbinstanceport.type = 'provider'
    AND lower(dbinstanceport.attr_name) = 'dbinstanceport'
    AND dbinstanceport.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS dbclusteridentifier
    ON dbclusteridentifier.resource_id = R.id
    AND dbclusteridentifier.type = 'provider'
    AND lower(dbclusteridentifier.attr_name) = 'dbclusteridentifier'
    AND dbclusteridentifier.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS storageencrypted
    ON storageencrypted.resource_id = R.id
    AND storageencrypted.type = 'provider'
    AND lower(storageencrypted.attr_name) = 'storageencrypted'
    AND storageencrypted.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS kmskeyid
    ON kmskeyid.resource_id = R.id
    AND kmskeyid.type = 'provider'
    AND lower(kmskeyid.attr_name) = 'kmskeyid'
    AND kmskeyid.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS dbiresourceid
    ON dbiresourceid.resource_id = R.id
    AND dbiresourceid.type = 'provider'
    AND lower(dbiresourceid.attr_name) = 'dbiresourceid'
    AND dbiresourceid.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS cacertificateidentifier
    ON cacertificateidentifier.resource_id = R.id
    AND cacertificateidentifier.type = 'provider'
    AND lower(cacertificateidentifier.attr_name) = 'cacertificateidentifier'
    AND cacertificateidentifier.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS domainmemberships
    ON domainmemberships.resource_id = R.id
    AND domainmemberships.type = 'provider'
    AND lower(domainmemberships.attr_name) = 'domainmemberships'
    AND domainmemberships.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS copytagstosnapshot
    ON copytagstosnapshot.resource_id = R.id
    AND copytagstosnapshot.type = 'provider'
    AND lower(copytagstosnapshot.attr_name) = 'copytagstosnapshot'
    AND copytagstosnapshot.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS monitoringinterval
    ON monitoringinterval.resource_id = R.id
    AND monitoringinterval.type = 'provider'
    AND lower(monitoringinterval.attr_name) = 'monitoringinterval'
    AND monitoringinterval.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS enhancedmonitoringresourcearn
    ON enhancedmonitoringresourcearn.resource_id = R.id
    AND enhancedmonitoringresourcearn.type = 'provider'
    AND lower(enhancedmonitoringresourcearn.attr_name) = 'enhancedmonitoringresourcearn'
    AND enhancedmonitoringresourcearn.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS monitoringrolearn
    ON monitoringrolearn.resource_id = R.id
    AND monitoringrolearn.type = 'provider'
    AND lower(monitoringrolearn.attr_name) = 'monitoringrolearn'
    AND monitoringrolearn.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS promotiontier
    ON promotiontier.resource_id = R.id
    AND promotiontier.type = 'provider'
    AND lower(promotiontier.attr_name) = 'promotiontier'
    AND promotiontier.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS dbinstancearn
    ON dbinstancearn.resource_id = R.id
    AND dbinstancearn.type = 'provider'
    AND lower(dbinstancearn.attr_name) = 'dbinstancearn'
    AND dbinstancearn.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS timezone
    ON timezone.resource_id = R.id
    AND timezone.type = 'provider'
    AND lower(timezone.attr_name) = 'timezone'
    AND timezone.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS iamdatabaseauthenticationenabled
    ON iamdatabaseauthenticationenabled.resource_id = R.id
    AND iamdatabaseauthenticationenabled.type = 'provider'
    AND lower(iamdatabaseauthenticationenabled.attr_name) = 'iamdatabaseauthenticationenabled'
    AND iamdatabaseauthenticationenabled.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS performanceinsightsenabled
    ON performanceinsightsenabled.resource_id = R.id
    AND performanceinsightsenabled.type = 'provider'
    AND lower(performanceinsightsenabled.attr_name) = 'performanceinsightsenabled'
    AND performanceinsightsenabled.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS performanceinsightskmskeyid
    ON performanceinsightskmskeyid.resource_id = R.id
    AND performanceinsightskmskeyid.type = 'provider'
    AND lower(performanceinsightskmskeyid.attr_name) = 'performanceinsightskmskeyid'
    AND performanceinsightskmskeyid.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS performanceinsightsretentionperiod
    ON performanceinsightsretentionperiod.resource_id = R.id
    AND performanceinsightsretentionperiod.type = 'provider'
    AND lower(performanceinsightsretentionperiod.attr_name) = 'performanceinsightsretentionperiod'
    AND performanceinsightsretentionperiod.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS enabledcloudwatchlogsexports
    ON enabledcloudwatchlogsexports.resource_id = R.id
    AND enabledcloudwatchlogsexports.type = 'provider'
    AND lower(enabledcloudwatchlogsexports.attr_name) = 'enabledcloudwatchlogsexports'
    AND enabledcloudwatchlogsexports.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS processorfeatures
    ON processorfeatures.resource_id = R.id
    AND processorfeatures.type = 'provider'
    AND lower(processorfeatures.attr_name) = 'processorfeatures'
    AND processorfeatures.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS deletionprotection
    ON deletionprotection.resource_id = R.id
    AND deletionprotection.type = 'provider'
    AND lower(deletionprotection.attr_name) = 'deletionprotection'
    AND deletionprotection.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS associatedroles
    ON associatedroles.resource_id = R.id
    AND associatedroles.type = 'provider'
    AND lower(associatedroles.attr_name) = 'associatedroles'
    AND associatedroles.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS listenerendpoint
    ON listenerendpoint.resource_id = R.id
    AND listenerendpoint.type = 'provider'
    AND lower(listenerendpoint.attr_name) = 'listenerendpoint'
    AND listenerendpoint.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS maxallocatedstorage
    ON maxallocatedstorage.resource_id = R.id
    AND maxallocatedstorage.type = 'provider'
    AND lower(maxallocatedstorage.attr_name) = 'maxallocatedstorage'
    AND maxallocatedstorage.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS taglist
    ON taglist.resource_id = R.id
    AND taglist.type = 'provider'
    AND lower(taglist.attr_name) = 'taglist'
    AND taglist.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS dbinstanceautomatedbackupsreplications
    ON dbinstanceautomatedbackupsreplications.resource_id = R.id
    AND dbinstanceautomatedbackupsreplications.type = 'provider'
    AND lower(dbinstanceautomatedbackupsreplications.attr_name) = 'dbinstanceautomatedbackupsreplications'
    AND dbinstanceautomatedbackupsreplications.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS customerownedipenabled
    ON customerownedipenabled.resource_id = R.id
    AND customerownedipenabled.type = 'provider'
    AND lower(customerownedipenabled.attr_name) = 'customerownedipenabled'
    AND customerownedipenabled.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS _tags
    ON _tags.resource_id = R.id
    AND _tags.type = 'Metadata'
    AND lower(_tags.attr_name) = 'tags'
    AND _tags.provider_account_id = R.provider_account_id
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
      _aws_organizations_account_relation.resource_id AS resource_id,
      _aws_organizations_account.id AS target_id
    FROM
    (
      SELECT
        _aws_organizations_account_relation.resource_id AS resource_id
      FROM
        resource_relation AS _aws_organizations_account_relation
        INNER JOIN resource AS _aws_organizations_account
          ON _aws_organizations_account_relation.target_id = _aws_organizations_account.id
          AND _aws_organizations_account.provider_type = 'Account'
          AND _aws_organizations_account.service = 'organizations'
      WHERE
        _aws_organizations_account_relation.relation = 'in'
        AND _aws_organizations_account_relation.provider_account_id = :provider_account_id
      GROUP BY _aws_organizations_account_relation.resource_id
      HAVING COUNT(*) = 1
    ) AS unique_account_mapping
    INNER JOIN resource_relation AS _aws_organizations_account_relation
      ON _aws_organizations_account_relation.resource_id = unique_account_mapping.resource_id
    INNER JOIN resource AS _aws_organizations_account
      ON _aws_organizations_account_relation.target_id = _aws_organizations_account.id
      AND _aws_organizations_account.provider_type = 'Account'
      AND _aws_organizations_account.service = 'organizations'
      AND _aws_organizations_account_relation.provider_account_id = :provider_account_id
    WHERE
        _aws_organizations_account_relation.relation = 'in'
        AND _aws_organizations_account_relation.provider_account_id = :provider_account_id
  ) AS _account_id ON _account_id.resource_id = R.id
  WHERE
  R.provider_account_id = :provider_account_id
  AND PA.provider = 'aws'
  AND R.provider_type = 'DBInstance'
  AND R.service = 'rds'
ON CONFLICT (_id) DO UPDATE
SET
    dbinstanceidentifier = EXCLUDED.dbinstanceidentifier,
    dbinstanceclass = EXCLUDED.dbinstanceclass,
    engine = EXCLUDED.engine,
    dbinstancestatus = EXCLUDED.dbinstancestatus,
    masterusername = EXCLUDED.masterusername,
    dbname = EXCLUDED.dbname,
    endpoint = EXCLUDED.endpoint,
    allocatedstorage = EXCLUDED.allocatedstorage,
    instancecreatetime = EXCLUDED.instancecreatetime,
    preferredbackupwindow = EXCLUDED.preferredbackupwindow,
    backupretentionperiod = EXCLUDED.backupretentionperiod,
    dbsecuritygroups = EXCLUDED.dbsecuritygroups,
    vpcsecuritygroups = EXCLUDED.vpcsecuritygroups,
    dbparametergroups = EXCLUDED.dbparametergroups,
    availabilityzone = EXCLUDED.availabilityzone,
    dbsubnetgroup = EXCLUDED.dbsubnetgroup,
    preferredmaintenancewindow = EXCLUDED.preferredmaintenancewindow,
    pendingmodifiedvalues = EXCLUDED.pendingmodifiedvalues,
    latestrestorabletime = EXCLUDED.latestrestorabletime,
    multiaz = EXCLUDED.multiaz,
    engineversion = EXCLUDED.engineversion,
    autominorversionupgrade = EXCLUDED.autominorversionupgrade,
    readreplicasourcedbinstanceidentifier = EXCLUDED.readreplicasourcedbinstanceidentifier,
    readreplicadbinstanceidentifiers = EXCLUDED.readreplicadbinstanceidentifiers,
    readreplicadbclusteridentifiers = EXCLUDED.readreplicadbclusteridentifiers,
    replicamode = EXCLUDED.replicamode,
    licensemodel = EXCLUDED.licensemodel,
    iops = EXCLUDED.iops,
    optiongroupmemberships = EXCLUDED.optiongroupmemberships,
    charactersetname = EXCLUDED.charactersetname,
    ncharcharactersetname = EXCLUDED.ncharcharactersetname,
    secondaryavailabilityzone = EXCLUDED.secondaryavailabilityzone,
    publiclyaccessible = EXCLUDED.publiclyaccessible,
    statusinfos = EXCLUDED.statusinfos,
    storagetype = EXCLUDED.storagetype,
    tdecredentialarn = EXCLUDED.tdecredentialarn,
    dbinstanceport = EXCLUDED.dbinstanceport,
    dbclusteridentifier = EXCLUDED.dbclusteridentifier,
    storageencrypted = EXCLUDED.storageencrypted,
    kmskeyid = EXCLUDED.kmskeyid,
    dbiresourceid = EXCLUDED.dbiresourceid,
    cacertificateidentifier = EXCLUDED.cacertificateidentifier,
    domainmemberships = EXCLUDED.domainmemberships,
    copytagstosnapshot = EXCLUDED.copytagstosnapshot,
    monitoringinterval = EXCLUDED.monitoringinterval,
    enhancedmonitoringresourcearn = EXCLUDED.enhancedmonitoringresourcearn,
    monitoringrolearn = EXCLUDED.monitoringrolearn,
    promotiontier = EXCLUDED.promotiontier,
    dbinstancearn = EXCLUDED.dbinstancearn,
    timezone = EXCLUDED.timezone,
    iamdatabaseauthenticationenabled = EXCLUDED.iamdatabaseauthenticationenabled,
    performanceinsightsenabled = EXCLUDED.performanceinsightsenabled,
    performanceinsightskmskeyid = EXCLUDED.performanceinsightskmskeyid,
    performanceinsightsretentionperiod = EXCLUDED.performanceinsightsretentionperiod,
    enabledcloudwatchlogsexports = EXCLUDED.enabledcloudwatchlogsexports,
    processorfeatures = EXCLUDED.processorfeatures,
    deletionprotection = EXCLUDED.deletionprotection,
    associatedroles = EXCLUDED.associatedroles,
    listenerendpoint = EXCLUDED.listenerendpoint,
    maxallocatedstorage = EXCLUDED.maxallocatedstorage,
    taglist = EXCLUDED.taglist,
    dbinstanceautomatedbackupsreplications = EXCLUDED.dbinstanceautomatedbackupsreplications,
    customerownedipenabled = EXCLUDED.customerownedipenabled,
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
  WHERE
    aws_rds_dbinstance.provider_type = 'DBInstance'
    AND aws_rds_dbinstance.service = 'rds'
ON CONFLICT (dbinstance_id, securitygroup_id)
DO NOTHING
;

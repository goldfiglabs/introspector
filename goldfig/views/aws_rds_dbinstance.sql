DROP MATERIALIZED VIEW IF EXISTS aws_rds_dbinstance CASCADE;

CREATE MATERIALIZED VIEW aws_rds_dbinstance AS
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
  dbinstanceidentifier.attr_value #>> '{}' AS dbinstanceidentifier,
  dbinstanceclass.attr_value #>> '{}' AS dbinstanceclass,
  engine.attr_value #>> '{}' AS engine,
  dbinstancestatus.attr_value #>> '{}' AS dbinstancestatus,
  masterusername.attr_value #>> '{}' AS masterusername,
  dbname.attr_value #>> '{}' AS dbname,
  endpoint.attr_value::jsonb AS endpoint,
  allocatedstorage.attr_value::integer AS allocatedstorage,
  (TO_TIMESTAMP(instancecreatetime.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS instancecreatetime,
  preferredbackupwindow.attr_value #>> '{}' AS preferredbackupwindow,
  backupretentionperiod.attr_value::integer AS backupretentionperiod,
  dbsecuritygroups.attr_value::jsonb AS dbsecuritygroups,
  vpcsecuritygroups.attr_value::jsonb AS vpcsecuritygroups,
  dbparametergroups.attr_value::jsonb AS dbparametergroups,
  availabilityzone.attr_value #>> '{}' AS availabilityzone,
  dbsubnetgroup.attr_value::jsonb AS dbsubnetgroup,
  preferredmaintenancewindow.attr_value #>> '{}' AS preferredmaintenancewindow,
  pendingmodifiedvalues.attr_value::jsonb AS pendingmodifiedvalues,
  (TO_TIMESTAMP(latestrestorabletime.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS latestrestorabletime,
  multiaz.attr_value::boolean AS multiaz,
  engineversion.attr_value #>> '{}' AS engineversion,
  autominorversionupgrade.attr_value::boolean AS autominorversionupgrade,
  readreplicasourcedbinstanceidentifier.attr_value #>> '{}' AS readreplicasourcedbinstanceidentifier,
  readreplicadbinstanceidentifiers.attr_value::jsonb AS readreplicadbinstanceidentifiers,
  readreplicadbclusteridentifiers.attr_value::jsonb AS readreplicadbclusteridentifiers,
  licensemodel.attr_value #>> '{}' AS licensemodel,
  iops.attr_value::integer AS iops,
  optiongroupmemberships.attr_value::jsonb AS optiongroupmemberships,
  charactersetname.attr_value #>> '{}' AS charactersetname,
  secondaryavailabilityzone.attr_value #>> '{}' AS secondaryavailabilityzone,
  publiclyaccessible.attr_value::boolean AS publiclyaccessible,
  statusinfos.attr_value::jsonb AS statusinfos,
  storagetype.attr_value #>> '{}' AS storagetype,
  tdecredentialarn.attr_value #>> '{}' AS tdecredentialarn,
  dbinstanceport.attr_value::integer AS dbinstanceport,
  dbclusteridentifier.attr_value #>> '{}' AS dbclusteridentifier,
  storageencrypted.attr_value::boolean AS storageencrypted,
  kmskeyid.attr_value #>> '{}' AS kmskeyid,
  dbiresourceid.attr_value #>> '{}' AS dbiresourceid,
  cacertificateidentifier.attr_value #>> '{}' AS cacertificateidentifier,
  domainmemberships.attr_value::jsonb AS domainmemberships,
  copytagstosnapshot.attr_value::boolean AS copytagstosnapshot,
  monitoringinterval.attr_value::integer AS monitoringinterval,
  enhancedmonitoringresourcearn.attr_value #>> '{}' AS enhancedmonitoringresourcearn,
  monitoringrolearn.attr_value #>> '{}' AS monitoringrolearn,
  promotiontier.attr_value::integer AS promotiontier,
  dbinstancearn.attr_value #>> '{}' AS dbinstancearn,
  timezone.attr_value #>> '{}' AS timezone,
  iamdatabaseauthenticationenabled.attr_value::boolean AS iamdatabaseauthenticationenabled,
  performanceinsightsenabled.attr_value::boolean AS performanceinsightsenabled,
  performanceinsightskmskeyid.attr_value #>> '{}' AS performanceinsightskmskeyid,
  performanceinsightsretentionperiod.attr_value::integer AS performanceinsightsretentionperiod,
  enabledcloudwatchlogsexports.attr_value::jsonb AS enabledcloudwatchlogsexports,
  processorfeatures.attr_value::jsonb AS processorfeatures,
  deletionprotection.attr_value::boolean AS deletionprotection,
  associatedroles.attr_value::jsonb AS associatedroles,
  listenerendpoint.attr_value::jsonb AS listenerendpoint,
  maxallocatedstorage.attr_value::integer AS maxallocatedstorage,
  tags.attr_value::jsonb AS tags
  
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN attrs AS dbinstanceidentifier
    ON dbinstanceidentifier.id = R.id
    AND dbinstanceidentifier.attr_name = 'dbinstanceidentifier'
  LEFT JOIN attrs AS dbinstanceclass
    ON dbinstanceclass.id = R.id
    AND dbinstanceclass.attr_name = 'dbinstanceclass'
  LEFT JOIN attrs AS engine
    ON engine.id = R.id
    AND engine.attr_name = 'engine'
  LEFT JOIN attrs AS dbinstancestatus
    ON dbinstancestatus.id = R.id
    AND dbinstancestatus.attr_name = 'dbinstancestatus'
  LEFT JOIN attrs AS masterusername
    ON masterusername.id = R.id
    AND masterusername.attr_name = 'masterusername'
  LEFT JOIN attrs AS dbname
    ON dbname.id = R.id
    AND dbname.attr_name = 'dbname'
  LEFT JOIN attrs AS endpoint
    ON endpoint.id = R.id
    AND endpoint.attr_name = 'endpoint'
  LEFT JOIN attrs AS allocatedstorage
    ON allocatedstorage.id = R.id
    AND allocatedstorage.attr_name = 'allocatedstorage'
  LEFT JOIN attrs AS instancecreatetime
    ON instancecreatetime.id = R.id
    AND instancecreatetime.attr_name = 'instancecreatetime'
  LEFT JOIN attrs AS preferredbackupwindow
    ON preferredbackupwindow.id = R.id
    AND preferredbackupwindow.attr_name = 'preferredbackupwindow'
  LEFT JOIN attrs AS backupretentionperiod
    ON backupretentionperiod.id = R.id
    AND backupretentionperiod.attr_name = 'backupretentionperiod'
  LEFT JOIN attrs AS dbsecuritygroups
    ON dbsecuritygroups.id = R.id
    AND dbsecuritygroups.attr_name = 'dbsecuritygroups'
  LEFT JOIN attrs AS vpcsecuritygroups
    ON vpcsecuritygroups.id = R.id
    AND vpcsecuritygroups.attr_name = 'vpcsecuritygroups'
  LEFT JOIN attrs AS dbparametergroups
    ON dbparametergroups.id = R.id
    AND dbparametergroups.attr_name = 'dbparametergroups'
  LEFT JOIN attrs AS availabilityzone
    ON availabilityzone.id = R.id
    AND availabilityzone.attr_name = 'availabilityzone'
  LEFT JOIN attrs AS dbsubnetgroup
    ON dbsubnetgroup.id = R.id
    AND dbsubnetgroup.attr_name = 'dbsubnetgroup'
  LEFT JOIN attrs AS preferredmaintenancewindow
    ON preferredmaintenancewindow.id = R.id
    AND preferredmaintenancewindow.attr_name = 'preferredmaintenancewindow'
  LEFT JOIN attrs AS pendingmodifiedvalues
    ON pendingmodifiedvalues.id = R.id
    AND pendingmodifiedvalues.attr_name = 'pendingmodifiedvalues'
  LEFT JOIN attrs AS latestrestorabletime
    ON latestrestorabletime.id = R.id
    AND latestrestorabletime.attr_name = 'latestrestorabletime'
  LEFT JOIN attrs AS multiaz
    ON multiaz.id = R.id
    AND multiaz.attr_name = 'multiaz'
  LEFT JOIN attrs AS engineversion
    ON engineversion.id = R.id
    AND engineversion.attr_name = 'engineversion'
  LEFT JOIN attrs AS autominorversionupgrade
    ON autominorversionupgrade.id = R.id
    AND autominorversionupgrade.attr_name = 'autominorversionupgrade'
  LEFT JOIN attrs AS readreplicasourcedbinstanceidentifier
    ON readreplicasourcedbinstanceidentifier.id = R.id
    AND readreplicasourcedbinstanceidentifier.attr_name = 'readreplicasourcedbinstanceidentifier'
  LEFT JOIN attrs AS readreplicadbinstanceidentifiers
    ON readreplicadbinstanceidentifiers.id = R.id
    AND readreplicadbinstanceidentifiers.attr_name = 'readreplicadbinstanceidentifiers'
  LEFT JOIN attrs AS readreplicadbclusteridentifiers
    ON readreplicadbclusteridentifiers.id = R.id
    AND readreplicadbclusteridentifiers.attr_name = 'readreplicadbclusteridentifiers'
  LEFT JOIN attrs AS licensemodel
    ON licensemodel.id = R.id
    AND licensemodel.attr_name = 'licensemodel'
  LEFT JOIN attrs AS iops
    ON iops.id = R.id
    AND iops.attr_name = 'iops'
  LEFT JOIN attrs AS optiongroupmemberships
    ON optiongroupmemberships.id = R.id
    AND optiongroupmemberships.attr_name = 'optiongroupmemberships'
  LEFT JOIN attrs AS charactersetname
    ON charactersetname.id = R.id
    AND charactersetname.attr_name = 'charactersetname'
  LEFT JOIN attrs AS secondaryavailabilityzone
    ON secondaryavailabilityzone.id = R.id
    AND secondaryavailabilityzone.attr_name = 'secondaryavailabilityzone'
  LEFT JOIN attrs AS publiclyaccessible
    ON publiclyaccessible.id = R.id
    AND publiclyaccessible.attr_name = 'publiclyaccessible'
  LEFT JOIN attrs AS statusinfos
    ON statusinfos.id = R.id
    AND statusinfos.attr_name = 'statusinfos'
  LEFT JOIN attrs AS storagetype
    ON storagetype.id = R.id
    AND storagetype.attr_name = 'storagetype'
  LEFT JOIN attrs AS tdecredentialarn
    ON tdecredentialarn.id = R.id
    AND tdecredentialarn.attr_name = 'tdecredentialarn'
  LEFT JOIN attrs AS dbinstanceport
    ON dbinstanceport.id = R.id
    AND dbinstanceport.attr_name = 'dbinstanceport'
  LEFT JOIN attrs AS dbclusteridentifier
    ON dbclusteridentifier.id = R.id
    AND dbclusteridentifier.attr_name = 'dbclusteridentifier'
  LEFT JOIN attrs AS storageencrypted
    ON storageencrypted.id = R.id
    AND storageencrypted.attr_name = 'storageencrypted'
  LEFT JOIN attrs AS kmskeyid
    ON kmskeyid.id = R.id
    AND kmskeyid.attr_name = 'kmskeyid'
  LEFT JOIN attrs AS dbiresourceid
    ON dbiresourceid.id = R.id
    AND dbiresourceid.attr_name = 'dbiresourceid'
  LEFT JOIN attrs AS cacertificateidentifier
    ON cacertificateidentifier.id = R.id
    AND cacertificateidentifier.attr_name = 'cacertificateidentifier'
  LEFT JOIN attrs AS domainmemberships
    ON domainmemberships.id = R.id
    AND domainmemberships.attr_name = 'domainmemberships'
  LEFT JOIN attrs AS copytagstosnapshot
    ON copytagstosnapshot.id = R.id
    AND copytagstosnapshot.attr_name = 'copytagstosnapshot'
  LEFT JOIN attrs AS monitoringinterval
    ON monitoringinterval.id = R.id
    AND monitoringinterval.attr_name = 'monitoringinterval'
  LEFT JOIN attrs AS enhancedmonitoringresourcearn
    ON enhancedmonitoringresourcearn.id = R.id
    AND enhancedmonitoringresourcearn.attr_name = 'enhancedmonitoringresourcearn'
  LEFT JOIN attrs AS monitoringrolearn
    ON monitoringrolearn.id = R.id
    AND monitoringrolearn.attr_name = 'monitoringrolearn'
  LEFT JOIN attrs AS promotiontier
    ON promotiontier.id = R.id
    AND promotiontier.attr_name = 'promotiontier'
  LEFT JOIN attrs AS dbinstancearn
    ON dbinstancearn.id = R.id
    AND dbinstancearn.attr_name = 'dbinstancearn'
  LEFT JOIN attrs AS timezone
    ON timezone.id = R.id
    AND timezone.attr_name = 'timezone'
  LEFT JOIN attrs AS iamdatabaseauthenticationenabled
    ON iamdatabaseauthenticationenabled.id = R.id
    AND iamdatabaseauthenticationenabled.attr_name = 'iamdatabaseauthenticationenabled'
  LEFT JOIN attrs AS performanceinsightsenabled
    ON performanceinsightsenabled.id = R.id
    AND performanceinsightsenabled.attr_name = 'performanceinsightsenabled'
  LEFT JOIN attrs AS performanceinsightskmskeyid
    ON performanceinsightskmskeyid.id = R.id
    AND performanceinsightskmskeyid.attr_name = 'performanceinsightskmskeyid'
  LEFT JOIN attrs AS performanceinsightsretentionperiod
    ON performanceinsightsretentionperiod.id = R.id
    AND performanceinsightsretentionperiod.attr_name = 'performanceinsightsretentionperiod'
  LEFT JOIN attrs AS enabledcloudwatchlogsexports
    ON enabledcloudwatchlogsexports.id = R.id
    AND enabledcloudwatchlogsexports.attr_name = 'enabledcloudwatchlogsexports'
  LEFT JOIN attrs AS processorfeatures
    ON processorfeatures.id = R.id
    AND processorfeatures.attr_name = 'processorfeatures'
  LEFT JOIN attrs AS deletionprotection
    ON deletionprotection.id = R.id
    AND deletionprotection.attr_name = 'deletionprotection'
  LEFT JOIN attrs AS associatedroles
    ON associatedroles.id = R.id
    AND associatedroles.attr_name = 'associatedroles'
  LEFT JOIN attrs AS listenerendpoint
    ON listenerendpoint.id = R.id
    AND listenerendpoint.attr_name = 'listenerendpoint'
  LEFT JOIN attrs AS maxallocatedstorage
    ON maxallocatedstorage.id = R.id
    AND maxallocatedstorage.attr_name = 'maxallocatedstorage'
  LEFT JOIN attrs AS tags
    ON tags.id = R.id
    AND tags.attr_name = 'tags'
  WHERE
  PA.provider = 'aws'
  AND LOWER(R.provider_type) = 'dbinstance'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_rds_dbinstance;

COMMENT ON MATERIALIZED VIEW aws_rds_dbinstance IS 'rds dbinstance resources and their associated attributes.';
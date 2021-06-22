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
  (allocatedstorage.attr_value #>> '{}')::integer AS allocatedstorage,
  availabilityzones.attr_value::jsonb AS availabilityzones,
  (backupretentionperiod.attr_value #>> '{}')::integer AS backupretentionperiod,
  charactersetname.attr_value #>> '{}' AS charactersetname,
  databasename.attr_value #>> '{}' AS databasename,
  dbclusteridentifier.attr_value #>> '{}' AS dbclusteridentifier,
  dbclusterparametergroup.attr_value #>> '{}' AS dbclusterparametergroup,
  dbsubnetgroup.attr_value #>> '{}' AS dbsubnetgroup,
  status.attr_value #>> '{}' AS status,
  percentprogress.attr_value #>> '{}' AS percentprogress,
  (TO_TIMESTAMP(earliestrestorabletime.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS earliestrestorabletime,
  endpoint.attr_value #>> '{}' AS endpoint,
  readerendpoint.attr_value #>> '{}' AS readerendpoint,
  customendpoints.attr_value::jsonb AS customendpoints,
  (multiaz.attr_value #>> '{}')::boolean AS multiaz,
  engine.attr_value #>> '{}' AS engine,
  engineversion.attr_value #>> '{}' AS engineversion,
  (TO_TIMESTAMP(latestrestorabletime.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS latestrestorabletime,
  (port.attr_value #>> '{}')::integer AS port,
  masterusername.attr_value #>> '{}' AS masterusername,
  dbclusteroptiongroupmemberships.attr_value::jsonb AS dbclusteroptiongroupmemberships,
  preferredbackupwindow.attr_value #>> '{}' AS preferredbackupwindow,
  preferredmaintenancewindow.attr_value #>> '{}' AS preferredmaintenancewindow,
  replicationsourceidentifier.attr_value #>> '{}' AS replicationsourceidentifier,
  readreplicaidentifiers.attr_value::jsonb AS readreplicaidentifiers,
  dbclustermembers.attr_value::jsonb AS dbclustermembers,
  vpcsecuritygroups.attr_value::jsonb AS vpcsecuritygroups,
  hostedzoneid.attr_value #>> '{}' AS hostedzoneid,
  (storageencrypted.attr_value #>> '{}')::boolean AS storageencrypted,
  kmskeyid.attr_value #>> '{}' AS kmskeyid,
  dbclusterresourceid.attr_value #>> '{}' AS dbclusterresourceid,
  dbclusterarn.attr_value #>> '{}' AS dbclusterarn,
  associatedroles.attr_value::jsonb AS associatedroles,
  (iamdatabaseauthenticationenabled.attr_value #>> '{}')::boolean AS iamdatabaseauthenticationenabled,
  clonegroupid.attr_value #>> '{}' AS clonegroupid,
  (TO_TIMESTAMP(clustercreatetime.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS clustercreatetime,
  (TO_TIMESTAMP(earliestbacktracktime.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS earliestbacktracktime,
  (backtrackwindow.attr_value #>> '{}')::bigint AS backtrackwindow,
  (backtrackconsumedchangerecords.attr_value #>> '{}')::bigint AS backtrackconsumedchangerecords,
  enabledcloudwatchlogsexports.attr_value::jsonb AS enabledcloudwatchlogsexports,
  (capacity.attr_value #>> '{}')::integer AS capacity,
  enginemode.attr_value #>> '{}' AS enginemode,
  scalingconfigurationinfo.attr_value::jsonb AS scalingconfigurationinfo,
  (deletionprotection.attr_value #>> '{}')::boolean AS deletionprotection,
  (httpendpointenabled.attr_value #>> '{}')::boolean AS httpendpointenabled,
  activitystreammode.attr_value #>> '{}' AS activitystreammode,
  activitystreamstatus.attr_value #>> '{}' AS activitystreamstatus,
  activitystreamkmskeyid.attr_value #>> '{}' AS activitystreamkmskeyid,
  activitystreamkinesisstreamname.attr_value #>> '{}' AS activitystreamkinesisstreamname,
  (copytagstosnapshot.attr_value #>> '{}')::boolean AS copytagstosnapshot,
  (crossaccountclone.attr_value #>> '{}')::boolean AS crossaccountclone,
  domainmemberships.attr_value::jsonb AS domainmemberships,
  taglist.attr_value::jsonb AS taglist,
  globalwriteforwardingstatus.attr_value #>> '{}' AS globalwriteforwardingstatus,
  (globalwriteforwardingrequested.attr_value #>> '{}')::boolean AS globalwriteforwardingrequested,
  pendingmodifiedvalues.attr_value::jsonb AS pendingmodifiedvalues,
  _tags.attr_value::jsonb AS _tags,
  
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN resource_attribute AS allocatedstorage
    ON allocatedstorage.resource_id = R.id
    AND allocatedstorage.type = 'provider'
    AND lower(allocatedstorage.attr_name) = 'allocatedstorage'
    AND allocatedstorage.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS availabilityzones
    ON availabilityzones.resource_id = R.id
    AND availabilityzones.type = 'provider'
    AND lower(availabilityzones.attr_name) = 'availabilityzones'
    AND availabilityzones.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS backupretentionperiod
    ON backupretentionperiod.resource_id = R.id
    AND backupretentionperiod.type = 'provider'
    AND lower(backupretentionperiod.attr_name) = 'backupretentionperiod'
    AND backupretentionperiod.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS charactersetname
    ON charactersetname.resource_id = R.id
    AND charactersetname.type = 'provider'
    AND lower(charactersetname.attr_name) = 'charactersetname'
    AND charactersetname.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS databasename
    ON databasename.resource_id = R.id
    AND databasename.type = 'provider'
    AND lower(databasename.attr_name) = 'databasename'
    AND databasename.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS dbclusteridentifier
    ON dbclusteridentifier.resource_id = R.id
    AND dbclusteridentifier.type = 'provider'
    AND lower(dbclusteridentifier.attr_name) = 'dbclusteridentifier'
    AND dbclusteridentifier.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS dbclusterparametergroup
    ON dbclusterparametergroup.resource_id = R.id
    AND dbclusterparametergroup.type = 'provider'
    AND lower(dbclusterparametergroup.attr_name) = 'dbclusterparametergroup'
    AND dbclusterparametergroup.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS dbsubnetgroup
    ON dbsubnetgroup.resource_id = R.id
    AND dbsubnetgroup.type = 'provider'
    AND lower(dbsubnetgroup.attr_name) = 'dbsubnetgroup'
    AND dbsubnetgroup.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS status
    ON status.resource_id = R.id
    AND status.type = 'provider'
    AND lower(status.attr_name) = 'status'
    AND status.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS percentprogress
    ON percentprogress.resource_id = R.id
    AND percentprogress.type = 'provider'
    AND lower(percentprogress.attr_name) = 'percentprogress'
    AND percentprogress.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS earliestrestorabletime
    ON earliestrestorabletime.resource_id = R.id
    AND earliestrestorabletime.type = 'provider'
    AND lower(earliestrestorabletime.attr_name) = 'earliestrestorabletime'
    AND earliestrestorabletime.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS endpoint
    ON endpoint.resource_id = R.id
    AND endpoint.type = 'provider'
    AND lower(endpoint.attr_name) = 'endpoint'
    AND endpoint.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS readerendpoint
    ON readerendpoint.resource_id = R.id
    AND readerendpoint.type = 'provider'
    AND lower(readerendpoint.attr_name) = 'readerendpoint'
    AND readerendpoint.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS customendpoints
    ON customendpoints.resource_id = R.id
    AND customendpoints.type = 'provider'
    AND lower(customendpoints.attr_name) = 'customendpoints'
    AND customendpoints.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS multiaz
    ON multiaz.resource_id = R.id
    AND multiaz.type = 'provider'
    AND lower(multiaz.attr_name) = 'multiaz'
    AND multiaz.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS engine
    ON engine.resource_id = R.id
    AND engine.type = 'provider'
    AND lower(engine.attr_name) = 'engine'
    AND engine.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS engineversion
    ON engineversion.resource_id = R.id
    AND engineversion.type = 'provider'
    AND lower(engineversion.attr_name) = 'engineversion'
    AND engineversion.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS latestrestorabletime
    ON latestrestorabletime.resource_id = R.id
    AND latestrestorabletime.type = 'provider'
    AND lower(latestrestorabletime.attr_name) = 'latestrestorabletime'
    AND latestrestorabletime.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS port
    ON port.resource_id = R.id
    AND port.type = 'provider'
    AND lower(port.attr_name) = 'port'
    AND port.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS masterusername
    ON masterusername.resource_id = R.id
    AND masterusername.type = 'provider'
    AND lower(masterusername.attr_name) = 'masterusername'
    AND masterusername.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS dbclusteroptiongroupmemberships
    ON dbclusteroptiongroupmemberships.resource_id = R.id
    AND dbclusteroptiongroupmemberships.type = 'provider'
    AND lower(dbclusteroptiongroupmemberships.attr_name) = 'dbclusteroptiongroupmemberships'
    AND dbclusteroptiongroupmemberships.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS preferredbackupwindow
    ON preferredbackupwindow.resource_id = R.id
    AND preferredbackupwindow.type = 'provider'
    AND lower(preferredbackupwindow.attr_name) = 'preferredbackupwindow'
    AND preferredbackupwindow.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS preferredmaintenancewindow
    ON preferredmaintenancewindow.resource_id = R.id
    AND preferredmaintenancewindow.type = 'provider'
    AND lower(preferredmaintenancewindow.attr_name) = 'preferredmaintenancewindow'
    AND preferredmaintenancewindow.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS replicationsourceidentifier
    ON replicationsourceidentifier.resource_id = R.id
    AND replicationsourceidentifier.type = 'provider'
    AND lower(replicationsourceidentifier.attr_name) = 'replicationsourceidentifier'
    AND replicationsourceidentifier.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS readreplicaidentifiers
    ON readreplicaidentifiers.resource_id = R.id
    AND readreplicaidentifiers.type = 'provider'
    AND lower(readreplicaidentifiers.attr_name) = 'readreplicaidentifiers'
    AND readreplicaidentifiers.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS dbclustermembers
    ON dbclustermembers.resource_id = R.id
    AND dbclustermembers.type = 'provider'
    AND lower(dbclustermembers.attr_name) = 'dbclustermembers'
    AND dbclustermembers.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS vpcsecuritygroups
    ON vpcsecuritygroups.resource_id = R.id
    AND vpcsecuritygroups.type = 'provider'
    AND lower(vpcsecuritygroups.attr_name) = 'vpcsecuritygroups'
    AND vpcsecuritygroups.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS hostedzoneid
    ON hostedzoneid.resource_id = R.id
    AND hostedzoneid.type = 'provider'
    AND lower(hostedzoneid.attr_name) = 'hostedzoneid'
    AND hostedzoneid.provider_account_id = R.provider_account_id
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
  LEFT JOIN resource_attribute AS dbclusterresourceid
    ON dbclusterresourceid.resource_id = R.id
    AND dbclusterresourceid.type = 'provider'
    AND lower(dbclusterresourceid.attr_name) = 'dbclusterresourceid'
    AND dbclusterresourceid.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS dbclusterarn
    ON dbclusterarn.resource_id = R.id
    AND dbclusterarn.type = 'provider'
    AND lower(dbclusterarn.attr_name) = 'dbclusterarn'
    AND dbclusterarn.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS associatedroles
    ON associatedroles.resource_id = R.id
    AND associatedroles.type = 'provider'
    AND lower(associatedroles.attr_name) = 'associatedroles'
    AND associatedroles.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS iamdatabaseauthenticationenabled
    ON iamdatabaseauthenticationenabled.resource_id = R.id
    AND iamdatabaseauthenticationenabled.type = 'provider'
    AND lower(iamdatabaseauthenticationenabled.attr_name) = 'iamdatabaseauthenticationenabled'
    AND iamdatabaseauthenticationenabled.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS clonegroupid
    ON clonegroupid.resource_id = R.id
    AND clonegroupid.type = 'provider'
    AND lower(clonegroupid.attr_name) = 'clonegroupid'
    AND clonegroupid.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS clustercreatetime
    ON clustercreatetime.resource_id = R.id
    AND clustercreatetime.type = 'provider'
    AND lower(clustercreatetime.attr_name) = 'clustercreatetime'
    AND clustercreatetime.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS earliestbacktracktime
    ON earliestbacktracktime.resource_id = R.id
    AND earliestbacktracktime.type = 'provider'
    AND lower(earliestbacktracktime.attr_name) = 'earliestbacktracktime'
    AND earliestbacktracktime.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS backtrackwindow
    ON backtrackwindow.resource_id = R.id
    AND backtrackwindow.type = 'provider'
    AND lower(backtrackwindow.attr_name) = 'backtrackwindow'
    AND backtrackwindow.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS backtrackconsumedchangerecords
    ON backtrackconsumedchangerecords.resource_id = R.id
    AND backtrackconsumedchangerecords.type = 'provider'
    AND lower(backtrackconsumedchangerecords.attr_name) = 'backtrackconsumedchangerecords'
    AND backtrackconsumedchangerecords.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS enabledcloudwatchlogsexports
    ON enabledcloudwatchlogsexports.resource_id = R.id
    AND enabledcloudwatchlogsexports.type = 'provider'
    AND lower(enabledcloudwatchlogsexports.attr_name) = 'enabledcloudwatchlogsexports'
    AND enabledcloudwatchlogsexports.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS capacity
    ON capacity.resource_id = R.id
    AND capacity.type = 'provider'
    AND lower(capacity.attr_name) = 'capacity'
    AND capacity.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS enginemode
    ON enginemode.resource_id = R.id
    AND enginemode.type = 'provider'
    AND lower(enginemode.attr_name) = 'enginemode'
    AND enginemode.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS scalingconfigurationinfo
    ON scalingconfigurationinfo.resource_id = R.id
    AND scalingconfigurationinfo.type = 'provider'
    AND lower(scalingconfigurationinfo.attr_name) = 'scalingconfigurationinfo'
    AND scalingconfigurationinfo.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS deletionprotection
    ON deletionprotection.resource_id = R.id
    AND deletionprotection.type = 'provider'
    AND lower(deletionprotection.attr_name) = 'deletionprotection'
    AND deletionprotection.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS httpendpointenabled
    ON httpendpointenabled.resource_id = R.id
    AND httpendpointenabled.type = 'provider'
    AND lower(httpendpointenabled.attr_name) = 'httpendpointenabled'
    AND httpendpointenabled.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS activitystreammode
    ON activitystreammode.resource_id = R.id
    AND activitystreammode.type = 'provider'
    AND lower(activitystreammode.attr_name) = 'activitystreammode'
    AND activitystreammode.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS activitystreamstatus
    ON activitystreamstatus.resource_id = R.id
    AND activitystreamstatus.type = 'provider'
    AND lower(activitystreamstatus.attr_name) = 'activitystreamstatus'
    AND activitystreamstatus.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS activitystreamkmskeyid
    ON activitystreamkmskeyid.resource_id = R.id
    AND activitystreamkmskeyid.type = 'provider'
    AND lower(activitystreamkmskeyid.attr_name) = 'activitystreamkmskeyid'
    AND activitystreamkmskeyid.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS activitystreamkinesisstreamname
    ON activitystreamkinesisstreamname.resource_id = R.id
    AND activitystreamkinesisstreamname.type = 'provider'
    AND lower(activitystreamkinesisstreamname.attr_name) = 'activitystreamkinesisstreamname'
    AND activitystreamkinesisstreamname.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS copytagstosnapshot
    ON copytagstosnapshot.resource_id = R.id
    AND copytagstosnapshot.type = 'provider'
    AND lower(copytagstosnapshot.attr_name) = 'copytagstosnapshot'
    AND copytagstosnapshot.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS crossaccountclone
    ON crossaccountclone.resource_id = R.id
    AND crossaccountclone.type = 'provider'
    AND lower(crossaccountclone.attr_name) = 'crossaccountclone'
    AND crossaccountclone.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS domainmemberships
    ON domainmemberships.resource_id = R.id
    AND domainmemberships.type = 'provider'
    AND lower(domainmemberships.attr_name) = 'domainmemberships'
    AND domainmemberships.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS taglist
    ON taglist.resource_id = R.id
    AND taglist.type = 'provider'
    AND lower(taglist.attr_name) = 'taglist'
    AND taglist.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS globalwriteforwardingstatus
    ON globalwriteforwardingstatus.resource_id = R.id
    AND globalwriteforwardingstatus.type = 'provider'
    AND lower(globalwriteforwardingstatus.attr_name) = 'globalwriteforwardingstatus'
    AND globalwriteforwardingstatus.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS globalwriteforwardingrequested
    ON globalwriteforwardingrequested.resource_id = R.id
    AND globalwriteforwardingrequested.type = 'provider'
    AND lower(globalwriteforwardingrequested.attr_name) = 'globalwriteforwardingrequested'
    AND globalwriteforwardingrequested.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS pendingmodifiedvalues
    ON pendingmodifiedvalues.resource_id = R.id
    AND pendingmodifiedvalues.type = 'provider'
    AND lower(pendingmodifiedvalues.attr_name) = 'pendingmodifiedvalues'
    AND pendingmodifiedvalues.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS _tags
    ON _tags.resource_id = R.id
    AND _tags.type = 'Metadata'
    AND lower(_tags.attr_name) = 'tags'
    AND _tags.provider_account_id = R.provider_account_id
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
  AND R.provider_type = 'DBCluster'
  AND R.service = 'rds'
ON CONFLICT (_id) DO UPDATE
SET
    allocatedstorage = EXCLUDED.allocatedstorage,
    availabilityzones = EXCLUDED.availabilityzones,
    backupretentionperiod = EXCLUDED.backupretentionperiod,
    charactersetname = EXCLUDED.charactersetname,
    databasename = EXCLUDED.databasename,
    dbclusteridentifier = EXCLUDED.dbclusteridentifier,
    dbclusterparametergroup = EXCLUDED.dbclusterparametergroup,
    dbsubnetgroup = EXCLUDED.dbsubnetgroup,
    status = EXCLUDED.status,
    percentprogress = EXCLUDED.percentprogress,
    earliestrestorabletime = EXCLUDED.earliestrestorabletime,
    endpoint = EXCLUDED.endpoint,
    readerendpoint = EXCLUDED.readerendpoint,
    customendpoints = EXCLUDED.customendpoints,
    multiaz = EXCLUDED.multiaz,
    engine = EXCLUDED.engine,
    engineversion = EXCLUDED.engineversion,
    latestrestorabletime = EXCLUDED.latestrestorabletime,
    port = EXCLUDED.port,
    masterusername = EXCLUDED.masterusername,
    dbclusteroptiongroupmemberships = EXCLUDED.dbclusteroptiongroupmemberships,
    preferredbackupwindow = EXCLUDED.preferredbackupwindow,
    preferredmaintenancewindow = EXCLUDED.preferredmaintenancewindow,
    replicationsourceidentifier = EXCLUDED.replicationsourceidentifier,
    readreplicaidentifiers = EXCLUDED.readreplicaidentifiers,
    dbclustermembers = EXCLUDED.dbclustermembers,
    vpcsecuritygroups = EXCLUDED.vpcsecuritygroups,
    hostedzoneid = EXCLUDED.hostedzoneid,
    storageencrypted = EXCLUDED.storageencrypted,
    kmskeyid = EXCLUDED.kmskeyid,
    dbclusterresourceid = EXCLUDED.dbclusterresourceid,
    dbclusterarn = EXCLUDED.dbclusterarn,
    associatedroles = EXCLUDED.associatedroles,
    iamdatabaseauthenticationenabled = EXCLUDED.iamdatabaseauthenticationenabled,
    clonegroupid = EXCLUDED.clonegroupid,
    clustercreatetime = EXCLUDED.clustercreatetime,
    earliestbacktracktime = EXCLUDED.earliestbacktracktime,
    backtrackwindow = EXCLUDED.backtrackwindow,
    backtrackconsumedchangerecords = EXCLUDED.backtrackconsumedchangerecords,
    enabledcloudwatchlogsexports = EXCLUDED.enabledcloudwatchlogsexports,
    capacity = EXCLUDED.capacity,
    enginemode = EXCLUDED.enginemode,
    scalingconfigurationinfo = EXCLUDED.scalingconfigurationinfo,
    deletionprotection = EXCLUDED.deletionprotection,
    httpendpointenabled = EXCLUDED.httpendpointenabled,
    activitystreammode = EXCLUDED.activitystreammode,
    activitystreamstatus = EXCLUDED.activitystreamstatus,
    activitystreamkmskeyid = EXCLUDED.activitystreamkmskeyid,
    activitystreamkinesisstreamname = EXCLUDED.activitystreamkinesisstreamname,
    copytagstosnapshot = EXCLUDED.copytagstosnapshot,
    crossaccountclone = EXCLUDED.crossaccountclone,
    domainmemberships = EXCLUDED.domainmemberships,
    taglist = EXCLUDED.taglist,
    globalwriteforwardingstatus = EXCLUDED.globalwriteforwardingstatus,
    globalwriteforwardingrequested = EXCLUDED.globalwriteforwardingrequested,
    pendingmodifiedvalues = EXCLUDED.pendingmodifiedvalues,
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
  WHERE
    aws_rds_dbcluster.provider_type = 'DBCluster'
    AND aws_rds_dbcluster.service = 'rds'
ON CONFLICT (dbcluster_id, securitygroup_id)
DO NOTHING
;

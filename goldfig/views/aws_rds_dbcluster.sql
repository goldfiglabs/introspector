DROP MATERIALIZED VIEW IF EXISTS aws_rds_dbcluster CASCADE;

CREATE MATERIALIZED VIEW aws_rds_dbcluster AS
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
  allocatedstorage.attr_value::integer AS allocatedstorage,
  availabilityzones.attr_value::jsonb AS availabilityzones,
  backupretentionperiod.attr_value::integer AS backupretentionperiod,
  charactersetname.attr_value #>> '{}' AS charactersetname,
  databasename.attr_value #>> '{}' AS databasename,
  dbclusteridentifier.attr_value #>> '{}' AS dbclusteridentifier,
  dbclusterparametergroup.attr_value #>> '{}' AS dbclusterparametergroup,
  dbsubnetgroup.attr_value #>> '{}' AS dbsubnetgroup,
  status.attr_value #>> '{}' AS status,
  percentprogress.attr_value #>> '{}' AS percentprogress,
  earliestrestorabletime.attr_value AS earliestrestorabletime,
  endpoint.attr_value #>> '{}' AS endpoint,
  readerendpoint.attr_value #>> '{}' AS readerendpoint,
  customendpoints.attr_value::jsonb AS customendpoints,
  multiaz.attr_value::boolean AS multiaz,
  engine.attr_value #>> '{}' AS engine,
  engineversion.attr_value #>> '{}' AS engineversion,
  latestrestorabletime.attr_value AS latestrestorabletime,
  port.attr_value::integer AS port,
  masterusername.attr_value #>> '{}' AS masterusername,
  dbclusteroptiongroupmemberships.attr_value::jsonb AS dbclusteroptiongroupmemberships,
  preferredbackupwindow.attr_value #>> '{}' AS preferredbackupwindow,
  preferredmaintenancewindow.attr_value #>> '{}' AS preferredmaintenancewindow,
  replicationsourceidentifier.attr_value #>> '{}' AS replicationsourceidentifier,
  readreplicaidentifiers.attr_value::jsonb AS readreplicaidentifiers,
  dbclustermembers.attr_value::jsonb AS dbclustermembers,
  vpcsecuritygroups.attr_value::jsonb AS vpcsecuritygroups,
  hostedzoneid.attr_value #>> '{}' AS hostedzoneid,
  storageencrypted.attr_value::boolean AS storageencrypted,
  kmskeyid.attr_value #>> '{}' AS kmskeyid,
  dbclusterresourceid.attr_value #>> '{}' AS dbclusterresourceid,
  dbclusterarn.attr_value #>> '{}' AS dbclusterarn,
  associatedroles.attr_value::jsonb AS associatedroles,
  iamdatabaseauthenticationenabled.attr_value::boolean AS iamdatabaseauthenticationenabled,
  clonegroupid.attr_value #>> '{}' AS clonegroupid,
  clustercreatetime.attr_value AS clustercreatetime,
  earliestbacktracktime.attr_value AS earliestbacktracktime,
  backtrackwindow.attr_value::bigint AS backtrackwindow,
  backtrackconsumedchangerecords.attr_value::bigint AS backtrackconsumedchangerecords,
  enabledcloudwatchlogsexports.attr_value::jsonb AS enabledcloudwatchlogsexports,
  capacity.attr_value::integer AS capacity,
  enginemode.attr_value #>> '{}' AS enginemode,
  scalingconfigurationinfo.attr_value::jsonb AS scalingconfigurationinfo,
  deletionprotection.attr_value::boolean AS deletionprotection,
  httpendpointenabled.attr_value::boolean AS httpendpointenabled,
  activitystreammode.attr_value #>> '{}' AS activitystreammode,
  activitystreamstatus.attr_value #>> '{}' AS activitystreamstatus,
  activitystreamkmskeyid.attr_value #>> '{}' AS activitystreamkmskeyid,
  activitystreamkinesisstreamname.attr_value #>> '{}' AS activitystreamkinesisstreamname,
  copytagstosnapshot.attr_value::boolean AS copytagstosnapshot,
  crossaccountclone.attr_value::boolean AS crossaccountclone,
  domainmemberships.attr_value::jsonb AS domainmemberships,
  globalwriteforwardingstatus.attr_value #>> '{}' AS globalwriteforwardingstatus,
  globalwriteforwardingrequested.attr_value::boolean AS globalwriteforwardingrequested,
  tags.attr_value::jsonb AS tags,
  
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN attrs AS allocatedstorage
    ON allocatedstorage.id = R.id
    AND allocatedstorage.attr_name = 'allocatedstorage'
  LEFT JOIN attrs AS availabilityzones
    ON availabilityzones.id = R.id
    AND availabilityzones.attr_name = 'availabilityzones'
  LEFT JOIN attrs AS backupretentionperiod
    ON backupretentionperiod.id = R.id
    AND backupretentionperiod.attr_name = 'backupretentionperiod'
  LEFT JOIN attrs AS charactersetname
    ON charactersetname.id = R.id
    AND charactersetname.attr_name = 'charactersetname'
  LEFT JOIN attrs AS databasename
    ON databasename.id = R.id
    AND databasename.attr_name = 'databasename'
  LEFT JOIN attrs AS dbclusteridentifier
    ON dbclusteridentifier.id = R.id
    AND dbclusteridentifier.attr_name = 'dbclusteridentifier'
  LEFT JOIN attrs AS dbclusterparametergroup
    ON dbclusterparametergroup.id = R.id
    AND dbclusterparametergroup.attr_name = 'dbclusterparametergroup'
  LEFT JOIN attrs AS dbsubnetgroup
    ON dbsubnetgroup.id = R.id
    AND dbsubnetgroup.attr_name = 'dbsubnetgroup'
  LEFT JOIN attrs AS status
    ON status.id = R.id
    AND status.attr_name = 'status'
  LEFT JOIN attrs AS percentprogress
    ON percentprogress.id = R.id
    AND percentprogress.attr_name = 'percentprogress'
  LEFT JOIN attrs AS earliestrestorabletime
    ON earliestrestorabletime.id = R.id
    AND earliestrestorabletime.attr_name = 'earliestrestorabletime'
  LEFT JOIN attrs AS endpoint
    ON endpoint.id = R.id
    AND endpoint.attr_name = 'endpoint'
  LEFT JOIN attrs AS readerendpoint
    ON readerendpoint.id = R.id
    AND readerendpoint.attr_name = 'readerendpoint'
  LEFT JOIN attrs AS customendpoints
    ON customendpoints.id = R.id
    AND customendpoints.attr_name = 'customendpoints'
  LEFT JOIN attrs AS multiaz
    ON multiaz.id = R.id
    AND multiaz.attr_name = 'multiaz'
  LEFT JOIN attrs AS engine
    ON engine.id = R.id
    AND engine.attr_name = 'engine'
  LEFT JOIN attrs AS engineversion
    ON engineversion.id = R.id
    AND engineversion.attr_name = 'engineversion'
  LEFT JOIN attrs AS latestrestorabletime
    ON latestrestorabletime.id = R.id
    AND latestrestorabletime.attr_name = 'latestrestorabletime'
  LEFT JOIN attrs AS port
    ON port.id = R.id
    AND port.attr_name = 'port'
  LEFT JOIN attrs AS masterusername
    ON masterusername.id = R.id
    AND masterusername.attr_name = 'masterusername'
  LEFT JOIN attrs AS dbclusteroptiongroupmemberships
    ON dbclusteroptiongroupmemberships.id = R.id
    AND dbclusteroptiongroupmemberships.attr_name = 'dbclusteroptiongroupmemberships'
  LEFT JOIN attrs AS preferredbackupwindow
    ON preferredbackupwindow.id = R.id
    AND preferredbackupwindow.attr_name = 'preferredbackupwindow'
  LEFT JOIN attrs AS preferredmaintenancewindow
    ON preferredmaintenancewindow.id = R.id
    AND preferredmaintenancewindow.attr_name = 'preferredmaintenancewindow'
  LEFT JOIN attrs AS replicationsourceidentifier
    ON replicationsourceidentifier.id = R.id
    AND replicationsourceidentifier.attr_name = 'replicationsourceidentifier'
  LEFT JOIN attrs AS readreplicaidentifiers
    ON readreplicaidentifiers.id = R.id
    AND readreplicaidentifiers.attr_name = 'readreplicaidentifiers'
  LEFT JOIN attrs AS dbclustermembers
    ON dbclustermembers.id = R.id
    AND dbclustermembers.attr_name = 'dbclustermembers'
  LEFT JOIN attrs AS vpcsecuritygroups
    ON vpcsecuritygroups.id = R.id
    AND vpcsecuritygroups.attr_name = 'vpcsecuritygroups'
  LEFT JOIN attrs AS hostedzoneid
    ON hostedzoneid.id = R.id
    AND hostedzoneid.attr_name = 'hostedzoneid'
  LEFT JOIN attrs AS storageencrypted
    ON storageencrypted.id = R.id
    AND storageencrypted.attr_name = 'storageencrypted'
  LEFT JOIN attrs AS kmskeyid
    ON kmskeyid.id = R.id
    AND kmskeyid.attr_name = 'kmskeyid'
  LEFT JOIN attrs AS dbclusterresourceid
    ON dbclusterresourceid.id = R.id
    AND dbclusterresourceid.attr_name = 'dbclusterresourceid'
  LEFT JOIN attrs AS dbclusterarn
    ON dbclusterarn.id = R.id
    AND dbclusterarn.attr_name = 'dbclusterarn'
  LEFT JOIN attrs AS associatedroles
    ON associatedroles.id = R.id
    AND associatedroles.attr_name = 'associatedroles'
  LEFT JOIN attrs AS iamdatabaseauthenticationenabled
    ON iamdatabaseauthenticationenabled.id = R.id
    AND iamdatabaseauthenticationenabled.attr_name = 'iamdatabaseauthenticationenabled'
  LEFT JOIN attrs AS clonegroupid
    ON clonegroupid.id = R.id
    AND clonegroupid.attr_name = 'clonegroupid'
  LEFT JOIN attrs AS clustercreatetime
    ON clustercreatetime.id = R.id
    AND clustercreatetime.attr_name = 'clustercreatetime'
  LEFT JOIN attrs AS earliestbacktracktime
    ON earliestbacktracktime.id = R.id
    AND earliestbacktracktime.attr_name = 'earliestbacktracktime'
  LEFT JOIN attrs AS backtrackwindow
    ON backtrackwindow.id = R.id
    AND backtrackwindow.attr_name = 'backtrackwindow'
  LEFT JOIN attrs AS backtrackconsumedchangerecords
    ON backtrackconsumedchangerecords.id = R.id
    AND backtrackconsumedchangerecords.attr_name = 'backtrackconsumedchangerecords'
  LEFT JOIN attrs AS enabledcloudwatchlogsexports
    ON enabledcloudwatchlogsexports.id = R.id
    AND enabledcloudwatchlogsexports.attr_name = 'enabledcloudwatchlogsexports'
  LEFT JOIN attrs AS capacity
    ON capacity.id = R.id
    AND capacity.attr_name = 'capacity'
  LEFT JOIN attrs AS enginemode
    ON enginemode.id = R.id
    AND enginemode.attr_name = 'enginemode'
  LEFT JOIN attrs AS scalingconfigurationinfo
    ON scalingconfigurationinfo.id = R.id
    AND scalingconfigurationinfo.attr_name = 'scalingconfigurationinfo'
  LEFT JOIN attrs AS deletionprotection
    ON deletionprotection.id = R.id
    AND deletionprotection.attr_name = 'deletionprotection'
  LEFT JOIN attrs AS httpendpointenabled
    ON httpendpointenabled.id = R.id
    AND httpendpointenabled.attr_name = 'httpendpointenabled'
  LEFT JOIN attrs AS activitystreammode
    ON activitystreammode.id = R.id
    AND activitystreammode.attr_name = 'activitystreammode'
  LEFT JOIN attrs AS activitystreamstatus
    ON activitystreamstatus.id = R.id
    AND activitystreamstatus.attr_name = 'activitystreamstatus'
  LEFT JOIN attrs AS activitystreamkmskeyid
    ON activitystreamkmskeyid.id = R.id
    AND activitystreamkmskeyid.attr_name = 'activitystreamkmskeyid'
  LEFT JOIN attrs AS activitystreamkinesisstreamname
    ON activitystreamkinesisstreamname.id = R.id
    AND activitystreamkinesisstreamname.attr_name = 'activitystreamkinesisstreamname'
  LEFT JOIN attrs AS copytagstosnapshot
    ON copytagstosnapshot.id = R.id
    AND copytagstosnapshot.attr_name = 'copytagstosnapshot'
  LEFT JOIN attrs AS crossaccountclone
    ON crossaccountclone.id = R.id
    AND crossaccountclone.attr_name = 'crossaccountclone'
  LEFT JOIN attrs AS domainmemberships
    ON domainmemberships.id = R.id
    AND domainmemberships.attr_name = 'domainmemberships'
  LEFT JOIN attrs AS globalwriteforwardingstatus
    ON globalwriteforwardingstatus.id = R.id
    AND globalwriteforwardingstatus.attr_name = 'globalwriteforwardingstatus'
  LEFT JOIN attrs AS globalwriteforwardingrequested
    ON globalwriteforwardingrequested.id = R.id
    AND globalwriteforwardingrequested.attr_name = 'globalwriteforwardingrequested'
  LEFT JOIN attrs AS tags
    ON tags.id = R.id
    AND tags.attr_name = 'tags'
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
  AND LOWER(R.provider_type) = 'dbcluster'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_rds_dbcluster;

COMMENT ON MATERIALIZED VIEW aws_rds_dbcluster IS 'rds dbcluster resources and their associated attributes.';



DROP MATERIALIZED VIEW IF EXISTS aws_rds_dbcluster_ec2_securitygroup CASCADE;

CREATE MATERIALIZED VIEW aws_rds_dbcluster_ec2_securitygroup AS
SELECT
  aws_rds_dbcluster.id AS dbcluster_id,
  aws_ec2_securitygroup.id AS securitygroup_id
FROM
  resource AS aws_rds_dbcluster
  INNER JOIN resource_relation AS RR
    ON RR.resource_id = aws_rds_dbcluster.id
    AND RR.relation = 'in'
  INNER JOIN resource AS aws_ec2_securitygroup
    ON aws_ec2_securitygroup.id = RR.target_id
    AND aws_ec2_securitygroup.provider_type = 'SecurityGroup'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_rds_dbcluster_ec2_securitygroup;

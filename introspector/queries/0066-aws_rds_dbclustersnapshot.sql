INSERT INTO aws_rds_dbclustersnapshot (
  _id,
  uri,
  provider_account_id,
  availabilityzones,
  dbclustersnapshotidentifier,
  dbclusteridentifier,
  snapshotcreatetime,
  engine,
  allocatedstorage,
  status,
  port,
  vpcid,
  clustercreatetime,
  masterusername,
  engineversion,
  licensemodel,
  snapshottype,
  percentprogress,
  storageencrypted,
  kmskeyid,
  dbclustersnapshotarn,
  sourcedbclustersnapshotarn,
  iamdatabaseauthenticationenabled,
  taglist,
  restore,
  _tags,
  _kms_key_id,_ec2_vpc_id,_dbcluster_id,_account_id
)
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  availabilityzones.attr_value::jsonb AS availabilityzones,
  dbclustersnapshotidentifier.attr_value #>> '{}' AS dbclustersnapshotidentifier,
  dbclusteridentifier.attr_value #>> '{}' AS dbclusteridentifier,
  (TO_TIMESTAMP(snapshotcreatetime.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS snapshotcreatetime,
  engine.attr_value #>> '{}' AS engine,
  (allocatedstorage.attr_value #>> '{}')::integer AS allocatedstorage,
  status.attr_value #>> '{}' AS status,
  (port.attr_value #>> '{}')::integer AS port,
  vpcid.attr_value #>> '{}' AS vpcid,
  (TO_TIMESTAMP(clustercreatetime.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS clustercreatetime,
  masterusername.attr_value #>> '{}' AS masterusername,
  engineversion.attr_value #>> '{}' AS engineversion,
  licensemodel.attr_value #>> '{}' AS licensemodel,
  snapshottype.attr_value #>> '{}' AS snapshottype,
  (percentprogress.attr_value #>> '{}')::integer AS percentprogress,
  (storageencrypted.attr_value #>> '{}')::boolean AS storageencrypted,
  kmskeyid.attr_value #>> '{}' AS kmskeyid,
  dbclustersnapshotarn.attr_value #>> '{}' AS dbclustersnapshotarn,
  sourcedbclustersnapshotarn.attr_value #>> '{}' AS sourcedbclustersnapshotarn,
  (iamdatabaseauthenticationenabled.attr_value #>> '{}')::boolean AS iamdatabaseauthenticationenabled,
  taglist.attr_value::jsonb AS taglist,
  restore.attr_value::jsonb AS restore,
  _tags.attr_value::jsonb AS _tags,

    _kms_key_id.target_id AS _kms_key_id,
    _ec2_vpc_id.target_id AS _ec2_vpc_id,
    _dbcluster_id.target_id AS _dbcluster_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN resource_attribute AS availabilityzones
    ON availabilityzones.resource_id = R.id
    AND availabilityzones.type = 'provider'
    AND lower(availabilityzones.attr_name) = 'availabilityzones'
  LEFT JOIN resource_attribute AS dbclustersnapshotidentifier
    ON dbclustersnapshotidentifier.resource_id = R.id
    AND dbclustersnapshotidentifier.type = 'provider'
    AND lower(dbclustersnapshotidentifier.attr_name) = 'dbclustersnapshotidentifier'
  LEFT JOIN resource_attribute AS dbclusteridentifier
    ON dbclusteridentifier.resource_id = R.id
    AND dbclusteridentifier.type = 'provider'
    AND lower(dbclusteridentifier.attr_name) = 'dbclusteridentifier'
  LEFT JOIN resource_attribute AS snapshotcreatetime
    ON snapshotcreatetime.resource_id = R.id
    AND snapshotcreatetime.type = 'provider'
    AND lower(snapshotcreatetime.attr_name) = 'snapshotcreatetime'
  LEFT JOIN resource_attribute AS engine
    ON engine.resource_id = R.id
    AND engine.type = 'provider'
    AND lower(engine.attr_name) = 'engine'
  LEFT JOIN resource_attribute AS allocatedstorage
    ON allocatedstorage.resource_id = R.id
    AND allocatedstorage.type = 'provider'
    AND lower(allocatedstorage.attr_name) = 'allocatedstorage'
  LEFT JOIN resource_attribute AS status
    ON status.resource_id = R.id
    AND status.type = 'provider'
    AND lower(status.attr_name) = 'status'
  LEFT JOIN resource_attribute AS port
    ON port.resource_id = R.id
    AND port.type = 'provider'
    AND lower(port.attr_name) = 'port'
  LEFT JOIN resource_attribute AS vpcid
    ON vpcid.resource_id = R.id
    AND vpcid.type = 'provider'
    AND lower(vpcid.attr_name) = 'vpcid'
  LEFT JOIN resource_attribute AS clustercreatetime
    ON clustercreatetime.resource_id = R.id
    AND clustercreatetime.type = 'provider'
    AND lower(clustercreatetime.attr_name) = 'clustercreatetime'
  LEFT JOIN resource_attribute AS masterusername
    ON masterusername.resource_id = R.id
    AND masterusername.type = 'provider'
    AND lower(masterusername.attr_name) = 'masterusername'
  LEFT JOIN resource_attribute AS engineversion
    ON engineversion.resource_id = R.id
    AND engineversion.type = 'provider'
    AND lower(engineversion.attr_name) = 'engineversion'
  LEFT JOIN resource_attribute AS licensemodel
    ON licensemodel.resource_id = R.id
    AND licensemodel.type = 'provider'
    AND lower(licensemodel.attr_name) = 'licensemodel'
  LEFT JOIN resource_attribute AS snapshottype
    ON snapshottype.resource_id = R.id
    AND snapshottype.type = 'provider'
    AND lower(snapshottype.attr_name) = 'snapshottype'
  LEFT JOIN resource_attribute AS percentprogress
    ON percentprogress.resource_id = R.id
    AND percentprogress.type = 'provider'
    AND lower(percentprogress.attr_name) = 'percentprogress'
  LEFT JOIN resource_attribute AS storageencrypted
    ON storageencrypted.resource_id = R.id
    AND storageencrypted.type = 'provider'
    AND lower(storageencrypted.attr_name) = 'storageencrypted'
  LEFT JOIN resource_attribute AS kmskeyid
    ON kmskeyid.resource_id = R.id
    AND kmskeyid.type = 'provider'
    AND lower(kmskeyid.attr_name) = 'kmskeyid'
  LEFT JOIN resource_attribute AS dbclustersnapshotarn
    ON dbclustersnapshotarn.resource_id = R.id
    AND dbclustersnapshotarn.type = 'provider'
    AND lower(dbclustersnapshotarn.attr_name) = 'dbclustersnapshotarn'
  LEFT JOIN resource_attribute AS sourcedbclustersnapshotarn
    ON sourcedbclustersnapshotarn.resource_id = R.id
    AND sourcedbclustersnapshotarn.type = 'provider'
    AND lower(sourcedbclustersnapshotarn.attr_name) = 'sourcedbclustersnapshotarn'
  LEFT JOIN resource_attribute AS iamdatabaseauthenticationenabled
    ON iamdatabaseauthenticationenabled.resource_id = R.id
    AND iamdatabaseauthenticationenabled.type = 'provider'
    AND lower(iamdatabaseauthenticationenabled.attr_name) = 'iamdatabaseauthenticationenabled'
  LEFT JOIN resource_attribute AS taglist
    ON taglist.resource_id = R.id
    AND taglist.type = 'provider'
    AND lower(taglist.attr_name) = 'taglist'
  LEFT JOIN resource_attribute AS restore
    ON restore.resource_id = R.id
    AND restore.type = 'provider'
    AND lower(restore.attr_name) = 'restore'
  LEFT JOIN resource_attribute AS _tags
    ON _tags.resource_id = R.id
    AND _tags.type = 'Metadata'
    AND lower(_tags.attr_name) = 'tags'
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
      _aws_kms_key_relation.relation = 'encrypted-with'
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
      _aws_rds_dbcluster_relation.resource_id AS resource_id,
      _aws_rds_dbcluster.id AS target_id
    FROM
      resource_relation AS _aws_rds_dbcluster_relation
      INNER JOIN resource AS _aws_rds_dbcluster
        ON _aws_rds_dbcluster_relation.target_id = _aws_rds_dbcluster.id
        AND _aws_rds_dbcluster.provider_type = 'DBCluster'
        AND _aws_rds_dbcluster.service = 'rds'
    WHERE
      _aws_rds_dbcluster_relation.relation = 'imaged'
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
  AND R.provider_type = 'DBClusterSnapshot'
  AND R.service = 'rds'
ON CONFLICT (_id) DO UPDATE
SET
    availabilityzones = EXCLUDED.availabilityzones,
    dbclustersnapshotidentifier = EXCLUDED.dbclustersnapshotidentifier,
    dbclusteridentifier = EXCLUDED.dbclusteridentifier,
    snapshotcreatetime = EXCLUDED.snapshotcreatetime,
    engine = EXCLUDED.engine,
    allocatedstorage = EXCLUDED.allocatedstorage,
    status = EXCLUDED.status,
    port = EXCLUDED.port,
    vpcid = EXCLUDED.vpcid,
    clustercreatetime = EXCLUDED.clustercreatetime,
    masterusername = EXCLUDED.masterusername,
    engineversion = EXCLUDED.engineversion,
    licensemodel = EXCLUDED.licensemodel,
    snapshottype = EXCLUDED.snapshottype,
    percentprogress = EXCLUDED.percentprogress,
    storageencrypted = EXCLUDED.storageencrypted,
    kmskeyid = EXCLUDED.kmskeyid,
    dbclustersnapshotarn = EXCLUDED.dbclustersnapshotarn,
    sourcedbclustersnapshotarn = EXCLUDED.sourcedbclustersnapshotarn,
    iamdatabaseauthenticationenabled = EXCLUDED.iamdatabaseauthenticationenabled,
    taglist = EXCLUDED.taglist,
    restore = EXCLUDED.restore,
    _tags = EXCLUDED._tags,
    _kms_key_id = EXCLUDED._kms_key_id,
    _ec2_vpc_id = EXCLUDED._ec2_vpc_id,
    _dbcluster_id = EXCLUDED._dbcluster_id,
    _account_id = EXCLUDED._account_id
  ;

INSERT INTO aws_rds_dbsnapshot (
  _id,
  uri,
  provider_account_id,
  dbsnapshotidentifier,
  dbinstanceidentifier,
  snapshotcreatetime,
  engine,
  allocatedstorage,
  status,
  port,
  availabilityzone,
  vpcid,
  instancecreatetime,
  masterusername,
  engineversion,
  licensemodel,
  snapshottype,
  iops,
  optiongroupname,
  percentprogress,
  sourceregion,
  sourcedbsnapshotidentifier,
  storagetype,
  tdecredentialarn,
  encrypted,
  kmskeyid,
  dbsnapshotarn,
  timezone,
  iamdatabaseauthenticationenabled,
  processorfeatures,
  dbiresourceid,
  taglist,
  restore,
  _tags,
  _kms_key_id,_ec2_vpc_id,_dbinstance_id,_account_id
)
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  dbsnapshotidentifier.attr_value #>> '{}' AS dbsnapshotidentifier,
  dbinstanceidentifier.attr_value #>> '{}' AS dbinstanceidentifier,
  (TO_TIMESTAMP(snapshotcreatetime.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS snapshotcreatetime,
  engine.attr_value #>> '{}' AS engine,
  (allocatedstorage.attr_value #>> '{}')::integer AS allocatedstorage,
  status.attr_value #>> '{}' AS status,
  (port.attr_value #>> '{}')::integer AS port,
  availabilityzone.attr_value #>> '{}' AS availabilityzone,
  vpcid.attr_value #>> '{}' AS vpcid,
  (TO_TIMESTAMP(instancecreatetime.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS instancecreatetime,
  masterusername.attr_value #>> '{}' AS masterusername,
  engineversion.attr_value #>> '{}' AS engineversion,
  licensemodel.attr_value #>> '{}' AS licensemodel,
  snapshottype.attr_value #>> '{}' AS snapshottype,
  (iops.attr_value #>> '{}')::integer AS iops,
  optiongroupname.attr_value #>> '{}' AS optiongroupname,
  (percentprogress.attr_value #>> '{}')::integer AS percentprogress,
  sourceregion.attr_value #>> '{}' AS sourceregion,
  sourcedbsnapshotidentifier.attr_value #>> '{}' AS sourcedbsnapshotidentifier,
  storagetype.attr_value #>> '{}' AS storagetype,
  tdecredentialarn.attr_value #>> '{}' AS tdecredentialarn,
  (encrypted.attr_value #>> '{}')::boolean AS encrypted,
  kmskeyid.attr_value #>> '{}' AS kmskeyid,
  dbsnapshotarn.attr_value #>> '{}' AS dbsnapshotarn,
  timezone.attr_value #>> '{}' AS timezone,
  (iamdatabaseauthenticationenabled.attr_value #>> '{}')::boolean AS iamdatabaseauthenticationenabled,
  processorfeatures.attr_value::jsonb AS processorfeatures,
  dbiresourceid.attr_value #>> '{}' AS dbiresourceid,
  taglist.attr_value::jsonb AS taglist,
  restore.attr_value::jsonb AS restore,
  _tags.attr_value::jsonb AS _tags,
  
    _kms_key_id.target_id AS _kms_key_id,
    _ec2_vpc_id.target_id AS _ec2_vpc_id,
    _dbinstance_id.target_id AS _dbinstance_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN resource_attribute AS dbsnapshotidentifier
    ON dbsnapshotidentifier.resource_id = R.id
    AND dbsnapshotidentifier.type = 'provider'
    AND lower(dbsnapshotidentifier.attr_name) = 'dbsnapshotidentifier'
    AND dbsnapshotidentifier.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS dbinstanceidentifier
    ON dbinstanceidentifier.resource_id = R.id
    AND dbinstanceidentifier.type = 'provider'
    AND lower(dbinstanceidentifier.attr_name) = 'dbinstanceidentifier'
    AND dbinstanceidentifier.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS snapshotcreatetime
    ON snapshotcreatetime.resource_id = R.id
    AND snapshotcreatetime.type = 'provider'
    AND lower(snapshotcreatetime.attr_name) = 'snapshotcreatetime'
    AND snapshotcreatetime.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS engine
    ON engine.resource_id = R.id
    AND engine.type = 'provider'
    AND lower(engine.attr_name) = 'engine'
    AND engine.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS allocatedstorage
    ON allocatedstorage.resource_id = R.id
    AND allocatedstorage.type = 'provider'
    AND lower(allocatedstorage.attr_name) = 'allocatedstorage'
    AND allocatedstorage.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS status
    ON status.resource_id = R.id
    AND status.type = 'provider'
    AND lower(status.attr_name) = 'status'
    AND status.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS port
    ON port.resource_id = R.id
    AND port.type = 'provider'
    AND lower(port.attr_name) = 'port'
    AND port.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS availabilityzone
    ON availabilityzone.resource_id = R.id
    AND availabilityzone.type = 'provider'
    AND lower(availabilityzone.attr_name) = 'availabilityzone'
    AND availabilityzone.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS vpcid
    ON vpcid.resource_id = R.id
    AND vpcid.type = 'provider'
    AND lower(vpcid.attr_name) = 'vpcid'
    AND vpcid.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS instancecreatetime
    ON instancecreatetime.resource_id = R.id
    AND instancecreatetime.type = 'provider'
    AND lower(instancecreatetime.attr_name) = 'instancecreatetime'
    AND instancecreatetime.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS masterusername
    ON masterusername.resource_id = R.id
    AND masterusername.type = 'provider'
    AND lower(masterusername.attr_name) = 'masterusername'
    AND masterusername.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS engineversion
    ON engineversion.resource_id = R.id
    AND engineversion.type = 'provider'
    AND lower(engineversion.attr_name) = 'engineversion'
    AND engineversion.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS licensemodel
    ON licensemodel.resource_id = R.id
    AND licensemodel.type = 'provider'
    AND lower(licensemodel.attr_name) = 'licensemodel'
    AND licensemodel.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS snapshottype
    ON snapshottype.resource_id = R.id
    AND snapshottype.type = 'provider'
    AND lower(snapshottype.attr_name) = 'snapshottype'
    AND snapshottype.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS iops
    ON iops.resource_id = R.id
    AND iops.type = 'provider'
    AND lower(iops.attr_name) = 'iops'
    AND iops.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS optiongroupname
    ON optiongroupname.resource_id = R.id
    AND optiongroupname.type = 'provider'
    AND lower(optiongroupname.attr_name) = 'optiongroupname'
    AND optiongroupname.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS percentprogress
    ON percentprogress.resource_id = R.id
    AND percentprogress.type = 'provider'
    AND lower(percentprogress.attr_name) = 'percentprogress'
    AND percentprogress.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS sourceregion
    ON sourceregion.resource_id = R.id
    AND sourceregion.type = 'provider'
    AND lower(sourceregion.attr_name) = 'sourceregion'
    AND sourceregion.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS sourcedbsnapshotidentifier
    ON sourcedbsnapshotidentifier.resource_id = R.id
    AND sourcedbsnapshotidentifier.type = 'provider'
    AND lower(sourcedbsnapshotidentifier.attr_name) = 'sourcedbsnapshotidentifier'
    AND sourcedbsnapshotidentifier.provider_account_id = R.provider_account_id
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
  LEFT JOIN resource_attribute AS encrypted
    ON encrypted.resource_id = R.id
    AND encrypted.type = 'provider'
    AND lower(encrypted.attr_name) = 'encrypted'
    AND encrypted.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS kmskeyid
    ON kmskeyid.resource_id = R.id
    AND kmskeyid.type = 'provider'
    AND lower(kmskeyid.attr_name) = 'kmskeyid'
    AND kmskeyid.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS dbsnapshotarn
    ON dbsnapshotarn.resource_id = R.id
    AND dbsnapshotarn.type = 'provider'
    AND lower(dbsnapshotarn.attr_name) = 'dbsnapshotarn'
    AND dbsnapshotarn.provider_account_id = R.provider_account_id
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
  LEFT JOIN resource_attribute AS processorfeatures
    ON processorfeatures.resource_id = R.id
    AND processorfeatures.type = 'provider'
    AND lower(processorfeatures.attr_name) = 'processorfeatures'
    AND processorfeatures.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS dbiresourceid
    ON dbiresourceid.resource_id = R.id
    AND dbiresourceid.type = 'provider'
    AND lower(dbiresourceid.attr_name) = 'dbiresourceid'
    AND dbiresourceid.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS taglist
    ON taglist.resource_id = R.id
    AND taglist.type = 'provider'
    AND lower(taglist.attr_name) = 'taglist'
    AND taglist.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS restore
    ON restore.resource_id = R.id
    AND restore.type = 'provider'
    AND lower(restore.attr_name) = 'restore'
    AND restore.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS _tags
    ON _tags.resource_id = R.id
    AND _tags.type = 'Metadata'
    AND lower(_tags.attr_name) = 'tags'
    AND _tags.provider_account_id = R.provider_account_id
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
      _aws_kms_key_relation.relation = 'encrypted-with'
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
      _aws_rds_dbinstance_relation.resource_id AS resource_id,
      _aws_rds_dbinstance.id AS target_id
    FROM
      resource_relation AS _aws_rds_dbinstance_relation
      INNER JOIN resource AS _aws_rds_dbinstance
        ON _aws_rds_dbinstance_relation.target_id = _aws_rds_dbinstance.id
        AND _aws_rds_dbinstance.provider_type = 'DBInstance'
        AND _aws_rds_dbinstance.service = 'rds'
        AND _aws_rds_dbinstance.provider_account_id = :provider_account_id
    WHERE
      _aws_rds_dbinstance_relation.relation = 'imaged'
      AND _aws_rds_dbinstance_relation.provider_account_id = :provider_account_id
  ) AS _dbinstance_id ON _dbinstance_id.resource_id = R.id
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
  AND R.provider_type = 'DBSnapshot'
  AND R.service = 'rds'
ON CONFLICT (_id) DO UPDATE
SET
    dbsnapshotidentifier = EXCLUDED.dbsnapshotidentifier,
    dbinstanceidentifier = EXCLUDED.dbinstanceidentifier,
    snapshotcreatetime = EXCLUDED.snapshotcreatetime,
    engine = EXCLUDED.engine,
    allocatedstorage = EXCLUDED.allocatedstorage,
    status = EXCLUDED.status,
    port = EXCLUDED.port,
    availabilityzone = EXCLUDED.availabilityzone,
    vpcid = EXCLUDED.vpcid,
    instancecreatetime = EXCLUDED.instancecreatetime,
    masterusername = EXCLUDED.masterusername,
    engineversion = EXCLUDED.engineversion,
    licensemodel = EXCLUDED.licensemodel,
    snapshottype = EXCLUDED.snapshottype,
    iops = EXCLUDED.iops,
    optiongroupname = EXCLUDED.optiongroupname,
    percentprogress = EXCLUDED.percentprogress,
    sourceregion = EXCLUDED.sourceregion,
    sourcedbsnapshotidentifier = EXCLUDED.sourcedbsnapshotidentifier,
    storagetype = EXCLUDED.storagetype,
    tdecredentialarn = EXCLUDED.tdecredentialarn,
    encrypted = EXCLUDED.encrypted,
    kmskeyid = EXCLUDED.kmskeyid,
    dbsnapshotarn = EXCLUDED.dbsnapshotarn,
    timezone = EXCLUDED.timezone,
    iamdatabaseauthenticationenabled = EXCLUDED.iamdatabaseauthenticationenabled,
    processorfeatures = EXCLUDED.processorfeatures,
    dbiresourceid = EXCLUDED.dbiresourceid,
    taglist = EXCLUDED.taglist,
    restore = EXCLUDED.restore,
    _tags = EXCLUDED._tags,
    _kms_key_id = EXCLUDED._kms_key_id,
    _ec2_vpc_id = EXCLUDED._ec2_vpc_id,
    _dbinstance_id = EXCLUDED._dbinstance_id,
    _account_id = EXCLUDED._account_id
  ;


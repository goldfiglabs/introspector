DROP MATERIALIZED VIEW IF EXISTS aws_rds_dbsnapshot CASCADE;

CREATE MATERIALIZED VIEW aws_rds_dbsnapshot AS
SELECT
  R.id AS resource_id,
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
  LEFT JOIN resource_attribute AS dbinstanceidentifier
    ON dbinstanceidentifier.resource_id = R.id
    AND dbinstanceidentifier.type = 'provider'
    AND lower(dbinstanceidentifier.attr_name) = 'dbinstanceidentifier'
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
  LEFT JOIN resource_attribute AS availabilityzone
    ON availabilityzone.resource_id = R.id
    AND availabilityzone.type = 'provider'
    AND lower(availabilityzone.attr_name) = 'availabilityzone'
  LEFT JOIN resource_attribute AS vpcid
    ON vpcid.resource_id = R.id
    AND vpcid.type = 'provider'
    AND lower(vpcid.attr_name) = 'vpcid'
  LEFT JOIN resource_attribute AS instancecreatetime
    ON instancecreatetime.resource_id = R.id
    AND instancecreatetime.type = 'provider'
    AND lower(instancecreatetime.attr_name) = 'instancecreatetime'
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
  LEFT JOIN resource_attribute AS iops
    ON iops.resource_id = R.id
    AND iops.type = 'provider'
    AND lower(iops.attr_name) = 'iops'
  LEFT JOIN resource_attribute AS optiongroupname
    ON optiongroupname.resource_id = R.id
    AND optiongroupname.type = 'provider'
    AND lower(optiongroupname.attr_name) = 'optiongroupname'
  LEFT JOIN resource_attribute AS percentprogress
    ON percentprogress.resource_id = R.id
    AND percentprogress.type = 'provider'
    AND lower(percentprogress.attr_name) = 'percentprogress'
  LEFT JOIN resource_attribute AS sourceregion
    ON sourceregion.resource_id = R.id
    AND sourceregion.type = 'provider'
    AND lower(sourceregion.attr_name) = 'sourceregion'
  LEFT JOIN resource_attribute AS sourcedbsnapshotidentifier
    ON sourcedbsnapshotidentifier.resource_id = R.id
    AND sourcedbsnapshotidentifier.type = 'provider'
    AND lower(sourcedbsnapshotidentifier.attr_name) = 'sourcedbsnapshotidentifier'
  LEFT JOIN resource_attribute AS storagetype
    ON storagetype.resource_id = R.id
    AND storagetype.type = 'provider'
    AND lower(storagetype.attr_name) = 'storagetype'
  LEFT JOIN resource_attribute AS tdecredentialarn
    ON tdecredentialarn.resource_id = R.id
    AND tdecredentialarn.type = 'provider'
    AND lower(tdecredentialarn.attr_name) = 'tdecredentialarn'
  LEFT JOIN resource_attribute AS encrypted
    ON encrypted.resource_id = R.id
    AND encrypted.type = 'provider'
    AND lower(encrypted.attr_name) = 'encrypted'
  LEFT JOIN resource_attribute AS kmskeyid
    ON kmskeyid.resource_id = R.id
    AND kmskeyid.type = 'provider'
    AND lower(kmskeyid.attr_name) = 'kmskeyid'
  LEFT JOIN resource_attribute AS dbsnapshotarn
    ON dbsnapshotarn.resource_id = R.id
    AND dbsnapshotarn.type = 'provider'
    AND lower(dbsnapshotarn.attr_name) = 'dbsnapshotarn'
  LEFT JOIN resource_attribute AS timezone
    ON timezone.resource_id = R.id
    AND timezone.type = 'provider'
    AND lower(timezone.attr_name) = 'timezone'
  LEFT JOIN resource_attribute AS iamdatabaseauthenticationenabled
    ON iamdatabaseauthenticationenabled.resource_id = R.id
    AND iamdatabaseauthenticationenabled.type = 'provider'
    AND lower(iamdatabaseauthenticationenabled.attr_name) = 'iamdatabaseauthenticationenabled'
  LEFT JOIN resource_attribute AS processorfeatures
    ON processorfeatures.resource_id = R.id
    AND processorfeatures.type = 'provider'
    AND lower(processorfeatures.attr_name) = 'processorfeatures'
  LEFT JOIN resource_attribute AS dbiresourceid
    ON dbiresourceid.resource_id = R.id
    AND dbiresourceid.type = 'provider'
    AND lower(dbiresourceid.attr_name) = 'dbiresourceid'
  LEFT JOIN resource_attribute AS taglist
    ON taglist.resource_id = R.id
    AND taglist.type = 'provider'
    AND lower(taglist.attr_name) = 'taglist'
  LEFT JOIN resource_attribute AS restore
    ON restore.resource_id = R.id
    AND restore.type = 'provider'
    AND lower(restore.attr_name) = 'restore'
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
      _aws_rds_dbinstance_relation.resource_id AS resource_id,
      _aws_rds_dbinstance.id AS target_id
    FROM
      resource_relation AS _aws_rds_dbinstance_relation
      INNER JOIN resource AS _aws_rds_dbinstance
        ON _aws_rds_dbinstance_relation.target_id = _aws_rds_dbinstance.id
        AND _aws_rds_dbinstance.provider_type = 'DBInstance'
        AND _aws_rds_dbinstance.service = 'rds'
    WHERE
      _aws_rds_dbinstance_relation.relation = 'imaged'
  ) AS _dbinstance_id ON _dbinstance_id.resource_id = R.id
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
  AND R.provider_type = 'DBSnapshot'
  AND R.service = 'rds'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_rds_dbsnapshot;

COMMENT ON MATERIALIZED VIEW aws_rds_dbsnapshot IS 'rds DBSnapshot resources and their associated attributes.';


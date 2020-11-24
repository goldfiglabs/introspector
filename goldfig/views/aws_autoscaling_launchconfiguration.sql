DROP MATERIALIZED VIEW IF EXISTS aws_autoscaling_launchconfiguration CASCADE;

CREATE MATERIALIZED VIEW aws_autoscaling_launchconfiguration AS
SELECT
  R.id AS resource_id,
  R.uri,
  R.provider_account_id,
  launchconfigurationname.attr_value #>> '{}' AS launchconfigurationname,
  launchconfigurationarn.attr_value #>> '{}' AS launchconfigurationarn,
  imageid.attr_value #>> '{}' AS imageid,
  keyname.attr_value #>> '{}' AS keyname,
  securitygroups.attr_value::jsonb AS securitygroups,
  classiclinkvpcid.attr_value #>> '{}' AS classiclinkvpcid,
  classiclinkvpcsecuritygroups.attr_value::jsonb AS classiclinkvpcsecuritygroups,
  userdata.attr_value #>> '{}' AS userdata,
  instancetype.attr_value #>> '{}' AS instancetype,
  kernelid.attr_value #>> '{}' AS kernelid,
  ramdiskid.attr_value #>> '{}' AS ramdiskid,
  blockdevicemappings.attr_value::jsonb AS blockdevicemappings,
  instancemonitoring.attr_value::jsonb AS instancemonitoring,
  spotprice.attr_value #>> '{}' AS spotprice,
  iaminstanceprofile.attr_value #>> '{}' AS iaminstanceprofile,
  (TO_TIMESTAMP(createdtime.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS createdtime,
  (ebsoptimized.attr_value #>> '{}')::boolean AS ebsoptimized,
  (associatepublicipaddress.attr_value #>> '{}')::boolean AS associatepublicipaddress,
  placementtenancy.attr_value #>> '{}' AS placementtenancy,
  
    _ec2_image_id.target_id AS _ec2_image_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN resource_attribute AS launchconfigurationname
    ON launchconfigurationname.resource_id = R.id
    AND launchconfigurationname.type = 'provider'
    AND lower(launchconfigurationname.attr_name) = 'launchconfigurationname'
  LEFT JOIN resource_attribute AS launchconfigurationarn
    ON launchconfigurationarn.resource_id = R.id
    AND launchconfigurationarn.type = 'provider'
    AND lower(launchconfigurationarn.attr_name) = 'launchconfigurationarn'
  LEFT JOIN resource_attribute AS imageid
    ON imageid.resource_id = R.id
    AND imageid.type = 'provider'
    AND lower(imageid.attr_name) = 'imageid'
  LEFT JOIN resource_attribute AS keyname
    ON keyname.resource_id = R.id
    AND keyname.type = 'provider'
    AND lower(keyname.attr_name) = 'keyname'
  LEFT JOIN resource_attribute AS securitygroups
    ON securitygroups.resource_id = R.id
    AND securitygroups.type = 'provider'
    AND lower(securitygroups.attr_name) = 'securitygroups'
  LEFT JOIN resource_attribute AS classiclinkvpcid
    ON classiclinkvpcid.resource_id = R.id
    AND classiclinkvpcid.type = 'provider'
    AND lower(classiclinkvpcid.attr_name) = 'classiclinkvpcid'
  LEFT JOIN resource_attribute AS classiclinkvpcsecuritygroups
    ON classiclinkvpcsecuritygroups.resource_id = R.id
    AND classiclinkvpcsecuritygroups.type = 'provider'
    AND lower(classiclinkvpcsecuritygroups.attr_name) = 'classiclinkvpcsecuritygroups'
  LEFT JOIN resource_attribute AS userdata
    ON userdata.resource_id = R.id
    AND userdata.type = 'provider'
    AND lower(userdata.attr_name) = 'userdata'
  LEFT JOIN resource_attribute AS instancetype
    ON instancetype.resource_id = R.id
    AND instancetype.type = 'provider'
    AND lower(instancetype.attr_name) = 'instancetype'
  LEFT JOIN resource_attribute AS kernelid
    ON kernelid.resource_id = R.id
    AND kernelid.type = 'provider'
    AND lower(kernelid.attr_name) = 'kernelid'
  LEFT JOIN resource_attribute AS ramdiskid
    ON ramdiskid.resource_id = R.id
    AND ramdiskid.type = 'provider'
    AND lower(ramdiskid.attr_name) = 'ramdiskid'
  LEFT JOIN resource_attribute AS blockdevicemappings
    ON blockdevicemappings.resource_id = R.id
    AND blockdevicemappings.type = 'provider'
    AND lower(blockdevicemappings.attr_name) = 'blockdevicemappings'
  LEFT JOIN resource_attribute AS instancemonitoring
    ON instancemonitoring.resource_id = R.id
    AND instancemonitoring.type = 'provider'
    AND lower(instancemonitoring.attr_name) = 'instancemonitoring'
  LEFT JOIN resource_attribute AS spotprice
    ON spotprice.resource_id = R.id
    AND spotprice.type = 'provider'
    AND lower(spotprice.attr_name) = 'spotprice'
  LEFT JOIN resource_attribute AS iaminstanceprofile
    ON iaminstanceprofile.resource_id = R.id
    AND iaminstanceprofile.type = 'provider'
    AND lower(iaminstanceprofile.attr_name) = 'iaminstanceprofile'
  LEFT JOIN resource_attribute AS createdtime
    ON createdtime.resource_id = R.id
    AND createdtime.type = 'provider'
    AND lower(createdtime.attr_name) = 'createdtime'
  LEFT JOIN resource_attribute AS ebsoptimized
    ON ebsoptimized.resource_id = R.id
    AND ebsoptimized.type = 'provider'
    AND lower(ebsoptimized.attr_name) = 'ebsoptimized'
  LEFT JOIN resource_attribute AS associatepublicipaddress
    ON associatepublicipaddress.resource_id = R.id
    AND associatepublicipaddress.type = 'provider'
    AND lower(associatepublicipaddress.attr_name) = 'associatepublicipaddress'
  LEFT JOIN resource_attribute AS placementtenancy
    ON placementtenancy.resource_id = R.id
    AND placementtenancy.type = 'provider'
    AND lower(placementtenancy.attr_name) = 'placementtenancy'
  LEFT JOIN (
    SELECT
      _aws_ec2_image_relation.resource_id AS resource_id,
      _aws_ec2_image.id AS target_id
    FROM
      resource_relation AS _aws_ec2_image_relation
      INNER JOIN resource AS _aws_ec2_image
        ON _aws_ec2_image_relation.target_id = _aws_ec2_image.id
        AND _aws_ec2_image.provider_type = 'Image'
        AND _aws_ec2_image.service = 'ec2'
    WHERE
      _aws_ec2_image_relation.relation = 'imaged'
  ) AS _ec2_image_id ON _ec2_image_id.resource_id = R.id
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
  AND R.provider_type = 'LaunchConfiguration'
  AND R.service = 'autoscaling'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_autoscaling_launchconfiguration;

COMMENT ON MATERIALIZED VIEW aws_autoscaling_launchconfiguration IS 'autoscaling LaunchConfiguration resources and their associated attributes.';



DROP MATERIALIZED VIEW IF EXISTS aws_autoscaling_launchconfiguration_ec2_securitygroup CASCADE;

CREATE MATERIALIZED VIEW aws_autoscaling_launchconfiguration_ec2_securitygroup AS
SELECT
  aws_autoscaling_launchconfiguration.id AS launchconfiguration_id,
  aws_ec2_securitygroup.id AS securitygroup_id
FROM
  resource AS aws_autoscaling_launchconfiguration
  INNER JOIN resource_relation AS RR
    ON RR.resource_id = aws_autoscaling_launchconfiguration.id
    AND RR.relation = 'launches-into'
  INNER JOIN resource AS aws_ec2_securitygroup
    ON aws_ec2_securitygroup.id = RR.target_id
    AND aws_ec2_securitygroup.provider_type = 'SecurityGroup'
    AND aws_ec2_securitygroup.service = 'ec2'
  WHERE
    aws_autoscaling_launchconfiguration.provider_type = 'LaunchConfiguration'
    AND aws_autoscaling_launchconfiguration.service = 'autoscaling'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_autoscaling_launchconfiguration_ec2_securitygroup;

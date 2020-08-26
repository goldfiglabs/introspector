DROP MATERIALIZED VIEW IF EXISTS aws_ec2_instance CASCADE;

CREATE MATERIALIZED VIEW aws_ec2_instance AS
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
  (amilaunchindex.attr_value #>> '{}')::integer AS amilaunchindex,
  imageid.attr_value #>> '{}' AS imageid,
  instanceid.attr_value #>> '{}' AS instanceid,
  instancetype.attr_value #>> '{}' AS instancetype,
  kernelid.attr_value #>> '{}' AS kernelid,
  keyname.attr_value #>> '{}' AS keyname,
  (TO_TIMESTAMP(launchtime.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS launchtime,
  monitoring.attr_value::jsonb AS monitoring,
  placement.attr_value::jsonb AS placement,
  platform.attr_value #>> '{}' AS platform,
  privatednsname.attr_value #>> '{}' AS privatednsname,
  (privateipaddress.attr_value #>> '{}')::inet AS privateipaddress,
  productcodes.attr_value::jsonb AS productcodes,
  publicdnsname.attr_value #>> '{}' AS publicdnsname,
  (publicipaddress.attr_value #>> '{}')::inet AS publicipaddress,
  ramdiskid.attr_value #>> '{}' AS ramdiskid,
  state.attr_value::jsonb AS state,
  statetransitionreason.attr_value #>> '{}' AS statetransitionreason,
  subnetid.attr_value #>> '{}' AS subnetid,
  vpcid.attr_value #>> '{}' AS vpcid,
  architecture.attr_value #>> '{}' AS architecture,
  blockdevicemappings.attr_value::jsonb AS blockdevicemappings,
  clienttoken.attr_value #>> '{}' AS clienttoken,
  (ebsoptimized.attr_value #>> '{}')::boolean AS ebsoptimized,
  (enasupport.attr_value #>> '{}')::boolean AS enasupport,
  hypervisor.attr_value #>> '{}' AS hypervisor,
  iaminstanceprofile.attr_value::jsonb AS iaminstanceprofile,
  instancelifecycle.attr_value #>> '{}' AS instancelifecycle,
  elasticgpuassociations.attr_value::jsonb AS elasticgpuassociations,
  elasticinferenceacceleratorassociations.attr_value::jsonb AS elasticinferenceacceleratorassociations,
  networkinterfaces.attr_value::jsonb AS networkinterfaces,
  outpostarn.attr_value #>> '{}' AS outpostarn,
  rootdevicename.attr_value #>> '{}' AS rootdevicename,
  rootdevicetype.attr_value #>> '{}' AS rootdevicetype,
  securitygroups.attr_value::jsonb AS securitygroups,
  (sourcedestcheck.attr_value #>> '{}')::boolean AS sourcedestcheck,
  spotinstancerequestid.attr_value #>> '{}' AS spotinstancerequestid,
  sriovnetsupport.attr_value #>> '{}' AS sriovnetsupport,
  statereason.attr_value::jsonb AS statereason,
  tags.attr_value::jsonb AS tags,
  virtualizationtype.attr_value #>> '{}' AS virtualizationtype,
  cpuoptions.attr_value::jsonb AS cpuoptions,
  capacityreservationid.attr_value #>> '{}' AS capacityreservationid,
  capacityreservationspecification.attr_value::jsonb AS capacityreservationspecification,
  hibernationoptions.attr_value::jsonb AS hibernationoptions,
  licenses.attr_value::jsonb AS licenses,
  metadataoptions.attr_value::jsonb AS metadataoptions,
  
    _image_id.target_id AS _image_id,
    _iam_instanceprofile_id.target_id AS _iam_instanceprofile_id,
    _vpc_id.target_id AS _vpc_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN attrs AS amilaunchindex
    ON amilaunchindex.id = R.id
    AND amilaunchindex.attr_name = 'amilaunchindex'
  LEFT JOIN attrs AS imageid
    ON imageid.id = R.id
    AND imageid.attr_name = 'imageid'
  LEFT JOIN attrs AS instanceid
    ON instanceid.id = R.id
    AND instanceid.attr_name = 'instanceid'
  LEFT JOIN attrs AS instancetype
    ON instancetype.id = R.id
    AND instancetype.attr_name = 'instancetype'
  LEFT JOIN attrs AS kernelid
    ON kernelid.id = R.id
    AND kernelid.attr_name = 'kernelid'
  LEFT JOIN attrs AS keyname
    ON keyname.id = R.id
    AND keyname.attr_name = 'keyname'
  LEFT JOIN attrs AS launchtime
    ON launchtime.id = R.id
    AND launchtime.attr_name = 'launchtime'
  LEFT JOIN attrs AS monitoring
    ON monitoring.id = R.id
    AND monitoring.attr_name = 'monitoring'
  LEFT JOIN attrs AS placement
    ON placement.id = R.id
    AND placement.attr_name = 'placement'
  LEFT JOIN attrs AS platform
    ON platform.id = R.id
    AND platform.attr_name = 'platform'
  LEFT JOIN attrs AS privatednsname
    ON privatednsname.id = R.id
    AND privatednsname.attr_name = 'privatednsname'
  LEFT JOIN attrs AS privateipaddress
    ON privateipaddress.id = R.id
    AND privateipaddress.attr_name = 'privateipaddress'
  LEFT JOIN attrs AS productcodes
    ON productcodes.id = R.id
    AND productcodes.attr_name = 'productcodes'
  LEFT JOIN attrs AS publicdnsname
    ON publicdnsname.id = R.id
    AND publicdnsname.attr_name = 'publicdnsname'
  LEFT JOIN attrs AS publicipaddress
    ON publicipaddress.id = R.id
    AND publicipaddress.attr_name = 'publicipaddress'
  LEFT JOIN attrs AS ramdiskid
    ON ramdiskid.id = R.id
    AND ramdiskid.attr_name = 'ramdiskid'
  LEFT JOIN attrs AS state
    ON state.id = R.id
    AND state.attr_name = 'state'
  LEFT JOIN attrs AS statetransitionreason
    ON statetransitionreason.id = R.id
    AND statetransitionreason.attr_name = 'statetransitionreason'
  LEFT JOIN attrs AS subnetid
    ON subnetid.id = R.id
    AND subnetid.attr_name = 'subnetid'
  LEFT JOIN attrs AS vpcid
    ON vpcid.id = R.id
    AND vpcid.attr_name = 'vpcid'
  LEFT JOIN attrs AS architecture
    ON architecture.id = R.id
    AND architecture.attr_name = 'architecture'
  LEFT JOIN attrs AS blockdevicemappings
    ON blockdevicemappings.id = R.id
    AND blockdevicemappings.attr_name = 'blockdevicemappings'
  LEFT JOIN attrs AS clienttoken
    ON clienttoken.id = R.id
    AND clienttoken.attr_name = 'clienttoken'
  LEFT JOIN attrs AS ebsoptimized
    ON ebsoptimized.id = R.id
    AND ebsoptimized.attr_name = 'ebsoptimized'
  LEFT JOIN attrs AS enasupport
    ON enasupport.id = R.id
    AND enasupport.attr_name = 'enasupport'
  LEFT JOIN attrs AS hypervisor
    ON hypervisor.id = R.id
    AND hypervisor.attr_name = 'hypervisor'
  LEFT JOIN attrs AS iaminstanceprofile
    ON iaminstanceprofile.id = R.id
    AND iaminstanceprofile.attr_name = 'iaminstanceprofile'
  LEFT JOIN attrs AS instancelifecycle
    ON instancelifecycle.id = R.id
    AND instancelifecycle.attr_name = 'instancelifecycle'
  LEFT JOIN attrs AS elasticgpuassociations
    ON elasticgpuassociations.id = R.id
    AND elasticgpuassociations.attr_name = 'elasticgpuassociations'
  LEFT JOIN attrs AS elasticinferenceacceleratorassociations
    ON elasticinferenceacceleratorassociations.id = R.id
    AND elasticinferenceacceleratorassociations.attr_name = 'elasticinferenceacceleratorassociations'
  LEFT JOIN attrs AS networkinterfaces
    ON networkinterfaces.id = R.id
    AND networkinterfaces.attr_name = 'networkinterfaces'
  LEFT JOIN attrs AS outpostarn
    ON outpostarn.id = R.id
    AND outpostarn.attr_name = 'outpostarn'
  LEFT JOIN attrs AS rootdevicename
    ON rootdevicename.id = R.id
    AND rootdevicename.attr_name = 'rootdevicename'
  LEFT JOIN attrs AS rootdevicetype
    ON rootdevicetype.id = R.id
    AND rootdevicetype.attr_name = 'rootdevicetype'
  LEFT JOIN attrs AS securitygroups
    ON securitygroups.id = R.id
    AND securitygroups.attr_name = 'securitygroups'
  LEFT JOIN attrs AS sourcedestcheck
    ON sourcedestcheck.id = R.id
    AND sourcedestcheck.attr_name = 'sourcedestcheck'
  LEFT JOIN attrs AS spotinstancerequestid
    ON spotinstancerequestid.id = R.id
    AND spotinstancerequestid.attr_name = 'spotinstancerequestid'
  LEFT JOIN attrs AS sriovnetsupport
    ON sriovnetsupport.id = R.id
    AND sriovnetsupport.attr_name = 'sriovnetsupport'
  LEFT JOIN attrs AS statereason
    ON statereason.id = R.id
    AND statereason.attr_name = 'statereason'
  LEFT JOIN attrs AS tags
    ON tags.id = R.id
    AND tags.attr_name = 'tags'
  LEFT JOIN attrs AS virtualizationtype
    ON virtualizationtype.id = R.id
    AND virtualizationtype.attr_name = 'virtualizationtype'
  LEFT JOIN attrs AS cpuoptions
    ON cpuoptions.id = R.id
    AND cpuoptions.attr_name = 'cpuoptions'
  LEFT JOIN attrs AS capacityreservationid
    ON capacityreservationid.id = R.id
    AND capacityreservationid.attr_name = 'capacityreservationid'
  LEFT JOIN attrs AS capacityreservationspecification
    ON capacityreservationspecification.id = R.id
    AND capacityreservationspecification.attr_name = 'capacityreservationspecification'
  LEFT JOIN attrs AS hibernationoptions
    ON hibernationoptions.id = R.id
    AND hibernationoptions.attr_name = 'hibernationoptions'
  LEFT JOIN attrs AS licenses
    ON licenses.id = R.id
    AND licenses.attr_name = 'licenses'
  LEFT JOIN attrs AS metadataoptions
    ON metadataoptions.id = R.id
    AND metadataoptions.attr_name = 'metadataoptions'
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
  ) AS _image_id ON _image_id.resource_id = R.id
  LEFT JOIN (
    SELECT
      _aws_iam_instanceprofile_relation.resource_id AS resource_id,
      _aws_iam_instanceprofile.id AS target_id
    FROM
      resource_relation AS _aws_iam_instanceprofile_relation
      INNER JOIN resource AS _aws_iam_instanceprofile
        ON _aws_iam_instanceprofile_relation.target_id = _aws_iam_instanceprofile.id
        AND _aws_iam_instanceprofile.provider_type = 'InstanceProfile'
        AND _aws_iam_instanceprofile.service = 'iam'
    WHERE
      _aws_iam_instanceprofile_relation.relation = 'acts-as'
  ) AS _iam_instanceprofile_id ON _iam_instanceprofile_id.resource_id = R.id
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
  ) AS _vpc_id ON _vpc_id.resource_id = R.id
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
  AND LOWER(R.provider_type) = 'instance'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_ec2_instance;

COMMENT ON MATERIALIZED VIEW aws_ec2_instance IS 'ec2 instance resources and their associated attributes.';



DROP MATERIALIZED VIEW IF EXISTS aws_ec2_instance_volume CASCADE;

CREATE MATERIALIZED VIEW aws_ec2_instance_volume AS
SELECT
  aws_ec2_instance.id AS instance_id,
  aws_ec2_volume.id AS volume_id,
  (DeleteOnTermiation.value #>> '{}')::boolean AS deleteontermiation,
  (TO_TIMESTAMP(AttachTime.value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS attachtime,
  VolumeId.value #>> '{}' AS volumeid,
  Status.value #>> '{}' AS status,
  DeviceName.value #>> '{}' AS devicename
FROM
  resource AS aws_ec2_instance
  INNER JOIN resource_relation AS RR
    ON RR.resource_id = aws_ec2_instance.id
    AND RR.relation = 'attached'
  INNER JOIN resource AS aws_ec2_volume
    ON aws_ec2_volume.id = RR.target_id
    AND aws_ec2_volume.provider_type = 'Volume'
  LEFT JOIN resource_relation_attribute AS DeleteOnTermiation
    ON DeleteOnTermiation.relation_id = RR.id
    AND DeleteOnTermiation.name = 'DeleteOnTermiation'
  LEFT JOIN resource_relation_attribute AS AttachTime
    ON AttachTime.relation_id = RR.id
    AND AttachTime.name = 'AttachTime'
  LEFT JOIN resource_relation_attribute AS VolumeId
    ON VolumeId.relation_id = RR.id
    AND VolumeId.name = 'VolumeId'
  LEFT JOIN resource_relation_attribute AS Status
    ON Status.relation_id = RR.id
    AND Status.name = 'Status'
  LEFT JOIN resource_relation_attribute AS DeviceName
    ON DeviceName.relation_id = RR.id
    AND DeviceName.name = 'DeviceName'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_ec2_instance_volume;

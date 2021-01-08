INSERT INTO aws_ec2_instance
SELECT
  R.id AS _id,
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
  enclaveoptions.attr_value::jsonb AS enclaveoptions,
  userdata.attr_value #>> '{}' AS userdata,
  
    _image_id.target_id AS _image_id,
    _iam_instanceprofile_id.target_id AS _iam_instanceprofile_id,
    _vpc_id.target_id AS _vpc_id,
    _subnet_id.target_id AS _subnet_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN resource_attribute AS amilaunchindex
    ON amilaunchindex.resource_id = R.id
    AND amilaunchindex.type = 'provider'
    AND lower(amilaunchindex.attr_name) = 'amilaunchindex'
  LEFT JOIN resource_attribute AS imageid
    ON imageid.resource_id = R.id
    AND imageid.type = 'provider'
    AND lower(imageid.attr_name) = 'imageid'
  LEFT JOIN resource_attribute AS instanceid
    ON instanceid.resource_id = R.id
    AND instanceid.type = 'provider'
    AND lower(instanceid.attr_name) = 'instanceid'
  LEFT JOIN resource_attribute AS instancetype
    ON instancetype.resource_id = R.id
    AND instancetype.type = 'provider'
    AND lower(instancetype.attr_name) = 'instancetype'
  LEFT JOIN resource_attribute AS kernelid
    ON kernelid.resource_id = R.id
    AND kernelid.type = 'provider'
    AND lower(kernelid.attr_name) = 'kernelid'
  LEFT JOIN resource_attribute AS keyname
    ON keyname.resource_id = R.id
    AND keyname.type = 'provider'
    AND lower(keyname.attr_name) = 'keyname'
  LEFT JOIN resource_attribute AS launchtime
    ON launchtime.resource_id = R.id
    AND launchtime.type = 'provider'
    AND lower(launchtime.attr_name) = 'launchtime'
  LEFT JOIN resource_attribute AS monitoring
    ON monitoring.resource_id = R.id
    AND monitoring.type = 'provider'
    AND lower(monitoring.attr_name) = 'monitoring'
  LEFT JOIN resource_attribute AS placement
    ON placement.resource_id = R.id
    AND placement.type = 'provider'
    AND lower(placement.attr_name) = 'placement'
  LEFT JOIN resource_attribute AS platform
    ON platform.resource_id = R.id
    AND platform.type = 'provider'
    AND lower(platform.attr_name) = 'platform'
  LEFT JOIN resource_attribute AS privatednsname
    ON privatednsname.resource_id = R.id
    AND privatednsname.type = 'provider'
    AND lower(privatednsname.attr_name) = 'privatednsname'
  LEFT JOIN resource_attribute AS privateipaddress
    ON privateipaddress.resource_id = R.id
    AND privateipaddress.type = 'provider'
    AND lower(privateipaddress.attr_name) = 'privateipaddress'
  LEFT JOIN resource_attribute AS productcodes
    ON productcodes.resource_id = R.id
    AND productcodes.type = 'provider'
    AND lower(productcodes.attr_name) = 'productcodes'
  LEFT JOIN resource_attribute AS publicdnsname
    ON publicdnsname.resource_id = R.id
    AND publicdnsname.type = 'provider'
    AND lower(publicdnsname.attr_name) = 'publicdnsname'
  LEFT JOIN resource_attribute AS publicipaddress
    ON publicipaddress.resource_id = R.id
    AND publicipaddress.type = 'provider'
    AND lower(publicipaddress.attr_name) = 'publicipaddress'
  LEFT JOIN resource_attribute AS ramdiskid
    ON ramdiskid.resource_id = R.id
    AND ramdiskid.type = 'provider'
    AND lower(ramdiskid.attr_name) = 'ramdiskid'
  LEFT JOIN resource_attribute AS state
    ON state.resource_id = R.id
    AND state.type = 'provider'
    AND lower(state.attr_name) = 'state'
  LEFT JOIN resource_attribute AS statetransitionreason
    ON statetransitionreason.resource_id = R.id
    AND statetransitionreason.type = 'provider'
    AND lower(statetransitionreason.attr_name) = 'statetransitionreason'
  LEFT JOIN resource_attribute AS subnetid
    ON subnetid.resource_id = R.id
    AND subnetid.type = 'provider'
    AND lower(subnetid.attr_name) = 'subnetid'
  LEFT JOIN resource_attribute AS vpcid
    ON vpcid.resource_id = R.id
    AND vpcid.type = 'provider'
    AND lower(vpcid.attr_name) = 'vpcid'
  LEFT JOIN resource_attribute AS architecture
    ON architecture.resource_id = R.id
    AND architecture.type = 'provider'
    AND lower(architecture.attr_name) = 'architecture'
  LEFT JOIN resource_attribute AS blockdevicemappings
    ON blockdevicemappings.resource_id = R.id
    AND blockdevicemappings.type = 'provider'
    AND lower(blockdevicemappings.attr_name) = 'blockdevicemappings'
  LEFT JOIN resource_attribute AS clienttoken
    ON clienttoken.resource_id = R.id
    AND clienttoken.type = 'provider'
    AND lower(clienttoken.attr_name) = 'clienttoken'
  LEFT JOIN resource_attribute AS ebsoptimized
    ON ebsoptimized.resource_id = R.id
    AND ebsoptimized.type = 'provider'
    AND lower(ebsoptimized.attr_name) = 'ebsoptimized'
  LEFT JOIN resource_attribute AS enasupport
    ON enasupport.resource_id = R.id
    AND enasupport.type = 'provider'
    AND lower(enasupport.attr_name) = 'enasupport'
  LEFT JOIN resource_attribute AS hypervisor
    ON hypervisor.resource_id = R.id
    AND hypervisor.type = 'provider'
    AND lower(hypervisor.attr_name) = 'hypervisor'
  LEFT JOIN resource_attribute AS iaminstanceprofile
    ON iaminstanceprofile.resource_id = R.id
    AND iaminstanceprofile.type = 'provider'
    AND lower(iaminstanceprofile.attr_name) = 'iaminstanceprofile'
  LEFT JOIN resource_attribute AS instancelifecycle
    ON instancelifecycle.resource_id = R.id
    AND instancelifecycle.type = 'provider'
    AND lower(instancelifecycle.attr_name) = 'instancelifecycle'
  LEFT JOIN resource_attribute AS elasticgpuassociations
    ON elasticgpuassociations.resource_id = R.id
    AND elasticgpuassociations.type = 'provider'
    AND lower(elasticgpuassociations.attr_name) = 'elasticgpuassociations'
  LEFT JOIN resource_attribute AS elasticinferenceacceleratorassociations
    ON elasticinferenceacceleratorassociations.resource_id = R.id
    AND elasticinferenceacceleratorassociations.type = 'provider'
    AND lower(elasticinferenceacceleratorassociations.attr_name) = 'elasticinferenceacceleratorassociations'
  LEFT JOIN resource_attribute AS networkinterfaces
    ON networkinterfaces.resource_id = R.id
    AND networkinterfaces.type = 'provider'
    AND lower(networkinterfaces.attr_name) = 'networkinterfaces'
  LEFT JOIN resource_attribute AS outpostarn
    ON outpostarn.resource_id = R.id
    AND outpostarn.type = 'provider'
    AND lower(outpostarn.attr_name) = 'outpostarn'
  LEFT JOIN resource_attribute AS rootdevicename
    ON rootdevicename.resource_id = R.id
    AND rootdevicename.type = 'provider'
    AND lower(rootdevicename.attr_name) = 'rootdevicename'
  LEFT JOIN resource_attribute AS rootdevicetype
    ON rootdevicetype.resource_id = R.id
    AND rootdevicetype.type = 'provider'
    AND lower(rootdevicetype.attr_name) = 'rootdevicetype'
  LEFT JOIN resource_attribute AS securitygroups
    ON securitygroups.resource_id = R.id
    AND securitygroups.type = 'provider'
    AND lower(securitygroups.attr_name) = 'securitygroups'
  LEFT JOIN resource_attribute AS sourcedestcheck
    ON sourcedestcheck.resource_id = R.id
    AND sourcedestcheck.type = 'provider'
    AND lower(sourcedestcheck.attr_name) = 'sourcedestcheck'
  LEFT JOIN resource_attribute AS spotinstancerequestid
    ON spotinstancerequestid.resource_id = R.id
    AND spotinstancerequestid.type = 'provider'
    AND lower(spotinstancerequestid.attr_name) = 'spotinstancerequestid'
  LEFT JOIN resource_attribute AS sriovnetsupport
    ON sriovnetsupport.resource_id = R.id
    AND sriovnetsupport.type = 'provider'
    AND lower(sriovnetsupport.attr_name) = 'sriovnetsupport'
  LEFT JOIN resource_attribute AS statereason
    ON statereason.resource_id = R.id
    AND statereason.type = 'provider'
    AND lower(statereason.attr_name) = 'statereason'
  LEFT JOIN resource_attribute AS tags
    ON tags.resource_id = R.id
    AND tags.type = 'provider'
    AND lower(tags.attr_name) = 'tags'
  LEFT JOIN resource_attribute AS virtualizationtype
    ON virtualizationtype.resource_id = R.id
    AND virtualizationtype.type = 'provider'
    AND lower(virtualizationtype.attr_name) = 'virtualizationtype'
  LEFT JOIN resource_attribute AS cpuoptions
    ON cpuoptions.resource_id = R.id
    AND cpuoptions.type = 'provider'
    AND lower(cpuoptions.attr_name) = 'cpuoptions'
  LEFT JOIN resource_attribute AS capacityreservationid
    ON capacityreservationid.resource_id = R.id
    AND capacityreservationid.type = 'provider'
    AND lower(capacityreservationid.attr_name) = 'capacityreservationid'
  LEFT JOIN resource_attribute AS capacityreservationspecification
    ON capacityreservationspecification.resource_id = R.id
    AND capacityreservationspecification.type = 'provider'
    AND lower(capacityreservationspecification.attr_name) = 'capacityreservationspecification'
  LEFT JOIN resource_attribute AS hibernationoptions
    ON hibernationoptions.resource_id = R.id
    AND hibernationoptions.type = 'provider'
    AND lower(hibernationoptions.attr_name) = 'hibernationoptions'
  LEFT JOIN resource_attribute AS licenses
    ON licenses.resource_id = R.id
    AND licenses.type = 'provider'
    AND lower(licenses.attr_name) = 'licenses'
  LEFT JOIN resource_attribute AS metadataoptions
    ON metadataoptions.resource_id = R.id
    AND metadataoptions.type = 'provider'
    AND lower(metadataoptions.attr_name) = 'metadataoptions'
  LEFT JOIN resource_attribute AS enclaveoptions
    ON enclaveoptions.resource_id = R.id
    AND enclaveoptions.type = 'provider'
    AND lower(enclaveoptions.attr_name) = 'enclaveoptions'
  LEFT JOIN resource_attribute AS userdata
    ON userdata.resource_id = R.id
    AND userdata.type = 'provider'
    AND lower(userdata.attr_name) = 'userdata'
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
      _aws_ec2_subnet_relation.resource_id AS resource_id,
      _aws_ec2_subnet.id AS target_id
    FROM
      resource_relation AS _aws_ec2_subnet_relation
      INNER JOIN resource AS _aws_ec2_subnet
        ON _aws_ec2_subnet_relation.target_id = _aws_ec2_subnet.id
        AND _aws_ec2_subnet.provider_type = 'Subnet'
        AND _aws_ec2_subnet.service = 'ec2'
    WHERE
      _aws_ec2_subnet_relation.relation = 'in'
  ) AS _subnet_id ON _subnet_id.resource_id = R.id
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
  AND R.provider_type = 'Instance'
  AND R.service = 'ec2'
ON CONFLICT (_id) DO UPDATE
SET
    amilaunchindex = EXCLUDED.amilaunchindex,
    imageid = EXCLUDED.imageid,
    instanceid = EXCLUDED.instanceid,
    instancetype = EXCLUDED.instancetype,
    kernelid = EXCLUDED.kernelid,
    keyname = EXCLUDED.keyname,
    launchtime = EXCLUDED.launchtime,
    monitoring = EXCLUDED.monitoring,
    placement = EXCLUDED.placement,
    platform = EXCLUDED.platform,
    privatednsname = EXCLUDED.privatednsname,
    privateipaddress = EXCLUDED.privateipaddress,
    productcodes = EXCLUDED.productcodes,
    publicdnsname = EXCLUDED.publicdnsname,
    publicipaddress = EXCLUDED.publicipaddress,
    ramdiskid = EXCLUDED.ramdiskid,
    state = EXCLUDED.state,
    statetransitionreason = EXCLUDED.statetransitionreason,
    subnetid = EXCLUDED.subnetid,
    vpcid = EXCLUDED.vpcid,
    architecture = EXCLUDED.architecture,
    blockdevicemappings = EXCLUDED.blockdevicemappings,
    clienttoken = EXCLUDED.clienttoken,
    ebsoptimized = EXCLUDED.ebsoptimized,
    enasupport = EXCLUDED.enasupport,
    hypervisor = EXCLUDED.hypervisor,
    iaminstanceprofile = EXCLUDED.iaminstanceprofile,
    instancelifecycle = EXCLUDED.instancelifecycle,
    elasticgpuassociations = EXCLUDED.elasticgpuassociations,
    elasticinferenceacceleratorassociations = EXCLUDED.elasticinferenceacceleratorassociations,
    networkinterfaces = EXCLUDED.networkinterfaces,
    outpostarn = EXCLUDED.outpostarn,
    rootdevicename = EXCLUDED.rootdevicename,
    rootdevicetype = EXCLUDED.rootdevicetype,
    securitygroups = EXCLUDED.securitygroups,
    sourcedestcheck = EXCLUDED.sourcedestcheck,
    spotinstancerequestid = EXCLUDED.spotinstancerequestid,
    sriovnetsupport = EXCLUDED.sriovnetsupport,
    statereason = EXCLUDED.statereason,
    tags = EXCLUDED.tags,
    virtualizationtype = EXCLUDED.virtualizationtype,
    cpuoptions = EXCLUDED.cpuoptions,
    capacityreservationid = EXCLUDED.capacityreservationid,
    capacityreservationspecification = EXCLUDED.capacityreservationspecification,
    hibernationoptions = EXCLUDED.hibernationoptions,
    licenses = EXCLUDED.licenses,
    metadataoptions = EXCLUDED.metadataoptions,
    enclaveoptions = EXCLUDED.enclaveoptions,
    userdata = EXCLUDED.userdata,
    _image_id = EXCLUDED._image_id,
    _iam_instanceprofile_id = EXCLUDED._iam_instanceprofile_id,
    _vpc_id = EXCLUDED._vpc_id,
    _subnet_id = EXCLUDED._subnet_id,
    _account_id = EXCLUDED._account_id
  ;



INSERT INTO aws_ec2_instance_volume
SELECT
  aws_ec2_instance.id AS instance_id,
  aws_ec2_volume.id AS volume_id,
  aws_ec2_instance.provider_account_id AS provider_account_id,
  (DeleteOnTermination.value #>> '{}')::boolean AS deleteontermination,
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
    AND aws_ec2_volume.service = 'ec2'
  LEFT JOIN resource_relation_attribute AS DeleteOnTermination
    ON DeleteOnTermination.relation_id = RR.id
    AND DeleteOnTermination.name = 'DeleteOnTermination'
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
  WHERE
    aws_ec2_instance.provider_type = 'Instance'
    AND aws_ec2_instance.service = 'ec2'
ON CONFLICT (instance_id, volume_id)

DO UPDATE
SET
  
  DeleteOnTermination = EXCLUDED.DeleteOnTermination,
  AttachTime = EXCLUDED.AttachTime,
  VolumeId = EXCLUDED.VolumeId,
  Status = EXCLUDED.Status,
  DeviceName = EXCLUDED.DeviceName;


INSERT INTO aws_ec2_instance_securitygroup
SELECT
  aws_ec2_instance.id AS instance_id,
  aws_ec2_securitygroup.id AS securitygroup_id,
  aws_ec2_instance.provider_account_id AS provider_account_id
FROM
  resource AS aws_ec2_instance
  INNER JOIN resource_relation AS RR
    ON RR.resource_id = aws_ec2_instance.id
    AND RR.relation = 'in'
  INNER JOIN resource AS aws_ec2_securitygroup
    ON aws_ec2_securitygroup.id = RR.target_id
    AND aws_ec2_securitygroup.provider_type = 'SecurityGroup'
    AND aws_ec2_securitygroup.service = 'ec2'
  WHERE
    aws_ec2_instance.provider_type = 'Instance'
    AND aws_ec2_instance.service = 'ec2'
ON CONFLICT (instance_id, securitygroup_id)
DO NOTHING
;

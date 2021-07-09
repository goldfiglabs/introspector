WITH attrs AS (
  SELECT
    resource_id,
    jsonb_object_agg(attr_name, attr_value) FILTER (WHERE type = 'provider') AS provider,
    jsonb_object_agg(attr_name, attr_value) FILTER (WHERE type = 'Metadata') AS metadata
  FROM
    resource_attribute
  WHERE
    provider_account_id = :provider_account_id
  GROUP BY resource_id
)
INSERT INTO aws_ec2_instance (
  _id,
  uri,
  provider_account_id,
  amilaunchindex,
  imageid,
  instanceid,
  instancetype,
  kernelid,
  keyname,
  launchtime,
  monitoring,
  placement,
  platform,
  privatednsname,
  privateipaddress,
  productcodes,
  publicdnsname,
  publicipaddress,
  ramdiskid,
  state,
  statetransitionreason,
  subnetid,
  vpcid,
  architecture,
  blockdevicemappings,
  clienttoken,
  ebsoptimized,
  enasupport,
  hypervisor,
  iaminstanceprofile,
  instancelifecycle,
  elasticgpuassociations,
  elasticinferenceacceleratorassociations,
  networkinterfaces,
  outpostarn,
  rootdevicename,
  rootdevicetype,
  securitygroups,
  sourcedestcheck,
  spotinstancerequestid,
  sriovnetsupport,
  statereason,
  tags,
  virtualizationtype,
  cpuoptions,
  capacityreservationid,
  capacityreservationspecification,
  hibernationoptions,
  licenses,
  metadataoptions,
  enclaveoptions,
  userdata,
  _tags,
  _image_id,_iam_instanceprofile_id,_vpc_id,_subnet_id,_account_id
)
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  (attrs.provider ->> 'AmiLaunchIndex')::integer AS amilaunchindex,
  attrs.provider ->> 'ImageId' AS imageid,
  attrs.provider ->> 'InstanceId' AS instanceid,
  attrs.provider ->> 'InstanceType' AS instancetype,
  attrs.provider ->> 'KernelId' AS kernelid,
  attrs.provider ->> 'KeyName' AS keyname,
  (TO_TIMESTAMP(attrs.provider ->> 'LaunchTime', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS launchtime,
  attrs.provider -> 'Monitoring' AS monitoring,
  attrs.provider -> 'Placement' AS placement,
  attrs.provider ->> 'Platform' AS platform,
  attrs.provider ->> 'PrivateDnsName' AS privatednsname,
  (attrs.provider ->> 'PrivateIpAddress')::inet AS privateipaddress,
  attrs.provider -> 'ProductCodes' AS productcodes,
  attrs.provider ->> 'PublicDnsName' AS publicdnsname,
  (attrs.provider ->> 'PublicIpAddress')::inet AS publicipaddress,
  attrs.provider ->> 'RamdiskId' AS ramdiskid,
  attrs.provider -> 'State' AS state,
  attrs.provider ->> 'StateTransitionReason' AS statetransitionreason,
  attrs.provider ->> 'SubnetId' AS subnetid,
  attrs.provider ->> 'VpcId' AS vpcid,
  attrs.provider ->> 'Architecture' AS architecture,
  attrs.provider -> 'BlockDeviceMappings' AS blockdevicemappings,
  attrs.provider ->> 'ClientToken' AS clienttoken,
  (attrs.provider ->> 'EbsOptimized')::boolean AS ebsoptimized,
  (attrs.provider ->> 'EnaSupport')::boolean AS enasupport,
  attrs.provider ->> 'Hypervisor' AS hypervisor,
  attrs.provider -> 'IamInstanceProfile' AS iaminstanceprofile,
  attrs.provider ->> 'InstanceLifecycle' AS instancelifecycle,
  attrs.provider -> 'ElasticGpuAssociations' AS elasticgpuassociations,
  attrs.provider -> 'ElasticInferenceAcceleratorAssociations' AS elasticinferenceacceleratorassociations,
  attrs.provider -> 'NetworkInterfaces' AS networkinterfaces,
  attrs.provider ->> 'OutpostArn' AS outpostarn,
  attrs.provider ->> 'RootDeviceName' AS rootdevicename,
  attrs.provider ->> 'RootDeviceType' AS rootdevicetype,
  attrs.provider -> 'SecurityGroups' AS securitygroups,
  (attrs.provider ->> 'SourceDestCheck')::boolean AS sourcedestcheck,
  attrs.provider ->> 'SpotInstanceRequestId' AS spotinstancerequestid,
  attrs.provider ->> 'SriovNetSupport' AS sriovnetsupport,
  attrs.provider -> 'StateReason' AS statereason,
  attrs.provider -> 'Tags' AS tags,
  attrs.provider ->> 'VirtualizationType' AS virtualizationtype,
  attrs.provider -> 'CpuOptions' AS cpuoptions,
  attrs.provider ->> 'CapacityReservationId' AS capacityreservationid,
  attrs.provider -> 'CapacityReservationSpecification' AS capacityreservationspecification,
  attrs.provider -> 'HibernationOptions' AS hibernationoptions,
  attrs.provider -> 'Licenses' AS licenses,
  attrs.provider -> 'MetadataOptions' AS metadataoptions,
  attrs.provider -> 'EnclaveOptions' AS enclaveoptions,
  attrs.provider ->> 'UserData' AS userdata,
  attrs.metadata -> 'Tags' AS tags,
  
    _image_id.target_id AS _image_id,
    _iam_instanceprofile_id.target_id AS _iam_instanceprofile_id,
    _vpc_id.target_id AS _vpc_id,
    _subnet_id.target_id AS _subnet_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  LEFT JOIN attrs ON
    attrs.resource_id = R.id
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
        AND _aws_ec2_image.provider_account_id = :provider_account_id
    WHERE
      _aws_ec2_image_relation.relation = 'imaged'
      AND _aws_ec2_image_relation.provider_account_id = :provider_account_id
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
        AND _aws_iam_instanceprofile.provider_account_id = :provider_account_id
    WHERE
      _aws_iam_instanceprofile_relation.relation = 'acts-as'
      AND _aws_iam_instanceprofile_relation.provider_account_id = :provider_account_id
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
        AND _aws_ec2_vpc.provider_account_id = :provider_account_id
    WHERE
      _aws_ec2_vpc_relation.relation = 'in'
      AND _aws_ec2_vpc_relation.provider_account_id = :provider_account_id
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
        AND _aws_ec2_subnet.provider_account_id = :provider_account_id
    WHERE
      _aws_ec2_subnet_relation.relation = 'in'
      AND _aws_ec2_subnet_relation.provider_account_id = :provider_account_id
  ) AS _subnet_id ON _subnet_id.resource_id = R.id
  LEFT JOIN (
    SELECT
      unique_account_mapping.resource_id,
      unique_account_mapping.target_ids[1] as target_id
    FROM
      (
        SELECT
          ARRAY_AGG(_aws_organizations_account_relation.target_id) AS target_ids,
          _aws_organizations_account_relation.resource_id
        FROM
          resource AS _aws_organizations_account
          INNER JOIN resource_relation AS _aws_organizations_account_relation
            ON _aws_organizations_account_relation.target_id = _aws_organizations_account.id
        WHERE
          _aws_organizations_account.provider_type = 'Account'
          AND _aws_organizations_account.service = 'organizations'
          AND _aws_organizations_account.provider_account_id = :provider_account_id
          AND _aws_organizations_account_relation.relation = 'in'
          AND _aws_organizations_account_relation.provider_account_id = 8
        GROUP BY _aws_organizations_account_relation.resource_id
        HAVING COUNT(*) = 1
      ) AS unique_account_mapping
  ) AS _account_id ON _account_id.resource_id = R.id
  WHERE
  R.provider_account_id = :provider_account_id
  AND R.provider_type = 'Instance'
  AND R.service = 'ec2'
ON CONFLICT (_id) DO UPDATE
SET
    AmiLaunchIndex = EXCLUDED.AmiLaunchIndex,
    ImageId = EXCLUDED.ImageId,
    InstanceId = EXCLUDED.InstanceId,
    InstanceType = EXCLUDED.InstanceType,
    KernelId = EXCLUDED.KernelId,
    KeyName = EXCLUDED.KeyName,
    LaunchTime = EXCLUDED.LaunchTime,
    Monitoring = EXCLUDED.Monitoring,
    Placement = EXCLUDED.Placement,
    Platform = EXCLUDED.Platform,
    PrivateDnsName = EXCLUDED.PrivateDnsName,
    PrivateIpAddress = EXCLUDED.PrivateIpAddress,
    ProductCodes = EXCLUDED.ProductCodes,
    PublicDnsName = EXCLUDED.PublicDnsName,
    PublicIpAddress = EXCLUDED.PublicIpAddress,
    RamdiskId = EXCLUDED.RamdiskId,
    State = EXCLUDED.State,
    StateTransitionReason = EXCLUDED.StateTransitionReason,
    SubnetId = EXCLUDED.SubnetId,
    VpcId = EXCLUDED.VpcId,
    Architecture = EXCLUDED.Architecture,
    BlockDeviceMappings = EXCLUDED.BlockDeviceMappings,
    ClientToken = EXCLUDED.ClientToken,
    EbsOptimized = EXCLUDED.EbsOptimized,
    EnaSupport = EXCLUDED.EnaSupport,
    Hypervisor = EXCLUDED.Hypervisor,
    IamInstanceProfile = EXCLUDED.IamInstanceProfile,
    InstanceLifecycle = EXCLUDED.InstanceLifecycle,
    ElasticGpuAssociations = EXCLUDED.ElasticGpuAssociations,
    ElasticInferenceAcceleratorAssociations = EXCLUDED.ElasticInferenceAcceleratorAssociations,
    NetworkInterfaces = EXCLUDED.NetworkInterfaces,
    OutpostArn = EXCLUDED.OutpostArn,
    RootDeviceName = EXCLUDED.RootDeviceName,
    RootDeviceType = EXCLUDED.RootDeviceType,
    SecurityGroups = EXCLUDED.SecurityGroups,
    SourceDestCheck = EXCLUDED.SourceDestCheck,
    SpotInstanceRequestId = EXCLUDED.SpotInstanceRequestId,
    SriovNetSupport = EXCLUDED.SriovNetSupport,
    StateReason = EXCLUDED.StateReason,
    Tags = EXCLUDED.Tags,
    VirtualizationType = EXCLUDED.VirtualizationType,
    CpuOptions = EXCLUDED.CpuOptions,
    CapacityReservationId = EXCLUDED.CapacityReservationId,
    CapacityReservationSpecification = EXCLUDED.CapacityReservationSpecification,
    HibernationOptions = EXCLUDED.HibernationOptions,
    Licenses = EXCLUDED.Licenses,
    MetadataOptions = EXCLUDED.MetadataOptions,
    EnclaveOptions = EXCLUDED.EnclaveOptions,
    UserData = EXCLUDED.UserData,
    _tags = EXCLUDED._tags,
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
    AND aws_ec2_volume.provider_account_id = :provider_account_id
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
    aws_ec2_instance.provider_account_id = :provider_account_id
    AND aws_ec2_instance.provider_type = 'Instance'
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
    AND aws_ec2_securitygroup.provider_account_id = :provider_account_id
  WHERE
    aws_ec2_instance.provider_account_id = :provider_account_id
    AND aws_ec2_instance.provider_type = 'Instance'
    AND aws_ec2_instance.service = 'ec2'
ON CONFLICT (instance_id, securitygroup_id)
DO NOTHING
;

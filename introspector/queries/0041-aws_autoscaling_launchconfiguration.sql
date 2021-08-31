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
INSERT INTO aws_autoscaling_launchconfiguration (
  _id,
  uri,
  provider_account_id,
  launchconfigurationname,
  launchconfigurationarn,
  imageid,
  keyname,
  securitygroups,
  classiclinkvpcid,
  classiclinkvpcsecuritygroups,
  userdata,
  instancetype,
  kernelid,
  ramdiskid,
  blockdevicemappings,
  instancemonitoring,
  spotprice,
  iaminstanceprofile,
  createdtime,
  ebsoptimized,
  associatepublicipaddress,
  placementtenancy,
  metadataoptions,
  _ec2_image_id,_iam_instanceprofile_id,_account_id
)
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  attrs.provider ->> 'LaunchConfigurationName' AS launchconfigurationname,
  attrs.provider ->> 'LaunchConfigurationARN' AS launchconfigurationarn,
  attrs.provider ->> 'ImageId' AS imageid,
  attrs.provider ->> 'KeyName' AS keyname,
  attrs.provider -> 'SecurityGroups' AS securitygroups,
  attrs.provider ->> 'ClassicLinkVPCId' AS classiclinkvpcid,
  attrs.provider -> 'ClassicLinkVPCSecurityGroups' AS classiclinkvpcsecuritygroups,
  attrs.provider ->> 'UserData' AS userdata,
  attrs.provider ->> 'InstanceType' AS instancetype,
  attrs.provider ->> 'KernelId' AS kernelid,
  attrs.provider ->> 'RamdiskId' AS ramdiskid,
  attrs.provider -> 'BlockDeviceMappings' AS blockdevicemappings,
  attrs.provider -> 'InstanceMonitoring' AS instancemonitoring,
  attrs.provider ->> 'SpotPrice' AS spotprice,
  attrs.provider ->> 'IamInstanceProfile' AS iaminstanceprofile,
  (TO_TIMESTAMP(attrs.provider ->> 'CreatedTime', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS createdtime,
  (attrs.provider ->> 'EbsOptimized')::boolean AS ebsoptimized,
  (attrs.provider ->> 'AssociatePublicIpAddress')::boolean AS associatepublicipaddress,
  attrs.provider ->> 'PlacementTenancy' AS placementtenancy,
  attrs.provider -> 'MetadataOptions' AS metadataoptions,
  
    _ec2_image_id.target_id AS _ec2_image_id,
    _iam_instanceprofile_id.target_id AS _iam_instanceprofile_id,
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
  ) AS _ec2_image_id ON _ec2_image_id.resource_id = R.id
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
          AND _aws_organizations_account_relation.provider_account_id = :provider_account_id
        GROUP BY _aws_organizations_account_relation.resource_id
        HAVING COUNT(*) = 1
      ) AS unique_account_mapping
  ) AS _account_id ON _account_id.resource_id = R.id
  WHERE
  R.provider_account_id = :provider_account_id
  AND R.provider_type = 'LaunchConfiguration'
  AND R.service = 'autoscaling'
ON CONFLICT (_id) DO UPDATE
SET
    LaunchConfigurationName = EXCLUDED.LaunchConfigurationName,
    LaunchConfigurationARN = EXCLUDED.LaunchConfigurationARN,
    ImageId = EXCLUDED.ImageId,
    KeyName = EXCLUDED.KeyName,
    SecurityGroups = EXCLUDED.SecurityGroups,
    ClassicLinkVPCId = EXCLUDED.ClassicLinkVPCId,
    ClassicLinkVPCSecurityGroups = EXCLUDED.ClassicLinkVPCSecurityGroups,
    UserData = EXCLUDED.UserData,
    InstanceType = EXCLUDED.InstanceType,
    KernelId = EXCLUDED.KernelId,
    RamdiskId = EXCLUDED.RamdiskId,
    BlockDeviceMappings = EXCLUDED.BlockDeviceMappings,
    InstanceMonitoring = EXCLUDED.InstanceMonitoring,
    SpotPrice = EXCLUDED.SpotPrice,
    IamInstanceProfile = EXCLUDED.IamInstanceProfile,
    CreatedTime = EXCLUDED.CreatedTime,
    EbsOptimized = EXCLUDED.EbsOptimized,
    AssociatePublicIpAddress = EXCLUDED.AssociatePublicIpAddress,
    PlacementTenancy = EXCLUDED.PlacementTenancy,
    MetadataOptions = EXCLUDED.MetadataOptions,
    _ec2_image_id = EXCLUDED._ec2_image_id,
    _iam_instanceprofile_id = EXCLUDED._iam_instanceprofile_id,
    _account_id = EXCLUDED._account_id
  ;



INSERT INTO aws_autoscaling_launchconfiguration_ec2_securitygroup
SELECT
  aws_autoscaling_launchconfiguration.id AS launchconfiguration_id,
  aws_ec2_securitygroup.id AS securitygroup_id,
  aws_autoscaling_launchconfiguration.provider_account_id AS provider_account_id
FROM
  resource AS aws_autoscaling_launchconfiguration
  INNER JOIN resource_relation AS RR
    ON RR.resource_id = aws_autoscaling_launchconfiguration.id
    AND RR.relation = 'launches-into'
  INNER JOIN resource AS aws_ec2_securitygroup
    ON aws_ec2_securitygroup.id = RR.target_id
    AND aws_ec2_securitygroup.provider_type = 'SecurityGroup'
    AND aws_ec2_securitygroup.service = 'ec2'
    AND aws_ec2_securitygroup.provider_account_id = :provider_account_id
  WHERE
    aws_autoscaling_launchconfiguration.provider_account_id = :provider_account_id
    AND aws_autoscaling_launchconfiguration.provider_type = 'LaunchConfiguration'
    AND aws_autoscaling_launchconfiguration.service = 'autoscaling'
ON CONFLICT (launchconfiguration_id, securitygroup_id)
DO NOTHING
;

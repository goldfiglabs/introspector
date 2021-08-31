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
INSERT INTO aws_ec2_image (
  _id,
  uri,
  provider_account_id,
  architecture,
  creationdate,
  imageid,
  imagelocation,
  imagetype,
  public,
  kernelid,
  ownerid,
  platform,
  platformdetails,
  usageoperation,
  productcodes,
  ramdiskid,
  state,
  blockdevicemappings,
  description,
  enasupport,
  hypervisor,
  imageowneralias,
  name,
  rootdevicename,
  rootdevicetype,
  sriovnetsupport,
  statereason,
  tags,
  virtualizationtype,
  launchpermissions,
  _tags,
  _account_id
)
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  attrs.provider ->> 'Architecture' AS architecture,
  attrs.provider ->> 'CreationDate' AS creationdate,
  attrs.provider ->> 'ImageId' AS imageid,
  attrs.provider ->> 'ImageLocation' AS imagelocation,
  attrs.provider ->> 'ImageType' AS imagetype,
  (attrs.provider ->> 'Public')::boolean AS public,
  attrs.provider ->> 'KernelId' AS kernelid,
  attrs.provider ->> 'OwnerId' AS ownerid,
  attrs.provider ->> 'Platform' AS platform,
  attrs.provider ->> 'PlatformDetails' AS platformdetails,
  attrs.provider ->> 'UsageOperation' AS usageoperation,
  attrs.provider -> 'ProductCodes' AS productcodes,
  attrs.provider ->> 'RamdiskId' AS ramdiskid,
  attrs.provider ->> 'State' AS state,
  attrs.provider -> 'BlockDeviceMappings' AS blockdevicemappings,
  attrs.provider ->> 'Description' AS description,
  (attrs.provider ->> 'EnaSupport')::boolean AS enasupport,
  attrs.provider ->> 'Hypervisor' AS hypervisor,
  attrs.provider ->> 'ImageOwnerAlias' AS imageowneralias,
  attrs.provider ->> 'Name' AS name,
  attrs.provider ->> 'RootDeviceName' AS rootdevicename,
  attrs.provider ->> 'RootDeviceType' AS rootdevicetype,
  attrs.provider ->> 'SriovNetSupport' AS sriovnetsupport,
  attrs.provider -> 'StateReason' AS statereason,
  attrs.provider -> 'Tags' AS tags,
  attrs.provider ->> 'VirtualizationType' AS virtualizationtype,
  attrs.provider -> 'LaunchPermissions' AS launchpermissions,
  attrs.metadata -> 'Tags' AS tags,
  
    _account_id.target_id AS _account_id
FROM
  resource AS R
  LEFT JOIN attrs ON
    attrs.resource_id = R.id
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
  AND R.provider_type = 'Image'
  AND R.service = 'ec2'
ON CONFLICT (_id) DO UPDATE
SET
    Architecture = EXCLUDED.Architecture,
    CreationDate = EXCLUDED.CreationDate,
    ImageId = EXCLUDED.ImageId,
    ImageLocation = EXCLUDED.ImageLocation,
    ImageType = EXCLUDED.ImageType,
    Public = EXCLUDED.Public,
    KernelId = EXCLUDED.KernelId,
    OwnerId = EXCLUDED.OwnerId,
    Platform = EXCLUDED.Platform,
    PlatformDetails = EXCLUDED.PlatformDetails,
    UsageOperation = EXCLUDED.UsageOperation,
    ProductCodes = EXCLUDED.ProductCodes,
    RamdiskId = EXCLUDED.RamdiskId,
    State = EXCLUDED.State,
    BlockDeviceMappings = EXCLUDED.BlockDeviceMappings,
    Description = EXCLUDED.Description,
    EnaSupport = EXCLUDED.EnaSupport,
    Hypervisor = EXCLUDED.Hypervisor,
    ImageOwnerAlias = EXCLUDED.ImageOwnerAlias,
    Name = EXCLUDED.Name,
    RootDeviceName = EXCLUDED.RootDeviceName,
    RootDeviceType = EXCLUDED.RootDeviceType,
    SriovNetSupport = EXCLUDED.SriovNetSupport,
    StateReason = EXCLUDED.StateReason,
    Tags = EXCLUDED.Tags,
    VirtualizationType = EXCLUDED.VirtualizationType,
    LaunchPermissions = EXCLUDED.LaunchPermissions,
    _tags = EXCLUDED._tags,
    _account_id = EXCLUDED._account_id
  ;


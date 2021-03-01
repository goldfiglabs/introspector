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
  architecture.attr_value #>> '{}' AS architecture,
  creationdate.attr_value #>> '{}' AS creationdate,
  imageid.attr_value #>> '{}' AS imageid,
  imagelocation.attr_value #>> '{}' AS imagelocation,
  imagetype.attr_value #>> '{}' AS imagetype,
  (public.attr_value #>> '{}')::boolean AS public,
  kernelid.attr_value #>> '{}' AS kernelid,
  ownerid.attr_value #>> '{}' AS ownerid,
  platform.attr_value #>> '{}' AS platform,
  platformdetails.attr_value #>> '{}' AS platformdetails,
  usageoperation.attr_value #>> '{}' AS usageoperation,
  productcodes.attr_value::jsonb AS productcodes,
  ramdiskid.attr_value #>> '{}' AS ramdiskid,
  state.attr_value #>> '{}' AS state,
  blockdevicemappings.attr_value::jsonb AS blockdevicemappings,
  description.attr_value #>> '{}' AS description,
  (enasupport.attr_value #>> '{}')::boolean AS enasupport,
  hypervisor.attr_value #>> '{}' AS hypervisor,
  imageowneralias.attr_value #>> '{}' AS imageowneralias,
  name.attr_value #>> '{}' AS name,
  rootdevicename.attr_value #>> '{}' AS rootdevicename,
  rootdevicetype.attr_value #>> '{}' AS rootdevicetype,
  sriovnetsupport.attr_value #>> '{}' AS sriovnetsupport,
  statereason.attr_value::jsonb AS statereason,
  tags.attr_value::jsonb AS tags,
  virtualizationtype.attr_value #>> '{}' AS virtualizationtype,
  launchpermissions.attr_value::jsonb AS launchpermissions,
  _tags.attr_value::jsonb AS _tags,
  
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN resource_attribute AS architecture
    ON architecture.resource_id = R.id
    AND architecture.type = 'provider'
    AND lower(architecture.attr_name) = 'architecture'
  LEFT JOIN resource_attribute AS creationdate
    ON creationdate.resource_id = R.id
    AND creationdate.type = 'provider'
    AND lower(creationdate.attr_name) = 'creationdate'
  LEFT JOIN resource_attribute AS imageid
    ON imageid.resource_id = R.id
    AND imageid.type = 'provider'
    AND lower(imageid.attr_name) = 'imageid'
  LEFT JOIN resource_attribute AS imagelocation
    ON imagelocation.resource_id = R.id
    AND imagelocation.type = 'provider'
    AND lower(imagelocation.attr_name) = 'imagelocation'
  LEFT JOIN resource_attribute AS imagetype
    ON imagetype.resource_id = R.id
    AND imagetype.type = 'provider'
    AND lower(imagetype.attr_name) = 'imagetype'
  LEFT JOIN resource_attribute AS public
    ON public.resource_id = R.id
    AND public.type = 'provider'
    AND lower(public.attr_name) = 'public'
  LEFT JOIN resource_attribute AS kernelid
    ON kernelid.resource_id = R.id
    AND kernelid.type = 'provider'
    AND lower(kernelid.attr_name) = 'kernelid'
  LEFT JOIN resource_attribute AS ownerid
    ON ownerid.resource_id = R.id
    AND ownerid.type = 'provider'
    AND lower(ownerid.attr_name) = 'ownerid'
  LEFT JOIN resource_attribute AS platform
    ON platform.resource_id = R.id
    AND platform.type = 'provider'
    AND lower(platform.attr_name) = 'platform'
  LEFT JOIN resource_attribute AS platformdetails
    ON platformdetails.resource_id = R.id
    AND platformdetails.type = 'provider'
    AND lower(platformdetails.attr_name) = 'platformdetails'
  LEFT JOIN resource_attribute AS usageoperation
    ON usageoperation.resource_id = R.id
    AND usageoperation.type = 'provider'
    AND lower(usageoperation.attr_name) = 'usageoperation'
  LEFT JOIN resource_attribute AS productcodes
    ON productcodes.resource_id = R.id
    AND productcodes.type = 'provider'
    AND lower(productcodes.attr_name) = 'productcodes'
  LEFT JOIN resource_attribute AS ramdiskid
    ON ramdiskid.resource_id = R.id
    AND ramdiskid.type = 'provider'
    AND lower(ramdiskid.attr_name) = 'ramdiskid'
  LEFT JOIN resource_attribute AS state
    ON state.resource_id = R.id
    AND state.type = 'provider'
    AND lower(state.attr_name) = 'state'
  LEFT JOIN resource_attribute AS blockdevicemappings
    ON blockdevicemappings.resource_id = R.id
    AND blockdevicemappings.type = 'provider'
    AND lower(blockdevicemappings.attr_name) = 'blockdevicemappings'
  LEFT JOIN resource_attribute AS description
    ON description.resource_id = R.id
    AND description.type = 'provider'
    AND lower(description.attr_name) = 'description'
  LEFT JOIN resource_attribute AS enasupport
    ON enasupport.resource_id = R.id
    AND enasupport.type = 'provider'
    AND lower(enasupport.attr_name) = 'enasupport'
  LEFT JOIN resource_attribute AS hypervisor
    ON hypervisor.resource_id = R.id
    AND hypervisor.type = 'provider'
    AND lower(hypervisor.attr_name) = 'hypervisor'
  LEFT JOIN resource_attribute AS imageowneralias
    ON imageowneralias.resource_id = R.id
    AND imageowneralias.type = 'provider'
    AND lower(imageowneralias.attr_name) = 'imageowneralias'
  LEFT JOIN resource_attribute AS name
    ON name.resource_id = R.id
    AND name.type = 'provider'
    AND lower(name.attr_name) = 'name'
  LEFT JOIN resource_attribute AS rootdevicename
    ON rootdevicename.resource_id = R.id
    AND rootdevicename.type = 'provider'
    AND lower(rootdevicename.attr_name) = 'rootdevicename'
  LEFT JOIN resource_attribute AS rootdevicetype
    ON rootdevicetype.resource_id = R.id
    AND rootdevicetype.type = 'provider'
    AND lower(rootdevicetype.attr_name) = 'rootdevicetype'
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
  LEFT JOIN resource_attribute AS launchpermissions
    ON launchpermissions.resource_id = R.id
    AND launchpermissions.type = 'provider'
    AND lower(launchpermissions.attr_name) = 'launchpermissions'
  LEFT JOIN resource_attribute AS _tags
    ON _tags.resource_id = R.id
    AND _tags.type = 'Metadata'
    AND lower(_tags.attr_name) = 'tags'
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
      GROUP BY _aws_organizations_account_relation.resource_id
      HAVING COUNT(*) = 1
    ) AS unique_account_mapping
    INNER JOIN resource_relation AS _aws_organizations_account_relation
      ON _aws_organizations_account_relation.resource_id = unique_account_mapping.resource_id
    INNER JOIN resource AS _aws_organizations_account
      ON _aws_organizations_account_relation.target_id = _aws_organizations_account.id
      AND _aws_organizations_account.provider_type = 'Account'
      AND _aws_organizations_account.service = 'organizations'
    WHERE
        _aws_organizations_account_relation.relation = 'in'
  ) AS _account_id ON _account_id.resource_id = R.id
  WHERE
  PA.provider = 'aws'
  AND R.provider_type = 'Image'
  AND R.service = 'ec2'
ON CONFLICT (_id) DO UPDATE
SET
    architecture = EXCLUDED.architecture,
    creationdate = EXCLUDED.creationdate,
    imageid = EXCLUDED.imageid,
    imagelocation = EXCLUDED.imagelocation,
    imagetype = EXCLUDED.imagetype,
    public = EXCLUDED.public,
    kernelid = EXCLUDED.kernelid,
    ownerid = EXCLUDED.ownerid,
    platform = EXCLUDED.platform,
    platformdetails = EXCLUDED.platformdetails,
    usageoperation = EXCLUDED.usageoperation,
    productcodes = EXCLUDED.productcodes,
    ramdiskid = EXCLUDED.ramdiskid,
    state = EXCLUDED.state,
    blockdevicemappings = EXCLUDED.blockdevicemappings,
    description = EXCLUDED.description,
    enasupport = EXCLUDED.enasupport,
    hypervisor = EXCLUDED.hypervisor,
    imageowneralias = EXCLUDED.imageowneralias,
    name = EXCLUDED.name,
    rootdevicename = EXCLUDED.rootdevicename,
    rootdevicetype = EXCLUDED.rootdevicetype,
    sriovnetsupport = EXCLUDED.sriovnetsupport,
    statereason = EXCLUDED.statereason,
    tags = EXCLUDED.tags,
    virtualizationtype = EXCLUDED.virtualizationtype,
    launchpermissions = EXCLUDED.launchpermissions,
    _tags = EXCLUDED._tags,
    _account_id = EXCLUDED._account_id
  ;


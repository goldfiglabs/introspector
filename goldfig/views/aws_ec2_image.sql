DROP MATERIALIZED VIEW IF EXISTS aws_ec2_image CASCADE;

CREATE MATERIALIZED VIEW aws_ec2_image AS
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
  
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN attrs AS architecture
    ON architecture.id = R.id
    AND architecture.attr_name = 'architecture'
  LEFT JOIN attrs AS creationdate
    ON creationdate.id = R.id
    AND creationdate.attr_name = 'creationdate'
  LEFT JOIN attrs AS imageid
    ON imageid.id = R.id
    AND imageid.attr_name = 'imageid'
  LEFT JOIN attrs AS imagelocation
    ON imagelocation.id = R.id
    AND imagelocation.attr_name = 'imagelocation'
  LEFT JOIN attrs AS imagetype
    ON imagetype.id = R.id
    AND imagetype.attr_name = 'imagetype'
  LEFT JOIN attrs AS public
    ON public.id = R.id
    AND public.attr_name = 'public'
  LEFT JOIN attrs AS kernelid
    ON kernelid.id = R.id
    AND kernelid.attr_name = 'kernelid'
  LEFT JOIN attrs AS ownerid
    ON ownerid.id = R.id
    AND ownerid.attr_name = 'ownerid'
  LEFT JOIN attrs AS platform
    ON platform.id = R.id
    AND platform.attr_name = 'platform'
  LEFT JOIN attrs AS platformdetails
    ON platformdetails.id = R.id
    AND platformdetails.attr_name = 'platformdetails'
  LEFT JOIN attrs AS usageoperation
    ON usageoperation.id = R.id
    AND usageoperation.attr_name = 'usageoperation'
  LEFT JOIN attrs AS productcodes
    ON productcodes.id = R.id
    AND productcodes.attr_name = 'productcodes'
  LEFT JOIN attrs AS ramdiskid
    ON ramdiskid.id = R.id
    AND ramdiskid.attr_name = 'ramdiskid'
  LEFT JOIN attrs AS state
    ON state.id = R.id
    AND state.attr_name = 'state'
  LEFT JOIN attrs AS blockdevicemappings
    ON blockdevicemappings.id = R.id
    AND blockdevicemappings.attr_name = 'blockdevicemappings'
  LEFT JOIN attrs AS description
    ON description.id = R.id
    AND description.attr_name = 'description'
  LEFT JOIN attrs AS enasupport
    ON enasupport.id = R.id
    AND enasupport.attr_name = 'enasupport'
  LEFT JOIN attrs AS hypervisor
    ON hypervisor.id = R.id
    AND hypervisor.attr_name = 'hypervisor'
  LEFT JOIN attrs AS imageowneralias
    ON imageowneralias.id = R.id
    AND imageowneralias.attr_name = 'imageowneralias'
  LEFT JOIN attrs AS name
    ON name.id = R.id
    AND name.attr_name = 'name'
  LEFT JOIN attrs AS rootdevicename
    ON rootdevicename.id = R.id
    AND rootdevicename.attr_name = 'rootdevicename'
  LEFT JOIN attrs AS rootdevicetype
    ON rootdevicetype.id = R.id
    AND rootdevicetype.attr_name = 'rootdevicetype'
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
  AND LOWER(R.provider_type) = 'image'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_ec2_image;

COMMENT ON MATERIALIZED VIEW aws_ec2_image IS 'ec2 image resources and their associated attributes.';


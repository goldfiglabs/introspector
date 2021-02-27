INSERT INTO aws_ec2_subnet (
  _id,
  uri,
  provider_account_id,
  availabilityzone,
  availabilityzoneid,
  availableipaddresscount,
  cidrblock,
  defaultforaz,
  mappubliciponlaunch,
  mapcustomerownediponlaunch,
  customerownedipv4pool,
  state,
  subnetid,
  vpcid,
  ownerid,
  assignipv6addressoncreation,
  ipv6cidrblockassociationset,
  tags,
  subnetarn,
  outpostarn,
  _tags,
  _vpc_id,_account_id
)
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  availabilityzone.attr_value #>> '{}' AS availabilityzone,
  availabilityzoneid.attr_value #>> '{}' AS availabilityzoneid,
  (availableipaddresscount.attr_value #>> '{}')::integer AS availableipaddresscount,
  cidrblock.attr_value #>> '{}' AS cidrblock,
  (defaultforaz.attr_value #>> '{}')::boolean AS defaultforaz,
  (mappubliciponlaunch.attr_value #>> '{}')::boolean AS mappubliciponlaunch,
  (mapcustomerownediponlaunch.attr_value #>> '{}')::boolean AS mapcustomerownediponlaunch,
  customerownedipv4pool.attr_value #>> '{}' AS customerownedipv4pool,
  state.attr_value #>> '{}' AS state,
  subnetid.attr_value #>> '{}' AS subnetid,
  vpcid.attr_value #>> '{}' AS vpcid,
  ownerid.attr_value #>> '{}' AS ownerid,
  (assignipv6addressoncreation.attr_value #>> '{}')::boolean AS assignipv6addressoncreation,
  ipv6cidrblockassociationset.attr_value::jsonb AS ipv6cidrblockassociationset,
  tags.attr_value::jsonb AS tags,
  subnetarn.attr_value #>> '{}' AS subnetarn,
  outpostarn.attr_value #>> '{}' AS outpostarn,
  _tags.attr_value::jsonb AS _tags,

    _vpc_id.target_id AS _vpc_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN resource_attribute AS availabilityzone
    ON availabilityzone.resource_id = R.id
    AND availabilityzone.type = 'provider'
    AND lower(availabilityzone.attr_name) = 'availabilityzone'
  LEFT JOIN resource_attribute AS availabilityzoneid
    ON availabilityzoneid.resource_id = R.id
    AND availabilityzoneid.type = 'provider'
    AND lower(availabilityzoneid.attr_name) = 'availabilityzoneid'
  LEFT JOIN resource_attribute AS availableipaddresscount
    ON availableipaddresscount.resource_id = R.id
    AND availableipaddresscount.type = 'provider'
    AND lower(availableipaddresscount.attr_name) = 'availableipaddresscount'
  LEFT JOIN resource_attribute AS cidrblock
    ON cidrblock.resource_id = R.id
    AND cidrblock.type = 'provider'
    AND lower(cidrblock.attr_name) = 'cidrblock'
  LEFT JOIN resource_attribute AS defaultforaz
    ON defaultforaz.resource_id = R.id
    AND defaultforaz.type = 'provider'
    AND lower(defaultforaz.attr_name) = 'defaultforaz'
  LEFT JOIN resource_attribute AS mappubliciponlaunch
    ON mappubliciponlaunch.resource_id = R.id
    AND mappubliciponlaunch.type = 'provider'
    AND lower(mappubliciponlaunch.attr_name) = 'mappubliciponlaunch'
  LEFT JOIN resource_attribute AS mapcustomerownediponlaunch
    ON mapcustomerownediponlaunch.resource_id = R.id
    AND mapcustomerownediponlaunch.type = 'provider'
    AND lower(mapcustomerownediponlaunch.attr_name) = 'mapcustomerownediponlaunch'
  LEFT JOIN resource_attribute AS customerownedipv4pool
    ON customerownedipv4pool.resource_id = R.id
    AND customerownedipv4pool.type = 'provider'
    AND lower(customerownedipv4pool.attr_name) = 'customerownedipv4pool'
  LEFT JOIN resource_attribute AS state
    ON state.resource_id = R.id
    AND state.type = 'provider'
    AND lower(state.attr_name) = 'state'
  LEFT JOIN resource_attribute AS subnetid
    ON subnetid.resource_id = R.id
    AND subnetid.type = 'provider'
    AND lower(subnetid.attr_name) = 'subnetid'
  LEFT JOIN resource_attribute AS vpcid
    ON vpcid.resource_id = R.id
    AND vpcid.type = 'provider'
    AND lower(vpcid.attr_name) = 'vpcid'
  LEFT JOIN resource_attribute AS ownerid
    ON ownerid.resource_id = R.id
    AND ownerid.type = 'provider'
    AND lower(ownerid.attr_name) = 'ownerid'
  LEFT JOIN resource_attribute AS assignipv6addressoncreation
    ON assignipv6addressoncreation.resource_id = R.id
    AND assignipv6addressoncreation.type = 'provider'
    AND lower(assignipv6addressoncreation.attr_name) = 'assignipv6addressoncreation'
  LEFT JOIN resource_attribute AS ipv6cidrblockassociationset
    ON ipv6cidrblockassociationset.resource_id = R.id
    AND ipv6cidrblockassociationset.type = 'provider'
    AND lower(ipv6cidrblockassociationset.attr_name) = 'ipv6cidrblockassociationset'
  LEFT JOIN resource_attribute AS tags
    ON tags.resource_id = R.id
    AND tags.type = 'provider'
    AND lower(tags.attr_name) = 'tags'
  LEFT JOIN resource_attribute AS subnetarn
    ON subnetarn.resource_id = R.id
    AND subnetarn.type = 'provider'
    AND lower(subnetarn.attr_name) = 'subnetarn'
  LEFT JOIN resource_attribute AS outpostarn
    ON outpostarn.resource_id = R.id
    AND outpostarn.type = 'provider'
    AND lower(outpostarn.attr_name) = 'outpostarn'
  LEFT JOIN resource_attribute AS _tags
    ON _tags.resource_id = R.id
    AND _tags.type = 'Metadata'
    AND lower(_tags.attr_name) = 'tags'
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
  AND R.provider_type = 'Subnet'
  AND R.service = 'ec2'
ON CONFLICT (_id) DO UPDATE
SET
    availabilityzone = EXCLUDED.availabilityzone,
    availabilityzoneid = EXCLUDED.availabilityzoneid,
    availableipaddresscount = EXCLUDED.availableipaddresscount,
    cidrblock = EXCLUDED.cidrblock,
    defaultforaz = EXCLUDED.defaultforaz,
    mappubliciponlaunch = EXCLUDED.mappubliciponlaunch,
    mapcustomerownediponlaunch = EXCLUDED.mapcustomerownediponlaunch,
    customerownedipv4pool = EXCLUDED.customerownedipv4pool,
    state = EXCLUDED.state,
    subnetid = EXCLUDED.subnetid,
    vpcid = EXCLUDED.vpcid,
    ownerid = EXCLUDED.ownerid,
    assignipv6addressoncreation = EXCLUDED.assignipv6addressoncreation,
    ipv6cidrblockassociationset = EXCLUDED.ipv6cidrblockassociationset,
    tags = EXCLUDED.tags,
    subnetarn = EXCLUDED.subnetarn,
    outpostarn = EXCLUDED.outpostarn,
    _tags = EXCLUDED._tags,
    _vpc_id = EXCLUDED._vpc_id,
    _account_id = EXCLUDED._account_id
  ;

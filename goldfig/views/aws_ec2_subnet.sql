DROP MATERIALIZED VIEW IF EXISTS aws_ec2_subnet CASCADE;

CREATE MATERIALIZED VIEW aws_ec2_subnet AS
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
  
    _vpc_id.target_id AS _vpc_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN attrs AS availabilityzone
    ON availabilityzone.id = R.id
    AND availabilityzone.attr_name = 'availabilityzone'
  LEFT JOIN attrs AS availabilityzoneid
    ON availabilityzoneid.id = R.id
    AND availabilityzoneid.attr_name = 'availabilityzoneid'
  LEFT JOIN attrs AS availableipaddresscount
    ON availableipaddresscount.id = R.id
    AND availableipaddresscount.attr_name = 'availableipaddresscount'
  LEFT JOIN attrs AS cidrblock
    ON cidrblock.id = R.id
    AND cidrblock.attr_name = 'cidrblock'
  LEFT JOIN attrs AS defaultforaz
    ON defaultforaz.id = R.id
    AND defaultforaz.attr_name = 'defaultforaz'
  LEFT JOIN attrs AS mappubliciponlaunch
    ON mappubliciponlaunch.id = R.id
    AND mappubliciponlaunch.attr_name = 'mappubliciponlaunch'
  LEFT JOIN attrs AS mapcustomerownediponlaunch
    ON mapcustomerownediponlaunch.id = R.id
    AND mapcustomerownediponlaunch.attr_name = 'mapcustomerownediponlaunch'
  LEFT JOIN attrs AS customerownedipv4pool
    ON customerownedipv4pool.id = R.id
    AND customerownedipv4pool.attr_name = 'customerownedipv4pool'
  LEFT JOIN attrs AS state
    ON state.id = R.id
    AND state.attr_name = 'state'
  LEFT JOIN attrs AS subnetid
    ON subnetid.id = R.id
    AND subnetid.attr_name = 'subnetid'
  LEFT JOIN attrs AS vpcid
    ON vpcid.id = R.id
    AND vpcid.attr_name = 'vpcid'
  LEFT JOIN attrs AS ownerid
    ON ownerid.id = R.id
    AND ownerid.attr_name = 'ownerid'
  LEFT JOIN attrs AS assignipv6addressoncreation
    ON assignipv6addressoncreation.id = R.id
    AND assignipv6addressoncreation.attr_name = 'assignipv6addressoncreation'
  LEFT JOIN attrs AS ipv6cidrblockassociationset
    ON ipv6cidrblockassociationset.id = R.id
    AND ipv6cidrblockassociationset.attr_name = 'ipv6cidrblockassociationset'
  LEFT JOIN attrs AS tags
    ON tags.id = R.id
    AND tags.attr_name = 'tags'
  LEFT JOIN attrs AS subnetarn
    ON subnetarn.id = R.id
    AND subnetarn.attr_name = 'subnetarn'
  LEFT JOIN attrs AS outpostarn
    ON outpostarn.id = R.id
    AND outpostarn.attr_name = 'outpostarn'
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
  AND LOWER(R.provider_type) = 'subnet'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_ec2_subnet;

COMMENT ON MATERIALIZED VIEW aws_ec2_subnet IS 'ec2 subnet resources and their associated attributes.';


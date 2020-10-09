DROP MATERIALIZED VIEW IF EXISTS aws_ec2_vpc CASCADE;

CREATE MATERIALIZED VIEW aws_ec2_vpc AS
SELECT
  R.id AS resource_id,
  R.uri,
  R.provider_account_id,
  cidrblock.attr_value #>> '{}' AS cidrblock,
  dhcpoptionsid.attr_value #>> '{}' AS dhcpoptionsid,
  state.attr_value #>> '{}' AS state,
  vpcid.attr_value #>> '{}' AS vpcid,
  ownerid.attr_value #>> '{}' AS ownerid,
  instancetenancy.attr_value #>> '{}' AS instancetenancy,
  ipv6cidrblockassociationset.attr_value::jsonb AS ipv6cidrblockassociationset,
  cidrblockassociationset.attr_value::jsonb AS cidrblockassociationset,
  (isdefault.attr_value #>> '{}')::boolean AS isdefault,
  tags.attr_value::jsonb AS tags,
  
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN resource_attribute AS cidrblock
    ON cidrblock.resource_id = R.id
    AND cidrblock.type = 'provider'
    AND lower(cidrblock.attr_name) = 'cidrblock'
  LEFT JOIN resource_attribute AS dhcpoptionsid
    ON dhcpoptionsid.resource_id = R.id
    AND dhcpoptionsid.type = 'provider'
    AND lower(dhcpoptionsid.attr_name) = 'dhcpoptionsid'
  LEFT JOIN resource_attribute AS state
    ON state.resource_id = R.id
    AND state.type = 'provider'
    AND lower(state.attr_name) = 'state'
  LEFT JOIN resource_attribute AS vpcid
    ON vpcid.resource_id = R.id
    AND vpcid.type = 'provider'
    AND lower(vpcid.attr_name) = 'vpcid'
  LEFT JOIN resource_attribute AS ownerid
    ON ownerid.resource_id = R.id
    AND ownerid.type = 'provider'
    AND lower(ownerid.attr_name) = 'ownerid'
  LEFT JOIN resource_attribute AS instancetenancy
    ON instancetenancy.resource_id = R.id
    AND instancetenancy.type = 'provider'
    AND lower(instancetenancy.attr_name) = 'instancetenancy'
  LEFT JOIN resource_attribute AS ipv6cidrblockassociationset
    ON ipv6cidrblockassociationset.resource_id = R.id
    AND ipv6cidrblockassociationset.type = 'provider'
    AND lower(ipv6cidrblockassociationset.attr_name) = 'ipv6cidrblockassociationset'
  LEFT JOIN resource_attribute AS cidrblockassociationset
    ON cidrblockassociationset.resource_id = R.id
    AND cidrblockassociationset.type = 'provider'
    AND lower(cidrblockassociationset.attr_name) = 'cidrblockassociationset'
  LEFT JOIN resource_attribute AS isdefault
    ON isdefault.resource_id = R.id
    AND isdefault.type = 'provider'
    AND lower(isdefault.attr_name) = 'isdefault'
  LEFT JOIN resource_attribute AS tags
    ON tags.resource_id = R.id
    AND tags.type = 'provider'
    AND lower(tags.attr_name) = 'tags'
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
  AND LOWER(R.provider_type) = 'vpc'
  AND R.service = 'ec2'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_ec2_vpc;

COMMENT ON MATERIALIZED VIEW aws_ec2_vpc IS 'ec2 vpc resources and their associated attributes.';


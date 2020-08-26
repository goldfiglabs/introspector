DROP MATERIALIZED VIEW IF EXISTS aws_ec2_vpc CASCADE;

CREATE MATERIALIZED VIEW aws_ec2_vpc AS
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
  LEFT JOIN attrs AS cidrblock
    ON cidrblock.id = R.id
    AND cidrblock.attr_name = 'cidrblock'
  LEFT JOIN attrs AS dhcpoptionsid
    ON dhcpoptionsid.id = R.id
    AND dhcpoptionsid.attr_name = 'dhcpoptionsid'
  LEFT JOIN attrs AS state
    ON state.id = R.id
    AND state.attr_name = 'state'
  LEFT JOIN attrs AS vpcid
    ON vpcid.id = R.id
    AND vpcid.attr_name = 'vpcid'
  LEFT JOIN attrs AS ownerid
    ON ownerid.id = R.id
    AND ownerid.attr_name = 'ownerid'
  LEFT JOIN attrs AS instancetenancy
    ON instancetenancy.id = R.id
    AND instancetenancy.attr_name = 'instancetenancy'
  LEFT JOIN attrs AS ipv6cidrblockassociationset
    ON ipv6cidrblockassociationset.id = R.id
    AND ipv6cidrblockassociationset.attr_name = 'ipv6cidrblockassociationset'
  LEFT JOIN attrs AS cidrblockassociationset
    ON cidrblockassociationset.id = R.id
    AND cidrblockassociationset.attr_name = 'cidrblockassociationset'
  LEFT JOIN attrs AS isdefault
    ON isdefault.id = R.id
    AND isdefault.attr_name = 'isdefault'
  LEFT JOIN attrs AS tags
    ON tags.id = R.id
    AND tags.attr_name = 'tags'
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
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_ec2_vpc;

COMMENT ON MATERIALIZED VIEW aws_ec2_vpc IS 'ec2 vpc resources and their associated attributes.';


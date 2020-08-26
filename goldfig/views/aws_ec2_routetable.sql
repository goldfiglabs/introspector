DROP MATERIALIZED VIEW IF EXISTS aws_ec2_routetable CASCADE;

CREATE MATERIALIZED VIEW aws_ec2_routetable AS
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
  associations.attr_value::jsonb AS associations,
  propagatingvgws.attr_value::jsonb AS propagatingvgws,
  routetableid.attr_value #>> '{}' AS routetableid,
  routes.attr_value::jsonb AS routes,
  tags.attr_value::jsonb AS tags,
  vpcid.attr_value #>> '{}' AS vpcid,
  ownerid.attr_value #>> '{}' AS ownerid,
  
    _vpc_id.target_id AS _vpc_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN attrs AS associations
    ON associations.id = R.id
    AND associations.attr_name = 'associations'
  LEFT JOIN attrs AS propagatingvgws
    ON propagatingvgws.id = R.id
    AND propagatingvgws.attr_name = 'propagatingvgws'
  LEFT JOIN attrs AS routetableid
    ON routetableid.id = R.id
    AND routetableid.attr_name = 'routetableid'
  LEFT JOIN attrs AS routes
    ON routes.id = R.id
    AND routes.attr_name = 'routes'
  LEFT JOIN attrs AS tags
    ON tags.id = R.id
    AND tags.attr_name = 'tags'
  LEFT JOIN attrs AS vpcid
    ON vpcid.id = R.id
    AND vpcid.attr_name = 'vpcid'
  LEFT JOIN attrs AS ownerid
    ON ownerid.id = R.id
    AND ownerid.attr_name = 'ownerid'
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
      _aws_ec2_vpc_relation.relation = 'routes'
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
  AND LOWER(R.provider_type) = 'routetable'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_ec2_routetable;

COMMENT ON MATERIALIZED VIEW aws_ec2_routetable IS 'ec2 routetable resources and their associated attributes.';


INSERT INTO aws_ec2_routetable (
  _id,
  uri,
  provider_account_id,
  associations,
  propagatingvgws,
  routetableid,
  routes,
  tags,
  vpcid,
  ownerid,
  _tags,
  _vpc_id,_account_id
)
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  associations.attr_value::jsonb AS associations,
  propagatingvgws.attr_value::jsonb AS propagatingvgws,
  routetableid.attr_value #>> '{}' AS routetableid,
  routes.attr_value::jsonb AS routes,
  tags.attr_value::jsonb AS tags,
  vpcid.attr_value #>> '{}' AS vpcid,
  ownerid.attr_value #>> '{}' AS ownerid,
  _tags.attr_value::jsonb AS _tags,
  
    _vpc_id.target_id AS _vpc_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN resource_attribute AS associations
    ON associations.resource_id = R.id
    AND associations.type = 'provider'
    AND lower(associations.attr_name) = 'associations'
  LEFT JOIN resource_attribute AS propagatingvgws
    ON propagatingvgws.resource_id = R.id
    AND propagatingvgws.type = 'provider'
    AND lower(propagatingvgws.attr_name) = 'propagatingvgws'
  LEFT JOIN resource_attribute AS routetableid
    ON routetableid.resource_id = R.id
    AND routetableid.type = 'provider'
    AND lower(routetableid.attr_name) = 'routetableid'
  LEFT JOIN resource_attribute AS routes
    ON routes.resource_id = R.id
    AND routes.type = 'provider'
    AND lower(routes.attr_name) = 'routes'
  LEFT JOIN resource_attribute AS tags
    ON tags.resource_id = R.id
    AND tags.type = 'provider'
    AND lower(tags.attr_name) = 'tags'
  LEFT JOIN resource_attribute AS vpcid
    ON vpcid.resource_id = R.id
    AND vpcid.type = 'provider'
    AND lower(vpcid.attr_name) = 'vpcid'
  LEFT JOIN resource_attribute AS ownerid
    ON ownerid.resource_id = R.id
    AND ownerid.type = 'provider'
    AND lower(ownerid.attr_name) = 'ownerid'
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
      _aws_ec2_vpc_relation.relation = 'routes'
  ) AS _vpc_id ON _vpc_id.resource_id = R.id
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
  AND R.provider_type = 'RouteTable'
  AND R.service = 'ec2'
ON CONFLICT (_id) DO UPDATE
SET
    associations = EXCLUDED.associations,
    propagatingvgws = EXCLUDED.propagatingvgws,
    routetableid = EXCLUDED.routetableid,
    routes = EXCLUDED.routes,
    tags = EXCLUDED.tags,
    vpcid = EXCLUDED.vpcid,
    ownerid = EXCLUDED.ownerid,
    _tags = EXCLUDED._tags,
    _vpc_id = EXCLUDED._vpc_id,
    _account_id = EXCLUDED._account_id
  ;


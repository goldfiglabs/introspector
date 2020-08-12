DROP MATERIALIZED VIEW IF EXISTS aws_ec2_securitygroup CASCADE;

CREATE MATERIALIZED VIEW aws_ec2_securitygroup AS
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
  description.attr_value #>> '{}' AS description,
  groupname.attr_value #>> '{}' AS groupname,
  ippermissions.attr_value::jsonb AS ippermissions,
  ownerid.attr_value #>> '{}' AS ownerid,
  groupid.attr_value #>> '{}' AS groupid,
  ippermissionsegress.attr_value::jsonb AS ippermissionsegress,
  tags.attr_value::jsonb AS tags,
  vpcid.attr_value #>> '{}' AS vpcid,
  
    _vpc_id.target_id AS _vpc_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN attrs AS description
    ON description.id = R.id
    AND description.attr_name = 'description'
  LEFT JOIN attrs AS groupname
    ON groupname.id = R.id
    AND groupname.attr_name = 'groupname'
  LEFT JOIN attrs AS ippermissions
    ON ippermissions.id = R.id
    AND ippermissions.attr_name = 'ippermissions'
  LEFT JOIN attrs AS ownerid
    ON ownerid.id = R.id
    AND ownerid.attr_name = 'ownerid'
  LEFT JOIN attrs AS groupid
    ON groupid.id = R.id
    AND groupid.attr_name = 'groupid'
  LEFT JOIN attrs AS ippermissionsegress
    ON ippermissionsegress.id = R.id
    AND ippermissionsegress.attr_name = 'ippermissionsegress'
  LEFT JOIN attrs AS tags
    ON tags.id = R.id
    AND tags.attr_name = 'tags'
  LEFT JOIN attrs AS vpcid
    ON vpcid.id = R.id
    AND vpcid.attr_name = 'vpcid'
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
  AND LOWER(R.provider_type) = 'securitygroup'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_ec2_securitygroup;

COMMENT ON MATERIALIZED VIEW aws_ec2_securitygroup IS 'ec2 securitygroup resources and their associated attributes.';


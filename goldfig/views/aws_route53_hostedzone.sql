DROP MATERIALIZED VIEW IF EXISTS aws_route53_hostedzone CASCADE;

CREATE MATERIALIZED VIEW aws_route53_hostedzone AS
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
  id.attr_value #>> '{}' AS id,
  name.attr_value #>> '{}' AS name,
  callerreference.attr_value #>> '{}' AS callerreference,
  config.attr_value::jsonb AS config,
  (resourcerecordsetcount.attr_value #>> '{}')::bigint AS resourcerecordsetcount,
  linkedservice.attr_value::jsonb AS linkedservice,
  tags.attr_value::jsonb AS tags,
  resourcerecordsets.attr_value::jsonb AS resourcerecordsets,
  trafficpolicyinstances.attr_value::jsonb AS trafficpolicyinstances,
  vpcs.attr_value::jsonb AS vpcs,
  queryloggingconfigs.attr_value::jsonb AS queryloggingconfigs,
  
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN attrs AS id
    ON id.id = R.id
    AND id.attr_name = 'id'
  LEFT JOIN attrs AS name
    ON name.id = R.id
    AND name.attr_name = 'name'
  LEFT JOIN attrs AS callerreference
    ON callerreference.id = R.id
    AND callerreference.attr_name = 'callerreference'
  LEFT JOIN attrs AS config
    ON config.id = R.id
    AND config.attr_name = 'config'
  LEFT JOIN attrs AS resourcerecordsetcount
    ON resourcerecordsetcount.id = R.id
    AND resourcerecordsetcount.attr_name = 'resourcerecordsetcount'
  LEFT JOIN attrs AS linkedservice
    ON linkedservice.id = R.id
    AND linkedservice.attr_name = 'linkedservice'
  LEFT JOIN attrs AS tags
    ON tags.id = R.id
    AND tags.attr_name = 'tags'
  LEFT JOIN attrs AS resourcerecordsets
    ON resourcerecordsets.id = R.id
    AND resourcerecordsets.attr_name = 'resourcerecordsets'
  LEFT JOIN attrs AS trafficpolicyinstances
    ON trafficpolicyinstances.id = R.id
    AND trafficpolicyinstances.attr_name = 'trafficpolicyinstances'
  LEFT JOIN attrs AS vpcs
    ON vpcs.id = R.id
    AND vpcs.attr_name = 'vpcs'
  LEFT JOIN attrs AS queryloggingconfigs
    ON queryloggingconfigs.id = R.id
    AND queryloggingconfigs.attr_name = 'queryloggingconfigs'
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
  AND LOWER(R.provider_type) = 'hostedzone'
  AND R.service = 'route53'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_route53_hostedzone;

COMMENT ON MATERIALIZED VIEW aws_route53_hostedzone IS 'route53 hostedzone resources and their associated attributes.';



DROP MATERIALIZED VIEW IF EXISTS aws_route53_hostedzone_ec2_vpc CASCADE;

CREATE MATERIALIZED VIEW aws_route53_hostedzone_ec2_vpc AS
SELECT
  aws_route53_hostedzone.id AS hostedzone_id,
  aws_ec2_vpc.id AS vpc_id
FROM
  resource AS aws_route53_hostedzone
  INNER JOIN resource_relation AS RR
    ON RR.resource_id = aws_route53_hostedzone.id
    AND RR.relation = 'in'
  INNER JOIN resource AS aws_ec2_vpc
    ON aws_ec2_vpc.id = RR.target_id
    AND aws_ec2_vpc.provider_type = 'VPC'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_route53_hostedzone_ec2_vpc;

DROP MATERIALIZED VIEW IF EXISTS aws_route53_hostedzone CASCADE;

CREATE MATERIALIZED VIEW aws_route53_hostedzone AS
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
  LEFT JOIN resource_attribute AS id
    ON id.resource_id = R.id
    AND id.type = 'provider'
    AND lower(id.attr_name) = 'id'
  LEFT JOIN resource_attribute AS name
    ON name.resource_id = R.id
    AND name.type = 'provider'
    AND lower(name.attr_name) = 'name'
  LEFT JOIN resource_attribute AS callerreference
    ON callerreference.resource_id = R.id
    AND callerreference.type = 'provider'
    AND lower(callerreference.attr_name) = 'callerreference'
  LEFT JOIN resource_attribute AS config
    ON config.resource_id = R.id
    AND config.type = 'provider'
    AND lower(config.attr_name) = 'config'
  LEFT JOIN resource_attribute AS resourcerecordsetcount
    ON resourcerecordsetcount.resource_id = R.id
    AND resourcerecordsetcount.type = 'provider'
    AND lower(resourcerecordsetcount.attr_name) = 'resourcerecordsetcount'
  LEFT JOIN resource_attribute AS linkedservice
    ON linkedservice.resource_id = R.id
    AND linkedservice.type = 'provider'
    AND lower(linkedservice.attr_name) = 'linkedservice'
  LEFT JOIN resource_attribute AS tags
    ON tags.resource_id = R.id
    AND tags.type = 'provider'
    AND lower(tags.attr_name) = 'tags'
  LEFT JOIN resource_attribute AS resourcerecordsets
    ON resourcerecordsets.resource_id = R.id
    AND resourcerecordsets.type = 'provider'
    AND lower(resourcerecordsets.attr_name) = 'resourcerecordsets'
  LEFT JOIN resource_attribute AS trafficpolicyinstances
    ON trafficpolicyinstances.resource_id = R.id
    AND trafficpolicyinstances.type = 'provider'
    AND lower(trafficpolicyinstances.attr_name) = 'trafficpolicyinstances'
  LEFT JOIN resource_attribute AS vpcs
    ON vpcs.resource_id = R.id
    AND vpcs.type = 'provider'
    AND lower(vpcs.attr_name) = 'vpcs'
  LEFT JOIN resource_attribute AS queryloggingconfigs
    ON queryloggingconfigs.resource_id = R.id
    AND queryloggingconfigs.type = 'provider'
    AND lower(queryloggingconfigs.attr_name) = 'queryloggingconfigs'
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
  AND R.provider_type = 'HostedZone'
  AND R.service = 'route53'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_route53_hostedzone;

COMMENT ON MATERIALIZED VIEW aws_route53_hostedzone IS 'route53 HostedZone resources and their associated attributes.';



DROP MATERIALIZED VIEW IF EXISTS aws_route53_HostedZone_ec2_vpc CASCADE;

CREATE MATERIALIZED VIEW aws_route53_HostedZone_ec2_vpc AS
SELECT
  aws_route53_HostedZone.id AS HostedZone_id,
  aws_ec2_vpc.id AS vpc_id
FROM
  resource AS aws_route53_HostedZone
  INNER JOIN resource_relation AS RR
    ON RR.resource_id = aws_route53_HostedZone.id
    AND RR.relation = 'in'
  INNER JOIN resource AS aws_ec2_vpc
    ON aws_ec2_vpc.id = RR.target_id
    AND aws_ec2_vpc.provider_type = 'VPC'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_route53_HostedZone_ec2_vpc;

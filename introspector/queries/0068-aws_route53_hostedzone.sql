INSERT INTO aws_route53_hostedzone (
  _id,
  uri,
  provider_account_id,
  id,
  name,
  callerreference,
  config,
  resourcerecordsetcount,
  linkedservice,
  tags,
  resourcerecordsets,
  trafficpolicyinstances,
  vpcs,
  queryloggingconfigs,
  _tags,
  _account_id
)
SELECT
  R.id AS _id,
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
  _tags.attr_value::jsonb AS _tags,
  
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN resource_attribute AS id
    ON id.resource_id = R.id
    AND id.type = 'provider'
    AND lower(id.attr_name) = 'id'
    AND id.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS name
    ON name.resource_id = R.id
    AND name.type = 'provider'
    AND lower(name.attr_name) = 'name'
    AND name.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS callerreference
    ON callerreference.resource_id = R.id
    AND callerreference.type = 'provider'
    AND lower(callerreference.attr_name) = 'callerreference'
    AND callerreference.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS config
    ON config.resource_id = R.id
    AND config.type = 'provider'
    AND lower(config.attr_name) = 'config'
    AND config.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS resourcerecordsetcount
    ON resourcerecordsetcount.resource_id = R.id
    AND resourcerecordsetcount.type = 'provider'
    AND lower(resourcerecordsetcount.attr_name) = 'resourcerecordsetcount'
    AND resourcerecordsetcount.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS linkedservice
    ON linkedservice.resource_id = R.id
    AND linkedservice.type = 'provider'
    AND lower(linkedservice.attr_name) = 'linkedservice'
    AND linkedservice.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS tags
    ON tags.resource_id = R.id
    AND tags.type = 'provider'
    AND lower(tags.attr_name) = 'tags'
    AND tags.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS resourcerecordsets
    ON resourcerecordsets.resource_id = R.id
    AND resourcerecordsets.type = 'provider'
    AND lower(resourcerecordsets.attr_name) = 'resourcerecordsets'
    AND resourcerecordsets.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS trafficpolicyinstances
    ON trafficpolicyinstances.resource_id = R.id
    AND trafficpolicyinstances.type = 'provider'
    AND lower(trafficpolicyinstances.attr_name) = 'trafficpolicyinstances'
    AND trafficpolicyinstances.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS vpcs
    ON vpcs.resource_id = R.id
    AND vpcs.type = 'provider'
    AND lower(vpcs.attr_name) = 'vpcs'
    AND vpcs.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS queryloggingconfigs
    ON queryloggingconfigs.resource_id = R.id
    AND queryloggingconfigs.type = 'provider'
    AND lower(queryloggingconfigs.attr_name) = 'queryloggingconfigs'
    AND queryloggingconfigs.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS _tags
    ON _tags.resource_id = R.id
    AND _tags.type = 'Metadata'
    AND lower(_tags.attr_name) = 'tags'
    AND _tags.provider_account_id = R.provider_account_id
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
        AND _aws_organizations_account_relation.provider_account_id = :provider_account_id
      GROUP BY _aws_organizations_account_relation.resource_id
      HAVING COUNT(*) = 1
    ) AS unique_account_mapping
    INNER JOIN resource_relation AS _aws_organizations_account_relation
      ON _aws_organizations_account_relation.resource_id = unique_account_mapping.resource_id
    INNER JOIN resource AS _aws_organizations_account
      ON _aws_organizations_account_relation.target_id = _aws_organizations_account.id
      AND _aws_organizations_account.provider_type = 'Account'
      AND _aws_organizations_account.service = 'organizations'
      AND _aws_organizations_account_relation.provider_account_id = :provider_account_id
    WHERE
        _aws_organizations_account_relation.relation = 'in'
        AND _aws_organizations_account_relation.provider_account_id = :provider_account_id
  ) AS _account_id ON _account_id.resource_id = R.id
  WHERE
  R.provider_account_id = :provider_account_id
  AND PA.provider = 'aws'
  AND R.provider_type = 'HostedZone'
  AND R.service = 'route53'
ON CONFLICT (_id) DO UPDATE
SET
    id = EXCLUDED.id,
    name = EXCLUDED.name,
    callerreference = EXCLUDED.callerreference,
    config = EXCLUDED.config,
    resourcerecordsetcount = EXCLUDED.resourcerecordsetcount,
    linkedservice = EXCLUDED.linkedservice,
    tags = EXCLUDED.tags,
    resourcerecordsets = EXCLUDED.resourcerecordsets,
    trafficpolicyinstances = EXCLUDED.trafficpolicyinstances,
    vpcs = EXCLUDED.vpcs,
    queryloggingconfigs = EXCLUDED.queryloggingconfigs,
    _tags = EXCLUDED._tags,
    _account_id = EXCLUDED._account_id
  ;



INSERT INTO aws_route53_hostedzone_ec2_vpc
SELECT
  aws_route53_hostedzone.id AS hostedzone_id,
  aws_ec2_vpc.id AS vpc_id,
  aws_route53_hostedzone.provider_account_id AS provider_account_id
FROM
  resource AS aws_route53_hostedzone
  INNER JOIN resource_relation AS RR
    ON RR.resource_id = aws_route53_hostedzone.id
    AND RR.relation = 'in'
  INNER JOIN resource AS aws_ec2_vpc
    ON aws_ec2_vpc.id = RR.target_id
    AND aws_ec2_vpc.provider_type = 'VPC'
    AND aws_ec2_vpc.service = 'ec2'
  WHERE
    aws_route53_hostedzone.provider_type = 'HostedZone'
    AND aws_route53_hostedzone.service = 'route53'
ON CONFLICT (hostedzone_id, vpc_id)
DO NOTHING
;

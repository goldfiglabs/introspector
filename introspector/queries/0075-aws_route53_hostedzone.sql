WITH attrs AS (
  SELECT
    resource_id,
    jsonb_object_agg(attr_name, attr_value) FILTER (WHERE type = 'provider') AS provider,
    jsonb_object_agg(attr_name, attr_value) FILTER (WHERE type = 'Metadata') AS metadata
  FROM
    resource_attribute
  WHERE
    provider_account_id = :provider_account_id
  GROUP BY resource_id
)
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
  attrs.provider ->> 'Id' AS id,
  attrs.provider ->> 'Name' AS name,
  attrs.provider ->> 'CallerReference' AS callerreference,
  attrs.provider -> 'Config' AS config,
  (attrs.provider ->> 'ResourceRecordSetCount')::bigint AS resourcerecordsetcount,
  attrs.provider -> 'LinkedService' AS linkedservice,
  attrs.provider -> 'Tags' AS tags,
  attrs.provider -> 'ResourceRecordSets' AS resourcerecordsets,
  attrs.provider -> 'TrafficPolicyInstances' AS trafficpolicyinstances,
  attrs.provider -> 'VPCs' AS vpcs,
  attrs.provider -> 'QueryLoggingConfigs' AS queryloggingconfigs,
  attrs.metadata -> 'Tags' AS tags,
  
    _account_id.target_id AS _account_id
FROM
  resource AS R
  LEFT JOIN attrs ON
    attrs.resource_id = R.id
  LEFT JOIN (
    SELECT
      unique_account_mapping.resource_id,
      unique_account_mapping.target_ids[1] as target_id
    FROM
      (
        SELECT
          ARRAY_AGG(_aws_organizations_account_relation.target_id) AS target_ids,
          _aws_organizations_account_relation.resource_id
        FROM
          resource AS _aws_organizations_account
          INNER JOIN resource_relation AS _aws_organizations_account_relation
            ON _aws_organizations_account_relation.target_id = _aws_organizations_account.id
        WHERE
          _aws_organizations_account.provider_type = 'Account'
          AND _aws_organizations_account.service = 'organizations'
          AND _aws_organizations_account.provider_account_id = :provider_account_id
          AND _aws_organizations_account_relation.relation = 'in'
          AND _aws_organizations_account_relation.provider_account_id = :provider_account_id
        GROUP BY _aws_organizations_account_relation.resource_id
        HAVING COUNT(*) = 1
      ) AS unique_account_mapping
  ) AS _account_id ON _account_id.resource_id = R.id
  WHERE
  R.provider_account_id = :provider_account_id
  AND R.provider_type = 'HostedZone'
  AND R.service = 'route53'
ON CONFLICT (_id) DO UPDATE
SET
    Id = EXCLUDED.Id,
    Name = EXCLUDED.Name,
    CallerReference = EXCLUDED.CallerReference,
    Config = EXCLUDED.Config,
    ResourceRecordSetCount = EXCLUDED.ResourceRecordSetCount,
    LinkedService = EXCLUDED.LinkedService,
    Tags = EXCLUDED.Tags,
    ResourceRecordSets = EXCLUDED.ResourceRecordSets,
    TrafficPolicyInstances = EXCLUDED.TrafficPolicyInstances,
    VPCs = EXCLUDED.VPCs,
    QueryLoggingConfigs = EXCLUDED.QueryLoggingConfigs,
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
    AND aws_ec2_vpc.provider_account_id = :provider_account_id
  WHERE
    aws_route53_hostedzone.provider_account_id = :provider_account_id
    AND aws_route53_hostedzone.provider_type = 'HostedZone'
    AND aws_route53_hostedzone.service = 'route53'
ON CONFLICT (hostedzone_id, vpc_id)
DO NOTHING
;

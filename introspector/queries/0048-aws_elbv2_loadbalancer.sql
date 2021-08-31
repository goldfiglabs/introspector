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
INSERT INTO aws_elbv2_loadbalancer (
  _id,
  uri,
  provider_account_id,
  loadbalancerarn,
  dnsname,
  canonicalhostedzoneid,
  createdtime,
  loadbalancername,
  scheme,
  vpcid,
  state,
  type,
  availabilityzones,
  securitygroups,
  ipaddresstype,
  customerownedipv4pool,
  tags,
  access_logs_s3_enabled,
  access_logs_s3_bucket,
  access_logs_s3_prefix,
  deletion_protection_enabled,
  idle_timeout_timeout_seconds,
  routing_http_desync_mitigation_mode,
  routing_http_drop_invalid_header_fields_enabled,
  routing_http2_enabled,
  load_balancing_cross_zone_enabled,
  _tags,
  _ec2_vpc_id,_account_id
)
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  attrs.provider ->> 'LoadBalancerArn' AS loadbalancerarn,
  attrs.provider ->> 'DNSName' AS dnsname,
  attrs.provider ->> 'CanonicalHostedZoneId' AS canonicalhostedzoneid,
  (TO_TIMESTAMP(attrs.provider ->> 'CreatedTime', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS createdtime,
  attrs.provider ->> 'LoadBalancerName' AS loadbalancername,
  attrs.provider ->> 'Scheme' AS scheme,
  attrs.provider ->> 'VpcId' AS vpcid,
  attrs.provider -> 'State' AS state,
  attrs.provider ->> 'Type' AS type,
  attrs.provider -> 'AvailabilityZones' AS availabilityzones,
  attrs.provider -> 'SecurityGroups' AS securitygroups,
  attrs.provider ->> 'IpAddressType' AS ipaddresstype,
  attrs.provider ->> 'CustomerOwnedIpv4Pool' AS customerownedipv4pool,
  attrs.provider -> 'Tags' AS tags,
  (attrs.provider ->> 'access_logs_s3_enabled')::boolean AS access_logs_s3_enabled,
  attrs.provider ->> 'access_logs_s3_bucket' AS access_logs_s3_bucket,
  attrs.provider ->> 'access_logs_s3_prefix' AS access_logs_s3_prefix,
  (attrs.provider ->> 'deletion_protection_enabled')::boolean AS deletion_protection_enabled,
  (attrs.provider ->> 'idle_timeout_timeout_seconds')::integer AS idle_timeout_timeout_seconds,
  attrs.provider ->> 'routing_http_desync_mitigation_mode' AS routing_http_desync_mitigation_mode,
  (attrs.provider ->> 'routing_http_drop_invalid_header_fields_enabled')::boolean AS routing_http_drop_invalid_header_fields_enabled,
  (attrs.provider ->> 'routing_http2_enabled')::boolean AS routing_http2_enabled,
  (attrs.provider ->> 'load_balancing_cross_zone_enabled')::boolean AS load_balancing_cross_zone_enabled,
  attrs.metadata -> 'Tags' AS tags,
  
    _ec2_vpc_id.target_id AS _ec2_vpc_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  LEFT JOIN attrs ON
    attrs.resource_id = R.id
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
        AND _aws_ec2_vpc.provider_account_id = :provider_account_id
    WHERE
      _aws_ec2_vpc_relation.relation = 'in'
      AND _aws_ec2_vpc_relation.provider_account_id = :provider_account_id
  ) AS _ec2_vpc_id ON _ec2_vpc_id.resource_id = R.id
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
  AND R.provider_type = 'LoadBalancer'
  AND R.service = 'elbv2'
ON CONFLICT (_id) DO UPDATE
SET
    LoadBalancerArn = EXCLUDED.LoadBalancerArn,
    DNSName = EXCLUDED.DNSName,
    CanonicalHostedZoneId = EXCLUDED.CanonicalHostedZoneId,
    CreatedTime = EXCLUDED.CreatedTime,
    LoadBalancerName = EXCLUDED.LoadBalancerName,
    Scheme = EXCLUDED.Scheme,
    VpcId = EXCLUDED.VpcId,
    State = EXCLUDED.State,
    Type = EXCLUDED.Type,
    AvailabilityZones = EXCLUDED.AvailabilityZones,
    SecurityGroups = EXCLUDED.SecurityGroups,
    IpAddressType = EXCLUDED.IpAddressType,
    CustomerOwnedIpv4Pool = EXCLUDED.CustomerOwnedIpv4Pool,
    Tags = EXCLUDED.Tags,
    access_logs_s3_enabled = EXCLUDED.access_logs_s3_enabled,
    access_logs_s3_bucket = EXCLUDED.access_logs_s3_bucket,
    access_logs_s3_prefix = EXCLUDED.access_logs_s3_prefix,
    deletion_protection_enabled = EXCLUDED.deletion_protection_enabled,
    idle_timeout_timeout_seconds = EXCLUDED.idle_timeout_timeout_seconds,
    routing_http_desync_mitigation_mode = EXCLUDED.routing_http_desync_mitigation_mode,
    routing_http_drop_invalid_header_fields_enabled = EXCLUDED.routing_http_drop_invalid_header_fields_enabled,
    routing_http2_enabled = EXCLUDED.routing_http2_enabled,
    load_balancing_cross_zone_enabled = EXCLUDED.load_balancing_cross_zone_enabled,
    _tags = EXCLUDED._tags,
    _ec2_vpc_id = EXCLUDED._ec2_vpc_id,
    _account_id = EXCLUDED._account_id
  ;



INSERT INTO aws_elbv2_loadbalancer_ec2_securitygroup
SELECT
  aws_elbv2_loadbalancer.id AS loadbalancer_id,
  aws_ec2_securitygroup.id AS securitygroup_id,
  aws_elbv2_loadbalancer.provider_account_id AS provider_account_id
FROM
  resource AS aws_elbv2_loadbalancer
  INNER JOIN resource_relation AS RR
    ON RR.resource_id = aws_elbv2_loadbalancer.id
    AND RR.relation = 'in'
  INNER JOIN resource AS aws_ec2_securitygroup
    ON aws_ec2_securitygroup.id = RR.target_id
    AND aws_ec2_securitygroup.provider_type = 'SecurityGroup'
    AND aws_ec2_securitygroup.service = 'ec2'
    AND aws_ec2_securitygroup.provider_account_id = :provider_account_id
  WHERE
    aws_elbv2_loadbalancer.provider_account_id = :provider_account_id
    AND aws_elbv2_loadbalancer.provider_type = 'LoadBalancer'
    AND aws_elbv2_loadbalancer.service = 'elbv2'
ON CONFLICT (loadbalancer_id, securitygroup_id)
DO NOTHING
;

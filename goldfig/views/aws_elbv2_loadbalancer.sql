DROP MATERIALIZED VIEW IF EXISTS aws_elbv2_loadbalancer CASCADE;

CREATE MATERIALIZED VIEW aws_elbv2_loadbalancer AS
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
  loadbalancerarn.attr_value #>> '{}' AS loadbalancerarn,
  dnsname.attr_value #>> '{}' AS dnsname,
  canonicalhostedzoneid.attr_value #>> '{}' AS canonicalhostedzoneid,
  (TO_TIMESTAMP(createdtime.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS createdtime,
  loadbalancername.attr_value #>> '{}' AS loadbalancername,
  scheme.attr_value #>> '{}' AS scheme,
  vpcid.attr_value #>> '{}' AS vpcid,
  state.attr_value::jsonb AS state,
  type.attr_value #>> '{}' AS type,
  availabilityzones.attr_value::jsonb AS availabilityzones,
  securitygroups.attr_value::jsonb AS securitygroups,
  ipaddresstype.attr_value #>> '{}' AS ipaddresstype,
  tags.attr_value::jsonb AS tags,
  (access_logs_s3_enabled.attr_value #>> '{}')::boolean AS access_logs_s3_enabled,
  access_logs_s3_bucket.attr_value #>> '{}' AS access_logs_s3_bucket,
  access_logs_s3_prefix.attr_value #>> '{}' AS access_logs_s3_prefix,
  (deletion_protection_enabled.attr_value #>> '{}')::boolean AS deletion_protection_enabled,
  (idle_timeout_timeout_seconds.attr_value #>> '{}')::integer AS idle_timeout_timeout_seconds,
  routing_http_desync_mitigation_mode.attr_value #>> '{}' AS routing_http_desync_mitigation_mode,
  (routing_http_drop_invalid_header_fields_enabled.attr_value #>> '{}')::boolean AS routing_http_drop_invalid_header_fields_enabled,
  (routing_http2_enabled.attr_value #>> '{}')::boolean AS routing_http2_enabled,
  (load_balancing_cross_zone_enabled.attr_value #>> '{}')::boolean AS load_balancing_cross_zone_enabled,
  
    _ec2_vpc_id.target_id AS _ec2_vpc_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN attrs AS loadbalancerarn
    ON loadbalancerarn.id = R.id
    AND loadbalancerarn.attr_name = 'loadbalancerarn'
  LEFT JOIN attrs AS dnsname
    ON dnsname.id = R.id
    AND dnsname.attr_name = 'dnsname'
  LEFT JOIN attrs AS canonicalhostedzoneid
    ON canonicalhostedzoneid.id = R.id
    AND canonicalhostedzoneid.attr_name = 'canonicalhostedzoneid'
  LEFT JOIN attrs AS createdtime
    ON createdtime.id = R.id
    AND createdtime.attr_name = 'createdtime'
  LEFT JOIN attrs AS loadbalancername
    ON loadbalancername.id = R.id
    AND loadbalancername.attr_name = 'loadbalancername'
  LEFT JOIN attrs AS scheme
    ON scheme.id = R.id
    AND scheme.attr_name = 'scheme'
  LEFT JOIN attrs AS vpcid
    ON vpcid.id = R.id
    AND vpcid.attr_name = 'vpcid'
  LEFT JOIN attrs AS state
    ON state.id = R.id
    AND state.attr_name = 'state'
  LEFT JOIN attrs AS type
    ON type.id = R.id
    AND type.attr_name = 'type'
  LEFT JOIN attrs AS availabilityzones
    ON availabilityzones.id = R.id
    AND availabilityzones.attr_name = 'availabilityzones'
  LEFT JOIN attrs AS securitygroups
    ON securitygroups.id = R.id
    AND securitygroups.attr_name = 'securitygroups'
  LEFT JOIN attrs AS ipaddresstype
    ON ipaddresstype.id = R.id
    AND ipaddresstype.attr_name = 'ipaddresstype'
  LEFT JOIN attrs AS tags
    ON tags.id = R.id
    AND tags.attr_name = 'tags'
  LEFT JOIN attrs AS access_logs_s3_enabled
    ON access_logs_s3_enabled.id = R.id
    AND access_logs_s3_enabled.attr_name = 'access_logs_s3_enabled'
  LEFT JOIN attrs AS access_logs_s3_bucket
    ON access_logs_s3_bucket.id = R.id
    AND access_logs_s3_bucket.attr_name = 'access_logs_s3_bucket'
  LEFT JOIN attrs AS access_logs_s3_prefix
    ON access_logs_s3_prefix.id = R.id
    AND access_logs_s3_prefix.attr_name = 'access_logs_s3_prefix'
  LEFT JOIN attrs AS deletion_protection_enabled
    ON deletion_protection_enabled.id = R.id
    AND deletion_protection_enabled.attr_name = 'deletion_protection_enabled'
  LEFT JOIN attrs AS idle_timeout_timeout_seconds
    ON idle_timeout_timeout_seconds.id = R.id
    AND idle_timeout_timeout_seconds.attr_name = 'idle_timeout_timeout_seconds'
  LEFT JOIN attrs AS routing_http_desync_mitigation_mode
    ON routing_http_desync_mitigation_mode.id = R.id
    AND routing_http_desync_mitigation_mode.attr_name = 'routing_http_desync_mitigation_mode'
  LEFT JOIN attrs AS routing_http_drop_invalid_header_fields_enabled
    ON routing_http_drop_invalid_header_fields_enabled.id = R.id
    AND routing_http_drop_invalid_header_fields_enabled.attr_name = 'routing_http_drop_invalid_header_fields_enabled'
  LEFT JOIN attrs AS routing_http2_enabled
    ON routing_http2_enabled.id = R.id
    AND routing_http2_enabled.attr_name = 'routing_http2_enabled'
  LEFT JOIN attrs AS load_balancing_cross_zone_enabled
    ON load_balancing_cross_zone_enabled.id = R.id
    AND load_balancing_cross_zone_enabled.attr_name = 'load_balancing_cross_zone_enabled'
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
  ) AS _ec2_vpc_id ON _ec2_vpc_id.resource_id = R.id
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
  AND LOWER(R.provider_type) = 'loadbalancer'
  AND R.service = 'elbv2'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_elbv2_loadbalancer;

COMMENT ON MATERIALIZED VIEW aws_elbv2_loadbalancer IS 'elbv2 loadbalancer resources and their associated attributes.';



DROP MATERIALIZED VIEW IF EXISTS aws_elbv2_loadbalancer_ec2_securitygroup CASCADE;

CREATE MATERIALIZED VIEW aws_elbv2_loadbalancer_ec2_securitygroup AS
SELECT
  aws_elbv2_loadbalancer.id AS loadbalancer_id,
  aws_ec2_securitygroup.id AS securitygroup_id
FROM
  resource AS aws_elbv2_loadbalancer
  INNER JOIN resource_relation AS RR
    ON RR.resource_id = aws_elbv2_loadbalancer.id
    AND RR.relation = 'in'
  INNER JOIN resource AS aws_ec2_securitygroup
    ON aws_ec2_securitygroup.id = RR.target_id
    AND aws_ec2_securitygroup.provider_type = 'SecurityGroup'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_elbv2_loadbalancer_ec2_securitygroup;

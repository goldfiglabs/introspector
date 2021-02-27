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
  customerownedipv4pool.attr_value #>> '{}' AS customerownedipv4pool,
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
  _tags.attr_value::jsonb AS _tags,

    _ec2_vpc_id.target_id AS _ec2_vpc_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN resource_attribute AS loadbalancerarn
    ON loadbalancerarn.resource_id = R.id
    AND loadbalancerarn.type = 'provider'
    AND lower(loadbalancerarn.attr_name) = 'loadbalancerarn'
  LEFT JOIN resource_attribute AS dnsname
    ON dnsname.resource_id = R.id
    AND dnsname.type = 'provider'
    AND lower(dnsname.attr_name) = 'dnsname'
  LEFT JOIN resource_attribute AS canonicalhostedzoneid
    ON canonicalhostedzoneid.resource_id = R.id
    AND canonicalhostedzoneid.type = 'provider'
    AND lower(canonicalhostedzoneid.attr_name) = 'canonicalhostedzoneid'
  LEFT JOIN resource_attribute AS createdtime
    ON createdtime.resource_id = R.id
    AND createdtime.type = 'provider'
    AND lower(createdtime.attr_name) = 'createdtime'
  LEFT JOIN resource_attribute AS loadbalancername
    ON loadbalancername.resource_id = R.id
    AND loadbalancername.type = 'provider'
    AND lower(loadbalancername.attr_name) = 'loadbalancername'
  LEFT JOIN resource_attribute AS scheme
    ON scheme.resource_id = R.id
    AND scheme.type = 'provider'
    AND lower(scheme.attr_name) = 'scheme'
  LEFT JOIN resource_attribute AS vpcid
    ON vpcid.resource_id = R.id
    AND vpcid.type = 'provider'
    AND lower(vpcid.attr_name) = 'vpcid'
  LEFT JOIN resource_attribute AS state
    ON state.resource_id = R.id
    AND state.type = 'provider'
    AND lower(state.attr_name) = 'state'
  LEFT JOIN resource_attribute AS type
    ON type.resource_id = R.id
    AND type.type = 'provider'
    AND lower(type.attr_name) = 'type'
  LEFT JOIN resource_attribute AS availabilityzones
    ON availabilityzones.resource_id = R.id
    AND availabilityzones.type = 'provider'
    AND lower(availabilityzones.attr_name) = 'availabilityzones'
  LEFT JOIN resource_attribute AS securitygroups
    ON securitygroups.resource_id = R.id
    AND securitygroups.type = 'provider'
    AND lower(securitygroups.attr_name) = 'securitygroups'
  LEFT JOIN resource_attribute AS ipaddresstype
    ON ipaddresstype.resource_id = R.id
    AND ipaddresstype.type = 'provider'
    AND lower(ipaddresstype.attr_name) = 'ipaddresstype'
  LEFT JOIN resource_attribute AS customerownedipv4pool
    ON customerownedipv4pool.resource_id = R.id
    AND customerownedipv4pool.type = 'provider'
    AND lower(customerownedipv4pool.attr_name) = 'customerownedipv4pool'
  LEFT JOIN resource_attribute AS tags
    ON tags.resource_id = R.id
    AND tags.type = 'provider'
    AND lower(tags.attr_name) = 'tags'
  LEFT JOIN resource_attribute AS access_logs_s3_enabled
    ON access_logs_s3_enabled.resource_id = R.id
    AND access_logs_s3_enabled.type = 'provider'
    AND lower(access_logs_s3_enabled.attr_name) = 'access_logs_s3_enabled'
  LEFT JOIN resource_attribute AS access_logs_s3_bucket
    ON access_logs_s3_bucket.resource_id = R.id
    AND access_logs_s3_bucket.type = 'provider'
    AND lower(access_logs_s3_bucket.attr_name) = 'access_logs_s3_bucket'
  LEFT JOIN resource_attribute AS access_logs_s3_prefix
    ON access_logs_s3_prefix.resource_id = R.id
    AND access_logs_s3_prefix.type = 'provider'
    AND lower(access_logs_s3_prefix.attr_name) = 'access_logs_s3_prefix'
  LEFT JOIN resource_attribute AS deletion_protection_enabled
    ON deletion_protection_enabled.resource_id = R.id
    AND deletion_protection_enabled.type = 'provider'
    AND lower(deletion_protection_enabled.attr_name) = 'deletion_protection_enabled'
  LEFT JOIN resource_attribute AS idle_timeout_timeout_seconds
    ON idle_timeout_timeout_seconds.resource_id = R.id
    AND idle_timeout_timeout_seconds.type = 'provider'
    AND lower(idle_timeout_timeout_seconds.attr_name) = 'idle_timeout_timeout_seconds'
  LEFT JOIN resource_attribute AS routing_http_desync_mitigation_mode
    ON routing_http_desync_mitigation_mode.resource_id = R.id
    AND routing_http_desync_mitigation_mode.type = 'provider'
    AND lower(routing_http_desync_mitigation_mode.attr_name) = 'routing_http_desync_mitigation_mode'
  LEFT JOIN resource_attribute AS routing_http_drop_invalid_header_fields_enabled
    ON routing_http_drop_invalid_header_fields_enabled.resource_id = R.id
    AND routing_http_drop_invalid_header_fields_enabled.type = 'provider'
    AND lower(routing_http_drop_invalid_header_fields_enabled.attr_name) = 'routing_http_drop_invalid_header_fields_enabled'
  LEFT JOIN resource_attribute AS routing_http2_enabled
    ON routing_http2_enabled.resource_id = R.id
    AND routing_http2_enabled.type = 'provider'
    AND lower(routing_http2_enabled.attr_name) = 'routing_http2_enabled'
  LEFT JOIN resource_attribute AS load_balancing_cross_zone_enabled
    ON load_balancing_cross_zone_enabled.resource_id = R.id
    AND load_balancing_cross_zone_enabled.type = 'provider'
    AND lower(load_balancing_cross_zone_enabled.attr_name) = 'load_balancing_cross_zone_enabled'
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
  AND R.provider_type = 'LoadBalancer'
  AND R.service = 'elbv2'
ON CONFLICT (_id) DO UPDATE
SET
    loadbalancerarn = EXCLUDED.loadbalancerarn,
    dnsname = EXCLUDED.dnsname,
    canonicalhostedzoneid = EXCLUDED.canonicalhostedzoneid,
    createdtime = EXCLUDED.createdtime,
    loadbalancername = EXCLUDED.loadbalancername,
    scheme = EXCLUDED.scheme,
    vpcid = EXCLUDED.vpcid,
    state = EXCLUDED.state,
    type = EXCLUDED.type,
    availabilityzones = EXCLUDED.availabilityzones,
    securitygroups = EXCLUDED.securitygroups,
    ipaddresstype = EXCLUDED.ipaddresstype,
    customerownedipv4pool = EXCLUDED.customerownedipv4pool,
    tags = EXCLUDED.tags,
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
  WHERE
    aws_elbv2_loadbalancer.provider_type = 'LoadBalancer'
    AND aws_elbv2_loadbalancer.service = 'elbv2'
ON CONFLICT (loadbalancer_id, securitygroup_id)
DO NOTHING
;

DROP MATERIALIZED VIEW IF EXISTS aws_elbv2_targetgroup CASCADE;

CREATE MATERIALIZED VIEW aws_elbv2_targetgroup AS
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
  targetgrouparn.attr_value #>> '{}' AS targetgrouparn,
  targetgroupname.attr_value #>> '{}' AS targetgroupname,
  protocol.attr_value #>> '{}' AS protocol,
  (port.attr_value #>> '{}')::integer AS port,
  vpcid.attr_value #>> '{}' AS vpcid,
  healthcheckprotocol.attr_value #>> '{}' AS healthcheckprotocol,
  healthcheckport.attr_value #>> '{}' AS healthcheckport,
  (healthcheckenabled.attr_value #>> '{}')::boolean AS healthcheckenabled,
  (healthcheckintervalseconds.attr_value #>> '{}')::integer AS healthcheckintervalseconds,
  (healthchecktimeoutseconds.attr_value #>> '{}')::integer AS healthchecktimeoutseconds,
  (healthythresholdcount.attr_value #>> '{}')::integer AS healthythresholdcount,
  (unhealthythresholdcount.attr_value #>> '{}')::integer AS unhealthythresholdcount,
  healthcheckpath.attr_value #>> '{}' AS healthcheckpath,
  matcher.attr_value::jsonb AS matcher,
  loadbalancerarns.attr_value::jsonb AS loadbalancerarns,
  targettype.attr_value #>> '{}' AS targettype,
  tags.attr_value::jsonb AS tags,
  (deregistration_delay_timeout_seconds.attr_value #>> '{}')::integer AS deregistration_delay_timeout_seconds,
  (stickiness_enabled.attr_value #>> '{}')::boolean AS stickiness_enabled,
  stickiness_type.attr_value #>> '{}' AS stickiness_type,
  load_balancing_algorithm_type.attr_value #>> '{}' AS load_balancing_algorithm_type,
  (slow_start_duration_seconds.attr_value #>> '{}')::integer AS slow_start_duration_seconds,
  (stickiness_lb_cookie_duration_seconds.attr_value #>> '{}')::integer AS stickiness_lb_cookie_duration_seconds,
  (lambda_multi_value_headers_enabled.attr_value #>> '{}')::boolean AS lambda_multi_value_headers_enabled,
  (proxy_protocol_v2_enabled.attr_value #>> '{}')::boolean AS proxy_protocol_v2_enabled,
  
    _ec2_vpc_id.target_id AS _ec2_vpc_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN attrs AS targetgrouparn
    ON targetgrouparn.id = R.id
    AND targetgrouparn.attr_name = 'targetgrouparn'
  LEFT JOIN attrs AS targetgroupname
    ON targetgroupname.id = R.id
    AND targetgroupname.attr_name = 'targetgroupname'
  LEFT JOIN attrs AS protocol
    ON protocol.id = R.id
    AND protocol.attr_name = 'protocol'
  LEFT JOIN attrs AS port
    ON port.id = R.id
    AND port.attr_name = 'port'
  LEFT JOIN attrs AS vpcid
    ON vpcid.id = R.id
    AND vpcid.attr_name = 'vpcid'
  LEFT JOIN attrs AS healthcheckprotocol
    ON healthcheckprotocol.id = R.id
    AND healthcheckprotocol.attr_name = 'healthcheckprotocol'
  LEFT JOIN attrs AS healthcheckport
    ON healthcheckport.id = R.id
    AND healthcheckport.attr_name = 'healthcheckport'
  LEFT JOIN attrs AS healthcheckenabled
    ON healthcheckenabled.id = R.id
    AND healthcheckenabled.attr_name = 'healthcheckenabled'
  LEFT JOIN attrs AS healthcheckintervalseconds
    ON healthcheckintervalseconds.id = R.id
    AND healthcheckintervalseconds.attr_name = 'healthcheckintervalseconds'
  LEFT JOIN attrs AS healthchecktimeoutseconds
    ON healthchecktimeoutseconds.id = R.id
    AND healthchecktimeoutseconds.attr_name = 'healthchecktimeoutseconds'
  LEFT JOIN attrs AS healthythresholdcount
    ON healthythresholdcount.id = R.id
    AND healthythresholdcount.attr_name = 'healthythresholdcount'
  LEFT JOIN attrs AS unhealthythresholdcount
    ON unhealthythresholdcount.id = R.id
    AND unhealthythresholdcount.attr_name = 'unhealthythresholdcount'
  LEFT JOIN attrs AS healthcheckpath
    ON healthcheckpath.id = R.id
    AND healthcheckpath.attr_name = 'healthcheckpath'
  LEFT JOIN attrs AS matcher
    ON matcher.id = R.id
    AND matcher.attr_name = 'matcher'
  LEFT JOIN attrs AS loadbalancerarns
    ON loadbalancerarns.id = R.id
    AND loadbalancerarns.attr_name = 'loadbalancerarns'
  LEFT JOIN attrs AS targettype
    ON targettype.id = R.id
    AND targettype.attr_name = 'targettype'
  LEFT JOIN attrs AS tags
    ON tags.id = R.id
    AND tags.attr_name = 'tags'
  LEFT JOIN attrs AS deregistration_delay_timeout_seconds
    ON deregistration_delay_timeout_seconds.id = R.id
    AND deregistration_delay_timeout_seconds.attr_name = 'deregistration_delay_timeout_seconds'
  LEFT JOIN attrs AS stickiness_enabled
    ON stickiness_enabled.id = R.id
    AND stickiness_enabled.attr_name = 'stickiness_enabled'
  LEFT JOIN attrs AS stickiness_type
    ON stickiness_type.id = R.id
    AND stickiness_type.attr_name = 'stickiness_type'
  LEFT JOIN attrs AS load_balancing_algorithm_type
    ON load_balancing_algorithm_type.id = R.id
    AND load_balancing_algorithm_type.attr_name = 'load_balancing_algorithm_type'
  LEFT JOIN attrs AS slow_start_duration_seconds
    ON slow_start_duration_seconds.id = R.id
    AND slow_start_duration_seconds.attr_name = 'slow_start_duration_seconds'
  LEFT JOIN attrs AS stickiness_lb_cookie_duration_seconds
    ON stickiness_lb_cookie_duration_seconds.id = R.id
    AND stickiness_lb_cookie_duration_seconds.attr_name = 'stickiness_lb_cookie_duration_seconds'
  LEFT JOIN attrs AS lambda_multi_value_headers_enabled
    ON lambda_multi_value_headers_enabled.id = R.id
    AND lambda_multi_value_headers_enabled.attr_name = 'lambda_multi_value_headers_enabled'
  LEFT JOIN attrs AS proxy_protocol_v2_enabled
    ON proxy_protocol_v2_enabled.id = R.id
    AND proxy_protocol_v2_enabled.attr_name = 'proxy_protocol_v2_enabled'
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
  AND LOWER(R.provider_type) = 'targetgroup'
  AND R.service = 'elbv2'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_elbv2_targetgroup;

COMMENT ON MATERIALIZED VIEW aws_elbv2_targetgroup IS 'elbv2 targetgroup resources and their associated attributes.';



DROP MATERIALIZED VIEW IF EXISTS aws_elbv2_targetgroup_loadbalancer CASCADE;

CREATE MATERIALIZED VIEW aws_elbv2_targetgroup_loadbalancer AS
SELECT
  aws_elbv2_targetgroup.id AS targetgroup_id,
  aws_elbv2_loadbalancer.id AS loadbalancer_id
FROM
  resource AS aws_elbv2_targetgroup
  INNER JOIN resource_relation AS RR
    ON RR.resource_id = aws_elbv2_targetgroup.id
    AND RR.relation = 'receives-from'
  INNER JOIN resource AS aws_elbv2_loadbalancer
    ON aws_elbv2_loadbalancer.id = RR.target_id
    AND aws_elbv2_loadbalancer.provider_type = 'LoadBalancer'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_elbv2_targetgroup_loadbalancer;

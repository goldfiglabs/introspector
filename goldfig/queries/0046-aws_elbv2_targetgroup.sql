INSERT INTO aws_elbv2_targetgroup
SELECT
  R.id AS _id,
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
  protocolversion.attr_value #>> '{}' AS protocolversion,
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
  LEFT JOIN resource_attribute AS targetgrouparn
    ON targetgrouparn.resource_id = R.id
    AND targetgrouparn.type = 'provider'
    AND lower(targetgrouparn.attr_name) = 'targetgrouparn'
  LEFT JOIN resource_attribute AS targetgroupname
    ON targetgroupname.resource_id = R.id
    AND targetgroupname.type = 'provider'
    AND lower(targetgroupname.attr_name) = 'targetgroupname'
  LEFT JOIN resource_attribute AS protocol
    ON protocol.resource_id = R.id
    AND protocol.type = 'provider'
    AND lower(protocol.attr_name) = 'protocol'
  LEFT JOIN resource_attribute AS port
    ON port.resource_id = R.id
    AND port.type = 'provider'
    AND lower(port.attr_name) = 'port'
  LEFT JOIN resource_attribute AS vpcid
    ON vpcid.resource_id = R.id
    AND vpcid.type = 'provider'
    AND lower(vpcid.attr_name) = 'vpcid'
  LEFT JOIN resource_attribute AS healthcheckprotocol
    ON healthcheckprotocol.resource_id = R.id
    AND healthcheckprotocol.type = 'provider'
    AND lower(healthcheckprotocol.attr_name) = 'healthcheckprotocol'
  LEFT JOIN resource_attribute AS healthcheckport
    ON healthcheckport.resource_id = R.id
    AND healthcheckport.type = 'provider'
    AND lower(healthcheckport.attr_name) = 'healthcheckport'
  LEFT JOIN resource_attribute AS healthcheckenabled
    ON healthcheckenabled.resource_id = R.id
    AND healthcheckenabled.type = 'provider'
    AND lower(healthcheckenabled.attr_name) = 'healthcheckenabled'
  LEFT JOIN resource_attribute AS healthcheckintervalseconds
    ON healthcheckintervalseconds.resource_id = R.id
    AND healthcheckintervalseconds.type = 'provider'
    AND lower(healthcheckintervalseconds.attr_name) = 'healthcheckintervalseconds'
  LEFT JOIN resource_attribute AS healthchecktimeoutseconds
    ON healthchecktimeoutseconds.resource_id = R.id
    AND healthchecktimeoutseconds.type = 'provider'
    AND lower(healthchecktimeoutseconds.attr_name) = 'healthchecktimeoutseconds'
  LEFT JOIN resource_attribute AS healthythresholdcount
    ON healthythresholdcount.resource_id = R.id
    AND healthythresholdcount.type = 'provider'
    AND lower(healthythresholdcount.attr_name) = 'healthythresholdcount'
  LEFT JOIN resource_attribute AS unhealthythresholdcount
    ON unhealthythresholdcount.resource_id = R.id
    AND unhealthythresholdcount.type = 'provider'
    AND lower(unhealthythresholdcount.attr_name) = 'unhealthythresholdcount'
  LEFT JOIN resource_attribute AS healthcheckpath
    ON healthcheckpath.resource_id = R.id
    AND healthcheckpath.type = 'provider'
    AND lower(healthcheckpath.attr_name) = 'healthcheckpath'
  LEFT JOIN resource_attribute AS matcher
    ON matcher.resource_id = R.id
    AND matcher.type = 'provider'
    AND lower(matcher.attr_name) = 'matcher'
  LEFT JOIN resource_attribute AS loadbalancerarns
    ON loadbalancerarns.resource_id = R.id
    AND loadbalancerarns.type = 'provider'
    AND lower(loadbalancerarns.attr_name) = 'loadbalancerarns'
  LEFT JOIN resource_attribute AS targettype
    ON targettype.resource_id = R.id
    AND targettype.type = 'provider'
    AND lower(targettype.attr_name) = 'targettype'
  LEFT JOIN resource_attribute AS protocolversion
    ON protocolversion.resource_id = R.id
    AND protocolversion.type = 'provider'
    AND lower(protocolversion.attr_name) = 'protocolversion'
  LEFT JOIN resource_attribute AS tags
    ON tags.resource_id = R.id
    AND tags.type = 'provider'
    AND lower(tags.attr_name) = 'tags'
  LEFT JOIN resource_attribute AS deregistration_delay_timeout_seconds
    ON deregistration_delay_timeout_seconds.resource_id = R.id
    AND deregistration_delay_timeout_seconds.type = 'provider'
    AND lower(deregistration_delay_timeout_seconds.attr_name) = 'deregistration_delay_timeout_seconds'
  LEFT JOIN resource_attribute AS stickiness_enabled
    ON stickiness_enabled.resource_id = R.id
    AND stickiness_enabled.type = 'provider'
    AND lower(stickiness_enabled.attr_name) = 'stickiness_enabled'
  LEFT JOIN resource_attribute AS stickiness_type
    ON stickiness_type.resource_id = R.id
    AND stickiness_type.type = 'provider'
    AND lower(stickiness_type.attr_name) = 'stickiness_type'
  LEFT JOIN resource_attribute AS load_balancing_algorithm_type
    ON load_balancing_algorithm_type.resource_id = R.id
    AND load_balancing_algorithm_type.type = 'provider'
    AND lower(load_balancing_algorithm_type.attr_name) = 'load_balancing_algorithm_type'
  LEFT JOIN resource_attribute AS slow_start_duration_seconds
    ON slow_start_duration_seconds.resource_id = R.id
    AND slow_start_duration_seconds.type = 'provider'
    AND lower(slow_start_duration_seconds.attr_name) = 'slow_start_duration_seconds'
  LEFT JOIN resource_attribute AS stickiness_lb_cookie_duration_seconds
    ON stickiness_lb_cookie_duration_seconds.resource_id = R.id
    AND stickiness_lb_cookie_duration_seconds.type = 'provider'
    AND lower(stickiness_lb_cookie_duration_seconds.attr_name) = 'stickiness_lb_cookie_duration_seconds'
  LEFT JOIN resource_attribute AS lambda_multi_value_headers_enabled
    ON lambda_multi_value_headers_enabled.resource_id = R.id
    AND lambda_multi_value_headers_enabled.type = 'provider'
    AND lower(lambda_multi_value_headers_enabled.attr_name) = 'lambda_multi_value_headers_enabled'
  LEFT JOIN resource_attribute AS proxy_protocol_v2_enabled
    ON proxy_protocol_v2_enabled.resource_id = R.id
    AND proxy_protocol_v2_enabled.type = 'provider'
    AND lower(proxy_protocol_v2_enabled.attr_name) = 'proxy_protocol_v2_enabled'
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
  AND R.provider_type = 'TargetGroup'
  AND R.service = 'elbv2'
ON CONFLICT (_id) DO UPDATE
SET
    targetgrouparn = EXCLUDED.targetgrouparn,
    targetgroupname = EXCLUDED.targetgroupname,
    protocol = EXCLUDED.protocol,
    port = EXCLUDED.port,
    vpcid = EXCLUDED.vpcid,
    healthcheckprotocol = EXCLUDED.healthcheckprotocol,
    healthcheckport = EXCLUDED.healthcheckport,
    healthcheckenabled = EXCLUDED.healthcheckenabled,
    healthcheckintervalseconds = EXCLUDED.healthcheckintervalseconds,
    healthchecktimeoutseconds = EXCLUDED.healthchecktimeoutseconds,
    healthythresholdcount = EXCLUDED.healthythresholdcount,
    unhealthythresholdcount = EXCLUDED.unhealthythresholdcount,
    healthcheckpath = EXCLUDED.healthcheckpath,
    matcher = EXCLUDED.matcher,
    loadbalancerarns = EXCLUDED.loadbalancerarns,
    targettype = EXCLUDED.targettype,
    protocolversion = EXCLUDED.protocolversion,
    tags = EXCLUDED.tags,
    deregistration_delay_timeout_seconds = EXCLUDED.deregistration_delay_timeout_seconds,
    stickiness_enabled = EXCLUDED.stickiness_enabled,
    stickiness_type = EXCLUDED.stickiness_type,
    load_balancing_algorithm_type = EXCLUDED.load_balancing_algorithm_type,
    slow_start_duration_seconds = EXCLUDED.slow_start_duration_seconds,
    stickiness_lb_cookie_duration_seconds = EXCLUDED.stickiness_lb_cookie_duration_seconds,
    lambda_multi_value_headers_enabled = EXCLUDED.lambda_multi_value_headers_enabled,
    proxy_protocol_v2_enabled = EXCLUDED.proxy_protocol_v2_enabled,
    _ec2_vpc_id = EXCLUDED._ec2_vpc_id,
    _account_id = EXCLUDED._account_id
  ;



INSERT INTO aws_elbv2_targetgroup_loadbalancer
SELECT
  aws_elbv2_targetgroup.id AS targetgroup_id,
  aws_elbv2_loadbalancer.id AS loadbalancer_id,
  aws_elbv2_targetgroup.provider_account_id AS provider_account_id
FROM
  resource AS aws_elbv2_targetgroup
  INNER JOIN resource_relation AS RR
    ON RR.resource_id = aws_elbv2_targetgroup.id
    AND RR.relation = 'receives-from'
  INNER JOIN resource AS aws_elbv2_loadbalancer
    ON aws_elbv2_loadbalancer.id = RR.target_id
    AND aws_elbv2_loadbalancer.provider_type = 'LoadBalancer'
    AND aws_elbv2_loadbalancer.service = 'elbv2'
  WHERE
    aws_elbv2_targetgroup.provider_type = 'TargetGroup'
    AND aws_elbv2_targetgroup.service = 'elbv2'
ON CONFLICT (targetgroup_id, loadbalancer_id)
DO NOTHING
;

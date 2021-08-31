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
INSERT INTO aws_elbv2_targetgroup (
  _id,
  uri,
  provider_account_id,
  targetgrouparn,
  targetgroupname,
  protocol,
  port,
  vpcid,
  healthcheckprotocol,
  healthcheckport,
  healthcheckenabled,
  healthcheckintervalseconds,
  healthchecktimeoutseconds,
  healthythresholdcount,
  unhealthythresholdcount,
  healthcheckpath,
  matcher,
  loadbalancerarns,
  targettype,
  protocolversion,
  tags,
  deregistration_delay_timeout_seconds,
  stickiness_enabled,
  stickiness_type,
  load_balancing_algorithm_type,
  slow_start_duration_seconds,
  stickiness_lb_cookie_duration_seconds,
  lambda_multi_value_headers_enabled,
  proxy_protocol_v2_enabled,
  _tags,
  _ec2_vpc_id,_account_id
)
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  attrs.provider ->> 'TargetGroupArn' AS targetgrouparn,
  attrs.provider ->> 'TargetGroupName' AS targetgroupname,
  attrs.provider ->> 'Protocol' AS protocol,
  (attrs.provider ->> 'Port')::integer AS port,
  attrs.provider ->> 'VpcId' AS vpcid,
  attrs.provider ->> 'HealthCheckProtocol' AS healthcheckprotocol,
  attrs.provider ->> 'HealthCheckPort' AS healthcheckport,
  (attrs.provider ->> 'HealthCheckEnabled')::boolean AS healthcheckenabled,
  (attrs.provider ->> 'HealthCheckIntervalSeconds')::integer AS healthcheckintervalseconds,
  (attrs.provider ->> 'HealthCheckTimeoutSeconds')::integer AS healthchecktimeoutseconds,
  (attrs.provider ->> 'HealthyThresholdCount')::integer AS healthythresholdcount,
  (attrs.provider ->> 'UnhealthyThresholdCount')::integer AS unhealthythresholdcount,
  attrs.provider ->> 'HealthCheckPath' AS healthcheckpath,
  attrs.provider -> 'Matcher' AS matcher,
  attrs.provider -> 'LoadBalancerArns' AS loadbalancerarns,
  attrs.provider ->> 'TargetType' AS targettype,
  attrs.provider ->> 'ProtocolVersion' AS protocolversion,
  attrs.provider -> 'Tags' AS tags,
  (attrs.provider ->> 'deregistration_delay_timeout_seconds')::integer AS deregistration_delay_timeout_seconds,
  (attrs.provider ->> 'stickiness_enabled')::boolean AS stickiness_enabled,
  attrs.provider ->> 'stickiness_type' AS stickiness_type,
  attrs.provider ->> 'load_balancing_algorithm_type' AS load_balancing_algorithm_type,
  (attrs.provider ->> 'slow_start_duration_seconds')::integer AS slow_start_duration_seconds,
  (attrs.provider ->> 'stickiness_lb_cookie_duration_seconds')::integer AS stickiness_lb_cookie_duration_seconds,
  (attrs.provider ->> 'lambda_multi_value_headers_enabled')::boolean AS lambda_multi_value_headers_enabled,
  (attrs.provider ->> 'proxy_protocol_v2_enabled')::boolean AS proxy_protocol_v2_enabled,
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
  AND R.provider_type = 'TargetGroup'
  AND R.service = 'elbv2'
ON CONFLICT (_id) DO UPDATE
SET
    TargetGroupArn = EXCLUDED.TargetGroupArn,
    TargetGroupName = EXCLUDED.TargetGroupName,
    Protocol = EXCLUDED.Protocol,
    Port = EXCLUDED.Port,
    VpcId = EXCLUDED.VpcId,
    HealthCheckProtocol = EXCLUDED.HealthCheckProtocol,
    HealthCheckPort = EXCLUDED.HealthCheckPort,
    HealthCheckEnabled = EXCLUDED.HealthCheckEnabled,
    HealthCheckIntervalSeconds = EXCLUDED.HealthCheckIntervalSeconds,
    HealthCheckTimeoutSeconds = EXCLUDED.HealthCheckTimeoutSeconds,
    HealthyThresholdCount = EXCLUDED.HealthyThresholdCount,
    UnhealthyThresholdCount = EXCLUDED.UnhealthyThresholdCount,
    HealthCheckPath = EXCLUDED.HealthCheckPath,
    Matcher = EXCLUDED.Matcher,
    LoadBalancerArns = EXCLUDED.LoadBalancerArns,
    TargetType = EXCLUDED.TargetType,
    ProtocolVersion = EXCLUDED.ProtocolVersion,
    Tags = EXCLUDED.Tags,
    deregistration_delay_timeout_seconds = EXCLUDED.deregistration_delay_timeout_seconds,
    stickiness_enabled = EXCLUDED.stickiness_enabled,
    stickiness_type = EXCLUDED.stickiness_type,
    load_balancing_algorithm_type = EXCLUDED.load_balancing_algorithm_type,
    slow_start_duration_seconds = EXCLUDED.slow_start_duration_seconds,
    stickiness_lb_cookie_duration_seconds = EXCLUDED.stickiness_lb_cookie_duration_seconds,
    lambda_multi_value_headers_enabled = EXCLUDED.lambda_multi_value_headers_enabled,
    proxy_protocol_v2_enabled = EXCLUDED.proxy_protocol_v2_enabled,
    _tags = EXCLUDED._tags,
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
    AND aws_elbv2_loadbalancer.provider_account_id = :provider_account_id
  WHERE
    aws_elbv2_targetgroup.provider_account_id = :provider_account_id
    AND aws_elbv2_targetgroup.provider_type = 'TargetGroup'
    AND aws_elbv2_targetgroup.service = 'elbv2'
ON CONFLICT (targetgroup_id, loadbalancer_id)
DO NOTHING
;

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
INSERT INTO aws_autoscaling_autoscalinggroup (
  _id,
  uri,
  provider_account_id,
  autoscalinggroupname,
  autoscalinggrouparn,
  launchconfigurationname,
  launchtemplate,
  mixedinstancespolicy,
  minsize,
  maxsize,
  desiredcapacity,
  defaultcooldown,
  availabilityzones,
  loadbalancernames,
  targetgrouparns,
  healthchecktype,
  healthcheckgraceperiod,
  instances,
  createdtime,
  suspendedprocesses,
  placementgroup,
  vpczoneidentifier,
  enabledmetrics,
  status,
  tags,
  terminationpolicies,
  newinstancesprotectedfromscalein,
  servicelinkedrolearn,
  maxinstancelifetime,
  capacityrebalance,
  _tags,
  _launchconfiguration_id,_iam_role_id,_account_id
)
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  attrs.provider ->> 'AutoScalingGroupName' AS autoscalinggroupname,
  attrs.provider ->> 'AutoScalingGroupARN' AS autoscalinggrouparn,
  attrs.provider ->> 'LaunchConfigurationName' AS launchconfigurationname,
  attrs.provider -> 'LaunchTemplate' AS launchtemplate,
  attrs.provider -> 'MixedInstancesPolicy' AS mixedinstancespolicy,
  (attrs.provider ->> 'MinSize')::integer AS minsize,
  (attrs.provider ->> 'MaxSize')::integer AS maxsize,
  (attrs.provider ->> 'DesiredCapacity')::integer AS desiredcapacity,
  (attrs.provider ->> 'DefaultCooldown')::integer AS defaultcooldown,
  attrs.provider -> 'AvailabilityZones' AS availabilityzones,
  attrs.provider -> 'LoadBalancerNames' AS loadbalancernames,
  attrs.provider -> 'TargetGroupARNs' AS targetgrouparns,
  attrs.provider ->> 'HealthCheckType' AS healthchecktype,
  (attrs.provider ->> 'HealthCheckGracePeriod')::integer AS healthcheckgraceperiod,
  attrs.provider -> 'Instances' AS instances,
  (TO_TIMESTAMP(attrs.provider ->> 'CreatedTime', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS createdtime,
  attrs.provider -> 'SuspendedProcesses' AS suspendedprocesses,
  attrs.provider ->> 'PlacementGroup' AS placementgroup,
  attrs.provider ->> 'VPCZoneIdentifier' AS vpczoneidentifier,
  attrs.provider -> 'EnabledMetrics' AS enabledmetrics,
  attrs.provider ->> 'Status' AS status,
  attrs.provider -> 'Tags' AS tags,
  attrs.provider -> 'TerminationPolicies' AS terminationpolicies,
  (attrs.provider ->> 'NewInstancesProtectedFromScaleIn')::boolean AS newinstancesprotectedfromscalein,
  attrs.provider ->> 'ServiceLinkedRoleARN' AS servicelinkedrolearn,
  (attrs.provider ->> 'MaxInstanceLifetime')::integer AS maxinstancelifetime,
  (attrs.provider ->> 'CapacityRebalance')::boolean AS capacityrebalance,
  attrs.metadata -> 'Tags' AS tags,
  
    _launchconfiguration_id.target_id AS _launchconfiguration_id,
    _iam_role_id.target_id AS _iam_role_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  LEFT JOIN attrs ON
    attrs.resource_id = R.id
  LEFT JOIN (
    SELECT
      _aws_autoscaling_launchconfiguration_relation.resource_id AS resource_id,
      _aws_autoscaling_launchconfiguration.id AS target_id
    FROM
      resource_relation AS _aws_autoscaling_launchconfiguration_relation
      INNER JOIN resource AS _aws_autoscaling_launchconfiguration
        ON _aws_autoscaling_launchconfiguration_relation.target_id = _aws_autoscaling_launchconfiguration.id
        AND _aws_autoscaling_launchconfiguration.provider_type = 'LaunchConfiguration'
        AND _aws_autoscaling_launchconfiguration.service = 'autoscaling'
        AND _aws_autoscaling_launchconfiguration.provider_account_id = :provider_account_id
    WHERE
      _aws_autoscaling_launchconfiguration_relation.relation = 'launches-with'
      AND _aws_autoscaling_launchconfiguration_relation.provider_account_id = :provider_account_id
  ) AS _launchconfiguration_id ON _launchconfiguration_id.resource_id = R.id
  LEFT JOIN (
    SELECT
      _aws_iam_role_relation.resource_id AS resource_id,
      _aws_iam_role.id AS target_id
    FROM
      resource_relation AS _aws_iam_role_relation
      INNER JOIN resource AS _aws_iam_role
        ON _aws_iam_role_relation.target_id = _aws_iam_role.id
        AND _aws_iam_role.provider_type = 'Role'
        AND _aws_iam_role.service = 'iam'
        AND _aws_iam_role.provider_account_id = :provider_account_id
    WHERE
      _aws_iam_role_relation.relation = 'acts-as'
      AND _aws_iam_role_relation.provider_account_id = :provider_account_id
  ) AS _iam_role_id ON _iam_role_id.resource_id = R.id
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
          AND _aws_organizations_account_relation.provider_account_id = 8
        GROUP BY _aws_organizations_account_relation.resource_id
        HAVING COUNT(*) = 1
      ) AS unique_account_mapping
  ) AS _account_id ON _account_id.resource_id = R.id
  WHERE
  R.provider_account_id = :provider_account_id
  AND R.provider_type = 'AutoScalingGroup'
  AND R.service = 'autoscaling'
ON CONFLICT (_id) DO UPDATE
SET
    AutoScalingGroupName = EXCLUDED.AutoScalingGroupName,
    AutoScalingGroupARN = EXCLUDED.AutoScalingGroupARN,
    LaunchConfigurationName = EXCLUDED.LaunchConfigurationName,
    LaunchTemplate = EXCLUDED.LaunchTemplate,
    MixedInstancesPolicy = EXCLUDED.MixedInstancesPolicy,
    MinSize = EXCLUDED.MinSize,
    MaxSize = EXCLUDED.MaxSize,
    DesiredCapacity = EXCLUDED.DesiredCapacity,
    DefaultCooldown = EXCLUDED.DefaultCooldown,
    AvailabilityZones = EXCLUDED.AvailabilityZones,
    LoadBalancerNames = EXCLUDED.LoadBalancerNames,
    TargetGroupARNs = EXCLUDED.TargetGroupARNs,
    HealthCheckType = EXCLUDED.HealthCheckType,
    HealthCheckGracePeriod = EXCLUDED.HealthCheckGracePeriod,
    Instances = EXCLUDED.Instances,
    CreatedTime = EXCLUDED.CreatedTime,
    SuspendedProcesses = EXCLUDED.SuspendedProcesses,
    PlacementGroup = EXCLUDED.PlacementGroup,
    VPCZoneIdentifier = EXCLUDED.VPCZoneIdentifier,
    EnabledMetrics = EXCLUDED.EnabledMetrics,
    Status = EXCLUDED.Status,
    Tags = EXCLUDED.Tags,
    TerminationPolicies = EXCLUDED.TerminationPolicies,
    NewInstancesProtectedFromScaleIn = EXCLUDED.NewInstancesProtectedFromScaleIn,
    ServiceLinkedRoleARN = EXCLUDED.ServiceLinkedRoleARN,
    MaxInstanceLifetime = EXCLUDED.MaxInstanceLifetime,
    CapacityRebalance = EXCLUDED.CapacityRebalance,
    _tags = EXCLUDED._tags,
    _launchconfiguration_id = EXCLUDED._launchconfiguration_id,
    _iam_role_id = EXCLUDED._iam_role_id,
    _account_id = EXCLUDED._account_id
  ;


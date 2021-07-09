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
INSERT INTO aws_elasticbeanstalk_environment (
  _id,
  uri,
  provider_account_id,
  environmentid,
  applicationname,
  versionlabel,
  solutionstackname,
  platformarn,
  templatename,
  description,
  endpointurl,
  cname,
  datecreated,
  dateupdated,
  status,
  abortableoperationinprogress,
  health,
  healthstatus,
  resources,
  tier,
  environmentlinks,
  environmentarn,
  operationsrole,
  tags,
  environmentname,
  autoscalinggroups,
  instances,
  launchconfigurations,
  launchtemplates,
  loadbalancers,
  triggers,
  queues,
  _tags,
  _application_id,_applicationversion_id,_iam_role_id,_account_id
)
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  attrs.provider ->> 'EnvironmentId' AS environmentid,
  attrs.provider ->> 'ApplicationName' AS applicationname,
  attrs.provider ->> 'VersionLabel' AS versionlabel,
  attrs.provider ->> 'SolutionStackName' AS solutionstackname,
  attrs.provider ->> 'PlatformArn' AS platformarn,
  attrs.provider ->> 'TemplateName' AS templatename,
  attrs.provider ->> 'Description' AS description,
  attrs.provider ->> 'EndpointURL' AS endpointurl,
  attrs.provider ->> 'CNAME' AS cname,
  (TO_TIMESTAMP(attrs.provider ->> 'DateCreated', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS datecreated,
  (TO_TIMESTAMP(attrs.provider ->> 'DateUpdated', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS dateupdated,
  attrs.provider ->> 'Status' AS status,
  (attrs.provider ->> 'AbortableOperationInProgress')::boolean AS abortableoperationinprogress,
  attrs.provider ->> 'Health' AS health,
  attrs.provider ->> 'HealthStatus' AS healthstatus,
  attrs.provider -> 'Resources' AS resources,
  attrs.provider -> 'Tier' AS tier,
  attrs.provider -> 'EnvironmentLinks' AS environmentlinks,
  attrs.provider ->> 'EnvironmentArn' AS environmentarn,
  attrs.provider ->> 'OperationsRole' AS operationsrole,
  attrs.provider -> 'Tags' AS tags,
  attrs.provider ->> 'EnvironmentName' AS environmentname,
  attrs.provider -> 'AutoScalingGroups' AS autoscalinggroups,
  attrs.provider -> 'Instances' AS instances,
  attrs.provider -> 'LaunchConfigurations' AS launchconfigurations,
  attrs.provider -> 'LaunchTemplates' AS launchtemplates,
  attrs.provider -> 'LoadBalancers' AS loadbalancers,
  attrs.provider -> 'Triggers' AS triggers,
  attrs.provider -> 'Queues' AS queues,
  attrs.metadata -> 'Tags' AS tags,
  
    _application_id.target_id AS _application_id,
    _applicationversion_id.target_id AS _applicationversion_id,
    _iam_role_id.target_id AS _iam_role_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  LEFT JOIN attrs ON
    attrs.resource_id = R.id
  LEFT JOIN (
    SELECT
      _aws_elasticbeanstalk_application_relation.resource_id AS resource_id,
      _aws_elasticbeanstalk_application.id AS target_id
    FROM
      resource_relation AS _aws_elasticbeanstalk_application_relation
      INNER JOIN resource AS _aws_elasticbeanstalk_application
        ON _aws_elasticbeanstalk_application_relation.target_id = _aws_elasticbeanstalk_application.id
        AND _aws_elasticbeanstalk_application.provider_type = 'Application'
        AND _aws_elasticbeanstalk_application.service = 'elasticbeanstalk'
        AND _aws_elasticbeanstalk_application.provider_account_id = :provider_account_id
    WHERE
      _aws_elasticbeanstalk_application_relation.relation = 'belongs-to'
      AND _aws_elasticbeanstalk_application_relation.provider_account_id = :provider_account_id
  ) AS _application_id ON _application_id.resource_id = R.id
  LEFT JOIN (
    SELECT
      _aws_elasticbeanstalk_applicationversion_relation.resource_id AS resource_id,
      _aws_elasticbeanstalk_applicationversion.id AS target_id
    FROM
      resource_relation AS _aws_elasticbeanstalk_applicationversion_relation
      INNER JOIN resource AS _aws_elasticbeanstalk_applicationversion
        ON _aws_elasticbeanstalk_applicationversion_relation.target_id = _aws_elasticbeanstalk_applicationversion.id
        AND _aws_elasticbeanstalk_applicationversion.provider_type = 'ApplicationVersion'
        AND _aws_elasticbeanstalk_applicationversion.service = 'elasticbeanstalk'
        AND _aws_elasticbeanstalk_applicationversion.provider_account_id = :provider_account_id
    WHERE
      _aws_elasticbeanstalk_applicationversion_relation.relation = 'belongs-to'
      AND _aws_elasticbeanstalk_applicationversion_relation.provider_account_id = :provider_account_id
  ) AS _applicationversion_id ON _applicationversion_id.resource_id = R.id
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
  AND R.provider_type = 'Environment'
  AND R.service = 'elasticbeanstalk'
ON CONFLICT (_id) DO UPDATE
SET
    EnvironmentId = EXCLUDED.EnvironmentId,
    ApplicationName = EXCLUDED.ApplicationName,
    VersionLabel = EXCLUDED.VersionLabel,
    SolutionStackName = EXCLUDED.SolutionStackName,
    PlatformArn = EXCLUDED.PlatformArn,
    TemplateName = EXCLUDED.TemplateName,
    Description = EXCLUDED.Description,
    EndpointURL = EXCLUDED.EndpointURL,
    CNAME = EXCLUDED.CNAME,
    DateCreated = EXCLUDED.DateCreated,
    DateUpdated = EXCLUDED.DateUpdated,
    Status = EXCLUDED.Status,
    AbortableOperationInProgress = EXCLUDED.AbortableOperationInProgress,
    Health = EXCLUDED.Health,
    HealthStatus = EXCLUDED.HealthStatus,
    Resources = EXCLUDED.Resources,
    Tier = EXCLUDED.Tier,
    EnvironmentLinks = EXCLUDED.EnvironmentLinks,
    EnvironmentArn = EXCLUDED.EnvironmentArn,
    OperationsRole = EXCLUDED.OperationsRole,
    Tags = EXCLUDED.Tags,
    EnvironmentName = EXCLUDED.EnvironmentName,
    AutoScalingGroups = EXCLUDED.AutoScalingGroups,
    Instances = EXCLUDED.Instances,
    LaunchConfigurations = EXCLUDED.LaunchConfigurations,
    LaunchTemplates = EXCLUDED.LaunchTemplates,
    LoadBalancers = EXCLUDED.LoadBalancers,
    Triggers = EXCLUDED.Triggers,
    Queues = EXCLUDED.Queues,
    _tags = EXCLUDED._tags,
    _application_id = EXCLUDED._application_id,
    _applicationversion_id = EXCLUDED._applicationversion_id,
    _iam_role_id = EXCLUDED._iam_role_id,
    _account_id = EXCLUDED._account_id
  ;



INSERT INTO aws_elasticbeanstalk_environment_autoscaling_autoscalinggroup
SELECT
  aws_elasticbeanstalk_environment.id AS environment_id,
  aws_autoscaling_autoscalinggroup.id AS autoscalinggroup_id,
  aws_elasticbeanstalk_environment.provider_account_id AS provider_account_id
FROM
  resource AS aws_elasticbeanstalk_environment
  INNER JOIN resource_relation AS RR
    ON RR.resource_id = aws_elasticbeanstalk_environment.id
    AND RR.relation = 'launches-into'
  INNER JOIN resource AS aws_autoscaling_autoscalinggroup
    ON aws_autoscaling_autoscalinggroup.id = RR.target_id
    AND aws_autoscaling_autoscalinggroup.provider_type = 'autoScalingGroup'
    AND aws_autoscaling_autoscalinggroup.service = 'autoscaling'
    AND aws_autoscaling_autoscalinggroup.provider_account_id = :provider_account_id
  WHERE
    aws_elasticbeanstalk_environment.provider_account_id = :provider_account_id
    AND aws_elasticbeanstalk_environment.provider_type = 'Environment'
    AND aws_elasticbeanstalk_environment.service = 'elasticbeanstalk'
ON CONFLICT (environment_id, autoscalinggroup_id)
DO NOTHING
;


INSERT INTO aws_elasticbeanstalk_environment_autoscaling_launchconfiguration
SELECT
  aws_elasticbeanstalk_environment.id AS environment_id,
  aws_autoscaling_launchconfiguration.id AS launchconfiguration_id,
  aws_elasticbeanstalk_environment.provider_account_id AS provider_account_id
FROM
  resource AS aws_elasticbeanstalk_environment
  INNER JOIN resource_relation AS RR
    ON RR.resource_id = aws_elasticbeanstalk_environment.id
    AND RR.relation = 'launches-with'
  INNER JOIN resource AS aws_autoscaling_launchconfiguration
    ON aws_autoscaling_launchconfiguration.id = RR.target_id
    AND aws_autoscaling_launchconfiguration.provider_type = 'launchConfiguration'
    AND aws_autoscaling_launchconfiguration.service = 'autoscaling'
    AND aws_autoscaling_launchconfiguration.provider_account_id = :provider_account_id
  WHERE
    aws_elasticbeanstalk_environment.provider_account_id = :provider_account_id
    AND aws_elasticbeanstalk_environment.provider_type = 'Environment'
    AND aws_elasticbeanstalk_environment.service = 'elasticbeanstalk'
ON CONFLICT (environment_id, launchconfiguration_id)
DO NOTHING
;


INSERT INTO aws_elasticbeanstalk_environment_ec2_instance
SELECT
  aws_elasticbeanstalk_environment.id AS environment_id,
  aws_ec2_instance.id AS instance_id,
  aws_elasticbeanstalk_environment.provider_account_id AS provider_account_id
FROM
  resource AS aws_elasticbeanstalk_environment
  INNER JOIN resource_relation AS RR
    ON RR.resource_id = aws_elasticbeanstalk_environment.id
    AND RR.relation = 'has-instances'
  INNER JOIN resource AS aws_ec2_instance
    ON aws_ec2_instance.id = RR.target_id
    AND aws_ec2_instance.provider_type = 'Instance'
    AND aws_ec2_instance.service = 'ec2'
    AND aws_ec2_instance.provider_account_id = :provider_account_id
  WHERE
    aws_elasticbeanstalk_environment.provider_account_id = :provider_account_id
    AND aws_elasticbeanstalk_environment.provider_type = 'Environment'
    AND aws_elasticbeanstalk_environment.service = 'elasticbeanstalk'
ON CONFLICT (environment_id, instance_id)
DO NOTHING
;

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
INSERT INTO aws_ecs_service (
  _id,
  uri,
  provider_account_id,
  servicearn,
  servicename,
  clusterarn,
  loadbalancers,
  serviceregistries,
  status,
  desiredcount,
  runningcount,
  pendingcount,
  launchtype,
  capacityproviderstrategy,
  platformversion,
  taskdefinition,
  deploymentconfiguration,
  tasksets,
  deployments,
  rolearn,
  events,
  createdat,
  placementconstraints,
  placementstrategy,
  networkconfiguration,
  healthcheckgraceperiodseconds,
  schedulingstrategy,
  deploymentcontroller,
  tags,
  createdby,
  enableecsmanagedtags,
  propagatetags,
  _tags,
  _cluster_id,_account_id
)
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  attrs.provider ->> 'serviceArn' AS servicearn,
  attrs.provider ->> 'serviceName' AS servicename,
  attrs.provider ->> 'clusterArn' AS clusterarn,
  attrs.provider -> 'loadBalancers' AS loadbalancers,
  attrs.provider -> 'serviceRegistries' AS serviceregistries,
  attrs.provider ->> 'status' AS status,
  (attrs.provider ->> 'desiredCount')::integer AS desiredcount,
  (attrs.provider ->> 'runningCount')::integer AS runningcount,
  (attrs.provider ->> 'pendingCount')::integer AS pendingcount,
  attrs.provider ->> 'launchType' AS launchtype,
  attrs.provider -> 'capacityProviderStrategy' AS capacityproviderstrategy,
  attrs.provider ->> 'platformVersion' AS platformversion,
  attrs.provider ->> 'taskDefinition' AS taskdefinition,
  attrs.provider -> 'deploymentConfiguration' AS deploymentconfiguration,
  attrs.provider -> 'taskSets' AS tasksets,
  attrs.provider -> 'deployments' AS deployments,
  attrs.provider ->> 'roleArn' AS rolearn,
  attrs.provider -> 'events' AS events,
  (TO_TIMESTAMP(attrs.provider ->> 'createdAt', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS createdat,
  attrs.provider -> 'placementConstraints' AS placementconstraints,
  attrs.provider -> 'placementStrategy' AS placementstrategy,
  attrs.provider -> 'networkConfiguration' AS networkconfiguration,
  (attrs.provider ->> 'healthCheckGracePeriodSeconds')::integer AS healthcheckgraceperiodseconds,
  attrs.provider ->> 'schedulingStrategy' AS schedulingstrategy,
  attrs.provider -> 'deploymentController' AS deploymentcontroller,
  attrs.provider -> 'tags' AS tags,
  attrs.provider ->> 'createdBy' AS createdby,
  (attrs.provider ->> 'enableECSManagedTags')::boolean AS enableecsmanagedtags,
  attrs.provider ->> 'propagateTags' AS propagatetags,
  attrs.metadata -> 'Tags' AS tags,
  
    _cluster_id.target_id AS _cluster_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  LEFT JOIN attrs ON
    attrs.resource_id = R.id
  LEFT JOIN (
    SELECT
      _aws_ecs_cluster_relation.resource_id AS resource_id,
      _aws_ecs_cluster.id AS target_id
    FROM
      resource_relation AS _aws_ecs_cluster_relation
      INNER JOIN resource AS _aws_ecs_cluster
        ON _aws_ecs_cluster_relation.target_id = _aws_ecs_cluster.id
        AND _aws_ecs_cluster.provider_type = 'Cluster'
        AND _aws_ecs_cluster.service = 'ecs'
        AND _aws_ecs_cluster.provider_account_id = :provider_account_id
    WHERE
      _aws_ecs_cluster_relation.relation = 'belongs-to'
      AND _aws_ecs_cluster_relation.provider_account_id = :provider_account_id
  ) AS _cluster_id ON _cluster_id.resource_id = R.id
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
  AND R.provider_type = 'Service'
  AND R.service = 'ecs'
ON CONFLICT (_id) DO UPDATE
SET
    serviceArn = EXCLUDED.serviceArn,
    serviceName = EXCLUDED.serviceName,
    clusterArn = EXCLUDED.clusterArn,
    loadBalancers = EXCLUDED.loadBalancers,
    serviceRegistries = EXCLUDED.serviceRegistries,
    status = EXCLUDED.status,
    desiredCount = EXCLUDED.desiredCount,
    runningCount = EXCLUDED.runningCount,
    pendingCount = EXCLUDED.pendingCount,
    launchType = EXCLUDED.launchType,
    capacityProviderStrategy = EXCLUDED.capacityProviderStrategy,
    platformVersion = EXCLUDED.platformVersion,
    taskDefinition = EXCLUDED.taskDefinition,
    deploymentConfiguration = EXCLUDED.deploymentConfiguration,
    taskSets = EXCLUDED.taskSets,
    deployments = EXCLUDED.deployments,
    roleArn = EXCLUDED.roleArn,
    events = EXCLUDED.events,
    createdAt = EXCLUDED.createdAt,
    placementConstraints = EXCLUDED.placementConstraints,
    placementStrategy = EXCLUDED.placementStrategy,
    networkConfiguration = EXCLUDED.networkConfiguration,
    healthCheckGracePeriodSeconds = EXCLUDED.healthCheckGracePeriodSeconds,
    schedulingStrategy = EXCLUDED.schedulingStrategy,
    deploymentController = EXCLUDED.deploymentController,
    tags = EXCLUDED.tags,
    createdBy = EXCLUDED.createdBy,
    enableECSManagedTags = EXCLUDED.enableECSManagedTags,
    propagateTags = EXCLUDED.propagateTags,
    _tags = EXCLUDED._tags,
    _cluster_id = EXCLUDED._cluster_id,
    _account_id = EXCLUDED._account_id
  ;


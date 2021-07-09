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
INSERT INTO aws_ecs_task (
  _id,
  uri,
  provider_account_id,
  attachments,
  attributes,
  availabilityzone,
  capacityprovidername,
  clusterarn,
  connectivity,
  connectivityat,
  containerinstancearn,
  containers,
  cpu,
  createdat,
  desiredstatus,
  executionstoppedat,
  "group",
  healthstatus,
  inferenceaccelerators,
  laststatus,
  launchtype,
  memory,
  overrides,
  platformversion,
  pullstartedat,
  pullstoppedat,
  startedat,
  startedby,
  stopcode,
  stoppedat,
  stoppedreason,
  stoppingat,
  tags,
  taskarn,
  taskdefinitionarn,
  version,
  _tags,
  _cluster_id,_account_id
)
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  attrs.provider -> 'attachments' AS attachments,
  attrs.provider -> 'attributes' AS attributes,
  attrs.provider ->> 'availabilityZone' AS availabilityzone,
  attrs.provider ->> 'capacityProviderName' AS capacityprovidername,
  attrs.provider ->> 'clusterArn' AS clusterarn,
  attrs.provider ->> 'connectivity' AS connectivity,
  (TO_TIMESTAMP(attrs.provider ->> 'connectivityAt', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS connectivityat,
  attrs.provider ->> 'containerInstanceArn' AS containerinstancearn,
  attrs.provider -> 'containers' AS containers,
  attrs.provider ->> 'cpu' AS cpu,
  (TO_TIMESTAMP(attrs.provider ->> 'createdAt', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS createdat,
  attrs.provider ->> 'desiredStatus' AS desiredstatus,
  (TO_TIMESTAMP(attrs.provider ->> 'executionStoppedAt', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS executionstoppedat,
  attrs.provider ->> 'group' AS group,
  attrs.provider ->> 'healthStatus' AS healthstatus,
  attrs.provider -> 'inferenceAccelerators' AS inferenceaccelerators,
  attrs.provider ->> 'lastStatus' AS laststatus,
  attrs.provider ->> 'launchType' AS launchtype,
  attrs.provider ->> 'memory' AS memory,
  attrs.provider -> 'overrides' AS overrides,
  attrs.provider ->> 'platformVersion' AS platformversion,
  (TO_TIMESTAMP(attrs.provider ->> 'pullStartedAt', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS pullstartedat,
  (TO_TIMESTAMP(attrs.provider ->> 'pullStoppedAt', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS pullstoppedat,
  (TO_TIMESTAMP(attrs.provider ->> 'startedAt', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS startedat,
  attrs.provider ->> 'startedBy' AS startedby,
  attrs.provider ->> 'stopCode' AS stopcode,
  (TO_TIMESTAMP(attrs.provider ->> 'stoppedAt', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS stoppedat,
  attrs.provider ->> 'stoppedReason' AS stoppedreason,
  (TO_TIMESTAMP(attrs.provider ->> 'stoppingAt', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS stoppingat,
  attrs.provider -> 'tags' AS tags,
  attrs.provider ->> 'taskArn' AS taskarn,
  attrs.provider ->> 'taskDefinitionArn' AS taskdefinitionarn,
  (attrs.provider ->> 'version')::bigint AS version,
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
          AND _aws_organizations_account_relation.provider_account_id = 8
        GROUP BY _aws_organizations_account_relation.resource_id
        HAVING COUNT(*) = 1
      ) AS unique_account_mapping
  ) AS _account_id ON _account_id.resource_id = R.id
  WHERE
  R.provider_account_id = :provider_account_id
  AND R.provider_type = 'Task'
  AND R.service = 'ecs'
ON CONFLICT (_id) DO UPDATE
SET
    attachments = EXCLUDED.attachments,
    attributes = EXCLUDED.attributes,
    availabilityZone = EXCLUDED.availabilityZone,
    capacityProviderName = EXCLUDED.capacityProviderName,
    clusterArn = EXCLUDED.clusterArn,
    connectivity = EXCLUDED.connectivity,
    connectivityAt = EXCLUDED.connectivityAt,
    containerInstanceArn = EXCLUDED.containerInstanceArn,
    containers = EXCLUDED.containers,
    cpu = EXCLUDED.cpu,
    createdAt = EXCLUDED.createdAt,
    desiredStatus = EXCLUDED.desiredStatus,
    executionStoppedAt = EXCLUDED.executionStoppedAt,
    "group" = EXCLUDED."group",
    healthStatus = EXCLUDED.healthStatus,
    inferenceAccelerators = EXCLUDED.inferenceAccelerators,
    lastStatus = EXCLUDED.lastStatus,
    launchType = EXCLUDED.launchType,
    memory = EXCLUDED.memory,
    overrides = EXCLUDED.overrides,
    platformVersion = EXCLUDED.platformVersion,
    pullStartedAt = EXCLUDED.pullStartedAt,
    pullStoppedAt = EXCLUDED.pullStoppedAt,
    startedAt = EXCLUDED.startedAt,
    startedBy = EXCLUDED.startedBy,
    stopCode = EXCLUDED.stopCode,
    stoppedAt = EXCLUDED.stoppedAt,
    stoppedReason = EXCLUDED.stoppedReason,
    stoppingAt = EXCLUDED.stoppingAt,
    tags = EXCLUDED.tags,
    taskArn = EXCLUDED.taskArn,
    taskDefinitionArn = EXCLUDED.taskDefinitionArn,
    version = EXCLUDED.version,
    _tags = EXCLUDED._tags,
    _cluster_id = EXCLUDED._cluster_id,
    _account_id = EXCLUDED._account_id
  ;


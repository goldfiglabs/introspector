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
  attachments.attr_value::jsonb AS attachments,
  attributes.attr_value::jsonb AS attributes,
  availabilityzone.attr_value #>> '{}' AS availabilityzone,
  capacityprovidername.attr_value #>> '{}' AS capacityprovidername,
  clusterarn.attr_value #>> '{}' AS clusterarn,
  connectivity.attr_value #>> '{}' AS connectivity,
  (TO_TIMESTAMP(connectivityat.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS connectivityat,
  containerinstancearn.attr_value #>> '{}' AS containerinstancearn,
  containers.attr_value::jsonb AS containers,
  cpu.attr_value #>> '{}' AS cpu,
  (TO_TIMESTAMP(createdat.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS createdat,
  desiredstatus.attr_value #>> '{}' AS desiredstatus,
  (TO_TIMESTAMP(executionstoppedat.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS executionstoppedat,
  "group".attr_value #>> '{}' AS group,
  healthstatus.attr_value #>> '{}' AS healthstatus,
  inferenceaccelerators.attr_value::jsonb AS inferenceaccelerators,
  laststatus.attr_value #>> '{}' AS laststatus,
  launchtype.attr_value #>> '{}' AS launchtype,
  memory.attr_value #>> '{}' AS memory,
  overrides.attr_value::jsonb AS overrides,
  platformversion.attr_value #>> '{}' AS platformversion,
  (TO_TIMESTAMP(pullstartedat.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS pullstartedat,
  (TO_TIMESTAMP(pullstoppedat.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS pullstoppedat,
  (TO_TIMESTAMP(startedat.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS startedat,
  startedby.attr_value #>> '{}' AS startedby,
  stopcode.attr_value #>> '{}' AS stopcode,
  (TO_TIMESTAMP(stoppedat.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS stoppedat,
  stoppedreason.attr_value #>> '{}' AS stoppedreason,
  (TO_TIMESTAMP(stoppingat.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS stoppingat,
  tags.attr_value::jsonb AS tags,
  taskarn.attr_value #>> '{}' AS taskarn,
  taskdefinitionarn.attr_value #>> '{}' AS taskdefinitionarn,
  (version.attr_value #>> '{}')::bigint AS version,
  _tags.attr_value::jsonb AS _tags,
  
    _cluster_id.target_id AS _cluster_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN resource_attribute AS attachments
    ON attachments.resource_id = R.id
    AND attachments.type = 'provider'
    AND lower(attachments.attr_name) = 'attachments'
    AND attachments.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS attributes
    ON attributes.resource_id = R.id
    AND attributes.type = 'provider'
    AND lower(attributes.attr_name) = 'attributes'
    AND attributes.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS availabilityzone
    ON availabilityzone.resource_id = R.id
    AND availabilityzone.type = 'provider'
    AND lower(availabilityzone.attr_name) = 'availabilityzone'
    AND availabilityzone.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS capacityprovidername
    ON capacityprovidername.resource_id = R.id
    AND capacityprovidername.type = 'provider'
    AND lower(capacityprovidername.attr_name) = 'capacityprovidername'
    AND capacityprovidername.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS clusterarn
    ON clusterarn.resource_id = R.id
    AND clusterarn.type = 'provider'
    AND lower(clusterarn.attr_name) = 'clusterarn'
    AND clusterarn.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS connectivity
    ON connectivity.resource_id = R.id
    AND connectivity.type = 'provider'
    AND lower(connectivity.attr_name) = 'connectivity'
    AND connectivity.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS connectivityat
    ON connectivityat.resource_id = R.id
    AND connectivityat.type = 'provider'
    AND lower(connectivityat.attr_name) = 'connectivityat'
    AND connectivityat.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS containerinstancearn
    ON containerinstancearn.resource_id = R.id
    AND containerinstancearn.type = 'provider'
    AND lower(containerinstancearn.attr_name) = 'containerinstancearn'
    AND containerinstancearn.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS containers
    ON containers.resource_id = R.id
    AND containers.type = 'provider'
    AND lower(containers.attr_name) = 'containers'
    AND containers.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS cpu
    ON cpu.resource_id = R.id
    AND cpu.type = 'provider'
    AND lower(cpu.attr_name) = 'cpu'
    AND cpu.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS createdat
    ON createdat.resource_id = R.id
    AND createdat.type = 'provider'
    AND lower(createdat.attr_name) = 'createdat'
    AND createdat.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS desiredstatus
    ON desiredstatus.resource_id = R.id
    AND desiredstatus.type = 'provider'
    AND lower(desiredstatus.attr_name) = 'desiredstatus'
    AND desiredstatus.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS executionstoppedat
    ON executionstoppedat.resource_id = R.id
    AND executionstoppedat.type = 'provider'
    AND lower(executionstoppedat.attr_name) = 'executionstoppedat'
    AND executionstoppedat.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS "group"
    ON "group".resource_id = R.id
    AND "group".type = 'provider'
    AND lower("group".attr_name) = 'group'
    AND "group".provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS healthstatus
    ON healthstatus.resource_id = R.id
    AND healthstatus.type = 'provider'
    AND lower(healthstatus.attr_name) = 'healthstatus'
    AND healthstatus.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS inferenceaccelerators
    ON inferenceaccelerators.resource_id = R.id
    AND inferenceaccelerators.type = 'provider'
    AND lower(inferenceaccelerators.attr_name) = 'inferenceaccelerators'
    AND inferenceaccelerators.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS laststatus
    ON laststatus.resource_id = R.id
    AND laststatus.type = 'provider'
    AND lower(laststatus.attr_name) = 'laststatus'
    AND laststatus.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS launchtype
    ON launchtype.resource_id = R.id
    AND launchtype.type = 'provider'
    AND lower(launchtype.attr_name) = 'launchtype'
    AND launchtype.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS memory
    ON memory.resource_id = R.id
    AND memory.type = 'provider'
    AND lower(memory.attr_name) = 'memory'
    AND memory.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS overrides
    ON overrides.resource_id = R.id
    AND overrides.type = 'provider'
    AND lower(overrides.attr_name) = 'overrides'
    AND overrides.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS platformversion
    ON platformversion.resource_id = R.id
    AND platformversion.type = 'provider'
    AND lower(platformversion.attr_name) = 'platformversion'
    AND platformversion.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS pullstartedat
    ON pullstartedat.resource_id = R.id
    AND pullstartedat.type = 'provider'
    AND lower(pullstartedat.attr_name) = 'pullstartedat'
    AND pullstartedat.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS pullstoppedat
    ON pullstoppedat.resource_id = R.id
    AND pullstoppedat.type = 'provider'
    AND lower(pullstoppedat.attr_name) = 'pullstoppedat'
    AND pullstoppedat.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS startedat
    ON startedat.resource_id = R.id
    AND startedat.type = 'provider'
    AND lower(startedat.attr_name) = 'startedat'
    AND startedat.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS startedby
    ON startedby.resource_id = R.id
    AND startedby.type = 'provider'
    AND lower(startedby.attr_name) = 'startedby'
    AND startedby.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS stopcode
    ON stopcode.resource_id = R.id
    AND stopcode.type = 'provider'
    AND lower(stopcode.attr_name) = 'stopcode'
    AND stopcode.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS stoppedat
    ON stoppedat.resource_id = R.id
    AND stoppedat.type = 'provider'
    AND lower(stoppedat.attr_name) = 'stoppedat'
    AND stoppedat.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS stoppedreason
    ON stoppedreason.resource_id = R.id
    AND stoppedreason.type = 'provider'
    AND lower(stoppedreason.attr_name) = 'stoppedreason'
    AND stoppedreason.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS stoppingat
    ON stoppingat.resource_id = R.id
    AND stoppingat.type = 'provider'
    AND lower(stoppingat.attr_name) = 'stoppingat'
    AND stoppingat.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS tags
    ON tags.resource_id = R.id
    AND tags.type = 'provider'
    AND lower(tags.attr_name) = 'tags'
    AND tags.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS taskarn
    ON taskarn.resource_id = R.id
    AND taskarn.type = 'provider'
    AND lower(taskarn.attr_name) = 'taskarn'
    AND taskarn.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS taskdefinitionarn
    ON taskdefinitionarn.resource_id = R.id
    AND taskdefinitionarn.type = 'provider'
    AND lower(taskdefinitionarn.attr_name) = 'taskdefinitionarn'
    AND taskdefinitionarn.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS version
    ON version.resource_id = R.id
    AND version.type = 'provider'
    AND lower(version.attr_name) = 'version'
    AND version.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS _tags
    ON _tags.resource_id = R.id
    AND _tags.type = 'Metadata'
    AND lower(_tags.attr_name) = 'tags'
    AND _tags.provider_account_id = R.provider_account_id
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
      _aws_organizations_account_relation.resource_id AS resource_id,
      _aws_organizations_account.id AS target_id
    FROM
    (
      SELECT
        _aws_organizations_account_relation.resource_id AS resource_id
      FROM
        resource_relation AS _aws_organizations_account_relation
        INNER JOIN resource AS _aws_organizations_account
          ON _aws_organizations_account_relation.target_id = _aws_organizations_account.id
          AND _aws_organizations_account.provider_type = 'Account'
          AND _aws_organizations_account.service = 'organizations'
      WHERE
        _aws_organizations_account_relation.relation = 'in'
        AND _aws_organizations_account_relation.provider_account_id = :provider_account_id
      GROUP BY _aws_organizations_account_relation.resource_id
      HAVING COUNT(*) = 1
    ) AS unique_account_mapping
    INNER JOIN resource_relation AS _aws_organizations_account_relation
      ON _aws_organizations_account_relation.resource_id = unique_account_mapping.resource_id
    INNER JOIN resource AS _aws_organizations_account
      ON _aws_organizations_account_relation.target_id = _aws_organizations_account.id
      AND _aws_organizations_account.provider_type = 'Account'
      AND _aws_organizations_account.service = 'organizations'
      AND _aws_organizations_account_relation.provider_account_id = :provider_account_id
    WHERE
        _aws_organizations_account_relation.relation = 'in'
        AND _aws_organizations_account_relation.provider_account_id = :provider_account_id
  ) AS _account_id ON _account_id.resource_id = R.id
  WHERE
  R.provider_account_id = :provider_account_id
  AND PA.provider = 'aws'
  AND R.provider_type = 'Task'
  AND R.service = 'ecs'
ON CONFLICT (_id) DO UPDATE
SET
    attachments = EXCLUDED.attachments,
    attributes = EXCLUDED.attributes,
    availabilityzone = EXCLUDED.availabilityzone,
    capacityprovidername = EXCLUDED.capacityprovidername,
    clusterarn = EXCLUDED.clusterarn,
    connectivity = EXCLUDED.connectivity,
    connectivityat = EXCLUDED.connectivityat,
    containerinstancearn = EXCLUDED.containerinstancearn,
    containers = EXCLUDED.containers,
    cpu = EXCLUDED.cpu,
    createdat = EXCLUDED.createdat,
    desiredstatus = EXCLUDED.desiredstatus,
    executionstoppedat = EXCLUDED.executionstoppedat,
    "group" = EXCLUDED."group",
    healthstatus = EXCLUDED.healthstatus,
    inferenceaccelerators = EXCLUDED.inferenceaccelerators,
    laststatus = EXCLUDED.laststatus,
    launchtype = EXCLUDED.launchtype,
    memory = EXCLUDED.memory,
    overrides = EXCLUDED.overrides,
    platformversion = EXCLUDED.platformversion,
    pullstartedat = EXCLUDED.pullstartedat,
    pullstoppedat = EXCLUDED.pullstoppedat,
    startedat = EXCLUDED.startedat,
    startedby = EXCLUDED.startedby,
    stopcode = EXCLUDED.stopcode,
    stoppedat = EXCLUDED.stoppedat,
    stoppedreason = EXCLUDED.stoppedreason,
    stoppingat = EXCLUDED.stoppingat,
    tags = EXCLUDED.tags,
    taskarn = EXCLUDED.taskarn,
    taskdefinitionarn = EXCLUDED.taskdefinitionarn,
    version = EXCLUDED.version,
    _tags = EXCLUDED._tags,
    _cluster_id = EXCLUDED._cluster_id,
    _account_id = EXCLUDED._account_id
  ;


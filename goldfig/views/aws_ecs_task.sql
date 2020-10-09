DROP MATERIALIZED VIEW IF EXISTS aws_ecs_task CASCADE;

CREATE MATERIALIZED VIEW aws_ecs_task AS
SELECT
  R.id AS resource_id,
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
  LEFT JOIN resource_attribute AS attributes
    ON attributes.resource_id = R.id
    AND attributes.type = 'provider'
    AND lower(attributes.attr_name) = 'attributes'
  LEFT JOIN resource_attribute AS availabilityzone
    ON availabilityzone.resource_id = R.id
    AND availabilityzone.type = 'provider'
    AND lower(availabilityzone.attr_name) = 'availabilityzone'
  LEFT JOIN resource_attribute AS capacityprovidername
    ON capacityprovidername.resource_id = R.id
    AND capacityprovidername.type = 'provider'
    AND lower(capacityprovidername.attr_name) = 'capacityprovidername'
  LEFT JOIN resource_attribute AS clusterarn
    ON clusterarn.resource_id = R.id
    AND clusterarn.type = 'provider'
    AND lower(clusterarn.attr_name) = 'clusterarn'
  LEFT JOIN resource_attribute AS connectivity
    ON connectivity.resource_id = R.id
    AND connectivity.type = 'provider'
    AND lower(connectivity.attr_name) = 'connectivity'
  LEFT JOIN resource_attribute AS connectivityat
    ON connectivityat.resource_id = R.id
    AND connectivityat.type = 'provider'
    AND lower(connectivityat.attr_name) = 'connectivityat'
  LEFT JOIN resource_attribute AS containerinstancearn
    ON containerinstancearn.resource_id = R.id
    AND containerinstancearn.type = 'provider'
    AND lower(containerinstancearn.attr_name) = 'containerinstancearn'
  LEFT JOIN resource_attribute AS containers
    ON containers.resource_id = R.id
    AND containers.type = 'provider'
    AND lower(containers.attr_name) = 'containers'
  LEFT JOIN resource_attribute AS cpu
    ON cpu.resource_id = R.id
    AND cpu.type = 'provider'
    AND lower(cpu.attr_name) = 'cpu'
  LEFT JOIN resource_attribute AS createdat
    ON createdat.resource_id = R.id
    AND createdat.type = 'provider'
    AND lower(createdat.attr_name) = 'createdat'
  LEFT JOIN resource_attribute AS desiredstatus
    ON desiredstatus.resource_id = R.id
    AND desiredstatus.type = 'provider'
    AND lower(desiredstatus.attr_name) = 'desiredstatus'
  LEFT JOIN resource_attribute AS executionstoppedat
    ON executionstoppedat.resource_id = R.id
    AND executionstoppedat.type = 'provider'
    AND lower(executionstoppedat.attr_name) = 'executionstoppedat'
  LEFT JOIN resource_attribute AS "group"
    ON "group".resource_id = R.id
    AND "group".type = 'provider'
    AND lower("group".attr_name) = 'group'
  LEFT JOIN resource_attribute AS healthstatus
    ON healthstatus.resource_id = R.id
    AND healthstatus.type = 'provider'
    AND lower(healthstatus.attr_name) = 'healthstatus'
  LEFT JOIN resource_attribute AS inferenceaccelerators
    ON inferenceaccelerators.resource_id = R.id
    AND inferenceaccelerators.type = 'provider'
    AND lower(inferenceaccelerators.attr_name) = 'inferenceaccelerators'
  LEFT JOIN resource_attribute AS laststatus
    ON laststatus.resource_id = R.id
    AND laststatus.type = 'provider'
    AND lower(laststatus.attr_name) = 'laststatus'
  LEFT JOIN resource_attribute AS launchtype
    ON launchtype.resource_id = R.id
    AND launchtype.type = 'provider'
    AND lower(launchtype.attr_name) = 'launchtype'
  LEFT JOIN resource_attribute AS memory
    ON memory.resource_id = R.id
    AND memory.type = 'provider'
    AND lower(memory.attr_name) = 'memory'
  LEFT JOIN resource_attribute AS overrides
    ON overrides.resource_id = R.id
    AND overrides.type = 'provider'
    AND lower(overrides.attr_name) = 'overrides'
  LEFT JOIN resource_attribute AS platformversion
    ON platformversion.resource_id = R.id
    AND platformversion.type = 'provider'
    AND lower(platformversion.attr_name) = 'platformversion'
  LEFT JOIN resource_attribute AS pullstartedat
    ON pullstartedat.resource_id = R.id
    AND pullstartedat.type = 'provider'
    AND lower(pullstartedat.attr_name) = 'pullstartedat'
  LEFT JOIN resource_attribute AS pullstoppedat
    ON pullstoppedat.resource_id = R.id
    AND pullstoppedat.type = 'provider'
    AND lower(pullstoppedat.attr_name) = 'pullstoppedat'
  LEFT JOIN resource_attribute AS startedat
    ON startedat.resource_id = R.id
    AND startedat.type = 'provider'
    AND lower(startedat.attr_name) = 'startedat'
  LEFT JOIN resource_attribute AS startedby
    ON startedby.resource_id = R.id
    AND startedby.type = 'provider'
    AND lower(startedby.attr_name) = 'startedby'
  LEFT JOIN resource_attribute AS stopcode
    ON stopcode.resource_id = R.id
    AND stopcode.type = 'provider'
    AND lower(stopcode.attr_name) = 'stopcode'
  LEFT JOIN resource_attribute AS stoppedat
    ON stoppedat.resource_id = R.id
    AND stoppedat.type = 'provider'
    AND lower(stoppedat.attr_name) = 'stoppedat'
  LEFT JOIN resource_attribute AS stoppedreason
    ON stoppedreason.resource_id = R.id
    AND stoppedreason.type = 'provider'
    AND lower(stoppedreason.attr_name) = 'stoppedreason'
  LEFT JOIN resource_attribute AS stoppingat
    ON stoppingat.resource_id = R.id
    AND stoppingat.type = 'provider'
    AND lower(stoppingat.attr_name) = 'stoppingat'
  LEFT JOIN resource_attribute AS tags
    ON tags.resource_id = R.id
    AND tags.type = 'provider'
    AND lower(tags.attr_name) = 'tags'
  LEFT JOIN resource_attribute AS taskarn
    ON taskarn.resource_id = R.id
    AND taskarn.type = 'provider'
    AND lower(taskarn.attr_name) = 'taskarn'
  LEFT JOIN resource_attribute AS taskdefinitionarn
    ON taskdefinitionarn.resource_id = R.id
    AND taskdefinitionarn.type = 'provider'
    AND lower(taskdefinitionarn.attr_name) = 'taskdefinitionarn'
  LEFT JOIN resource_attribute AS version
    ON version.resource_id = R.id
    AND version.type = 'provider'
    AND lower(version.attr_name) = 'version'
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
    WHERE
      _aws_ecs_cluster_relation.relation = 'belongs-to'
  ) AS _cluster_id ON _cluster_id.resource_id = R.id
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
  AND LOWER(R.provider_type) = 'task'
  AND R.service = 'ecs'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_ecs_task;

COMMENT ON MATERIALIZED VIEW aws_ecs_task IS 'ecs task resources and their associated attributes.';


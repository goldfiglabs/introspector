DROP MATERIALIZED VIEW IF EXISTS aws_ecs_task CASCADE;

CREATE MATERIALIZED VIEW aws_ecs_task AS
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
  LEFT JOIN attrs AS attachments
    ON attachments.id = R.id
    AND attachments.attr_name = 'attachments'
  LEFT JOIN attrs AS attributes
    ON attributes.id = R.id
    AND attributes.attr_name = 'attributes'
  LEFT JOIN attrs AS availabilityzone
    ON availabilityzone.id = R.id
    AND availabilityzone.attr_name = 'availabilityzone'
  LEFT JOIN attrs AS capacityprovidername
    ON capacityprovidername.id = R.id
    AND capacityprovidername.attr_name = 'capacityprovidername'
  LEFT JOIN attrs AS clusterarn
    ON clusterarn.id = R.id
    AND clusterarn.attr_name = 'clusterarn'
  LEFT JOIN attrs AS connectivity
    ON connectivity.id = R.id
    AND connectivity.attr_name = 'connectivity'
  LEFT JOIN attrs AS connectivityat
    ON connectivityat.id = R.id
    AND connectivityat.attr_name = 'connectivityat'
  LEFT JOIN attrs AS containerinstancearn
    ON containerinstancearn.id = R.id
    AND containerinstancearn.attr_name = 'containerinstancearn'
  LEFT JOIN attrs AS containers
    ON containers.id = R.id
    AND containers.attr_name = 'containers'
  LEFT JOIN attrs AS cpu
    ON cpu.id = R.id
    AND cpu.attr_name = 'cpu'
  LEFT JOIN attrs AS createdat
    ON createdat.id = R.id
    AND createdat.attr_name = 'createdat'
  LEFT JOIN attrs AS desiredstatus
    ON desiredstatus.id = R.id
    AND desiredstatus.attr_name = 'desiredstatus'
  LEFT JOIN attrs AS executionstoppedat
    ON executionstoppedat.id = R.id
    AND executionstoppedat.attr_name = 'executionstoppedat'
  LEFT JOIN attrs AS "group"
    ON "group".id = R.id
    AND "group".attr_name = 'group'
  LEFT JOIN attrs AS healthstatus
    ON healthstatus.id = R.id
    AND healthstatus.attr_name = 'healthstatus'
  LEFT JOIN attrs AS inferenceaccelerators
    ON inferenceaccelerators.id = R.id
    AND inferenceaccelerators.attr_name = 'inferenceaccelerators'
  LEFT JOIN attrs AS laststatus
    ON laststatus.id = R.id
    AND laststatus.attr_name = 'laststatus'
  LEFT JOIN attrs AS launchtype
    ON launchtype.id = R.id
    AND launchtype.attr_name = 'launchtype'
  LEFT JOIN attrs AS memory
    ON memory.id = R.id
    AND memory.attr_name = 'memory'
  LEFT JOIN attrs AS overrides
    ON overrides.id = R.id
    AND overrides.attr_name = 'overrides'
  LEFT JOIN attrs AS platformversion
    ON platformversion.id = R.id
    AND platformversion.attr_name = 'platformversion'
  LEFT JOIN attrs AS pullstartedat
    ON pullstartedat.id = R.id
    AND pullstartedat.attr_name = 'pullstartedat'
  LEFT JOIN attrs AS pullstoppedat
    ON pullstoppedat.id = R.id
    AND pullstoppedat.attr_name = 'pullstoppedat'
  LEFT JOIN attrs AS startedat
    ON startedat.id = R.id
    AND startedat.attr_name = 'startedat'
  LEFT JOIN attrs AS startedby
    ON startedby.id = R.id
    AND startedby.attr_name = 'startedby'
  LEFT JOIN attrs AS stopcode
    ON stopcode.id = R.id
    AND stopcode.attr_name = 'stopcode'
  LEFT JOIN attrs AS stoppedat
    ON stoppedat.id = R.id
    AND stoppedat.attr_name = 'stoppedat'
  LEFT JOIN attrs AS stoppedreason
    ON stoppedreason.id = R.id
    AND stoppedreason.attr_name = 'stoppedreason'
  LEFT JOIN attrs AS stoppingat
    ON stoppingat.id = R.id
    AND stoppingat.attr_name = 'stoppingat'
  LEFT JOIN attrs AS tags
    ON tags.id = R.id
    AND tags.attr_name = 'tags'
  LEFT JOIN attrs AS taskarn
    ON taskarn.id = R.id
    AND taskarn.attr_name = 'taskarn'
  LEFT JOIN attrs AS taskdefinitionarn
    ON taskdefinitionarn.id = R.id
    AND taskdefinitionarn.attr_name = 'taskdefinitionarn'
  LEFT JOIN attrs AS version
    ON version.id = R.id
    AND version.attr_name = 'version'
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


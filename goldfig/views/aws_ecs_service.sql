DROP MATERIALIZED VIEW IF EXISTS aws_ecs_service CASCADE;

CREATE MATERIALIZED VIEW aws_ecs_service AS
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
  servicearn.attr_value #>> '{}' AS servicearn,
  servicename.attr_value #>> '{}' AS servicename,
  clusterarn.attr_value #>> '{}' AS clusterarn,
  loadbalancers.attr_value::jsonb AS loadbalancers,
  serviceregistries.attr_value::jsonb AS serviceregistries,
  status.attr_value #>> '{}' AS status,
  (desiredcount.attr_value #>> '{}')::integer AS desiredcount,
  (runningcount.attr_value #>> '{}')::integer AS runningcount,
  (pendingcount.attr_value #>> '{}')::integer AS pendingcount,
  launchtype.attr_value #>> '{}' AS launchtype,
  capacityproviderstrategy.attr_value::jsonb AS capacityproviderstrategy,
  platformversion.attr_value #>> '{}' AS platformversion,
  taskdefinition.attr_value #>> '{}' AS taskdefinition,
  deploymentconfiguration.attr_value::jsonb AS deploymentconfiguration,
  tasksets.attr_value::jsonb AS tasksets,
  deployments.attr_value::jsonb AS deployments,
  rolearn.attr_value #>> '{}' AS rolearn,
  events.attr_value::jsonb AS events,
  (TO_TIMESTAMP(createdat.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS createdat,
  placementconstraints.attr_value::jsonb AS placementconstraints,
  placementstrategy.attr_value::jsonb AS placementstrategy,
  networkconfiguration.attr_value::jsonb AS networkconfiguration,
  (healthcheckgraceperiodseconds.attr_value #>> '{}')::integer AS healthcheckgraceperiodseconds,
  schedulingstrategy.attr_value #>> '{}' AS schedulingstrategy,
  deploymentcontroller.attr_value::jsonb AS deploymentcontroller,
  tags.attr_value::jsonb AS tags,
  createdby.attr_value #>> '{}' AS createdby,
  (enableecsmanagedtags.attr_value #>> '{}')::boolean AS enableecsmanagedtags,
  propagatetags.attr_value #>> '{}' AS propagatetags,
  
    _cluster_id.target_id AS _cluster_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN attrs AS servicearn
    ON servicearn.id = R.id
    AND servicearn.attr_name = 'servicearn'
  LEFT JOIN attrs AS servicename
    ON servicename.id = R.id
    AND servicename.attr_name = 'servicename'
  LEFT JOIN attrs AS clusterarn
    ON clusterarn.id = R.id
    AND clusterarn.attr_name = 'clusterarn'
  LEFT JOIN attrs AS loadbalancers
    ON loadbalancers.id = R.id
    AND loadbalancers.attr_name = 'loadbalancers'
  LEFT JOIN attrs AS serviceregistries
    ON serviceregistries.id = R.id
    AND serviceregistries.attr_name = 'serviceregistries'
  LEFT JOIN attrs AS status
    ON status.id = R.id
    AND status.attr_name = 'status'
  LEFT JOIN attrs AS desiredcount
    ON desiredcount.id = R.id
    AND desiredcount.attr_name = 'desiredcount'
  LEFT JOIN attrs AS runningcount
    ON runningcount.id = R.id
    AND runningcount.attr_name = 'runningcount'
  LEFT JOIN attrs AS pendingcount
    ON pendingcount.id = R.id
    AND pendingcount.attr_name = 'pendingcount'
  LEFT JOIN attrs AS launchtype
    ON launchtype.id = R.id
    AND launchtype.attr_name = 'launchtype'
  LEFT JOIN attrs AS capacityproviderstrategy
    ON capacityproviderstrategy.id = R.id
    AND capacityproviderstrategy.attr_name = 'capacityproviderstrategy'
  LEFT JOIN attrs AS platformversion
    ON platformversion.id = R.id
    AND platformversion.attr_name = 'platformversion'
  LEFT JOIN attrs AS taskdefinition
    ON taskdefinition.id = R.id
    AND taskdefinition.attr_name = 'taskdefinition'
  LEFT JOIN attrs AS deploymentconfiguration
    ON deploymentconfiguration.id = R.id
    AND deploymentconfiguration.attr_name = 'deploymentconfiguration'
  LEFT JOIN attrs AS tasksets
    ON tasksets.id = R.id
    AND tasksets.attr_name = 'tasksets'
  LEFT JOIN attrs AS deployments
    ON deployments.id = R.id
    AND deployments.attr_name = 'deployments'
  LEFT JOIN attrs AS rolearn
    ON rolearn.id = R.id
    AND rolearn.attr_name = 'rolearn'
  LEFT JOIN attrs AS events
    ON events.id = R.id
    AND events.attr_name = 'events'
  LEFT JOIN attrs AS createdat
    ON createdat.id = R.id
    AND createdat.attr_name = 'createdat'
  LEFT JOIN attrs AS placementconstraints
    ON placementconstraints.id = R.id
    AND placementconstraints.attr_name = 'placementconstraints'
  LEFT JOIN attrs AS placementstrategy
    ON placementstrategy.id = R.id
    AND placementstrategy.attr_name = 'placementstrategy'
  LEFT JOIN attrs AS networkconfiguration
    ON networkconfiguration.id = R.id
    AND networkconfiguration.attr_name = 'networkconfiguration'
  LEFT JOIN attrs AS healthcheckgraceperiodseconds
    ON healthcheckgraceperiodseconds.id = R.id
    AND healthcheckgraceperiodseconds.attr_name = 'healthcheckgraceperiodseconds'
  LEFT JOIN attrs AS schedulingstrategy
    ON schedulingstrategy.id = R.id
    AND schedulingstrategy.attr_name = 'schedulingstrategy'
  LEFT JOIN attrs AS deploymentcontroller
    ON deploymentcontroller.id = R.id
    AND deploymentcontroller.attr_name = 'deploymentcontroller'
  LEFT JOIN attrs AS tags
    ON tags.id = R.id
    AND tags.attr_name = 'tags'
  LEFT JOIN attrs AS createdby
    ON createdby.id = R.id
    AND createdby.attr_name = 'createdby'
  LEFT JOIN attrs AS enableecsmanagedtags
    ON enableecsmanagedtags.id = R.id
    AND enableecsmanagedtags.attr_name = 'enableecsmanagedtags'
  LEFT JOIN attrs AS propagatetags
    ON propagatetags.id = R.id
    AND propagatetags.attr_name = 'propagatetags'
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
  AND LOWER(R.provider_type) = 'service'
  AND R.service = 'ecs'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_ecs_service;

COMMENT ON MATERIALIZED VIEW aws_ecs_service IS 'ecs service resources and their associated attributes.';


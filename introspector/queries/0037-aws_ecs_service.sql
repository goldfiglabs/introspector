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
  _tags.attr_value::jsonb AS _tags,

    _cluster_id.target_id AS _cluster_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN resource_attribute AS servicearn
    ON servicearn.resource_id = R.id
    AND servicearn.type = 'provider'
    AND lower(servicearn.attr_name) = 'servicearn'
  LEFT JOIN resource_attribute AS servicename
    ON servicename.resource_id = R.id
    AND servicename.type = 'provider'
    AND lower(servicename.attr_name) = 'servicename'
  LEFT JOIN resource_attribute AS clusterarn
    ON clusterarn.resource_id = R.id
    AND clusterarn.type = 'provider'
    AND lower(clusterarn.attr_name) = 'clusterarn'
  LEFT JOIN resource_attribute AS loadbalancers
    ON loadbalancers.resource_id = R.id
    AND loadbalancers.type = 'provider'
    AND lower(loadbalancers.attr_name) = 'loadbalancers'
  LEFT JOIN resource_attribute AS serviceregistries
    ON serviceregistries.resource_id = R.id
    AND serviceregistries.type = 'provider'
    AND lower(serviceregistries.attr_name) = 'serviceregistries'
  LEFT JOIN resource_attribute AS status
    ON status.resource_id = R.id
    AND status.type = 'provider'
    AND lower(status.attr_name) = 'status'
  LEFT JOIN resource_attribute AS desiredcount
    ON desiredcount.resource_id = R.id
    AND desiredcount.type = 'provider'
    AND lower(desiredcount.attr_name) = 'desiredcount'
  LEFT JOIN resource_attribute AS runningcount
    ON runningcount.resource_id = R.id
    AND runningcount.type = 'provider'
    AND lower(runningcount.attr_name) = 'runningcount'
  LEFT JOIN resource_attribute AS pendingcount
    ON pendingcount.resource_id = R.id
    AND pendingcount.type = 'provider'
    AND lower(pendingcount.attr_name) = 'pendingcount'
  LEFT JOIN resource_attribute AS launchtype
    ON launchtype.resource_id = R.id
    AND launchtype.type = 'provider'
    AND lower(launchtype.attr_name) = 'launchtype'
  LEFT JOIN resource_attribute AS capacityproviderstrategy
    ON capacityproviderstrategy.resource_id = R.id
    AND capacityproviderstrategy.type = 'provider'
    AND lower(capacityproviderstrategy.attr_name) = 'capacityproviderstrategy'
  LEFT JOIN resource_attribute AS platformversion
    ON platformversion.resource_id = R.id
    AND platformversion.type = 'provider'
    AND lower(platformversion.attr_name) = 'platformversion'
  LEFT JOIN resource_attribute AS taskdefinition
    ON taskdefinition.resource_id = R.id
    AND taskdefinition.type = 'provider'
    AND lower(taskdefinition.attr_name) = 'taskdefinition'
  LEFT JOIN resource_attribute AS deploymentconfiguration
    ON deploymentconfiguration.resource_id = R.id
    AND deploymentconfiguration.type = 'provider'
    AND lower(deploymentconfiguration.attr_name) = 'deploymentconfiguration'
  LEFT JOIN resource_attribute AS tasksets
    ON tasksets.resource_id = R.id
    AND tasksets.type = 'provider'
    AND lower(tasksets.attr_name) = 'tasksets'
  LEFT JOIN resource_attribute AS deployments
    ON deployments.resource_id = R.id
    AND deployments.type = 'provider'
    AND lower(deployments.attr_name) = 'deployments'
  LEFT JOIN resource_attribute AS rolearn
    ON rolearn.resource_id = R.id
    AND rolearn.type = 'provider'
    AND lower(rolearn.attr_name) = 'rolearn'
  LEFT JOIN resource_attribute AS events
    ON events.resource_id = R.id
    AND events.type = 'provider'
    AND lower(events.attr_name) = 'events'
  LEFT JOIN resource_attribute AS createdat
    ON createdat.resource_id = R.id
    AND createdat.type = 'provider'
    AND lower(createdat.attr_name) = 'createdat'
  LEFT JOIN resource_attribute AS placementconstraints
    ON placementconstraints.resource_id = R.id
    AND placementconstraints.type = 'provider'
    AND lower(placementconstraints.attr_name) = 'placementconstraints'
  LEFT JOIN resource_attribute AS placementstrategy
    ON placementstrategy.resource_id = R.id
    AND placementstrategy.type = 'provider'
    AND lower(placementstrategy.attr_name) = 'placementstrategy'
  LEFT JOIN resource_attribute AS networkconfiguration
    ON networkconfiguration.resource_id = R.id
    AND networkconfiguration.type = 'provider'
    AND lower(networkconfiguration.attr_name) = 'networkconfiguration'
  LEFT JOIN resource_attribute AS healthcheckgraceperiodseconds
    ON healthcheckgraceperiodseconds.resource_id = R.id
    AND healthcheckgraceperiodseconds.type = 'provider'
    AND lower(healthcheckgraceperiodseconds.attr_name) = 'healthcheckgraceperiodseconds'
  LEFT JOIN resource_attribute AS schedulingstrategy
    ON schedulingstrategy.resource_id = R.id
    AND schedulingstrategy.type = 'provider'
    AND lower(schedulingstrategy.attr_name) = 'schedulingstrategy'
  LEFT JOIN resource_attribute AS deploymentcontroller
    ON deploymentcontroller.resource_id = R.id
    AND deploymentcontroller.type = 'provider'
    AND lower(deploymentcontroller.attr_name) = 'deploymentcontroller'
  LEFT JOIN resource_attribute AS tags
    ON tags.resource_id = R.id
    AND tags.type = 'provider'
    AND lower(tags.attr_name) = 'tags'
  LEFT JOIN resource_attribute AS createdby
    ON createdby.resource_id = R.id
    AND createdby.type = 'provider'
    AND lower(createdby.attr_name) = 'createdby'
  LEFT JOIN resource_attribute AS enableecsmanagedtags
    ON enableecsmanagedtags.resource_id = R.id
    AND enableecsmanagedtags.type = 'provider'
    AND lower(enableecsmanagedtags.attr_name) = 'enableecsmanagedtags'
  LEFT JOIN resource_attribute AS propagatetags
    ON propagatetags.resource_id = R.id
    AND propagatetags.type = 'provider'
    AND lower(propagatetags.attr_name) = 'propagatetags'
  LEFT JOIN resource_attribute AS _tags
    ON _tags.resource_id = R.id
    AND _tags.type = 'Metadata'
    AND lower(_tags.attr_name) = 'tags'
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
  AND R.provider_type = 'Service'
  AND R.service = 'ecs'
ON CONFLICT (_id) DO UPDATE
SET
    servicearn = EXCLUDED.servicearn,
    servicename = EXCLUDED.servicename,
    clusterarn = EXCLUDED.clusterarn,
    loadbalancers = EXCLUDED.loadbalancers,
    serviceregistries = EXCLUDED.serviceregistries,
    status = EXCLUDED.status,
    desiredcount = EXCLUDED.desiredcount,
    runningcount = EXCLUDED.runningcount,
    pendingcount = EXCLUDED.pendingcount,
    launchtype = EXCLUDED.launchtype,
    capacityproviderstrategy = EXCLUDED.capacityproviderstrategy,
    platformversion = EXCLUDED.platformversion,
    taskdefinition = EXCLUDED.taskdefinition,
    deploymentconfiguration = EXCLUDED.deploymentconfiguration,
    tasksets = EXCLUDED.tasksets,
    deployments = EXCLUDED.deployments,
    rolearn = EXCLUDED.rolearn,
    events = EXCLUDED.events,
    createdat = EXCLUDED.createdat,
    placementconstraints = EXCLUDED.placementconstraints,
    placementstrategy = EXCLUDED.placementstrategy,
    networkconfiguration = EXCLUDED.networkconfiguration,
    healthcheckgraceperiodseconds = EXCLUDED.healthcheckgraceperiodseconds,
    schedulingstrategy = EXCLUDED.schedulingstrategy,
    deploymentcontroller = EXCLUDED.deploymentcontroller,
    tags = EXCLUDED.tags,
    createdby = EXCLUDED.createdby,
    enableecsmanagedtags = EXCLUDED.enableecsmanagedtags,
    propagatetags = EXCLUDED.propagatetags,
    _tags = EXCLUDED._tags,
    _cluster_id = EXCLUDED._cluster_id,
    _account_id = EXCLUDED._account_id
  ;

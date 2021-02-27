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
  autoscalinggroupname.attr_value #>> '{}' AS autoscalinggroupname,
  autoscalinggrouparn.attr_value #>> '{}' AS autoscalinggrouparn,
  launchconfigurationname.attr_value #>> '{}' AS launchconfigurationname,
  launchtemplate.attr_value::jsonb AS launchtemplate,
  mixedinstancespolicy.attr_value::jsonb AS mixedinstancespolicy,
  (minsize.attr_value #>> '{}')::integer AS minsize,
  (maxsize.attr_value #>> '{}')::integer AS maxsize,
  (desiredcapacity.attr_value #>> '{}')::integer AS desiredcapacity,
  (defaultcooldown.attr_value #>> '{}')::integer AS defaultcooldown,
  availabilityzones.attr_value::jsonb AS availabilityzones,
  loadbalancernames.attr_value::jsonb AS loadbalancernames,
  targetgrouparns.attr_value::jsonb AS targetgrouparns,
  healthchecktype.attr_value #>> '{}' AS healthchecktype,
  (healthcheckgraceperiod.attr_value #>> '{}')::integer AS healthcheckgraceperiod,
  instances.attr_value::jsonb AS instances,
  (TO_TIMESTAMP(createdtime.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS createdtime,
  suspendedprocesses.attr_value::jsonb AS suspendedprocesses,
  placementgroup.attr_value #>> '{}' AS placementgroup,
  vpczoneidentifier.attr_value #>> '{}' AS vpczoneidentifier,
  enabledmetrics.attr_value::jsonb AS enabledmetrics,
  status.attr_value #>> '{}' AS status,
  tags.attr_value::jsonb AS tags,
  terminationpolicies.attr_value::jsonb AS terminationpolicies,
  (newinstancesprotectedfromscalein.attr_value #>> '{}')::boolean AS newinstancesprotectedfromscalein,
  servicelinkedrolearn.attr_value #>> '{}' AS servicelinkedrolearn,
  (maxinstancelifetime.attr_value #>> '{}')::integer AS maxinstancelifetime,
  (capacityrebalance.attr_value #>> '{}')::boolean AS capacityrebalance,
  _tags.attr_value::jsonb AS _tags,

    _launchconfiguration_id.target_id AS _launchconfiguration_id,
    _iam_role_id.target_id AS _iam_role_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN resource_attribute AS autoscalinggroupname
    ON autoscalinggroupname.resource_id = R.id
    AND autoscalinggroupname.type = 'provider'
    AND lower(autoscalinggroupname.attr_name) = 'autoscalinggroupname'
  LEFT JOIN resource_attribute AS autoscalinggrouparn
    ON autoscalinggrouparn.resource_id = R.id
    AND autoscalinggrouparn.type = 'provider'
    AND lower(autoscalinggrouparn.attr_name) = 'autoscalinggrouparn'
  LEFT JOIN resource_attribute AS launchconfigurationname
    ON launchconfigurationname.resource_id = R.id
    AND launchconfigurationname.type = 'provider'
    AND lower(launchconfigurationname.attr_name) = 'launchconfigurationname'
  LEFT JOIN resource_attribute AS launchtemplate
    ON launchtemplate.resource_id = R.id
    AND launchtemplate.type = 'provider'
    AND lower(launchtemplate.attr_name) = 'launchtemplate'
  LEFT JOIN resource_attribute AS mixedinstancespolicy
    ON mixedinstancespolicy.resource_id = R.id
    AND mixedinstancespolicy.type = 'provider'
    AND lower(mixedinstancespolicy.attr_name) = 'mixedinstancespolicy'
  LEFT JOIN resource_attribute AS minsize
    ON minsize.resource_id = R.id
    AND minsize.type = 'provider'
    AND lower(minsize.attr_name) = 'minsize'
  LEFT JOIN resource_attribute AS maxsize
    ON maxsize.resource_id = R.id
    AND maxsize.type = 'provider'
    AND lower(maxsize.attr_name) = 'maxsize'
  LEFT JOIN resource_attribute AS desiredcapacity
    ON desiredcapacity.resource_id = R.id
    AND desiredcapacity.type = 'provider'
    AND lower(desiredcapacity.attr_name) = 'desiredcapacity'
  LEFT JOIN resource_attribute AS defaultcooldown
    ON defaultcooldown.resource_id = R.id
    AND defaultcooldown.type = 'provider'
    AND lower(defaultcooldown.attr_name) = 'defaultcooldown'
  LEFT JOIN resource_attribute AS availabilityzones
    ON availabilityzones.resource_id = R.id
    AND availabilityzones.type = 'provider'
    AND lower(availabilityzones.attr_name) = 'availabilityzones'
  LEFT JOIN resource_attribute AS loadbalancernames
    ON loadbalancernames.resource_id = R.id
    AND loadbalancernames.type = 'provider'
    AND lower(loadbalancernames.attr_name) = 'loadbalancernames'
  LEFT JOIN resource_attribute AS targetgrouparns
    ON targetgrouparns.resource_id = R.id
    AND targetgrouparns.type = 'provider'
    AND lower(targetgrouparns.attr_name) = 'targetgrouparns'
  LEFT JOIN resource_attribute AS healthchecktype
    ON healthchecktype.resource_id = R.id
    AND healthchecktype.type = 'provider'
    AND lower(healthchecktype.attr_name) = 'healthchecktype'
  LEFT JOIN resource_attribute AS healthcheckgraceperiod
    ON healthcheckgraceperiod.resource_id = R.id
    AND healthcheckgraceperiod.type = 'provider'
    AND lower(healthcheckgraceperiod.attr_name) = 'healthcheckgraceperiod'
  LEFT JOIN resource_attribute AS instances
    ON instances.resource_id = R.id
    AND instances.type = 'provider'
    AND lower(instances.attr_name) = 'instances'
  LEFT JOIN resource_attribute AS createdtime
    ON createdtime.resource_id = R.id
    AND createdtime.type = 'provider'
    AND lower(createdtime.attr_name) = 'createdtime'
  LEFT JOIN resource_attribute AS suspendedprocesses
    ON suspendedprocesses.resource_id = R.id
    AND suspendedprocesses.type = 'provider'
    AND lower(suspendedprocesses.attr_name) = 'suspendedprocesses'
  LEFT JOIN resource_attribute AS placementgroup
    ON placementgroup.resource_id = R.id
    AND placementgroup.type = 'provider'
    AND lower(placementgroup.attr_name) = 'placementgroup'
  LEFT JOIN resource_attribute AS vpczoneidentifier
    ON vpczoneidentifier.resource_id = R.id
    AND vpczoneidentifier.type = 'provider'
    AND lower(vpczoneidentifier.attr_name) = 'vpczoneidentifier'
  LEFT JOIN resource_attribute AS enabledmetrics
    ON enabledmetrics.resource_id = R.id
    AND enabledmetrics.type = 'provider'
    AND lower(enabledmetrics.attr_name) = 'enabledmetrics'
  LEFT JOIN resource_attribute AS status
    ON status.resource_id = R.id
    AND status.type = 'provider'
    AND lower(status.attr_name) = 'status'
  LEFT JOIN resource_attribute AS tags
    ON tags.resource_id = R.id
    AND tags.type = 'provider'
    AND lower(tags.attr_name) = 'tags'
  LEFT JOIN resource_attribute AS terminationpolicies
    ON terminationpolicies.resource_id = R.id
    AND terminationpolicies.type = 'provider'
    AND lower(terminationpolicies.attr_name) = 'terminationpolicies'
  LEFT JOIN resource_attribute AS newinstancesprotectedfromscalein
    ON newinstancesprotectedfromscalein.resource_id = R.id
    AND newinstancesprotectedfromscalein.type = 'provider'
    AND lower(newinstancesprotectedfromscalein.attr_name) = 'newinstancesprotectedfromscalein'
  LEFT JOIN resource_attribute AS servicelinkedrolearn
    ON servicelinkedrolearn.resource_id = R.id
    AND servicelinkedrolearn.type = 'provider'
    AND lower(servicelinkedrolearn.attr_name) = 'servicelinkedrolearn'
  LEFT JOIN resource_attribute AS maxinstancelifetime
    ON maxinstancelifetime.resource_id = R.id
    AND maxinstancelifetime.type = 'provider'
    AND lower(maxinstancelifetime.attr_name) = 'maxinstancelifetime'
  LEFT JOIN resource_attribute AS capacityrebalance
    ON capacityrebalance.resource_id = R.id
    AND capacityrebalance.type = 'provider'
    AND lower(capacityrebalance.attr_name) = 'capacityrebalance'
  LEFT JOIN resource_attribute AS _tags
    ON _tags.resource_id = R.id
    AND _tags.type = 'Metadata'
    AND lower(_tags.attr_name) = 'tags'
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
    WHERE
      _aws_autoscaling_launchconfiguration_relation.relation = 'launches-with'
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
    WHERE
      _aws_iam_role_relation.relation = 'acts-as'
  ) AS _iam_role_id ON _iam_role_id.resource_id = R.id
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
  AND R.provider_type = 'AutoScalingGroup'
  AND R.service = 'autoscaling'
ON CONFLICT (_id) DO UPDATE
SET
    autoscalinggroupname = EXCLUDED.autoscalinggroupname,
    autoscalinggrouparn = EXCLUDED.autoscalinggrouparn,
    launchconfigurationname = EXCLUDED.launchconfigurationname,
    launchtemplate = EXCLUDED.launchtemplate,
    mixedinstancespolicy = EXCLUDED.mixedinstancespolicy,
    minsize = EXCLUDED.minsize,
    maxsize = EXCLUDED.maxsize,
    desiredcapacity = EXCLUDED.desiredcapacity,
    defaultcooldown = EXCLUDED.defaultcooldown,
    availabilityzones = EXCLUDED.availabilityzones,
    loadbalancernames = EXCLUDED.loadbalancernames,
    targetgrouparns = EXCLUDED.targetgrouparns,
    healthchecktype = EXCLUDED.healthchecktype,
    healthcheckgraceperiod = EXCLUDED.healthcheckgraceperiod,
    instances = EXCLUDED.instances,
    createdtime = EXCLUDED.createdtime,
    suspendedprocesses = EXCLUDED.suspendedprocesses,
    placementgroup = EXCLUDED.placementgroup,
    vpczoneidentifier = EXCLUDED.vpczoneidentifier,
    enabledmetrics = EXCLUDED.enabledmetrics,
    status = EXCLUDED.status,
    tags = EXCLUDED.tags,
    terminationpolicies = EXCLUDED.terminationpolicies,
    newinstancesprotectedfromscalein = EXCLUDED.newinstancesprotectedfromscalein,
    servicelinkedrolearn = EXCLUDED.servicelinkedrolearn,
    maxinstancelifetime = EXCLUDED.maxinstancelifetime,
    capacityrebalance = EXCLUDED.capacityrebalance,
    _tags = EXCLUDED._tags,
    _launchconfiguration_id = EXCLUDED._launchconfiguration_id,
    _iam_role_id = EXCLUDED._iam_role_id,
    _account_id = EXCLUDED._account_id
  ;

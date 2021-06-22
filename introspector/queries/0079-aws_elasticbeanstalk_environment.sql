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
  environmentid.attr_value #>> '{}' AS environmentid,
  applicationname.attr_value #>> '{}' AS applicationname,
  versionlabel.attr_value #>> '{}' AS versionlabel,
  solutionstackname.attr_value #>> '{}' AS solutionstackname,
  platformarn.attr_value #>> '{}' AS platformarn,
  templatename.attr_value #>> '{}' AS templatename,
  description.attr_value #>> '{}' AS description,
  endpointurl.attr_value #>> '{}' AS endpointurl,
  cname.attr_value #>> '{}' AS cname,
  (TO_TIMESTAMP(datecreated.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS datecreated,
  (TO_TIMESTAMP(dateupdated.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS dateupdated,
  status.attr_value #>> '{}' AS status,
  (abortableoperationinprogress.attr_value #>> '{}')::boolean AS abortableoperationinprogress,
  health.attr_value #>> '{}' AS health,
  healthstatus.attr_value #>> '{}' AS healthstatus,
  resources.attr_value::jsonb AS resources,
  tier.attr_value::jsonb AS tier,
  environmentlinks.attr_value::jsonb AS environmentlinks,
  environmentarn.attr_value #>> '{}' AS environmentarn,
  operationsrole.attr_value #>> '{}' AS operationsrole,
  tags.attr_value::jsonb AS tags,
  environmentname.attr_value #>> '{}' AS environmentname,
  autoscalinggroups.attr_value::jsonb AS autoscalinggroups,
  instances.attr_value::jsonb AS instances,
  launchconfigurations.attr_value::jsonb AS launchconfigurations,
  launchtemplates.attr_value::jsonb AS launchtemplates,
  loadbalancers.attr_value::jsonb AS loadbalancers,
  triggers.attr_value::jsonb AS triggers,
  queues.attr_value::jsonb AS queues,
  _tags.attr_value::jsonb AS _tags,
  
    _application_id.target_id AS _application_id,
    _applicationversion_id.target_id AS _applicationversion_id,
    _iam_role_id.target_id AS _iam_role_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN resource_attribute AS environmentid
    ON environmentid.resource_id = R.id
    AND environmentid.type = 'provider'
    AND lower(environmentid.attr_name) = 'environmentid'
    AND environmentid.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS applicationname
    ON applicationname.resource_id = R.id
    AND applicationname.type = 'provider'
    AND lower(applicationname.attr_name) = 'applicationname'
    AND applicationname.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS versionlabel
    ON versionlabel.resource_id = R.id
    AND versionlabel.type = 'provider'
    AND lower(versionlabel.attr_name) = 'versionlabel'
    AND versionlabel.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS solutionstackname
    ON solutionstackname.resource_id = R.id
    AND solutionstackname.type = 'provider'
    AND lower(solutionstackname.attr_name) = 'solutionstackname'
    AND solutionstackname.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS platformarn
    ON platformarn.resource_id = R.id
    AND platformarn.type = 'provider'
    AND lower(platformarn.attr_name) = 'platformarn'
    AND platformarn.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS templatename
    ON templatename.resource_id = R.id
    AND templatename.type = 'provider'
    AND lower(templatename.attr_name) = 'templatename'
    AND templatename.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS description
    ON description.resource_id = R.id
    AND description.type = 'provider'
    AND lower(description.attr_name) = 'description'
    AND description.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS endpointurl
    ON endpointurl.resource_id = R.id
    AND endpointurl.type = 'provider'
    AND lower(endpointurl.attr_name) = 'endpointurl'
    AND endpointurl.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS cname
    ON cname.resource_id = R.id
    AND cname.type = 'provider'
    AND lower(cname.attr_name) = 'cname'
    AND cname.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS datecreated
    ON datecreated.resource_id = R.id
    AND datecreated.type = 'provider'
    AND lower(datecreated.attr_name) = 'datecreated'
    AND datecreated.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS dateupdated
    ON dateupdated.resource_id = R.id
    AND dateupdated.type = 'provider'
    AND lower(dateupdated.attr_name) = 'dateupdated'
    AND dateupdated.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS status
    ON status.resource_id = R.id
    AND status.type = 'provider'
    AND lower(status.attr_name) = 'status'
    AND status.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS abortableoperationinprogress
    ON abortableoperationinprogress.resource_id = R.id
    AND abortableoperationinprogress.type = 'provider'
    AND lower(abortableoperationinprogress.attr_name) = 'abortableoperationinprogress'
    AND abortableoperationinprogress.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS health
    ON health.resource_id = R.id
    AND health.type = 'provider'
    AND lower(health.attr_name) = 'health'
    AND health.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS healthstatus
    ON healthstatus.resource_id = R.id
    AND healthstatus.type = 'provider'
    AND lower(healthstatus.attr_name) = 'healthstatus'
    AND healthstatus.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS resources
    ON resources.resource_id = R.id
    AND resources.type = 'provider'
    AND lower(resources.attr_name) = 'resources'
    AND resources.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS tier
    ON tier.resource_id = R.id
    AND tier.type = 'provider'
    AND lower(tier.attr_name) = 'tier'
    AND tier.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS environmentlinks
    ON environmentlinks.resource_id = R.id
    AND environmentlinks.type = 'provider'
    AND lower(environmentlinks.attr_name) = 'environmentlinks'
    AND environmentlinks.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS environmentarn
    ON environmentarn.resource_id = R.id
    AND environmentarn.type = 'provider'
    AND lower(environmentarn.attr_name) = 'environmentarn'
    AND environmentarn.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS operationsrole
    ON operationsrole.resource_id = R.id
    AND operationsrole.type = 'provider'
    AND lower(operationsrole.attr_name) = 'operationsrole'
    AND operationsrole.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS tags
    ON tags.resource_id = R.id
    AND tags.type = 'provider'
    AND lower(tags.attr_name) = 'tags'
    AND tags.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS environmentname
    ON environmentname.resource_id = R.id
    AND environmentname.type = 'provider'
    AND lower(environmentname.attr_name) = 'environmentname'
    AND environmentname.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS autoscalinggroups
    ON autoscalinggroups.resource_id = R.id
    AND autoscalinggroups.type = 'provider'
    AND lower(autoscalinggroups.attr_name) = 'autoscalinggroups'
    AND autoscalinggroups.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS instances
    ON instances.resource_id = R.id
    AND instances.type = 'provider'
    AND lower(instances.attr_name) = 'instances'
    AND instances.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS launchconfigurations
    ON launchconfigurations.resource_id = R.id
    AND launchconfigurations.type = 'provider'
    AND lower(launchconfigurations.attr_name) = 'launchconfigurations'
    AND launchconfigurations.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS launchtemplates
    ON launchtemplates.resource_id = R.id
    AND launchtemplates.type = 'provider'
    AND lower(launchtemplates.attr_name) = 'launchtemplates'
    AND launchtemplates.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS loadbalancers
    ON loadbalancers.resource_id = R.id
    AND loadbalancers.type = 'provider'
    AND lower(loadbalancers.attr_name) = 'loadbalancers'
    AND loadbalancers.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS triggers
    ON triggers.resource_id = R.id
    AND triggers.type = 'provider'
    AND lower(triggers.attr_name) = 'triggers'
    AND triggers.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS queues
    ON queues.resource_id = R.id
    AND queues.type = 'provider'
    AND lower(queues.attr_name) = 'queues'
    AND queues.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS _tags
    ON _tags.resource_id = R.id
    AND _tags.type = 'Metadata'
    AND lower(_tags.attr_name) = 'tags'
    AND _tags.provider_account_id = R.provider_account_id
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
  AND R.provider_type = 'Environment'
  AND R.service = 'elasticbeanstalk'
ON CONFLICT (_id) DO UPDATE
SET
    environmentid = EXCLUDED.environmentid,
    applicationname = EXCLUDED.applicationname,
    versionlabel = EXCLUDED.versionlabel,
    solutionstackname = EXCLUDED.solutionstackname,
    platformarn = EXCLUDED.platformarn,
    templatename = EXCLUDED.templatename,
    description = EXCLUDED.description,
    endpointurl = EXCLUDED.endpointurl,
    cname = EXCLUDED.cname,
    datecreated = EXCLUDED.datecreated,
    dateupdated = EXCLUDED.dateupdated,
    status = EXCLUDED.status,
    abortableoperationinprogress = EXCLUDED.abortableoperationinprogress,
    health = EXCLUDED.health,
    healthstatus = EXCLUDED.healthstatus,
    resources = EXCLUDED.resources,
    tier = EXCLUDED.tier,
    environmentlinks = EXCLUDED.environmentlinks,
    environmentarn = EXCLUDED.environmentarn,
    operationsrole = EXCLUDED.operationsrole,
    tags = EXCLUDED.tags,
    environmentname = EXCLUDED.environmentname,
    autoscalinggroups = EXCLUDED.autoscalinggroups,
    instances = EXCLUDED.instances,
    launchconfigurations = EXCLUDED.launchconfigurations,
    launchtemplates = EXCLUDED.launchtemplates,
    loadbalancers = EXCLUDED.loadbalancers,
    triggers = EXCLUDED.triggers,
    queues = EXCLUDED.queues,
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
  WHERE
    aws_elasticbeanstalk_environment.provider_type = 'Environment'
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
  WHERE
    aws_elasticbeanstalk_environment.provider_type = 'Environment'
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
  WHERE
    aws_elasticbeanstalk_environment.provider_type = 'Environment'
    AND aws_elasticbeanstalk_environment.service = 'elasticbeanstalk'
ON CONFLICT (environment_id, instance_id)
DO NOTHING
;

INSERT INTO aws_cloudformation_stack (
  _id,
  uri,
  provider_account_id,
  stackid,
  stackname,
  changesetid,
  description,
  parameters,
  creationtime,
  deletiontime,
  lastupdatedtime,
  rollbackconfiguration,
  stackstatus,
  stackstatusreason,
  disablerollback,
  notificationarns,
  timeoutinminutes,
  capabilities,
  outputs,
  rolearn,
  tags,
  enableterminationprotection,
  parentid,
  rootid,
  driftinformation,
  _tags,
  _iam_role_id,_account_id
)
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  stackid.attr_value #>> '{}' AS stackid,
  stackname.attr_value #>> '{}' AS stackname,
  changesetid.attr_value #>> '{}' AS changesetid,
  description.attr_value #>> '{}' AS description,
  parameters.attr_value::jsonb AS parameters,
  (TO_TIMESTAMP(creationtime.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS creationtime,
  (TO_TIMESTAMP(deletiontime.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS deletiontime,
  (TO_TIMESTAMP(lastupdatedtime.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS lastupdatedtime,
  rollbackconfiguration.attr_value::jsonb AS rollbackconfiguration,
  stackstatus.attr_value #>> '{}' AS stackstatus,
  stackstatusreason.attr_value #>> '{}' AS stackstatusreason,
  (disablerollback.attr_value #>> '{}')::boolean AS disablerollback,
  notificationarns.attr_value::jsonb AS notificationarns,
  (timeoutinminutes.attr_value #>> '{}')::integer AS timeoutinminutes,
  capabilities.attr_value::jsonb AS capabilities,
  outputs.attr_value::jsonb AS outputs,
  rolearn.attr_value #>> '{}' AS rolearn,
  tags.attr_value::jsonb AS tags,
  (enableterminationprotection.attr_value #>> '{}')::boolean AS enableterminationprotection,
  parentid.attr_value #>> '{}' AS parentid,
  rootid.attr_value #>> '{}' AS rootid,
  driftinformation.attr_value::jsonb AS driftinformation,
  _tags.attr_value::jsonb AS _tags,
  
    _iam_role_id.target_id AS _iam_role_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN resource_attribute AS stackid
    ON stackid.resource_id = R.id
    AND stackid.type = 'provider'
    AND lower(stackid.attr_name) = 'stackid'
    AND stackid.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS stackname
    ON stackname.resource_id = R.id
    AND stackname.type = 'provider'
    AND lower(stackname.attr_name) = 'stackname'
    AND stackname.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS changesetid
    ON changesetid.resource_id = R.id
    AND changesetid.type = 'provider'
    AND lower(changesetid.attr_name) = 'changesetid'
    AND changesetid.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS description
    ON description.resource_id = R.id
    AND description.type = 'provider'
    AND lower(description.attr_name) = 'description'
    AND description.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS parameters
    ON parameters.resource_id = R.id
    AND parameters.type = 'provider'
    AND lower(parameters.attr_name) = 'parameters'
    AND parameters.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS creationtime
    ON creationtime.resource_id = R.id
    AND creationtime.type = 'provider'
    AND lower(creationtime.attr_name) = 'creationtime'
    AND creationtime.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS deletiontime
    ON deletiontime.resource_id = R.id
    AND deletiontime.type = 'provider'
    AND lower(deletiontime.attr_name) = 'deletiontime'
    AND deletiontime.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS lastupdatedtime
    ON lastupdatedtime.resource_id = R.id
    AND lastupdatedtime.type = 'provider'
    AND lower(lastupdatedtime.attr_name) = 'lastupdatedtime'
    AND lastupdatedtime.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS rollbackconfiguration
    ON rollbackconfiguration.resource_id = R.id
    AND rollbackconfiguration.type = 'provider'
    AND lower(rollbackconfiguration.attr_name) = 'rollbackconfiguration'
    AND rollbackconfiguration.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS stackstatus
    ON stackstatus.resource_id = R.id
    AND stackstatus.type = 'provider'
    AND lower(stackstatus.attr_name) = 'stackstatus'
    AND stackstatus.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS stackstatusreason
    ON stackstatusreason.resource_id = R.id
    AND stackstatusreason.type = 'provider'
    AND lower(stackstatusreason.attr_name) = 'stackstatusreason'
    AND stackstatusreason.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS disablerollback
    ON disablerollback.resource_id = R.id
    AND disablerollback.type = 'provider'
    AND lower(disablerollback.attr_name) = 'disablerollback'
    AND disablerollback.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS notificationarns
    ON notificationarns.resource_id = R.id
    AND notificationarns.type = 'provider'
    AND lower(notificationarns.attr_name) = 'notificationarns'
    AND notificationarns.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS timeoutinminutes
    ON timeoutinminutes.resource_id = R.id
    AND timeoutinminutes.type = 'provider'
    AND lower(timeoutinminutes.attr_name) = 'timeoutinminutes'
    AND timeoutinminutes.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS capabilities
    ON capabilities.resource_id = R.id
    AND capabilities.type = 'provider'
    AND lower(capabilities.attr_name) = 'capabilities'
    AND capabilities.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS outputs
    ON outputs.resource_id = R.id
    AND outputs.type = 'provider'
    AND lower(outputs.attr_name) = 'outputs'
    AND outputs.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS rolearn
    ON rolearn.resource_id = R.id
    AND rolearn.type = 'provider'
    AND lower(rolearn.attr_name) = 'rolearn'
    AND rolearn.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS tags
    ON tags.resource_id = R.id
    AND tags.type = 'provider'
    AND lower(tags.attr_name) = 'tags'
    AND tags.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS enableterminationprotection
    ON enableterminationprotection.resource_id = R.id
    AND enableterminationprotection.type = 'provider'
    AND lower(enableterminationprotection.attr_name) = 'enableterminationprotection'
    AND enableterminationprotection.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS parentid
    ON parentid.resource_id = R.id
    AND parentid.type = 'provider'
    AND lower(parentid.attr_name) = 'parentid'
    AND parentid.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS rootid
    ON rootid.resource_id = R.id
    AND rootid.type = 'provider'
    AND lower(rootid.attr_name) = 'rootid'
    AND rootid.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS driftinformation
    ON driftinformation.resource_id = R.id
    AND driftinformation.type = 'provider'
    AND lower(driftinformation.attr_name) = 'driftinformation'
    AND driftinformation.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS _tags
    ON _tags.resource_id = R.id
    AND _tags.type = 'Metadata'
    AND lower(_tags.attr_name) = 'tags'
    AND _tags.provider_account_id = R.provider_account_id
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
  AND R.provider_type = 'Stack'
  AND R.service = 'cloudformation'
ON CONFLICT (_id) DO UPDATE
SET
    stackid = EXCLUDED.stackid,
    stackname = EXCLUDED.stackname,
    changesetid = EXCLUDED.changesetid,
    description = EXCLUDED.description,
    parameters = EXCLUDED.parameters,
    creationtime = EXCLUDED.creationtime,
    deletiontime = EXCLUDED.deletiontime,
    lastupdatedtime = EXCLUDED.lastupdatedtime,
    rollbackconfiguration = EXCLUDED.rollbackconfiguration,
    stackstatus = EXCLUDED.stackstatus,
    stackstatusreason = EXCLUDED.stackstatusreason,
    disablerollback = EXCLUDED.disablerollback,
    notificationarns = EXCLUDED.notificationarns,
    timeoutinminutes = EXCLUDED.timeoutinminutes,
    capabilities = EXCLUDED.capabilities,
    outputs = EXCLUDED.outputs,
    rolearn = EXCLUDED.rolearn,
    tags = EXCLUDED.tags,
    enableterminationprotection = EXCLUDED.enableterminationprotection,
    parentid = EXCLUDED.parentid,
    rootid = EXCLUDED.rootid,
    driftinformation = EXCLUDED.driftinformation,
    _tags = EXCLUDED._tags,
    _iam_role_id = EXCLUDED._iam_role_id,
    _account_id = EXCLUDED._account_id
  ;



INSERT INTO aws_cloudformation_stack_sns_topic
SELECT
  aws_cloudformation_stack.id AS stack_id,
  aws_sns_topic.id AS topic_id,
  aws_cloudformation_stack.provider_account_id AS provider_account_id
FROM
  resource AS aws_cloudformation_stack
  INNER JOIN resource_relation AS RR
    ON RR.resource_id = aws_cloudformation_stack.id
    AND RR.relation = 'publishes-to'
  INNER JOIN resource AS aws_sns_topic
    ON aws_sns_topic.id = RR.target_id
    AND aws_sns_topic.provider_type = 'Topic'
    AND aws_sns_topic.service = 'sns'
  WHERE
    aws_cloudformation_stack.provider_type = 'Stack'
    AND aws_cloudformation_stack.service = 'cloudformation'
ON CONFLICT (stack_id, topic_id)
DO NOTHING
;

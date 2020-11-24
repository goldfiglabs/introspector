DROP MATERIALIZED VIEW IF EXISTS aws_cloudformation_stack CASCADE;

CREATE MATERIALIZED VIEW aws_cloudformation_stack AS
SELECT
  R.id AS resource_id,
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
  LEFT JOIN resource_attribute AS stackname
    ON stackname.resource_id = R.id
    AND stackname.type = 'provider'
    AND lower(stackname.attr_name) = 'stackname'
  LEFT JOIN resource_attribute AS changesetid
    ON changesetid.resource_id = R.id
    AND changesetid.type = 'provider'
    AND lower(changesetid.attr_name) = 'changesetid'
  LEFT JOIN resource_attribute AS description
    ON description.resource_id = R.id
    AND description.type = 'provider'
    AND lower(description.attr_name) = 'description'
  LEFT JOIN resource_attribute AS parameters
    ON parameters.resource_id = R.id
    AND parameters.type = 'provider'
    AND lower(parameters.attr_name) = 'parameters'
  LEFT JOIN resource_attribute AS creationtime
    ON creationtime.resource_id = R.id
    AND creationtime.type = 'provider'
    AND lower(creationtime.attr_name) = 'creationtime'
  LEFT JOIN resource_attribute AS deletiontime
    ON deletiontime.resource_id = R.id
    AND deletiontime.type = 'provider'
    AND lower(deletiontime.attr_name) = 'deletiontime'
  LEFT JOIN resource_attribute AS lastupdatedtime
    ON lastupdatedtime.resource_id = R.id
    AND lastupdatedtime.type = 'provider'
    AND lower(lastupdatedtime.attr_name) = 'lastupdatedtime'
  LEFT JOIN resource_attribute AS rollbackconfiguration
    ON rollbackconfiguration.resource_id = R.id
    AND rollbackconfiguration.type = 'provider'
    AND lower(rollbackconfiguration.attr_name) = 'rollbackconfiguration'
  LEFT JOIN resource_attribute AS stackstatus
    ON stackstatus.resource_id = R.id
    AND stackstatus.type = 'provider'
    AND lower(stackstatus.attr_name) = 'stackstatus'
  LEFT JOIN resource_attribute AS stackstatusreason
    ON stackstatusreason.resource_id = R.id
    AND stackstatusreason.type = 'provider'
    AND lower(stackstatusreason.attr_name) = 'stackstatusreason'
  LEFT JOIN resource_attribute AS disablerollback
    ON disablerollback.resource_id = R.id
    AND disablerollback.type = 'provider'
    AND lower(disablerollback.attr_name) = 'disablerollback'
  LEFT JOIN resource_attribute AS notificationarns
    ON notificationarns.resource_id = R.id
    AND notificationarns.type = 'provider'
    AND lower(notificationarns.attr_name) = 'notificationarns'
  LEFT JOIN resource_attribute AS timeoutinminutes
    ON timeoutinminutes.resource_id = R.id
    AND timeoutinminutes.type = 'provider'
    AND lower(timeoutinminutes.attr_name) = 'timeoutinminutes'
  LEFT JOIN resource_attribute AS capabilities
    ON capabilities.resource_id = R.id
    AND capabilities.type = 'provider'
    AND lower(capabilities.attr_name) = 'capabilities'
  LEFT JOIN resource_attribute AS outputs
    ON outputs.resource_id = R.id
    AND outputs.type = 'provider'
    AND lower(outputs.attr_name) = 'outputs'
  LEFT JOIN resource_attribute AS rolearn
    ON rolearn.resource_id = R.id
    AND rolearn.type = 'provider'
    AND lower(rolearn.attr_name) = 'rolearn'
  LEFT JOIN resource_attribute AS tags
    ON tags.resource_id = R.id
    AND tags.type = 'provider'
    AND lower(tags.attr_name) = 'tags'
  LEFT JOIN resource_attribute AS enableterminationprotection
    ON enableterminationprotection.resource_id = R.id
    AND enableterminationprotection.type = 'provider'
    AND lower(enableterminationprotection.attr_name) = 'enableterminationprotection'
  LEFT JOIN resource_attribute AS parentid
    ON parentid.resource_id = R.id
    AND parentid.type = 'provider'
    AND lower(parentid.attr_name) = 'parentid'
  LEFT JOIN resource_attribute AS rootid
    ON rootid.resource_id = R.id
    AND rootid.type = 'provider'
    AND lower(rootid.attr_name) = 'rootid'
  LEFT JOIN resource_attribute AS driftinformation
    ON driftinformation.resource_id = R.id
    AND driftinformation.type = 'provider'
    AND lower(driftinformation.attr_name) = 'driftinformation'
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
  AND R.provider_type = 'Stack'
  AND R.service = 'cloudformation'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_cloudformation_stack;

COMMENT ON MATERIALIZED VIEW aws_cloudformation_stack IS 'cloudformation Stack resources and their associated attributes.';



DROP MATERIALIZED VIEW IF EXISTS aws_cloudformation_stack_sns_topic CASCADE;

CREATE MATERIALIZED VIEW aws_cloudformation_stack_sns_topic AS
SELECT
  aws_cloudformation_stack.id AS stack_id,
  aws_sns_topic.id AS topic_id
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
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_cloudformation_stack_sns_topic;

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
  attrs.provider ->> 'StackId' AS stackid,
  attrs.provider ->> 'StackName' AS stackname,
  attrs.provider ->> 'ChangeSetId' AS changesetid,
  attrs.provider ->> 'Description' AS description,
  attrs.provider -> 'Parameters' AS parameters,
  (TO_TIMESTAMP(attrs.provider ->> 'CreationTime', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS creationtime,
  (TO_TIMESTAMP(attrs.provider ->> 'DeletionTime', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS deletiontime,
  (TO_TIMESTAMP(attrs.provider ->> 'LastUpdatedTime', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS lastupdatedtime,
  attrs.provider -> 'RollbackConfiguration' AS rollbackconfiguration,
  attrs.provider ->> 'StackStatus' AS stackstatus,
  attrs.provider ->> 'StackStatusReason' AS stackstatusreason,
  (attrs.provider ->> 'DisableRollback')::boolean AS disablerollback,
  attrs.provider -> 'NotificationARNs' AS notificationarns,
  (attrs.provider ->> 'TimeoutInMinutes')::integer AS timeoutinminutes,
  attrs.provider -> 'Capabilities' AS capabilities,
  attrs.provider -> 'Outputs' AS outputs,
  attrs.provider ->> 'RoleARN' AS rolearn,
  attrs.provider -> 'Tags' AS tags,
  (attrs.provider ->> 'EnableTerminationProtection')::boolean AS enableterminationprotection,
  attrs.provider ->> 'ParentId' AS parentid,
  attrs.provider ->> 'RootId' AS rootid,
  attrs.provider -> 'DriftInformation' AS driftinformation,
  attrs.metadata -> 'Tags' AS tags,
  
    _iam_role_id.target_id AS _iam_role_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  LEFT JOIN attrs ON
    attrs.resource_id = R.id
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
          AND _aws_organizations_account_relation.provider_account_id = :provider_account_id
        GROUP BY _aws_organizations_account_relation.resource_id
        HAVING COUNT(*) = 1
      ) AS unique_account_mapping
  ) AS _account_id ON _account_id.resource_id = R.id
  WHERE
  R.provider_account_id = :provider_account_id
  AND R.provider_type = 'Stack'
  AND R.service = 'cloudformation'
ON CONFLICT (_id) DO UPDATE
SET
    StackId = EXCLUDED.StackId,
    StackName = EXCLUDED.StackName,
    ChangeSetId = EXCLUDED.ChangeSetId,
    Description = EXCLUDED.Description,
    Parameters = EXCLUDED.Parameters,
    CreationTime = EXCLUDED.CreationTime,
    DeletionTime = EXCLUDED.DeletionTime,
    LastUpdatedTime = EXCLUDED.LastUpdatedTime,
    RollbackConfiguration = EXCLUDED.RollbackConfiguration,
    StackStatus = EXCLUDED.StackStatus,
    StackStatusReason = EXCLUDED.StackStatusReason,
    DisableRollback = EXCLUDED.DisableRollback,
    NotificationARNs = EXCLUDED.NotificationARNs,
    TimeoutInMinutes = EXCLUDED.TimeoutInMinutes,
    Capabilities = EXCLUDED.Capabilities,
    Outputs = EXCLUDED.Outputs,
    RoleARN = EXCLUDED.RoleARN,
    Tags = EXCLUDED.Tags,
    EnableTerminationProtection = EXCLUDED.EnableTerminationProtection,
    ParentId = EXCLUDED.ParentId,
    RootId = EXCLUDED.RootId,
    DriftInformation = EXCLUDED.DriftInformation,
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
    AND aws_sns_topic.provider_account_id = :provider_account_id
  WHERE
    aws_cloudformation_stack.provider_account_id = :provider_account_id
    AND aws_cloudformation_stack.provider_type = 'Stack'
    AND aws_cloudformation_stack.service = 'cloudformation'
ON CONFLICT (stack_id, topic_id)
DO NOTHING
;

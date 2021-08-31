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
INSERT INTO aws_cloudwatch_compositealarm (
  _id,
  uri,
  provider_account_id,
  actionsenabled,
  alarmactions,
  alarmarn,
  alarmconfigurationupdatedtimestamp,
  alarmdescription,
  alarmname,
  alarmrule,
  insufficientdataactions,
  okactions,
  statereason,
  statereasondata,
  stateupdatedtimestamp,
  statevalue,
  tags,
  _tags,
  _account_id
)
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  (attrs.provider ->> 'ActionsEnabled')::boolean AS actionsenabled,
  attrs.provider -> 'AlarmActions' AS alarmactions,
  attrs.provider ->> 'AlarmArn' AS alarmarn,
  (TO_TIMESTAMP(attrs.provider ->> 'AlarmConfigurationUpdatedTimestamp', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS alarmconfigurationupdatedtimestamp,
  attrs.provider ->> 'AlarmDescription' AS alarmdescription,
  attrs.provider ->> 'AlarmName' AS alarmname,
  attrs.provider ->> 'AlarmRule' AS alarmrule,
  attrs.provider -> 'InsufficientDataActions' AS insufficientdataactions,
  attrs.provider -> 'OKActions' AS okactions,
  attrs.provider ->> 'StateReason' AS statereason,
  attrs.provider ->> 'StateReasonData' AS statereasondata,
  (TO_TIMESTAMP(attrs.provider ->> 'StateUpdatedTimestamp', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS stateupdatedtimestamp,
  attrs.provider ->> 'StateValue' AS statevalue,
  attrs.provider -> 'Tags' AS tags,
  attrs.metadata -> 'Tags' AS tags,
  
    _account_id.target_id AS _account_id
FROM
  resource AS R
  LEFT JOIN attrs ON
    attrs.resource_id = R.id
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
  AND R.provider_type = 'CompositeAlarm'
  AND R.service = 'cloudwatch'
ON CONFLICT (_id) DO UPDATE
SET
    ActionsEnabled = EXCLUDED.ActionsEnabled,
    AlarmActions = EXCLUDED.AlarmActions,
    AlarmArn = EXCLUDED.AlarmArn,
    AlarmConfigurationUpdatedTimestamp = EXCLUDED.AlarmConfigurationUpdatedTimestamp,
    AlarmDescription = EXCLUDED.AlarmDescription,
    AlarmName = EXCLUDED.AlarmName,
    AlarmRule = EXCLUDED.AlarmRule,
    InsufficientDataActions = EXCLUDED.InsufficientDataActions,
    OKActions = EXCLUDED.OKActions,
    StateReason = EXCLUDED.StateReason,
    StateReasonData = EXCLUDED.StateReasonData,
    StateUpdatedTimestamp = EXCLUDED.StateUpdatedTimestamp,
    StateValue = EXCLUDED.StateValue,
    Tags = EXCLUDED.Tags,
    _tags = EXCLUDED._tags,
    _account_id = EXCLUDED._account_id
  ;


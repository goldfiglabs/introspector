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
  (actionsenabled.attr_value #>> '{}')::boolean AS actionsenabled,
  alarmactions.attr_value::jsonb AS alarmactions,
  alarmarn.attr_value #>> '{}' AS alarmarn,
  (TO_TIMESTAMP(alarmconfigurationupdatedtimestamp.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS alarmconfigurationupdatedtimestamp,
  alarmdescription.attr_value #>> '{}' AS alarmdescription,
  alarmname.attr_value #>> '{}' AS alarmname,
  alarmrule.attr_value #>> '{}' AS alarmrule,
  insufficientdataactions.attr_value::jsonb AS insufficientdataactions,
  okactions.attr_value::jsonb AS okactions,
  statereason.attr_value #>> '{}' AS statereason,
  statereasondata.attr_value #>> '{}' AS statereasondata,
  (TO_TIMESTAMP(stateupdatedtimestamp.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS stateupdatedtimestamp,
  statevalue.attr_value #>> '{}' AS statevalue,
  tags.attr_value::jsonb AS tags,
  _tags.attr_value::jsonb AS _tags,

    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN resource_attribute AS actionsenabled
    ON actionsenabled.resource_id = R.id
    AND actionsenabled.type = 'provider'
    AND lower(actionsenabled.attr_name) = 'actionsenabled'
  LEFT JOIN resource_attribute AS alarmactions
    ON alarmactions.resource_id = R.id
    AND alarmactions.type = 'provider'
    AND lower(alarmactions.attr_name) = 'alarmactions'
  LEFT JOIN resource_attribute AS alarmarn
    ON alarmarn.resource_id = R.id
    AND alarmarn.type = 'provider'
    AND lower(alarmarn.attr_name) = 'alarmarn'
  LEFT JOIN resource_attribute AS alarmconfigurationupdatedtimestamp
    ON alarmconfigurationupdatedtimestamp.resource_id = R.id
    AND alarmconfigurationupdatedtimestamp.type = 'provider'
    AND lower(alarmconfigurationupdatedtimestamp.attr_name) = 'alarmconfigurationupdatedtimestamp'
  LEFT JOIN resource_attribute AS alarmdescription
    ON alarmdescription.resource_id = R.id
    AND alarmdescription.type = 'provider'
    AND lower(alarmdescription.attr_name) = 'alarmdescription'
  LEFT JOIN resource_attribute AS alarmname
    ON alarmname.resource_id = R.id
    AND alarmname.type = 'provider'
    AND lower(alarmname.attr_name) = 'alarmname'
  LEFT JOIN resource_attribute AS alarmrule
    ON alarmrule.resource_id = R.id
    AND alarmrule.type = 'provider'
    AND lower(alarmrule.attr_name) = 'alarmrule'
  LEFT JOIN resource_attribute AS insufficientdataactions
    ON insufficientdataactions.resource_id = R.id
    AND insufficientdataactions.type = 'provider'
    AND lower(insufficientdataactions.attr_name) = 'insufficientdataactions'
  LEFT JOIN resource_attribute AS okactions
    ON okactions.resource_id = R.id
    AND okactions.type = 'provider'
    AND lower(okactions.attr_name) = 'okactions'
  LEFT JOIN resource_attribute AS statereason
    ON statereason.resource_id = R.id
    AND statereason.type = 'provider'
    AND lower(statereason.attr_name) = 'statereason'
  LEFT JOIN resource_attribute AS statereasondata
    ON statereasondata.resource_id = R.id
    AND statereasondata.type = 'provider'
    AND lower(statereasondata.attr_name) = 'statereasondata'
  LEFT JOIN resource_attribute AS stateupdatedtimestamp
    ON stateupdatedtimestamp.resource_id = R.id
    AND stateupdatedtimestamp.type = 'provider'
    AND lower(stateupdatedtimestamp.attr_name) = 'stateupdatedtimestamp'
  LEFT JOIN resource_attribute AS statevalue
    ON statevalue.resource_id = R.id
    AND statevalue.type = 'provider'
    AND lower(statevalue.attr_name) = 'statevalue'
  LEFT JOIN resource_attribute AS tags
    ON tags.resource_id = R.id
    AND tags.type = 'provider'
    AND lower(tags.attr_name) = 'tags'
  LEFT JOIN resource_attribute AS _tags
    ON _tags.resource_id = R.id
    AND _tags.type = 'Metadata'
    AND lower(_tags.attr_name) = 'tags'
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
  AND R.provider_type = 'CompositeAlarm'
  AND R.service = 'cloudwatch'
ON CONFLICT (_id) DO UPDATE
SET
    actionsenabled = EXCLUDED.actionsenabled,
    alarmactions = EXCLUDED.alarmactions,
    alarmarn = EXCLUDED.alarmarn,
    alarmconfigurationupdatedtimestamp = EXCLUDED.alarmconfigurationupdatedtimestamp,
    alarmdescription = EXCLUDED.alarmdescription,
    alarmname = EXCLUDED.alarmname,
    alarmrule = EXCLUDED.alarmrule,
    insufficientdataactions = EXCLUDED.insufficientdataactions,
    okactions = EXCLUDED.okactions,
    statereason = EXCLUDED.statereason,
    statereasondata = EXCLUDED.statereasondata,
    stateupdatedtimestamp = EXCLUDED.stateupdatedtimestamp,
    statevalue = EXCLUDED.statevalue,
    tags = EXCLUDED.tags,
    _tags = EXCLUDED._tags,
    _account_id = EXCLUDED._account_id
  ;

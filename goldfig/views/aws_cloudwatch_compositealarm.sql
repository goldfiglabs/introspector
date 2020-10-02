DROP MATERIALIZED VIEW IF EXISTS aws_cloudwatch_compositealarm CASCADE;

CREATE MATERIALIZED VIEW aws_cloudwatch_compositealarm AS
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
  
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN attrs AS actionsenabled
    ON actionsenabled.id = R.id
    AND actionsenabled.attr_name = 'actionsenabled'
  LEFT JOIN attrs AS alarmactions
    ON alarmactions.id = R.id
    AND alarmactions.attr_name = 'alarmactions'
  LEFT JOIN attrs AS alarmarn
    ON alarmarn.id = R.id
    AND alarmarn.attr_name = 'alarmarn'
  LEFT JOIN attrs AS alarmconfigurationupdatedtimestamp
    ON alarmconfigurationupdatedtimestamp.id = R.id
    AND alarmconfigurationupdatedtimestamp.attr_name = 'alarmconfigurationupdatedtimestamp'
  LEFT JOIN attrs AS alarmdescription
    ON alarmdescription.id = R.id
    AND alarmdescription.attr_name = 'alarmdescription'
  LEFT JOIN attrs AS alarmname
    ON alarmname.id = R.id
    AND alarmname.attr_name = 'alarmname'
  LEFT JOIN attrs AS alarmrule
    ON alarmrule.id = R.id
    AND alarmrule.attr_name = 'alarmrule'
  LEFT JOIN attrs AS insufficientdataactions
    ON insufficientdataactions.id = R.id
    AND insufficientdataactions.attr_name = 'insufficientdataactions'
  LEFT JOIN attrs AS okactions
    ON okactions.id = R.id
    AND okactions.attr_name = 'okactions'
  LEFT JOIN attrs AS statereason
    ON statereason.id = R.id
    AND statereason.attr_name = 'statereason'
  LEFT JOIN attrs AS statereasondata
    ON statereasondata.id = R.id
    AND statereasondata.attr_name = 'statereasondata'
  LEFT JOIN attrs AS stateupdatedtimestamp
    ON stateupdatedtimestamp.id = R.id
    AND stateupdatedtimestamp.attr_name = 'stateupdatedtimestamp'
  LEFT JOIN attrs AS statevalue
    ON statevalue.id = R.id
    AND statevalue.attr_name = 'statevalue'
  LEFT JOIN attrs AS tags
    ON tags.id = R.id
    AND tags.attr_name = 'tags'
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
  AND LOWER(R.provider_type) = 'compositealarm'
  AND R.service = 'cloudwatch'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_cloudwatch_compositealarm;

COMMENT ON MATERIALIZED VIEW aws_cloudwatch_compositealarm IS 'cloudwatch compositealarm resources and their associated attributes.';


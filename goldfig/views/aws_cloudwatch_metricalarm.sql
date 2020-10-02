DROP MATERIALIZED VIEW IF EXISTS aws_cloudwatch_metricalarm CASCADE;

CREATE MATERIALIZED VIEW aws_cloudwatch_metricalarm AS
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
  alarmname.attr_value #>> '{}' AS alarmname,
  alarmarn.attr_value #>> '{}' AS alarmarn,
  alarmdescription.attr_value #>> '{}' AS alarmdescription,
  (TO_TIMESTAMP(alarmconfigurationupdatedtimestamp.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS alarmconfigurationupdatedtimestamp,
  (actionsenabled.attr_value #>> '{}')::boolean AS actionsenabled,
  okactions.attr_value::jsonb AS okactions,
  alarmactions.attr_value::jsonb AS alarmactions,
  insufficientdataactions.attr_value::jsonb AS insufficientdataactions,
  statevalue.attr_value #>> '{}' AS statevalue,
  statereason.attr_value #>> '{}' AS statereason,
  statereasondata.attr_value #>> '{}' AS statereasondata,
  (TO_TIMESTAMP(stateupdatedtimestamp.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS stateupdatedtimestamp,
  metricname.attr_value #>> '{}' AS metricname,
  namespace.attr_value #>> '{}' AS namespace,
  statistic.attr_value #>> '{}' AS statistic,
  extendedstatistic.attr_value #>> '{}' AS extendedstatistic,
  dimensions.attr_value::jsonb AS dimensions,
  (period.attr_value #>> '{}')::integer AS period,
  unit.attr_value #>> '{}' AS unit,
  (evaluationperiods.attr_value #>> '{}')::integer AS evaluationperiods,
  (datapointstoalarm.attr_value #>> '{}')::integer AS datapointstoalarm,
  (threshold.attr_value #>> '{}')::double precision AS threshold,
  comparisonoperator.attr_value #>> '{}' AS comparisonoperator,
  treatmissingdata.attr_value #>> '{}' AS treatmissingdata,
  evaluatelowsamplecountpercentile.attr_value #>> '{}' AS evaluatelowsamplecountpercentile,
  metrics.attr_value::jsonb AS metrics,
  thresholdmetricid.attr_value #>> '{}' AS thresholdmetricid,
  tags.attr_value::jsonb AS tags,
  
    _metric_id.target_id AS _metric_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN attrs AS alarmname
    ON alarmname.id = R.id
    AND alarmname.attr_name = 'alarmname'
  LEFT JOIN attrs AS alarmarn
    ON alarmarn.id = R.id
    AND alarmarn.attr_name = 'alarmarn'
  LEFT JOIN attrs AS alarmdescription
    ON alarmdescription.id = R.id
    AND alarmdescription.attr_name = 'alarmdescription'
  LEFT JOIN attrs AS alarmconfigurationupdatedtimestamp
    ON alarmconfigurationupdatedtimestamp.id = R.id
    AND alarmconfigurationupdatedtimestamp.attr_name = 'alarmconfigurationupdatedtimestamp'
  LEFT JOIN attrs AS actionsenabled
    ON actionsenabled.id = R.id
    AND actionsenabled.attr_name = 'actionsenabled'
  LEFT JOIN attrs AS okactions
    ON okactions.id = R.id
    AND okactions.attr_name = 'okactions'
  LEFT JOIN attrs AS alarmactions
    ON alarmactions.id = R.id
    AND alarmactions.attr_name = 'alarmactions'
  LEFT JOIN attrs AS insufficientdataactions
    ON insufficientdataactions.id = R.id
    AND insufficientdataactions.attr_name = 'insufficientdataactions'
  LEFT JOIN attrs AS statevalue
    ON statevalue.id = R.id
    AND statevalue.attr_name = 'statevalue'
  LEFT JOIN attrs AS statereason
    ON statereason.id = R.id
    AND statereason.attr_name = 'statereason'
  LEFT JOIN attrs AS statereasondata
    ON statereasondata.id = R.id
    AND statereasondata.attr_name = 'statereasondata'
  LEFT JOIN attrs AS stateupdatedtimestamp
    ON stateupdatedtimestamp.id = R.id
    AND stateupdatedtimestamp.attr_name = 'stateupdatedtimestamp'
  LEFT JOIN attrs AS metricname
    ON metricname.id = R.id
    AND metricname.attr_name = 'metricname'
  LEFT JOIN attrs AS namespace
    ON namespace.id = R.id
    AND namespace.attr_name = 'namespace'
  LEFT JOIN attrs AS statistic
    ON statistic.id = R.id
    AND statistic.attr_name = 'statistic'
  LEFT JOIN attrs AS extendedstatistic
    ON extendedstatistic.id = R.id
    AND extendedstatistic.attr_name = 'extendedstatistic'
  LEFT JOIN attrs AS dimensions
    ON dimensions.id = R.id
    AND dimensions.attr_name = 'dimensions'
  LEFT JOIN attrs AS period
    ON period.id = R.id
    AND period.attr_name = 'period'
  LEFT JOIN attrs AS unit
    ON unit.id = R.id
    AND unit.attr_name = 'unit'
  LEFT JOIN attrs AS evaluationperiods
    ON evaluationperiods.id = R.id
    AND evaluationperiods.attr_name = 'evaluationperiods'
  LEFT JOIN attrs AS datapointstoalarm
    ON datapointstoalarm.id = R.id
    AND datapointstoalarm.attr_name = 'datapointstoalarm'
  LEFT JOIN attrs AS threshold
    ON threshold.id = R.id
    AND threshold.attr_name = 'threshold'
  LEFT JOIN attrs AS comparisonoperator
    ON comparisonoperator.id = R.id
    AND comparisonoperator.attr_name = 'comparisonoperator'
  LEFT JOIN attrs AS treatmissingdata
    ON treatmissingdata.id = R.id
    AND treatmissingdata.attr_name = 'treatmissingdata'
  LEFT JOIN attrs AS evaluatelowsamplecountpercentile
    ON evaluatelowsamplecountpercentile.id = R.id
    AND evaluatelowsamplecountpercentile.attr_name = 'evaluatelowsamplecountpercentile'
  LEFT JOIN attrs AS metrics
    ON metrics.id = R.id
    AND metrics.attr_name = 'metrics'
  LEFT JOIN attrs AS thresholdmetricid
    ON thresholdmetricid.id = R.id
    AND thresholdmetricid.attr_name = 'thresholdmetricid'
  LEFT JOIN attrs AS tags
    ON tags.id = R.id
    AND tags.attr_name = 'tags'
  LEFT JOIN (
    SELECT
      _aws_cloudwatch_metric_relation.resource_id AS resource_id,
      _aws_cloudwatch_metric.id AS target_id
    FROM
      resource_relation AS _aws_cloudwatch_metric_relation
      INNER JOIN resource AS _aws_cloudwatch_metric
        ON _aws_cloudwatch_metric_relation.target_id = _aws_cloudwatch_metric.id
        AND _aws_cloudwatch_metric.provider_type = 'Metric'
        AND _aws_cloudwatch_metric.service = 'cloudwatch'
    WHERE
      _aws_cloudwatch_metric_relation.relation = 'fires-on'
  ) AS _metric_id ON _metric_id.resource_id = R.id
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
  AND LOWER(R.provider_type) = 'metricalarm'
  AND R.service = 'cloudwatch'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_cloudwatch_metricalarm;

COMMENT ON MATERIALIZED VIEW aws_cloudwatch_metricalarm IS 'cloudwatch metricalarm resources and their associated attributes.';



DROP MATERIALIZED VIEW IF EXISTS aws_cloudwatch_metricalarm_sns_topic CASCADE;

CREATE MATERIALIZED VIEW aws_cloudwatch_metricalarm_sns_topic AS
SELECT
  aws_cloudwatch_metricalarm.id AS metricalarm_id,
  aws_sns_topic.id AS topic_id
FROM
  resource AS aws_cloudwatch_metricalarm
  INNER JOIN resource_relation AS RR
    ON RR.resource_id = aws_cloudwatch_metricalarm.id
    AND RR.relation = 'triggers'
  INNER JOIN resource AS aws_sns_topic
    ON aws_sns_topic.id = RR.target_id
    AND aws_sns_topic.provider_type = 'Topic'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_cloudwatch_metricalarm_sns_topic;

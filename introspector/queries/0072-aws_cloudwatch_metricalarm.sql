INSERT INTO aws_cloudwatch_metricalarm (
  _id,
  uri,
  provider_account_id,
  alarmname,
  alarmarn,
  alarmdescription,
  alarmconfigurationupdatedtimestamp,
  actionsenabled,
  okactions,
  alarmactions,
  insufficientdataactions,
  statevalue,
  statereason,
  statereasondata,
  stateupdatedtimestamp,
  metricname,
  namespace,
  statistic,
  extendedstatistic,
  dimensions,
  period,
  unit,
  evaluationperiods,
  datapointstoalarm,
  threshold,
  comparisonoperator,
  treatmissingdata,
  evaluatelowsamplecountpercentile,
  metrics,
  thresholdmetricid,
  tags,
  _tags,
  _metric_id,_account_id
)
SELECT
  R.id AS _id,
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
  _tags.attr_value::jsonb AS _tags,
  
    _metric_id.target_id AS _metric_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN resource_attribute AS alarmname
    ON alarmname.resource_id = R.id
    AND alarmname.type = 'provider'
    AND lower(alarmname.attr_name) = 'alarmname'
    AND alarmname.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS alarmarn
    ON alarmarn.resource_id = R.id
    AND alarmarn.type = 'provider'
    AND lower(alarmarn.attr_name) = 'alarmarn'
    AND alarmarn.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS alarmdescription
    ON alarmdescription.resource_id = R.id
    AND alarmdescription.type = 'provider'
    AND lower(alarmdescription.attr_name) = 'alarmdescription'
    AND alarmdescription.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS alarmconfigurationupdatedtimestamp
    ON alarmconfigurationupdatedtimestamp.resource_id = R.id
    AND alarmconfigurationupdatedtimestamp.type = 'provider'
    AND lower(alarmconfigurationupdatedtimestamp.attr_name) = 'alarmconfigurationupdatedtimestamp'
    AND alarmconfigurationupdatedtimestamp.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS actionsenabled
    ON actionsenabled.resource_id = R.id
    AND actionsenabled.type = 'provider'
    AND lower(actionsenabled.attr_name) = 'actionsenabled'
    AND actionsenabled.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS okactions
    ON okactions.resource_id = R.id
    AND okactions.type = 'provider'
    AND lower(okactions.attr_name) = 'okactions'
    AND okactions.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS alarmactions
    ON alarmactions.resource_id = R.id
    AND alarmactions.type = 'provider'
    AND lower(alarmactions.attr_name) = 'alarmactions'
    AND alarmactions.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS insufficientdataactions
    ON insufficientdataactions.resource_id = R.id
    AND insufficientdataactions.type = 'provider'
    AND lower(insufficientdataactions.attr_name) = 'insufficientdataactions'
    AND insufficientdataactions.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS statevalue
    ON statevalue.resource_id = R.id
    AND statevalue.type = 'provider'
    AND lower(statevalue.attr_name) = 'statevalue'
    AND statevalue.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS statereason
    ON statereason.resource_id = R.id
    AND statereason.type = 'provider'
    AND lower(statereason.attr_name) = 'statereason'
    AND statereason.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS statereasondata
    ON statereasondata.resource_id = R.id
    AND statereasondata.type = 'provider'
    AND lower(statereasondata.attr_name) = 'statereasondata'
    AND statereasondata.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS stateupdatedtimestamp
    ON stateupdatedtimestamp.resource_id = R.id
    AND stateupdatedtimestamp.type = 'provider'
    AND lower(stateupdatedtimestamp.attr_name) = 'stateupdatedtimestamp'
    AND stateupdatedtimestamp.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS metricname
    ON metricname.resource_id = R.id
    AND metricname.type = 'provider'
    AND lower(metricname.attr_name) = 'metricname'
    AND metricname.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS namespace
    ON namespace.resource_id = R.id
    AND namespace.type = 'provider'
    AND lower(namespace.attr_name) = 'namespace'
    AND namespace.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS statistic
    ON statistic.resource_id = R.id
    AND statistic.type = 'provider'
    AND lower(statistic.attr_name) = 'statistic'
    AND statistic.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS extendedstatistic
    ON extendedstatistic.resource_id = R.id
    AND extendedstatistic.type = 'provider'
    AND lower(extendedstatistic.attr_name) = 'extendedstatistic'
    AND extendedstatistic.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS dimensions
    ON dimensions.resource_id = R.id
    AND dimensions.type = 'provider'
    AND lower(dimensions.attr_name) = 'dimensions'
    AND dimensions.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS period
    ON period.resource_id = R.id
    AND period.type = 'provider'
    AND lower(period.attr_name) = 'period'
    AND period.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS unit
    ON unit.resource_id = R.id
    AND unit.type = 'provider'
    AND lower(unit.attr_name) = 'unit'
    AND unit.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS evaluationperiods
    ON evaluationperiods.resource_id = R.id
    AND evaluationperiods.type = 'provider'
    AND lower(evaluationperiods.attr_name) = 'evaluationperiods'
    AND evaluationperiods.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS datapointstoalarm
    ON datapointstoalarm.resource_id = R.id
    AND datapointstoalarm.type = 'provider'
    AND lower(datapointstoalarm.attr_name) = 'datapointstoalarm'
    AND datapointstoalarm.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS threshold
    ON threshold.resource_id = R.id
    AND threshold.type = 'provider'
    AND lower(threshold.attr_name) = 'threshold'
    AND threshold.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS comparisonoperator
    ON comparisonoperator.resource_id = R.id
    AND comparisonoperator.type = 'provider'
    AND lower(comparisonoperator.attr_name) = 'comparisonoperator'
    AND comparisonoperator.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS treatmissingdata
    ON treatmissingdata.resource_id = R.id
    AND treatmissingdata.type = 'provider'
    AND lower(treatmissingdata.attr_name) = 'treatmissingdata'
    AND treatmissingdata.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS evaluatelowsamplecountpercentile
    ON evaluatelowsamplecountpercentile.resource_id = R.id
    AND evaluatelowsamplecountpercentile.type = 'provider'
    AND lower(evaluatelowsamplecountpercentile.attr_name) = 'evaluatelowsamplecountpercentile'
    AND evaluatelowsamplecountpercentile.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS metrics
    ON metrics.resource_id = R.id
    AND metrics.type = 'provider'
    AND lower(metrics.attr_name) = 'metrics'
    AND metrics.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS thresholdmetricid
    ON thresholdmetricid.resource_id = R.id
    AND thresholdmetricid.type = 'provider'
    AND lower(thresholdmetricid.attr_name) = 'thresholdmetricid'
    AND thresholdmetricid.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS tags
    ON tags.resource_id = R.id
    AND tags.type = 'provider'
    AND lower(tags.attr_name) = 'tags'
    AND tags.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS _tags
    ON _tags.resource_id = R.id
    AND _tags.type = 'Metadata'
    AND lower(_tags.attr_name) = 'tags'
    AND _tags.provider_account_id = R.provider_account_id
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
        AND _aws_cloudwatch_metric.provider_account_id = :provider_account_id
    WHERE
      _aws_cloudwatch_metric_relation.relation = 'fires-on'
      AND _aws_cloudwatch_metric_relation.provider_account_id = :provider_account_id
  ) AS _metric_id ON _metric_id.resource_id = R.id
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
  AND R.provider_type = 'MetricAlarm'
  AND R.service = 'cloudwatch'
ON CONFLICT (_id) DO UPDATE
SET
    alarmname = EXCLUDED.alarmname,
    alarmarn = EXCLUDED.alarmarn,
    alarmdescription = EXCLUDED.alarmdescription,
    alarmconfigurationupdatedtimestamp = EXCLUDED.alarmconfigurationupdatedtimestamp,
    actionsenabled = EXCLUDED.actionsenabled,
    okactions = EXCLUDED.okactions,
    alarmactions = EXCLUDED.alarmactions,
    insufficientdataactions = EXCLUDED.insufficientdataactions,
    statevalue = EXCLUDED.statevalue,
    statereason = EXCLUDED.statereason,
    statereasondata = EXCLUDED.statereasondata,
    stateupdatedtimestamp = EXCLUDED.stateupdatedtimestamp,
    metricname = EXCLUDED.metricname,
    namespace = EXCLUDED.namespace,
    statistic = EXCLUDED.statistic,
    extendedstatistic = EXCLUDED.extendedstatistic,
    dimensions = EXCLUDED.dimensions,
    period = EXCLUDED.period,
    unit = EXCLUDED.unit,
    evaluationperiods = EXCLUDED.evaluationperiods,
    datapointstoalarm = EXCLUDED.datapointstoalarm,
    threshold = EXCLUDED.threshold,
    comparisonoperator = EXCLUDED.comparisonoperator,
    treatmissingdata = EXCLUDED.treatmissingdata,
    evaluatelowsamplecountpercentile = EXCLUDED.evaluatelowsamplecountpercentile,
    metrics = EXCLUDED.metrics,
    thresholdmetricid = EXCLUDED.thresholdmetricid,
    tags = EXCLUDED.tags,
    _tags = EXCLUDED._tags,
    _metric_id = EXCLUDED._metric_id,
    _account_id = EXCLUDED._account_id
  ;



INSERT INTO aws_cloudwatch_metricalarm_sns_topic
SELECT
  aws_cloudwatch_metricalarm.id AS metricalarm_id,
  aws_sns_topic.id AS topic_id,
  aws_cloudwatch_metricalarm.provider_account_id AS provider_account_id
FROM
  resource AS aws_cloudwatch_metricalarm
  INNER JOIN resource_relation AS RR
    ON RR.resource_id = aws_cloudwatch_metricalarm.id
    AND RR.relation = 'triggers'
  INNER JOIN resource AS aws_sns_topic
    ON aws_sns_topic.id = RR.target_id
    AND aws_sns_topic.provider_type = 'Topic'
    AND aws_sns_topic.service = 'sns'
  WHERE
    aws_cloudwatch_metricalarm.provider_type = 'MetricAlarm'
    AND aws_cloudwatch_metricalarm.service = 'cloudwatch'
ON CONFLICT (metricalarm_id, topic_id)
DO NOTHING
;

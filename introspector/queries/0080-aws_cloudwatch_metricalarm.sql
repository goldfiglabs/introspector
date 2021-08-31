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
  attrs.provider ->> 'AlarmName' AS alarmname,
  attrs.provider ->> 'AlarmArn' AS alarmarn,
  attrs.provider ->> 'AlarmDescription' AS alarmdescription,
  (TO_TIMESTAMP(attrs.provider ->> 'AlarmConfigurationUpdatedTimestamp', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS alarmconfigurationupdatedtimestamp,
  (attrs.provider ->> 'ActionsEnabled')::boolean AS actionsenabled,
  attrs.provider -> 'OKActions' AS okactions,
  attrs.provider -> 'AlarmActions' AS alarmactions,
  attrs.provider -> 'InsufficientDataActions' AS insufficientdataactions,
  attrs.provider ->> 'StateValue' AS statevalue,
  attrs.provider ->> 'StateReason' AS statereason,
  attrs.provider ->> 'StateReasonData' AS statereasondata,
  (TO_TIMESTAMP(attrs.provider ->> 'StateUpdatedTimestamp', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS stateupdatedtimestamp,
  attrs.provider ->> 'MetricName' AS metricname,
  attrs.provider ->> 'Namespace' AS namespace,
  attrs.provider ->> 'Statistic' AS statistic,
  attrs.provider ->> 'ExtendedStatistic' AS extendedstatistic,
  attrs.provider -> 'Dimensions' AS dimensions,
  (attrs.provider ->> 'Period')::integer AS period,
  attrs.provider ->> 'Unit' AS unit,
  (attrs.provider ->> 'EvaluationPeriods')::integer AS evaluationperiods,
  (attrs.provider ->> 'DatapointsToAlarm')::integer AS datapointstoalarm,
  (attrs.provider ->> 'Threshold')::double precision AS threshold,
  attrs.provider ->> 'ComparisonOperator' AS comparisonoperator,
  attrs.provider ->> 'TreatMissingData' AS treatmissingdata,
  attrs.provider ->> 'EvaluateLowSampleCountPercentile' AS evaluatelowsamplecountpercentile,
  attrs.provider -> 'Metrics' AS metrics,
  attrs.provider ->> 'ThresholdMetricId' AS thresholdmetricid,
  attrs.provider -> 'Tags' AS tags,
  attrs.metadata -> 'Tags' AS tags,
  
    _metric_id.target_id AS _metric_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  LEFT JOIN attrs ON
    attrs.resource_id = R.id
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
  AND R.provider_type = 'MetricAlarm'
  AND R.service = 'cloudwatch'
ON CONFLICT (_id) DO UPDATE
SET
    AlarmName = EXCLUDED.AlarmName,
    AlarmArn = EXCLUDED.AlarmArn,
    AlarmDescription = EXCLUDED.AlarmDescription,
    AlarmConfigurationUpdatedTimestamp = EXCLUDED.AlarmConfigurationUpdatedTimestamp,
    ActionsEnabled = EXCLUDED.ActionsEnabled,
    OKActions = EXCLUDED.OKActions,
    AlarmActions = EXCLUDED.AlarmActions,
    InsufficientDataActions = EXCLUDED.InsufficientDataActions,
    StateValue = EXCLUDED.StateValue,
    StateReason = EXCLUDED.StateReason,
    StateReasonData = EXCLUDED.StateReasonData,
    StateUpdatedTimestamp = EXCLUDED.StateUpdatedTimestamp,
    MetricName = EXCLUDED.MetricName,
    Namespace = EXCLUDED.Namespace,
    Statistic = EXCLUDED.Statistic,
    ExtendedStatistic = EXCLUDED.ExtendedStatistic,
    Dimensions = EXCLUDED.Dimensions,
    Period = EXCLUDED.Period,
    Unit = EXCLUDED.Unit,
    EvaluationPeriods = EXCLUDED.EvaluationPeriods,
    DatapointsToAlarm = EXCLUDED.DatapointsToAlarm,
    Threshold = EXCLUDED.Threshold,
    ComparisonOperator = EXCLUDED.ComparisonOperator,
    TreatMissingData = EXCLUDED.TreatMissingData,
    EvaluateLowSampleCountPercentile = EXCLUDED.EvaluateLowSampleCountPercentile,
    Metrics = EXCLUDED.Metrics,
    ThresholdMetricId = EXCLUDED.ThresholdMetricId,
    Tags = EXCLUDED.Tags,
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
    AND aws_sns_topic.provider_account_id = :provider_account_id
  WHERE
    aws_cloudwatch_metricalarm.provider_account_id = :provider_account_id
    AND aws_cloudwatch_metricalarm.provider_type = 'MetricAlarm'
    AND aws_cloudwatch_metricalarm.service = 'cloudwatch'
ON CONFLICT (metricalarm_id, topic_id)
DO NOTHING
;

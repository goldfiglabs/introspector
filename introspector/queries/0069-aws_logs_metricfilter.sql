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
INSERT INTO aws_logs_metricfilter (
  _id,
  uri,
  provider_account_id,
  filtername,
  filterpattern,
  metrictransformations,
  creationtime,
  loggroupname,
  _loggroup_id,_account_id
)
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  attrs.provider ->> 'filterName' AS filtername,
  attrs.provider ->> 'filterPattern' AS filterpattern,
  attrs.provider -> 'metricTransformations' AS metrictransformations,
  (attrs.provider ->> 'creationTime')::bigint AS creationtime,
  attrs.provider ->> 'logGroupName' AS loggroupname,
  
    _loggroup_id.target_id AS _loggroup_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  LEFT JOIN attrs ON
    attrs.resource_id = R.id
  LEFT JOIN (
    SELECT
      _aws_logs_loggroup_relation.resource_id AS resource_id,
      _aws_logs_loggroup.id AS target_id
    FROM
      resource_relation AS _aws_logs_loggroup_relation
      INNER JOIN resource AS _aws_logs_loggroup
        ON _aws_logs_loggroup_relation.target_id = _aws_logs_loggroup.id
        AND _aws_logs_loggroup.provider_type = 'LogGroup'
        AND _aws_logs_loggroup.service = 'logs'
        AND _aws_logs_loggroup.provider_account_id = :provider_account_id
    WHERE
      _aws_logs_loggroup_relation.relation = 'filters-group'
      AND _aws_logs_loggroup_relation.provider_account_id = :provider_account_id
  ) AS _loggroup_id ON _loggroup_id.resource_id = R.id
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
          AND _aws_organizations_account_relation.provider_account_id = 8
        GROUP BY _aws_organizations_account_relation.resource_id
        HAVING COUNT(*) = 1
      ) AS unique_account_mapping
  ) AS _account_id ON _account_id.resource_id = R.id
  WHERE
  R.provider_account_id = :provider_account_id
  AND R.provider_type = 'MetricFilter'
  AND R.service = 'logs'
ON CONFLICT (_id) DO UPDATE
SET
    filterName = EXCLUDED.filterName,
    filterPattern = EXCLUDED.filterPattern,
    metricTransformations = EXCLUDED.metricTransformations,
    creationTime = EXCLUDED.creationTime,
    logGroupName = EXCLUDED.logGroupName,
    _loggroup_id = EXCLUDED._loggroup_id,
    _account_id = EXCLUDED._account_id
  ;



INSERT INTO aws_logs_metricfilter_cloudwatch_metric
SELECT
  aws_logs_metricfilter.id AS metricfilter_id,
  aws_cloudwatch_metric.id AS metric_id,
  aws_logs_metricfilter.provider_account_id AS provider_account_id,
  MetricValue.value #>> '{}' AS metricvalue,
  (DefaultValue.value #>> '{}')::double precision AS defaultvalue
FROM
  resource AS aws_logs_metricfilter
  INNER JOIN resource_relation AS RR
    ON RR.resource_id = aws_logs_metricfilter.id
    AND RR.relation = 'forwards-to'
  INNER JOIN resource AS aws_cloudwatch_metric
    ON aws_cloudwatch_metric.id = RR.target_id
    AND aws_cloudwatch_metric.provider_type = 'Metric'
    AND aws_cloudwatch_metric.service = 'cloudwatch'
    AND aws_cloudwatch_metric.provider_account_id = :provider_account_id
  LEFT JOIN resource_relation_attribute AS MetricValue
    ON MetricValue.relation_id = RR.id
    AND MetricValue.name = 'MetricValue'
  LEFT JOIN resource_relation_attribute AS DefaultValue
    ON DefaultValue.relation_id = RR.id
    AND DefaultValue.name = 'DefaultValue'
  WHERE
    aws_logs_metricfilter.provider_account_id = :provider_account_id
    AND aws_logs_metricfilter.provider_type = 'MetricFilter'
    AND aws_logs_metricfilter.service = 'logs'
ON CONFLICT (metricfilter_id, metric_id)

DO UPDATE
SET
  
  MetricValue = EXCLUDED.MetricValue,
  DefaultValue = EXCLUDED.DefaultValue;

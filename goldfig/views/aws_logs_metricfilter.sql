DROP MATERIALIZED VIEW IF EXISTS aws_logs_metricfilter CASCADE;

CREATE MATERIALIZED VIEW aws_logs_metricfilter AS
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
  filtername.attr_value #>> '{}' AS filtername,
  filterpattern.attr_value #>> '{}' AS filterpattern,
  metrictransformations.attr_value::jsonb AS metrictransformations,
  (creationtime.attr_value #>> '{}')::bigint AS creationtime,
  loggroupname.attr_value #>> '{}' AS loggroupname,
  
    _loggroup_id.target_id AS _loggroup_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN attrs AS filtername
    ON filtername.id = R.id
    AND filtername.attr_name = 'filtername'
  LEFT JOIN attrs AS filterpattern
    ON filterpattern.id = R.id
    AND filterpattern.attr_name = 'filterpattern'
  LEFT JOIN attrs AS metrictransformations
    ON metrictransformations.id = R.id
    AND metrictransformations.attr_name = 'metrictransformations'
  LEFT JOIN attrs AS creationtime
    ON creationtime.id = R.id
    AND creationtime.attr_name = 'creationtime'
  LEFT JOIN attrs AS loggroupname
    ON loggroupname.id = R.id
    AND loggroupname.attr_name = 'loggroupname'
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
    WHERE
      _aws_logs_loggroup_relation.relation = 'filters-group'
  ) AS _loggroup_id ON _loggroup_id.resource_id = R.id
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
  AND LOWER(R.provider_type) = 'metricfilter'
  AND R.service = 'logs'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_logs_metricfilter;

COMMENT ON MATERIALIZED VIEW aws_logs_metricfilter IS 'logs metricfilter resources and their associated attributes.';



DROP MATERIALIZED VIEW IF EXISTS aws_logs_metricfilter_cloudwatch_metric CASCADE;

CREATE MATERIALIZED VIEW aws_logs_metricfilter_cloudwatch_metric AS
SELECT
  aws_logs_metricfilter.id AS metricfilter_id,
  aws_cloudwatch_metric.id AS metric_id,
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
  LEFT JOIN resource_relation_attribute AS MetricValue
    ON MetricValue.relation_id = RR.id
    AND MetricValue.name = 'MetricValue'
  LEFT JOIN resource_relation_attribute AS DefaultValue
    ON DefaultValue.relation_id = RR.id
    AND DefaultValue.name = 'DefaultValue'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_logs_metricfilter_cloudwatch_metric;

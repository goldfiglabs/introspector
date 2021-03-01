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
  LEFT JOIN resource_attribute AS filtername
    ON filtername.resource_id = R.id
    AND filtername.type = 'provider'
    AND lower(filtername.attr_name) = 'filtername'
  LEFT JOIN resource_attribute AS filterpattern
    ON filterpattern.resource_id = R.id
    AND filterpattern.type = 'provider'
    AND lower(filterpattern.attr_name) = 'filterpattern'
  LEFT JOIN resource_attribute AS metrictransformations
    ON metrictransformations.resource_id = R.id
    AND metrictransformations.type = 'provider'
    AND lower(metrictransformations.attr_name) = 'metrictransformations'
  LEFT JOIN resource_attribute AS creationtime
    ON creationtime.resource_id = R.id
    AND creationtime.type = 'provider'
    AND lower(creationtime.attr_name) = 'creationtime'
  LEFT JOIN resource_attribute AS loggroupname
    ON loggroupname.resource_id = R.id
    AND loggroupname.type = 'provider'
    AND lower(loggroupname.attr_name) = 'loggroupname'
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
      GROUP BY _aws_organizations_account_relation.resource_id
      HAVING COUNT(*) = 1
    ) AS unique_account_mapping
    INNER JOIN resource_relation AS _aws_organizations_account_relation
      ON _aws_organizations_account_relation.resource_id = unique_account_mapping.resource_id
    INNER JOIN resource AS _aws_organizations_account
      ON _aws_organizations_account_relation.target_id = _aws_organizations_account.id
      AND _aws_organizations_account.provider_type = 'Account'
      AND _aws_organizations_account.service = 'organizations'
    WHERE
        _aws_organizations_account_relation.relation = 'in'
  ) AS _account_id ON _account_id.resource_id = R.id
  WHERE
  PA.provider = 'aws'
  AND R.provider_type = 'MetricFilter'
  AND R.service = 'logs'
ON CONFLICT (_id) DO UPDATE
SET
    filtername = EXCLUDED.filtername,
    filterpattern = EXCLUDED.filterpattern,
    metrictransformations = EXCLUDED.metrictransformations,
    creationtime = EXCLUDED.creationtime,
    loggroupname = EXCLUDED.loggroupname,
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
  LEFT JOIN resource_relation_attribute AS MetricValue
    ON MetricValue.relation_id = RR.id
    AND MetricValue.name = 'MetricValue'
  LEFT JOIN resource_relation_attribute AS DefaultValue
    ON DefaultValue.relation_id = RR.id
    AND DefaultValue.name = 'DefaultValue'
  WHERE
    aws_logs_metricfilter.provider_type = 'MetricFilter'
    AND aws_logs_metricfilter.service = 'logs'
ON CONFLICT (metricfilter_id, metric_id)

DO UPDATE
SET
  
  MetricValue = EXCLUDED.MetricValue,
  DefaultValue = EXCLUDED.DefaultValue;

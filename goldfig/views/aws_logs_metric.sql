DROP MATERIALIZED VIEW IF EXISTS aws_logs_metric CASCADE;

CREATE MATERIALIZED VIEW aws_logs_metric AS
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
  metricName.attr_value #>> '{}' AS metricname,
  metricNamespace.attr_value #>> '{}' AS metricnamespace,
  
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN attrs AS metricName
    ON metricName.id = R.id
    AND metricName.attr_name = 'metricname'
  LEFT JOIN attrs AS metricNamespace
    ON metricNamespace.id = R.id
    AND metricNamespace.attr_name = 'metricnamespace'
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
  AND LOWER(R.provider_type) = 'metric'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_logs_metric;

COMMENT ON MATERIALIZED VIEW aws_logs_metric IS 'logs metric resources and their associated attributes.';


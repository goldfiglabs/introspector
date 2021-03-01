INSERT INTO aws_cloudwatch_metric (
  _id,
  uri,
  provider_account_id,
  namespace,
  metricname,
  dimensions,
  _account_id
)
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  namespace.attr_value #>> '{}' AS namespace,
  metricname.attr_value #>> '{}' AS metricname,
  dimensions.attr_value::jsonb AS dimensions,
  
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN resource_attribute AS namespace
    ON namespace.resource_id = R.id
    AND namespace.type = 'provider'
    AND lower(namespace.attr_name) = 'namespace'
  LEFT JOIN resource_attribute AS metricname
    ON metricname.resource_id = R.id
    AND metricname.type = 'provider'
    AND lower(metricname.attr_name) = 'metricname'
  LEFT JOIN resource_attribute AS dimensions
    ON dimensions.resource_id = R.id
    AND dimensions.type = 'provider'
    AND lower(dimensions.attr_name) = 'dimensions'
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
  AND R.provider_type = 'Metric'
  AND R.service = 'cloudwatch'
ON CONFLICT (_id) DO UPDATE
SET
    namespace = EXCLUDED.namespace,
    metricname = EXCLUDED.metricname,
    dimensions = EXCLUDED.dimensions,
    _account_id = EXCLUDED._account_id
  ;


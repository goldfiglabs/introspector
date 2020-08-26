DROP MATERIALIZED VIEW IF EXISTS aws_lambda_alias CASCADE;

CREATE MATERIALIZED VIEW aws_lambda_alias AS
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
  aliasarn.attr_value #>> '{}' AS aliasarn,
  name.attr_value #>> '{}' AS name,
  functionversion.attr_value #>> '{}' AS functionversion,
  description.attr_value #>> '{}' AS description,
  routingconfig.attr_value::jsonb AS routingconfig,
  revisionid.attr_value #>> '{}' AS revisionid,
  Policy.attr_value::jsonb AS policy,
  
    _function_id.target_id AS _function_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN attrs AS aliasarn
    ON aliasarn.id = R.id
    AND aliasarn.attr_name = 'aliasarn'
  LEFT JOIN attrs AS name
    ON name.id = R.id
    AND name.attr_name = 'name'
  LEFT JOIN attrs AS functionversion
    ON functionversion.id = R.id
    AND functionversion.attr_name = 'functionversion'
  LEFT JOIN attrs AS description
    ON description.id = R.id
    AND description.attr_name = 'description'
  LEFT JOIN attrs AS routingconfig
    ON routingconfig.id = R.id
    AND routingconfig.attr_name = 'routingconfig'
  LEFT JOIN attrs AS revisionid
    ON revisionid.id = R.id
    AND revisionid.attr_name = 'revisionid'
  LEFT JOIN attrs AS Policy
    ON Policy.id = R.id
    AND Policy.attr_name = 'policy'
  LEFT JOIN (
    SELECT
      _aws_lambda_function_relation.resource_id AS resource_id,
      _aws_lambda_function.id AS target_id
    FROM
      resource_relation AS _aws_lambda_function_relation
      INNER JOIN resource AS _aws_lambda_function
        ON _aws_lambda_function_relation.target_id = _aws_lambda_function.id
        AND _aws_lambda_function.provider_type = 'Function'
        AND _aws_lambda_function.service = 'lambda'
    WHERE
      _aws_lambda_function_relation.relation = 'aliases'
  ) AS _function_id ON _function_id.resource_id = R.id
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
  AND LOWER(R.provider_type) = 'alias'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_lambda_alias;

COMMENT ON MATERIALIZED VIEW aws_lambda_alias IS 'lambda alias resources and their associated attributes.';



DROP MATERIALIZED VIEW IF EXISTS aws_lambda_alias_functionversion CASCADE;

CREATE MATERIALIZED VIEW aws_lambda_alias_functionversion AS
SELECT
  aws_lambda_alias.id AS alias_id,
  aws_lambda_functionversion.id AS functionversion_id,
  (weight.value #>> '{}')::double precision AS weight
FROM
  resource AS aws_lambda_alias
  INNER JOIN resource_relation AS RR
    ON RR.resource_id = aws_lambda_alias.id
    AND RR.relation = 'forwards-to'
  INNER JOIN resource AS aws_lambda_functionversion
    ON aws_lambda_functionversion.id = RR.target_id
    AND aws_lambda_functionversion.provider_type = 'FunctionVersion'
  LEFT JOIN resource_relation_attribute AS weight
    ON weight.relation_id = RR.id
    AND weight.name = 'weight'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_lambda_alias_functionversion;

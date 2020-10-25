DROP MATERIALIZED VIEW IF EXISTS aws_lambda_alias CASCADE;

CREATE MATERIALIZED VIEW aws_lambda_alias AS
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
  LEFT JOIN resource_attribute AS aliasarn
    ON aliasarn.resource_id = R.id
    AND aliasarn.type = 'provider'
    AND lower(aliasarn.attr_name) = 'aliasarn'
  LEFT JOIN resource_attribute AS name
    ON name.resource_id = R.id
    AND name.type = 'provider'
    AND lower(name.attr_name) = 'name'
  LEFT JOIN resource_attribute AS functionversion
    ON functionversion.resource_id = R.id
    AND functionversion.type = 'provider'
    AND lower(functionversion.attr_name) = 'functionversion'
  LEFT JOIN resource_attribute AS description
    ON description.resource_id = R.id
    AND description.type = 'provider'
    AND lower(description.attr_name) = 'description'
  LEFT JOIN resource_attribute AS routingconfig
    ON routingconfig.resource_id = R.id
    AND routingconfig.type = 'provider'
    AND lower(routingconfig.attr_name) = 'routingconfig'
  LEFT JOIN resource_attribute AS revisionid
    ON revisionid.resource_id = R.id
    AND revisionid.type = 'provider'
    AND lower(revisionid.attr_name) = 'revisionid'
  LEFT JOIN resource_attribute AS Policy
    ON Policy.resource_id = R.id
    AND Policy.type = 'provider'
    AND lower(Policy.attr_name) = 'policy'
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
  AND R.provider_type = 'Alias'
  AND R.service = 'lambda'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_lambda_alias;

COMMENT ON MATERIALIZED VIEW aws_lambda_alias IS 'lambda Alias resources and their associated attributes.';



DROP MATERIALIZED VIEW IF EXISTS aws_lambda_Alias_functionversion CASCADE;

CREATE MATERIALIZED VIEW aws_lambda_Alias_functionversion AS
SELECT
  aws_lambda_Alias.id AS Alias_id,
  aws_lambda_functionversion.id AS functionversion_id,
  (weight.value #>> '{}')::double precision AS weight
FROM
  resource AS aws_lambda_Alias
  INNER JOIN resource_relation AS RR
    ON RR.resource_id = aws_lambda_Alias.id
    AND RR.relation = 'forwards-to'
  INNER JOIN resource AS aws_lambda_functionversion
    ON aws_lambda_functionversion.id = RR.target_id
    AND aws_lambda_functionversion.provider_type = 'FunctionVersion'
  LEFT JOIN resource_relation_attribute AS weight
    ON weight.relation_id = RR.id
    AND weight.name = 'weight'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_lambda_Alias_functionversion;

INSERT INTO aws_lambda_alias (
  _id,
  uri,
  provider_account_id,
  aliasarn,
  name,
  functionversion,
  description,
  routingconfig,
  revisionid,
  policy,
  _policy,
  _function_id,_account_id
)
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  aliasarn.attr_value #>> '{}' AS aliasarn,
  name.attr_value #>> '{}' AS name,
  functionversion.attr_value #>> '{}' AS functionversion,
  description.attr_value #>> '{}' AS description,
  routingconfig.attr_value::jsonb AS routingconfig,
  revisionid.attr_value #>> '{}' AS revisionid,
  Policy.attr_value::jsonb AS policy,
  _policy.attr_value::jsonb AS _policy,
  
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
  LEFT JOIN resource_attribute AS _policy
    ON _policy.resource_id = R.id
    AND _policy.type = 'Metadata'
    AND lower(_policy.attr_name) = 'policy'
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
ON CONFLICT (_id) DO UPDATE
SET
    aliasarn = EXCLUDED.aliasarn,
    name = EXCLUDED.name,
    functionversion = EXCLUDED.functionversion,
    description = EXCLUDED.description,
    routingconfig = EXCLUDED.routingconfig,
    revisionid = EXCLUDED.revisionid,
    Policy = EXCLUDED.Policy,
    _policy = EXCLUDED._policy,
    _function_id = EXCLUDED._function_id,
    _account_id = EXCLUDED._account_id
  ;



INSERT INTO aws_lambda_alias_functionversion
SELECT
  aws_lambda_alias.id AS alias_id,
  aws_lambda_functionversion.id AS functionversion_id,
  aws_lambda_alias.provider_account_id AS provider_account_id,
  (weight.value #>> '{}')::double precision AS weight
FROM
  resource AS aws_lambda_alias
  INNER JOIN resource_relation AS RR
    ON RR.resource_id = aws_lambda_alias.id
    AND RR.relation = 'forwards-to'
  INNER JOIN resource AS aws_lambda_functionversion
    ON aws_lambda_functionversion.id = RR.target_id
    AND aws_lambda_functionversion.provider_type = 'FunctionVersion'
    AND aws_lambda_functionversion.service = 'lambda'
  LEFT JOIN resource_relation_attribute AS weight
    ON weight.relation_id = RR.id
    AND weight.name = 'weight'
  WHERE
    aws_lambda_alias.provider_type = 'Alias'
    AND aws_lambda_alias.service = 'lambda'
ON CONFLICT (alias_id, functionversion_id)

DO UPDATE
SET
  
  weight = EXCLUDED.weight;

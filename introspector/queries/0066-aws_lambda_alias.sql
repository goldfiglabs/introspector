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
  attrs.provider ->> 'AliasArn' AS aliasarn,
  attrs.provider ->> 'Name' AS name,
  attrs.provider ->> 'FunctionVersion' AS functionversion,
  attrs.provider ->> 'Description' AS description,
  attrs.provider -> 'RoutingConfig' AS routingconfig,
  attrs.provider ->> 'RevisionId' AS revisionid,
  attrs.provider -> 'Policy' AS policy,
  attrs.metadata -> 'Policy' AS policy,
  
    _function_id.target_id AS _function_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  LEFT JOIN attrs ON
    attrs.resource_id = R.id
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
        AND _aws_lambda_function.provider_account_id = :provider_account_id
    WHERE
      _aws_lambda_function_relation.relation = 'aliases'
      AND _aws_lambda_function_relation.provider_account_id = :provider_account_id
  ) AS _function_id ON _function_id.resource_id = R.id
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
  AND R.provider_type = 'Alias'
  AND R.service = 'lambda'
ON CONFLICT (_id) DO UPDATE
SET
    AliasArn = EXCLUDED.AliasArn,
    Name = EXCLUDED.Name,
    FunctionVersion = EXCLUDED.FunctionVersion,
    Description = EXCLUDED.Description,
    RoutingConfig = EXCLUDED.RoutingConfig,
    RevisionId = EXCLUDED.RevisionId,
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
    AND aws_lambda_functionversion.provider_account_id = :provider_account_id
  LEFT JOIN resource_relation_attribute AS weight
    ON weight.relation_id = RR.id
    AND weight.name = 'weight'
  WHERE
    aws_lambda_alias.provider_account_id = :provider_account_id
    AND aws_lambda_alias.provider_type = 'Alias'
    AND aws_lambda_alias.service = 'lambda'
ON CONFLICT (alias_id, functionversion_id)

DO UPDATE
SET
  
  weight = EXCLUDED.weight;

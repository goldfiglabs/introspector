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
INSERT INTO aws_apigatewayv2_api (
  _id,
  uri,
  provider_account_id,
  apiendpoint,
  apigatewaymanaged,
  apiid,
  apikeyselectionexpression,
  corsconfiguration,
  createddate,
  description,
  disableschemavalidation,
  disableexecuteapiendpoint,
  importinfo,
  name,
  protocoltype,
  routeselectionexpression,
  tags,
  version,
  warnings,
  stages,
  _tags,
  _account_id
)
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  attrs.provider ->> 'ApiEndpoint' AS apiendpoint,
  (attrs.provider ->> 'ApiGatewayManaged')::boolean AS apigatewaymanaged,
  attrs.provider ->> 'ApiId' AS apiid,
  attrs.provider ->> 'ApiKeySelectionExpression' AS apikeyselectionexpression,
  attrs.provider -> 'CorsConfiguration' AS corsconfiguration,
  (TO_TIMESTAMP(attrs.provider ->> 'CreatedDate', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS createddate,
  attrs.provider ->> 'Description' AS description,
  (attrs.provider ->> 'DisableSchemaValidation')::boolean AS disableschemavalidation,
  (attrs.provider ->> 'DisableExecuteApiEndpoint')::boolean AS disableexecuteapiendpoint,
  attrs.provider -> 'ImportInfo' AS importinfo,
  attrs.provider ->> 'Name' AS name,
  attrs.provider ->> 'ProtocolType' AS protocoltype,
  attrs.provider ->> 'RouteSelectionExpression' AS routeselectionexpression,
  attrs.provider -> 'Tags' AS tags,
  attrs.provider ->> 'Version' AS version,
  attrs.provider -> 'Warnings' AS warnings,
  attrs.provider -> 'Stages' AS stages,
  attrs.metadata -> 'Tags' AS tags,
  
    _account_id.target_id AS _account_id
FROM
  resource AS R
  LEFT JOIN attrs ON
    attrs.resource_id = R.id
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
  AND R.provider_type = 'Api'
  AND R.service = 'apigatewayv2'
ON CONFLICT (_id) DO UPDATE
SET
    ApiEndpoint = EXCLUDED.ApiEndpoint,
    ApiGatewayManaged = EXCLUDED.ApiGatewayManaged,
    ApiId = EXCLUDED.ApiId,
    ApiKeySelectionExpression = EXCLUDED.ApiKeySelectionExpression,
    CorsConfiguration = EXCLUDED.CorsConfiguration,
    CreatedDate = EXCLUDED.CreatedDate,
    Description = EXCLUDED.Description,
    DisableSchemaValidation = EXCLUDED.DisableSchemaValidation,
    DisableExecuteApiEndpoint = EXCLUDED.DisableExecuteApiEndpoint,
    ImportInfo = EXCLUDED.ImportInfo,
    Name = EXCLUDED.Name,
    ProtocolType = EXCLUDED.ProtocolType,
    RouteSelectionExpression = EXCLUDED.RouteSelectionExpression,
    Tags = EXCLUDED.Tags,
    Version = EXCLUDED.Version,
    Warnings = EXCLUDED.Warnings,
    Stages = EXCLUDED.Stages,
    _tags = EXCLUDED._tags,
    _account_id = EXCLUDED._account_id
  ;


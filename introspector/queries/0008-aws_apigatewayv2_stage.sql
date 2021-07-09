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
INSERT INTO aws_apigatewayv2_stage (
  _id,
  uri,
  provider_account_id,
  accesslogsettings,
  apigatewaymanaged,
  autodeploy,
  clientcertificateid,
  createddate,
  defaultroutesettings,
  deploymentid,
  description,
  lastdeploymentstatusmessage,
  lastupdateddate,
  routesettings,
  stagename,
  stagevariables,
  tags,
  _tags,
  _api_id,_account_id
)
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  attrs.provider -> 'AccessLogSettings' AS accesslogsettings,
  (attrs.provider ->> 'ApiGatewayManaged')::boolean AS apigatewaymanaged,
  (attrs.provider ->> 'AutoDeploy')::boolean AS autodeploy,
  attrs.provider ->> 'ClientCertificateId' AS clientcertificateid,
  (TO_TIMESTAMP(attrs.provider ->> 'CreatedDate', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS createddate,
  attrs.provider -> 'DefaultRouteSettings' AS defaultroutesettings,
  attrs.provider ->> 'DeploymentId' AS deploymentid,
  attrs.provider ->> 'Description' AS description,
  attrs.provider ->> 'LastDeploymentStatusMessage' AS lastdeploymentstatusmessage,
  (TO_TIMESTAMP(attrs.provider ->> 'LastUpdatedDate', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS lastupdateddate,
  attrs.provider -> 'RouteSettings' AS routesettings,
  attrs.provider ->> 'StageName' AS stagename,
  attrs.provider -> 'StageVariables' AS stagevariables,
  attrs.provider -> 'Tags' AS tags,
  attrs.metadata -> 'Tags' AS tags,
  
    _api_id.target_id AS _api_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  LEFT JOIN attrs ON
    attrs.resource_id = R.id
  LEFT JOIN (
    SELECT
      _aws_apigatewayv2_api_relation.resource_id AS resource_id,
      _aws_apigatewayv2_api.id AS target_id
    FROM
      resource_relation AS _aws_apigatewayv2_api_relation
      INNER JOIN resource AS _aws_apigatewayv2_api
        ON _aws_apigatewayv2_api_relation.target_id = _aws_apigatewayv2_api.id
        AND _aws_apigatewayv2_api.provider_type = 'Api'
        AND _aws_apigatewayv2_api.service = 'apigatewayv2'
        AND _aws_apigatewayv2_api.provider_account_id = :provider_account_id
    WHERE
      _aws_apigatewayv2_api_relation.relation = 'belongs-to'
      AND _aws_apigatewayv2_api_relation.provider_account_id = :provider_account_id
  ) AS _api_id ON _api_id.resource_id = R.id
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
  AND R.provider_type = 'Stage'
  AND R.service = 'apigatewayv2'
ON CONFLICT (_id) DO UPDATE
SET
    AccessLogSettings = EXCLUDED.AccessLogSettings,
    ApiGatewayManaged = EXCLUDED.ApiGatewayManaged,
    AutoDeploy = EXCLUDED.AutoDeploy,
    ClientCertificateId = EXCLUDED.ClientCertificateId,
    CreatedDate = EXCLUDED.CreatedDate,
    DefaultRouteSettings = EXCLUDED.DefaultRouteSettings,
    DeploymentId = EXCLUDED.DeploymentId,
    Description = EXCLUDED.Description,
    LastDeploymentStatusMessage = EXCLUDED.LastDeploymentStatusMessage,
    LastUpdatedDate = EXCLUDED.LastUpdatedDate,
    RouteSettings = EXCLUDED.RouteSettings,
    StageName = EXCLUDED.StageName,
    StageVariables = EXCLUDED.StageVariables,
    Tags = EXCLUDED.Tags,
    _tags = EXCLUDED._tags,
    _api_id = EXCLUDED._api_id,
    _account_id = EXCLUDED._account_id
  ;


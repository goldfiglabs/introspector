DROP MATERIALIZED VIEW IF EXISTS aws_apigatewayv2_stage CASCADE;

CREATE MATERIALIZED VIEW aws_apigatewayv2_stage AS
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
  accesslogsettings.attr_value::jsonb AS accesslogsettings,
  (apigatewaymanaged.attr_value #>> '{}')::boolean AS apigatewaymanaged,
  (autodeploy.attr_value #>> '{}')::boolean AS autodeploy,
  clientcertificateid.attr_value #>> '{}' AS clientcertificateid,
  (TO_TIMESTAMP(createddate.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS createddate,
  defaultroutesettings.attr_value::jsonb AS defaultroutesettings,
  deploymentid.attr_value #>> '{}' AS deploymentid,
  description.attr_value #>> '{}' AS description,
  lastdeploymentstatusmessage.attr_value #>> '{}' AS lastdeploymentstatusmessage,
  (TO_TIMESTAMP(lastupdateddate.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS lastupdateddate,
  routesettings.attr_value::jsonb AS routesettings,
  stagename.attr_value #>> '{}' AS stagename,
  stagevariables.attr_value::jsonb AS stagevariables,
  tags.attr_value::jsonb AS tags,
  
    _api_id.target_id AS _api_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN attrs AS accesslogsettings
    ON accesslogsettings.id = R.id
    AND accesslogsettings.attr_name = 'accesslogsettings'
  LEFT JOIN attrs AS apigatewaymanaged
    ON apigatewaymanaged.id = R.id
    AND apigatewaymanaged.attr_name = 'apigatewaymanaged'
  LEFT JOIN attrs AS autodeploy
    ON autodeploy.id = R.id
    AND autodeploy.attr_name = 'autodeploy'
  LEFT JOIN attrs AS clientcertificateid
    ON clientcertificateid.id = R.id
    AND clientcertificateid.attr_name = 'clientcertificateid'
  LEFT JOIN attrs AS createddate
    ON createddate.id = R.id
    AND createddate.attr_name = 'createddate'
  LEFT JOIN attrs AS defaultroutesettings
    ON defaultroutesettings.id = R.id
    AND defaultroutesettings.attr_name = 'defaultroutesettings'
  LEFT JOIN attrs AS deploymentid
    ON deploymentid.id = R.id
    AND deploymentid.attr_name = 'deploymentid'
  LEFT JOIN attrs AS description
    ON description.id = R.id
    AND description.attr_name = 'description'
  LEFT JOIN attrs AS lastdeploymentstatusmessage
    ON lastdeploymentstatusmessage.id = R.id
    AND lastdeploymentstatusmessage.attr_name = 'lastdeploymentstatusmessage'
  LEFT JOIN attrs AS lastupdateddate
    ON lastupdateddate.id = R.id
    AND lastupdateddate.attr_name = 'lastupdateddate'
  LEFT JOIN attrs AS routesettings
    ON routesettings.id = R.id
    AND routesettings.attr_name = 'routesettings'
  LEFT JOIN attrs AS stagename
    ON stagename.id = R.id
    AND stagename.attr_name = 'stagename'
  LEFT JOIN attrs AS stagevariables
    ON stagevariables.id = R.id
    AND stagevariables.attr_name = 'stagevariables'
  LEFT JOIN attrs AS tags
    ON tags.id = R.id
    AND tags.attr_name = 'tags'
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
    WHERE
      _aws_apigatewayv2_api_relation.relation = 'belongs-to'
  ) AS _api_id ON _api_id.resource_id = R.id
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
  AND LOWER(R.provider_type) = 'stage'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_apigatewayv2_stage;

COMMENT ON MATERIALIZED VIEW aws_apigatewayv2_stage IS 'apigatewayv2 stage resources and their associated attributes.';


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
  _tags.attr_value::jsonb AS _tags,
  
    _api_id.target_id AS _api_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN resource_attribute AS accesslogsettings
    ON accesslogsettings.resource_id = R.id
    AND accesslogsettings.type = 'provider'
    AND lower(accesslogsettings.attr_name) = 'accesslogsettings'
    AND accesslogsettings.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS apigatewaymanaged
    ON apigatewaymanaged.resource_id = R.id
    AND apigatewaymanaged.type = 'provider'
    AND lower(apigatewaymanaged.attr_name) = 'apigatewaymanaged'
    AND apigatewaymanaged.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS autodeploy
    ON autodeploy.resource_id = R.id
    AND autodeploy.type = 'provider'
    AND lower(autodeploy.attr_name) = 'autodeploy'
    AND autodeploy.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS clientcertificateid
    ON clientcertificateid.resource_id = R.id
    AND clientcertificateid.type = 'provider'
    AND lower(clientcertificateid.attr_name) = 'clientcertificateid'
    AND clientcertificateid.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS createddate
    ON createddate.resource_id = R.id
    AND createddate.type = 'provider'
    AND lower(createddate.attr_name) = 'createddate'
    AND createddate.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS defaultroutesettings
    ON defaultroutesettings.resource_id = R.id
    AND defaultroutesettings.type = 'provider'
    AND lower(defaultroutesettings.attr_name) = 'defaultroutesettings'
    AND defaultroutesettings.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS deploymentid
    ON deploymentid.resource_id = R.id
    AND deploymentid.type = 'provider'
    AND lower(deploymentid.attr_name) = 'deploymentid'
    AND deploymentid.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS description
    ON description.resource_id = R.id
    AND description.type = 'provider'
    AND lower(description.attr_name) = 'description'
    AND description.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS lastdeploymentstatusmessage
    ON lastdeploymentstatusmessage.resource_id = R.id
    AND lastdeploymentstatusmessage.type = 'provider'
    AND lower(lastdeploymentstatusmessage.attr_name) = 'lastdeploymentstatusmessage'
    AND lastdeploymentstatusmessage.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS lastupdateddate
    ON lastupdateddate.resource_id = R.id
    AND lastupdateddate.type = 'provider'
    AND lower(lastupdateddate.attr_name) = 'lastupdateddate'
    AND lastupdateddate.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS routesettings
    ON routesettings.resource_id = R.id
    AND routesettings.type = 'provider'
    AND lower(routesettings.attr_name) = 'routesettings'
    AND routesettings.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS stagename
    ON stagename.resource_id = R.id
    AND stagename.type = 'provider'
    AND lower(stagename.attr_name) = 'stagename'
    AND stagename.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS stagevariables
    ON stagevariables.resource_id = R.id
    AND stagevariables.type = 'provider'
    AND lower(stagevariables.attr_name) = 'stagevariables'
    AND stagevariables.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS tags
    ON tags.resource_id = R.id
    AND tags.type = 'provider'
    AND lower(tags.attr_name) = 'tags'
    AND tags.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS _tags
    ON _tags.resource_id = R.id
    AND _tags.type = 'Metadata'
    AND lower(_tags.attr_name) = 'tags'
    AND _tags.provider_account_id = R.provider_account_id
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
        AND _aws_organizations_account_relation.provider_account_id = :provider_account_id
      GROUP BY _aws_organizations_account_relation.resource_id
      HAVING COUNT(*) = 1
    ) AS unique_account_mapping
    INNER JOIN resource_relation AS _aws_organizations_account_relation
      ON _aws_organizations_account_relation.resource_id = unique_account_mapping.resource_id
    INNER JOIN resource AS _aws_organizations_account
      ON _aws_organizations_account_relation.target_id = _aws_organizations_account.id
      AND _aws_organizations_account.provider_type = 'Account'
      AND _aws_organizations_account.service = 'organizations'
      AND _aws_organizations_account_relation.provider_account_id = :provider_account_id
    WHERE
        _aws_organizations_account_relation.relation = 'in'
        AND _aws_organizations_account_relation.provider_account_id = :provider_account_id
  ) AS _account_id ON _account_id.resource_id = R.id
  WHERE
  R.provider_account_id = :provider_account_id
  AND PA.provider = 'aws'
  AND R.provider_type = 'Stage'
  AND R.service = 'apigatewayv2'
ON CONFLICT (_id) DO UPDATE
SET
    accesslogsettings = EXCLUDED.accesslogsettings,
    apigatewaymanaged = EXCLUDED.apigatewaymanaged,
    autodeploy = EXCLUDED.autodeploy,
    clientcertificateid = EXCLUDED.clientcertificateid,
    createddate = EXCLUDED.createddate,
    defaultroutesettings = EXCLUDED.defaultroutesettings,
    deploymentid = EXCLUDED.deploymentid,
    description = EXCLUDED.description,
    lastdeploymentstatusmessage = EXCLUDED.lastdeploymentstatusmessage,
    lastupdateddate = EXCLUDED.lastupdateddate,
    routesettings = EXCLUDED.routesettings,
    stagename = EXCLUDED.stagename,
    stagevariables = EXCLUDED.stagevariables,
    tags = EXCLUDED.tags,
    _tags = EXCLUDED._tags,
    _api_id = EXCLUDED._api_id,
    _account_id = EXCLUDED._account_id
  ;


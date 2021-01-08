INSERT INTO aws_apigatewayv2_api
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  apiendpoint.attr_value #>> '{}' AS apiendpoint,
  (apigatewaymanaged.attr_value #>> '{}')::boolean AS apigatewaymanaged,
  apiid.attr_value #>> '{}' AS apiid,
  apikeyselectionexpression.attr_value #>> '{}' AS apikeyselectionexpression,
  corsconfiguration.attr_value::jsonb AS corsconfiguration,
  (TO_TIMESTAMP(createddate.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS createddate,
  description.attr_value #>> '{}' AS description,
  (disableschemavalidation.attr_value #>> '{}')::boolean AS disableschemavalidation,
  (disableexecuteapiendpoint.attr_value #>> '{}')::boolean AS disableexecuteapiendpoint,
  importinfo.attr_value::jsonb AS importinfo,
  name.attr_value #>> '{}' AS name,
  protocoltype.attr_value #>> '{}' AS protocoltype,
  routeselectionexpression.attr_value #>> '{}' AS routeselectionexpression,
  tags.attr_value::jsonb AS tags,
  version.attr_value #>> '{}' AS version,
  warnings.attr_value::jsonb AS warnings,
  stages.attr_value::jsonb AS stages,
  
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN resource_attribute AS apiendpoint
    ON apiendpoint.resource_id = R.id
    AND apiendpoint.type = 'provider'
    AND lower(apiendpoint.attr_name) = 'apiendpoint'
  LEFT JOIN resource_attribute AS apigatewaymanaged
    ON apigatewaymanaged.resource_id = R.id
    AND apigatewaymanaged.type = 'provider'
    AND lower(apigatewaymanaged.attr_name) = 'apigatewaymanaged'
  LEFT JOIN resource_attribute AS apiid
    ON apiid.resource_id = R.id
    AND apiid.type = 'provider'
    AND lower(apiid.attr_name) = 'apiid'
  LEFT JOIN resource_attribute AS apikeyselectionexpression
    ON apikeyselectionexpression.resource_id = R.id
    AND apikeyselectionexpression.type = 'provider'
    AND lower(apikeyselectionexpression.attr_name) = 'apikeyselectionexpression'
  LEFT JOIN resource_attribute AS corsconfiguration
    ON corsconfiguration.resource_id = R.id
    AND corsconfiguration.type = 'provider'
    AND lower(corsconfiguration.attr_name) = 'corsconfiguration'
  LEFT JOIN resource_attribute AS createddate
    ON createddate.resource_id = R.id
    AND createddate.type = 'provider'
    AND lower(createddate.attr_name) = 'createddate'
  LEFT JOIN resource_attribute AS description
    ON description.resource_id = R.id
    AND description.type = 'provider'
    AND lower(description.attr_name) = 'description'
  LEFT JOIN resource_attribute AS disableschemavalidation
    ON disableschemavalidation.resource_id = R.id
    AND disableschemavalidation.type = 'provider'
    AND lower(disableschemavalidation.attr_name) = 'disableschemavalidation'
  LEFT JOIN resource_attribute AS disableexecuteapiendpoint
    ON disableexecuteapiendpoint.resource_id = R.id
    AND disableexecuteapiendpoint.type = 'provider'
    AND lower(disableexecuteapiendpoint.attr_name) = 'disableexecuteapiendpoint'
  LEFT JOIN resource_attribute AS importinfo
    ON importinfo.resource_id = R.id
    AND importinfo.type = 'provider'
    AND lower(importinfo.attr_name) = 'importinfo'
  LEFT JOIN resource_attribute AS name
    ON name.resource_id = R.id
    AND name.type = 'provider'
    AND lower(name.attr_name) = 'name'
  LEFT JOIN resource_attribute AS protocoltype
    ON protocoltype.resource_id = R.id
    AND protocoltype.type = 'provider'
    AND lower(protocoltype.attr_name) = 'protocoltype'
  LEFT JOIN resource_attribute AS routeselectionexpression
    ON routeselectionexpression.resource_id = R.id
    AND routeselectionexpression.type = 'provider'
    AND lower(routeselectionexpression.attr_name) = 'routeselectionexpression'
  LEFT JOIN resource_attribute AS tags
    ON tags.resource_id = R.id
    AND tags.type = 'provider'
    AND lower(tags.attr_name) = 'tags'
  LEFT JOIN resource_attribute AS version
    ON version.resource_id = R.id
    AND version.type = 'provider'
    AND lower(version.attr_name) = 'version'
  LEFT JOIN resource_attribute AS warnings
    ON warnings.resource_id = R.id
    AND warnings.type = 'provider'
    AND lower(warnings.attr_name) = 'warnings'
  LEFT JOIN resource_attribute AS stages
    ON stages.resource_id = R.id
    AND stages.type = 'provider'
    AND lower(stages.attr_name) = 'stages'
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
  AND R.provider_type = 'Api'
  AND R.service = 'apigatewayv2'
ON CONFLICT (_id) DO UPDATE
SET
    apiendpoint = EXCLUDED.apiendpoint,
    apigatewaymanaged = EXCLUDED.apigatewaymanaged,
    apiid = EXCLUDED.apiid,
    apikeyselectionexpression = EXCLUDED.apikeyselectionexpression,
    corsconfiguration = EXCLUDED.corsconfiguration,
    createddate = EXCLUDED.createddate,
    description = EXCLUDED.description,
    disableschemavalidation = EXCLUDED.disableschemavalidation,
    disableexecuteapiendpoint = EXCLUDED.disableexecuteapiendpoint,
    importinfo = EXCLUDED.importinfo,
    name = EXCLUDED.name,
    protocoltype = EXCLUDED.protocoltype,
    routeselectionexpression = EXCLUDED.routeselectionexpression,
    tags = EXCLUDED.tags,
    version = EXCLUDED.version,
    warnings = EXCLUDED.warnings,
    stages = EXCLUDED.stages,
    _account_id = EXCLUDED._account_id
  ;


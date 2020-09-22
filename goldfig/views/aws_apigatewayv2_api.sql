DROP MATERIALIZED VIEW IF EXISTS aws_apigatewayv2_api CASCADE;

CREATE MATERIALIZED VIEW aws_apigatewayv2_api AS
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
  apiendpoint.attr_value #>> '{}' AS apiendpoint,
  apiid.attr_value #>> '{}' AS apiid,
  apikeyselectionexpression.attr_value #>> '{}' AS apikeyselectionexpression,
  corsconfiguration.attr_value::jsonb AS corsconfiguration,
  (TO_TIMESTAMP(createddate.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS createddate,
  description.attr_value #>> '{}' AS description,
  (disableschemavalidation.attr_value #>> '{}')::boolean AS disableschemavalidation,
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
  LEFT JOIN attrs AS apiendpoint
    ON apiendpoint.id = R.id
    AND apiendpoint.attr_name = 'apiendpoint'
  LEFT JOIN attrs AS apiid
    ON apiid.id = R.id
    AND apiid.attr_name = 'apiid'
  LEFT JOIN attrs AS apikeyselectionexpression
    ON apikeyselectionexpression.id = R.id
    AND apikeyselectionexpression.attr_name = 'apikeyselectionexpression'
  LEFT JOIN attrs AS corsconfiguration
    ON corsconfiguration.id = R.id
    AND corsconfiguration.attr_name = 'corsconfiguration'
  LEFT JOIN attrs AS createddate
    ON createddate.id = R.id
    AND createddate.attr_name = 'createddate'
  LEFT JOIN attrs AS description
    ON description.id = R.id
    AND description.attr_name = 'description'
  LEFT JOIN attrs AS disableschemavalidation
    ON disableschemavalidation.id = R.id
    AND disableschemavalidation.attr_name = 'disableschemavalidation'
  LEFT JOIN attrs AS importinfo
    ON importinfo.id = R.id
    AND importinfo.attr_name = 'importinfo'
  LEFT JOIN attrs AS name
    ON name.id = R.id
    AND name.attr_name = 'name'
  LEFT JOIN attrs AS protocoltype
    ON protocoltype.id = R.id
    AND protocoltype.attr_name = 'protocoltype'
  LEFT JOIN attrs AS routeselectionexpression
    ON routeselectionexpression.id = R.id
    AND routeselectionexpression.attr_name = 'routeselectionexpression'
  LEFT JOIN attrs AS tags
    ON tags.id = R.id
    AND tags.attr_name = 'tags'
  LEFT JOIN attrs AS version
    ON version.id = R.id
    AND version.attr_name = 'version'
  LEFT JOIN attrs AS warnings
    ON warnings.id = R.id
    AND warnings.attr_name = 'warnings'
  LEFT JOIN attrs AS stages
    ON stages.id = R.id
    AND stages.attr_name = 'stages'
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
  AND LOWER(R.provider_type) = 'api'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_apigatewayv2_api;

COMMENT ON MATERIALIZED VIEW aws_apigatewayv2_api IS 'apigatewayv2 api resources and their associated attributes.';


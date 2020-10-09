DROP MATERIALIZED VIEW IF EXISTS aws_apigateway_restapi CASCADE;

CREATE MATERIALIZED VIEW aws_apigateway_restapi AS
SELECT
  R.id AS resource_id,
  R.uri,
  R.provider_account_id,
  id.attr_value #>> '{}' AS id,
  name.attr_value #>> '{}' AS name,
  description.attr_value #>> '{}' AS description,
  (TO_TIMESTAMP(createddate.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS createddate,
  version.attr_value #>> '{}' AS version,
  warnings.attr_value::jsonb AS warnings,
  binarymediatypes.attr_value::jsonb AS binarymediatypes,
  (minimumcompressionsize.attr_value #>> '{}')::integer AS minimumcompressionsize,
  apikeysource.attr_value #>> '{}' AS apikeysource,
  endpointconfiguration.attr_value::jsonb AS endpointconfiguration,
  policy.attr_value #>> '{}' AS policy,
  tags.attr_value::jsonb AS tags,
  stages.attr_value::jsonb AS stages,
  
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN resource_attribute AS id
    ON id.resource_id = R.id
    AND id.type = 'provider'
    AND lower(id.attr_name) = 'id'
  LEFT JOIN resource_attribute AS name
    ON name.resource_id = R.id
    AND name.type = 'provider'
    AND lower(name.attr_name) = 'name'
  LEFT JOIN resource_attribute AS description
    ON description.resource_id = R.id
    AND description.type = 'provider'
    AND lower(description.attr_name) = 'description'
  LEFT JOIN resource_attribute AS createddate
    ON createddate.resource_id = R.id
    AND createddate.type = 'provider'
    AND lower(createddate.attr_name) = 'createddate'
  LEFT JOIN resource_attribute AS version
    ON version.resource_id = R.id
    AND version.type = 'provider'
    AND lower(version.attr_name) = 'version'
  LEFT JOIN resource_attribute AS warnings
    ON warnings.resource_id = R.id
    AND warnings.type = 'provider'
    AND lower(warnings.attr_name) = 'warnings'
  LEFT JOIN resource_attribute AS binarymediatypes
    ON binarymediatypes.resource_id = R.id
    AND binarymediatypes.type = 'provider'
    AND lower(binarymediatypes.attr_name) = 'binarymediatypes'
  LEFT JOIN resource_attribute AS minimumcompressionsize
    ON minimumcompressionsize.resource_id = R.id
    AND minimumcompressionsize.type = 'provider'
    AND lower(minimumcompressionsize.attr_name) = 'minimumcompressionsize'
  LEFT JOIN resource_attribute AS apikeysource
    ON apikeysource.resource_id = R.id
    AND apikeysource.type = 'provider'
    AND lower(apikeysource.attr_name) = 'apikeysource'
  LEFT JOIN resource_attribute AS endpointconfiguration
    ON endpointconfiguration.resource_id = R.id
    AND endpointconfiguration.type = 'provider'
    AND lower(endpointconfiguration.attr_name) = 'endpointconfiguration'
  LEFT JOIN resource_attribute AS policy
    ON policy.resource_id = R.id
    AND policy.type = 'provider'
    AND lower(policy.attr_name) = 'policy'
  LEFT JOIN resource_attribute AS tags
    ON tags.resource_id = R.id
    AND tags.type = 'provider'
    AND lower(tags.attr_name) = 'tags'
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
  AND LOWER(R.provider_type) = 'restapi'
  AND R.service = 'apigateway'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_apigateway_restapi;

COMMENT ON MATERIALIZED VIEW aws_apigateway_restapi IS 'apigateway restapi resources and their associated attributes.';


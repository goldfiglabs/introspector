DROP MATERIALIZED VIEW IF EXISTS aws_apigateway_restapi CASCADE;

CREATE MATERIALIZED VIEW aws_apigateway_restapi AS
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
  LEFT JOIN attrs AS id
    ON id.id = R.id
    AND id.attr_name = 'id'
  LEFT JOIN attrs AS name
    ON name.id = R.id
    AND name.attr_name = 'name'
  LEFT JOIN attrs AS description
    ON description.id = R.id
    AND description.attr_name = 'description'
  LEFT JOIN attrs AS createddate
    ON createddate.id = R.id
    AND createddate.attr_name = 'createddate'
  LEFT JOIN attrs AS version
    ON version.id = R.id
    AND version.attr_name = 'version'
  LEFT JOIN attrs AS warnings
    ON warnings.id = R.id
    AND warnings.attr_name = 'warnings'
  LEFT JOIN attrs AS binarymediatypes
    ON binarymediatypes.id = R.id
    AND binarymediatypes.attr_name = 'binarymediatypes'
  LEFT JOIN attrs AS minimumcompressionsize
    ON minimumcompressionsize.id = R.id
    AND minimumcompressionsize.attr_name = 'minimumcompressionsize'
  LEFT JOIN attrs AS apikeysource
    ON apikeysource.id = R.id
    AND apikeysource.attr_name = 'apikeysource'
  LEFT JOIN attrs AS endpointconfiguration
    ON endpointconfiguration.id = R.id
    AND endpointconfiguration.attr_name = 'endpointconfiguration'
  LEFT JOIN attrs AS policy
    ON policy.id = R.id
    AND policy.attr_name = 'policy'
  LEFT JOIN attrs AS tags
    ON tags.id = R.id
    AND tags.attr_name = 'tags'
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
  AND LOWER(R.provider_type) = 'restapi'
  AND R.service = 'apigateway'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_apigateway_restapi;

COMMENT ON MATERIALIZED VIEW aws_apigateway_restapi IS 'apigateway restapi resources and their associated attributes.';


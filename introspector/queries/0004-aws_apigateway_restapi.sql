INSERT INTO aws_apigateway_restapi (
  _id,
  uri,
  provider_account_id,
  id,
  name,
  description,
  createddate,
  version,
  warnings,
  binarymediatypes,
  minimumcompressionsize,
  apikeysource,
  endpointconfiguration,
  policy,
  tags,
  disableexecuteapiendpoint,
  stages,
  _tags,
  _policy,
  _account_id
)
SELECT
  R.id AS _id,
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
  (disableexecuteapiendpoint.attr_value #>> '{}')::boolean AS disableexecuteapiendpoint,
  stages.attr_value::jsonb AS stages,
  _tags.attr_value::jsonb AS _tags,
  _policy.attr_value::jsonb AS _policy,
  
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN resource_attribute AS id
    ON id.resource_id = R.id
    AND id.type = 'provider'
    AND lower(id.attr_name) = 'id'
    AND id.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS name
    ON name.resource_id = R.id
    AND name.type = 'provider'
    AND lower(name.attr_name) = 'name'
    AND name.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS description
    ON description.resource_id = R.id
    AND description.type = 'provider'
    AND lower(description.attr_name) = 'description'
    AND description.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS createddate
    ON createddate.resource_id = R.id
    AND createddate.type = 'provider'
    AND lower(createddate.attr_name) = 'createddate'
    AND createddate.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS version
    ON version.resource_id = R.id
    AND version.type = 'provider'
    AND lower(version.attr_name) = 'version'
    AND version.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS warnings
    ON warnings.resource_id = R.id
    AND warnings.type = 'provider'
    AND lower(warnings.attr_name) = 'warnings'
    AND warnings.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS binarymediatypes
    ON binarymediatypes.resource_id = R.id
    AND binarymediatypes.type = 'provider'
    AND lower(binarymediatypes.attr_name) = 'binarymediatypes'
    AND binarymediatypes.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS minimumcompressionsize
    ON minimumcompressionsize.resource_id = R.id
    AND minimumcompressionsize.type = 'provider'
    AND lower(minimumcompressionsize.attr_name) = 'minimumcompressionsize'
    AND minimumcompressionsize.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS apikeysource
    ON apikeysource.resource_id = R.id
    AND apikeysource.type = 'provider'
    AND lower(apikeysource.attr_name) = 'apikeysource'
    AND apikeysource.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS endpointconfiguration
    ON endpointconfiguration.resource_id = R.id
    AND endpointconfiguration.type = 'provider'
    AND lower(endpointconfiguration.attr_name) = 'endpointconfiguration'
    AND endpointconfiguration.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS policy
    ON policy.resource_id = R.id
    AND policy.type = 'provider'
    AND lower(policy.attr_name) = 'policy'
    AND policy.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS tags
    ON tags.resource_id = R.id
    AND tags.type = 'provider'
    AND lower(tags.attr_name) = 'tags'
    AND tags.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS disableexecuteapiendpoint
    ON disableexecuteapiendpoint.resource_id = R.id
    AND disableexecuteapiendpoint.type = 'provider'
    AND lower(disableexecuteapiendpoint.attr_name) = 'disableexecuteapiendpoint'
    AND disableexecuteapiendpoint.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS stages
    ON stages.resource_id = R.id
    AND stages.type = 'provider'
    AND lower(stages.attr_name) = 'stages'
    AND stages.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS _tags
    ON _tags.resource_id = R.id
    AND _tags.type = 'Metadata'
    AND lower(_tags.attr_name) = 'tags'
    AND _tags.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS _policy
    ON _policy.resource_id = R.id
    AND _policy.type = 'Metadata'
    AND lower(_policy.attr_name) = 'policy'
    AND _policy.provider_account_id = R.provider_account_id
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
  AND R.provider_type = 'RestApi'
  AND R.service = 'apigateway'
ON CONFLICT (_id) DO UPDATE
SET
    id = EXCLUDED.id,
    name = EXCLUDED.name,
    description = EXCLUDED.description,
    createddate = EXCLUDED.createddate,
    version = EXCLUDED.version,
    warnings = EXCLUDED.warnings,
    binarymediatypes = EXCLUDED.binarymediatypes,
    minimumcompressionsize = EXCLUDED.minimumcompressionsize,
    apikeysource = EXCLUDED.apikeysource,
    endpointconfiguration = EXCLUDED.endpointconfiguration,
    policy = EXCLUDED.policy,
    tags = EXCLUDED.tags,
    disableexecuteapiendpoint = EXCLUDED.disableexecuteapiendpoint,
    stages = EXCLUDED.stages,
    _tags = EXCLUDED._tags,
    _policy = EXCLUDED._policy,
    _account_id = EXCLUDED._account_id
  ;


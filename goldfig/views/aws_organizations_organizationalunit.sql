DROP MATERIALIZED VIEW IF EXISTS aws_organizations_organizationalunit CASCADE;

CREATE MATERIALIZED VIEW aws_organizations_organizationalunit AS
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
  arn.attr_value #>> '{}' AS arn,
  name.attr_value #>> '{}' AS name,
  servicecontrolpolicies.attr_value::jsonb AS servicecontrolpolicies,
  tagpolicies.attr_value::jsonb AS tagpolicies,
  
    _root_id.target_id AS _root_id,
    _organizational_unit_id.target_id AS _organizational_unit_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN attrs AS id
    ON id.id = R.id
    AND id.attr_name = 'id'
  LEFT JOIN attrs AS arn
    ON arn.id = R.id
    AND arn.attr_name = 'arn'
  LEFT JOIN attrs AS name
    ON name.id = R.id
    AND name.attr_name = 'name'
  LEFT JOIN attrs AS servicecontrolpolicies
    ON servicecontrolpolicies.id = R.id
    AND servicecontrolpolicies.attr_name = 'servicecontrolpolicies'
  LEFT JOIN attrs AS tagpolicies
    ON tagpolicies.id = R.id
    AND tagpolicies.attr_name = 'tagpolicies'
  LEFT JOIN (
    SELECT
      _aws_organizations_root_relation.resource_id AS resource_id,
      _aws_organizations_root.id AS target_id
    FROM
      resource_relation AS _aws_organizations_root_relation
      INNER JOIN resource AS _aws_organizations_root
        ON _aws_organizations_root_relation.target_id = _aws_organizations_root.id
        AND _aws_organizations_root.provider_type = 'Root'
        AND _aws_organizations_root.service = 'organizations'
    WHERE
      _aws_organizations_root_relation.relation = 'in'
  ) AS _root_id ON _root_id.resource_id = R.id
  LEFT JOIN (
    SELECT
      _aws_organizations_organizationalunit_relation.resource_id AS resource_id,
      _aws_organizations_organizationalunit.id AS target_id
    FROM
      resource_relation AS _aws_organizations_organizationalunit_relation
      INNER JOIN resource AS _aws_organizations_organizationalunit
        ON _aws_organizations_organizationalunit_relation.target_id = _aws_organizations_organizationalunit.id
        AND _aws_organizations_organizationalunit.provider_type = 'OrganizationalUnit'
        AND _aws_organizations_organizationalunit.service = 'organizations'
    WHERE
      _aws_organizations_organizationalunit_relation.relation = 'in'
  ) AS _organizational_unit_id ON _organizational_unit_id.resource_id = R.id
  WHERE
  PA.provider = 'aws'
  AND LOWER(R.provider_type) = 'organizationalunit'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_organizations_organizationalunit;

COMMENT ON MATERIALIZED VIEW aws_organizations_organizationalunit IS 'organizations organizationalunit resources and their associated attributes.';


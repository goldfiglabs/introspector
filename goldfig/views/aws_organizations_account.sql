DROP MATERIALIZED VIEW IF EXISTS aws_organizations_account CASCADE;

CREATE MATERIALIZED VIEW aws_organizations_account AS
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
  email.attr_value #>> '{}' AS email,
  name.attr_value #>> '{}' AS name,
  status.attr_value #>> '{}' AS status,
  joinedmethod.attr_value #>> '{}' AS joinedmethod,
  joinedtimestamp.attr_value AS joinedtimestamp,
  servicecontrolpolicies.attr_value::jsonb AS servicecontrolpolicies,
  tagpolicies.attr_value::jsonb AS tagpolicies,
  tags.attr_value::jsonb AS tags,
  
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
  LEFT JOIN attrs AS email
    ON email.id = R.id
    AND email.attr_name = 'email'
  LEFT JOIN attrs AS name
    ON name.id = R.id
    AND name.attr_name = 'name'
  LEFT JOIN attrs AS status
    ON status.id = R.id
    AND status.attr_name = 'status'
  LEFT JOIN attrs AS joinedmethod
    ON joinedmethod.id = R.id
    AND joinedmethod.attr_name = 'joinedmethod'
  LEFT JOIN attrs AS joinedtimestamp
    ON joinedtimestamp.id = R.id
    AND joinedtimestamp.attr_name = 'joinedtimestamp'
  LEFT JOIN attrs AS servicecontrolpolicies
    ON servicecontrolpolicies.id = R.id
    AND servicecontrolpolicies.attr_name = 'servicecontrolpolicies'
  LEFT JOIN attrs AS tagpolicies
    ON tagpolicies.id = R.id
    AND tagpolicies.attr_name = 'tagpolicies'
  LEFT JOIN attrs AS tags
    ON tags.id = R.id
    AND tags.attr_name = 'tags'
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
  AND LOWER(R.provider_type) = 'account'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_organizations_account;

COMMENT ON MATERIALIZED VIEW aws_organizations_account IS 'organizations account resources and their associated attributes.';


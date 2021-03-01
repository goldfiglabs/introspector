INSERT INTO aws_organizations_organizationalunit (
  _id,
  uri,
  provider_account_id,
  id,
  arn,
  name,
  servicecontrolpolicies,
  tagpolicies,
  _root_id,_organizational_unit_id
)
SELECT
  R.id AS _id,
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
  LEFT JOIN resource_attribute AS id
    ON id.resource_id = R.id
    AND id.type = 'provider'
    AND lower(id.attr_name) = 'id'
  LEFT JOIN resource_attribute AS arn
    ON arn.resource_id = R.id
    AND arn.type = 'provider'
    AND lower(arn.attr_name) = 'arn'
  LEFT JOIN resource_attribute AS name
    ON name.resource_id = R.id
    AND name.type = 'provider'
    AND lower(name.attr_name) = 'name'
  LEFT JOIN resource_attribute AS servicecontrolpolicies
    ON servicecontrolpolicies.resource_id = R.id
    AND servicecontrolpolicies.type = 'provider'
    AND lower(servicecontrolpolicies.attr_name) = 'servicecontrolpolicies'
  LEFT JOIN resource_attribute AS tagpolicies
    ON tagpolicies.resource_id = R.id
    AND tagpolicies.type = 'provider'
    AND lower(tagpolicies.attr_name) = 'tagpolicies'
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
  AND R.provider_type = 'OrganizationalUnit'
  AND R.service = 'organizations'
ON CONFLICT (_id) DO UPDATE
SET
    id = EXCLUDED.id,
    arn = EXCLUDED.arn,
    name = EXCLUDED.name,
    servicecontrolpolicies = EXCLUDED.servicecontrolpolicies,
    tagpolicies = EXCLUDED.tagpolicies,
    _root_id = EXCLUDED._root_id,
    _organizational_unit_id = EXCLUDED._organizational_unit_id
  ;


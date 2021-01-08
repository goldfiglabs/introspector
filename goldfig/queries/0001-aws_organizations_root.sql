INSERT INTO aws_organizations_root
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  id.attr_value #>> '{}' AS id,
  arn.attr_value #>> '{}' AS arn,
  name.attr_value #>> '{}' AS name,
  policytypes.attr_value::jsonb AS policytypes,
  servicecontrolpolicies.attr_value::jsonb AS servicecontrolpolicies,
  tagpolicies.attr_value::jsonb AS tagpolicies,
  
    _organization_id.target_id AS _organization_id
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
  LEFT JOIN resource_attribute AS policytypes
    ON policytypes.resource_id = R.id
    AND policytypes.type = 'provider'
    AND lower(policytypes.attr_name) = 'policytypes'
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
      _aws_organizations_organization_relation.resource_id AS resource_id,
      _aws_organizations_organization.id AS target_id
    FROM
      resource_relation AS _aws_organizations_organization_relation
      INNER JOIN resource AS _aws_organizations_organization
        ON _aws_organizations_organization_relation.target_id = _aws_organizations_organization.id
        AND _aws_organizations_organization.provider_type = 'Organization'
        AND _aws_organizations_organization.service = 'organizations'
    WHERE
      _aws_organizations_organization_relation.relation = 'in'
  ) AS _organization_id ON _organization_id.resource_id = R.id
  WHERE
  PA.provider = 'aws'
  AND R.provider_type = 'Root'
  AND R.service = 'organizations'
ON CONFLICT (_id) DO UPDATE
SET
    id = EXCLUDED.id,
    arn = EXCLUDED.arn,
    name = EXCLUDED.name,
    policytypes = EXCLUDED.policytypes,
    servicecontrolpolicies = EXCLUDED.servicecontrolpolicies,
    tagpolicies = EXCLUDED.tagpolicies,
    _organization_id = EXCLUDED._organization_id
  ;


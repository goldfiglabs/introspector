WITH attrs AS (
  SELECT
    resource_id,
    jsonb_object_agg(attr_name, attr_value) FILTER (WHERE type = 'provider') AS provider,
    jsonb_object_agg(attr_name, attr_value) FILTER (WHERE type = 'Metadata') AS metadata
  FROM
    resource_attribute
  WHERE
    provider_account_id = :provider_account_id
  GROUP BY resource_id
)
INSERT INTO aws_organizations_root (
  _id,
  uri,
  provider_account_id,
  id,
  arn,
  name,
  policytypes,
  servicecontrolpolicies,
  tagpolicies,
  _organization_id
)
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  attrs.provider ->> 'Id' AS id,
  attrs.provider ->> 'Arn' AS arn,
  attrs.provider ->> 'Name' AS name,
  attrs.provider -> 'PolicyTypes' AS policytypes,
  attrs.provider -> 'ServiceControlPolicies' AS servicecontrolpolicies,
  attrs.provider -> 'TagPolicies' AS tagpolicies,
  
    _organization_id.target_id AS _organization_id
FROM
  resource AS R
  LEFT JOIN attrs ON
    attrs.resource_id = R.id
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
        AND _aws_organizations_organization.provider_account_id = :provider_account_id
    WHERE
      _aws_organizations_organization_relation.relation = 'in'
      AND _aws_organizations_organization_relation.provider_account_id = :provider_account_id
  ) AS _organization_id ON _organization_id.resource_id = R.id
  WHERE
  R.provider_account_id = :provider_account_id
  AND R.provider_type = 'Root'
  AND R.service = 'organizations'
ON CONFLICT (_id) DO UPDATE
SET
    Id = EXCLUDED.Id,
    Arn = EXCLUDED.Arn,
    Name = EXCLUDED.Name,
    PolicyTypes = EXCLUDED.PolicyTypes,
    ServiceControlPolicies = EXCLUDED.ServiceControlPolicies,
    TagPolicies = EXCLUDED.TagPolicies,
    _organization_id = EXCLUDED._organization_id
  ;


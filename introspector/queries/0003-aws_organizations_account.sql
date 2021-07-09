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
INSERT INTO aws_organizations_account (
  _id,
  uri,
  provider_account_id,
  id,
  arn,
  email,
  name,
  status,
  joinedmethod,
  joinedtimestamp,
  servicecontrolpolicies,
  tagpolicies,
  tags,
  _tags,
  _root_id,_organizational_unit_id
)
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  attrs.provider ->> 'Id' AS id,
  attrs.provider ->> 'Arn' AS arn,
  attrs.provider ->> 'Email' AS email,
  attrs.provider ->> 'Name' AS name,
  attrs.provider ->> 'Status' AS status,
  attrs.provider ->> 'JoinedMethod' AS joinedmethod,
  (TO_TIMESTAMP(attrs.provider ->> 'JoinedTimestamp', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS joinedtimestamp,
  attrs.provider -> 'ServiceControlPolicies' AS servicecontrolpolicies,
  attrs.provider -> 'TagPolicies' AS tagpolicies,
  attrs.provider -> 'Tags' AS tags,
  attrs.metadata -> 'Tags' AS tags,
  
    _root_id.target_id AS _root_id,
    _organizational_unit_id.target_id AS _organizational_unit_id
FROM
  resource AS R
  LEFT JOIN attrs ON
    attrs.resource_id = R.id
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
        AND _aws_organizations_root.provider_account_id = :provider_account_id
    WHERE
      _aws_organizations_root_relation.relation = 'in'
      AND _aws_organizations_root_relation.provider_account_id = :provider_account_id
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
        AND _aws_organizations_organizationalunit.provider_account_id = :provider_account_id
    WHERE
      _aws_organizations_organizationalunit_relation.relation = 'in'
      AND _aws_organizations_organizationalunit_relation.provider_account_id = :provider_account_id
  ) AS _organizational_unit_id ON _organizational_unit_id.resource_id = R.id
  WHERE
  R.provider_account_id = :provider_account_id
  AND R.provider_type = 'Account'
  AND R.service = 'organizations'
ON CONFLICT (_id) DO UPDATE
SET
    Id = EXCLUDED.Id,
    Arn = EXCLUDED.Arn,
    Email = EXCLUDED.Email,
    Name = EXCLUDED.Name,
    Status = EXCLUDED.Status,
    JoinedMethod = EXCLUDED.JoinedMethod,
    JoinedTimestamp = EXCLUDED.JoinedTimestamp,
    ServiceControlPolicies = EXCLUDED.ServiceControlPolicies,
    TagPolicies = EXCLUDED.TagPolicies,
    Tags = EXCLUDED.Tags,
    _tags = EXCLUDED._tags,
    _root_id = EXCLUDED._root_id,
    _organizational_unit_id = EXCLUDED._organizational_unit_id
  ;


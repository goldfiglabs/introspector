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
  id.attr_value #>> '{}' AS id,
  arn.attr_value #>> '{}' AS arn,
  email.attr_value #>> '{}' AS email,
  name.attr_value #>> '{}' AS name,
  status.attr_value #>> '{}' AS status,
  joinedmethod.attr_value #>> '{}' AS joinedmethod,
  (TO_TIMESTAMP(joinedtimestamp.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS joinedtimestamp,
  servicecontrolpolicies.attr_value::jsonb AS servicecontrolpolicies,
  tagpolicies.attr_value::jsonb AS tagpolicies,
  tags.attr_value::jsonb AS tags,
  _tags.attr_value::jsonb AS _tags,

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
  LEFT JOIN resource_attribute AS email
    ON email.resource_id = R.id
    AND email.type = 'provider'
    AND lower(email.attr_name) = 'email'
  LEFT JOIN resource_attribute AS name
    ON name.resource_id = R.id
    AND name.type = 'provider'
    AND lower(name.attr_name) = 'name'
  LEFT JOIN resource_attribute AS status
    ON status.resource_id = R.id
    AND status.type = 'provider'
    AND lower(status.attr_name) = 'status'
  LEFT JOIN resource_attribute AS joinedmethod
    ON joinedmethod.resource_id = R.id
    AND joinedmethod.type = 'provider'
    AND lower(joinedmethod.attr_name) = 'joinedmethod'
  LEFT JOIN resource_attribute AS joinedtimestamp
    ON joinedtimestamp.resource_id = R.id
    AND joinedtimestamp.type = 'provider'
    AND lower(joinedtimestamp.attr_name) = 'joinedtimestamp'
  LEFT JOIN resource_attribute AS servicecontrolpolicies
    ON servicecontrolpolicies.resource_id = R.id
    AND servicecontrolpolicies.type = 'provider'
    AND lower(servicecontrolpolicies.attr_name) = 'servicecontrolpolicies'
  LEFT JOIN resource_attribute AS tagpolicies
    ON tagpolicies.resource_id = R.id
    AND tagpolicies.type = 'provider'
    AND lower(tagpolicies.attr_name) = 'tagpolicies'
  LEFT JOIN resource_attribute AS tags
    ON tags.resource_id = R.id
    AND tags.type = 'provider'
    AND lower(tags.attr_name) = 'tags'
  LEFT JOIN resource_attribute AS _tags
    ON _tags.resource_id = R.id
    AND _tags.type = 'Metadata'
    AND lower(_tags.attr_name) = 'tags'
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
  AND R.provider_type = 'Account'
  AND R.service = 'organizations'
ON CONFLICT (_id) DO UPDATE
SET
    id = EXCLUDED.id,
    arn = EXCLUDED.arn,
    email = EXCLUDED.email,
    name = EXCLUDED.name,
    status = EXCLUDED.status,
    joinedmethod = EXCLUDED.joinedmethod,
    joinedtimestamp = EXCLUDED.joinedtimestamp,
    servicecontrolpolicies = EXCLUDED.servicecontrolpolicies,
    tagpolicies = EXCLUDED.tagpolicies,
    tags = EXCLUDED.tags,
    _tags = EXCLUDED._tags,
    _root_id = EXCLUDED._root_id,
    _organizational_unit_id = EXCLUDED._organizational_unit_id
  ;

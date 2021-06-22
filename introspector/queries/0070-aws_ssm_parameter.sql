INSERT INTO aws_ssm_parameter (
  _id,
  uri,
  provider_account_id,
  name,
  type,
  keyid,
  lastmodifieddate,
  lastmodifieduser,
  description,
  allowedpattern,
  version,
  tier,
  policies,
  datatype,
  tags,
  _tags,
  _kms_key_id,_account_id
)
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  name.attr_value #>> '{}' AS name,
  type.attr_value #>> '{}' AS type,
  keyid.attr_value #>> '{}' AS keyid,
  (TO_TIMESTAMP(lastmodifieddate.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS lastmodifieddate,
  lastmodifieduser.attr_value #>> '{}' AS lastmodifieduser,
  description.attr_value #>> '{}' AS description,
  allowedpattern.attr_value #>> '{}' AS allowedpattern,
  (version.attr_value #>> '{}')::bigint AS version,
  tier.attr_value #>> '{}' AS tier,
  policies.attr_value::jsonb AS policies,
  datatype.attr_value #>> '{}' AS datatype,
  tags.attr_value::jsonb AS tags,
  _tags.attr_value::jsonb AS _tags,
  
    _kms_key_id.target_id AS _kms_key_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN resource_attribute AS name
    ON name.resource_id = R.id
    AND name.type = 'provider'
    AND lower(name.attr_name) = 'name'
    AND name.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS type
    ON type.resource_id = R.id
    AND type.type = 'provider'
    AND lower(type.attr_name) = 'type'
    AND type.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS keyid
    ON keyid.resource_id = R.id
    AND keyid.type = 'provider'
    AND lower(keyid.attr_name) = 'keyid'
    AND keyid.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS lastmodifieddate
    ON lastmodifieddate.resource_id = R.id
    AND lastmodifieddate.type = 'provider'
    AND lower(lastmodifieddate.attr_name) = 'lastmodifieddate'
    AND lastmodifieddate.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS lastmodifieduser
    ON lastmodifieduser.resource_id = R.id
    AND lastmodifieduser.type = 'provider'
    AND lower(lastmodifieduser.attr_name) = 'lastmodifieduser'
    AND lastmodifieduser.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS description
    ON description.resource_id = R.id
    AND description.type = 'provider'
    AND lower(description.attr_name) = 'description'
    AND description.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS allowedpattern
    ON allowedpattern.resource_id = R.id
    AND allowedpattern.type = 'provider'
    AND lower(allowedpattern.attr_name) = 'allowedpattern'
    AND allowedpattern.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS version
    ON version.resource_id = R.id
    AND version.type = 'provider'
    AND lower(version.attr_name) = 'version'
    AND version.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS tier
    ON tier.resource_id = R.id
    AND tier.type = 'provider'
    AND lower(tier.attr_name) = 'tier'
    AND tier.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS policies
    ON policies.resource_id = R.id
    AND policies.type = 'provider'
    AND lower(policies.attr_name) = 'policies'
    AND policies.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS datatype
    ON datatype.resource_id = R.id
    AND datatype.type = 'provider'
    AND lower(datatype.attr_name) = 'datatype'
    AND datatype.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS tags
    ON tags.resource_id = R.id
    AND tags.type = 'provider'
    AND lower(tags.attr_name) = 'tags'
    AND tags.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS _tags
    ON _tags.resource_id = R.id
    AND _tags.type = 'Metadata'
    AND lower(_tags.attr_name) = 'tags'
    AND _tags.provider_account_id = R.provider_account_id
  LEFT JOIN (
    SELECT
      _aws_kms_key_relation.resource_id AS resource_id,
      _aws_kms_key.id AS target_id
    FROM
      resource_relation AS _aws_kms_key_relation
      INNER JOIN resource AS _aws_kms_key
        ON _aws_kms_key_relation.target_id = _aws_kms_key.id
        AND _aws_kms_key.provider_type = 'Key'
        AND _aws_kms_key.service = 'kms'
        AND _aws_kms_key.provider_account_id = :provider_account_id
    WHERE
      _aws_kms_key_relation.relation = 'secured-by'
      AND _aws_kms_key_relation.provider_account_id = :provider_account_id
  ) AS _kms_key_id ON _kms_key_id.resource_id = R.id
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
  AND R.provider_type = 'Parameter'
  AND R.service = 'ssm'
ON CONFLICT (_id) DO UPDATE
SET
    name = EXCLUDED.name,
    type = EXCLUDED.type,
    keyid = EXCLUDED.keyid,
    lastmodifieddate = EXCLUDED.lastmodifieddate,
    lastmodifieduser = EXCLUDED.lastmodifieduser,
    description = EXCLUDED.description,
    allowedpattern = EXCLUDED.allowedpattern,
    version = EXCLUDED.version,
    tier = EXCLUDED.tier,
    policies = EXCLUDED.policies,
    datatype = EXCLUDED.datatype,
    tags = EXCLUDED.tags,
    _tags = EXCLUDED._tags,
    _kms_key_id = EXCLUDED._kms_key_id,
    _account_id = EXCLUDED._account_id
  ;


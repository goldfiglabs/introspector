INSERT INTO aws_secretsmanager_secret (
  _id,
  uri,
  provider_account_id,
  arn,
  name,
  description,
  kmskeyid,
  rotationenabled,
  rotationlambdaarn,
  rotationrules,
  lastrotateddate,
  lastchangeddate,
  lastaccesseddate,
  deleteddate,
  tags,
  secretversionstostages,
  owningservice,
  createddate,
  policy,
  _tags,
  _policy,
  _kms_key_id,_account_id
)
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  arn.attr_value #>> '{}' AS arn,
  name.attr_value #>> '{}' AS name,
  description.attr_value #>> '{}' AS description,
  kmskeyid.attr_value #>> '{}' AS kmskeyid,
  (rotationenabled.attr_value #>> '{}')::boolean AS rotationenabled,
  rotationlambdaarn.attr_value #>> '{}' AS rotationlambdaarn,
  rotationrules.attr_value::jsonb AS rotationrules,
  (TO_TIMESTAMP(lastrotateddate.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS lastrotateddate,
  (TO_TIMESTAMP(lastchangeddate.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS lastchangeddate,
  (TO_TIMESTAMP(lastaccesseddate.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS lastaccesseddate,
  (TO_TIMESTAMP(deleteddate.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS deleteddate,
  tags.attr_value::jsonb AS tags,
  secretversionstostages.attr_value::jsonb AS secretversionstostages,
  owningservice.attr_value #>> '{}' AS owningservice,
  (TO_TIMESTAMP(createddate.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS createddate,
  policy.attr_value::jsonb AS policy,
  _tags.attr_value::jsonb AS _tags,
  _policy.attr_value::jsonb AS _policy,
  
    _kms_key_id.target_id AS _kms_key_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN resource_attribute AS arn
    ON arn.resource_id = R.id
    AND arn.type = 'provider'
    AND lower(arn.attr_name) = 'arn'
  LEFT JOIN resource_attribute AS name
    ON name.resource_id = R.id
    AND name.type = 'provider'
    AND lower(name.attr_name) = 'name'
  LEFT JOIN resource_attribute AS description
    ON description.resource_id = R.id
    AND description.type = 'provider'
    AND lower(description.attr_name) = 'description'
  LEFT JOIN resource_attribute AS kmskeyid
    ON kmskeyid.resource_id = R.id
    AND kmskeyid.type = 'provider'
    AND lower(kmskeyid.attr_name) = 'kmskeyid'
  LEFT JOIN resource_attribute AS rotationenabled
    ON rotationenabled.resource_id = R.id
    AND rotationenabled.type = 'provider'
    AND lower(rotationenabled.attr_name) = 'rotationenabled'
  LEFT JOIN resource_attribute AS rotationlambdaarn
    ON rotationlambdaarn.resource_id = R.id
    AND rotationlambdaarn.type = 'provider'
    AND lower(rotationlambdaarn.attr_name) = 'rotationlambdaarn'
  LEFT JOIN resource_attribute AS rotationrules
    ON rotationrules.resource_id = R.id
    AND rotationrules.type = 'provider'
    AND lower(rotationrules.attr_name) = 'rotationrules'
  LEFT JOIN resource_attribute AS lastrotateddate
    ON lastrotateddate.resource_id = R.id
    AND lastrotateddate.type = 'provider'
    AND lower(lastrotateddate.attr_name) = 'lastrotateddate'
  LEFT JOIN resource_attribute AS lastchangeddate
    ON lastchangeddate.resource_id = R.id
    AND lastchangeddate.type = 'provider'
    AND lower(lastchangeddate.attr_name) = 'lastchangeddate'
  LEFT JOIN resource_attribute AS lastaccesseddate
    ON lastaccesseddate.resource_id = R.id
    AND lastaccesseddate.type = 'provider'
    AND lower(lastaccesseddate.attr_name) = 'lastaccesseddate'
  LEFT JOIN resource_attribute AS deleteddate
    ON deleteddate.resource_id = R.id
    AND deleteddate.type = 'provider'
    AND lower(deleteddate.attr_name) = 'deleteddate'
  LEFT JOIN resource_attribute AS tags
    ON tags.resource_id = R.id
    AND tags.type = 'provider'
    AND lower(tags.attr_name) = 'tags'
  LEFT JOIN resource_attribute AS secretversionstostages
    ON secretversionstostages.resource_id = R.id
    AND secretversionstostages.type = 'provider'
    AND lower(secretversionstostages.attr_name) = 'secretversionstostages'
  LEFT JOIN resource_attribute AS owningservice
    ON owningservice.resource_id = R.id
    AND owningservice.type = 'provider'
    AND lower(owningservice.attr_name) = 'owningservice'
  LEFT JOIN resource_attribute AS createddate
    ON createddate.resource_id = R.id
    AND createddate.type = 'provider'
    AND lower(createddate.attr_name) = 'createddate'
  LEFT JOIN resource_attribute AS policy
    ON policy.resource_id = R.id
    AND policy.type = 'provider'
    AND lower(policy.attr_name) = 'policy'
  LEFT JOIN resource_attribute AS _tags
    ON _tags.resource_id = R.id
    AND _tags.type = 'Metadata'
    AND lower(_tags.attr_name) = 'tags'
  LEFT JOIN resource_attribute AS _policy
    ON _policy.resource_id = R.id
    AND _policy.type = 'Metadata'
    AND lower(_policy.attr_name) = 'policy'
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
    WHERE
      _aws_kms_key_relation.relation = 'encrypted-by'
  ) AS _kms_key_id ON _kms_key_id.resource_id = R.id
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
  AND R.provider_type = 'Secret'
  AND R.service = 'secretsmanager'
ON CONFLICT (_id) DO UPDATE
SET
    arn = EXCLUDED.arn,
    name = EXCLUDED.name,
    description = EXCLUDED.description,
    kmskeyid = EXCLUDED.kmskeyid,
    rotationenabled = EXCLUDED.rotationenabled,
    rotationlambdaarn = EXCLUDED.rotationlambdaarn,
    rotationrules = EXCLUDED.rotationrules,
    lastrotateddate = EXCLUDED.lastrotateddate,
    lastchangeddate = EXCLUDED.lastchangeddate,
    lastaccesseddate = EXCLUDED.lastaccesseddate,
    deleteddate = EXCLUDED.deleteddate,
    tags = EXCLUDED.tags,
    secretversionstostages = EXCLUDED.secretversionstostages,
    owningservice = EXCLUDED.owningservice,
    createddate = EXCLUDED.createddate,
    policy = EXCLUDED.policy,
    _tags = EXCLUDED._tags,
    _policy = EXCLUDED._policy,
    _kms_key_id = EXCLUDED._kms_key_id,
    _account_id = EXCLUDED._account_id
  ;


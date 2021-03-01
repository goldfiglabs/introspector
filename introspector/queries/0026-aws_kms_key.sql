INSERT INTO aws_kms_key (
  _id,
  uri,
  provider_account_id,
  awsaccountid,
  keyid,
  arn,
  creationdate,
  enabled,
  description,
  keyusage,
  keystate,
  deletiondate,
  validto,
  origin,
  customkeystoreid,
  cloudhsmclusterid,
  expirationmodel,
  keymanager,
  customermasterkeyspec,
  encryptionalgorithms,
  signingalgorithms,
  tags,
  keyrotationenabled,
  policy,
  _tags,
  _policy,
  _account_id
)
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  awsaccountid.attr_value #>> '{}' AS awsaccountid,
  keyid.attr_value #>> '{}' AS keyid,
  arn.attr_value #>> '{}' AS arn,
  (TO_TIMESTAMP(creationdate.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS creationdate,
  (enabled.attr_value #>> '{}')::boolean AS enabled,
  description.attr_value #>> '{}' AS description,
  keyusage.attr_value #>> '{}' AS keyusage,
  keystate.attr_value #>> '{}' AS keystate,
  (TO_TIMESTAMP(deletiondate.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS deletiondate,
  (TO_TIMESTAMP(validto.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS validto,
  origin.attr_value #>> '{}' AS origin,
  customkeystoreid.attr_value #>> '{}' AS customkeystoreid,
  cloudhsmclusterid.attr_value #>> '{}' AS cloudhsmclusterid,
  expirationmodel.attr_value #>> '{}' AS expirationmodel,
  keymanager.attr_value #>> '{}' AS keymanager,
  customermasterkeyspec.attr_value #>> '{}' AS customermasterkeyspec,
  encryptionalgorithms.attr_value::jsonb AS encryptionalgorithms,
  signingalgorithms.attr_value::jsonb AS signingalgorithms,
  tags.attr_value::jsonb AS tags,
  (keyrotationenabled.attr_value #>> '{}')::boolean AS keyrotationenabled,
  policy.attr_value::jsonb AS policy,
  _tags.attr_value::jsonb AS _tags,
  _policy.attr_value::jsonb AS _policy,
  
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN resource_attribute AS awsaccountid
    ON awsaccountid.resource_id = R.id
    AND awsaccountid.type = 'provider'
    AND lower(awsaccountid.attr_name) = 'awsaccountid'
  LEFT JOIN resource_attribute AS keyid
    ON keyid.resource_id = R.id
    AND keyid.type = 'provider'
    AND lower(keyid.attr_name) = 'keyid'
  LEFT JOIN resource_attribute AS arn
    ON arn.resource_id = R.id
    AND arn.type = 'provider'
    AND lower(arn.attr_name) = 'arn'
  LEFT JOIN resource_attribute AS creationdate
    ON creationdate.resource_id = R.id
    AND creationdate.type = 'provider'
    AND lower(creationdate.attr_name) = 'creationdate'
  LEFT JOIN resource_attribute AS enabled
    ON enabled.resource_id = R.id
    AND enabled.type = 'provider'
    AND lower(enabled.attr_name) = 'enabled'
  LEFT JOIN resource_attribute AS description
    ON description.resource_id = R.id
    AND description.type = 'provider'
    AND lower(description.attr_name) = 'description'
  LEFT JOIN resource_attribute AS keyusage
    ON keyusage.resource_id = R.id
    AND keyusage.type = 'provider'
    AND lower(keyusage.attr_name) = 'keyusage'
  LEFT JOIN resource_attribute AS keystate
    ON keystate.resource_id = R.id
    AND keystate.type = 'provider'
    AND lower(keystate.attr_name) = 'keystate'
  LEFT JOIN resource_attribute AS deletiondate
    ON deletiondate.resource_id = R.id
    AND deletiondate.type = 'provider'
    AND lower(deletiondate.attr_name) = 'deletiondate'
  LEFT JOIN resource_attribute AS validto
    ON validto.resource_id = R.id
    AND validto.type = 'provider'
    AND lower(validto.attr_name) = 'validto'
  LEFT JOIN resource_attribute AS origin
    ON origin.resource_id = R.id
    AND origin.type = 'provider'
    AND lower(origin.attr_name) = 'origin'
  LEFT JOIN resource_attribute AS customkeystoreid
    ON customkeystoreid.resource_id = R.id
    AND customkeystoreid.type = 'provider'
    AND lower(customkeystoreid.attr_name) = 'customkeystoreid'
  LEFT JOIN resource_attribute AS cloudhsmclusterid
    ON cloudhsmclusterid.resource_id = R.id
    AND cloudhsmclusterid.type = 'provider'
    AND lower(cloudhsmclusterid.attr_name) = 'cloudhsmclusterid'
  LEFT JOIN resource_attribute AS expirationmodel
    ON expirationmodel.resource_id = R.id
    AND expirationmodel.type = 'provider'
    AND lower(expirationmodel.attr_name) = 'expirationmodel'
  LEFT JOIN resource_attribute AS keymanager
    ON keymanager.resource_id = R.id
    AND keymanager.type = 'provider'
    AND lower(keymanager.attr_name) = 'keymanager'
  LEFT JOIN resource_attribute AS customermasterkeyspec
    ON customermasterkeyspec.resource_id = R.id
    AND customermasterkeyspec.type = 'provider'
    AND lower(customermasterkeyspec.attr_name) = 'customermasterkeyspec'
  LEFT JOIN resource_attribute AS encryptionalgorithms
    ON encryptionalgorithms.resource_id = R.id
    AND encryptionalgorithms.type = 'provider'
    AND lower(encryptionalgorithms.attr_name) = 'encryptionalgorithms'
  LEFT JOIN resource_attribute AS signingalgorithms
    ON signingalgorithms.resource_id = R.id
    AND signingalgorithms.type = 'provider'
    AND lower(signingalgorithms.attr_name) = 'signingalgorithms'
  LEFT JOIN resource_attribute AS tags
    ON tags.resource_id = R.id
    AND tags.type = 'provider'
    AND lower(tags.attr_name) = 'tags'
  LEFT JOIN resource_attribute AS keyrotationenabled
    ON keyrotationenabled.resource_id = R.id
    AND keyrotationenabled.type = 'provider'
    AND lower(keyrotationenabled.attr_name) = 'keyrotationenabled'
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
      GROUP BY _aws_organizations_account_relation.resource_id
      HAVING COUNT(*) = 1
    ) AS unique_account_mapping
    INNER JOIN resource_relation AS _aws_organizations_account_relation
      ON _aws_organizations_account_relation.resource_id = unique_account_mapping.resource_id
    INNER JOIN resource AS _aws_organizations_account
      ON _aws_organizations_account_relation.target_id = _aws_organizations_account.id
      AND _aws_organizations_account.provider_type = 'Account'
      AND _aws_organizations_account.service = 'organizations'
    WHERE
        _aws_organizations_account_relation.relation = 'in'
  ) AS _account_id ON _account_id.resource_id = R.id
  WHERE
  PA.provider = 'aws'
  AND R.provider_type = 'Key'
  AND R.service = 'kms'
ON CONFLICT (_id) DO UPDATE
SET
    awsaccountid = EXCLUDED.awsaccountid,
    keyid = EXCLUDED.keyid,
    arn = EXCLUDED.arn,
    creationdate = EXCLUDED.creationdate,
    enabled = EXCLUDED.enabled,
    description = EXCLUDED.description,
    keyusage = EXCLUDED.keyusage,
    keystate = EXCLUDED.keystate,
    deletiondate = EXCLUDED.deletiondate,
    validto = EXCLUDED.validto,
    origin = EXCLUDED.origin,
    customkeystoreid = EXCLUDED.customkeystoreid,
    cloudhsmclusterid = EXCLUDED.cloudhsmclusterid,
    expirationmodel = EXCLUDED.expirationmodel,
    keymanager = EXCLUDED.keymanager,
    customermasterkeyspec = EXCLUDED.customermasterkeyspec,
    encryptionalgorithms = EXCLUDED.encryptionalgorithms,
    signingalgorithms = EXCLUDED.signingalgorithms,
    tags = EXCLUDED.tags,
    keyrotationenabled = EXCLUDED.keyrotationenabled,
    policy = EXCLUDED.policy,
    _tags = EXCLUDED._tags,
    _policy = EXCLUDED._policy,
    _account_id = EXCLUDED._account_id
  ;


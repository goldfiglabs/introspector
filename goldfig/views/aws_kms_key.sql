DROP MATERIALIZED VIEW IF EXISTS aws_kms_key CASCADE;

CREATE MATERIALIZED VIEW aws_kms_key AS
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
  
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN attrs AS awsaccountid
    ON awsaccountid.id = R.id
    AND awsaccountid.attr_name = 'awsaccountid'
  LEFT JOIN attrs AS keyid
    ON keyid.id = R.id
    AND keyid.attr_name = 'keyid'
  LEFT JOIN attrs AS arn
    ON arn.id = R.id
    AND arn.attr_name = 'arn'
  LEFT JOIN attrs AS creationdate
    ON creationdate.id = R.id
    AND creationdate.attr_name = 'creationdate'
  LEFT JOIN attrs AS enabled
    ON enabled.id = R.id
    AND enabled.attr_name = 'enabled'
  LEFT JOIN attrs AS description
    ON description.id = R.id
    AND description.attr_name = 'description'
  LEFT JOIN attrs AS keyusage
    ON keyusage.id = R.id
    AND keyusage.attr_name = 'keyusage'
  LEFT JOIN attrs AS keystate
    ON keystate.id = R.id
    AND keystate.attr_name = 'keystate'
  LEFT JOIN attrs AS deletiondate
    ON deletiondate.id = R.id
    AND deletiondate.attr_name = 'deletiondate'
  LEFT JOIN attrs AS validto
    ON validto.id = R.id
    AND validto.attr_name = 'validto'
  LEFT JOIN attrs AS origin
    ON origin.id = R.id
    AND origin.attr_name = 'origin'
  LEFT JOIN attrs AS customkeystoreid
    ON customkeystoreid.id = R.id
    AND customkeystoreid.attr_name = 'customkeystoreid'
  LEFT JOIN attrs AS cloudhsmclusterid
    ON cloudhsmclusterid.id = R.id
    AND cloudhsmclusterid.attr_name = 'cloudhsmclusterid'
  LEFT JOIN attrs AS expirationmodel
    ON expirationmodel.id = R.id
    AND expirationmodel.attr_name = 'expirationmodel'
  LEFT JOIN attrs AS keymanager
    ON keymanager.id = R.id
    AND keymanager.attr_name = 'keymanager'
  LEFT JOIN attrs AS customermasterkeyspec
    ON customermasterkeyspec.id = R.id
    AND customermasterkeyspec.attr_name = 'customermasterkeyspec'
  LEFT JOIN attrs AS encryptionalgorithms
    ON encryptionalgorithms.id = R.id
    AND encryptionalgorithms.attr_name = 'encryptionalgorithms'
  LEFT JOIN attrs AS signingalgorithms
    ON signingalgorithms.id = R.id
    AND signingalgorithms.attr_name = 'signingalgorithms'
  LEFT JOIN attrs AS tags
    ON tags.id = R.id
    AND tags.attr_name = 'tags'
  LEFT JOIN attrs AS keyrotationenabled
    ON keyrotationenabled.id = R.id
    AND keyrotationenabled.attr_name = 'keyrotationenabled'
  LEFT JOIN attrs AS policy
    ON policy.id = R.id
    AND policy.attr_name = 'policy'
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
  AND LOWER(R.provider_type) = 'key'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_kms_key;

COMMENT ON MATERIALIZED VIEW aws_kms_key IS 'kms key resources and their associated attributes.';


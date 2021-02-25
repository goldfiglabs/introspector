INSERT INTO aws_acmpca_certificateauthority (
  _id,
  uri,
  provider_account_id,
  arn,
  owneraccount,
  createdat,
  laststatechangeat,
  type,
  serial,
  status,
  notbefore,
  notafter,
  failurereason,
  certificateauthorityconfiguration,
  revocationconfiguration,
  restorableuntil,
  policy,
  tags,
  _tags,
  _policy,
  _account_id
)
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  arn.attr_value #>> '{}' AS arn,
  owneraccount.attr_value #>> '{}' AS owneraccount,
  (TO_TIMESTAMP(createdat.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS createdat,
  (TO_TIMESTAMP(laststatechangeat.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS laststatechangeat,
  type.attr_value #>> '{}' AS type,
  serial.attr_value #>> '{}' AS serial,
  status.attr_value #>> '{}' AS status,
  (TO_TIMESTAMP(notbefore.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS notbefore,
  (TO_TIMESTAMP(notafter.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS notafter,
  failurereason.attr_value #>> '{}' AS failurereason,
  certificateauthorityconfiguration.attr_value::jsonb AS certificateauthorityconfiguration,
  revocationconfiguration.attr_value::jsonb AS revocationconfiguration,
  (TO_TIMESTAMP(restorableuntil.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS restorableuntil,
  policy.attr_value::jsonb AS policy,
  tags.attr_value::jsonb AS tags,
  _tags.attr_value::jsonb AS _tags,
  _policy.attr_value::jsonb AS _policy,
  
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN resource_attribute AS arn
    ON arn.resource_id = R.id
    AND arn.type = 'provider'
    AND lower(arn.attr_name) = 'arn'
  LEFT JOIN resource_attribute AS owneraccount
    ON owneraccount.resource_id = R.id
    AND owneraccount.type = 'provider'
    AND lower(owneraccount.attr_name) = 'owneraccount'
  LEFT JOIN resource_attribute AS createdat
    ON createdat.resource_id = R.id
    AND createdat.type = 'provider'
    AND lower(createdat.attr_name) = 'createdat'
  LEFT JOIN resource_attribute AS laststatechangeat
    ON laststatechangeat.resource_id = R.id
    AND laststatechangeat.type = 'provider'
    AND lower(laststatechangeat.attr_name) = 'laststatechangeat'
  LEFT JOIN resource_attribute AS type
    ON type.resource_id = R.id
    AND type.type = 'provider'
    AND lower(type.attr_name) = 'type'
  LEFT JOIN resource_attribute AS serial
    ON serial.resource_id = R.id
    AND serial.type = 'provider'
    AND lower(serial.attr_name) = 'serial'
  LEFT JOIN resource_attribute AS status
    ON status.resource_id = R.id
    AND status.type = 'provider'
    AND lower(status.attr_name) = 'status'
  LEFT JOIN resource_attribute AS notbefore
    ON notbefore.resource_id = R.id
    AND notbefore.type = 'provider'
    AND lower(notbefore.attr_name) = 'notbefore'
  LEFT JOIN resource_attribute AS notafter
    ON notafter.resource_id = R.id
    AND notafter.type = 'provider'
    AND lower(notafter.attr_name) = 'notafter'
  LEFT JOIN resource_attribute AS failurereason
    ON failurereason.resource_id = R.id
    AND failurereason.type = 'provider'
    AND lower(failurereason.attr_name) = 'failurereason'
  LEFT JOIN resource_attribute AS certificateauthorityconfiguration
    ON certificateauthorityconfiguration.resource_id = R.id
    AND certificateauthorityconfiguration.type = 'provider'
    AND lower(certificateauthorityconfiguration.attr_name) = 'certificateauthorityconfiguration'
  LEFT JOIN resource_attribute AS revocationconfiguration
    ON revocationconfiguration.resource_id = R.id
    AND revocationconfiguration.type = 'provider'
    AND lower(revocationconfiguration.attr_name) = 'revocationconfiguration'
  LEFT JOIN resource_attribute AS restorableuntil
    ON restorableuntil.resource_id = R.id
    AND restorableuntil.type = 'provider'
    AND lower(restorableuntil.attr_name) = 'restorableuntil'
  LEFT JOIN resource_attribute AS policy
    ON policy.resource_id = R.id
    AND policy.type = 'provider'
    AND lower(policy.attr_name) = 'policy'
  LEFT JOIN resource_attribute AS tags
    ON tags.resource_id = R.id
    AND tags.type = 'provider'
    AND lower(tags.attr_name) = 'tags'
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
  AND R.provider_type = 'CertificateAuthority'
  AND R.service = 'acm-pca'
ON CONFLICT (_id) DO UPDATE
SET
    arn = EXCLUDED.arn,
    owneraccount = EXCLUDED.owneraccount,
    createdat = EXCLUDED.createdat,
    laststatechangeat = EXCLUDED.laststatechangeat,
    type = EXCLUDED.type,
    serial = EXCLUDED.serial,
    status = EXCLUDED.status,
    notbefore = EXCLUDED.notbefore,
    notafter = EXCLUDED.notafter,
    failurereason = EXCLUDED.failurereason,
    certificateauthorityconfiguration = EXCLUDED.certificateauthorityconfiguration,
    revocationconfiguration = EXCLUDED.revocationconfiguration,
    restorableuntil = EXCLUDED.restorableuntil,
    policy = EXCLUDED.policy,
    tags = EXCLUDED.tags,
    _tags = EXCLUDED._tags,
    _policy = EXCLUDED._policy,
    _account_id = EXCLUDED._account_id
  ;


INSERT INTO aws_ec2_keypair
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  keypairid.attr_value #>> '{}' AS keypairid,
  keyfingerprint.attr_value #>> '{}' AS keyfingerprint,
  keyname.attr_value #>> '{}' AS keyname,
  tags.attr_value::jsonb AS tags,
  
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN resource_attribute AS keypairid
    ON keypairid.resource_id = R.id
    AND keypairid.type = 'provider'
    AND lower(keypairid.attr_name) = 'keypairid'
  LEFT JOIN resource_attribute AS keyfingerprint
    ON keyfingerprint.resource_id = R.id
    AND keyfingerprint.type = 'provider'
    AND lower(keyfingerprint.attr_name) = 'keyfingerprint'
  LEFT JOIN resource_attribute AS keyname
    ON keyname.resource_id = R.id
    AND keyname.type = 'provider'
    AND lower(keyname.attr_name) = 'keyname'
  LEFT JOIN resource_attribute AS tags
    ON tags.resource_id = R.id
    AND tags.type = 'provider'
    AND lower(tags.attr_name) = 'tags'
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
  AND R.provider_type = 'KeyPair'
  AND R.service = 'ec2'
ON CONFLICT (_id) DO UPDATE
SET
    keypairid = EXCLUDED.keypairid,
    keyfingerprint = EXCLUDED.keyfingerprint,
    keyname = EXCLUDED.keyname,
    tags = EXCLUDED.tags,
    _account_id = EXCLUDED._account_id
  ;


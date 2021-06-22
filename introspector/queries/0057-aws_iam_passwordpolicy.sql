INSERT INTO aws_iam_passwordpolicy (
  _id,
  uri,
  provider_account_id,
  minimumpasswordlength,
  requiresymbols,
  requirenumbers,
  requireuppercasecharacters,
  requirelowercasecharacters,
  allowuserstochangepassword,
  expirepasswords,
  maxpasswordage,
  passwordreuseprevention,
  hardexpiry,
  _account_id
)
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  (minimumpasswordlength.attr_value #>> '{}')::integer AS minimumpasswordlength,
  (requiresymbols.attr_value #>> '{}')::boolean AS requiresymbols,
  (requirenumbers.attr_value #>> '{}')::boolean AS requirenumbers,
  (requireuppercasecharacters.attr_value #>> '{}')::boolean AS requireuppercasecharacters,
  (requirelowercasecharacters.attr_value #>> '{}')::boolean AS requirelowercasecharacters,
  (allowuserstochangepassword.attr_value #>> '{}')::boolean AS allowuserstochangepassword,
  (expirepasswords.attr_value #>> '{}')::boolean AS expirepasswords,
  (maxpasswordage.attr_value #>> '{}')::integer AS maxpasswordage,
  (passwordreuseprevention.attr_value #>> '{}')::integer AS passwordreuseprevention,
  (hardexpiry.attr_value #>> '{}')::boolean AS hardexpiry,
  
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN resource_attribute AS minimumpasswordlength
    ON minimumpasswordlength.resource_id = R.id
    AND minimumpasswordlength.type = 'provider'
    AND lower(minimumpasswordlength.attr_name) = 'minimumpasswordlength'
    AND minimumpasswordlength.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS requiresymbols
    ON requiresymbols.resource_id = R.id
    AND requiresymbols.type = 'provider'
    AND lower(requiresymbols.attr_name) = 'requiresymbols'
    AND requiresymbols.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS requirenumbers
    ON requirenumbers.resource_id = R.id
    AND requirenumbers.type = 'provider'
    AND lower(requirenumbers.attr_name) = 'requirenumbers'
    AND requirenumbers.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS requireuppercasecharacters
    ON requireuppercasecharacters.resource_id = R.id
    AND requireuppercasecharacters.type = 'provider'
    AND lower(requireuppercasecharacters.attr_name) = 'requireuppercasecharacters'
    AND requireuppercasecharacters.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS requirelowercasecharacters
    ON requirelowercasecharacters.resource_id = R.id
    AND requirelowercasecharacters.type = 'provider'
    AND lower(requirelowercasecharacters.attr_name) = 'requirelowercasecharacters'
    AND requirelowercasecharacters.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS allowuserstochangepassword
    ON allowuserstochangepassword.resource_id = R.id
    AND allowuserstochangepassword.type = 'provider'
    AND lower(allowuserstochangepassword.attr_name) = 'allowuserstochangepassword'
    AND allowuserstochangepassword.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS expirepasswords
    ON expirepasswords.resource_id = R.id
    AND expirepasswords.type = 'provider'
    AND lower(expirepasswords.attr_name) = 'expirepasswords'
    AND expirepasswords.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS maxpasswordage
    ON maxpasswordage.resource_id = R.id
    AND maxpasswordage.type = 'provider'
    AND lower(maxpasswordage.attr_name) = 'maxpasswordage'
    AND maxpasswordage.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS passwordreuseprevention
    ON passwordreuseprevention.resource_id = R.id
    AND passwordreuseprevention.type = 'provider'
    AND lower(passwordreuseprevention.attr_name) = 'passwordreuseprevention'
    AND passwordreuseprevention.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS hardexpiry
    ON hardexpiry.resource_id = R.id
    AND hardexpiry.type = 'provider'
    AND lower(hardexpiry.attr_name) = 'hardexpiry'
    AND hardexpiry.provider_account_id = R.provider_account_id
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
  AND R.provider_type = 'PasswordPolicy'
  AND R.service = 'iam'
ON CONFLICT (_id) DO UPDATE
SET
    minimumpasswordlength = EXCLUDED.minimumpasswordlength,
    requiresymbols = EXCLUDED.requiresymbols,
    requirenumbers = EXCLUDED.requirenumbers,
    requireuppercasecharacters = EXCLUDED.requireuppercasecharacters,
    requirelowercasecharacters = EXCLUDED.requirelowercasecharacters,
    allowuserstochangepassword = EXCLUDED.allowuserstochangepassword,
    expirepasswords = EXCLUDED.expirepasswords,
    maxpasswordage = EXCLUDED.maxpasswordage,
    passwordreuseprevention = EXCLUDED.passwordreuseprevention,
    hardexpiry = EXCLUDED.hardexpiry,
    _account_id = EXCLUDED._account_id
  ;


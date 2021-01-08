INSERT INTO aws_iam_passwordpolicy
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
  LEFT JOIN resource_attribute AS requiresymbols
    ON requiresymbols.resource_id = R.id
    AND requiresymbols.type = 'provider'
    AND lower(requiresymbols.attr_name) = 'requiresymbols'
  LEFT JOIN resource_attribute AS requirenumbers
    ON requirenumbers.resource_id = R.id
    AND requirenumbers.type = 'provider'
    AND lower(requirenumbers.attr_name) = 'requirenumbers'
  LEFT JOIN resource_attribute AS requireuppercasecharacters
    ON requireuppercasecharacters.resource_id = R.id
    AND requireuppercasecharacters.type = 'provider'
    AND lower(requireuppercasecharacters.attr_name) = 'requireuppercasecharacters'
  LEFT JOIN resource_attribute AS requirelowercasecharacters
    ON requirelowercasecharacters.resource_id = R.id
    AND requirelowercasecharacters.type = 'provider'
    AND lower(requirelowercasecharacters.attr_name) = 'requirelowercasecharacters'
  LEFT JOIN resource_attribute AS allowuserstochangepassword
    ON allowuserstochangepassword.resource_id = R.id
    AND allowuserstochangepassword.type = 'provider'
    AND lower(allowuserstochangepassword.attr_name) = 'allowuserstochangepassword'
  LEFT JOIN resource_attribute AS expirepasswords
    ON expirepasswords.resource_id = R.id
    AND expirepasswords.type = 'provider'
    AND lower(expirepasswords.attr_name) = 'expirepasswords'
  LEFT JOIN resource_attribute AS maxpasswordage
    ON maxpasswordage.resource_id = R.id
    AND maxpasswordage.type = 'provider'
    AND lower(maxpasswordage.attr_name) = 'maxpasswordage'
  LEFT JOIN resource_attribute AS passwordreuseprevention
    ON passwordreuseprevention.resource_id = R.id
    AND passwordreuseprevention.type = 'provider'
    AND lower(passwordreuseprevention.attr_name) = 'passwordreuseprevention'
  LEFT JOIN resource_attribute AS hardexpiry
    ON hardexpiry.resource_id = R.id
    AND hardexpiry.type = 'provider'
    AND lower(hardexpiry.attr_name) = 'hardexpiry'
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


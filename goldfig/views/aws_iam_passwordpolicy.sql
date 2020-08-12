DROP MATERIALIZED VIEW IF EXISTS aws_iam_passwordpolicy CASCADE;

CREATE MATERIALIZED VIEW aws_iam_passwordpolicy AS
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
  minimumpasswordlength.attr_value::integer AS minimumpasswordlength,
  requiresymbols.attr_value::boolean AS requiresymbols,
  requirenumbers.attr_value::boolean AS requirenumbers,
  requireuppercasecharacters.attr_value::boolean AS requireuppercasecharacters,
  requirelowercasecharacters.attr_value::boolean AS requirelowercasecharacters,
  allowuserstochangepassword.attr_value::boolean AS allowuserstochangepassword,
  expirepasswords.attr_value::boolean AS expirepasswords,
  maxpasswordage.attr_value::integer AS maxpasswordage,
  passwordreuseprevention.attr_value::integer AS passwordreuseprevention,
  hardexpiry.attr_value::boolean AS hardexpiry,
  
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN attrs AS minimumpasswordlength
    ON minimumpasswordlength.id = R.id
    AND minimumpasswordlength.attr_name = 'minimumpasswordlength'
  LEFT JOIN attrs AS requiresymbols
    ON requiresymbols.id = R.id
    AND requiresymbols.attr_name = 'requiresymbols'
  LEFT JOIN attrs AS requirenumbers
    ON requirenumbers.id = R.id
    AND requirenumbers.attr_name = 'requirenumbers'
  LEFT JOIN attrs AS requireuppercasecharacters
    ON requireuppercasecharacters.id = R.id
    AND requireuppercasecharacters.attr_name = 'requireuppercasecharacters'
  LEFT JOIN attrs AS requirelowercasecharacters
    ON requirelowercasecharacters.id = R.id
    AND requirelowercasecharacters.attr_name = 'requirelowercasecharacters'
  LEFT JOIN attrs AS allowuserstochangepassword
    ON allowuserstochangepassword.id = R.id
    AND allowuserstochangepassword.attr_name = 'allowuserstochangepassword'
  LEFT JOIN attrs AS expirepasswords
    ON expirepasswords.id = R.id
    AND expirepasswords.attr_name = 'expirepasswords'
  LEFT JOIN attrs AS maxpasswordage
    ON maxpasswordage.id = R.id
    AND maxpasswordage.attr_name = 'maxpasswordage'
  LEFT JOIN attrs AS passwordreuseprevention
    ON passwordreuseprevention.id = R.id
    AND passwordreuseprevention.attr_name = 'passwordreuseprevention'
  LEFT JOIN attrs AS hardexpiry
    ON hardexpiry.id = R.id
    AND hardexpiry.attr_name = 'hardexpiry'
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
  AND LOWER(R.provider_type) = 'passwordpolicy'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_iam_passwordpolicy;

COMMENT ON MATERIALIZED VIEW aws_iam_passwordpolicy IS 'iam passwordpolicy resources and their associated attributes.';


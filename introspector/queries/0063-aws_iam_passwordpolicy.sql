WITH attrs AS (
  SELECT
    resource_id,
    jsonb_object_agg(attr_name, attr_value) FILTER (WHERE type = 'provider') AS provider,
    jsonb_object_agg(attr_name, attr_value) FILTER (WHERE type = 'Metadata') AS metadata
  FROM
    resource_attribute
  WHERE
    provider_account_id = :provider_account_id
  GROUP BY resource_id
)
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
  (attrs.provider ->> 'MinimumPasswordLength')::integer AS minimumpasswordlength,
  (attrs.provider ->> 'RequireSymbols')::boolean AS requiresymbols,
  (attrs.provider ->> 'RequireNumbers')::boolean AS requirenumbers,
  (attrs.provider ->> 'RequireUppercaseCharacters')::boolean AS requireuppercasecharacters,
  (attrs.provider ->> 'RequireLowercaseCharacters')::boolean AS requirelowercasecharacters,
  (attrs.provider ->> 'AllowUsersToChangePassword')::boolean AS allowuserstochangepassword,
  (attrs.provider ->> 'ExpirePasswords')::boolean AS expirepasswords,
  (attrs.provider ->> 'MaxPasswordAge')::integer AS maxpasswordage,
  (attrs.provider ->> 'PasswordReusePrevention')::integer AS passwordreuseprevention,
  (attrs.provider ->> 'HardExpiry')::boolean AS hardexpiry,
  
    _account_id.target_id AS _account_id
FROM
  resource AS R
  LEFT JOIN attrs ON
    attrs.resource_id = R.id
  LEFT JOIN (
    SELECT
      unique_account_mapping.resource_id,
      unique_account_mapping.target_ids[1] as target_id
    FROM
      (
        SELECT
          ARRAY_AGG(_aws_organizations_account_relation.target_id) AS target_ids,
          _aws_organizations_account_relation.resource_id
        FROM
          resource AS _aws_organizations_account
          INNER JOIN resource_relation AS _aws_organizations_account_relation
            ON _aws_organizations_account_relation.target_id = _aws_organizations_account.id
        WHERE
          _aws_organizations_account.provider_type = 'Account'
          AND _aws_organizations_account.service = 'organizations'
          AND _aws_organizations_account.provider_account_id = :provider_account_id
          AND _aws_organizations_account_relation.relation = 'in'
          AND _aws_organizations_account_relation.provider_account_id = 8
        GROUP BY _aws_organizations_account_relation.resource_id
        HAVING COUNT(*) = 1
      ) AS unique_account_mapping
  ) AS _account_id ON _account_id.resource_id = R.id
  WHERE
  R.provider_account_id = :provider_account_id
  AND R.provider_type = 'PasswordPolicy'
  AND R.service = 'iam'
ON CONFLICT (_id) DO UPDATE
SET
    MinimumPasswordLength = EXCLUDED.MinimumPasswordLength,
    RequireSymbols = EXCLUDED.RequireSymbols,
    RequireNumbers = EXCLUDED.RequireNumbers,
    RequireUppercaseCharacters = EXCLUDED.RequireUppercaseCharacters,
    RequireLowercaseCharacters = EXCLUDED.RequireLowercaseCharacters,
    AllowUsersToChangePassword = EXCLUDED.AllowUsersToChangePassword,
    ExpirePasswords = EXCLUDED.ExpirePasswords,
    MaxPasswordAge = EXCLUDED.MaxPasswordAge,
    PasswordReusePrevention = EXCLUDED.PasswordReusePrevention,
    HardExpiry = EXCLUDED.HardExpiry,
    _account_id = EXCLUDED._account_id
  ;


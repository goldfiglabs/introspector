INSERT INTO aws_ec2_defaults
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  (EbsEncryptionByDefault.attr_value #>> '{}')::boolean AS ebsencryptionbydefault,
  EbsDefaultKmsKeyId.attr_value #>> '{}' AS ebsdefaultkmskeyid,
  
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN resource_attribute AS EbsEncryptionByDefault
    ON EbsEncryptionByDefault.resource_id = R.id
    AND EbsEncryptionByDefault.type = 'provider'
    AND lower(EbsEncryptionByDefault.attr_name) = 'ebsencryptionbydefault'
  LEFT JOIN resource_attribute AS EbsDefaultKmsKeyId
    ON EbsDefaultKmsKeyId.resource_id = R.id
    AND EbsDefaultKmsKeyId.type = 'provider'
    AND lower(EbsDefaultKmsKeyId.attr_name) = 'ebsdefaultkmskeyid'
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
  AND R.provider_type = 'Defaults'
  AND R.service = 'ec2'
ON CONFLICT (_id) DO UPDATE
SET
    EbsEncryptionByDefault = EXCLUDED.EbsEncryptionByDefault,
    EbsDefaultKmsKeyId = EXCLUDED.EbsDefaultKmsKeyId,
    _account_id = EXCLUDED._account_id
  ;


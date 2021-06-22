INSERT INTO aws_ec2_defaults (
  _id,
  uri,
  provider_account_id,
  ebsencryptionbydefault,
  ebsdefaultkmskeyid,
  _account_id
)
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
    AND EbsEncryptionByDefault.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS EbsDefaultKmsKeyId
    ON EbsDefaultKmsKeyId.resource_id = R.id
    AND EbsDefaultKmsKeyId.type = 'provider'
    AND lower(EbsDefaultKmsKeyId.attr_name) = 'ebsdefaultkmskeyid'
    AND EbsDefaultKmsKeyId.provider_account_id = R.provider_account_id
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
  AND R.provider_type = 'Defaults'
  AND R.service = 'ec2'
ON CONFLICT (_id) DO UPDATE
SET
    EbsEncryptionByDefault = EXCLUDED.EbsEncryptionByDefault,
    EbsDefaultKmsKeyId = EXCLUDED.EbsDefaultKmsKeyId,
    _account_id = EXCLUDED._account_id
  ;


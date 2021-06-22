INSERT INTO aws_iam_signingcertificate (
  _id,
  uri,
  provider_account_id,
  username,
  certificateid,
  certificatebody,
  status,
  uploaddate,
  _user_id,_account_id
)
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  username.attr_value #>> '{}' AS username,
  certificateid.attr_value #>> '{}' AS certificateid,
  certificatebody.attr_value #>> '{}' AS certificatebody,
  status.attr_value #>> '{}' AS status,
  (TO_TIMESTAMP(uploaddate.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS uploaddate,
  
    _user_id.target_id AS _user_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN resource_attribute AS username
    ON username.resource_id = R.id
    AND username.type = 'provider'
    AND lower(username.attr_name) = 'username'
    AND username.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS certificateid
    ON certificateid.resource_id = R.id
    AND certificateid.type = 'provider'
    AND lower(certificateid.attr_name) = 'certificateid'
    AND certificateid.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS certificatebody
    ON certificatebody.resource_id = R.id
    AND certificatebody.type = 'provider'
    AND lower(certificatebody.attr_name) = 'certificatebody'
    AND certificatebody.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS status
    ON status.resource_id = R.id
    AND status.type = 'provider'
    AND lower(status.attr_name) = 'status'
    AND status.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS uploaddate
    ON uploaddate.resource_id = R.id
    AND uploaddate.type = 'provider'
    AND lower(uploaddate.attr_name) = 'uploaddate'
    AND uploaddate.provider_account_id = R.provider_account_id
  LEFT JOIN (
    SELECT
      _aws_iam_user_relation.resource_id AS resource_id,
      _aws_iam_user.id AS target_id
    FROM
      resource_relation AS _aws_iam_user_relation
      INNER JOIN resource AS _aws_iam_user
        ON _aws_iam_user_relation.target_id = _aws_iam_user.id
        AND _aws_iam_user.provider_type = 'User'
        AND _aws_iam_user.service = 'iam'
        AND _aws_iam_user.provider_account_id = :provider_account_id
    WHERE
      _aws_iam_user_relation.relation = 'owns'
      AND _aws_iam_user_relation.provider_account_id = :provider_account_id
  ) AS _user_id ON _user_id.resource_id = R.id
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
  AND R.provider_type = 'SigningCertificate'
  AND R.service = 'iam'
ON CONFLICT (_id) DO UPDATE
SET
    username = EXCLUDED.username,
    certificateid = EXCLUDED.certificateid,
    certificatebody = EXCLUDED.certificatebody,
    status = EXCLUDED.status,
    uploaddate = EXCLUDED.uploaddate,
    _user_id = EXCLUDED._user_id,
    _account_id = EXCLUDED._account_id
  ;


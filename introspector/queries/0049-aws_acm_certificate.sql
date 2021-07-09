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
INSERT INTO aws_acm_certificate (
  _id,
  uri,
  provider_account_id,
  certificatearn,
  domainname,
  subjectalternativenames,
  domainvalidationoptions,
  serial,
  subject,
  issuer,
  createdat,
  issuedat,
  importedat,
  status,
  revokedat,
  revocationreason,
  notbefore,
  notafter,
  keyalgorithm,
  signaturealgorithm,
  inuseby,
  failurereason,
  type,
  renewalsummary,
  keyusages,
  extendedkeyusages,
  certificateauthorityarn,
  renewaleligibility,
  certificatetransparencyloggingpreference,
  tags,
  _tags,
  _account_id
)
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  attrs.provider ->> 'CertificateArn' AS certificatearn,
  attrs.provider ->> 'DomainName' AS domainname,
  attrs.provider -> 'SubjectAlternativeNames' AS subjectalternativenames,
  attrs.provider -> 'DomainValidationOptions' AS domainvalidationoptions,
  attrs.provider ->> 'Serial' AS serial,
  attrs.provider ->> 'Subject' AS subject,
  attrs.provider ->> 'Issuer' AS issuer,
  (TO_TIMESTAMP(attrs.provider ->> 'CreatedAt', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS createdat,
  (TO_TIMESTAMP(attrs.provider ->> 'IssuedAt', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS issuedat,
  (TO_TIMESTAMP(attrs.provider ->> 'ImportedAt', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS importedat,
  attrs.provider ->> 'Status' AS status,
  (TO_TIMESTAMP(attrs.provider ->> 'RevokedAt', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS revokedat,
  attrs.provider ->> 'RevocationReason' AS revocationreason,
  (TO_TIMESTAMP(attrs.provider ->> 'NotBefore', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS notbefore,
  (TO_TIMESTAMP(attrs.provider ->> 'NotAfter', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS notafter,
  attrs.provider ->> 'KeyAlgorithm' AS keyalgorithm,
  attrs.provider ->> 'SignatureAlgorithm' AS signaturealgorithm,
  attrs.provider -> 'InUseBy' AS inuseby,
  attrs.provider ->> 'FailureReason' AS failurereason,
  attrs.provider ->> 'Type' AS type,
  attrs.provider -> 'RenewalSummary' AS renewalsummary,
  attrs.provider -> 'KeyUsages' AS keyusages,
  attrs.provider -> 'ExtendedKeyUsages' AS extendedkeyusages,
  attrs.provider ->> 'CertificateAuthorityArn' AS certificateauthorityarn,
  attrs.provider ->> 'RenewalEligibility' AS renewaleligibility,
  attrs.provider ->> 'CertificateTransparencyLoggingPreference' AS certificatetransparencyloggingpreference,
  attrs.provider -> 'Tags' AS tags,
  attrs.metadata -> 'Tags' AS tags,
  
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
  AND R.provider_type = 'Certificate'
  AND R.service = 'acm'
ON CONFLICT (_id) DO UPDATE
SET
    CertificateArn = EXCLUDED.CertificateArn,
    DomainName = EXCLUDED.DomainName,
    SubjectAlternativeNames = EXCLUDED.SubjectAlternativeNames,
    DomainValidationOptions = EXCLUDED.DomainValidationOptions,
    Serial = EXCLUDED.Serial,
    Subject = EXCLUDED.Subject,
    Issuer = EXCLUDED.Issuer,
    CreatedAt = EXCLUDED.CreatedAt,
    IssuedAt = EXCLUDED.IssuedAt,
    ImportedAt = EXCLUDED.ImportedAt,
    Status = EXCLUDED.Status,
    RevokedAt = EXCLUDED.RevokedAt,
    RevocationReason = EXCLUDED.RevocationReason,
    NotBefore = EXCLUDED.NotBefore,
    NotAfter = EXCLUDED.NotAfter,
    KeyAlgorithm = EXCLUDED.KeyAlgorithm,
    SignatureAlgorithm = EXCLUDED.SignatureAlgorithm,
    InUseBy = EXCLUDED.InUseBy,
    FailureReason = EXCLUDED.FailureReason,
    Type = EXCLUDED.Type,
    RenewalSummary = EXCLUDED.RenewalSummary,
    KeyUsages = EXCLUDED.KeyUsages,
    ExtendedKeyUsages = EXCLUDED.ExtendedKeyUsages,
    CertificateAuthorityArn = EXCLUDED.CertificateAuthorityArn,
    RenewalEligibility = EXCLUDED.RenewalEligibility,
    CertificateTransparencyLoggingPreference = EXCLUDED.CertificateTransparencyLoggingPreference,
    Tags = EXCLUDED.Tags,
    _tags = EXCLUDED._tags,
    _account_id = EXCLUDED._account_id
  ;


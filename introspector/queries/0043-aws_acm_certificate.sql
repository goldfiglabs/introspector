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
  certificatearn.attr_value #>> '{}' AS certificatearn,
  domainname.attr_value #>> '{}' AS domainname,
  subjectalternativenames.attr_value::jsonb AS subjectalternativenames,
  domainvalidationoptions.attr_value::jsonb AS domainvalidationoptions,
  serial.attr_value #>> '{}' AS serial,
  subject.attr_value #>> '{}' AS subject,
  issuer.attr_value #>> '{}' AS issuer,
  (TO_TIMESTAMP(createdat.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS createdat,
  (TO_TIMESTAMP(issuedat.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS issuedat,
  (TO_TIMESTAMP(importedat.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS importedat,
  status.attr_value #>> '{}' AS status,
  (TO_TIMESTAMP(revokedat.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS revokedat,
  revocationreason.attr_value #>> '{}' AS revocationreason,
  (TO_TIMESTAMP(notbefore.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS notbefore,
  (TO_TIMESTAMP(notafter.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS notafter,
  keyalgorithm.attr_value #>> '{}' AS keyalgorithm,
  signaturealgorithm.attr_value #>> '{}' AS signaturealgorithm,
  inuseby.attr_value::jsonb AS inuseby,
  failurereason.attr_value #>> '{}' AS failurereason,
  type.attr_value #>> '{}' AS type,
  renewalsummary.attr_value::jsonb AS renewalsummary,
  keyusages.attr_value::jsonb AS keyusages,
  extendedkeyusages.attr_value::jsonb AS extendedkeyusages,
  certificateauthorityarn.attr_value #>> '{}' AS certificateauthorityarn,
  renewaleligibility.attr_value #>> '{}' AS renewaleligibility,
  certificatetransparencyloggingpreference.attr_value #>> '{}' AS certificatetransparencyloggingpreference,
  tags.attr_value::jsonb AS tags,
  _tags.attr_value::jsonb AS _tags,
  
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN resource_attribute AS certificatearn
    ON certificatearn.resource_id = R.id
    AND certificatearn.type = 'provider'
    AND lower(certificatearn.attr_name) = 'certificatearn'
    AND certificatearn.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS domainname
    ON domainname.resource_id = R.id
    AND domainname.type = 'provider'
    AND lower(domainname.attr_name) = 'domainname'
    AND domainname.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS subjectalternativenames
    ON subjectalternativenames.resource_id = R.id
    AND subjectalternativenames.type = 'provider'
    AND lower(subjectalternativenames.attr_name) = 'subjectalternativenames'
    AND subjectalternativenames.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS domainvalidationoptions
    ON domainvalidationoptions.resource_id = R.id
    AND domainvalidationoptions.type = 'provider'
    AND lower(domainvalidationoptions.attr_name) = 'domainvalidationoptions'
    AND domainvalidationoptions.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS serial
    ON serial.resource_id = R.id
    AND serial.type = 'provider'
    AND lower(serial.attr_name) = 'serial'
    AND serial.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS subject
    ON subject.resource_id = R.id
    AND subject.type = 'provider'
    AND lower(subject.attr_name) = 'subject'
    AND subject.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS issuer
    ON issuer.resource_id = R.id
    AND issuer.type = 'provider'
    AND lower(issuer.attr_name) = 'issuer'
    AND issuer.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS createdat
    ON createdat.resource_id = R.id
    AND createdat.type = 'provider'
    AND lower(createdat.attr_name) = 'createdat'
    AND createdat.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS issuedat
    ON issuedat.resource_id = R.id
    AND issuedat.type = 'provider'
    AND lower(issuedat.attr_name) = 'issuedat'
    AND issuedat.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS importedat
    ON importedat.resource_id = R.id
    AND importedat.type = 'provider'
    AND lower(importedat.attr_name) = 'importedat'
    AND importedat.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS status
    ON status.resource_id = R.id
    AND status.type = 'provider'
    AND lower(status.attr_name) = 'status'
    AND status.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS revokedat
    ON revokedat.resource_id = R.id
    AND revokedat.type = 'provider'
    AND lower(revokedat.attr_name) = 'revokedat'
    AND revokedat.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS revocationreason
    ON revocationreason.resource_id = R.id
    AND revocationreason.type = 'provider'
    AND lower(revocationreason.attr_name) = 'revocationreason'
    AND revocationreason.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS notbefore
    ON notbefore.resource_id = R.id
    AND notbefore.type = 'provider'
    AND lower(notbefore.attr_name) = 'notbefore'
    AND notbefore.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS notafter
    ON notafter.resource_id = R.id
    AND notafter.type = 'provider'
    AND lower(notafter.attr_name) = 'notafter'
    AND notafter.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS keyalgorithm
    ON keyalgorithm.resource_id = R.id
    AND keyalgorithm.type = 'provider'
    AND lower(keyalgorithm.attr_name) = 'keyalgorithm'
    AND keyalgorithm.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS signaturealgorithm
    ON signaturealgorithm.resource_id = R.id
    AND signaturealgorithm.type = 'provider'
    AND lower(signaturealgorithm.attr_name) = 'signaturealgorithm'
    AND signaturealgorithm.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS inuseby
    ON inuseby.resource_id = R.id
    AND inuseby.type = 'provider'
    AND lower(inuseby.attr_name) = 'inuseby'
    AND inuseby.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS failurereason
    ON failurereason.resource_id = R.id
    AND failurereason.type = 'provider'
    AND lower(failurereason.attr_name) = 'failurereason'
    AND failurereason.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS type
    ON type.resource_id = R.id
    AND type.type = 'provider'
    AND lower(type.attr_name) = 'type'
    AND type.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS renewalsummary
    ON renewalsummary.resource_id = R.id
    AND renewalsummary.type = 'provider'
    AND lower(renewalsummary.attr_name) = 'renewalsummary'
    AND renewalsummary.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS keyusages
    ON keyusages.resource_id = R.id
    AND keyusages.type = 'provider'
    AND lower(keyusages.attr_name) = 'keyusages'
    AND keyusages.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS extendedkeyusages
    ON extendedkeyusages.resource_id = R.id
    AND extendedkeyusages.type = 'provider'
    AND lower(extendedkeyusages.attr_name) = 'extendedkeyusages'
    AND extendedkeyusages.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS certificateauthorityarn
    ON certificateauthorityarn.resource_id = R.id
    AND certificateauthorityarn.type = 'provider'
    AND lower(certificateauthorityarn.attr_name) = 'certificateauthorityarn'
    AND certificateauthorityarn.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS renewaleligibility
    ON renewaleligibility.resource_id = R.id
    AND renewaleligibility.type = 'provider'
    AND lower(renewaleligibility.attr_name) = 'renewaleligibility'
    AND renewaleligibility.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS certificatetransparencyloggingpreference
    ON certificatetransparencyloggingpreference.resource_id = R.id
    AND certificatetransparencyloggingpreference.type = 'provider'
    AND lower(certificatetransparencyloggingpreference.attr_name) = 'certificatetransparencyloggingpreference'
    AND certificatetransparencyloggingpreference.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS tags
    ON tags.resource_id = R.id
    AND tags.type = 'provider'
    AND lower(tags.attr_name) = 'tags'
    AND tags.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS _tags
    ON _tags.resource_id = R.id
    AND _tags.type = 'Metadata'
    AND lower(_tags.attr_name) = 'tags'
    AND _tags.provider_account_id = R.provider_account_id
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
  AND R.provider_type = 'Certificate'
  AND R.service = 'acm'
ON CONFLICT (_id) DO UPDATE
SET
    certificatearn = EXCLUDED.certificatearn,
    domainname = EXCLUDED.domainname,
    subjectalternativenames = EXCLUDED.subjectalternativenames,
    domainvalidationoptions = EXCLUDED.domainvalidationoptions,
    serial = EXCLUDED.serial,
    subject = EXCLUDED.subject,
    issuer = EXCLUDED.issuer,
    createdat = EXCLUDED.createdat,
    issuedat = EXCLUDED.issuedat,
    importedat = EXCLUDED.importedat,
    status = EXCLUDED.status,
    revokedat = EXCLUDED.revokedat,
    revocationreason = EXCLUDED.revocationreason,
    notbefore = EXCLUDED.notbefore,
    notafter = EXCLUDED.notafter,
    keyalgorithm = EXCLUDED.keyalgorithm,
    signaturealgorithm = EXCLUDED.signaturealgorithm,
    inuseby = EXCLUDED.inuseby,
    failurereason = EXCLUDED.failurereason,
    type = EXCLUDED.type,
    renewalsummary = EXCLUDED.renewalsummary,
    keyusages = EXCLUDED.keyusages,
    extendedkeyusages = EXCLUDED.extendedkeyusages,
    certificateauthorityarn = EXCLUDED.certificateauthorityarn,
    renewaleligibility = EXCLUDED.renewaleligibility,
    certificatetransparencyloggingpreference = EXCLUDED.certificatetransparencyloggingpreference,
    tags = EXCLUDED.tags,
    _tags = EXCLUDED._tags,
    _account_id = EXCLUDED._account_id
  ;


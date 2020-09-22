DROP MATERIALIZED VIEW IF EXISTS aws_acm_certificate CASCADE;

CREATE MATERIALIZED VIEW aws_acm_certificate AS
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
  
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN attrs AS certificatearn
    ON certificatearn.id = R.id
    AND certificatearn.attr_name = 'certificatearn'
  LEFT JOIN attrs AS domainname
    ON domainname.id = R.id
    AND domainname.attr_name = 'domainname'
  LEFT JOIN attrs AS subjectalternativenames
    ON subjectalternativenames.id = R.id
    AND subjectalternativenames.attr_name = 'subjectalternativenames'
  LEFT JOIN attrs AS domainvalidationoptions
    ON domainvalidationoptions.id = R.id
    AND domainvalidationoptions.attr_name = 'domainvalidationoptions'
  LEFT JOIN attrs AS serial
    ON serial.id = R.id
    AND serial.attr_name = 'serial'
  LEFT JOIN attrs AS subject
    ON subject.id = R.id
    AND subject.attr_name = 'subject'
  LEFT JOIN attrs AS issuer
    ON issuer.id = R.id
    AND issuer.attr_name = 'issuer'
  LEFT JOIN attrs AS createdat
    ON createdat.id = R.id
    AND createdat.attr_name = 'createdat'
  LEFT JOIN attrs AS issuedat
    ON issuedat.id = R.id
    AND issuedat.attr_name = 'issuedat'
  LEFT JOIN attrs AS importedat
    ON importedat.id = R.id
    AND importedat.attr_name = 'importedat'
  LEFT JOIN attrs AS status
    ON status.id = R.id
    AND status.attr_name = 'status'
  LEFT JOIN attrs AS revokedat
    ON revokedat.id = R.id
    AND revokedat.attr_name = 'revokedat'
  LEFT JOIN attrs AS revocationreason
    ON revocationreason.id = R.id
    AND revocationreason.attr_name = 'revocationreason'
  LEFT JOIN attrs AS notbefore
    ON notbefore.id = R.id
    AND notbefore.attr_name = 'notbefore'
  LEFT JOIN attrs AS notafter
    ON notafter.id = R.id
    AND notafter.attr_name = 'notafter'
  LEFT JOIN attrs AS keyalgorithm
    ON keyalgorithm.id = R.id
    AND keyalgorithm.attr_name = 'keyalgorithm'
  LEFT JOIN attrs AS signaturealgorithm
    ON signaturealgorithm.id = R.id
    AND signaturealgorithm.attr_name = 'signaturealgorithm'
  LEFT JOIN attrs AS inuseby
    ON inuseby.id = R.id
    AND inuseby.attr_name = 'inuseby'
  LEFT JOIN attrs AS failurereason
    ON failurereason.id = R.id
    AND failurereason.attr_name = 'failurereason'
  LEFT JOIN attrs AS type
    ON type.id = R.id
    AND type.attr_name = 'type'
  LEFT JOIN attrs AS renewalsummary
    ON renewalsummary.id = R.id
    AND renewalsummary.attr_name = 'renewalsummary'
  LEFT JOIN attrs AS keyusages
    ON keyusages.id = R.id
    AND keyusages.attr_name = 'keyusages'
  LEFT JOIN attrs AS extendedkeyusages
    ON extendedkeyusages.id = R.id
    AND extendedkeyusages.attr_name = 'extendedkeyusages'
  LEFT JOIN attrs AS certificateauthorityarn
    ON certificateauthorityarn.id = R.id
    AND certificateauthorityarn.attr_name = 'certificateauthorityarn'
  LEFT JOIN attrs AS renewaleligibility
    ON renewaleligibility.id = R.id
    AND renewaleligibility.attr_name = 'renewaleligibility'
  LEFT JOIN attrs AS certificatetransparencyloggingpreference
    ON certificatetransparencyloggingpreference.id = R.id
    AND certificatetransparencyloggingpreference.attr_name = 'certificatetransparencyloggingpreference'
  LEFT JOIN attrs AS tags
    ON tags.id = R.id
    AND tags.attr_name = 'tags'
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
  AND LOWER(R.provider_type) = 'certificate'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_acm_certificate;

COMMENT ON MATERIALIZED VIEW aws_acm_certificate IS 'acm certificate resources and their associated attributes.';


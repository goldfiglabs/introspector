DROP MATERIALIZED VIEW IF EXISTS aws_iam_signingcertificate CASCADE;

CREATE MATERIALIZED VIEW aws_iam_signingcertificate AS
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
  username.attr_value #>> '{}' AS username,
  certificateid.attr_value #>> '{}' AS certificateid,
  certificatebody.attr_value #>> '{}' AS certificatebody,
  status.attr_value #>> '{}' AS status,
  (TO_TIMESTAMP(uploaddate.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS uploaddate
  
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN attrs AS username
    ON username.id = R.id
    AND username.attr_name = 'username'
  LEFT JOIN attrs AS certificateid
    ON certificateid.id = R.id
    AND certificateid.attr_name = 'certificateid'
  LEFT JOIN attrs AS certificatebody
    ON certificatebody.id = R.id
    AND certificatebody.attr_name = 'certificatebody'
  LEFT JOIN attrs AS status
    ON status.id = R.id
    AND status.attr_name = 'status'
  LEFT JOIN attrs AS uploaddate
    ON uploaddate.id = R.id
    AND uploaddate.attr_name = 'uploaddate'
  WHERE
  PA.provider = 'aws'
  AND LOWER(R.provider_type) = 'signingcertificate'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_iam_signingcertificate;

COMMENT ON MATERIALIZED VIEW aws_iam_signingcertificate IS 'iam signingcertificate resources and their associated attributes.';
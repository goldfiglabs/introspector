DROP MATERIALIZED VIEW IF EXISTS aws_iam_policyversion CASCADE;

CREATE MATERIALIZED VIEW aws_iam_policyversion AS
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
  document.attr_value #>> '{}' AS document,
  versionid.attr_value #>> '{}' AS versionid,
  isdefaultversion.attr_value::boolean AS isdefaultversion,
  (TO_TIMESTAMP(createdate.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS createdate
  
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN attrs AS document
    ON document.id = R.id
    AND document.attr_name = 'document'
  LEFT JOIN attrs AS versionid
    ON versionid.id = R.id
    AND versionid.attr_name = 'versionid'
  LEFT JOIN attrs AS isdefaultversion
    ON isdefaultversion.id = R.id
    AND isdefaultversion.attr_name = 'isdefaultversion'
  LEFT JOIN attrs AS createdate
    ON createdate.id = R.id
    AND createdate.attr_name = 'createdate'
  WHERE
  PA.provider = 'aws'
  AND LOWER(R.provider_type) = 'policyversion'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_iam_policyversion;

COMMENT ON MATERIALIZED VIEW aws_iam_policyversion IS 'iam policyversion resources and their associated attributes.';
DROP MATERIALIZED VIEW IF EXISTS aws_iam_grouppolicy CASCADE;

CREATE MATERIALIZED VIEW aws_iam_grouppolicy AS
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
  groupname.attr_value #>> '{}' AS groupname,
  policyname.attr_value #>> '{}' AS policyname,
  policydocument.attr_value #>> '{}' AS policydocument
  
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN attrs AS groupname
    ON groupname.id = R.id
    AND groupname.attr_name = 'groupname'
  LEFT JOIN attrs AS policyname
    ON policyname.id = R.id
    AND policyname.attr_name = 'policyname'
  LEFT JOIN attrs AS policydocument
    ON policydocument.id = R.id
    AND policydocument.attr_name = 'policydocument'
  WHERE
  PA.provider = 'aws'
  AND LOWER(R.provider_type) = 'grouppolicy'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_iam_grouppolicy;

COMMENT ON MATERIALIZED VIEW aws_iam_grouppolicy IS 'iam grouppolicy resources and their associated attributes.';
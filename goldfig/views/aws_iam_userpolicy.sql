DROP MATERIALIZED VIEW IF EXISTS aws_iam_userpolicy CASCADE;

CREATE MATERIALIZED VIEW aws_iam_userpolicy AS
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
  policyname.attr_value #>> '{}' AS policyname,
  policydocument.attr_value #>> '{}' AS policydocument
  
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN attrs AS username
    ON username.id = R.id
    AND username.attr_name = 'username'
  LEFT JOIN attrs AS policyname
    ON policyname.id = R.id
    AND policyname.attr_name = 'policyname'
  LEFT JOIN attrs AS policydocument
    ON policydocument.id = R.id
    AND policydocument.attr_name = 'policydocument'
  WHERE
  PA.provider = 'aws'
  AND LOWER(R.provider_type) = 'userpolicy'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_iam_userpolicy;

COMMENT ON MATERIALIZED VIEW aws_iam_userpolicy IS 'iam userpolicy resources and their associated attributes.';
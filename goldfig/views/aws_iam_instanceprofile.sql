DROP MATERIALIZED VIEW IF EXISTS aws_iam_instanceprofile CASCADE;

CREATE MATERIALIZED VIEW aws_iam_instanceprofile AS
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
  path.attr_value #>> '{}' AS path,
  instanceprofilename.attr_value #>> '{}' AS instanceprofilename,
  instanceprofileid.attr_value #>> '{}' AS instanceprofileid,
  arn.attr_value #>> '{}' AS arn,
  (TO_TIMESTAMP(createdate.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS createdate,
  roles.attr_value::jsonb AS roles
  
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN attrs AS path
    ON path.id = R.id
    AND path.attr_name = 'path'
  LEFT JOIN attrs AS instanceprofilename
    ON instanceprofilename.id = R.id
    AND instanceprofilename.attr_name = 'instanceprofilename'
  LEFT JOIN attrs AS instanceprofileid
    ON instanceprofileid.id = R.id
    AND instanceprofileid.attr_name = 'instanceprofileid'
  LEFT JOIN attrs AS arn
    ON arn.id = R.id
    AND arn.attr_name = 'arn'
  LEFT JOIN attrs AS createdate
    ON createdate.id = R.id
    AND createdate.attr_name = 'createdate'
  LEFT JOIN attrs AS roles
    ON roles.id = R.id
    AND roles.attr_name = 'roles'
  WHERE
  PA.provider = 'aws'
  AND LOWER(R.provider_type) = 'instanceprofile'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_iam_instanceprofile;

COMMENT ON MATERIALIZED VIEW aws_iam_instanceprofile IS 'iam instanceprofile resources and their associated attributes.';
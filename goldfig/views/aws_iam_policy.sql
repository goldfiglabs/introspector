DROP MATERIALIZED VIEW IF EXISTS aws_iam_policy CASCADE;

CREATE MATERIALIZED VIEW aws_iam_policy AS
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
  policyname.attr_value #>> '{}' AS policyname,
  policyid.attr_value #>> '{}' AS policyid,
  arn.attr_value #>> '{}' AS arn,
  path.attr_value #>> '{}' AS path,
  defaultversionid.attr_value #>> '{}' AS defaultversionid,
  attachmentcount.attr_value::integer AS attachmentcount,
  permissionsboundaryusagecount.attr_value::integer AS permissionsboundaryusagecount,
  isattachable.attr_value::boolean AS isattachable,
  description.attr_value #>> '{}' AS description,
  (TO_TIMESTAMP(createdate.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS createdate,
  (TO_TIMESTAMP(updatedate.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS updatedate,
  policygroups.attr_value::jsonb AS policygroups,
  policyusers.attr_value::jsonb AS policyusers,
  policyroles.attr_value::jsonb AS policyroles,
  versions.attr_value::jsonb AS versions
  
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN attrs AS policyname
    ON policyname.id = R.id
    AND policyname.attr_name = 'policyname'
  LEFT JOIN attrs AS policyid
    ON policyid.id = R.id
    AND policyid.attr_name = 'policyid'
  LEFT JOIN attrs AS arn
    ON arn.id = R.id
    AND arn.attr_name = 'arn'
  LEFT JOIN attrs AS path
    ON path.id = R.id
    AND path.attr_name = 'path'
  LEFT JOIN attrs AS defaultversionid
    ON defaultversionid.id = R.id
    AND defaultversionid.attr_name = 'defaultversionid'
  LEFT JOIN attrs AS attachmentcount
    ON attachmentcount.id = R.id
    AND attachmentcount.attr_name = 'attachmentcount'
  LEFT JOIN attrs AS permissionsboundaryusagecount
    ON permissionsboundaryusagecount.id = R.id
    AND permissionsboundaryusagecount.attr_name = 'permissionsboundaryusagecount'
  LEFT JOIN attrs AS isattachable
    ON isattachable.id = R.id
    AND isattachable.attr_name = 'isattachable'
  LEFT JOIN attrs AS description
    ON description.id = R.id
    AND description.attr_name = 'description'
  LEFT JOIN attrs AS createdate
    ON createdate.id = R.id
    AND createdate.attr_name = 'createdate'
  LEFT JOIN attrs AS updatedate
    ON updatedate.id = R.id
    AND updatedate.attr_name = 'updatedate'
  LEFT JOIN attrs AS policygroups
    ON policygroups.id = R.id
    AND policygroups.attr_name = 'policygroups'
  LEFT JOIN attrs AS policyusers
    ON policyusers.id = R.id
    AND policyusers.attr_name = 'policyusers'
  LEFT JOIN attrs AS policyroles
    ON policyroles.id = R.id
    AND policyroles.attr_name = 'policyroles'
  LEFT JOIN attrs AS versions
    ON versions.id = R.id
    AND versions.attr_name = 'versions'
  WHERE
  PA.provider = 'aws'
  AND LOWER(R.provider_type) = 'policy'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_iam_policy;

COMMENT ON MATERIALIZED VIEW aws_iam_policy IS 'iam policy resources and their associated attributes.';
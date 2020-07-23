DROP MATERIALIZED VIEW IF EXISTS aws_iam_user CASCADE;

CREATE MATERIALIZED VIEW aws_iam_user AS
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
  username.attr_value #>> '{}' AS username,
  userid.attr_value #>> '{}' AS userid,
  arn.attr_value #>> '{}' AS arn,
  (TO_TIMESTAMP(createdate.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS createdate,
  (TO_TIMESTAMP(passwordlastused.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS passwordlastused,
  permissionsboundary.attr_value::jsonb AS permissionsboundary,
  tags.attr_value::jsonb AS tags,
  policylist.attr_value::jsonb AS policylist,
  attachedpolicies.attr_value::jsonb AS attachedpolicies,
  accesskeys.attr_value::jsonb AS accesskeys,
  groups.attr_value::jsonb AS groups,
  mfadevices.attr_value::jsonb AS mfadevices,
  sshpublickeys.attr_value::jsonb AS sshpublickeys,
  servicespecificcredentials.attr_value::jsonb AS servicespecificcredentials,
  certificates.attr_value::jsonb AS certificates
  
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN attrs AS path
    ON path.id = R.id
    AND path.attr_name = 'path'
  LEFT JOIN attrs AS username
    ON username.id = R.id
    AND username.attr_name = 'username'
  LEFT JOIN attrs AS userid
    ON userid.id = R.id
    AND userid.attr_name = 'userid'
  LEFT JOIN attrs AS arn
    ON arn.id = R.id
    AND arn.attr_name = 'arn'
  LEFT JOIN attrs AS createdate
    ON createdate.id = R.id
    AND createdate.attr_name = 'createdate'
  LEFT JOIN attrs AS passwordlastused
    ON passwordlastused.id = R.id
    AND passwordlastused.attr_name = 'passwordlastused'
  LEFT JOIN attrs AS permissionsboundary
    ON permissionsboundary.id = R.id
    AND permissionsboundary.attr_name = 'permissionsboundary'
  LEFT JOIN attrs AS tags
    ON tags.id = R.id
    AND tags.attr_name = 'tags'
  LEFT JOIN attrs AS policylist
    ON policylist.id = R.id
    AND policylist.attr_name = 'policylist'
  LEFT JOIN attrs AS attachedpolicies
    ON attachedpolicies.id = R.id
    AND attachedpolicies.attr_name = 'attachedpolicies'
  LEFT JOIN attrs AS accesskeys
    ON accesskeys.id = R.id
    AND accesskeys.attr_name = 'accesskeys'
  LEFT JOIN attrs AS groups
    ON groups.id = R.id
    AND groups.attr_name = 'groups'
  LEFT JOIN attrs AS mfadevices
    ON mfadevices.id = R.id
    AND mfadevices.attr_name = 'mfadevices'
  LEFT JOIN attrs AS sshpublickeys
    ON sshpublickeys.id = R.id
    AND sshpublickeys.attr_name = 'sshpublickeys'
  LEFT JOIN attrs AS servicespecificcredentials
    ON servicespecificcredentials.id = R.id
    AND servicespecificcredentials.attr_name = 'servicespecificcredentials'
  LEFT JOIN attrs AS certificates
    ON certificates.id = R.id
    AND certificates.attr_name = 'certificates'
  WHERE
  PA.provider = 'aws'
  AND LOWER(R.provider_type) = 'user'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_iam_user;

COMMENT ON MATERIALIZED VIEW aws_iam_user IS 'iam user resources and their associated attributes.';
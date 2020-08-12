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
  certificates.attr_value::jsonb AS certificates,
  loginprofile.attr_value::jsonb AS loginprofile,
  password_enabled.attr_value::boolean AS password_enabled,
  (TO_TIMESTAMP(password_last_changed.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS password_last_changed,
  (TO_TIMESTAMP(password_next_rotation.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS password_next_rotation,
  mfa_active.attr_value::boolean AS mfa_active,
  access_key_1_active.attr_value::boolean AS access_key_1_active,
  (TO_TIMESTAMP(access_key_1_last_rotated.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS access_key_1_last_rotated,
  (TO_TIMESTAMP(access_key_1_last_used_date.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS access_key_1_last_used_date,
  access_key_1_last_used_region.attr_value #>> '{}' AS access_key_1_last_used_region,
  access_key_1_last_used_service.attr_value #>> '{}' AS access_key_1_last_used_service,
  access_key_2_active.attr_value::boolean AS access_key_2_active,
  (TO_TIMESTAMP(access_key_2_last_rotated.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS access_key_2_last_rotated,
  (TO_TIMESTAMP(access_key_2_last_used_date.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS access_key_2_last_used_date,
  access_key_2_last_used_region.attr_value #>> '{}' AS access_key_2_last_used_region,
  access_key_2_last_used_service.attr_value #>> '{}' AS access_key_2_last_used_service,
  cert_1_active.attr_value::boolean AS cert_1_active,
  (TO_TIMESTAMP(cert_1_last_rotated.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS cert_1_last_rotated,
  cert_2_active.attr_value::boolean AS cert_2_active,
  (TO_TIMESTAMP(cert_2_last_rotated.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS cert_2_last_rotated,
  
    _account_id.target_id AS _account_id
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
  LEFT JOIN attrs AS loginprofile
    ON loginprofile.id = R.id
    AND loginprofile.attr_name = 'loginprofile'
  LEFT JOIN attrs AS password_enabled
    ON password_enabled.id = R.id
    AND password_enabled.attr_name = 'password_enabled'
  LEFT JOIN attrs AS password_last_changed
    ON password_last_changed.id = R.id
    AND password_last_changed.attr_name = 'password_last_changed'
  LEFT JOIN attrs AS password_next_rotation
    ON password_next_rotation.id = R.id
    AND password_next_rotation.attr_name = 'password_next_rotation'
  LEFT JOIN attrs AS mfa_active
    ON mfa_active.id = R.id
    AND mfa_active.attr_name = 'mfa_active'
  LEFT JOIN attrs AS access_key_1_active
    ON access_key_1_active.id = R.id
    AND access_key_1_active.attr_name = 'access_key_1_active'
  LEFT JOIN attrs AS access_key_1_last_rotated
    ON access_key_1_last_rotated.id = R.id
    AND access_key_1_last_rotated.attr_name = 'access_key_1_last_rotated'
  LEFT JOIN attrs AS access_key_1_last_used_date
    ON access_key_1_last_used_date.id = R.id
    AND access_key_1_last_used_date.attr_name = 'access_key_1_last_used_date'
  LEFT JOIN attrs AS access_key_1_last_used_region
    ON access_key_1_last_used_region.id = R.id
    AND access_key_1_last_used_region.attr_name = 'access_key_1_last_used_region'
  LEFT JOIN attrs AS access_key_1_last_used_service
    ON access_key_1_last_used_service.id = R.id
    AND access_key_1_last_used_service.attr_name = 'access_key_1_last_used_service'
  LEFT JOIN attrs AS access_key_2_active
    ON access_key_2_active.id = R.id
    AND access_key_2_active.attr_name = 'access_key_2_active'
  LEFT JOIN attrs AS access_key_2_last_rotated
    ON access_key_2_last_rotated.id = R.id
    AND access_key_2_last_rotated.attr_name = 'access_key_2_last_rotated'
  LEFT JOIN attrs AS access_key_2_last_used_date
    ON access_key_2_last_used_date.id = R.id
    AND access_key_2_last_used_date.attr_name = 'access_key_2_last_used_date'
  LEFT JOIN attrs AS access_key_2_last_used_region
    ON access_key_2_last_used_region.id = R.id
    AND access_key_2_last_used_region.attr_name = 'access_key_2_last_used_region'
  LEFT JOIN attrs AS access_key_2_last_used_service
    ON access_key_2_last_used_service.id = R.id
    AND access_key_2_last_used_service.attr_name = 'access_key_2_last_used_service'
  LEFT JOIN attrs AS cert_1_active
    ON cert_1_active.id = R.id
    AND cert_1_active.attr_name = 'cert_1_active'
  LEFT JOIN attrs AS cert_1_last_rotated
    ON cert_1_last_rotated.id = R.id
    AND cert_1_last_rotated.attr_name = 'cert_1_last_rotated'
  LEFT JOIN attrs AS cert_2_active
    ON cert_2_active.id = R.id
    AND cert_2_active.attr_name = 'cert_2_active'
  LEFT JOIN attrs AS cert_2_last_rotated
    ON cert_2_last_rotated.id = R.id
    AND cert_2_last_rotated.attr_name = 'cert_2_last_rotated'
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
  AND LOWER(R.provider_type) = 'user'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_iam_user;

COMMENT ON MATERIALIZED VIEW aws_iam_user IS 'iam user resources and their associated attributes.';


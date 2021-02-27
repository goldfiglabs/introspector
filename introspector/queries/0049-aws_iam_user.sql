INSERT INTO aws_iam_user (
  _id,
  uri,
  provider_account_id,
  path,
  username,
  userid,
  arn,
  createdate,
  passwordlastused,
  permissionsboundary,
  tags,
  policylist,
  attachedpolicies,
  accesskeys,
  groups,
  mfadevices,
  sshpublickeys,
  servicespecificcredentials,
  certificates,
  loginprofile,
  _tags,
  password_enabled,
  password_last_changed,
  password_next_rotation,
  mfa_active,
  access_key_1_active,
  access_key_1_last_rotated,
  access_key_1_last_used_date,
  access_key_1_last_used_region,
  access_key_1_last_used_service,
  access_key_2_active,
  access_key_2_last_rotated,
  access_key_2_last_used_date,
  access_key_2_last_used_region,
  access_key_2_last_used_service,
  cert_1_active,
  cert_1_last_rotated,
  cert_2_active,
  cert_2_last_rotated,
  _account_id
)
SELECT
  R.id AS _id,
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
  _tags.attr_value::jsonb AS _tags,
  (password_enabled.attr_value #>> '{}')::boolean AS password_enabled,
  (TO_TIMESTAMP(password_last_changed.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS password_last_changed,
  (TO_TIMESTAMP(password_next_rotation.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS password_next_rotation,
  (mfa_active.attr_value #>> '{}')::boolean AS mfa_active,
  (access_key_1_active.attr_value #>> '{}')::boolean AS access_key_1_active,
  (TO_TIMESTAMP(access_key_1_last_rotated.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS access_key_1_last_rotated,
  (TO_TIMESTAMP(access_key_1_last_used_date.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS access_key_1_last_used_date,
  access_key_1_last_used_region.attr_value #>> '{}' AS access_key_1_last_used_region,
  access_key_1_last_used_service.attr_value #>> '{}' AS access_key_1_last_used_service,
  (access_key_2_active.attr_value #>> '{}')::boolean AS access_key_2_active,
  (TO_TIMESTAMP(access_key_2_last_rotated.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS access_key_2_last_rotated,
  (TO_TIMESTAMP(access_key_2_last_used_date.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS access_key_2_last_used_date,
  access_key_2_last_used_region.attr_value #>> '{}' AS access_key_2_last_used_region,
  access_key_2_last_used_service.attr_value #>> '{}' AS access_key_2_last_used_service,
  (cert_1_active.attr_value #>> '{}')::boolean AS cert_1_active,
  (TO_TIMESTAMP(cert_1_last_rotated.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS cert_1_last_rotated,
  (cert_2_active.attr_value #>> '{}')::boolean AS cert_2_active,
  (TO_TIMESTAMP(cert_2_last_rotated.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS cert_2_last_rotated,

    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN resource_attribute AS path
    ON path.resource_id = R.id
    AND path.type = 'provider'
    AND lower(path.attr_name) = 'path'
  LEFT JOIN resource_attribute AS username
    ON username.resource_id = R.id
    AND username.type = 'provider'
    AND lower(username.attr_name) = 'username'
  LEFT JOIN resource_attribute AS userid
    ON userid.resource_id = R.id
    AND userid.type = 'provider'
    AND lower(userid.attr_name) = 'userid'
  LEFT JOIN resource_attribute AS arn
    ON arn.resource_id = R.id
    AND arn.type = 'provider'
    AND lower(arn.attr_name) = 'arn'
  LEFT JOIN resource_attribute AS createdate
    ON createdate.resource_id = R.id
    AND createdate.type = 'provider'
    AND lower(createdate.attr_name) = 'createdate'
  LEFT JOIN resource_attribute AS passwordlastused
    ON passwordlastused.resource_id = R.id
    AND passwordlastused.type = 'provider'
    AND lower(passwordlastused.attr_name) = 'passwordlastused'
  LEFT JOIN resource_attribute AS permissionsboundary
    ON permissionsboundary.resource_id = R.id
    AND permissionsboundary.type = 'provider'
    AND lower(permissionsboundary.attr_name) = 'permissionsboundary'
  LEFT JOIN resource_attribute AS tags
    ON tags.resource_id = R.id
    AND tags.type = 'provider'
    AND lower(tags.attr_name) = 'tags'
  LEFT JOIN resource_attribute AS policylist
    ON policylist.resource_id = R.id
    AND policylist.type = 'provider'
    AND lower(policylist.attr_name) = 'policylist'
  LEFT JOIN resource_attribute AS attachedpolicies
    ON attachedpolicies.resource_id = R.id
    AND attachedpolicies.type = 'provider'
    AND lower(attachedpolicies.attr_name) = 'attachedpolicies'
  LEFT JOIN resource_attribute AS accesskeys
    ON accesskeys.resource_id = R.id
    AND accesskeys.type = 'provider'
    AND lower(accesskeys.attr_name) = 'accesskeys'
  LEFT JOIN resource_attribute AS groups
    ON groups.resource_id = R.id
    AND groups.type = 'provider'
    AND lower(groups.attr_name) = 'groups'
  LEFT JOIN resource_attribute AS mfadevices
    ON mfadevices.resource_id = R.id
    AND mfadevices.type = 'provider'
    AND lower(mfadevices.attr_name) = 'mfadevices'
  LEFT JOIN resource_attribute AS sshpublickeys
    ON sshpublickeys.resource_id = R.id
    AND sshpublickeys.type = 'provider'
    AND lower(sshpublickeys.attr_name) = 'sshpublickeys'
  LEFT JOIN resource_attribute AS servicespecificcredentials
    ON servicespecificcredentials.resource_id = R.id
    AND servicespecificcredentials.type = 'provider'
    AND lower(servicespecificcredentials.attr_name) = 'servicespecificcredentials'
  LEFT JOIN resource_attribute AS certificates
    ON certificates.resource_id = R.id
    AND certificates.type = 'provider'
    AND lower(certificates.attr_name) = 'certificates'
  LEFT JOIN resource_attribute AS loginprofile
    ON loginprofile.resource_id = R.id
    AND loginprofile.type = 'provider'
    AND lower(loginprofile.attr_name) = 'loginprofile'
  LEFT JOIN resource_attribute AS _tags
    ON _tags.resource_id = R.id
    AND _tags.type = 'Metadata'
    AND lower(_tags.attr_name) = 'tags'
  LEFT JOIN resource_attribute AS password_enabled
    ON password_enabled.resource_id = R.id
    AND password_enabled.type = 'provider'
    AND lower(password_enabled.attr_name) = 'password_enabled'
  LEFT JOIN resource_attribute AS password_last_changed
    ON password_last_changed.resource_id = R.id
    AND password_last_changed.type = 'provider'
    AND lower(password_last_changed.attr_name) = 'password_last_changed'
  LEFT JOIN resource_attribute AS password_next_rotation
    ON password_next_rotation.resource_id = R.id
    AND password_next_rotation.type = 'provider'
    AND lower(password_next_rotation.attr_name) = 'password_next_rotation'
  LEFT JOIN resource_attribute AS mfa_active
    ON mfa_active.resource_id = R.id
    AND mfa_active.type = 'provider'
    AND lower(mfa_active.attr_name) = 'mfa_active'
  LEFT JOIN resource_attribute AS access_key_1_active
    ON access_key_1_active.resource_id = R.id
    AND access_key_1_active.type = 'provider'
    AND lower(access_key_1_active.attr_name) = 'access_key_1_active'
  LEFT JOIN resource_attribute AS access_key_1_last_rotated
    ON access_key_1_last_rotated.resource_id = R.id
    AND access_key_1_last_rotated.type = 'provider'
    AND lower(access_key_1_last_rotated.attr_name) = 'access_key_1_last_rotated'
  LEFT JOIN resource_attribute AS access_key_1_last_used_date
    ON access_key_1_last_used_date.resource_id = R.id
    AND access_key_1_last_used_date.type = 'provider'
    AND lower(access_key_1_last_used_date.attr_name) = 'access_key_1_last_used_date'
  LEFT JOIN resource_attribute AS access_key_1_last_used_region
    ON access_key_1_last_used_region.resource_id = R.id
    AND access_key_1_last_used_region.type = 'provider'
    AND lower(access_key_1_last_used_region.attr_name) = 'access_key_1_last_used_region'
  LEFT JOIN resource_attribute AS access_key_1_last_used_service
    ON access_key_1_last_used_service.resource_id = R.id
    AND access_key_1_last_used_service.type = 'provider'
    AND lower(access_key_1_last_used_service.attr_name) = 'access_key_1_last_used_service'
  LEFT JOIN resource_attribute AS access_key_2_active
    ON access_key_2_active.resource_id = R.id
    AND access_key_2_active.type = 'provider'
    AND lower(access_key_2_active.attr_name) = 'access_key_2_active'
  LEFT JOIN resource_attribute AS access_key_2_last_rotated
    ON access_key_2_last_rotated.resource_id = R.id
    AND access_key_2_last_rotated.type = 'provider'
    AND lower(access_key_2_last_rotated.attr_name) = 'access_key_2_last_rotated'
  LEFT JOIN resource_attribute AS access_key_2_last_used_date
    ON access_key_2_last_used_date.resource_id = R.id
    AND access_key_2_last_used_date.type = 'provider'
    AND lower(access_key_2_last_used_date.attr_name) = 'access_key_2_last_used_date'
  LEFT JOIN resource_attribute AS access_key_2_last_used_region
    ON access_key_2_last_used_region.resource_id = R.id
    AND access_key_2_last_used_region.type = 'provider'
    AND lower(access_key_2_last_used_region.attr_name) = 'access_key_2_last_used_region'
  LEFT JOIN resource_attribute AS access_key_2_last_used_service
    ON access_key_2_last_used_service.resource_id = R.id
    AND access_key_2_last_used_service.type = 'provider'
    AND lower(access_key_2_last_used_service.attr_name) = 'access_key_2_last_used_service'
  LEFT JOIN resource_attribute AS cert_1_active
    ON cert_1_active.resource_id = R.id
    AND cert_1_active.type = 'provider'
    AND lower(cert_1_active.attr_name) = 'cert_1_active'
  LEFT JOIN resource_attribute AS cert_1_last_rotated
    ON cert_1_last_rotated.resource_id = R.id
    AND cert_1_last_rotated.type = 'provider'
    AND lower(cert_1_last_rotated.attr_name) = 'cert_1_last_rotated'
  LEFT JOIN resource_attribute AS cert_2_active
    ON cert_2_active.resource_id = R.id
    AND cert_2_active.type = 'provider'
    AND lower(cert_2_active.attr_name) = 'cert_2_active'
  LEFT JOIN resource_attribute AS cert_2_last_rotated
    ON cert_2_last_rotated.resource_id = R.id
    AND cert_2_last_rotated.type = 'provider'
    AND lower(cert_2_last_rotated.attr_name) = 'cert_2_last_rotated'
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
  AND R.provider_type = 'User'
  AND R.service = 'iam'
ON CONFLICT (_id) DO UPDATE
SET
    path = EXCLUDED.path,
    username = EXCLUDED.username,
    userid = EXCLUDED.userid,
    arn = EXCLUDED.arn,
    createdate = EXCLUDED.createdate,
    passwordlastused = EXCLUDED.passwordlastused,
    permissionsboundary = EXCLUDED.permissionsboundary,
    tags = EXCLUDED.tags,
    policylist = EXCLUDED.policylist,
    attachedpolicies = EXCLUDED.attachedpolicies,
    accesskeys = EXCLUDED.accesskeys,
    groups = EXCLUDED.groups,
    mfadevices = EXCLUDED.mfadevices,
    sshpublickeys = EXCLUDED.sshpublickeys,
    servicespecificcredentials = EXCLUDED.servicespecificcredentials,
    certificates = EXCLUDED.certificates,
    loginprofile = EXCLUDED.loginprofile,
    _tags = EXCLUDED._tags,
    password_enabled = EXCLUDED.password_enabled,
    password_last_changed = EXCLUDED.password_last_changed,
    password_next_rotation = EXCLUDED.password_next_rotation,
    mfa_active = EXCLUDED.mfa_active,
    access_key_1_active = EXCLUDED.access_key_1_active,
    access_key_1_last_rotated = EXCLUDED.access_key_1_last_rotated,
    access_key_1_last_used_date = EXCLUDED.access_key_1_last_used_date,
    access_key_1_last_used_region = EXCLUDED.access_key_1_last_used_region,
    access_key_1_last_used_service = EXCLUDED.access_key_1_last_used_service,
    access_key_2_active = EXCLUDED.access_key_2_active,
    access_key_2_last_rotated = EXCLUDED.access_key_2_last_rotated,
    access_key_2_last_used_date = EXCLUDED.access_key_2_last_used_date,
    access_key_2_last_used_region = EXCLUDED.access_key_2_last_used_region,
    access_key_2_last_used_service = EXCLUDED.access_key_2_last_used_service,
    cert_1_active = EXCLUDED.cert_1_active,
    cert_1_last_rotated = EXCLUDED.cert_1_last_rotated,
    cert_2_active = EXCLUDED.cert_2_active,
    cert_2_last_rotated = EXCLUDED.cert_2_last_rotated,
    _account_id = EXCLUDED._account_id
  ;

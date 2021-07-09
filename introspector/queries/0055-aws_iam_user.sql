WITH attrs AS (
  SELECT
    resource_id,
    jsonb_object_agg(attr_name, attr_value) FILTER (WHERE type = 'provider') AS provider,
    jsonb_object_agg(attr_name, attr_value) FILTER (WHERE type = 'Metadata') AS metadata
  FROM
    resource_attribute
  WHERE
    provider_account_id = :provider_account_id
  GROUP BY resource_id
)
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
  attrs.provider ->> 'Path' AS path,
  attrs.provider ->> 'UserName' AS username,
  attrs.provider ->> 'UserId' AS userid,
  attrs.provider ->> 'Arn' AS arn,
  (TO_TIMESTAMP(attrs.provider ->> 'CreateDate', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS createdate,
  (TO_TIMESTAMP(attrs.provider ->> 'PasswordLastUsed', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS passwordlastused,
  attrs.provider -> 'PermissionsBoundary' AS permissionsboundary,
  attrs.provider -> 'Tags' AS tags,
  attrs.provider -> 'PolicyList' AS policylist,
  attrs.provider -> 'AttachedPolicies' AS attachedpolicies,
  attrs.provider -> 'AccessKeys' AS accesskeys,
  attrs.provider -> 'Groups' AS groups,
  attrs.provider -> 'MFADevices' AS mfadevices,
  attrs.provider -> 'SSHPublicKeys' AS sshpublickeys,
  attrs.provider -> 'ServiceSpecificCredentials' AS servicespecificcredentials,
  attrs.provider -> 'Certificates' AS certificates,
  attrs.provider -> 'LoginProfile' AS loginprofile,
  attrs.metadata -> 'Tags' AS tags,
  (attrs.provider ->> 'password_enabled')::boolean AS password_enabled,
  (TO_TIMESTAMP(attrs.provider ->> 'password_last_changed', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS password_last_changed,
  (TO_TIMESTAMP(attrs.provider ->> 'password_next_rotation', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS password_next_rotation,
  (attrs.provider ->> 'mfa_active')::boolean AS mfa_active,
  (attrs.provider ->> 'access_key_1_active')::boolean AS access_key_1_active,
  (TO_TIMESTAMP(attrs.provider ->> 'access_key_1_last_rotated', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS access_key_1_last_rotated,
  (TO_TIMESTAMP(attrs.provider ->> 'access_key_1_last_used_date', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS access_key_1_last_used_date,
  attrs.provider ->> 'access_key_1_last_used_region' AS access_key_1_last_used_region,
  attrs.provider ->> 'access_key_1_last_used_service' AS access_key_1_last_used_service,
  (attrs.provider ->> 'access_key_2_active')::boolean AS access_key_2_active,
  (TO_TIMESTAMP(attrs.provider ->> 'access_key_2_last_rotated', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS access_key_2_last_rotated,
  (TO_TIMESTAMP(attrs.provider ->> 'access_key_2_last_used_date', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS access_key_2_last_used_date,
  attrs.provider ->> 'access_key_2_last_used_region' AS access_key_2_last_used_region,
  attrs.provider ->> 'access_key_2_last_used_service' AS access_key_2_last_used_service,
  (attrs.provider ->> 'cert_1_active')::boolean AS cert_1_active,
  (TO_TIMESTAMP(attrs.provider ->> 'cert_1_last_rotated', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS cert_1_last_rotated,
  (attrs.provider ->> 'cert_2_active')::boolean AS cert_2_active,
  (TO_TIMESTAMP(attrs.provider ->> 'cert_2_last_rotated', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS cert_2_last_rotated,
  
    _account_id.target_id AS _account_id
FROM
  resource AS R
  LEFT JOIN attrs ON
    attrs.resource_id = R.id
  LEFT JOIN (
    SELECT
      unique_account_mapping.resource_id,
      unique_account_mapping.target_ids[1] as target_id
    FROM
      (
        SELECT
          ARRAY_AGG(_aws_organizations_account_relation.target_id) AS target_ids,
          _aws_organizations_account_relation.resource_id
        FROM
          resource AS _aws_organizations_account
          INNER JOIN resource_relation AS _aws_organizations_account_relation
            ON _aws_organizations_account_relation.target_id = _aws_organizations_account.id
        WHERE
          _aws_organizations_account.provider_type = 'Account'
          AND _aws_organizations_account.service = 'organizations'
          AND _aws_organizations_account.provider_account_id = :provider_account_id
          AND _aws_organizations_account_relation.relation = 'in'
          AND _aws_organizations_account_relation.provider_account_id = 8
        GROUP BY _aws_organizations_account_relation.resource_id
        HAVING COUNT(*) = 1
      ) AS unique_account_mapping
  ) AS _account_id ON _account_id.resource_id = R.id
  WHERE
  R.provider_account_id = :provider_account_id
  AND R.provider_type = 'User'
  AND R.service = 'iam'
ON CONFLICT (_id) DO UPDATE
SET
    Path = EXCLUDED.Path,
    UserName = EXCLUDED.UserName,
    UserId = EXCLUDED.UserId,
    Arn = EXCLUDED.Arn,
    CreateDate = EXCLUDED.CreateDate,
    PasswordLastUsed = EXCLUDED.PasswordLastUsed,
    PermissionsBoundary = EXCLUDED.PermissionsBoundary,
    Tags = EXCLUDED.Tags,
    PolicyList = EXCLUDED.PolicyList,
    AttachedPolicies = EXCLUDED.AttachedPolicies,
    AccessKeys = EXCLUDED.AccessKeys,
    Groups = EXCLUDED.Groups,
    MFADevices = EXCLUDED.MFADevices,
    SSHPublicKeys = EXCLUDED.SSHPublicKeys,
    ServiceSpecificCredentials = EXCLUDED.ServiceSpecificCredentials,
    Certificates = EXCLUDED.Certificates,
    LoginProfile = EXCLUDED.LoginProfile,
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


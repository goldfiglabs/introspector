INSERT INTO aws_iam_policy (
  _id,
  uri,
  provider_account_id,
  policyname,
  policyid,
  arn,
  path,
  defaultversionid,
  attachmentcount,
  permissionsboundaryusagecount,
  isattachable,
  description,
  createdate,
  updatedate,
  policygroups,
  policyusers,
  policyroles,
  versions,
  _account_id
)
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  policyname.attr_value #>> '{}' AS policyname,
  policyid.attr_value #>> '{}' AS policyid,
  arn.attr_value #>> '{}' AS arn,
  path.attr_value #>> '{}' AS path,
  defaultversionid.attr_value #>> '{}' AS defaultversionid,
  (attachmentcount.attr_value #>> '{}')::integer AS attachmentcount,
  (permissionsboundaryusagecount.attr_value #>> '{}')::integer AS permissionsboundaryusagecount,
  (isattachable.attr_value #>> '{}')::boolean AS isattachable,
  description.attr_value #>> '{}' AS description,
  (TO_TIMESTAMP(createdate.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS createdate,
  (TO_TIMESTAMP(updatedate.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS updatedate,
  policygroups.attr_value::jsonb AS policygroups,
  policyusers.attr_value::jsonb AS policyusers,
  policyroles.attr_value::jsonb AS policyroles,
  versions.attr_value::jsonb AS versions,
  
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN resource_attribute AS policyname
    ON policyname.resource_id = R.id
    AND policyname.type = 'provider'
    AND lower(policyname.attr_name) = 'policyname'
    AND policyname.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS policyid
    ON policyid.resource_id = R.id
    AND policyid.type = 'provider'
    AND lower(policyid.attr_name) = 'policyid'
    AND policyid.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS arn
    ON arn.resource_id = R.id
    AND arn.type = 'provider'
    AND lower(arn.attr_name) = 'arn'
    AND arn.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS path
    ON path.resource_id = R.id
    AND path.type = 'provider'
    AND lower(path.attr_name) = 'path'
    AND path.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS defaultversionid
    ON defaultversionid.resource_id = R.id
    AND defaultversionid.type = 'provider'
    AND lower(defaultversionid.attr_name) = 'defaultversionid'
    AND defaultversionid.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS attachmentcount
    ON attachmentcount.resource_id = R.id
    AND attachmentcount.type = 'provider'
    AND lower(attachmentcount.attr_name) = 'attachmentcount'
    AND attachmentcount.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS permissionsboundaryusagecount
    ON permissionsboundaryusagecount.resource_id = R.id
    AND permissionsboundaryusagecount.type = 'provider'
    AND lower(permissionsboundaryusagecount.attr_name) = 'permissionsboundaryusagecount'
    AND permissionsboundaryusagecount.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS isattachable
    ON isattachable.resource_id = R.id
    AND isattachable.type = 'provider'
    AND lower(isattachable.attr_name) = 'isattachable'
    AND isattachable.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS description
    ON description.resource_id = R.id
    AND description.type = 'provider'
    AND lower(description.attr_name) = 'description'
    AND description.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS createdate
    ON createdate.resource_id = R.id
    AND createdate.type = 'provider'
    AND lower(createdate.attr_name) = 'createdate'
    AND createdate.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS updatedate
    ON updatedate.resource_id = R.id
    AND updatedate.type = 'provider'
    AND lower(updatedate.attr_name) = 'updatedate'
    AND updatedate.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS policygroups
    ON policygroups.resource_id = R.id
    AND policygroups.type = 'provider'
    AND lower(policygroups.attr_name) = 'policygroups'
    AND policygroups.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS policyusers
    ON policyusers.resource_id = R.id
    AND policyusers.type = 'provider'
    AND lower(policyusers.attr_name) = 'policyusers'
    AND policyusers.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS policyroles
    ON policyroles.resource_id = R.id
    AND policyroles.type = 'provider'
    AND lower(policyroles.attr_name) = 'policyroles'
    AND policyroles.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS versions
    ON versions.resource_id = R.id
    AND versions.type = 'provider'
    AND lower(versions.attr_name) = 'versions'
    AND versions.provider_account_id = R.provider_account_id
  LEFT JOIN (
    SELECT
      _aws_organizations_account_relation.resource_id AS resource_id,
      _aws_organizations_account.id AS target_id
    FROM
    (
      SELECT
        _aws_organizations_account_relation.resource_id AS resource_id
      FROM
        resource_relation AS _aws_organizations_account_relation
        INNER JOIN resource AS _aws_organizations_account
          ON _aws_organizations_account_relation.target_id = _aws_organizations_account.id
          AND _aws_organizations_account.provider_type = 'Account'
          AND _aws_organizations_account.service = 'organizations'
      WHERE
        _aws_organizations_account_relation.relation = 'in'
        AND _aws_organizations_account_relation.provider_account_id = :provider_account_id
      GROUP BY _aws_organizations_account_relation.resource_id
      HAVING COUNT(*) = 1
    ) AS unique_account_mapping
    INNER JOIN resource_relation AS _aws_organizations_account_relation
      ON _aws_organizations_account_relation.resource_id = unique_account_mapping.resource_id
    INNER JOIN resource AS _aws_organizations_account
      ON _aws_organizations_account_relation.target_id = _aws_organizations_account.id
      AND _aws_organizations_account.provider_type = 'Account'
      AND _aws_organizations_account.service = 'organizations'
      AND _aws_organizations_account_relation.provider_account_id = :provider_account_id
    WHERE
        _aws_organizations_account_relation.relation = 'in'
        AND _aws_organizations_account_relation.provider_account_id = :provider_account_id
  ) AS _account_id ON _account_id.resource_id = R.id
  WHERE
  R.provider_account_id = :provider_account_id
  AND PA.provider = 'aws'
  AND R.provider_type = 'Policy'
  AND R.service = 'iam'
ON CONFLICT (_id) DO UPDATE
SET
    policyname = EXCLUDED.policyname,
    policyid = EXCLUDED.policyid,
    arn = EXCLUDED.arn,
    path = EXCLUDED.path,
    defaultversionid = EXCLUDED.defaultversionid,
    attachmentcount = EXCLUDED.attachmentcount,
    permissionsboundaryusagecount = EXCLUDED.permissionsboundaryusagecount,
    isattachable = EXCLUDED.isattachable,
    description = EXCLUDED.description,
    createdate = EXCLUDED.createdate,
    updatedate = EXCLUDED.updatedate,
    policygroups = EXCLUDED.policygroups,
    policyusers = EXCLUDED.policyusers,
    policyroles = EXCLUDED.policyroles,
    versions = EXCLUDED.versions,
    _account_id = EXCLUDED._account_id
  ;



INSERT INTO aws_iam_policy_user
SELECT
  aws_iam_policy.id AS policy_id,
  aws_iam_user.id AS user_id,
  aws_iam_policy.provider_account_id AS provider_account_id
FROM
  resource AS aws_iam_policy
  INNER JOIN resource_relation AS RR
    ON RR.resource_id = aws_iam_policy.id
    AND RR.relation = 'manages'
  INNER JOIN resource AS aws_iam_user
    ON aws_iam_user.id = RR.target_id
    AND aws_iam_user.provider_type = 'User'
    AND aws_iam_user.service = 'iam'
  WHERE
    aws_iam_policy.provider_type = 'Policy'
    AND aws_iam_policy.service = 'iam'
ON CONFLICT (policy_id, user_id)
DO NOTHING
;


INSERT INTO aws_iam_policy_role
SELECT
  aws_iam_policy.id AS policy_id,
  aws_iam_role.id AS role_id,
  aws_iam_policy.provider_account_id AS provider_account_id
FROM
  resource AS aws_iam_policy
  INNER JOIN resource_relation AS RR
    ON RR.resource_id = aws_iam_policy.id
    AND RR.relation = 'manages'
  INNER JOIN resource AS aws_iam_role
    ON aws_iam_role.id = RR.target_id
    AND aws_iam_role.provider_type = 'Role'
    AND aws_iam_role.service = 'iam'
  WHERE
    aws_iam_policy.provider_type = 'Policy'
    AND aws_iam_policy.service = 'iam'
ON CONFLICT (policy_id, role_id)
DO NOTHING
;


INSERT INTO aws_iam_policy_group
SELECT
  aws_iam_policy.id AS policy_id,
  aws_iam_group.id AS group_id,
  aws_iam_policy.provider_account_id AS provider_account_id
FROM
  resource AS aws_iam_policy
  INNER JOIN resource_relation AS RR
    ON RR.resource_id = aws_iam_policy.id
    AND RR.relation = 'manages'
  INNER JOIN resource AS aws_iam_group
    ON aws_iam_group.id = RR.target_id
    AND aws_iam_group.provider_type = 'Group'
    AND aws_iam_group.service = 'iam'
  WHERE
    aws_iam_policy.provider_type = 'Policy'
    AND aws_iam_policy.service = 'iam'
ON CONFLICT (policy_id, group_id)
DO NOTHING
;

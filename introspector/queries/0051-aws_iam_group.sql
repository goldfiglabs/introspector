INSERT INTO aws_iam_group (
  _id,
  uri,
  provider_account_id,
  path,
  groupname,
  groupid,
  arn,
  createdate,
  policylist,
  attachedpolicies,
  _account_id
)
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  path.attr_value #>> '{}' AS path,
  groupname.attr_value #>> '{}' AS groupname,
  groupid.attr_value #>> '{}' AS groupid,
  arn.attr_value #>> '{}' AS arn,
  (TO_TIMESTAMP(createdate.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS createdate,
  policylist.attr_value::jsonb AS policylist,
  attachedpolicies.attr_value::jsonb AS attachedpolicies,
  
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN resource_attribute AS path
    ON path.resource_id = R.id
    AND path.type = 'provider'
    AND lower(path.attr_name) = 'path'
  LEFT JOIN resource_attribute AS groupname
    ON groupname.resource_id = R.id
    AND groupname.type = 'provider'
    AND lower(groupname.attr_name) = 'groupname'
  LEFT JOIN resource_attribute AS groupid
    ON groupid.resource_id = R.id
    AND groupid.type = 'provider'
    AND lower(groupid.attr_name) = 'groupid'
  LEFT JOIN resource_attribute AS arn
    ON arn.resource_id = R.id
    AND arn.type = 'provider'
    AND lower(arn.attr_name) = 'arn'
  LEFT JOIN resource_attribute AS createdate
    ON createdate.resource_id = R.id
    AND createdate.type = 'provider'
    AND lower(createdate.attr_name) = 'createdate'
  LEFT JOIN resource_attribute AS policylist
    ON policylist.resource_id = R.id
    AND policylist.type = 'provider'
    AND lower(policylist.attr_name) = 'policylist'
  LEFT JOIN resource_attribute AS attachedpolicies
    ON attachedpolicies.resource_id = R.id
    AND attachedpolicies.type = 'provider'
    AND lower(attachedpolicies.attr_name) = 'attachedpolicies'
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
      GROUP BY _aws_organizations_account_relation.resource_id
      HAVING COUNT(*) = 1
    ) AS unique_account_mapping
    INNER JOIN resource_relation AS _aws_organizations_account_relation
      ON _aws_organizations_account_relation.resource_id = unique_account_mapping.resource_id
    INNER JOIN resource AS _aws_organizations_account
      ON _aws_organizations_account_relation.target_id = _aws_organizations_account.id
      AND _aws_organizations_account.provider_type = 'Account'
      AND _aws_organizations_account.service = 'organizations'
    WHERE
        _aws_organizations_account_relation.relation = 'in'
  ) AS _account_id ON _account_id.resource_id = R.id
  WHERE
  PA.provider = 'aws'
  AND R.provider_type = 'Group'
  AND R.service = 'iam'
ON CONFLICT (_id) DO UPDATE
SET
    path = EXCLUDED.path,
    groupname = EXCLUDED.groupname,
    groupid = EXCLUDED.groupid,
    arn = EXCLUDED.arn,
    createdate = EXCLUDED.createdate,
    policylist = EXCLUDED.policylist,
    attachedpolicies = EXCLUDED.attachedpolicies,
    _account_id = EXCLUDED._account_id
  ;



INSERT INTO aws_iam_group_user
SELECT
  aws_iam_group.id AS group_id,
  aws_iam_user.id AS user_id,
  aws_iam_group.provider_account_id AS provider_account_id
FROM
  resource AS aws_iam_group
  INNER JOIN resource_relation AS RR
    ON RR.resource_id = aws_iam_group.id
    AND RR.relation = 'contains'
  INNER JOIN resource AS aws_iam_user
    ON aws_iam_user.id = RR.target_id
    AND aws_iam_user.provider_type = 'User'
    AND aws_iam_user.service = 'iam'
  WHERE
    aws_iam_group.provider_type = 'Group'
    AND aws_iam_group.service = 'iam'
ON CONFLICT (group_id, user_id)
DO NOTHING
;

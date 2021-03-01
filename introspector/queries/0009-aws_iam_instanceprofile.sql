INSERT INTO aws_iam_instanceprofile (
  _id,
  uri,
  provider_account_id,
  path,
  instanceprofilename,
  instanceprofileid,
  arn,
  createdate,
  roles,
  _role_id,_account_id
)
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  path.attr_value #>> '{}' AS path,
  instanceprofilename.attr_value #>> '{}' AS instanceprofilename,
  instanceprofileid.attr_value #>> '{}' AS instanceprofileid,
  arn.attr_value #>> '{}' AS arn,
  (TO_TIMESTAMP(createdate.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS createdate,
  roles.attr_value::jsonb AS roles,
  
    _role_id.target_id AS _role_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN resource_attribute AS path
    ON path.resource_id = R.id
    AND path.type = 'provider'
    AND lower(path.attr_name) = 'path'
  LEFT JOIN resource_attribute AS instanceprofilename
    ON instanceprofilename.resource_id = R.id
    AND instanceprofilename.type = 'provider'
    AND lower(instanceprofilename.attr_name) = 'instanceprofilename'
  LEFT JOIN resource_attribute AS instanceprofileid
    ON instanceprofileid.resource_id = R.id
    AND instanceprofileid.type = 'provider'
    AND lower(instanceprofileid.attr_name) = 'instanceprofileid'
  LEFT JOIN resource_attribute AS arn
    ON arn.resource_id = R.id
    AND arn.type = 'provider'
    AND lower(arn.attr_name) = 'arn'
  LEFT JOIN resource_attribute AS createdate
    ON createdate.resource_id = R.id
    AND createdate.type = 'provider'
    AND lower(createdate.attr_name) = 'createdate'
  LEFT JOIN resource_attribute AS roles
    ON roles.resource_id = R.id
    AND roles.type = 'provider'
    AND lower(roles.attr_name) = 'roles'
  LEFT JOIN (
    SELECT
      _aws_iam_role_relation.resource_id AS resource_id,
      _aws_iam_role.id AS target_id
    FROM
      resource_relation AS _aws_iam_role_relation
      INNER JOIN resource AS _aws_iam_role
        ON _aws_iam_role_relation.target_id = _aws_iam_role.id
        AND _aws_iam_role.provider_type = 'Role'
        AND _aws_iam_role.service = 'iam'
    WHERE
      _aws_iam_role_relation.relation = 'contains'
  ) AS _role_id ON _role_id.resource_id = R.id
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
  AND R.provider_type = 'InstanceProfile'
  AND R.service = 'iam'
ON CONFLICT (_id) DO UPDATE
SET
    path = EXCLUDED.path,
    instanceprofilename = EXCLUDED.instanceprofilename,
    instanceprofileid = EXCLUDED.instanceprofileid,
    arn = EXCLUDED.arn,
    createdate = EXCLUDED.createdate,
    roles = EXCLUDED.roles,
    _role_id = EXCLUDED._role_id,
    _account_id = EXCLUDED._account_id
  ;


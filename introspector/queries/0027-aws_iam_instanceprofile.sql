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
  attrs.provider ->> 'Path' AS path,
  attrs.provider ->> 'InstanceProfileName' AS instanceprofilename,
  attrs.provider ->> 'InstanceProfileId' AS instanceprofileid,
  attrs.provider ->> 'Arn' AS arn,
  (TO_TIMESTAMP(attrs.provider ->> 'CreateDate', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS createdate,
  attrs.provider -> 'Roles' AS roles,
  
    _role_id.target_id AS _role_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  LEFT JOIN attrs ON
    attrs.resource_id = R.id
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
        AND _aws_iam_role.provider_account_id = :provider_account_id
    WHERE
      _aws_iam_role_relation.relation = 'contains'
      AND _aws_iam_role_relation.provider_account_id = :provider_account_id
  ) AS _role_id ON _role_id.resource_id = R.id
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
          AND _aws_organizations_account_relation.provider_account_id = :provider_account_id
        GROUP BY _aws_organizations_account_relation.resource_id
        HAVING COUNT(*) = 1
      ) AS unique_account_mapping
  ) AS _account_id ON _account_id.resource_id = R.id
  WHERE
  R.provider_account_id = :provider_account_id
  AND R.provider_type = 'InstanceProfile'
  AND R.service = 'iam'
ON CONFLICT (_id) DO UPDATE
SET
    Path = EXCLUDED.Path,
    InstanceProfileName = EXCLUDED.InstanceProfileName,
    InstanceProfileId = EXCLUDED.InstanceProfileId,
    Arn = EXCLUDED.Arn,
    CreateDate = EXCLUDED.CreateDate,
    Roles = EXCLUDED.Roles,
    _role_id = EXCLUDED._role_id,
    _account_id = EXCLUDED._account_id
  ;


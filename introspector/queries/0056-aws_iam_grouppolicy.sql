INSERT INTO aws_iam_grouppolicy (
  _id,
  uri,
  provider_account_id,
  groupname,
  policyname,
  policydocument,
  _group_id,_account_id
)
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  groupname.attr_value #>> '{}' AS groupname,
  policyname.attr_value #>> '{}' AS policyname,
  policydocument.attr_value::jsonb AS policydocument,
  
    _group_id.target_id AS _group_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN resource_attribute AS groupname
    ON groupname.resource_id = R.id
    AND groupname.type = 'provider'
    AND lower(groupname.attr_name) = 'groupname'
  LEFT JOIN resource_attribute AS policyname
    ON policyname.resource_id = R.id
    AND policyname.type = 'provider'
    AND lower(policyname.attr_name) = 'policyname'
  LEFT JOIN resource_attribute AS policydocument
    ON policydocument.resource_id = R.id
    AND policydocument.type = 'provider'
    AND lower(policydocument.attr_name) = 'policydocument'
  LEFT JOIN (
    SELECT
      _aws_iam_group_relation.resource_id AS resource_id,
      _aws_iam_group.id AS target_id
    FROM
      resource_relation AS _aws_iam_group_relation
      INNER JOIN resource AS _aws_iam_group
        ON _aws_iam_group_relation.target_id = _aws_iam_group.id
        AND _aws_iam_group.provider_type = 'Group'
        AND _aws_iam_group.service = 'iam'
    WHERE
      _aws_iam_group_relation.relation = 'manages'
  ) AS _group_id ON _group_id.resource_id = R.id
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
  AND R.provider_type = 'GroupPolicy'
  AND R.service = 'iam'
ON CONFLICT (_id) DO UPDATE
SET
    groupname = EXCLUDED.groupname,
    policyname = EXCLUDED.policyname,
    policydocument = EXCLUDED.policydocument,
    _group_id = EXCLUDED._group_id,
    _account_id = EXCLUDED._account_id
  ;


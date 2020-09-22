DROP MATERIALIZED VIEW IF EXISTS aws_iam_grouppolicy CASCADE;

CREATE MATERIALIZED VIEW aws_iam_grouppolicy AS
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
  groupname.attr_value #>> '{}' AS groupname,
  policyname.attr_value #>> '{}' AS policyname,
  policydocument.attr_value::jsonb AS policydocument,
  
    _group_id.target_id AS _group_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN attrs AS groupname
    ON groupname.id = R.id
    AND groupname.attr_name = 'groupname'
  LEFT JOIN attrs AS policyname
    ON policyname.id = R.id
    AND policyname.attr_name = 'policyname'
  LEFT JOIN attrs AS policydocument
    ON policydocument.id = R.id
    AND policydocument.attr_name = 'policydocument'
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
  AND LOWER(R.provider_type) = 'grouppolicy'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_iam_grouppolicy;

COMMENT ON MATERIALIZED VIEW aws_iam_grouppolicy IS 'iam grouppolicy resources and their associated attributes.';


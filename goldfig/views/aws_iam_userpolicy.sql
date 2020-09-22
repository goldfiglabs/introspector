DROP MATERIALIZED VIEW IF EXISTS aws_iam_userpolicy CASCADE;

CREATE MATERIALIZED VIEW aws_iam_userpolicy AS
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
  username.attr_value #>> '{}' AS username,
  policyname.attr_value #>> '{}' AS policyname,
  policydocument.attr_value::jsonb AS policydocument,
  
    _user_id.target_id AS _user_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN attrs AS username
    ON username.id = R.id
    AND username.attr_name = 'username'
  LEFT JOIN attrs AS policyname
    ON policyname.id = R.id
    AND policyname.attr_name = 'policyname'
  LEFT JOIN attrs AS policydocument
    ON policydocument.id = R.id
    AND policydocument.attr_name = 'policydocument'
  LEFT JOIN (
    SELECT
      _aws_iam_user_relation.resource_id AS resource_id,
      _aws_iam_user.id AS target_id
    FROM
      resource_relation AS _aws_iam_user_relation
      INNER JOIN resource AS _aws_iam_user
        ON _aws_iam_user_relation.target_id = _aws_iam_user.id
        AND _aws_iam_user.provider_type = 'User'
        AND _aws_iam_user.service = 'iam'
    WHERE
      _aws_iam_user_relation.relation = 'manages'
  ) AS _user_id ON _user_id.resource_id = R.id
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
  AND LOWER(R.provider_type) = 'userpolicy'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_iam_userpolicy;

COMMENT ON MATERIALIZED VIEW aws_iam_userpolicy IS 'iam userpolicy resources and their associated attributes.';


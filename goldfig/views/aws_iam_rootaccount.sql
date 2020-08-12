DROP MATERIALIZED VIEW IF EXISTS aws_iam_rootaccount CASCADE;

CREATE MATERIALIZED VIEW aws_iam_rootaccount AS
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
  Arn.attr_value #>> '{}' AS arn,
  mfa_active.attr_value::boolean AS mfa_active,
  access_key_1_active.attr_value::boolean AS access_key_1_active,
  access_key_2_active.attr_value::boolean AS access_key_2_active,
  cert_1_active.attr_value::boolean AS cert_1_active,
  cert_2_active.attr_value::boolean AS cert_2_active,
  
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN attrs AS Arn
    ON Arn.id = R.id
    AND Arn.attr_name = 'arn'
  LEFT JOIN attrs AS mfa_active
    ON mfa_active.id = R.id
    AND mfa_active.attr_name = 'mfa_active'
  LEFT JOIN attrs AS access_key_1_active
    ON access_key_1_active.id = R.id
    AND access_key_1_active.attr_name = 'access_key_1_active'
  LEFT JOIN attrs AS access_key_2_active
    ON access_key_2_active.id = R.id
    AND access_key_2_active.attr_name = 'access_key_2_active'
  LEFT JOIN attrs AS cert_1_active
    ON cert_1_active.id = R.id
    AND cert_1_active.attr_name = 'cert_1_active'
  LEFT JOIN attrs AS cert_2_active
    ON cert_2_active.id = R.id
    AND cert_2_active.attr_name = 'cert_2_active'
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
  AND LOWER(R.provider_type) = 'rootaccount'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_iam_rootaccount;

COMMENT ON MATERIALIZED VIEW aws_iam_rootaccount IS 'iam rootaccount resources and their associated attributes.';


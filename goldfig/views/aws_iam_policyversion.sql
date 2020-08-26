DROP MATERIALIZED VIEW IF EXISTS aws_iam_policyversion CASCADE;

CREATE MATERIALIZED VIEW aws_iam_policyversion AS
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
  document.attr_value #>> '{}' AS document,
  versionid.attr_value #>> '{}' AS versionid,
  (isdefaultversion.attr_value #>> '{}')::boolean AS isdefaultversion,
  (TO_TIMESTAMP(createdate.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS createdate,
  
    _policy_id.target_id AS _policy_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN attrs AS document
    ON document.id = R.id
    AND document.attr_name = 'document'
  LEFT JOIN attrs AS versionid
    ON versionid.id = R.id
    AND versionid.attr_name = 'versionid'
  LEFT JOIN attrs AS isdefaultversion
    ON isdefaultversion.id = R.id
    AND isdefaultversion.attr_name = 'isdefaultversion'
  LEFT JOIN attrs AS createdate
    ON createdate.id = R.id
    AND createdate.attr_name = 'createdate'
  LEFT JOIN (
    SELECT
      _aws_iam_policy_relation.resource_id AS resource_id,
      _aws_iam_policy.id AS target_id
    FROM
      resource_relation AS _aws_iam_policy_relation
      INNER JOIN resource AS _aws_iam_policy
        ON _aws_iam_policy_relation.target_id = _aws_iam_policy.id
        AND _aws_iam_policy.provider_type = 'Policy'
        AND _aws_iam_policy.service = 'iam'
    WHERE
      _aws_iam_policy_relation.relation = 'contains-version'
  ) AS _policy_id ON _policy_id.resource_id = R.id
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
  AND LOWER(R.provider_type) = 'policyversion'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_iam_policyversion;

COMMENT ON MATERIALIZED VIEW aws_iam_policyversion IS 'iam policyversion resources and their associated attributes.';


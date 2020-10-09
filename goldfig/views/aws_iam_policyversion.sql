DROP MATERIALIZED VIEW IF EXISTS aws_iam_policyversion CASCADE;

CREATE MATERIALIZED VIEW aws_iam_policyversion AS
SELECT
  R.id AS resource_id,
  R.uri,
  R.provider_account_id,
  document.attr_value::jsonb AS document,
  versionid.attr_value #>> '{}' AS versionid,
  (isdefaultversion.attr_value #>> '{}')::boolean AS isdefaultversion,
  (TO_TIMESTAMP(createdate.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS createdate,
  
    _policy_id.target_id AS _policy_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN resource_attribute AS document
    ON document.resource_id = R.id
    AND document.type = 'provider'
    AND lower(document.attr_name) = 'document'
  LEFT JOIN resource_attribute AS versionid
    ON versionid.resource_id = R.id
    AND versionid.type = 'provider'
    AND lower(versionid.attr_name) = 'versionid'
  LEFT JOIN resource_attribute AS isdefaultversion
    ON isdefaultversion.resource_id = R.id
    AND isdefaultversion.type = 'provider'
    AND lower(isdefaultversion.attr_name) = 'isdefaultversion'
  LEFT JOIN resource_attribute AS createdate
    ON createdate.resource_id = R.id
    AND createdate.type = 'provider'
    AND lower(createdate.attr_name) = 'createdate'
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
  AND R.service = 'iam'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_iam_policyversion;

COMMENT ON MATERIALIZED VIEW aws_iam_policyversion IS 'iam policyversion resources and their associated attributes.';


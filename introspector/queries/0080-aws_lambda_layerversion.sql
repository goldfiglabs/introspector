INSERT INTO aws_lambda_layerversion (
  _id,
  uri,
  provider_account_id,
  layerversionarn,
  version,
  description,
  createddate,
  compatibleruntimes,
  licenseinfo,
  policy,
  name,
  _policy,
  _account_id
)
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  layerversionarn.attr_value #>> '{}' AS layerversionarn,
  (version.attr_value #>> '{}')::bigint AS version,
  description.attr_value #>> '{}' AS description,
  createddate.attr_value #>> '{}' AS createddate,
  compatibleruntimes.attr_value::jsonb AS compatibleruntimes,
  licenseinfo.attr_value #>> '{}' AS licenseinfo,
  policy.attr_value::jsonb AS policy,
  name.attr_value #>> '{}' AS name,
  _policy.attr_value::jsonb AS _policy,
  
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN resource_attribute AS layerversionarn
    ON layerversionarn.resource_id = R.id
    AND layerversionarn.type = 'provider'
    AND lower(layerversionarn.attr_name) = 'layerversionarn'
    AND layerversionarn.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS version
    ON version.resource_id = R.id
    AND version.type = 'provider'
    AND lower(version.attr_name) = 'version'
    AND version.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS description
    ON description.resource_id = R.id
    AND description.type = 'provider'
    AND lower(description.attr_name) = 'description'
    AND description.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS createddate
    ON createddate.resource_id = R.id
    AND createddate.type = 'provider'
    AND lower(createddate.attr_name) = 'createddate'
    AND createddate.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS compatibleruntimes
    ON compatibleruntimes.resource_id = R.id
    AND compatibleruntimes.type = 'provider'
    AND lower(compatibleruntimes.attr_name) = 'compatibleruntimes'
    AND compatibleruntimes.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS licenseinfo
    ON licenseinfo.resource_id = R.id
    AND licenseinfo.type = 'provider'
    AND lower(licenseinfo.attr_name) = 'licenseinfo'
    AND licenseinfo.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS policy
    ON policy.resource_id = R.id
    AND policy.type = 'provider'
    AND lower(policy.attr_name) = 'policy'
    AND policy.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS name
    ON name.resource_id = R.id
    AND name.type = 'provider'
    AND lower(name.attr_name) = 'name'
    AND name.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS _policy
    ON _policy.resource_id = R.id
    AND _policy.type = 'Metadata'
    AND lower(_policy.attr_name) = 'policy'
    AND _policy.provider_account_id = R.provider_account_id
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
  AND R.provider_type = 'LayerVersion'
  AND R.service = 'lambda'
ON CONFLICT (_id) DO UPDATE
SET
    layerversionarn = EXCLUDED.layerversionarn,
    version = EXCLUDED.version,
    description = EXCLUDED.description,
    createddate = EXCLUDED.createddate,
    compatibleruntimes = EXCLUDED.compatibleruntimes,
    licenseinfo = EXCLUDED.licenseinfo,
    policy = EXCLUDED.policy,
    name = EXCLUDED.name,
    _policy = EXCLUDED._policy,
    _account_id = EXCLUDED._account_id
  ;


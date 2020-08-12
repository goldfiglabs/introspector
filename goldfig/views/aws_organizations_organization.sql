DROP MATERIALIZED VIEW IF EXISTS aws_organizations_organization CASCADE;

CREATE MATERIALIZED VIEW aws_organizations_organization AS
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
  id.attr_value #>> '{}' AS id,
  arn.attr_value #>> '{}' AS arn,
  featureset.attr_value #>> '{}' AS featureset,
  masteraccountarn.attr_value #>> '{}' AS masteraccountarn,
  masteraccountid.attr_value #>> '{}' AS masteraccountid,
  masteraccountemail.attr_value #>> '{}' AS masteraccountemail,
  availablepolicytypes.attr_value::jsonb AS availablepolicytypes,
  servicecontrolpolicies.attr_value::jsonb AS servicecontrolpolicies,
  tagpolicies.attr_value::jsonb AS tagpolicies
  
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN attrs AS id
    ON id.id = R.id
    AND id.attr_name = 'id'
  LEFT JOIN attrs AS arn
    ON arn.id = R.id
    AND arn.attr_name = 'arn'
  LEFT JOIN attrs AS featureset
    ON featureset.id = R.id
    AND featureset.attr_name = 'featureset'
  LEFT JOIN attrs AS masteraccountarn
    ON masteraccountarn.id = R.id
    AND masteraccountarn.attr_name = 'masteraccountarn'
  LEFT JOIN attrs AS masteraccountid
    ON masteraccountid.id = R.id
    AND masteraccountid.attr_name = 'masteraccountid'
  LEFT JOIN attrs AS masteraccountemail
    ON masteraccountemail.id = R.id
    AND masteraccountemail.attr_name = 'masteraccountemail'
  LEFT JOIN attrs AS availablepolicytypes
    ON availablepolicytypes.id = R.id
    AND availablepolicytypes.attr_name = 'availablepolicytypes'
  LEFT JOIN attrs AS servicecontrolpolicies
    ON servicecontrolpolicies.id = R.id
    AND servicecontrolpolicies.attr_name = 'servicecontrolpolicies'
  LEFT JOIN attrs AS tagpolicies
    ON tagpolicies.id = R.id
    AND tagpolicies.attr_name = 'tagpolicies'
  WHERE
  PA.provider = 'aws'
  AND LOWER(R.provider_type) = 'organization'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_organizations_organization;

COMMENT ON MATERIALIZED VIEW aws_organizations_organization IS 'organizations organization resources and their associated attributes.';


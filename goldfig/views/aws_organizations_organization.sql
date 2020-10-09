DROP MATERIALIZED VIEW IF EXISTS aws_organizations_organization CASCADE;

CREATE MATERIALIZED VIEW aws_organizations_organization AS
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
  LEFT JOIN resource_attribute AS id
    ON id.resource_id = R.id
    AND id.type = 'provider'
    AND lower(id.attr_name) = 'id'
  LEFT JOIN resource_attribute AS arn
    ON arn.resource_id = R.id
    AND arn.type = 'provider'
    AND lower(arn.attr_name) = 'arn'
  LEFT JOIN resource_attribute AS featureset
    ON featureset.resource_id = R.id
    AND featureset.type = 'provider'
    AND lower(featureset.attr_name) = 'featureset'
  LEFT JOIN resource_attribute AS masteraccountarn
    ON masteraccountarn.resource_id = R.id
    AND masteraccountarn.type = 'provider'
    AND lower(masteraccountarn.attr_name) = 'masteraccountarn'
  LEFT JOIN resource_attribute AS masteraccountid
    ON masteraccountid.resource_id = R.id
    AND masteraccountid.type = 'provider'
    AND lower(masteraccountid.attr_name) = 'masteraccountid'
  LEFT JOIN resource_attribute AS masteraccountemail
    ON masteraccountemail.resource_id = R.id
    AND masteraccountemail.type = 'provider'
    AND lower(masteraccountemail.attr_name) = 'masteraccountemail'
  LEFT JOIN resource_attribute AS availablepolicytypes
    ON availablepolicytypes.resource_id = R.id
    AND availablepolicytypes.type = 'provider'
    AND lower(availablepolicytypes.attr_name) = 'availablepolicytypes'
  LEFT JOIN resource_attribute AS servicecontrolpolicies
    ON servicecontrolpolicies.resource_id = R.id
    AND servicecontrolpolicies.type = 'provider'
    AND lower(servicecontrolpolicies.attr_name) = 'servicecontrolpolicies'
  LEFT JOIN resource_attribute AS tagpolicies
    ON tagpolicies.resource_id = R.id
    AND tagpolicies.type = 'provider'
    AND lower(tagpolicies.attr_name) = 'tagpolicies'
  WHERE
  PA.provider = 'aws'
  AND LOWER(R.provider_type) = 'organization'
  AND R.service = 'organizations'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_organizations_organization;

COMMENT ON MATERIALIZED VIEW aws_organizations_organization IS 'organizations organization resources and their associated attributes.';


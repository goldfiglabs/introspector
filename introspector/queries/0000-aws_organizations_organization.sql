INSERT INTO aws_organizations_organization (
  _id,
  uri,
  provider_account_id,
  id,
  arn,
  featureset,
  masteraccountarn,
  masteraccountid,
  masteraccountemail,
  availablepolicytypes,
  servicecontrolpolicies,
  tagpolicies
  
)
SELECT
  R.id AS _id,
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
    AND id.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS arn
    ON arn.resource_id = R.id
    AND arn.type = 'provider'
    AND lower(arn.attr_name) = 'arn'
    AND arn.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS featureset
    ON featureset.resource_id = R.id
    AND featureset.type = 'provider'
    AND lower(featureset.attr_name) = 'featureset'
    AND featureset.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS masteraccountarn
    ON masteraccountarn.resource_id = R.id
    AND masteraccountarn.type = 'provider'
    AND lower(masteraccountarn.attr_name) = 'masteraccountarn'
    AND masteraccountarn.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS masteraccountid
    ON masteraccountid.resource_id = R.id
    AND masteraccountid.type = 'provider'
    AND lower(masteraccountid.attr_name) = 'masteraccountid'
    AND masteraccountid.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS masteraccountemail
    ON masteraccountemail.resource_id = R.id
    AND masteraccountemail.type = 'provider'
    AND lower(masteraccountemail.attr_name) = 'masteraccountemail'
    AND masteraccountemail.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS availablepolicytypes
    ON availablepolicytypes.resource_id = R.id
    AND availablepolicytypes.type = 'provider'
    AND lower(availablepolicytypes.attr_name) = 'availablepolicytypes'
    AND availablepolicytypes.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS servicecontrolpolicies
    ON servicecontrolpolicies.resource_id = R.id
    AND servicecontrolpolicies.type = 'provider'
    AND lower(servicecontrolpolicies.attr_name) = 'servicecontrolpolicies'
    AND servicecontrolpolicies.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS tagpolicies
    ON tagpolicies.resource_id = R.id
    AND tagpolicies.type = 'provider'
    AND lower(tagpolicies.attr_name) = 'tagpolicies'
    AND tagpolicies.provider_account_id = R.provider_account_id
  WHERE
  R.provider_account_id = :provider_account_id
  AND PA.provider = 'aws'
  AND R.provider_type = 'Organization'
  AND R.service = 'organizations'
ON CONFLICT (_id) DO UPDATE
SET
    id = EXCLUDED.id,
    arn = EXCLUDED.arn,
    featureset = EXCLUDED.featureset,
    masteraccountarn = EXCLUDED.masteraccountarn,
    masteraccountid = EXCLUDED.masteraccountid,
    masteraccountemail = EXCLUDED.masteraccountemail,
    availablepolicytypes = EXCLUDED.availablepolicytypes,
    servicecontrolpolicies = EXCLUDED.servicecontrolpolicies,
    tagpolicies = EXCLUDED.tagpolicies
  ;


WITH attrs AS (
  SELECT
    resource_id,
    jsonb_object_agg(attr_name, attr_value) FILTER (WHERE type = 'provider') AS provider,
    jsonb_object_agg(attr_name, attr_value) FILTER (WHERE type = 'Metadata') AS metadata
  FROM
    resource_attribute
  WHERE
    provider_account_id = :provider_account_id
  GROUP BY resource_id
)
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
  attrs.provider ->> 'Id' AS id,
  attrs.provider ->> 'Arn' AS arn,
  attrs.provider ->> 'FeatureSet' AS featureset,
  attrs.provider ->> 'MasterAccountArn' AS masteraccountarn,
  attrs.provider ->> 'MasterAccountId' AS masteraccountid,
  attrs.provider ->> 'MasterAccountEmail' AS masteraccountemail,
  attrs.provider -> 'AvailablePolicyTypes' AS availablepolicytypes,
  attrs.provider -> 'ServiceControlPolicies' AS servicecontrolpolicies,
  attrs.provider -> 'TagPolicies' AS tagpolicies
  
FROM
  resource AS R
  LEFT JOIN attrs ON
    attrs.resource_id = R.id
  WHERE
  R.provider_account_id = :provider_account_id
  AND R.provider_type = 'Organization'
  AND R.service = 'organizations'
ON CONFLICT (_id) DO UPDATE
SET
    Id = EXCLUDED.Id,
    Arn = EXCLUDED.Arn,
    FeatureSet = EXCLUDED.FeatureSet,
    MasterAccountArn = EXCLUDED.MasterAccountArn,
    MasterAccountId = EXCLUDED.MasterAccountId,
    MasterAccountEmail = EXCLUDED.MasterAccountEmail,
    AvailablePolicyTypes = EXCLUDED.AvailablePolicyTypes,
    ServiceControlPolicies = EXCLUDED.ServiceControlPolicies,
    TagPolicies = EXCLUDED.TagPolicies
  ;


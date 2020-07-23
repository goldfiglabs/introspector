DROP MATERIALIZED VIEW IF EXISTS aws_organizations_account CASCADE;

CREATE MATERIALIZED VIEW aws_organizations_account AS
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
  email.attr_value #>> '{}' AS email,
  name.attr_value #>> '{}' AS name,
  status.attr_value #>> '{}' AS status,
  joinedmethod.attr_value #>> '{}' AS joinedmethod,
  joinedtimestamp.attr_value AS joinedtimestamp,
  servicecontrolpolicies.attr_value::jsonb AS servicecontrolpolicies,
  tagpolicies.attr_value::jsonb AS tagpolicies,
  tags.attr_value::jsonb AS tags
  
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
  LEFT JOIN attrs AS email
    ON email.id = R.id
    AND email.attr_name = 'email'
  LEFT JOIN attrs AS name
    ON name.id = R.id
    AND name.attr_name = 'name'
  LEFT JOIN attrs AS status
    ON status.id = R.id
    AND status.attr_name = 'status'
  LEFT JOIN attrs AS joinedmethod
    ON joinedmethod.id = R.id
    AND joinedmethod.attr_name = 'joinedmethod'
  LEFT JOIN attrs AS joinedtimestamp
    ON joinedtimestamp.id = R.id
    AND joinedtimestamp.attr_name = 'joinedtimestamp'
  LEFT JOIN attrs AS servicecontrolpolicies
    ON servicecontrolpolicies.id = R.id
    AND servicecontrolpolicies.attr_name = 'servicecontrolpolicies'
  LEFT JOIN attrs AS tagpolicies
    ON tagpolicies.id = R.id
    AND tagpolicies.attr_name = 'tagpolicies'
  LEFT JOIN attrs AS tags
    ON tags.id = R.id
    AND tags.attr_name = 'tags'
  WHERE
  PA.provider = 'aws'
  AND LOWER(R.provider_type) = 'account'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_organizations_account;

COMMENT ON MATERIALIZED VIEW aws_organizations_account IS 'organizations account resources and their associated attributes.';
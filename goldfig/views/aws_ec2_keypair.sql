DROP MATERIALIZED VIEW IF EXISTS aws_ec2_keypair CASCADE;

CREATE MATERIALIZED VIEW aws_ec2_keypair AS
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
  keypairid.attr_value #>> '{}' AS keypairid,
  keyfingerprint.attr_value #>> '{}' AS keyfingerprint,
  keyname.attr_value #>> '{}' AS keyname,
  tags.attr_value::jsonb AS tags
  
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN attrs AS keypairid
    ON keypairid.id = R.id
    AND keypairid.attr_name = 'keypairid'
  LEFT JOIN attrs AS keyfingerprint
    ON keyfingerprint.id = R.id
    AND keyfingerprint.attr_name = 'keyfingerprint'
  LEFT JOIN attrs AS keyname
    ON keyname.id = R.id
    AND keyname.attr_name = 'keyname'
  LEFT JOIN attrs AS tags
    ON tags.id = R.id
    AND tags.attr_name = 'tags'
  WHERE
  PA.provider = 'aws'
  AND LOWER(R.provider_type) = 'keypair'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_ec2_keypair;

COMMENT ON MATERIALIZED VIEW aws_ec2_keypair IS 'ec2 keypair resources and their associated attributes.';
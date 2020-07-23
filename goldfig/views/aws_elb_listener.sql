DROP MATERIALIZED VIEW IF EXISTS aws_elb_listener CASCADE;

CREATE MATERIALIZED VIEW aws_elb_listener AS
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
  protocol.attr_value #>> '{}' AS protocol,
  loadbalancerport.attr_value::integer AS loadbalancerport,
  instanceprotocol.attr_value #>> '{}' AS instanceprotocol,
  instanceport.attr_value::integer AS instanceport,
  sslcertificateid.attr_value #>> '{}' AS sslcertificateid,
  policynames.attr_value::jsonb AS policynames
  
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN attrs AS protocol
    ON protocol.id = R.id
    AND protocol.attr_name = 'protocol'
  LEFT JOIN attrs AS loadbalancerport
    ON loadbalancerport.id = R.id
    AND loadbalancerport.attr_name = 'loadbalancerport'
  LEFT JOIN attrs AS instanceprotocol
    ON instanceprotocol.id = R.id
    AND instanceprotocol.attr_name = 'instanceprotocol'
  LEFT JOIN attrs AS instanceport
    ON instanceport.id = R.id
    AND instanceport.attr_name = 'instanceport'
  LEFT JOIN attrs AS sslcertificateid
    ON sslcertificateid.id = R.id
    AND sslcertificateid.attr_name = 'sslcertificateid'
  LEFT JOIN attrs AS policynames
    ON policynames.id = R.id
    AND policynames.attr_name = 'policynames'
  WHERE
  PA.provider = 'aws'
  AND LOWER(R.provider_type) = 'listener'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_elb_listener;

COMMENT ON MATERIALIZED VIEW aws_elb_listener IS 'elb listener resources and their associated attributes.';
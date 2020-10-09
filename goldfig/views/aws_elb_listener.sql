DROP MATERIALIZED VIEW IF EXISTS aws_elb_listener CASCADE;

CREATE MATERIALIZED VIEW aws_elb_listener AS
SELECT
  R.id AS resource_id,
  R.uri,
  R.provider_account_id,
  protocol.attr_value #>> '{}' AS protocol,
  (loadbalancerport.attr_value #>> '{}')::integer AS loadbalancerport,
  instanceprotocol.attr_value #>> '{}' AS instanceprotocol,
  (instanceport.attr_value #>> '{}')::integer AS instanceport,
  sslcertificateid.attr_value #>> '{}' AS sslcertificateid,
  policynames.attr_value::jsonb AS policynames,
  
    _loadbalancer_id.target_id AS _loadbalancer_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN resource_attribute AS protocol
    ON protocol.resource_id = R.id
    AND protocol.type = 'provider'
    AND lower(protocol.attr_name) = 'protocol'
  LEFT JOIN resource_attribute AS loadbalancerport
    ON loadbalancerport.resource_id = R.id
    AND loadbalancerport.type = 'provider'
    AND lower(loadbalancerport.attr_name) = 'loadbalancerport'
  LEFT JOIN resource_attribute AS instanceprotocol
    ON instanceprotocol.resource_id = R.id
    AND instanceprotocol.type = 'provider'
    AND lower(instanceprotocol.attr_name) = 'instanceprotocol'
  LEFT JOIN resource_attribute AS instanceport
    ON instanceport.resource_id = R.id
    AND instanceport.type = 'provider'
    AND lower(instanceport.attr_name) = 'instanceport'
  LEFT JOIN resource_attribute AS sslcertificateid
    ON sslcertificateid.resource_id = R.id
    AND sslcertificateid.type = 'provider'
    AND lower(sslcertificateid.attr_name) = 'sslcertificateid'
  LEFT JOIN resource_attribute AS policynames
    ON policynames.resource_id = R.id
    AND policynames.type = 'provider'
    AND lower(policynames.attr_name) = 'policynames'
  LEFT JOIN (
    SELECT
      _aws_elb_loadbalancer_relation.resource_id AS resource_id,
      _aws_elb_loadbalancer.id AS target_id
    FROM
      resource_relation AS _aws_elb_loadbalancer_relation
      INNER JOIN resource AS _aws_elb_loadbalancer
        ON _aws_elb_loadbalancer_relation.target_id = _aws_elb_loadbalancer.id
        AND _aws_elb_loadbalancer.provider_type = 'LoadBalancer'
        AND _aws_elb_loadbalancer.service = 'elb'
    WHERE
      _aws_elb_loadbalancer_relation.relation = 'forwards-to'
  ) AS _loadbalancer_id ON _loadbalancer_id.resource_id = R.id
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
  AND LOWER(R.provider_type) = 'listener'
  AND R.service = 'elb'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_elb_listener;

COMMENT ON MATERIALIZED VIEW aws_elb_listener IS 'elb listener resources and their associated attributes.';


DROP MATERIALIZED VIEW IF EXISTS aws_elbv2_listener CASCADE;

CREATE MATERIALIZED VIEW aws_elbv2_listener AS
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
  listenerarn.attr_value #>> '{}' AS listenerarn,
  loadbalancerarn.attr_value #>> '{}' AS loadbalancerarn,
  (port.attr_value #>> '{}')::integer AS port,
  protocol.attr_value #>> '{}' AS protocol,
  certificates.attr_value::jsonb AS certificates,
  sslpolicy.attr_value #>> '{}' AS sslpolicy,
  defaultactions.attr_value::jsonb AS defaultactions,
  alpnpolicy.attr_value::jsonb AS alpnpolicy,
  
    _loadbalancer_id.target_id AS _loadbalancer_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN attrs AS listenerarn
    ON listenerarn.id = R.id
    AND listenerarn.attr_name = 'listenerarn'
  LEFT JOIN attrs AS loadbalancerarn
    ON loadbalancerarn.id = R.id
    AND loadbalancerarn.attr_name = 'loadbalancerarn'
  LEFT JOIN attrs AS port
    ON port.id = R.id
    AND port.attr_name = 'port'
  LEFT JOIN attrs AS protocol
    ON protocol.id = R.id
    AND protocol.attr_name = 'protocol'
  LEFT JOIN attrs AS certificates
    ON certificates.id = R.id
    AND certificates.attr_name = 'certificates'
  LEFT JOIN attrs AS sslpolicy
    ON sslpolicy.id = R.id
    AND sslpolicy.attr_name = 'sslpolicy'
  LEFT JOIN attrs AS defaultactions
    ON defaultactions.id = R.id
    AND defaultactions.attr_name = 'defaultactions'
  LEFT JOIN attrs AS alpnpolicy
    ON alpnpolicy.id = R.id
    AND alpnpolicy.attr_name = 'alpnpolicy'
  LEFT JOIN (
    SELECT
      _aws_elbv2_loadbalancer_relation.resource_id AS resource_id,
      _aws_elbv2_loadbalancer.id AS target_id
    FROM
      resource_relation AS _aws_elbv2_loadbalancer_relation
      INNER JOIN resource AS _aws_elbv2_loadbalancer
        ON _aws_elbv2_loadbalancer_relation.target_id = _aws_elbv2_loadbalancer.id
        AND _aws_elbv2_loadbalancer.provider_type = 'LoadBalancer'
        AND _aws_elbv2_loadbalancer.service = 'elbv2'
    WHERE
      _aws_elbv2_loadbalancer_relation.relation = 'forwards-to'
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
  AND R.service = 'elbv2'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_elbv2_listener;

COMMENT ON MATERIALIZED VIEW aws_elbv2_listener IS 'elbv2 listener resources and their associated attributes.';



DROP MATERIALIZED VIEW IF EXISTS aws_elbv2_listener_acm_certificate CASCADE;

CREATE MATERIALIZED VIEW aws_elbv2_listener_acm_certificate AS
SELECT
  aws_elbv2_listener.id AS listener_id,
  aws_acm_certificate.id AS certificate_id,
  (IsDefault.value #>> '{}')::boolean AS isdefault
FROM
  resource AS aws_elbv2_listener
  INNER JOIN resource_relation AS RR
    ON RR.resource_id = aws_elbv2_listener.id
    AND RR.relation = 'serves'
  INNER JOIN resource AS aws_acm_certificate
    ON aws_acm_certificate.id = RR.target_id
    AND aws_acm_certificate.provider_type = 'Certificate'
  LEFT JOIN resource_relation_attribute AS IsDefault
    ON IsDefault.relation_id = RR.id
    AND IsDefault.name = 'IsDefault'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_elbv2_listener_acm_certificate;

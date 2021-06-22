INSERT INTO aws_elbv2_listener (
  _id,
  uri,
  provider_account_id,
  listenerarn,
  loadbalancerarn,
  port,
  protocol,
  certificates,
  sslpolicy,
  defaultactions,
  alpnpolicy,
  _loadbalancer_id,_account_id
)
SELECT
  R.id AS _id,
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
  LEFT JOIN resource_attribute AS listenerarn
    ON listenerarn.resource_id = R.id
    AND listenerarn.type = 'provider'
    AND lower(listenerarn.attr_name) = 'listenerarn'
    AND listenerarn.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS loadbalancerarn
    ON loadbalancerarn.resource_id = R.id
    AND loadbalancerarn.type = 'provider'
    AND lower(loadbalancerarn.attr_name) = 'loadbalancerarn'
    AND loadbalancerarn.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS port
    ON port.resource_id = R.id
    AND port.type = 'provider'
    AND lower(port.attr_name) = 'port'
    AND port.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS protocol
    ON protocol.resource_id = R.id
    AND protocol.type = 'provider'
    AND lower(protocol.attr_name) = 'protocol'
    AND protocol.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS certificates
    ON certificates.resource_id = R.id
    AND certificates.type = 'provider'
    AND lower(certificates.attr_name) = 'certificates'
    AND certificates.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS sslpolicy
    ON sslpolicy.resource_id = R.id
    AND sslpolicy.type = 'provider'
    AND lower(sslpolicy.attr_name) = 'sslpolicy'
    AND sslpolicy.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS defaultactions
    ON defaultactions.resource_id = R.id
    AND defaultactions.type = 'provider'
    AND lower(defaultactions.attr_name) = 'defaultactions'
    AND defaultactions.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS alpnpolicy
    ON alpnpolicy.resource_id = R.id
    AND alpnpolicy.type = 'provider'
    AND lower(alpnpolicy.attr_name) = 'alpnpolicy'
    AND alpnpolicy.provider_account_id = R.provider_account_id
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
        AND _aws_elbv2_loadbalancer.provider_account_id = :provider_account_id
    WHERE
      _aws_elbv2_loadbalancer_relation.relation = 'forwards-to'
      AND _aws_elbv2_loadbalancer_relation.provider_account_id = :provider_account_id
  ) AS _loadbalancer_id ON _loadbalancer_id.resource_id = R.id
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
  AND R.provider_type = 'Listener'
  AND R.service = 'elbv2'
ON CONFLICT (_id) DO UPDATE
SET
    listenerarn = EXCLUDED.listenerarn,
    loadbalancerarn = EXCLUDED.loadbalancerarn,
    port = EXCLUDED.port,
    protocol = EXCLUDED.protocol,
    certificates = EXCLUDED.certificates,
    sslpolicy = EXCLUDED.sslpolicy,
    defaultactions = EXCLUDED.defaultactions,
    alpnpolicy = EXCLUDED.alpnpolicy,
    _loadbalancer_id = EXCLUDED._loadbalancer_id,
    _account_id = EXCLUDED._account_id
  ;



INSERT INTO aws_elbv2_listener_acm_certificate
SELECT
  aws_elbv2_listener.id AS listener_id,
  aws_acm_certificate.id AS certificate_id,
  aws_elbv2_listener.provider_account_id AS provider_account_id,
  (IsDefault.value #>> '{}')::boolean AS isdefault
FROM
  resource AS aws_elbv2_listener
  INNER JOIN resource_relation AS RR
    ON RR.resource_id = aws_elbv2_listener.id
    AND RR.relation = 'serves'
  INNER JOIN resource AS aws_acm_certificate
    ON aws_acm_certificate.id = RR.target_id
    AND aws_acm_certificate.provider_type = 'Certificate'
    AND aws_acm_certificate.service = 'acm'
  LEFT JOIN resource_relation_attribute AS IsDefault
    ON IsDefault.relation_id = RR.id
    AND IsDefault.name = 'IsDefault'
  WHERE
    aws_elbv2_listener.provider_type = 'Listener'
    AND aws_elbv2_listener.service = 'elbv2'
ON CONFLICT (listener_id, certificate_id)

DO UPDATE
SET
  
  IsDefault = EXCLUDED.IsDefault;

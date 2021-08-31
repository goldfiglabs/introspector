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
  attrs.provider ->> 'ListenerArn' AS listenerarn,
  attrs.provider ->> 'LoadBalancerArn' AS loadbalancerarn,
  (attrs.provider ->> 'Port')::integer AS port,
  attrs.provider ->> 'Protocol' AS protocol,
  attrs.provider -> 'Certificates' AS certificates,
  attrs.provider ->> 'SslPolicy' AS sslpolicy,
  attrs.provider -> 'DefaultActions' AS defaultactions,
  attrs.provider -> 'AlpnPolicy' AS alpnpolicy,
  
    _loadbalancer_id.target_id AS _loadbalancer_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  LEFT JOIN attrs ON
    attrs.resource_id = R.id
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
      unique_account_mapping.resource_id,
      unique_account_mapping.target_ids[1] as target_id
    FROM
      (
        SELECT
          ARRAY_AGG(_aws_organizations_account_relation.target_id) AS target_ids,
          _aws_organizations_account_relation.resource_id
        FROM
          resource AS _aws_organizations_account
          INNER JOIN resource_relation AS _aws_organizations_account_relation
            ON _aws_organizations_account_relation.target_id = _aws_organizations_account.id
        WHERE
          _aws_organizations_account.provider_type = 'Account'
          AND _aws_organizations_account.service = 'organizations'
          AND _aws_organizations_account.provider_account_id = :provider_account_id
          AND _aws_organizations_account_relation.relation = 'in'
          AND _aws_organizations_account_relation.provider_account_id = :provider_account_id
        GROUP BY _aws_organizations_account_relation.resource_id
        HAVING COUNT(*) = 1
      ) AS unique_account_mapping
  ) AS _account_id ON _account_id.resource_id = R.id
  WHERE
  R.provider_account_id = :provider_account_id
  AND R.provider_type = 'Listener'
  AND R.service = 'elbv2'
ON CONFLICT (_id) DO UPDATE
SET
    ListenerArn = EXCLUDED.ListenerArn,
    LoadBalancerArn = EXCLUDED.LoadBalancerArn,
    Port = EXCLUDED.Port,
    Protocol = EXCLUDED.Protocol,
    Certificates = EXCLUDED.Certificates,
    SslPolicy = EXCLUDED.SslPolicy,
    DefaultActions = EXCLUDED.DefaultActions,
    AlpnPolicy = EXCLUDED.AlpnPolicy,
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
    AND aws_acm_certificate.provider_account_id = :provider_account_id
  LEFT JOIN resource_relation_attribute AS IsDefault
    ON IsDefault.relation_id = RR.id
    AND IsDefault.name = 'IsDefault'
  WHERE
    aws_elbv2_listener.provider_account_id = :provider_account_id
    AND aws_elbv2_listener.provider_type = 'Listener'
    AND aws_elbv2_listener.service = 'elbv2'
ON CONFLICT (listener_id, certificate_id)

DO UPDATE
SET
  
  IsDefault = EXCLUDED.IsDefault;

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
INSERT INTO aws_elb_listener (
  _id,
  uri,
  provider_account_id,
  protocol,
  loadbalancerport,
  instanceprotocol,
  instanceport,
  sslcertificateid,
  policynames,
  _loadbalancer_id,_account_id
)
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  attrs.provider ->> 'Protocol' AS protocol,
  (attrs.provider ->> 'LoadBalancerPort')::integer AS loadbalancerport,
  attrs.provider ->> 'InstanceProtocol' AS instanceprotocol,
  (attrs.provider ->> 'InstancePort')::integer AS instanceport,
  attrs.provider ->> 'SSLCertificateId' AS sslcertificateid,
  attrs.provider -> 'PolicyNames' AS policynames,
  
    _loadbalancer_id.target_id AS _loadbalancer_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  LEFT JOIN attrs ON
    attrs.resource_id = R.id
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
        AND _aws_elb_loadbalancer.provider_account_id = :provider_account_id
    WHERE
      _aws_elb_loadbalancer_relation.relation = 'forwards-to'
      AND _aws_elb_loadbalancer_relation.provider_account_id = :provider_account_id
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
  AND R.service = 'elb'
ON CONFLICT (_id) DO UPDATE
SET
    Protocol = EXCLUDED.Protocol,
    LoadBalancerPort = EXCLUDED.LoadBalancerPort,
    InstanceProtocol = EXCLUDED.InstanceProtocol,
    InstancePort = EXCLUDED.InstancePort,
    SSLCertificateId = EXCLUDED.SSLCertificateId,
    PolicyNames = EXCLUDED.PolicyNames,
    _loadbalancer_id = EXCLUDED._loadbalancer_id,
    _account_id = EXCLUDED._account_id
  ;


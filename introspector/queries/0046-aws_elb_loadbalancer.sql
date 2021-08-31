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
INSERT INTO aws_elb_loadbalancer (
  _id,
  uri,
  provider_account_id,
  loadbalancername,
  dnsname,
  canonicalhostedzonename,
  canonicalhostedzonenameid,
  listenerdescriptions,
  policies,
  backendserverdescriptions,
  availabilityzones,
  subnets,
  vpcid,
  instances,
  healthcheck,
  sourcesecuritygroup,
  securitygroups,
  createdtime,
  scheme,
  tags,
  attributes,
  _tags,
  _account_id
)
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  attrs.provider ->> 'LoadBalancerName' AS loadbalancername,
  attrs.provider ->> 'DNSName' AS dnsname,
  attrs.provider ->> 'CanonicalHostedZoneName' AS canonicalhostedzonename,
  attrs.provider ->> 'CanonicalHostedZoneNameID' AS canonicalhostedzonenameid,
  attrs.provider -> 'ListenerDescriptions' AS listenerdescriptions,
  attrs.provider -> 'Policies' AS policies,
  attrs.provider -> 'BackendServerDescriptions' AS backendserverdescriptions,
  attrs.provider -> 'AvailabilityZones' AS availabilityzones,
  attrs.provider -> 'Subnets' AS subnets,
  attrs.provider ->> 'VPCId' AS vpcid,
  attrs.provider -> 'Instances' AS instances,
  attrs.provider -> 'HealthCheck' AS healthcheck,
  attrs.provider -> 'SourceSecurityGroup' AS sourcesecuritygroup,
  attrs.provider -> 'SecurityGroups' AS securitygroups,
  (TO_TIMESTAMP(attrs.provider ->> 'CreatedTime', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS createdtime,
  attrs.provider ->> 'Scheme' AS scheme,
  attrs.provider -> 'Tags' AS tags,
  attrs.provider -> 'Attributes' AS attributes,
  attrs.metadata -> 'Tags' AS tags,
  
    _account_id.target_id AS _account_id
FROM
  resource AS R
  LEFT JOIN attrs ON
    attrs.resource_id = R.id
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
  AND R.provider_type = 'LoadBalancer'
  AND R.service = 'elb'
ON CONFLICT (_id) DO UPDATE
SET
    LoadBalancerName = EXCLUDED.LoadBalancerName,
    DNSName = EXCLUDED.DNSName,
    CanonicalHostedZoneName = EXCLUDED.CanonicalHostedZoneName,
    CanonicalHostedZoneNameID = EXCLUDED.CanonicalHostedZoneNameID,
    ListenerDescriptions = EXCLUDED.ListenerDescriptions,
    Policies = EXCLUDED.Policies,
    BackendServerDescriptions = EXCLUDED.BackendServerDescriptions,
    AvailabilityZones = EXCLUDED.AvailabilityZones,
    Subnets = EXCLUDED.Subnets,
    VPCId = EXCLUDED.VPCId,
    Instances = EXCLUDED.Instances,
    HealthCheck = EXCLUDED.HealthCheck,
    SourceSecurityGroup = EXCLUDED.SourceSecurityGroup,
    SecurityGroups = EXCLUDED.SecurityGroups,
    CreatedTime = EXCLUDED.CreatedTime,
    Scheme = EXCLUDED.Scheme,
    Tags = EXCLUDED.Tags,
    Attributes = EXCLUDED.Attributes,
    _tags = EXCLUDED._tags,
    _account_id = EXCLUDED._account_id
  ;


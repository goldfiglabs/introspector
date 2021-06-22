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
  loadbalancername.attr_value #>> '{}' AS loadbalancername,
  dnsname.attr_value #>> '{}' AS dnsname,
  canonicalhostedzonename.attr_value #>> '{}' AS canonicalhostedzonename,
  canonicalhostedzonenameid.attr_value #>> '{}' AS canonicalhostedzonenameid,
  listenerdescriptions.attr_value::jsonb AS listenerdescriptions,
  policies.attr_value::jsonb AS policies,
  backendserverdescriptions.attr_value::jsonb AS backendserverdescriptions,
  availabilityzones.attr_value::jsonb AS availabilityzones,
  subnets.attr_value::jsonb AS subnets,
  vpcid.attr_value #>> '{}' AS vpcid,
  instances.attr_value::jsonb AS instances,
  healthcheck.attr_value::jsonb AS healthcheck,
  sourcesecuritygroup.attr_value::jsonb AS sourcesecuritygroup,
  securitygroups.attr_value::jsonb AS securitygroups,
  (TO_TIMESTAMP(createdtime.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS createdtime,
  scheme.attr_value #>> '{}' AS scheme,
  tags.attr_value::jsonb AS tags,
  attributes.attr_value::jsonb AS attributes,
  _tags.attr_value::jsonb AS _tags,
  
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN resource_attribute AS loadbalancername
    ON loadbalancername.resource_id = R.id
    AND loadbalancername.type = 'provider'
    AND lower(loadbalancername.attr_name) = 'loadbalancername'
    AND loadbalancername.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS dnsname
    ON dnsname.resource_id = R.id
    AND dnsname.type = 'provider'
    AND lower(dnsname.attr_name) = 'dnsname'
    AND dnsname.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS canonicalhostedzonename
    ON canonicalhostedzonename.resource_id = R.id
    AND canonicalhostedzonename.type = 'provider'
    AND lower(canonicalhostedzonename.attr_name) = 'canonicalhostedzonename'
    AND canonicalhostedzonename.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS canonicalhostedzonenameid
    ON canonicalhostedzonenameid.resource_id = R.id
    AND canonicalhostedzonenameid.type = 'provider'
    AND lower(canonicalhostedzonenameid.attr_name) = 'canonicalhostedzonenameid'
    AND canonicalhostedzonenameid.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS listenerdescriptions
    ON listenerdescriptions.resource_id = R.id
    AND listenerdescriptions.type = 'provider'
    AND lower(listenerdescriptions.attr_name) = 'listenerdescriptions'
    AND listenerdescriptions.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS policies
    ON policies.resource_id = R.id
    AND policies.type = 'provider'
    AND lower(policies.attr_name) = 'policies'
    AND policies.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS backendserverdescriptions
    ON backendserverdescriptions.resource_id = R.id
    AND backendserverdescriptions.type = 'provider'
    AND lower(backendserverdescriptions.attr_name) = 'backendserverdescriptions'
    AND backendserverdescriptions.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS availabilityzones
    ON availabilityzones.resource_id = R.id
    AND availabilityzones.type = 'provider'
    AND lower(availabilityzones.attr_name) = 'availabilityzones'
    AND availabilityzones.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS subnets
    ON subnets.resource_id = R.id
    AND subnets.type = 'provider'
    AND lower(subnets.attr_name) = 'subnets'
    AND subnets.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS vpcid
    ON vpcid.resource_id = R.id
    AND vpcid.type = 'provider'
    AND lower(vpcid.attr_name) = 'vpcid'
    AND vpcid.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS instances
    ON instances.resource_id = R.id
    AND instances.type = 'provider'
    AND lower(instances.attr_name) = 'instances'
    AND instances.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS healthcheck
    ON healthcheck.resource_id = R.id
    AND healthcheck.type = 'provider'
    AND lower(healthcheck.attr_name) = 'healthcheck'
    AND healthcheck.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS sourcesecuritygroup
    ON sourcesecuritygroup.resource_id = R.id
    AND sourcesecuritygroup.type = 'provider'
    AND lower(sourcesecuritygroup.attr_name) = 'sourcesecuritygroup'
    AND sourcesecuritygroup.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS securitygroups
    ON securitygroups.resource_id = R.id
    AND securitygroups.type = 'provider'
    AND lower(securitygroups.attr_name) = 'securitygroups'
    AND securitygroups.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS createdtime
    ON createdtime.resource_id = R.id
    AND createdtime.type = 'provider'
    AND lower(createdtime.attr_name) = 'createdtime'
    AND createdtime.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS scheme
    ON scheme.resource_id = R.id
    AND scheme.type = 'provider'
    AND lower(scheme.attr_name) = 'scheme'
    AND scheme.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS tags
    ON tags.resource_id = R.id
    AND tags.type = 'provider'
    AND lower(tags.attr_name) = 'tags'
    AND tags.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS attributes
    ON attributes.resource_id = R.id
    AND attributes.type = 'provider'
    AND lower(attributes.attr_name) = 'attributes'
    AND attributes.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS _tags
    ON _tags.resource_id = R.id
    AND _tags.type = 'Metadata'
    AND lower(_tags.attr_name) = 'tags'
    AND _tags.provider_account_id = R.provider_account_id
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
  AND R.provider_type = 'LoadBalancer'
  AND R.service = 'elb'
ON CONFLICT (_id) DO UPDATE
SET
    loadbalancername = EXCLUDED.loadbalancername,
    dnsname = EXCLUDED.dnsname,
    canonicalhostedzonename = EXCLUDED.canonicalhostedzonename,
    canonicalhostedzonenameid = EXCLUDED.canonicalhostedzonenameid,
    listenerdescriptions = EXCLUDED.listenerdescriptions,
    policies = EXCLUDED.policies,
    backendserverdescriptions = EXCLUDED.backendserverdescriptions,
    availabilityzones = EXCLUDED.availabilityzones,
    subnets = EXCLUDED.subnets,
    vpcid = EXCLUDED.vpcid,
    instances = EXCLUDED.instances,
    healthcheck = EXCLUDED.healthcheck,
    sourcesecuritygroup = EXCLUDED.sourcesecuritygroup,
    securitygroups = EXCLUDED.securitygroups,
    createdtime = EXCLUDED.createdtime,
    scheme = EXCLUDED.scheme,
    tags = EXCLUDED.tags,
    attributes = EXCLUDED.attributes,
    _tags = EXCLUDED._tags,
    _account_id = EXCLUDED._account_id
  ;


DROP MATERIALIZED VIEW IF EXISTS aws_elb_loadbalancer CASCADE;

CREATE MATERIALIZED VIEW aws_elb_loadbalancer AS
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
  
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN attrs AS loadbalancername
    ON loadbalancername.id = R.id
    AND loadbalancername.attr_name = 'loadbalancername'
  LEFT JOIN attrs AS dnsname
    ON dnsname.id = R.id
    AND dnsname.attr_name = 'dnsname'
  LEFT JOIN attrs AS canonicalhostedzonename
    ON canonicalhostedzonename.id = R.id
    AND canonicalhostedzonename.attr_name = 'canonicalhostedzonename'
  LEFT JOIN attrs AS canonicalhostedzonenameid
    ON canonicalhostedzonenameid.id = R.id
    AND canonicalhostedzonenameid.attr_name = 'canonicalhostedzonenameid'
  LEFT JOIN attrs AS listenerdescriptions
    ON listenerdescriptions.id = R.id
    AND listenerdescriptions.attr_name = 'listenerdescriptions'
  LEFT JOIN attrs AS policies
    ON policies.id = R.id
    AND policies.attr_name = 'policies'
  LEFT JOIN attrs AS backendserverdescriptions
    ON backendserverdescriptions.id = R.id
    AND backendserverdescriptions.attr_name = 'backendserverdescriptions'
  LEFT JOIN attrs AS availabilityzones
    ON availabilityzones.id = R.id
    AND availabilityzones.attr_name = 'availabilityzones'
  LEFT JOIN attrs AS subnets
    ON subnets.id = R.id
    AND subnets.attr_name = 'subnets'
  LEFT JOIN attrs AS vpcid
    ON vpcid.id = R.id
    AND vpcid.attr_name = 'vpcid'
  LEFT JOIN attrs AS instances
    ON instances.id = R.id
    AND instances.attr_name = 'instances'
  LEFT JOIN attrs AS healthcheck
    ON healthcheck.id = R.id
    AND healthcheck.attr_name = 'healthcheck'
  LEFT JOIN attrs AS sourcesecuritygroup
    ON sourcesecuritygroup.id = R.id
    AND sourcesecuritygroup.attr_name = 'sourcesecuritygroup'
  LEFT JOIN attrs AS securitygroups
    ON securitygroups.id = R.id
    AND securitygroups.attr_name = 'securitygroups'
  LEFT JOIN attrs AS createdtime
    ON createdtime.id = R.id
    AND createdtime.attr_name = 'createdtime'
  LEFT JOIN attrs AS scheme
    ON scheme.id = R.id
    AND scheme.attr_name = 'scheme'
  LEFT JOIN attrs AS tags
    ON tags.id = R.id
    AND tags.attr_name = 'tags'
  LEFT JOIN attrs AS attributes
    ON attributes.id = R.id
    AND attributes.attr_name = 'attributes'
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
  AND LOWER(R.provider_type) = 'loadbalancer'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_elb_loadbalancer;

COMMENT ON MATERIALIZED VIEW aws_elb_loadbalancer IS 'elb loadbalancer resources and their associated attributes.';


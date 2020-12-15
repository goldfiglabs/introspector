DROP MATERIALIZED VIEW IF EXISTS aws_es_domain CASCADE;

CREATE MATERIALIZED VIEW aws_es_domain AS
SELECT
  R.id AS resource_id,
  R.uri,
  R.provider_account_id,
  domainid.attr_value #>> '{}' AS domainid,
  domainname.attr_value #>> '{}' AS domainname,
  arn.attr_value #>> '{}' AS arn,
  (created.attr_value #>> '{}')::boolean AS created,
  (deleted.attr_value #>> '{}')::boolean AS deleted,
  endpoint.attr_value #>> '{}' AS endpoint,
  endpoints.attr_value::jsonb AS endpoints,
  (processing.attr_value #>> '{}')::boolean AS processing,
  (upgradeprocessing.attr_value #>> '{}')::boolean AS upgradeprocessing,
  elasticsearchversion.attr_value #>> '{}' AS elasticsearchversion,
  elasticsearchclusterconfig.attr_value::jsonb AS elasticsearchclusterconfig,
  ebsoptions.attr_value::jsonb AS ebsoptions,
  accesspolicies.attr_value::jsonb AS accesspolicies,
  snapshotoptions.attr_value::jsonb AS snapshotoptions,
  vpcoptions.attr_value::jsonb AS vpcoptions,
  cognitooptions.attr_value::jsonb AS cognitooptions,
  encryptionatrestoptions.attr_value::jsonb AS encryptionatrestoptions,
  nodetonodeencryptionoptions.attr_value::jsonb AS nodetonodeencryptionoptions,
  advancedoptions.attr_value::jsonb AS advancedoptions,
  logpublishingoptions.attr_value::jsonb AS logpublishingoptions,
  servicesoftwareoptions.attr_value::jsonb AS servicesoftwareoptions,
  domainendpointoptions.attr_value::jsonb AS domainendpointoptions,
  advancedsecurityoptions.attr_value::jsonb AS advancedsecurityoptions,
  tags.attr_value::jsonb AS tags,
  
    _ec2_vpc_id.target_id AS _ec2_vpc_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN resource_attribute AS domainid
    ON domainid.resource_id = R.id
    AND domainid.type = 'provider'
    AND lower(domainid.attr_name) = 'domainid'
  LEFT JOIN resource_attribute AS domainname
    ON domainname.resource_id = R.id
    AND domainname.type = 'provider'
    AND lower(domainname.attr_name) = 'domainname'
  LEFT JOIN resource_attribute AS arn
    ON arn.resource_id = R.id
    AND arn.type = 'provider'
    AND lower(arn.attr_name) = 'arn'
  LEFT JOIN resource_attribute AS created
    ON created.resource_id = R.id
    AND created.type = 'provider'
    AND lower(created.attr_name) = 'created'
  LEFT JOIN resource_attribute AS deleted
    ON deleted.resource_id = R.id
    AND deleted.type = 'provider'
    AND lower(deleted.attr_name) = 'deleted'
  LEFT JOIN resource_attribute AS endpoint
    ON endpoint.resource_id = R.id
    AND endpoint.type = 'provider'
    AND lower(endpoint.attr_name) = 'endpoint'
  LEFT JOIN resource_attribute AS endpoints
    ON endpoints.resource_id = R.id
    AND endpoints.type = 'provider'
    AND lower(endpoints.attr_name) = 'endpoints'
  LEFT JOIN resource_attribute AS processing
    ON processing.resource_id = R.id
    AND processing.type = 'provider'
    AND lower(processing.attr_name) = 'processing'
  LEFT JOIN resource_attribute AS upgradeprocessing
    ON upgradeprocessing.resource_id = R.id
    AND upgradeprocessing.type = 'provider'
    AND lower(upgradeprocessing.attr_name) = 'upgradeprocessing'
  LEFT JOIN resource_attribute AS elasticsearchversion
    ON elasticsearchversion.resource_id = R.id
    AND elasticsearchversion.type = 'provider'
    AND lower(elasticsearchversion.attr_name) = 'elasticsearchversion'
  LEFT JOIN resource_attribute AS elasticsearchclusterconfig
    ON elasticsearchclusterconfig.resource_id = R.id
    AND elasticsearchclusterconfig.type = 'provider'
    AND lower(elasticsearchclusterconfig.attr_name) = 'elasticsearchclusterconfig'
  LEFT JOIN resource_attribute AS ebsoptions
    ON ebsoptions.resource_id = R.id
    AND ebsoptions.type = 'provider'
    AND lower(ebsoptions.attr_name) = 'ebsoptions'
  LEFT JOIN resource_attribute AS accesspolicies
    ON accesspolicies.resource_id = R.id
    AND accesspolicies.type = 'provider'
    AND lower(accesspolicies.attr_name) = 'accesspolicies'
  LEFT JOIN resource_attribute AS snapshotoptions
    ON snapshotoptions.resource_id = R.id
    AND snapshotoptions.type = 'provider'
    AND lower(snapshotoptions.attr_name) = 'snapshotoptions'
  LEFT JOIN resource_attribute AS vpcoptions
    ON vpcoptions.resource_id = R.id
    AND vpcoptions.type = 'provider'
    AND lower(vpcoptions.attr_name) = 'vpcoptions'
  LEFT JOIN resource_attribute AS cognitooptions
    ON cognitooptions.resource_id = R.id
    AND cognitooptions.type = 'provider'
    AND lower(cognitooptions.attr_name) = 'cognitooptions'
  LEFT JOIN resource_attribute AS encryptionatrestoptions
    ON encryptionatrestoptions.resource_id = R.id
    AND encryptionatrestoptions.type = 'provider'
    AND lower(encryptionatrestoptions.attr_name) = 'encryptionatrestoptions'
  LEFT JOIN resource_attribute AS nodetonodeencryptionoptions
    ON nodetonodeencryptionoptions.resource_id = R.id
    AND nodetonodeencryptionoptions.type = 'provider'
    AND lower(nodetonodeencryptionoptions.attr_name) = 'nodetonodeencryptionoptions'
  LEFT JOIN resource_attribute AS advancedoptions
    ON advancedoptions.resource_id = R.id
    AND advancedoptions.type = 'provider'
    AND lower(advancedoptions.attr_name) = 'advancedoptions'
  LEFT JOIN resource_attribute AS logpublishingoptions
    ON logpublishingoptions.resource_id = R.id
    AND logpublishingoptions.type = 'provider'
    AND lower(logpublishingoptions.attr_name) = 'logpublishingoptions'
  LEFT JOIN resource_attribute AS servicesoftwareoptions
    ON servicesoftwareoptions.resource_id = R.id
    AND servicesoftwareoptions.type = 'provider'
    AND lower(servicesoftwareoptions.attr_name) = 'servicesoftwareoptions'
  LEFT JOIN resource_attribute AS domainendpointoptions
    ON domainendpointoptions.resource_id = R.id
    AND domainendpointoptions.type = 'provider'
    AND lower(domainendpointoptions.attr_name) = 'domainendpointoptions'
  LEFT JOIN resource_attribute AS advancedsecurityoptions
    ON advancedsecurityoptions.resource_id = R.id
    AND advancedsecurityoptions.type = 'provider'
    AND lower(advancedsecurityoptions.attr_name) = 'advancedsecurityoptions'
  LEFT JOIN resource_attribute AS tags
    ON tags.resource_id = R.id
    AND tags.type = 'provider'
    AND lower(tags.attr_name) = 'tags'
  LEFT JOIN (
    SELECT
      _aws_ec2_vpc_relation.resource_id AS resource_id,
      _aws_ec2_vpc.id AS target_id
    FROM
      resource_relation AS _aws_ec2_vpc_relation
      INNER JOIN resource AS _aws_ec2_vpc
        ON _aws_ec2_vpc_relation.target_id = _aws_ec2_vpc.id
        AND _aws_ec2_vpc.provider_type = 'Vpc'
        AND _aws_ec2_vpc.service = 'ec2'
    WHERE
      _aws_ec2_vpc_relation.relation = 'in'
  ) AS _ec2_vpc_id ON _ec2_vpc_id.resource_id = R.id
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
  AND R.provider_type = 'Domain'
  AND R.service = 'es'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_es_domain;

COMMENT ON MATERIALIZED VIEW aws_es_domain IS 'es Domain resources and their associated attributes.';



DROP MATERIALIZED VIEW IF EXISTS aws_es_domain_ec2_subnet CASCADE;

CREATE MATERIALIZED VIEW aws_es_domain_ec2_subnet AS
SELECT
  aws_es_domain.id AS domain_id,
  aws_ec2_subnet.id AS subnet_id
FROM
  resource AS aws_es_domain
  INNER JOIN resource_relation AS RR
    ON RR.resource_id = aws_es_domain.id
    AND RR.relation = 'in'
  INNER JOIN resource AS aws_ec2_subnet
    ON aws_ec2_subnet.id = RR.target_id
    AND aws_ec2_subnet.provider_type = 'Subnet'
    AND aws_ec2_subnet.service = 'ec2'
  WHERE
    aws_es_domain.provider_type = 'Domain'
    AND aws_es_domain.service = 'es'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_es_domain_ec2_subnet;


DROP MATERIALIZED VIEW IF EXISTS aws_es_domain_ec2_securitygroup CASCADE;

CREATE MATERIALIZED VIEW aws_es_domain_ec2_securitygroup AS
SELECT
  aws_es_domain.id AS domain_id,
  aws_ec2_securitygroup.id AS securitygroup_id
FROM
  resource AS aws_es_domain
  INNER JOIN resource_relation AS RR
    ON RR.resource_id = aws_es_domain.id
    AND RR.relation = 'in'
  INNER JOIN resource AS aws_ec2_securitygroup
    ON aws_ec2_securitygroup.id = RR.target_id
    AND aws_ec2_securitygroup.provider_type = 'SecurityGroup'
    AND aws_ec2_securitygroup.service = 'ec2'
  WHERE
    aws_es_domain.provider_type = 'Domain'
    AND aws_es_domain.service = 'es'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_es_domain_ec2_securitygroup;

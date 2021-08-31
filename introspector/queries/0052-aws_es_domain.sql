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
INSERT INTO aws_es_domain (
  _id,
  uri,
  provider_account_id,
  domainid,
  domainname,
  arn,
  created,
  deleted,
  endpoint,
  endpoints,
  processing,
  upgradeprocessing,
  elasticsearchversion,
  elasticsearchclusterconfig,
  ebsoptions,
  accesspolicies,
  snapshotoptions,
  vpcoptions,
  cognitooptions,
  encryptionatrestoptions,
  nodetonodeencryptionoptions,
  advancedoptions,
  logpublishingoptions,
  servicesoftwareoptions,
  domainendpointoptions,
  advancedsecurityoptions,
  tags,
  _tags,
  _policy,
  _ec2_vpc_id,_account_id
)
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  attrs.provider ->> 'DomainId' AS domainid,
  attrs.provider ->> 'DomainName' AS domainname,
  attrs.provider ->> 'ARN' AS arn,
  (attrs.provider ->> 'Created')::boolean AS created,
  (attrs.provider ->> 'Deleted')::boolean AS deleted,
  attrs.provider ->> 'Endpoint' AS endpoint,
  attrs.provider -> 'Endpoints' AS endpoints,
  (attrs.provider ->> 'Processing')::boolean AS processing,
  (attrs.provider ->> 'UpgradeProcessing')::boolean AS upgradeprocessing,
  attrs.provider ->> 'ElasticsearchVersion' AS elasticsearchversion,
  attrs.provider -> 'ElasticsearchClusterConfig' AS elasticsearchclusterconfig,
  attrs.provider -> 'EBSOptions' AS ebsoptions,
  attrs.provider -> 'AccessPolicies' AS accesspolicies,
  attrs.provider -> 'SnapshotOptions' AS snapshotoptions,
  attrs.provider -> 'VPCOptions' AS vpcoptions,
  attrs.provider -> 'CognitoOptions' AS cognitooptions,
  attrs.provider -> 'EncryptionAtRestOptions' AS encryptionatrestoptions,
  attrs.provider -> 'NodeToNodeEncryptionOptions' AS nodetonodeencryptionoptions,
  attrs.provider -> 'AdvancedOptions' AS advancedoptions,
  attrs.provider -> 'LogPublishingOptions' AS logpublishingoptions,
  attrs.provider -> 'ServiceSoftwareOptions' AS servicesoftwareoptions,
  attrs.provider -> 'DomainEndpointOptions' AS domainendpointoptions,
  attrs.provider -> 'AdvancedSecurityOptions' AS advancedsecurityoptions,
  attrs.provider -> 'Tags' AS tags,
  attrs.metadata -> 'Tags' AS tags,
  attrs.metadata -> 'Policy' AS policy,
  
    _ec2_vpc_id.target_id AS _ec2_vpc_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  LEFT JOIN attrs ON
    attrs.resource_id = R.id
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
        AND _aws_ec2_vpc.provider_account_id = :provider_account_id
    WHERE
      _aws_ec2_vpc_relation.relation = 'in'
      AND _aws_ec2_vpc_relation.provider_account_id = :provider_account_id
  ) AS _ec2_vpc_id ON _ec2_vpc_id.resource_id = R.id
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
  AND R.provider_type = 'Domain'
  AND R.service = 'es'
ON CONFLICT (_id) DO UPDATE
SET
    DomainId = EXCLUDED.DomainId,
    DomainName = EXCLUDED.DomainName,
    ARN = EXCLUDED.ARN,
    Created = EXCLUDED.Created,
    Deleted = EXCLUDED.Deleted,
    Endpoint = EXCLUDED.Endpoint,
    Endpoints = EXCLUDED.Endpoints,
    Processing = EXCLUDED.Processing,
    UpgradeProcessing = EXCLUDED.UpgradeProcessing,
    ElasticsearchVersion = EXCLUDED.ElasticsearchVersion,
    ElasticsearchClusterConfig = EXCLUDED.ElasticsearchClusterConfig,
    EBSOptions = EXCLUDED.EBSOptions,
    AccessPolicies = EXCLUDED.AccessPolicies,
    SnapshotOptions = EXCLUDED.SnapshotOptions,
    VPCOptions = EXCLUDED.VPCOptions,
    CognitoOptions = EXCLUDED.CognitoOptions,
    EncryptionAtRestOptions = EXCLUDED.EncryptionAtRestOptions,
    NodeToNodeEncryptionOptions = EXCLUDED.NodeToNodeEncryptionOptions,
    AdvancedOptions = EXCLUDED.AdvancedOptions,
    LogPublishingOptions = EXCLUDED.LogPublishingOptions,
    ServiceSoftwareOptions = EXCLUDED.ServiceSoftwareOptions,
    DomainEndpointOptions = EXCLUDED.DomainEndpointOptions,
    AdvancedSecurityOptions = EXCLUDED.AdvancedSecurityOptions,
    Tags = EXCLUDED.Tags,
    _tags = EXCLUDED._tags,
    _policy = EXCLUDED._policy,
    _ec2_vpc_id = EXCLUDED._ec2_vpc_id,
    _account_id = EXCLUDED._account_id
  ;



INSERT INTO aws_es_domain_ec2_subnet
SELECT
  aws_es_domain.id AS domain_id,
  aws_ec2_subnet.id AS subnet_id,
  aws_es_domain.provider_account_id AS provider_account_id
FROM
  resource AS aws_es_domain
  INNER JOIN resource_relation AS RR
    ON RR.resource_id = aws_es_domain.id
    AND RR.relation = 'in'
  INNER JOIN resource AS aws_ec2_subnet
    ON aws_ec2_subnet.id = RR.target_id
    AND aws_ec2_subnet.provider_type = 'Subnet'
    AND aws_ec2_subnet.service = 'ec2'
    AND aws_ec2_subnet.provider_account_id = :provider_account_id
  WHERE
    aws_es_domain.provider_account_id = :provider_account_id
    AND aws_es_domain.provider_type = 'Domain'
    AND aws_es_domain.service = 'es'
ON CONFLICT (domain_id, subnet_id)
DO NOTHING
;


INSERT INTO aws_es_domain_ec2_securitygroup
SELECT
  aws_es_domain.id AS domain_id,
  aws_ec2_securitygroup.id AS securitygroup_id,
  aws_es_domain.provider_account_id AS provider_account_id
FROM
  resource AS aws_es_domain
  INNER JOIN resource_relation AS RR
    ON RR.resource_id = aws_es_domain.id
    AND RR.relation = 'in'
  INNER JOIN resource AS aws_ec2_securitygroup
    ON aws_ec2_securitygroup.id = RR.target_id
    AND aws_ec2_securitygroup.provider_type = 'SecurityGroup'
    AND aws_ec2_securitygroup.service = 'ec2'
    AND aws_ec2_securitygroup.provider_account_id = :provider_account_id
  WHERE
    aws_es_domain.provider_account_id = :provider_account_id
    AND aws_es_domain.provider_type = 'Domain'
    AND aws_es_domain.service = 'es'
ON CONFLICT (domain_id, securitygroup_id)
DO NOTHING
;

DROP MATERIALIZED VIEW IF EXISTS aws_ecr_repository CASCADE;

CREATE MATERIALIZED VIEW aws_ecr_repository AS
SELECT
  R.id AS resource_id,
  R.uri,
  R.provider_account_id,
  repositoryarn.attr_value #>> '{}' AS repositoryarn,
  registryid.attr_value #>> '{}' AS registryid,
  repositoryname.attr_value #>> '{}' AS repositoryname,
  repositoryuri.attr_value #>> '{}' AS repositoryuri,
  (TO_TIMESTAMP(createdat.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS createdat,
  imagetagmutability.attr_value #>> '{}' AS imagetagmutability,
  imagescanningconfiguration.attr_value::jsonb AS imagescanningconfiguration,
  tags.attr_value::jsonb AS tags,
  policy.attr_value::jsonb AS policy,
  
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN resource_attribute AS repositoryarn
    ON repositoryarn.resource_id = R.id
    AND repositoryarn.type = 'provider'
    AND lower(repositoryarn.attr_name) = 'repositoryarn'
  LEFT JOIN resource_attribute AS registryid
    ON registryid.resource_id = R.id
    AND registryid.type = 'provider'
    AND lower(registryid.attr_name) = 'registryid'
  LEFT JOIN resource_attribute AS repositoryname
    ON repositoryname.resource_id = R.id
    AND repositoryname.type = 'provider'
    AND lower(repositoryname.attr_name) = 'repositoryname'
  LEFT JOIN resource_attribute AS repositoryuri
    ON repositoryuri.resource_id = R.id
    AND repositoryuri.type = 'provider'
    AND lower(repositoryuri.attr_name) = 'repositoryuri'
  LEFT JOIN resource_attribute AS createdat
    ON createdat.resource_id = R.id
    AND createdat.type = 'provider'
    AND lower(createdat.attr_name) = 'createdat'
  LEFT JOIN resource_attribute AS imagetagmutability
    ON imagetagmutability.resource_id = R.id
    AND imagetagmutability.type = 'provider'
    AND lower(imagetagmutability.attr_name) = 'imagetagmutability'
  LEFT JOIN resource_attribute AS imagescanningconfiguration
    ON imagescanningconfiguration.resource_id = R.id
    AND imagescanningconfiguration.type = 'provider'
    AND lower(imagescanningconfiguration.attr_name) = 'imagescanningconfiguration'
  LEFT JOIN resource_attribute AS tags
    ON tags.resource_id = R.id
    AND tags.type = 'provider'
    AND lower(tags.attr_name) = 'tags'
  LEFT JOIN resource_attribute AS policy
    ON policy.resource_id = R.id
    AND policy.type = 'provider'
    AND lower(policy.attr_name) = 'policy'
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
  AND R.provider_type = 'Repository'
  AND R.service = 'ecr'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_ecr_repository;

COMMENT ON MATERIALIZED VIEW aws_ecr_repository IS 'ecr Repository resources and their associated attributes.';


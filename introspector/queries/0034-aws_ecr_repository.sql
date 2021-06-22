INSERT INTO aws_ecr_repository (
  _id,
  uri,
  provider_account_id,
  repositoryarn,
  registryid,
  repositoryname,
  repositoryuri,
  createdat,
  imagetagmutability,
  imagescanningconfiguration,
  encryptionconfiguration,
  tags,
  policy,
  _tags,
  _policy,
  _account_id
)
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  repositoryarn.attr_value #>> '{}' AS repositoryarn,
  registryid.attr_value #>> '{}' AS registryid,
  repositoryname.attr_value #>> '{}' AS repositoryname,
  repositoryuri.attr_value #>> '{}' AS repositoryuri,
  (TO_TIMESTAMP(createdat.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS createdat,
  imagetagmutability.attr_value #>> '{}' AS imagetagmutability,
  imagescanningconfiguration.attr_value::jsonb AS imagescanningconfiguration,
  encryptionconfiguration.attr_value::jsonb AS encryptionconfiguration,
  tags.attr_value::jsonb AS tags,
  policy.attr_value::jsonb AS policy,
  _tags.attr_value::jsonb AS _tags,
  _policy.attr_value::jsonb AS _policy,
  
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN resource_attribute AS repositoryarn
    ON repositoryarn.resource_id = R.id
    AND repositoryarn.type = 'provider'
    AND lower(repositoryarn.attr_name) = 'repositoryarn'
    AND repositoryarn.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS registryid
    ON registryid.resource_id = R.id
    AND registryid.type = 'provider'
    AND lower(registryid.attr_name) = 'registryid'
    AND registryid.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS repositoryname
    ON repositoryname.resource_id = R.id
    AND repositoryname.type = 'provider'
    AND lower(repositoryname.attr_name) = 'repositoryname'
    AND repositoryname.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS repositoryuri
    ON repositoryuri.resource_id = R.id
    AND repositoryuri.type = 'provider'
    AND lower(repositoryuri.attr_name) = 'repositoryuri'
    AND repositoryuri.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS createdat
    ON createdat.resource_id = R.id
    AND createdat.type = 'provider'
    AND lower(createdat.attr_name) = 'createdat'
    AND createdat.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS imagetagmutability
    ON imagetagmutability.resource_id = R.id
    AND imagetagmutability.type = 'provider'
    AND lower(imagetagmutability.attr_name) = 'imagetagmutability'
    AND imagetagmutability.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS imagescanningconfiguration
    ON imagescanningconfiguration.resource_id = R.id
    AND imagescanningconfiguration.type = 'provider'
    AND lower(imagescanningconfiguration.attr_name) = 'imagescanningconfiguration'
    AND imagescanningconfiguration.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS encryptionconfiguration
    ON encryptionconfiguration.resource_id = R.id
    AND encryptionconfiguration.type = 'provider'
    AND lower(encryptionconfiguration.attr_name) = 'encryptionconfiguration'
    AND encryptionconfiguration.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS tags
    ON tags.resource_id = R.id
    AND tags.type = 'provider'
    AND lower(tags.attr_name) = 'tags'
    AND tags.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS policy
    ON policy.resource_id = R.id
    AND policy.type = 'provider'
    AND lower(policy.attr_name) = 'policy'
    AND policy.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS _tags
    ON _tags.resource_id = R.id
    AND _tags.type = 'Metadata'
    AND lower(_tags.attr_name) = 'tags'
    AND _tags.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS _policy
    ON _policy.resource_id = R.id
    AND _policy.type = 'Metadata'
    AND lower(_policy.attr_name) = 'policy'
    AND _policy.provider_account_id = R.provider_account_id
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
  AND R.provider_type = 'Repository'
  AND R.service = 'ecr'
ON CONFLICT (_id) DO UPDATE
SET
    repositoryarn = EXCLUDED.repositoryarn,
    registryid = EXCLUDED.registryid,
    repositoryname = EXCLUDED.repositoryname,
    repositoryuri = EXCLUDED.repositoryuri,
    createdat = EXCLUDED.createdat,
    imagetagmutability = EXCLUDED.imagetagmutability,
    imagescanningconfiguration = EXCLUDED.imagescanningconfiguration,
    encryptionconfiguration = EXCLUDED.encryptionconfiguration,
    tags = EXCLUDED.tags,
    policy = EXCLUDED.policy,
    _tags = EXCLUDED._tags,
    _policy = EXCLUDED._policy,
    _account_id = EXCLUDED._account_id
  ;


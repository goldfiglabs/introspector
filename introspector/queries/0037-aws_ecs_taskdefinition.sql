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
INSERT INTO aws_ecs_taskdefinition (
  _id,
  uri,
  provider_account_id,
  taskdefinitionarn,
  containerdefinitions,
  family,
  taskrolearn,
  executionrolearn,
  networkmode,
  revision,
  volumes,
  status,
  requiresattributes,
  placementconstraints,
  compatibilities,
  requirescompatibilities,
  cpu,
  memory,
  inferenceaccelerators,
  pidmode,
  ipcmode,
  proxyconfiguration,
  _tags,
  _account_id
)
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  attrs.provider ->> 'taskDefinitionArn' AS taskdefinitionarn,
  attrs.provider -> 'containerDefinitions' AS containerdefinitions,
  attrs.provider ->> 'family' AS family,
  attrs.provider ->> 'taskRoleArn' AS taskrolearn,
  attrs.provider ->> 'executionRoleArn' AS executionrolearn,
  attrs.provider ->> 'networkMode' AS networkmode,
  (attrs.provider ->> 'revision')::integer AS revision,
  attrs.provider -> 'volumes' AS volumes,
  attrs.provider ->> 'status' AS status,
  attrs.provider -> 'requiresAttributes' AS requiresattributes,
  attrs.provider -> 'placementConstraints' AS placementconstraints,
  attrs.provider -> 'compatibilities' AS compatibilities,
  attrs.provider -> 'requiresCompatibilities' AS requirescompatibilities,
  attrs.provider ->> 'cpu' AS cpu,
  attrs.provider ->> 'memory' AS memory,
  attrs.provider -> 'inferenceAccelerators' AS inferenceaccelerators,
  attrs.provider ->> 'pidMode' AS pidmode,
  attrs.provider ->> 'ipcMode' AS ipcmode,
  attrs.provider -> 'proxyConfiguration' AS proxyconfiguration,
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
  AND R.provider_type = 'TaskDefinition'
  AND R.service = 'ecs'
ON CONFLICT (_id) DO UPDATE
SET
    taskDefinitionArn = EXCLUDED.taskDefinitionArn,
    containerDefinitions = EXCLUDED.containerDefinitions,
    family = EXCLUDED.family,
    taskRoleArn = EXCLUDED.taskRoleArn,
    executionRoleArn = EXCLUDED.executionRoleArn,
    networkMode = EXCLUDED.networkMode,
    revision = EXCLUDED.revision,
    volumes = EXCLUDED.volumes,
    status = EXCLUDED.status,
    requiresAttributes = EXCLUDED.requiresAttributes,
    placementConstraints = EXCLUDED.placementConstraints,
    compatibilities = EXCLUDED.compatibilities,
    requiresCompatibilities = EXCLUDED.requiresCompatibilities,
    cpu = EXCLUDED.cpu,
    memory = EXCLUDED.memory,
    inferenceAccelerators = EXCLUDED.inferenceAccelerators,
    pidMode = EXCLUDED.pidMode,
    ipcMode = EXCLUDED.ipcMode,
    proxyConfiguration = EXCLUDED.proxyConfiguration,
    _tags = EXCLUDED._tags,
    _account_id = EXCLUDED._account_id
  ;


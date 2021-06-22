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
  taskdefinitionarn.attr_value #>> '{}' AS taskdefinitionarn,
  containerdefinitions.attr_value::jsonb AS containerdefinitions,
  family.attr_value #>> '{}' AS family,
  taskrolearn.attr_value #>> '{}' AS taskrolearn,
  executionrolearn.attr_value #>> '{}' AS executionrolearn,
  networkmode.attr_value #>> '{}' AS networkmode,
  (revision.attr_value #>> '{}')::integer AS revision,
  volumes.attr_value::jsonb AS volumes,
  status.attr_value #>> '{}' AS status,
  requiresattributes.attr_value::jsonb AS requiresattributes,
  placementconstraints.attr_value::jsonb AS placementconstraints,
  compatibilities.attr_value::jsonb AS compatibilities,
  requirescompatibilities.attr_value::jsonb AS requirescompatibilities,
  cpu.attr_value #>> '{}' AS cpu,
  memory.attr_value #>> '{}' AS memory,
  inferenceaccelerators.attr_value::jsonb AS inferenceaccelerators,
  pidmode.attr_value #>> '{}' AS pidmode,
  ipcmode.attr_value #>> '{}' AS ipcmode,
  proxyconfiguration.attr_value::jsonb AS proxyconfiguration,
  _tags.attr_value::jsonb AS _tags,
  
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN resource_attribute AS taskdefinitionarn
    ON taskdefinitionarn.resource_id = R.id
    AND taskdefinitionarn.type = 'provider'
    AND lower(taskdefinitionarn.attr_name) = 'taskdefinitionarn'
    AND taskdefinitionarn.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS containerdefinitions
    ON containerdefinitions.resource_id = R.id
    AND containerdefinitions.type = 'provider'
    AND lower(containerdefinitions.attr_name) = 'containerdefinitions'
    AND containerdefinitions.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS family
    ON family.resource_id = R.id
    AND family.type = 'provider'
    AND lower(family.attr_name) = 'family'
    AND family.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS taskrolearn
    ON taskrolearn.resource_id = R.id
    AND taskrolearn.type = 'provider'
    AND lower(taskrolearn.attr_name) = 'taskrolearn'
    AND taskrolearn.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS executionrolearn
    ON executionrolearn.resource_id = R.id
    AND executionrolearn.type = 'provider'
    AND lower(executionrolearn.attr_name) = 'executionrolearn'
    AND executionrolearn.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS networkmode
    ON networkmode.resource_id = R.id
    AND networkmode.type = 'provider'
    AND lower(networkmode.attr_name) = 'networkmode'
    AND networkmode.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS revision
    ON revision.resource_id = R.id
    AND revision.type = 'provider'
    AND lower(revision.attr_name) = 'revision'
    AND revision.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS volumes
    ON volumes.resource_id = R.id
    AND volumes.type = 'provider'
    AND lower(volumes.attr_name) = 'volumes'
    AND volumes.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS status
    ON status.resource_id = R.id
    AND status.type = 'provider'
    AND lower(status.attr_name) = 'status'
    AND status.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS requiresattributes
    ON requiresattributes.resource_id = R.id
    AND requiresattributes.type = 'provider'
    AND lower(requiresattributes.attr_name) = 'requiresattributes'
    AND requiresattributes.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS placementconstraints
    ON placementconstraints.resource_id = R.id
    AND placementconstraints.type = 'provider'
    AND lower(placementconstraints.attr_name) = 'placementconstraints'
    AND placementconstraints.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS compatibilities
    ON compatibilities.resource_id = R.id
    AND compatibilities.type = 'provider'
    AND lower(compatibilities.attr_name) = 'compatibilities'
    AND compatibilities.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS requirescompatibilities
    ON requirescompatibilities.resource_id = R.id
    AND requirescompatibilities.type = 'provider'
    AND lower(requirescompatibilities.attr_name) = 'requirescompatibilities'
    AND requirescompatibilities.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS cpu
    ON cpu.resource_id = R.id
    AND cpu.type = 'provider'
    AND lower(cpu.attr_name) = 'cpu'
    AND cpu.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS memory
    ON memory.resource_id = R.id
    AND memory.type = 'provider'
    AND lower(memory.attr_name) = 'memory'
    AND memory.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS inferenceaccelerators
    ON inferenceaccelerators.resource_id = R.id
    AND inferenceaccelerators.type = 'provider'
    AND lower(inferenceaccelerators.attr_name) = 'inferenceaccelerators'
    AND inferenceaccelerators.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS pidmode
    ON pidmode.resource_id = R.id
    AND pidmode.type = 'provider'
    AND lower(pidmode.attr_name) = 'pidmode'
    AND pidmode.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS ipcmode
    ON ipcmode.resource_id = R.id
    AND ipcmode.type = 'provider'
    AND lower(ipcmode.attr_name) = 'ipcmode'
    AND ipcmode.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS proxyconfiguration
    ON proxyconfiguration.resource_id = R.id
    AND proxyconfiguration.type = 'provider'
    AND lower(proxyconfiguration.attr_name) = 'proxyconfiguration'
    AND proxyconfiguration.provider_account_id = R.provider_account_id
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
  AND R.provider_type = 'TaskDefinition'
  AND R.service = 'ecs'
ON CONFLICT (_id) DO UPDATE
SET
    taskdefinitionarn = EXCLUDED.taskdefinitionarn,
    containerdefinitions = EXCLUDED.containerdefinitions,
    family = EXCLUDED.family,
    taskrolearn = EXCLUDED.taskrolearn,
    executionrolearn = EXCLUDED.executionrolearn,
    networkmode = EXCLUDED.networkmode,
    revision = EXCLUDED.revision,
    volumes = EXCLUDED.volumes,
    status = EXCLUDED.status,
    requiresattributes = EXCLUDED.requiresattributes,
    placementconstraints = EXCLUDED.placementconstraints,
    compatibilities = EXCLUDED.compatibilities,
    requirescompatibilities = EXCLUDED.requirescompatibilities,
    cpu = EXCLUDED.cpu,
    memory = EXCLUDED.memory,
    inferenceaccelerators = EXCLUDED.inferenceaccelerators,
    pidmode = EXCLUDED.pidmode,
    ipcmode = EXCLUDED.ipcmode,
    proxyconfiguration = EXCLUDED.proxyconfiguration,
    _tags = EXCLUDED._tags,
    _account_id = EXCLUDED._account_id
  ;


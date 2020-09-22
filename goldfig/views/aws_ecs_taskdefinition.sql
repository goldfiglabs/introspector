DROP MATERIALIZED VIEW IF EXISTS aws_ecs_taskdefinition CASCADE;

CREATE MATERIALIZED VIEW aws_ecs_taskdefinition AS
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
  
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN attrs AS taskdefinitionarn
    ON taskdefinitionarn.id = R.id
    AND taskdefinitionarn.attr_name = 'taskdefinitionarn'
  LEFT JOIN attrs AS containerdefinitions
    ON containerdefinitions.id = R.id
    AND containerdefinitions.attr_name = 'containerdefinitions'
  LEFT JOIN attrs AS family
    ON family.id = R.id
    AND family.attr_name = 'family'
  LEFT JOIN attrs AS taskrolearn
    ON taskrolearn.id = R.id
    AND taskrolearn.attr_name = 'taskrolearn'
  LEFT JOIN attrs AS executionrolearn
    ON executionrolearn.id = R.id
    AND executionrolearn.attr_name = 'executionrolearn'
  LEFT JOIN attrs AS networkmode
    ON networkmode.id = R.id
    AND networkmode.attr_name = 'networkmode'
  LEFT JOIN attrs AS revision
    ON revision.id = R.id
    AND revision.attr_name = 'revision'
  LEFT JOIN attrs AS volumes
    ON volumes.id = R.id
    AND volumes.attr_name = 'volumes'
  LEFT JOIN attrs AS status
    ON status.id = R.id
    AND status.attr_name = 'status'
  LEFT JOIN attrs AS requiresattributes
    ON requiresattributes.id = R.id
    AND requiresattributes.attr_name = 'requiresattributes'
  LEFT JOIN attrs AS placementconstraints
    ON placementconstraints.id = R.id
    AND placementconstraints.attr_name = 'placementconstraints'
  LEFT JOIN attrs AS compatibilities
    ON compatibilities.id = R.id
    AND compatibilities.attr_name = 'compatibilities'
  LEFT JOIN attrs AS requirescompatibilities
    ON requirescompatibilities.id = R.id
    AND requirescompatibilities.attr_name = 'requirescompatibilities'
  LEFT JOIN attrs AS cpu
    ON cpu.id = R.id
    AND cpu.attr_name = 'cpu'
  LEFT JOIN attrs AS memory
    ON memory.id = R.id
    AND memory.attr_name = 'memory'
  LEFT JOIN attrs AS inferenceaccelerators
    ON inferenceaccelerators.id = R.id
    AND inferenceaccelerators.attr_name = 'inferenceaccelerators'
  LEFT JOIN attrs AS pidmode
    ON pidmode.id = R.id
    AND pidmode.attr_name = 'pidmode'
  LEFT JOIN attrs AS ipcmode
    ON ipcmode.id = R.id
    AND ipcmode.attr_name = 'ipcmode'
  LEFT JOIN attrs AS proxyconfiguration
    ON proxyconfiguration.id = R.id
    AND proxyconfiguration.attr_name = 'proxyconfiguration'
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
  AND LOWER(R.provider_type) = 'taskdefinition'
  AND R.service = 'ecs'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_ecs_taskdefinition;

COMMENT ON MATERIALIZED VIEW aws_ecs_taskdefinition IS 'ecs taskdefinition resources and their associated attributes.';


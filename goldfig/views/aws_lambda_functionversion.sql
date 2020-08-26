DROP MATERIALIZED VIEW IF EXISTS aws_lambda_functionversion CASCADE;

CREATE MATERIALIZED VIEW aws_lambda_functionversion AS
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
  functionname.attr_value #>> '{}' AS functionname,
  functionarn.attr_value #>> '{}' AS functionarn,
  runtime.attr_value #>> '{}' AS runtime,
  role.attr_value #>> '{}' AS role,
  handler.attr_value #>> '{}' AS handler,
  (codesize.attr_value #>> '{}')::bigint AS codesize,
  description.attr_value #>> '{}' AS description,
  (timeout.attr_value #>> '{}')::integer AS timeout,
  (memorysize.attr_value #>> '{}')::integer AS memorysize,
  lastmodified.attr_value #>> '{}' AS lastmodified,
  codesha256.attr_value #>> '{}' AS codesha256,
  version.attr_value #>> '{}' AS version,
  vpcconfig.attr_value::jsonb AS vpcconfig,
  deadletterconfig.attr_value::jsonb AS deadletterconfig,
  environment.attr_value::jsonb AS environment,
  kmskeyarn.attr_value #>> '{}' AS kmskeyarn,
  tracingconfig.attr_value::jsonb AS tracingconfig,
  masterarn.attr_value #>> '{}' AS masterarn,
  revisionid.attr_value #>> '{}' AS revisionid,
  layers.attr_value::jsonb AS layers,
  state.attr_value #>> '{}' AS state,
  statereason.attr_value #>> '{}' AS statereason,
  statereasoncode.attr_value #>> '{}' AS statereasoncode,
  lastupdatestatus.attr_value #>> '{}' AS lastupdatestatus,
  lastupdatestatusreason.attr_value #>> '{}' AS lastupdatestatusreason,
  lastupdatestatusreasoncode.attr_value #>> '{}' AS lastupdatestatusreasoncode,
  filesystemconfigs.attr_value::jsonb AS filesystemconfigs,
  Policy.attr_value::jsonb AS policy,
  
    _function_id.target_id AS _function_id,
    _iam_role_id.target_id AS _iam_role_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN attrs AS functionname
    ON functionname.id = R.id
    AND functionname.attr_name = 'functionname'
  LEFT JOIN attrs AS functionarn
    ON functionarn.id = R.id
    AND functionarn.attr_name = 'functionarn'
  LEFT JOIN attrs AS runtime
    ON runtime.id = R.id
    AND runtime.attr_name = 'runtime'
  LEFT JOIN attrs AS role
    ON role.id = R.id
    AND role.attr_name = 'role'
  LEFT JOIN attrs AS handler
    ON handler.id = R.id
    AND handler.attr_name = 'handler'
  LEFT JOIN attrs AS codesize
    ON codesize.id = R.id
    AND codesize.attr_name = 'codesize'
  LEFT JOIN attrs AS description
    ON description.id = R.id
    AND description.attr_name = 'description'
  LEFT JOIN attrs AS timeout
    ON timeout.id = R.id
    AND timeout.attr_name = 'timeout'
  LEFT JOIN attrs AS memorysize
    ON memorysize.id = R.id
    AND memorysize.attr_name = 'memorysize'
  LEFT JOIN attrs AS lastmodified
    ON lastmodified.id = R.id
    AND lastmodified.attr_name = 'lastmodified'
  LEFT JOIN attrs AS codesha256
    ON codesha256.id = R.id
    AND codesha256.attr_name = 'codesha256'
  LEFT JOIN attrs AS version
    ON version.id = R.id
    AND version.attr_name = 'version'
  LEFT JOIN attrs AS vpcconfig
    ON vpcconfig.id = R.id
    AND vpcconfig.attr_name = 'vpcconfig'
  LEFT JOIN attrs AS deadletterconfig
    ON deadletterconfig.id = R.id
    AND deadletterconfig.attr_name = 'deadletterconfig'
  LEFT JOIN attrs AS environment
    ON environment.id = R.id
    AND environment.attr_name = 'environment'
  LEFT JOIN attrs AS kmskeyarn
    ON kmskeyarn.id = R.id
    AND kmskeyarn.attr_name = 'kmskeyarn'
  LEFT JOIN attrs AS tracingconfig
    ON tracingconfig.id = R.id
    AND tracingconfig.attr_name = 'tracingconfig'
  LEFT JOIN attrs AS masterarn
    ON masterarn.id = R.id
    AND masterarn.attr_name = 'masterarn'
  LEFT JOIN attrs AS revisionid
    ON revisionid.id = R.id
    AND revisionid.attr_name = 'revisionid'
  LEFT JOIN attrs AS layers
    ON layers.id = R.id
    AND layers.attr_name = 'layers'
  LEFT JOIN attrs AS state
    ON state.id = R.id
    AND state.attr_name = 'state'
  LEFT JOIN attrs AS statereason
    ON statereason.id = R.id
    AND statereason.attr_name = 'statereason'
  LEFT JOIN attrs AS statereasoncode
    ON statereasoncode.id = R.id
    AND statereasoncode.attr_name = 'statereasoncode'
  LEFT JOIN attrs AS lastupdatestatus
    ON lastupdatestatus.id = R.id
    AND lastupdatestatus.attr_name = 'lastupdatestatus'
  LEFT JOIN attrs AS lastupdatestatusreason
    ON lastupdatestatusreason.id = R.id
    AND lastupdatestatusreason.attr_name = 'lastupdatestatusreason'
  LEFT JOIN attrs AS lastupdatestatusreasoncode
    ON lastupdatestatusreasoncode.id = R.id
    AND lastupdatestatusreasoncode.attr_name = 'lastupdatestatusreasoncode'
  LEFT JOIN attrs AS filesystemconfigs
    ON filesystemconfigs.id = R.id
    AND filesystemconfigs.attr_name = 'filesystemconfigs'
  LEFT JOIN attrs AS Policy
    ON Policy.id = R.id
    AND Policy.attr_name = 'policy'
  LEFT JOIN (
    SELECT
      _aws_lambda_function_relation.resource_id AS resource_id,
      _aws_lambda_function.id AS target_id
    FROM
      resource_relation AS _aws_lambda_function_relation
      INNER JOIN resource AS _aws_lambda_function
        ON _aws_lambda_function_relation.target_id = _aws_lambda_function.id
        AND _aws_lambda_function.provider_type = 'Function'
        AND _aws_lambda_function.service = 'lambda'
    WHERE
      _aws_lambda_function_relation.relation = 'is-version'
  ) AS _function_id ON _function_id.resource_id = R.id
  LEFT JOIN (
    SELECT
      _aws_iam_role_relation.resource_id AS resource_id,
      _aws_iam_role.id AS target_id
    FROM
      resource_relation AS _aws_iam_role_relation
      INNER JOIN resource AS _aws_iam_role
        ON _aws_iam_role_relation.target_id = _aws_iam_role.id
        AND _aws_iam_role.provider_type = 'Role'
        AND _aws_iam_role.service = 'iam'
    WHERE
      _aws_iam_role_relation.relation = 'acts-as'
  ) AS _iam_role_id ON _iam_role_id.resource_id = R.id
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
  AND LOWER(R.provider_type) = 'functionversion'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_lambda_functionversion;

COMMENT ON MATERIALIZED VIEW aws_lambda_functionversion IS 'lambda functionversion resources and their associated attributes.';


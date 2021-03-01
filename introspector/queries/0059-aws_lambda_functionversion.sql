INSERT INTO aws_lambda_functionversion (
  _id,
  uri,
  provider_account_id,
  functionname,
  functionarn,
  runtime,
  role,
  handler,
  codesize,
  description,
  timeout,
  memorysize,
  lastmodified,
  codesha256,
  version,
  vpcconfig,
  deadletterconfig,
  environment,
  kmskeyarn,
  tracingconfig,
  masterarn,
  revisionid,
  layers,
  state,
  statereason,
  statereasoncode,
  lastupdatestatus,
  lastupdatestatusreason,
  lastupdatestatusreasoncode,
  filesystemconfigs,
  signingprofileversionarn,
  signingjobarn,
  policy,
  _function_id,_iam_role_id,_account_id
)
SELECT
  R.id AS _id,
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
  signingprofileversionarn.attr_value #>> '{}' AS signingprofileversionarn,
  signingjobarn.attr_value #>> '{}' AS signingjobarn,
  Policy.attr_value::jsonb AS policy,

    _function_id.target_id AS _function_id,
    _iam_role_id.target_id AS _iam_role_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN resource_attribute AS functionname
    ON functionname.resource_id = R.id
    AND functionname.type = 'provider'
    AND lower(functionname.attr_name) = 'functionname'
  LEFT JOIN resource_attribute AS functionarn
    ON functionarn.resource_id = R.id
    AND functionarn.type = 'provider'
    AND lower(functionarn.attr_name) = 'functionarn'
  LEFT JOIN resource_attribute AS runtime
    ON runtime.resource_id = R.id
    AND runtime.type = 'provider'
    AND lower(runtime.attr_name) = 'runtime'
  LEFT JOIN resource_attribute AS role
    ON role.resource_id = R.id
    AND role.type = 'provider'
    AND lower(role.attr_name) = 'role'
  LEFT JOIN resource_attribute AS handler
    ON handler.resource_id = R.id
    AND handler.type = 'provider'
    AND lower(handler.attr_name) = 'handler'
  LEFT JOIN resource_attribute AS codesize
    ON codesize.resource_id = R.id
    AND codesize.type = 'provider'
    AND lower(codesize.attr_name) = 'codesize'
  LEFT JOIN resource_attribute AS description
    ON description.resource_id = R.id
    AND description.type = 'provider'
    AND lower(description.attr_name) = 'description'
  LEFT JOIN resource_attribute AS timeout
    ON timeout.resource_id = R.id
    AND timeout.type = 'provider'
    AND lower(timeout.attr_name) = 'timeout'
  LEFT JOIN resource_attribute AS memorysize
    ON memorysize.resource_id = R.id
    AND memorysize.type = 'provider'
    AND lower(memorysize.attr_name) = 'memorysize'
  LEFT JOIN resource_attribute AS lastmodified
    ON lastmodified.resource_id = R.id
    AND lastmodified.type = 'provider'
    AND lower(lastmodified.attr_name) = 'lastmodified'
  LEFT JOIN resource_attribute AS codesha256
    ON codesha256.resource_id = R.id
    AND codesha256.type = 'provider'
    AND lower(codesha256.attr_name) = 'codesha256'
  LEFT JOIN resource_attribute AS version
    ON version.resource_id = R.id
    AND version.type = 'provider'
    AND lower(version.attr_name) = 'version'
  LEFT JOIN resource_attribute AS vpcconfig
    ON vpcconfig.resource_id = R.id
    AND vpcconfig.type = 'provider'
    AND lower(vpcconfig.attr_name) = 'vpcconfig'
  LEFT JOIN resource_attribute AS deadletterconfig
    ON deadletterconfig.resource_id = R.id
    AND deadletterconfig.type = 'provider'
    AND lower(deadletterconfig.attr_name) = 'deadletterconfig'
  LEFT JOIN resource_attribute AS environment
    ON environment.resource_id = R.id
    AND environment.type = 'provider'
    AND lower(environment.attr_name) = 'environment'
  LEFT JOIN resource_attribute AS kmskeyarn
    ON kmskeyarn.resource_id = R.id
    AND kmskeyarn.type = 'provider'
    AND lower(kmskeyarn.attr_name) = 'kmskeyarn'
  LEFT JOIN resource_attribute AS tracingconfig
    ON tracingconfig.resource_id = R.id
    AND tracingconfig.type = 'provider'
    AND lower(tracingconfig.attr_name) = 'tracingconfig'
  LEFT JOIN resource_attribute AS masterarn
    ON masterarn.resource_id = R.id
    AND masterarn.type = 'provider'
    AND lower(masterarn.attr_name) = 'masterarn'
  LEFT JOIN resource_attribute AS revisionid
    ON revisionid.resource_id = R.id
    AND revisionid.type = 'provider'
    AND lower(revisionid.attr_name) = 'revisionid'
  LEFT JOIN resource_attribute AS layers
    ON layers.resource_id = R.id
    AND layers.type = 'provider'
    AND lower(layers.attr_name) = 'layers'
  LEFT JOIN resource_attribute AS state
    ON state.resource_id = R.id
    AND state.type = 'provider'
    AND lower(state.attr_name) = 'state'
  LEFT JOIN resource_attribute AS statereason
    ON statereason.resource_id = R.id
    AND statereason.type = 'provider'
    AND lower(statereason.attr_name) = 'statereason'
  LEFT JOIN resource_attribute AS statereasoncode
    ON statereasoncode.resource_id = R.id
    AND statereasoncode.type = 'provider'
    AND lower(statereasoncode.attr_name) = 'statereasoncode'
  LEFT JOIN resource_attribute AS lastupdatestatus
    ON lastupdatestatus.resource_id = R.id
    AND lastupdatestatus.type = 'provider'
    AND lower(lastupdatestatus.attr_name) = 'lastupdatestatus'
  LEFT JOIN resource_attribute AS lastupdatestatusreason
    ON lastupdatestatusreason.resource_id = R.id
    AND lastupdatestatusreason.type = 'provider'
    AND lower(lastupdatestatusreason.attr_name) = 'lastupdatestatusreason'
  LEFT JOIN resource_attribute AS lastupdatestatusreasoncode
    ON lastupdatestatusreasoncode.resource_id = R.id
    AND lastupdatestatusreasoncode.type = 'provider'
    AND lower(lastupdatestatusreasoncode.attr_name) = 'lastupdatestatusreasoncode'
  LEFT JOIN resource_attribute AS filesystemconfigs
    ON filesystemconfigs.resource_id = R.id
    AND filesystemconfigs.type = 'provider'
    AND lower(filesystemconfigs.attr_name) = 'filesystemconfigs'
  LEFT JOIN resource_attribute AS signingprofileversionarn
    ON signingprofileversionarn.resource_id = R.id
    AND signingprofileversionarn.type = 'provider'
    AND lower(signingprofileversionarn.attr_name) = 'signingprofileversionarn'
  LEFT JOIN resource_attribute AS signingjobarn
    ON signingjobarn.resource_id = R.id
    AND signingjobarn.type = 'provider'
    AND lower(signingjobarn.attr_name) = 'signingjobarn'
  LEFT JOIN resource_attribute AS Policy
    ON Policy.resource_id = R.id
    AND Policy.type = 'provider'
    AND lower(Policy.attr_name) = 'policy'
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
      GROUP BY _aws_organizations_account_relation.resource_id
      HAVING COUNT(*) = 1
    ) AS unique_account_mapping
    INNER JOIN resource_relation AS _aws_organizations_account_relation
      ON _aws_organizations_account_relation.resource_id = unique_account_mapping.resource_id
    INNER JOIN resource AS _aws_organizations_account
      ON _aws_organizations_account_relation.target_id = _aws_organizations_account.id
      AND _aws_organizations_account.provider_type = 'Account'
      AND _aws_organizations_account.service = 'organizations'
    WHERE
        _aws_organizations_account_relation.relation = 'in'
  ) AS _account_id ON _account_id.resource_id = R.id
  WHERE
  PA.provider = 'aws'
  AND R.provider_type = 'FunctionVersion'
  AND R.service = 'lambda'
ON CONFLICT (_id) DO UPDATE
SET
    functionname = EXCLUDED.functionname,
    functionarn = EXCLUDED.functionarn,
    runtime = EXCLUDED.runtime,
    role = EXCLUDED.role,
    handler = EXCLUDED.handler,
    codesize = EXCLUDED.codesize,
    description = EXCLUDED.description,
    timeout = EXCLUDED.timeout,
    memorysize = EXCLUDED.memorysize,
    lastmodified = EXCLUDED.lastmodified,
    codesha256 = EXCLUDED.codesha256,
    version = EXCLUDED.version,
    vpcconfig = EXCLUDED.vpcconfig,
    deadletterconfig = EXCLUDED.deadletterconfig,
    environment = EXCLUDED.environment,
    kmskeyarn = EXCLUDED.kmskeyarn,
    tracingconfig = EXCLUDED.tracingconfig,
    masterarn = EXCLUDED.masterarn,
    revisionid = EXCLUDED.revisionid,
    layers = EXCLUDED.layers,
    state = EXCLUDED.state,
    statereason = EXCLUDED.statereason,
    statereasoncode = EXCLUDED.statereasoncode,
    lastupdatestatus = EXCLUDED.lastupdatestatus,
    lastupdatestatusreason = EXCLUDED.lastupdatestatusreason,
    lastupdatestatusreasoncode = EXCLUDED.lastupdatestatusreasoncode,
    filesystemconfigs = EXCLUDED.filesystemconfigs,
    signingprofileversionarn = EXCLUDED.signingprofileversionarn,
    signingjobarn = EXCLUDED.signingjobarn,
    Policy = EXCLUDED.Policy,
    _function_id = EXCLUDED._function_id,
    _iam_role_id = EXCLUDED._iam_role_id,
    _account_id = EXCLUDED._account_id
  ;

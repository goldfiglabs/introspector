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
  packagetype,
  imageconfigresponse,
  signingprofileversionarn,
  signingjobarn,
  policy,
  _function_id,_iam_role_id,_account_id
)
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  attrs.provider ->> 'FunctionName' AS functionname,
  attrs.provider ->> 'FunctionArn' AS functionarn,
  attrs.provider ->> 'Runtime' AS runtime,
  attrs.provider ->> 'Role' AS role,
  attrs.provider ->> 'Handler' AS handler,
  (attrs.provider ->> 'CodeSize')::bigint AS codesize,
  attrs.provider ->> 'Description' AS description,
  (attrs.provider ->> 'Timeout')::integer AS timeout,
  (attrs.provider ->> 'MemorySize')::integer AS memorysize,
  attrs.provider ->> 'LastModified' AS lastmodified,
  attrs.provider ->> 'CodeSha256' AS codesha256,
  attrs.provider ->> 'Version' AS version,
  attrs.provider -> 'VpcConfig' AS vpcconfig,
  attrs.provider -> 'DeadLetterConfig' AS deadletterconfig,
  attrs.provider -> 'Environment' AS environment,
  attrs.provider ->> 'KMSKeyArn' AS kmskeyarn,
  attrs.provider -> 'TracingConfig' AS tracingconfig,
  attrs.provider ->> 'MasterArn' AS masterarn,
  attrs.provider ->> 'RevisionId' AS revisionid,
  attrs.provider -> 'Layers' AS layers,
  attrs.provider ->> 'State' AS state,
  attrs.provider ->> 'StateReason' AS statereason,
  attrs.provider ->> 'StateReasonCode' AS statereasoncode,
  attrs.provider ->> 'LastUpdateStatus' AS lastupdatestatus,
  attrs.provider ->> 'LastUpdateStatusReason' AS lastupdatestatusreason,
  attrs.provider ->> 'LastUpdateStatusReasonCode' AS lastupdatestatusreasoncode,
  attrs.provider -> 'FileSystemConfigs' AS filesystemconfigs,
  attrs.provider ->> 'PackageType' AS packagetype,
  attrs.provider -> 'ImageConfigResponse' AS imageconfigresponse,
  attrs.provider ->> 'SigningProfileVersionArn' AS signingprofileversionarn,
  attrs.provider ->> 'SigningJobArn' AS signingjobarn,
  attrs.provider -> 'Policy' AS policy,
  
    _function_id.target_id AS _function_id,
    _iam_role_id.target_id AS _iam_role_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  LEFT JOIN attrs ON
    attrs.resource_id = R.id
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
        AND _aws_lambda_function.provider_account_id = :provider_account_id
    WHERE
      _aws_lambda_function_relation.relation = 'is-version'
      AND _aws_lambda_function_relation.provider_account_id = :provider_account_id
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
        AND _aws_iam_role.provider_account_id = :provider_account_id
    WHERE
      _aws_iam_role_relation.relation = 'acts-as'
      AND _aws_iam_role_relation.provider_account_id = :provider_account_id
  ) AS _iam_role_id ON _iam_role_id.resource_id = R.id
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
  AND R.provider_type = 'FunctionVersion'
  AND R.service = 'lambda'
ON CONFLICT (_id) DO UPDATE
SET
    FunctionName = EXCLUDED.FunctionName,
    FunctionArn = EXCLUDED.FunctionArn,
    Runtime = EXCLUDED.Runtime,
    Role = EXCLUDED.Role,
    Handler = EXCLUDED.Handler,
    CodeSize = EXCLUDED.CodeSize,
    Description = EXCLUDED.Description,
    Timeout = EXCLUDED.Timeout,
    MemorySize = EXCLUDED.MemorySize,
    LastModified = EXCLUDED.LastModified,
    CodeSha256 = EXCLUDED.CodeSha256,
    Version = EXCLUDED.Version,
    VpcConfig = EXCLUDED.VpcConfig,
    DeadLetterConfig = EXCLUDED.DeadLetterConfig,
    Environment = EXCLUDED.Environment,
    KMSKeyArn = EXCLUDED.KMSKeyArn,
    TracingConfig = EXCLUDED.TracingConfig,
    MasterArn = EXCLUDED.MasterArn,
    RevisionId = EXCLUDED.RevisionId,
    Layers = EXCLUDED.Layers,
    State = EXCLUDED.State,
    StateReason = EXCLUDED.StateReason,
    StateReasonCode = EXCLUDED.StateReasonCode,
    LastUpdateStatus = EXCLUDED.LastUpdateStatus,
    LastUpdateStatusReason = EXCLUDED.LastUpdateStatusReason,
    LastUpdateStatusReasonCode = EXCLUDED.LastUpdateStatusReasonCode,
    FileSystemConfigs = EXCLUDED.FileSystemConfigs,
    PackageType = EXCLUDED.PackageType,
    ImageConfigResponse = EXCLUDED.ImageConfigResponse,
    SigningProfileVersionArn = EXCLUDED.SigningProfileVersionArn,
    SigningJobArn = EXCLUDED.SigningJobArn,
    Policy = EXCLUDED.Policy,
    _function_id = EXCLUDED._function_id,
    _iam_role_id = EXCLUDED._iam_role_id,
    _account_id = EXCLUDED._account_id
  ;


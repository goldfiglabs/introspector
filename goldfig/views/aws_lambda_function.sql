DROP MATERIALIZED VIEW IF EXISTS aws_lambda_function CASCADE;

CREATE MATERIALIZED VIEW aws_lambda_function AS
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
  tags.attr_value::jsonb AS tags,
  Policy.attr_value::jsonb AS policy,
  
    _iam_role_id.target_id AS _iam_role_id,
    _ec2_vpc_id.target_id AS _ec2_vpc_id,
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
  LEFT JOIN resource_attribute AS tags
    ON tags.resource_id = R.id
    AND tags.type = 'provider'
    AND lower(tags.attr_name) = 'tags'
  LEFT JOIN resource_attribute AS Policy
    ON Policy.resource_id = R.id
    AND Policy.type = 'provider'
    AND lower(Policy.attr_name) = 'policy'
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
  AND R.provider_type = 'Function'
  AND R.service = 'lambda'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_lambda_function;

COMMENT ON MATERIALIZED VIEW aws_lambda_function IS 'lambda Function resources and their associated attributes.';



DROP MATERIALIZED VIEW IF EXISTS aws_lambda_function_ec2_securitygroup CASCADE;

CREATE MATERIALIZED VIEW aws_lambda_function_ec2_securitygroup AS
SELECT
  aws_lambda_function.id AS function_id,
  aws_ec2_securitygroup.id AS securitygroup_id
FROM
  resource AS aws_lambda_function
  INNER JOIN resource_relation AS RR
    ON RR.resource_id = aws_lambda_function.id
    AND RR.relation = 'in'
  INNER JOIN resource AS aws_ec2_securitygroup
    ON aws_ec2_securitygroup.id = RR.target_id
    AND aws_ec2_securitygroup.provider_type = 'SecurityGroup'
    AND aws_ec2_securitygroup.service = 'ec2'
  WHERE
    aws_lambda_function.provider_type = 'Function'
    AND aws_lambda_function.service = 'lambda'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_lambda_function_ec2_securitygroup;


DROP MATERIALIZED VIEW IF EXISTS aws_lambda_function_ec2_subnet CASCADE;

CREATE MATERIALIZED VIEW aws_lambda_function_ec2_subnet AS
SELECT
  aws_lambda_function.id AS function_id,
  aws_ec2_subnet.id AS subnet_id
FROM
  resource AS aws_lambda_function
  INNER JOIN resource_relation AS RR
    ON RR.resource_id = aws_lambda_function.id
    AND RR.relation = 'in'
  INNER JOIN resource AS aws_ec2_subnet
    ON aws_ec2_subnet.id = RR.target_id
    AND aws_ec2_subnet.provider_type = 'Subnet'
    AND aws_ec2_subnet.service = 'ec2'
  WHERE
    aws_lambda_function.provider_type = 'Function'
    AND aws_lambda_function.service = 'lambda'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_lambda_function_ec2_subnet;

-- migrate:up

CREATE TABLE IF NOT EXISTS aws_lambda_function (
  _id INTEGER NOT NULL PRIMARY KEY,
  uri TEXT NOT NULL,
  provider_account_id INTEGER NOT NULL,functionname TEXT,
  functionarn TEXT,
  runtime TEXT,
  role TEXT,
  handler TEXT,
  codesize BIGINT,
  description TEXT,
  timeout INTEGER,
  memorysize INTEGER,
  lastmodified TEXT,
  codesha256 TEXT,
  version TEXT,
  vpcconfig JSONB,
  deadletterconfig JSONB,
  environment JSONB,
  kmskeyarn TEXT,
  tracingconfig JSONB,
  masterarn TEXT,
  revisionid TEXT,
  layers JSONB,
  state TEXT,
  statereason TEXT,
  statereasoncode TEXT,
  lastupdatestatus TEXT,
  lastupdatestatusreason TEXT,
  lastupdatestatusreasoncode TEXT,
  filesystemconfigs JSONB,
  signingprofileversionarn TEXT,
  signingjobarn TEXT,
  tags JSONB,
  policy JSONB,
  _iam_role_id INTEGER,
    FOREIGN KEY (_iam_role_id) REFERENCES aws_iam_role (_id) ON DELETE SET NULL,
  _ec2_vpc_id INTEGER,
    FOREIGN KEY (_ec2_vpc_id) REFERENCES aws_ec2_vpc (_id) ON DELETE SET NULL,
  _account_id INTEGER,
    FOREIGN KEY (_account_id) REFERENCES aws_organizations_account (_id) ON DELETE SET NULL,
  FOREIGN KEY (provider_account_id) REFERENCES public.provider_account (id) ON DELETE CASCADE,
  FOREIGN KEY (_id) REFERENCES public.resource (id) ON DELETE CASCADE
);

COMMENT ON TABLE aws_lambda_function IS 'lambda Function resources and their associated attributes.';

ALTER TABLE aws_lambda_function ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_lambda_function ON aws_lambda_function
USING (
  current_user = 'goldfig_ro'
  OR
  provider_account_id = current_setting('gf.provider_account_id', true)::int
);



CREATE TABLE IF NOT EXISTS aws_lambda_function_ec2_securitygroup (
  function_id INTEGER NOT NULL REFERENCES aws_lambda_function (_id) ON DELETE CASCADE,
  securitygroup_id INTEGER NOT NULL REFERENCES aws_ec2_securitygroup (_id) ON DELETE CASCADE,
  provider_account_id INTEGER NOT NULL REFERENCES provider_account (id) ON DELETE CASCADE,PRIMARY KEY (function_id, securitygroup_id)
);

ALTER TABLE aws_lambda_function_ec2_securitygroup ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_lambda_function_ec2_securitygroup ON aws_lambda_function_ec2_securitygroup
USING (
  current_user = 'goldfig_ro'
  OR
  provider_account_id = current_setting('gf.provider_account_id', true)::int
);



CREATE TABLE IF NOT EXISTS aws_lambda_function_ec2_subnet (
  function_id INTEGER NOT NULL REFERENCES aws_lambda_function (_id) ON DELETE CASCADE,
  subnet_id INTEGER NOT NULL REFERENCES aws_ec2_subnet (_id) ON DELETE CASCADE,
  provider_account_id INTEGER NOT NULL REFERENCES provider_account (id) ON DELETE CASCADE,PRIMARY KEY (function_id, subnet_id)
);

ALTER TABLE aws_lambda_function_ec2_subnet ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_lambda_function_ec2_subnet ON aws_lambda_function_ec2_subnet
USING (
  current_user = 'goldfig_ro'
  OR
  provider_account_id = current_setting('gf.provider_account_id', true)::int
);


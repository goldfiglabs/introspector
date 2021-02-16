-- migrate:up

CREATE TABLE IF NOT EXISTS aws_lambda_functionversion (
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
  policy JSONB,
  _function_id INTEGER,
    FOREIGN KEY (_function_id) REFERENCES aws_lambda_function (_id) ON DELETE SET NULL,
  _iam_role_id INTEGER,
    FOREIGN KEY (_iam_role_id) REFERENCES aws_iam_role (_id) ON DELETE SET NULL,
  _account_id INTEGER,
    FOREIGN KEY (_account_id) REFERENCES aws_organizations_account (_id) ON DELETE SET NULL,
  FOREIGN KEY (provider_account_id) REFERENCES public.provider_account (id) ON DELETE CASCADE,
  FOREIGN KEY (_id) REFERENCES public.resource (id) ON DELETE CASCADE
);

COMMENT ON TABLE aws_lambda_functionversion IS 'lambda FunctionVersion resources and their associated attributes.';

ALTER TABLE aws_lambda_functionversion ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_lambda_functionversion ON aws_lambda_functionversion
USING (
  current_user = 'introspector_ro'
  OR
  provider_account_id = current_setting('introspector.provider_account_id', true)::int
);


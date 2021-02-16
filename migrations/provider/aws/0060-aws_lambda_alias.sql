-- migrate:up

CREATE TABLE IF NOT EXISTS aws_lambda_alias (
  _id INTEGER NOT NULL PRIMARY KEY,
  uri TEXT NOT NULL,
  provider_account_id INTEGER NOT NULL,aliasarn TEXT,
  name TEXT,
  functionversion TEXT,
  description TEXT,
  routingconfig JSONB,
  revisionid TEXT,
  policy JSONB,
  _function_id INTEGER,
    FOREIGN KEY (_function_id) REFERENCES aws_lambda_function (_id) ON DELETE SET NULL,
  _account_id INTEGER,
    FOREIGN KEY (_account_id) REFERENCES aws_organizations_account (_id) ON DELETE SET NULL,
  FOREIGN KEY (provider_account_id) REFERENCES public.provider_account (id) ON DELETE CASCADE,
  FOREIGN KEY (_id) REFERENCES public.resource (id) ON DELETE CASCADE
);

COMMENT ON TABLE aws_lambda_alias IS 'lambda Alias resources and their associated attributes.';

ALTER TABLE aws_lambda_alias ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_lambda_alias ON aws_lambda_alias
USING (
  current_user = 'introspector_ro'
  OR
  provider_account_id = current_setting('introspector.provider_account_id', true)::int
);



CREATE TABLE IF NOT EXISTS aws_lambda_alias_functionversion (
  alias_id INTEGER NOT NULL REFERENCES aws_lambda_alias (_id) ON DELETE CASCADE,
  functionversion_id INTEGER NOT NULL REFERENCES aws_lambda_functionversion (_id) ON DELETE CASCADE,
  provider_account_id INTEGER NOT NULL REFERENCES provider_account (id) ON DELETE CASCADE,weight DOUBLE PRECISION,
  PRIMARY KEY (alias_id, functionversion_id)
);

ALTER TABLE aws_lambda_alias_functionversion ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_lambda_alias_functionversion ON aws_lambda_alias_functionversion
USING (
  current_user = 'introspector_ro'
  OR
  provider_account_id = current_setting('introspector.provider_account_id', true)::int
);


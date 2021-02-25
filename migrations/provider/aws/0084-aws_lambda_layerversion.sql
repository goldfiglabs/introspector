-- migrate:up

CREATE TABLE IF NOT EXISTS aws_lambda_layerversion (
  _id INTEGER NOT NULL PRIMARY KEY,
  uri TEXT NOT NULL,
  provider_account_id INTEGER NOT NULL,
  layerversionarn TEXT,
  version BIGINT,
  description TEXT,
  createddate TEXT,
  compatibleruntimes JSONB,
  licenseinfo TEXT,
  policy JSONB,
  name TEXT,
  _policy JSONB,
  _account_id INTEGER,
    FOREIGN KEY (_account_id) REFERENCES aws_organizations_account (_id) ON DELETE SET NULL,
  FOREIGN KEY (provider_account_id) REFERENCES public.provider_account (id) ON DELETE CASCADE,
  FOREIGN KEY (_id) REFERENCES public.resource (id) ON DELETE CASCADE
);

COMMENT ON TABLE aws_lambda_layerversion IS 'lambda LayerVersion resources and their associated attributes.';

ALTER TABLE aws_lambda_layerversion ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_lambda_layerversion ON aws_lambda_layerversion
USING (
  current_user = 'introspector_ro'
  OR
  provider_account_id = current_setting('introspector.provider_account_id', true)::int
);


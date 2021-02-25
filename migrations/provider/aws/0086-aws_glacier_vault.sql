-- migrate:up

CREATE TABLE IF NOT EXISTS aws_glacier_vault (
  _id INTEGER NOT NULL PRIMARY KEY,
  uri TEXT NOT NULL,
  provider_account_id INTEGER NOT NULL,
  vaultarn TEXT,
  vaultname TEXT,
  creationdate TEXT,
  lastinventorydate TEXT,
  numberofarchives BIGINT,
  sizeinbytes BIGINT,
  policy JSONB,
  tags JSONB,
  _tags JSONB,
  _policy JSONB,
  _account_id INTEGER,
    FOREIGN KEY (_account_id) REFERENCES aws_organizations_account (_id) ON DELETE SET NULL,
  FOREIGN KEY (provider_account_id) REFERENCES public.provider_account (id) ON DELETE CASCADE,
  FOREIGN KEY (_id) REFERENCES public.resource (id) ON DELETE CASCADE
);

COMMENT ON TABLE aws_glacier_vault IS 'glacier Vault resources and their associated attributes.';

ALTER TABLE aws_glacier_vault ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_glacier_vault ON aws_glacier_vault
USING (
  current_user = 'introspector_ro'
  OR
  provider_account_id = current_setting('introspector.provider_account_id', true)::int
);


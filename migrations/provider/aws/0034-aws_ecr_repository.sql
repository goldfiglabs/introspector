-- migrate:up

CREATE TABLE IF NOT EXISTS aws_ecr_repository (
  _id INTEGER NOT NULL PRIMARY KEY,
  uri TEXT NOT NULL,
  provider_account_id INTEGER NOT NULL,repositoryarn TEXT,
  registryid TEXT,
  repositoryname TEXT,
  repositoryuri TEXT,
  createdat TIMESTAMP WITH TIME ZONE,
  imagetagmutability TEXT,
  imagescanningconfiguration JSONB,
  encryptionconfiguration JSONB,
  tags JSONB,
  policy JSONB,
  _account_id INTEGER,
    FOREIGN KEY (_account_id) REFERENCES aws_organizations_account (_id) ON DELETE SET NULL,
  FOREIGN KEY (provider_account_id) REFERENCES public.provider_account (id) ON DELETE CASCADE,
  FOREIGN KEY (_id) REFERENCES public.resource (id) ON DELETE CASCADE
);

COMMENT ON TABLE aws_ecr_repository IS 'ecr Repository resources and their associated attributes.';

ALTER TABLE aws_ecr_repository ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_ecr_repository ON aws_ecr_repository
USING (
  current_user = 'goldfig_ro'
  OR
  provider_account_id = current_setting('gf.provider_account_id', true)::int
);


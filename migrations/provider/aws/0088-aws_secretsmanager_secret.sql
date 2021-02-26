-- migrate:up

CREATE TABLE IF NOT EXISTS aws_secretsmanager_secret (
  _id INTEGER NOT NULL PRIMARY KEY,
  uri TEXT NOT NULL,
  provider_account_id INTEGER NOT NULL,
  arn TEXT,
  name TEXT,
  description TEXT,
  kmskeyid TEXT,
  rotationenabled BOOLEAN,
  rotationlambdaarn TEXT,
  rotationrules JSONB,
  lastrotateddate TIMESTAMP WITH TIME ZONE,
  lastchangeddate TIMESTAMP WITH TIME ZONE,
  lastaccesseddate TIMESTAMP WITH TIME ZONE,
  deleteddate TIMESTAMP WITH TIME ZONE,
  tags JSONB,
  secretversionstostages JSONB,
  owningservice TEXT,
  createddate TIMESTAMP WITH TIME ZONE,
  _tags JSONB,
  _policy JSONB,
  _kms_key_id INTEGER,
    FOREIGN KEY (_kms_key_id) REFERENCES aws_kms_key (_id) ON DELETE SET NULL,
  _account_id INTEGER,
    FOREIGN KEY (_account_id) REFERENCES aws_organizations_account (_id) ON DELETE SET NULL,
  FOREIGN KEY (provider_account_id) REFERENCES public.provider_account (id) ON DELETE CASCADE,
  FOREIGN KEY (_id) REFERENCES public.resource (id) ON DELETE CASCADE
);

COMMENT ON TABLE aws_secretsmanager_secret IS 'secretsmanager Secret resources and their associated attributes.';

ALTER TABLE aws_secretsmanager_secret ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_secretsmanager_secret ON aws_secretsmanager_secret
USING (
  current_user = 'introspector_ro'
  OR
  provider_account_id = current_setting('introspector.provider_account_id', true)::int
);


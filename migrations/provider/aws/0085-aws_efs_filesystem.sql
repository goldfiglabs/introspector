-- migrate:up

CREATE TABLE IF NOT EXISTS aws_efs_filesystem (
  _id INTEGER NOT NULL PRIMARY KEY,
  uri TEXT NOT NULL,
  provider_account_id INTEGER NOT NULL,
  ownerid TEXT,
  creationtoken TEXT,
  filesystemid TEXT,
  filesystemarn TEXT,
  creationtime TIMESTAMP WITH TIME ZONE,
  lifecyclestate TEXT,
  name TEXT,
  numberofmounttargets INTEGER,
  sizeinbytes JSONB,
  performancemode TEXT,
  encrypted BOOLEAN,
  kmskeyid TEXT,
  throughputmode TEXT,
  provisionedthroughputinmibps DOUBLE PRECISION,
  tags JSONB,
  policy JSONB,
  _tags JSONB,
  _policy JSONB,
  _kms_key_id INTEGER,
    FOREIGN KEY (_kms_key_id) REFERENCES aws_kms_key (_id) ON DELETE SET NULL,
  _account_id INTEGER,
    FOREIGN KEY (_account_id) REFERENCES aws_organizations_account (_id) ON DELETE SET NULL,
  FOREIGN KEY (provider_account_id) REFERENCES public.provider_account (id) ON DELETE CASCADE,
  FOREIGN KEY (_id) REFERENCES public.resource (id) ON DELETE CASCADE
);

COMMENT ON TABLE aws_efs_filesystem IS 'efs FileSystem resources and their associated attributes.';

ALTER TABLE aws_efs_filesystem ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_efs_filesystem ON aws_efs_filesystem
USING (
  current_user = 'introspector_ro'
  OR
  provider_account_id = current_setting('introspector.provider_account_id', true)::int
);


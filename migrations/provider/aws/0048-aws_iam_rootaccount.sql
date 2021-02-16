-- migrate:up

CREATE TABLE IF NOT EXISTS aws_iam_rootaccount (
  _id INTEGER NOT NULL PRIMARY KEY,
  uri TEXT NOT NULL,
  provider_account_id INTEGER NOT NULL,arn TEXT,
  has_virtual_mfa BOOLEAN,
  mfa_active BOOLEAN,
  access_key_1_active BOOLEAN,
  access_key_2_active BOOLEAN,
  cert_1_active BOOLEAN,
  cert_2_active BOOLEAN,
  password_last_used TIMESTAMP WITH TIME ZONE,
  _account_id INTEGER,
    FOREIGN KEY (_account_id) REFERENCES aws_organizations_account (_id) ON DELETE SET NULL,
  FOREIGN KEY (provider_account_id) REFERENCES public.provider_account (id) ON DELETE CASCADE,
  FOREIGN KEY (_id) REFERENCES public.resource (id) ON DELETE CASCADE
);

COMMENT ON TABLE aws_iam_rootaccount IS 'iam RootAccount resources and their associated attributes.';

ALTER TABLE aws_iam_rootaccount ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_iam_rootaccount ON aws_iam_rootaccount
USING (
  current_user = 'introspector_ro'
  OR
  provider_account_id = current_setting('introspector.provider_account_id', true)::int
);


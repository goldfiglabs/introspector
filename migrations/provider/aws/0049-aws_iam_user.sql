-- migrate:up

CREATE TABLE IF NOT EXISTS aws_iam_user (
  _id INTEGER NOT NULL PRIMARY KEY,
  uri TEXT NOT NULL,
  provider_account_id INTEGER NOT NULL,path TEXT,
  username TEXT,
  userid TEXT,
  arn TEXT,
  createdate TIMESTAMP WITH TIME ZONE,
  passwordlastused TIMESTAMP WITH TIME ZONE,
  permissionsboundary JSONB,
  tags JSONB,
  policylist JSONB,
  attachedpolicies JSONB,
  accesskeys JSONB,
  groups JSONB,
  mfadevices JSONB,
  sshpublickeys JSONB,
  servicespecificcredentials JSONB,
  certificates JSONB,
  loginprofile JSONB,
  password_enabled BOOLEAN,
  password_last_changed TIMESTAMP WITH TIME ZONE,
  password_next_rotation TIMESTAMP WITH TIME ZONE,
  mfa_active BOOLEAN,
  access_key_1_active BOOLEAN,
  access_key_1_last_rotated TIMESTAMP WITH TIME ZONE,
  access_key_1_last_used_date TIMESTAMP WITH TIME ZONE,
  access_key_1_last_used_region TEXT,
  access_key_1_last_used_service TEXT,
  access_key_2_active BOOLEAN,
  access_key_2_last_rotated TIMESTAMP WITH TIME ZONE,
  access_key_2_last_used_date TIMESTAMP WITH TIME ZONE,
  access_key_2_last_used_region TEXT,
  access_key_2_last_used_service TEXT,
  cert_1_active BOOLEAN,
  cert_1_last_rotated TIMESTAMP WITH TIME ZONE,
  cert_2_active BOOLEAN,
  cert_2_last_rotated TIMESTAMP WITH TIME ZONE,
  _account_id INTEGER,
    FOREIGN KEY (_account_id) REFERENCES aws_organizations_account (_id) ON DELETE SET NULL,
  FOREIGN KEY (provider_account_id) REFERENCES public.provider_account (id) ON DELETE CASCADE,
  FOREIGN KEY (_id) REFERENCES public.resource (id) ON DELETE CASCADE
);

COMMENT ON TABLE aws_iam_user IS 'iam User resources and their associated attributes.';

ALTER TABLE aws_iam_user ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_iam_user ON aws_iam_user
USING (
  current_user = 'introspector_ro'
  OR
  provider_account_id = current_setting('introspector.provider_account_id', true)::int
);


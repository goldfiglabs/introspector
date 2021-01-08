-- migrate:up

CREATE TABLE IF NOT EXISTS aws_ssm_parameter (
  _id INTEGER NOT NULL PRIMARY KEY,
  uri TEXT NOT NULL,
  provider_account_id INTEGER NOT NULL,name TEXT,
  type TEXT,
  keyid TEXT,
  lastmodifieddate TIMESTAMP WITH TIME ZONE,
  lastmodifieduser TEXT,
  description TEXT,
  allowedpattern TEXT,
  version BIGINT,
  tier TEXT,
  policies JSONB,
  datatype TEXT,
  tags JSONB,
  _kms_key_id INTEGER,
    FOREIGN KEY (_kms_key_id) REFERENCES aws_kms_key (_id) ON DELETE SET NULL,
  _account_id INTEGER,
    FOREIGN KEY (_account_id) REFERENCES aws_organizations_account (_id) ON DELETE SET NULL,
  FOREIGN KEY (provider_account_id) REFERENCES public.provider_account (id) ON DELETE CASCADE,
  FOREIGN KEY (_id) REFERENCES public.resource (id) ON DELETE CASCADE
);

COMMENT ON TABLE aws_ssm_parameter IS 'ssm Parameter resources and their associated attributes.';

ALTER TABLE aws_ssm_parameter ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_ssm_parameter ON aws_ssm_parameter
USING (
  current_user = 'goldfig_ro'
  OR
  provider_account_id = current_setting('gf.provider_account_id', true)::int
);


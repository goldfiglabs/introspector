-- migrate:up

CREATE TABLE IF NOT EXISTS aws_iam_passwordpolicy (
  _id INTEGER NOT NULL PRIMARY KEY,
  uri TEXT NOT NULL,
  provider_account_id INTEGER NOT NULL,minimumpasswordlength INTEGER,
  requiresymbols BOOLEAN,
  requirenumbers BOOLEAN,
  requireuppercasecharacters BOOLEAN,
  requirelowercasecharacters BOOLEAN,
  allowuserstochangepassword BOOLEAN,
  expirepasswords BOOLEAN,
  maxpasswordage INTEGER,
  passwordreuseprevention INTEGER,
  hardexpiry BOOLEAN,
  _account_id INTEGER,
    FOREIGN KEY (_account_id) REFERENCES aws_organizations_account (_id) ON DELETE SET NULL,
  FOREIGN KEY (provider_account_id) REFERENCES public.provider_account (id) ON DELETE CASCADE,
  FOREIGN KEY (_id) REFERENCES public.resource (id) ON DELETE CASCADE
);

COMMENT ON TABLE aws_iam_passwordpolicy IS 'iam PasswordPolicy resources and their associated attributes.';

ALTER TABLE aws_iam_passwordpolicy ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_iam_passwordpolicy ON aws_iam_passwordpolicy
USING (
  current_user = 'introspector_ro'
  OR
  provider_account_id = current_setting('introspector.provider_account_id', true)::int
);


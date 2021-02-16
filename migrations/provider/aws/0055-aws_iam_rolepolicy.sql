-- migrate:up

CREATE TABLE IF NOT EXISTS aws_iam_rolepolicy (
  _id INTEGER NOT NULL PRIMARY KEY,
  uri TEXT NOT NULL,
  provider_account_id INTEGER NOT NULL,rolename TEXT,
  policyname TEXT,
  policydocument JSONB,
  _role_id INTEGER,
    FOREIGN KEY (_role_id) REFERENCES aws_iam_role (_id) ON DELETE SET NULL,
  _account_id INTEGER,
    FOREIGN KEY (_account_id) REFERENCES aws_organizations_account (_id) ON DELETE SET NULL,
  FOREIGN KEY (provider_account_id) REFERENCES public.provider_account (id) ON DELETE CASCADE,
  FOREIGN KEY (_id) REFERENCES public.resource (id) ON DELETE CASCADE
);

COMMENT ON TABLE aws_iam_rolepolicy IS 'iam RolePolicy resources and their associated attributes.';

ALTER TABLE aws_iam_rolepolicy ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_iam_rolepolicy ON aws_iam_rolepolicy
USING (
  current_user = 'introspector_ro'
  OR
  provider_account_id = current_setting('introspector.provider_account_id', true)::int
);


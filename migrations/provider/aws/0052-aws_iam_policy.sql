-- migrate:up

CREATE TABLE IF NOT EXISTS aws_iam_policy (
  _id INTEGER NOT NULL PRIMARY KEY,
  uri TEXT NOT NULL,
  provider_account_id INTEGER NOT NULL,policyname TEXT,
  policyid TEXT,
  arn TEXT,
  path TEXT,
  defaultversionid TEXT,
  attachmentcount INTEGER,
  permissionsboundaryusagecount INTEGER,
  isattachable BOOLEAN,
  description TEXT,
  createdate TIMESTAMP WITH TIME ZONE,
  updatedate TIMESTAMP WITH TIME ZONE,
  policygroups JSONB,
  policyusers JSONB,
  policyroles JSONB,
  versions JSONB,
  _account_id INTEGER,
    FOREIGN KEY (_account_id) REFERENCES aws_organizations_account (_id) ON DELETE SET NULL,
  FOREIGN KEY (provider_account_id) REFERENCES public.provider_account (id) ON DELETE CASCADE,
  FOREIGN KEY (_id) REFERENCES public.resource (id) ON DELETE CASCADE
);

COMMENT ON TABLE aws_iam_policy IS 'iam Policy resources and their associated attributes.';

ALTER TABLE aws_iam_policy ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_iam_policy ON aws_iam_policy
USING (
  current_user = 'goldfig_ro'
  OR
  provider_account_id = current_setting('gf.provider_account_id', true)::int
);



CREATE TABLE IF NOT EXISTS aws_iam_policy_group (
  policy_id INTEGER NOT NULL REFERENCES aws_iam_policy (_id) ON DELETE CASCADE,
  group_id INTEGER NOT NULL REFERENCES aws_iam_group (_id) ON DELETE CASCADE,
  provider_account_id INTEGER NOT NULL REFERENCES provider_account (id) ON DELETE CASCADE,PRIMARY KEY (policy_id, group_id)
);

ALTER TABLE aws_iam_policy_group ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_iam_policy_group ON aws_iam_policy_group
USING (
  current_user = 'goldfig_ro'
  OR
  provider_account_id = current_setting('gf.provider_account_id', true)::int
);



CREATE TABLE IF NOT EXISTS aws_iam_policy_role (
  policy_id INTEGER NOT NULL REFERENCES aws_iam_policy (_id) ON DELETE CASCADE,
  role_id INTEGER NOT NULL REFERENCES aws_iam_role (_id) ON DELETE CASCADE,
  provider_account_id INTEGER NOT NULL REFERENCES provider_account (id) ON DELETE CASCADE,PRIMARY KEY (policy_id, role_id)
);

ALTER TABLE aws_iam_policy_role ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_iam_policy_role ON aws_iam_policy_role
USING (
  current_user = 'goldfig_ro'
  OR
  provider_account_id = current_setting('gf.provider_account_id', true)::int
);



CREATE TABLE IF NOT EXISTS aws_iam_policy_user (
  policy_id INTEGER NOT NULL REFERENCES aws_iam_policy (_id) ON DELETE CASCADE,
  user_id INTEGER NOT NULL REFERENCES aws_iam_user (_id) ON DELETE CASCADE,
  provider_account_id INTEGER NOT NULL REFERENCES provider_account (id) ON DELETE CASCADE,PRIMARY KEY (policy_id, user_id)
);

ALTER TABLE aws_iam_policy_user ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_iam_policy_user ON aws_iam_policy_user
USING (
  current_user = 'goldfig_ro'
  OR
  provider_account_id = current_setting('gf.provider_account_id', true)::int
);


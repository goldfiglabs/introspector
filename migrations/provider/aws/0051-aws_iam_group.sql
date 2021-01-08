-- migrate:up

CREATE TABLE IF NOT EXISTS aws_iam_group (
  _id INTEGER NOT NULL PRIMARY KEY,
  uri TEXT NOT NULL,
  provider_account_id INTEGER NOT NULL,path TEXT,
  groupname TEXT,
  groupid TEXT,
  arn TEXT,
  createdate TIMESTAMP WITH TIME ZONE,
  policylist JSONB,
  attachedpolicies JSONB,
  _account_id INTEGER,
    FOREIGN KEY (_account_id) REFERENCES aws_organizations_account (_id) ON DELETE SET NULL,
  FOREIGN KEY (provider_account_id) REFERENCES public.provider_account (id) ON DELETE CASCADE,
  FOREIGN KEY (_id) REFERENCES public.resource (id) ON DELETE CASCADE
);

COMMENT ON TABLE aws_iam_group IS 'iam Group resources and their associated attributes.';

ALTER TABLE aws_iam_group ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_iam_group ON aws_iam_group
USING (
  current_user = 'goldfig_ro'
  OR
  provider_account_id = current_setting('gf.provider_account_id', true)::int
);



CREATE TABLE IF NOT EXISTS aws_iam_group_user (
  group_id INTEGER NOT NULL REFERENCES aws_iam_group (_id) ON DELETE CASCADE,
  user_id INTEGER NOT NULL REFERENCES aws_iam_user (_id) ON DELETE CASCADE,
  provider_account_id INTEGER NOT NULL REFERENCES provider_account (id) ON DELETE CASCADE,PRIMARY KEY (group_id, user_id)
);

ALTER TABLE aws_iam_group_user ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_iam_group_user ON aws_iam_group_user
USING (
  current_user = 'goldfig_ro'
  OR
  provider_account_id = current_setting('gf.provider_account_id', true)::int
);


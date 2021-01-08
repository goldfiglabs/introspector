-- migrate:up

CREATE TABLE IF NOT EXISTS aws_iam_policyversion (
  _id INTEGER NOT NULL PRIMARY KEY,
  uri TEXT NOT NULL,
  provider_account_id INTEGER NOT NULL,document JSONB,
  versionid TEXT,
  isdefaultversion BOOLEAN,
  createdate TIMESTAMP WITH TIME ZONE,
  _policy_id INTEGER,
    FOREIGN KEY (_policy_id) REFERENCES aws_iam_policy (_id) ON DELETE SET NULL,
  _account_id INTEGER,
    FOREIGN KEY (_account_id) REFERENCES aws_organizations_account (_id) ON DELETE SET NULL,
  FOREIGN KEY (provider_account_id) REFERENCES public.provider_account (id) ON DELETE CASCADE,
  FOREIGN KEY (_id) REFERENCES public.resource (id) ON DELETE CASCADE
);

COMMENT ON TABLE aws_iam_policyversion IS 'iam PolicyVersion resources and their associated attributes.';

ALTER TABLE aws_iam_policyversion ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_iam_policyversion ON aws_iam_policyversion
USING (
  current_user = 'goldfig_ro'
  OR
  provider_account_id = current_setting('gf.provider_account_id', true)::int
);


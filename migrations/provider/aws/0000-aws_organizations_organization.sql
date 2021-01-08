-- migrate:up

CREATE TABLE IF NOT EXISTS aws_organizations_organization (
  _id INTEGER NOT NULL PRIMARY KEY,
  uri TEXT NOT NULL,
  provider_account_id INTEGER NOT NULL,id TEXT,
  arn TEXT,
  featureset TEXT,
  masteraccountarn TEXT,
  masteraccountid TEXT,
  masteraccountemail TEXT,
  availablepolicytypes JSONB,
  servicecontrolpolicies JSONB,
  tagpolicies JSONB,
  FOREIGN KEY (provider_account_id) REFERENCES public.provider_account (id) ON DELETE CASCADE,
  FOREIGN KEY (_id) REFERENCES public.resource (id) ON DELETE CASCADE
);

COMMENT ON TABLE aws_organizations_organization IS 'organizations Organization resources and their associated attributes.';

ALTER TABLE aws_organizations_organization ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_organizations_organization ON aws_organizations_organization
USING (
  current_user = 'goldfig_ro'
  OR
  provider_account_id = current_setting('gf.provider_account_id', true)::int
);


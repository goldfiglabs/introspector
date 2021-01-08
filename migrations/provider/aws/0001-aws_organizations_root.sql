-- migrate:up

CREATE TABLE IF NOT EXISTS aws_organizations_root (
  _id INTEGER NOT NULL PRIMARY KEY,
  uri TEXT NOT NULL,
  provider_account_id INTEGER NOT NULL,id TEXT,
  arn TEXT,
  name TEXT,
  policytypes JSONB,
  servicecontrolpolicies JSONB,
  tagpolicies JSONB,
  _organization_id INTEGER,
    FOREIGN KEY (_organization_id) REFERENCES aws_organizations_organization (_id) ON DELETE SET NULL,
  FOREIGN KEY (provider_account_id) REFERENCES public.provider_account (id) ON DELETE CASCADE,
  FOREIGN KEY (_id) REFERENCES public.resource (id) ON DELETE CASCADE
);

COMMENT ON TABLE aws_organizations_root IS 'organizations Root resources and their associated attributes.';

ALTER TABLE aws_organizations_root ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_organizations_root ON aws_organizations_root
USING (
  current_user = 'goldfig_ro'
  OR
  provider_account_id = current_setting('gf.provider_account_id', true)::int
);


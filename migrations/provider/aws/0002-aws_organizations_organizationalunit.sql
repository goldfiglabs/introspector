-- migrate:up

CREATE TABLE IF NOT EXISTS aws_organizations_organizationalunit (
  _id INTEGER NOT NULL PRIMARY KEY,
  uri TEXT NOT NULL,
  provider_account_id INTEGER NOT NULL,id TEXT,
  arn TEXT,
  name TEXT,
  servicecontrolpolicies JSONB,
  tagpolicies JSONB,
  _root_id INTEGER,
    FOREIGN KEY (_root_id) REFERENCES aws_organizations_root (_id) ON DELETE SET NULL,
  _organizational_unit_id INTEGER,
    FOREIGN KEY (_organizational_unit_id) REFERENCES aws_organizations_organizationalunit (_id) ON DELETE SET NULL,
  FOREIGN KEY (provider_account_id) REFERENCES public.provider_account (id) ON DELETE CASCADE,
  FOREIGN KEY (_id) REFERENCES public.resource (id) ON DELETE CASCADE
);

COMMENT ON TABLE aws_organizations_organizationalunit IS 'organizations OrganizationalUnit resources and their associated attributes.';

ALTER TABLE aws_organizations_organizationalunit ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_organizations_organizationalunit ON aws_organizations_organizationalunit
USING (
  current_user = 'introspector_ro'
  OR
  provider_account_id = current_setting('introspector.provider_account_id', true)::int
);


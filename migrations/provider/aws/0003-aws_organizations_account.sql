-- migrate:up

CREATE TABLE IF NOT EXISTS aws_organizations_account (
  _id INTEGER NOT NULL PRIMARY KEY,
  uri TEXT NOT NULL,
  provider_account_id INTEGER NOT NULL,id TEXT,
  arn TEXT,
  email TEXT,
  name TEXT,
  status TEXT,
  joinedmethod TEXT,
  joinedtimestamp TIMESTAMP WITH TIME ZONE,
  servicecontrolpolicies JSONB,
  tagpolicies JSONB,
  tags JSONB,
  _root_id INTEGER,
    FOREIGN KEY (_root_id) REFERENCES aws_organizations_root (_id) ON DELETE SET NULL,
  _organizational_unit_id INTEGER,
    FOREIGN KEY (_organizational_unit_id) REFERENCES aws_organizations_organizationalunit (_id) ON DELETE SET NULL,
  FOREIGN KEY (provider_account_id) REFERENCES public.provider_account (id) ON DELETE CASCADE,
  FOREIGN KEY (_id) REFERENCES public.resource (id) ON DELETE CASCADE
);

COMMENT ON TABLE aws_organizations_account IS 'organizations Account resources and their associated attributes.';

ALTER TABLE aws_organizations_account ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_organizations_account ON aws_organizations_account
USING (
  current_user = 'introspector_ro'
  OR
  provider_account_id = current_setting('introspector.provider_account_id', true)::int
);


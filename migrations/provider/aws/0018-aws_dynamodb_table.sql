-- migrate:up

CREATE TABLE IF NOT EXISTS aws_dynamodb_table (
  _id INTEGER NOT NULL PRIMARY KEY,
  uri TEXT NOT NULL,
  provider_account_id INTEGER NOT NULL,attributedefinitions JSONB,
  tablename TEXT,
  keyschema JSONB,
  tablestatus TEXT,
  creationdatetime TIMESTAMP WITH TIME ZONE,
  provisionedthroughput JSONB,
  tablesizebytes BIGINT,
  itemcount BIGINT,
  tablearn TEXT,
  tableid TEXT,
  billingmodesummary JSONB,
  localsecondaryindexes JSONB,
  globalsecondaryindexes JSONB,
  streamspecification JSONB,
  lateststreamlabel TEXT,
  lateststreamarn TEXT,
  globaltableversion TEXT,
  replicas JSONB,
  restoresummary JSONB,
  ssedescription JSONB,
  archivalsummary JSONB,
  continuousbackupsstatus TEXT,
  pointintimerecoverydescription JSONB,
  tags JSONB,
  _account_id INTEGER,
    FOREIGN KEY (_account_id) REFERENCES aws_organizations_account (_id) ON DELETE SET NULL,
  FOREIGN KEY (provider_account_id) REFERENCES public.provider_account (id) ON DELETE CASCADE,
  FOREIGN KEY (_id) REFERENCES public.resource (id) ON DELETE CASCADE
);

COMMENT ON TABLE aws_dynamodb_table IS 'dynamodb Table resources and their associated attributes.';

ALTER TABLE aws_dynamodb_table ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_dynamodb_table ON aws_dynamodb_table
USING (
  current_user = 'introspector_ro'
  OR
  provider_account_id = current_setting('introspector.provider_account_id', true)::int
);


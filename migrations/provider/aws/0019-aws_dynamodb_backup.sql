-- migrate:up

CREATE TABLE IF NOT EXISTS aws_dynamodb_backup (
  _id INTEGER NOT NULL PRIMARY KEY,
  uri TEXT NOT NULL,
  provider_account_id INTEGER NOT NULL,tablename TEXT,
  tableid TEXT,
  tablearn TEXT,
  backuparn TEXT,
  backupname TEXT,
  backupcreationdatetime TIMESTAMP WITH TIME ZONE,
  backupexpirydatetime TIMESTAMP WITH TIME ZONE,
  backupstatus TEXT,
  backuptype TEXT,
  backupsizebytes BIGINT,
  _table_id INTEGER,
    FOREIGN KEY (_table_id) REFERENCES aws_dynamodb_table (_id) ON DELETE SET NULL,
  _account_id INTEGER,
    FOREIGN KEY (_account_id) REFERENCES aws_organizations_account (_id) ON DELETE SET NULL,
  FOREIGN KEY (provider_account_id) REFERENCES public.provider_account (id) ON DELETE CASCADE,
  FOREIGN KEY (_id) REFERENCES public.resource (id) ON DELETE CASCADE
);

COMMENT ON TABLE aws_dynamodb_backup IS 'dynamodb Backup resources and their associated attributes.';

ALTER TABLE aws_dynamodb_backup ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_dynamodb_backup ON aws_dynamodb_backup
USING (
  current_user = 'goldfig_ro'
  OR
  provider_account_id = current_setting('gf.provider_account_id', true)::int
);


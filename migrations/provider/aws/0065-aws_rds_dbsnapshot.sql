-- migrate:up

CREATE TABLE IF NOT EXISTS aws_rds_dbsnapshot (
  _id INTEGER NOT NULL PRIMARY KEY,
  uri TEXT NOT NULL,
  provider_account_id INTEGER NOT NULL,dbsnapshotidentifier TEXT,
  dbinstanceidentifier TEXT,
  snapshotcreatetime TIMESTAMP WITH TIME ZONE,
  engine TEXT,
  allocatedstorage INTEGER,
  status TEXT,
  port INTEGER,
  availabilityzone TEXT,
  vpcid TEXT,
  instancecreatetime TIMESTAMP WITH TIME ZONE,
  masterusername TEXT,
  engineversion TEXT,
  licensemodel TEXT,
  snapshottype TEXT,
  iops INTEGER,
  optiongroupname TEXT,
  percentprogress INTEGER,
  sourceregion TEXT,
  sourcedbsnapshotidentifier TEXT,
  storagetype TEXT,
  tdecredentialarn TEXT,
  encrypted BOOLEAN,
  kmskeyid TEXT,
  dbsnapshotarn TEXT,
  timezone TEXT,
  iamdatabaseauthenticationenabled BOOLEAN,
  processorfeatures JSONB,
  dbiresourceid TEXT,
  taglist JSONB,
  restore JSONB,
  _kms_key_id INTEGER,
    FOREIGN KEY (_kms_key_id) REFERENCES aws_kms_key (_id) ON DELETE SET NULL,
  _ec2_vpc_id INTEGER,
    FOREIGN KEY (_ec2_vpc_id) REFERENCES aws_ec2_vpc (_id) ON DELETE SET NULL,
  _dbinstance_id INTEGER,
    FOREIGN KEY (_dbinstance_id) REFERENCES aws_rds_dbinstance (_id) ON DELETE SET NULL,
  _account_id INTEGER,
    FOREIGN KEY (_account_id) REFERENCES aws_organizations_account (_id) ON DELETE SET NULL,
  FOREIGN KEY (provider_account_id) REFERENCES public.provider_account (id) ON DELETE CASCADE,
  FOREIGN KEY (_id) REFERENCES public.resource (id) ON DELETE CASCADE
);

COMMENT ON TABLE aws_rds_dbsnapshot IS 'rds DBSnapshot resources and their associated attributes.';

ALTER TABLE aws_rds_dbsnapshot ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_rds_dbsnapshot ON aws_rds_dbsnapshot
USING (
  current_user = 'introspector_ro'
  OR
  provider_account_id = current_setting('introspector.provider_account_id', true)::int
);


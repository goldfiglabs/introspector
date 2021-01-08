-- migrate:up

CREATE TABLE IF NOT EXISTS aws_rds_dbclustersnapshot (
  _id INTEGER NOT NULL PRIMARY KEY,
  uri TEXT NOT NULL,
  provider_account_id INTEGER NOT NULL,availabilityzones JSONB,
  dbclustersnapshotidentifier TEXT,
  dbclusteridentifier TEXT,
  snapshotcreatetime TIMESTAMP WITH TIME ZONE,
  engine TEXT,
  allocatedstorage INTEGER,
  status TEXT,
  port INTEGER,
  vpcid TEXT,
  clustercreatetime TIMESTAMP WITH TIME ZONE,
  masterusername TEXT,
  engineversion TEXT,
  licensemodel TEXT,
  snapshottype TEXT,
  percentprogress INTEGER,
  storageencrypted BOOLEAN,
  kmskeyid TEXT,
  dbclustersnapshotarn TEXT,
  sourcedbclustersnapshotarn TEXT,
  iamdatabaseauthenticationenabled BOOLEAN,
  taglist JSONB,
  restore JSONB,
  _kms_key_id INTEGER,
    FOREIGN KEY (_kms_key_id) REFERENCES aws_kms_key (_id) ON DELETE SET NULL,
  _ec2_vpc_id INTEGER,
    FOREIGN KEY (_ec2_vpc_id) REFERENCES aws_ec2_vpc (_id) ON DELETE SET NULL,
  _dbcluster_id INTEGER,
    FOREIGN KEY (_dbcluster_id) REFERENCES aws_rds_dbcluster (_id) ON DELETE SET NULL,
  _account_id INTEGER,
    FOREIGN KEY (_account_id) REFERENCES aws_organizations_account (_id) ON DELETE SET NULL,
  FOREIGN KEY (provider_account_id) REFERENCES public.provider_account (id) ON DELETE CASCADE,
  FOREIGN KEY (_id) REFERENCES public.resource (id) ON DELETE CASCADE
);

COMMENT ON TABLE aws_rds_dbclustersnapshot IS 'rds DBClusterSnapshot resources and their associated attributes.';

ALTER TABLE aws_rds_dbclustersnapshot ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_rds_dbclustersnapshot ON aws_rds_dbclustersnapshot
USING (
  current_user = 'goldfig_ro'
  OR
  provider_account_id = current_setting('gf.provider_account_id', true)::int
);


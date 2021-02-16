-- migrate:up

CREATE TABLE IF NOT EXISTS aws_rds_dbinstance (
  _id INTEGER NOT NULL PRIMARY KEY,
  uri TEXT NOT NULL,
  provider_account_id INTEGER NOT NULL,dbinstanceidentifier TEXT,
  dbinstanceclass TEXT,
  engine TEXT,
  dbinstancestatus TEXT,
  masterusername TEXT,
  dbname TEXT,
  endpoint JSONB,
  allocatedstorage INTEGER,
  instancecreatetime TIMESTAMP WITH TIME ZONE,
  preferredbackupwindow TEXT,
  backupretentionperiod INTEGER,
  dbsecuritygroups JSONB,
  vpcsecuritygroups JSONB,
  dbparametergroups JSONB,
  availabilityzone TEXT,
  dbsubnetgroup JSONB,
  preferredmaintenancewindow TEXT,
  pendingmodifiedvalues JSONB,
  latestrestorabletime TIMESTAMP WITH TIME ZONE,
  multiaz BOOLEAN,
  engineversion TEXT,
  autominorversionupgrade BOOLEAN,
  readreplicasourcedbinstanceidentifier TEXT,
  readreplicadbinstanceidentifiers JSONB,
  readreplicadbclusteridentifiers JSONB,
  replicamode TEXT,
  licensemodel TEXT,
  iops INTEGER,
  optiongroupmemberships JSONB,
  charactersetname TEXT,
  ncharcharactersetname TEXT,
  secondaryavailabilityzone TEXT,
  publiclyaccessible BOOLEAN,
  statusinfos JSONB,
  storagetype TEXT,
  tdecredentialarn TEXT,
  dbinstanceport INTEGER,
  dbclusteridentifier TEXT,
  storageencrypted BOOLEAN,
  kmskeyid TEXT,
  dbiresourceid TEXT,
  cacertificateidentifier TEXT,
  domainmemberships JSONB,
  copytagstosnapshot BOOLEAN,
  monitoringinterval INTEGER,
  enhancedmonitoringresourcearn TEXT,
  monitoringrolearn TEXT,
  promotiontier INTEGER,
  dbinstancearn TEXT,
  timezone TEXT,
  iamdatabaseauthenticationenabled BOOLEAN,
  performanceinsightsenabled BOOLEAN,
  performanceinsightskmskeyid TEXT,
  performanceinsightsretentionperiod INTEGER,
  enabledcloudwatchlogsexports JSONB,
  processorfeatures JSONB,
  deletionprotection BOOLEAN,
  associatedroles JSONB,
  listenerendpoint JSONB,
  maxallocatedstorage INTEGER,
  taglist JSONB,
  _dbcluster_id INTEGER,
    FOREIGN KEY (_dbcluster_id) REFERENCES aws_rds_dbcluster (_id) ON DELETE SET NULL,
  _account_id INTEGER,
    FOREIGN KEY (_account_id) REFERENCES aws_organizations_account (_id) ON DELETE SET NULL,
  FOREIGN KEY (provider_account_id) REFERENCES public.provider_account (id) ON DELETE CASCADE,
  FOREIGN KEY (_id) REFERENCES public.resource (id) ON DELETE CASCADE
);

COMMENT ON TABLE aws_rds_dbinstance IS 'rds DBInstance resources and their associated attributes.';

ALTER TABLE aws_rds_dbinstance ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_rds_dbinstance ON aws_rds_dbinstance
USING (
  current_user = 'introspector_ro'
  OR
  provider_account_id = current_setting('introspector.provider_account_id', true)::int
);



CREATE TABLE IF NOT EXISTS aws_rds_dbinstance_ec2_securitygroup (
  dbinstance_id INTEGER NOT NULL REFERENCES aws_rds_dbinstance (_id) ON DELETE CASCADE,
  securitygroup_id INTEGER NOT NULL REFERENCES aws_ec2_securitygroup (_id) ON DELETE CASCADE,
  provider_account_id INTEGER NOT NULL REFERENCES provider_account (id) ON DELETE CASCADE,PRIMARY KEY (dbinstance_id, securitygroup_id)
);

ALTER TABLE aws_rds_dbinstance_ec2_securitygroup ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_rds_dbinstance_ec2_securitygroup ON aws_rds_dbinstance_ec2_securitygroup
USING (
  current_user = 'introspector_ro'
  OR
  provider_account_id = current_setting('introspector.provider_account_id', true)::int
);


-- migrate:up

CREATE TABLE IF NOT EXISTS aws_rds_dbcluster (
  _id INTEGER NOT NULL PRIMARY KEY,
  uri TEXT NOT NULL,
  provider_account_id INTEGER NOT NULL,allocatedstorage INTEGER,
  availabilityzones JSONB,
  backupretentionperiod INTEGER,
  charactersetname TEXT,
  databasename TEXT,
  dbclusteridentifier TEXT,
  dbclusterparametergroup TEXT,
  dbsubnetgroup TEXT,
  status TEXT,
  percentprogress TEXT,
  earliestrestorabletime TIMESTAMP WITH TIME ZONE,
  endpoint TEXT,
  readerendpoint TEXT,
  customendpoints JSONB,
  multiaz BOOLEAN,
  engine TEXT,
  engineversion TEXT,
  latestrestorabletime TIMESTAMP WITH TIME ZONE,
  port INTEGER,
  masterusername TEXT,
  dbclusteroptiongroupmemberships JSONB,
  preferredbackupwindow TEXT,
  preferredmaintenancewindow TEXT,
  replicationsourceidentifier TEXT,
  readreplicaidentifiers JSONB,
  dbclustermembers JSONB,
  vpcsecuritygroups JSONB,
  hostedzoneid TEXT,
  storageencrypted BOOLEAN,
  kmskeyid TEXT,
  dbclusterresourceid TEXT,
  dbclusterarn TEXT,
  associatedroles JSONB,
  iamdatabaseauthenticationenabled BOOLEAN,
  clonegroupid TEXT,
  clustercreatetime TIMESTAMP WITH TIME ZONE,
  earliestbacktracktime TIMESTAMP WITH TIME ZONE,
  backtrackwindow BIGINT,
  backtrackconsumedchangerecords BIGINT,
  enabledcloudwatchlogsexports JSONB,
  capacity INTEGER,
  enginemode TEXT,
  scalingconfigurationinfo JSONB,
  deletionprotection BOOLEAN,
  httpendpointenabled BOOLEAN,
  activitystreammode TEXT,
  activitystreamstatus TEXT,
  activitystreamkmskeyid TEXT,
  activitystreamkinesisstreamname TEXT,
  copytagstosnapshot BOOLEAN,
  crossaccountclone BOOLEAN,
  domainmemberships JSONB,
  taglist JSONB,
  globalwriteforwardingstatus TEXT,
  globalwriteforwardingrequested BOOLEAN,
  _account_id INTEGER,
    FOREIGN KEY (_account_id) REFERENCES aws_organizations_account (_id) ON DELETE SET NULL,
  FOREIGN KEY (provider_account_id) REFERENCES public.provider_account (id) ON DELETE CASCADE,
  FOREIGN KEY (_id) REFERENCES public.resource (id) ON DELETE CASCADE
);

COMMENT ON TABLE aws_rds_dbcluster IS 'rds DBCluster resources and their associated attributes.';

ALTER TABLE aws_rds_dbcluster ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_rds_dbcluster ON aws_rds_dbcluster
USING (
  current_user = 'introspector_ro'
  OR
  provider_account_id = current_setting('introspector.provider_account_id', true)::int
);



CREATE TABLE IF NOT EXISTS aws_rds_dbcluster_ec2_securitygroup (
  dbcluster_id INTEGER NOT NULL REFERENCES aws_rds_dbcluster (_id) ON DELETE CASCADE,
  securitygroup_id INTEGER NOT NULL REFERENCES aws_ec2_securitygroup (_id) ON DELETE CASCADE,
  provider_account_id INTEGER NOT NULL REFERENCES provider_account (id) ON DELETE CASCADE,PRIMARY KEY (dbcluster_id, securitygroup_id)
);

ALTER TABLE aws_rds_dbcluster_ec2_securitygroup ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_rds_dbcluster_ec2_securitygroup ON aws_rds_dbcluster_ec2_securitygroup
USING (
  current_user = 'introspector_ro'
  OR
  provider_account_id = current_setting('introspector.provider_account_id', true)::int
);


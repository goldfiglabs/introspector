-- migrate:up

CREATE TABLE IF NOT EXISTS aws_redshift_cluster (
  _id INTEGER NOT NULL PRIMARY KEY,
  uri TEXT NOT NULL,
  provider_account_id INTEGER NOT NULL,clusteridentifier TEXT,
  nodetype TEXT,
  clusterstatus TEXT,
  clusteravailabilitystatus TEXT,
  modifystatus TEXT,
  masterusername TEXT,
  dbname TEXT,
  endpoint JSONB,
  clustercreatetime TIMESTAMP WITH TIME ZONE,
  automatedsnapshotretentionperiod INTEGER,
  manualsnapshotretentionperiod INTEGER,
  clustersecuritygroups JSONB,
  vpcsecuritygroups JSONB,
  clusterparametergroups JSONB,
  clustersubnetgroupname TEXT,
  vpcid TEXT,
  availabilityzone TEXT,
  preferredmaintenancewindow TEXT,
  pendingmodifiedvalues JSONB,
  clusterversion TEXT,
  allowversionupgrade BOOLEAN,
  numberofnodes INTEGER,
  publiclyaccessible BOOLEAN,
  encrypted BOOLEAN,
  restorestatus JSONB,
  datatransferprogress JSONB,
  hsmstatus JSONB,
  clustersnapshotcopystatus JSONB,
  clusterpublickey TEXT,
  clusternodes JSONB,
  elasticipstatus JSONB,
  clusterrevisionnumber TEXT,
  tags JSONB,
  kmskeyid TEXT,
  enhancedvpcrouting BOOLEAN,
  iamroles JSONB,
  pendingactions JSONB,
  maintenancetrackname TEXT,
  elasticresizenumberofnodeoptions TEXT,
  deferredmaintenancewindows JSONB,
  snapshotscheduleidentifier TEXT,
  snapshotschedulestate TEXT,
  expectednextsnapshotscheduletime TIMESTAMP WITH TIME ZONE,
  expectednextsnapshotscheduletimestatus TEXT,
  nextmaintenancewindowstarttime TIMESTAMP WITH TIME ZONE,
  resizeinfo JSONB,
  clusternamespacearn TEXT,
  loggingstatus JSONB,
  _kms_key_id INTEGER,
    FOREIGN KEY (_kms_key_id) REFERENCES aws_kms_key (_id) ON DELETE SET NULL,
  _ec2_vpc_id INTEGER,
    FOREIGN KEY (_ec2_vpc_id) REFERENCES aws_ec2_vpc (_id) ON DELETE SET NULL,
  _account_id INTEGER,
    FOREIGN KEY (_account_id) REFERENCES aws_organizations_account (_id) ON DELETE SET NULL,
  FOREIGN KEY (provider_account_id) REFERENCES public.provider_account (id) ON DELETE CASCADE,
  FOREIGN KEY (_id) REFERENCES public.resource (id) ON DELETE CASCADE
);

COMMENT ON TABLE aws_redshift_cluster IS 'redshift Cluster resources and their associated attributes.';

ALTER TABLE aws_redshift_cluster ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_redshift_cluster ON aws_redshift_cluster
USING (
  current_user = 'introspector_ro'
  OR
  provider_account_id = current_setting('introspector.provider_account_id', true)::int
);



CREATE TABLE IF NOT EXISTS aws_redshift_cluster_ec2_securitygroup (
  cluster_id INTEGER NOT NULL REFERENCES aws_redshift_cluster (_id) ON DELETE CASCADE,
  securitygroup_id INTEGER NOT NULL REFERENCES aws_ec2_securitygroup (_id) ON DELETE CASCADE,
  provider_account_id INTEGER NOT NULL REFERENCES provider_account (id) ON DELETE CASCADE,Status TEXT,
  PRIMARY KEY (cluster_id, securitygroup_id)
);

ALTER TABLE aws_redshift_cluster_ec2_securitygroup ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_redshift_cluster_ec2_securitygroup ON aws_redshift_cluster_ec2_securitygroup
USING (
  current_user = 'introspector_ro'
  OR
  provider_account_id = current_setting('introspector.provider_account_id', true)::int
);


-- migrate:up

CREATE TABLE IF NOT EXISTS aws_ec2_instance (
  _id INTEGER NOT NULL PRIMARY KEY,
  uri TEXT NOT NULL,
  provider_account_id INTEGER NOT NULL,amilaunchindex INTEGER,
  imageid TEXT,
  instanceid TEXT,
  instancetype TEXT,
  kernelid TEXT,
  keyname TEXT,
  launchtime TIMESTAMP WITH TIME ZONE,
  monitoring JSONB,
  placement JSONB,
  platform TEXT,
  privatednsname TEXT,
  privateipaddress INET,
  productcodes JSONB,
  publicdnsname TEXT,
  publicipaddress INET,
  ramdiskid TEXT,
  state JSONB,
  statetransitionreason TEXT,
  subnetid TEXT,
  vpcid TEXT,
  architecture TEXT,
  blockdevicemappings JSONB,
  clienttoken TEXT,
  ebsoptimized BOOLEAN,
  enasupport BOOLEAN,
  hypervisor TEXT,
  iaminstanceprofile JSONB,
  instancelifecycle TEXT,
  elasticgpuassociations JSONB,
  elasticinferenceacceleratorassociations JSONB,
  networkinterfaces JSONB,
  outpostarn TEXT,
  rootdevicename TEXT,
  rootdevicetype TEXT,
  securitygroups JSONB,
  sourcedestcheck BOOLEAN,
  spotinstancerequestid TEXT,
  sriovnetsupport TEXT,
  statereason JSONB,
  tags JSONB,
  virtualizationtype TEXT,
  cpuoptions JSONB,
  capacityreservationid TEXT,
  capacityreservationspecification JSONB,
  hibernationoptions JSONB,
  licenses JSONB,
  metadataoptions JSONB,
  enclaveoptions JSONB,
  userdata TEXT,
  _image_id INTEGER,
    FOREIGN KEY (_image_id) REFERENCES aws_ec2_image (_id) ON DELETE SET NULL,
  _iam_instanceprofile_id INTEGER,
    FOREIGN KEY (_iam_instanceprofile_id) REFERENCES aws_iam_instanceprofile (_id) ON DELETE SET NULL,
  _vpc_id INTEGER,
    FOREIGN KEY (_vpc_id) REFERENCES aws_ec2_vpc (_id) ON DELETE SET NULL,
  _subnet_id INTEGER,
    FOREIGN KEY (_subnet_id) REFERENCES aws_ec2_subnet (_id) ON DELETE SET NULL,
  _account_id INTEGER,
    FOREIGN KEY (_account_id) REFERENCES aws_organizations_account (_id) ON DELETE SET NULL,
  FOREIGN KEY (provider_account_id) REFERENCES public.provider_account (id) ON DELETE CASCADE,
  FOREIGN KEY (_id) REFERENCES public.resource (id) ON DELETE CASCADE
);

COMMENT ON TABLE aws_ec2_instance IS 'ec2 Instance resources and their associated attributes.';

ALTER TABLE aws_ec2_instance ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_ec2_instance ON aws_ec2_instance
USING (
  current_user = 'goldfig_ro'
  OR
  provider_account_id = current_setting('gf.provider_account_id', true)::int
);



CREATE TABLE IF NOT EXISTS aws_ec2_instance_volume (
  instance_id INTEGER NOT NULL REFERENCES aws_ec2_instance (_id) ON DELETE CASCADE,
  volume_id INTEGER NOT NULL REFERENCES aws_ec2_volume (_id) ON DELETE CASCADE,
  provider_account_id INTEGER NOT NULL REFERENCES provider_account (id) ON DELETE CASCADE,DeleteOnTermination BOOLEAN,
  AttachTime TIMESTAMP WITH TIME ZONE,
  VolumeId TEXT,
  Status TEXT,
  DeviceName TEXT,
  PRIMARY KEY (instance_id, volume_id)
);

ALTER TABLE aws_ec2_instance_volume ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_ec2_instance_volume ON aws_ec2_instance_volume
USING (
  current_user = 'goldfig_ro'
  OR
  provider_account_id = current_setting('gf.provider_account_id', true)::int
);



CREATE TABLE IF NOT EXISTS aws_ec2_instance_securitygroup (
  instance_id INTEGER NOT NULL REFERENCES aws_ec2_instance (_id) ON DELETE CASCADE,
  securitygroup_id INTEGER NOT NULL REFERENCES aws_ec2_securitygroup (_id) ON DELETE CASCADE,
  provider_account_id INTEGER NOT NULL REFERENCES provider_account (id) ON DELETE CASCADE,PRIMARY KEY (instance_id, securitygroup_id)
);

ALTER TABLE aws_ec2_instance_securitygroup ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_ec2_instance_securitygroup ON aws_ec2_instance_securitygroup
USING (
  current_user = 'goldfig_ro'
  OR
  provider_account_id = current_setting('gf.provider_account_id', true)::int
);


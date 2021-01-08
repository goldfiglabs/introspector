-- migrate:up

CREATE TABLE IF NOT EXISTS aws_autoscaling_launchconfiguration (
  _id INTEGER NOT NULL PRIMARY KEY,
  uri TEXT NOT NULL,
  provider_account_id INTEGER NOT NULL,launchconfigurationname TEXT,
  launchconfigurationarn TEXT,
  imageid TEXT,
  keyname TEXT,
  securitygroups JSONB,
  classiclinkvpcid TEXT,
  classiclinkvpcsecuritygroups JSONB,
  userdata TEXT,
  instancetype TEXT,
  kernelid TEXT,
  ramdiskid TEXT,
  blockdevicemappings JSONB,
  instancemonitoring JSONB,
  spotprice TEXT,
  iaminstanceprofile TEXT,
  createdtime TIMESTAMP WITH TIME ZONE,
  ebsoptimized BOOLEAN,
  associatepublicipaddress BOOLEAN,
  placementtenancy TEXT,
  metadataoptions JSONB,
  _ec2_image_id INTEGER,
    FOREIGN KEY (_ec2_image_id) REFERENCES aws_ec2_image (_id) ON DELETE SET NULL,
  _iam_instanceprofile_id INTEGER,
    FOREIGN KEY (_iam_instanceprofile_id) REFERENCES aws_iam_instanceprofile (_id) ON DELETE SET NULL,
  _account_id INTEGER,
    FOREIGN KEY (_account_id) REFERENCES aws_organizations_account (_id) ON DELETE SET NULL,
  FOREIGN KEY (provider_account_id) REFERENCES public.provider_account (id) ON DELETE CASCADE,
  FOREIGN KEY (_id) REFERENCES public.resource (id) ON DELETE CASCADE
);

COMMENT ON TABLE aws_autoscaling_launchconfiguration IS 'autoscaling LaunchConfiguration resources and their associated attributes.';

ALTER TABLE aws_autoscaling_launchconfiguration ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_autoscaling_launchconfiguration ON aws_autoscaling_launchconfiguration
USING (
  current_user = 'goldfig_ro'
  OR
  provider_account_id = current_setting('gf.provider_account_id', true)::int
);



CREATE TABLE IF NOT EXISTS aws_autoscaling_launchconfiguration_ec2_securitygroup (
  launchconfiguration_id INTEGER NOT NULL REFERENCES aws_autoscaling_launchconfiguration (_id) ON DELETE CASCADE,
  securitygroup_id INTEGER NOT NULL REFERENCES aws_ec2_securitygroup (_id) ON DELETE CASCADE,
  provider_account_id INTEGER NOT NULL REFERENCES provider_account (id) ON DELETE CASCADE,PRIMARY KEY (launchconfiguration_id, securitygroup_id)
);

ALTER TABLE aws_autoscaling_launchconfiguration_ec2_securitygroup ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_autoscaling_launchconfiguration_ec2_securitygroup ON aws_autoscaling_launchconfiguration_ec2_securitygroup
USING (
  current_user = 'goldfig_ro'
  OR
  provider_account_id = current_setting('gf.provider_account_id', true)::int
);


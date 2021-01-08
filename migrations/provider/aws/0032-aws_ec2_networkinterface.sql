-- migrate:up

CREATE TABLE IF NOT EXISTS aws_ec2_networkinterface (
  _id INTEGER NOT NULL PRIMARY KEY,
  uri TEXT NOT NULL,
  provider_account_id INTEGER NOT NULL,association JSONB,
  attachment JSONB,
  availabilityzone TEXT,
  description TEXT,
  groups JSONB,
  interfacetype TEXT,
  ipv6addresses JSONB,
  macaddress TEXT,
  networkinterfaceid TEXT,
  outpostarn TEXT,
  ownerid TEXT,
  privatednsname TEXT,
  privateipaddress TEXT,
  privateipaddresses JSONB,
  requesterid TEXT,
  requestermanaged BOOLEAN,
  sourcedestcheck BOOLEAN,
  status TEXT,
  subnetid TEXT,
  tagset JSONB,
  vpcid TEXT,
  _instance_id INTEGER,
    FOREIGN KEY (_instance_id) REFERENCES aws_ec2_instance (_id) ON DELETE SET NULL,
  _vpc_id INTEGER,
    FOREIGN KEY (_vpc_id) REFERENCES aws_ec2_vpc (_id) ON DELETE SET NULL,
  _subnet_id INTEGER,
    FOREIGN KEY (_subnet_id) REFERENCES aws_ec2_subnet (_id) ON DELETE SET NULL,
  _account_id INTEGER,
    FOREIGN KEY (_account_id) REFERENCES aws_organizations_account (_id) ON DELETE SET NULL,
  FOREIGN KEY (provider_account_id) REFERENCES public.provider_account (id) ON DELETE CASCADE,
  FOREIGN KEY (_id) REFERENCES public.resource (id) ON DELETE CASCADE
);

COMMENT ON TABLE aws_ec2_networkinterface IS 'ec2 NetworkInterface resources and their associated attributes.';

ALTER TABLE aws_ec2_networkinterface ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_ec2_networkinterface ON aws_ec2_networkinterface
USING (
  current_user = 'goldfig_ro'
  OR
  provider_account_id = current_setting('gf.provider_account_id', true)::int
);



CREATE TABLE IF NOT EXISTS aws_ec2_networkinterface_securitygroup (
  networkinterface_id INTEGER NOT NULL REFERENCES aws_ec2_networkinterface (_id) ON DELETE CASCADE,
  securitygroup_id INTEGER NOT NULL REFERENCES aws_ec2_securitygroup (_id) ON DELETE CASCADE,
  provider_account_id INTEGER NOT NULL REFERENCES provider_account (id) ON DELETE CASCADE,PRIMARY KEY (networkinterface_id, securitygroup_id)
);

ALTER TABLE aws_ec2_networkinterface_securitygroup ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_ec2_networkinterface_securitygroup ON aws_ec2_networkinterface_securitygroup
USING (
  current_user = 'goldfig_ro'
  OR
  provider_account_id = current_setting('gf.provider_account_id', true)::int
);


-- migrate:up

CREATE TABLE IF NOT EXISTS aws_ec2_vpcendpoint (
  _id INTEGER NOT NULL PRIMARY KEY,
  uri TEXT NOT NULL,
  provider_account_id INTEGER NOT NULL,
  vpcendpointid TEXT,
  vpcendpointtype TEXT,
  vpcid TEXT,
  servicename TEXT,
  state TEXT,
  policydocument TEXT,
  routetableids JSONB,
  subnetids JSONB,
  groups JSONB,
  privatednsenabled BOOLEAN,
  requestermanaged BOOLEAN,
  networkinterfaceids JSONB,
  dnsentries JSONB,
  creationtimestamp TIMESTAMP WITH TIME ZONE,
  tags JSONB,
  ownerid TEXT,
  lasterror JSONB,
  _tags JSONB,
  _policy JSONB,
  _vpc_id INTEGER,
    FOREIGN KEY (_vpc_id) REFERENCES aws_ec2_vpc (_id) ON DELETE SET NULL,
  _account_id INTEGER,
    FOREIGN KEY (_account_id) REFERENCES aws_organizations_account (_id) ON DELETE SET NULL,
  FOREIGN KEY (provider_account_id) REFERENCES public.provider_account (id) ON DELETE CASCADE,
  FOREIGN KEY (_id) REFERENCES public.resource (id) ON DELETE CASCADE
);

COMMENT ON TABLE aws_ec2_vpcendpoint IS 'ec2 VpcEndpoint resources and their associated attributes.';

ALTER TABLE aws_ec2_vpcendpoint ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_ec2_vpcendpoint ON aws_ec2_vpcendpoint
USING (
  current_user = 'introspector_ro'
  OR
  provider_account_id = current_setting('introspector.provider_account_id', true)::int
);



CREATE TABLE IF NOT EXISTS aws_ec2_vpcendpoint_subnet (
  vpcendpoint_id INTEGER NOT NULL REFERENCES aws_ec2_vpcendpoint (_id) ON DELETE CASCADE,
  subnet_id INTEGER NOT NULL REFERENCES aws_ec2_subnet (_id) ON DELETE CASCADE,
  provider_account_id INTEGER NOT NULL REFERENCES provider_account (id) ON DELETE CASCADE,PRIMARY KEY (vpcendpoint_id, subnet_id)
);

ALTER TABLE aws_ec2_vpcendpoint_subnet ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_ec2_vpcendpoint_subnet ON aws_ec2_vpcendpoint_subnet
USING (
  current_user = 'introspector_ro'
  OR
  provider_account_id = current_setting('introspector.provider_account_id', true)::int
);



CREATE TABLE IF NOT EXISTS aws_ec2_vpcendpoint_securitygroup (
  vpcendpoint_id INTEGER NOT NULL REFERENCES aws_ec2_vpcendpoint (_id) ON DELETE CASCADE,
  securitygroup_id INTEGER NOT NULL REFERENCES aws_ec2_securitygroup (_id) ON DELETE CASCADE,
  provider_account_id INTEGER NOT NULL REFERENCES provider_account (id) ON DELETE CASCADE,PRIMARY KEY (vpcendpoint_id, securitygroup_id)
);

ALTER TABLE aws_ec2_vpcendpoint_securitygroup ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_ec2_vpcendpoint_securitygroup ON aws_ec2_vpcendpoint_securitygroup
USING (
  current_user = 'introspector_ro'
  OR
  provider_account_id = current_setting('introspector.provider_account_id', true)::int
);


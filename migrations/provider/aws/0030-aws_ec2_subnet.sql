-- migrate:up

CREATE TABLE IF NOT EXISTS aws_ec2_subnet (
  _id INTEGER NOT NULL PRIMARY KEY,
  uri TEXT NOT NULL,
  provider_account_id INTEGER NOT NULL,availabilityzone TEXT,
  availabilityzoneid TEXT,
  availableipaddresscount INTEGER,
  cidrblock TEXT,
  defaultforaz BOOLEAN,
  mappubliciponlaunch BOOLEAN,
  mapcustomerownediponlaunch BOOLEAN,
  customerownedipv4pool TEXT,
  state TEXT,
  subnetid TEXT,
  vpcid TEXT,
  ownerid TEXT,
  assignipv6addressoncreation BOOLEAN,
  ipv6cidrblockassociationset JSONB,
  tags JSONB,
  subnetarn TEXT,
  outpostarn TEXT,
  _vpc_id INTEGER,
    FOREIGN KEY (_vpc_id) REFERENCES aws_ec2_vpc (_id) ON DELETE SET NULL,
  _account_id INTEGER,
    FOREIGN KEY (_account_id) REFERENCES aws_organizations_account (_id) ON DELETE SET NULL,
  FOREIGN KEY (provider_account_id) REFERENCES public.provider_account (id) ON DELETE CASCADE,
  FOREIGN KEY (_id) REFERENCES public.resource (id) ON DELETE CASCADE
);

COMMENT ON TABLE aws_ec2_subnet IS 'ec2 Subnet resources and their associated attributes.';

ALTER TABLE aws_ec2_subnet ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_ec2_subnet ON aws_ec2_subnet
USING (
  current_user = 'goldfig_ro'
  OR
  provider_account_id = current_setting('gf.provider_account_id', true)::int
);


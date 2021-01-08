-- migrate:up

CREATE TABLE IF NOT EXISTS aws_ec2_address (
  _id INTEGER NOT NULL PRIMARY KEY,
  uri TEXT NOT NULL,
  provider_account_id INTEGER NOT NULL,instanceid TEXT,
  publicip TEXT,
  allocationid TEXT,
  associationid TEXT,
  domain TEXT,
  networkinterfaceid TEXT,
  networkinterfaceownerid TEXT,
  privateipaddress TEXT,
  tags JSONB,
  publicipv4pool TEXT,
  networkbordergroup TEXT,
  customerownedip TEXT,
  customerownedipv4pool TEXT,
  carrierip TEXT,
  _networkinterface_id INTEGER,
    FOREIGN KEY (_networkinterface_id) REFERENCES aws_ec2_networkinterface (_id) ON DELETE SET NULL,
  _instance_id INTEGER,
    FOREIGN KEY (_instance_id) REFERENCES aws_ec2_instance (_id) ON DELETE SET NULL,
  _account_id INTEGER,
    FOREIGN KEY (_account_id) REFERENCES aws_organizations_account (_id) ON DELETE SET NULL,
  FOREIGN KEY (provider_account_id) REFERENCES public.provider_account (id) ON DELETE CASCADE,
  FOREIGN KEY (_id) REFERENCES public.resource (id) ON DELETE CASCADE
);

COMMENT ON TABLE aws_ec2_address IS 'ec2 Address resources and their associated attributes.';

ALTER TABLE aws_ec2_address ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_ec2_address ON aws_ec2_address
USING (
  current_user = 'goldfig_ro'
  OR
  provider_account_id = current_setting('gf.provider_account_id', true)::int
);


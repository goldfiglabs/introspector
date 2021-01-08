-- migrate:up

CREATE TABLE IF NOT EXISTS aws_ec2_image (
  _id INTEGER NOT NULL PRIMARY KEY,
  uri TEXT NOT NULL,
  provider_account_id INTEGER NOT NULL,architecture TEXT,
  creationdate TEXT,
  imageid TEXT,
  imagelocation TEXT,
  imagetype TEXT,
  public BOOLEAN,
  kernelid TEXT,
  ownerid TEXT,
  platform TEXT,
  platformdetails TEXT,
  usageoperation TEXT,
  productcodes JSONB,
  ramdiskid TEXT,
  state TEXT,
  blockdevicemappings JSONB,
  description TEXT,
  enasupport BOOLEAN,
  hypervisor TEXT,
  imageowneralias TEXT,
  name TEXT,
  rootdevicename TEXT,
  rootdevicetype TEXT,
  sriovnetsupport TEXT,
  statereason JSONB,
  tags JSONB,
  virtualizationtype TEXT,
  _account_id INTEGER,
    FOREIGN KEY (_account_id) REFERENCES aws_organizations_account (_id) ON DELETE SET NULL,
  FOREIGN KEY (provider_account_id) REFERENCES public.provider_account (id) ON DELETE CASCADE,
  FOREIGN KEY (_id) REFERENCES public.resource (id) ON DELETE CASCADE
);

COMMENT ON TABLE aws_ec2_image IS 'ec2 Image resources and their associated attributes.';

ALTER TABLE aws_ec2_image ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_ec2_image ON aws_ec2_image
USING (
  current_user = 'goldfig_ro'
  OR
  provider_account_id = current_setting('gf.provider_account_id', true)::int
);


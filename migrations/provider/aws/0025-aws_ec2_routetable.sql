-- migrate:up

CREATE TABLE IF NOT EXISTS aws_ec2_routetable (
  _id INTEGER NOT NULL PRIMARY KEY,
  uri TEXT NOT NULL,
  provider_account_id INTEGER NOT NULL,associations JSONB,
  propagatingvgws JSONB,
  routetableid TEXT,
  routes JSONB,
  tags JSONB,
  vpcid TEXT,
  ownerid TEXT,
  _vpc_id INTEGER,
    FOREIGN KEY (_vpc_id) REFERENCES aws_ec2_vpc (_id) ON DELETE SET NULL,
  _account_id INTEGER,
    FOREIGN KEY (_account_id) REFERENCES aws_organizations_account (_id) ON DELETE SET NULL,
  FOREIGN KEY (provider_account_id) REFERENCES public.provider_account (id) ON DELETE CASCADE,
  FOREIGN KEY (_id) REFERENCES public.resource (id) ON DELETE CASCADE
);

COMMENT ON TABLE aws_ec2_routetable IS 'ec2 RouteTable resources and their associated attributes.';

ALTER TABLE aws_ec2_routetable ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_ec2_routetable ON aws_ec2_routetable
USING (
  current_user = 'goldfig_ro'
  OR
  provider_account_id = current_setting('gf.provider_account_id', true)::int
);


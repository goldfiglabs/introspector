-- migrate:up

CREATE TABLE IF NOT EXISTS aws_ec2_vpcpeeringconnection (
  _id INTEGER NOT NULL PRIMARY KEY,
  uri TEXT NOT NULL,
  provider_account_id INTEGER NOT NULL,acceptervpcinfo JSONB,
  expirationtime TIMESTAMP WITH TIME ZONE,
  requestervpcinfo JSONB,
  status JSONB,
  tags JSONB,
  vpcpeeringconnectionid TEXT,
  _acceptervpc_id INTEGER,
    FOREIGN KEY (_acceptervpc_id) REFERENCES aws_ec2_vpc (_id) ON DELETE SET NULL,
  _requestervpc_id INTEGER,
    FOREIGN KEY (_requestervpc_id) REFERENCES aws_ec2_vpc (_id) ON DELETE SET NULL,
  _account_id INTEGER,
    FOREIGN KEY (_account_id) REFERENCES aws_organizations_account (_id) ON DELETE SET NULL,
  FOREIGN KEY (provider_account_id) REFERENCES public.provider_account (id) ON DELETE CASCADE,
  FOREIGN KEY (_id) REFERENCES public.resource (id) ON DELETE CASCADE
);

COMMENT ON TABLE aws_ec2_vpcpeeringconnection IS 'ec2 VpcPeeringConnection resources and their associated attributes.';

ALTER TABLE aws_ec2_vpcpeeringconnection ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_ec2_vpcpeeringconnection ON aws_ec2_vpcpeeringconnection
USING (
  current_user = 'introspector_ro'
  OR
  provider_account_id = current_setting('introspector.provider_account_id', true)::int
);


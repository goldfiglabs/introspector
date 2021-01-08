-- migrate:up

CREATE TABLE IF NOT EXISTS aws_route53_hostedzone (
  _id INTEGER NOT NULL PRIMARY KEY,
  uri TEXT NOT NULL,
  provider_account_id INTEGER NOT NULL,id TEXT,
  name TEXT,
  callerreference TEXT,
  config JSONB,
  resourcerecordsetcount BIGINT,
  linkedservice JSONB,
  tags JSONB,
  resourcerecordsets JSONB,
  trafficpolicyinstances JSONB,
  vpcs JSONB,
  queryloggingconfigs JSONB,
  _account_id INTEGER,
    FOREIGN KEY (_account_id) REFERENCES aws_organizations_account (_id) ON DELETE SET NULL,
  FOREIGN KEY (provider_account_id) REFERENCES public.provider_account (id) ON DELETE CASCADE,
  FOREIGN KEY (_id) REFERENCES public.resource (id) ON DELETE CASCADE
);

COMMENT ON TABLE aws_route53_hostedzone IS 'route53 HostedZone resources and their associated attributes.';

ALTER TABLE aws_route53_hostedzone ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_route53_hostedzone ON aws_route53_hostedzone
USING (
  current_user = 'goldfig_ro'
  OR
  provider_account_id = current_setting('gf.provider_account_id', true)::int
);



CREATE TABLE IF NOT EXISTS aws_route53_hostedzone_ec2_vpc (
  hostedzone_id INTEGER NOT NULL REFERENCES aws_route53_hostedzone (_id) ON DELETE CASCADE,
  vpc_id INTEGER NOT NULL REFERENCES aws_ec2_vpc (_id) ON DELETE CASCADE,
  provider_account_id INTEGER NOT NULL REFERENCES provider_account (id) ON DELETE CASCADE,PRIMARY KEY (hostedzone_id, vpc_id)
);

ALTER TABLE aws_route53_hostedzone_ec2_vpc ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_route53_hostedzone_ec2_vpc ON aws_route53_hostedzone_ec2_vpc
USING (
  current_user = 'goldfig_ro'
  OR
  provider_account_id = current_setting('gf.provider_account_id', true)::int
);


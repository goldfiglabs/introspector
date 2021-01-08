-- migrate:up

CREATE TABLE IF NOT EXISTS aws_elb_loadbalancer (
  _id INTEGER NOT NULL PRIMARY KEY,
  uri TEXT NOT NULL,
  provider_account_id INTEGER NOT NULL,loadbalancername TEXT,
  dnsname TEXT,
  canonicalhostedzonename TEXT,
  canonicalhostedzonenameid TEXT,
  listenerdescriptions JSONB,
  policies JSONB,
  backendserverdescriptions JSONB,
  availabilityzones JSONB,
  subnets JSONB,
  vpcid TEXT,
  instances JSONB,
  healthcheck JSONB,
  sourcesecuritygroup JSONB,
  securitygroups JSONB,
  createdtime TIMESTAMP WITH TIME ZONE,
  scheme TEXT,
  tags JSONB,
  attributes JSONB,
  _account_id INTEGER,
    FOREIGN KEY (_account_id) REFERENCES aws_organizations_account (_id) ON DELETE SET NULL,
  FOREIGN KEY (provider_account_id) REFERENCES public.provider_account (id) ON DELETE CASCADE,
  FOREIGN KEY (_id) REFERENCES public.resource (id) ON DELETE CASCADE
);

COMMENT ON TABLE aws_elb_loadbalancer IS 'elb LoadBalancer resources and their associated attributes.';

ALTER TABLE aws_elb_loadbalancer ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_elb_loadbalancer ON aws_elb_loadbalancer
USING (
  current_user = 'goldfig_ro'
  OR
  provider_account_id = current_setting('gf.provider_account_id', true)::int
);


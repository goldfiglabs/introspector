-- migrate:up

CREATE TABLE IF NOT EXISTS aws_elb_listener (
  _id INTEGER NOT NULL PRIMARY KEY,
  uri TEXT NOT NULL,
  provider_account_id INTEGER NOT NULL,protocol TEXT,
  loadbalancerport INTEGER,
  instanceprotocol TEXT,
  instanceport INTEGER,
  sslcertificateid TEXT,
  policynames JSONB,
  _loadbalancer_id INTEGER,
    FOREIGN KEY (_loadbalancer_id) REFERENCES aws_elb_loadbalancer (_id) ON DELETE SET NULL,
  _account_id INTEGER,
    FOREIGN KEY (_account_id) REFERENCES aws_organizations_account (_id) ON DELETE SET NULL,
  FOREIGN KEY (provider_account_id) REFERENCES public.provider_account (id) ON DELETE CASCADE,
  FOREIGN KEY (_id) REFERENCES public.resource (id) ON DELETE CASCADE
);

COMMENT ON TABLE aws_elb_listener IS 'elb Listener resources and their associated attributes.';

ALTER TABLE aws_elb_listener ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_elb_listener ON aws_elb_listener
USING (
  current_user = 'goldfig_ro'
  OR
  provider_account_id = current_setting('gf.provider_account_id', true)::int
);


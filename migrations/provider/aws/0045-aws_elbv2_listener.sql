-- migrate:up

CREATE TABLE IF NOT EXISTS aws_elbv2_listener (
  _id INTEGER NOT NULL PRIMARY KEY,
  uri TEXT NOT NULL,
  provider_account_id INTEGER NOT NULL,listenerarn TEXT,
  loadbalancerarn TEXT,
  port INTEGER,
  protocol TEXT,
  certificates JSONB,
  sslpolicy TEXT,
  defaultactions JSONB,
  alpnpolicy JSONB,
  _loadbalancer_id INTEGER,
    FOREIGN KEY (_loadbalancer_id) REFERENCES aws_elbv2_loadbalancer (_id) ON DELETE SET NULL,
  _account_id INTEGER,
    FOREIGN KEY (_account_id) REFERENCES aws_organizations_account (_id) ON DELETE SET NULL,
  FOREIGN KEY (provider_account_id) REFERENCES public.provider_account (id) ON DELETE CASCADE,
  FOREIGN KEY (_id) REFERENCES public.resource (id) ON DELETE CASCADE
);

COMMENT ON TABLE aws_elbv2_listener IS 'elbv2 Listener resources and their associated attributes.';

ALTER TABLE aws_elbv2_listener ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_elbv2_listener ON aws_elbv2_listener
USING (
  current_user = 'goldfig_ro'
  OR
  provider_account_id = current_setting('gf.provider_account_id', true)::int
);



CREATE TABLE IF NOT EXISTS aws_elbv2_listener_acm_certificate (
  listener_id INTEGER NOT NULL REFERENCES aws_elbv2_listener (_id) ON DELETE CASCADE,
  certificate_id INTEGER NOT NULL REFERENCES aws_acm_certificate (_id) ON DELETE CASCADE,
  provider_account_id INTEGER NOT NULL REFERENCES provider_account (id) ON DELETE CASCADE,IsDefault BOOLEAN,
  PRIMARY KEY (listener_id, certificate_id)
);

ALTER TABLE aws_elbv2_listener_acm_certificate ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_elbv2_listener_acm_certificate ON aws_elbv2_listener_acm_certificate
USING (
  current_user = 'goldfig_ro'
  OR
  provider_account_id = current_setting('gf.provider_account_id', true)::int
);


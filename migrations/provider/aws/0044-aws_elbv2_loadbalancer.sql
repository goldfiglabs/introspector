-- migrate:up

CREATE TABLE IF NOT EXISTS aws_elbv2_loadbalancer (
  _id INTEGER NOT NULL PRIMARY KEY,
  uri TEXT NOT NULL,
  provider_account_id INTEGER NOT NULL,loadbalancerarn TEXT,
  dnsname TEXT,
  canonicalhostedzoneid TEXT,
  createdtime TIMESTAMP WITH TIME ZONE,
  loadbalancername TEXT,
  scheme TEXT,
  vpcid TEXT,
  state JSONB,
  type TEXT,
  availabilityzones JSONB,
  securitygroups JSONB,
  ipaddresstype TEXT,
  customerownedipv4pool TEXT,
  tags JSONB,
  access_logs_s3_enabled BOOLEAN,
  access_logs_s3_bucket TEXT,
  access_logs_s3_prefix TEXT,
  deletion_protection_enabled BOOLEAN,
  idle_timeout_timeout_seconds INTEGER,
  routing_http_desync_mitigation_mode TEXT,
  routing_http_drop_invalid_header_fields_enabled BOOLEAN,
  routing_http2_enabled BOOLEAN,
  load_balancing_cross_zone_enabled BOOLEAN,
  _ec2_vpc_id INTEGER,
    FOREIGN KEY (_ec2_vpc_id) REFERENCES aws_ec2_vpc (_id) ON DELETE SET NULL,
  _account_id INTEGER,
    FOREIGN KEY (_account_id) REFERENCES aws_organizations_account (_id) ON DELETE SET NULL,
  FOREIGN KEY (provider_account_id) REFERENCES public.provider_account (id) ON DELETE CASCADE,
  FOREIGN KEY (_id) REFERENCES public.resource (id) ON DELETE CASCADE
);

COMMENT ON TABLE aws_elbv2_loadbalancer IS 'elbv2 LoadBalancer resources and their associated attributes.';

ALTER TABLE aws_elbv2_loadbalancer ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_elbv2_loadbalancer ON aws_elbv2_loadbalancer
USING (
  current_user = 'introspector_ro'
  OR
  provider_account_id = current_setting('introspector.provider_account_id', true)::int
);



CREATE TABLE IF NOT EXISTS aws_elbv2_loadbalancer_ec2_securitygroup (
  loadbalancer_id INTEGER NOT NULL REFERENCES aws_elbv2_loadbalancer (_id) ON DELETE CASCADE,
  securitygroup_id INTEGER NOT NULL REFERENCES aws_ec2_securitygroup (_id) ON DELETE CASCADE,
  provider_account_id INTEGER NOT NULL REFERENCES provider_account (id) ON DELETE CASCADE,PRIMARY KEY (loadbalancer_id, securitygroup_id)
);

ALTER TABLE aws_elbv2_loadbalancer_ec2_securitygroup ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_elbv2_loadbalancer_ec2_securitygroup ON aws_elbv2_loadbalancer_ec2_securitygroup
USING (
  current_user = 'introspector_ro'
  OR
  provider_account_id = current_setting('introspector.provider_account_id', true)::int
);


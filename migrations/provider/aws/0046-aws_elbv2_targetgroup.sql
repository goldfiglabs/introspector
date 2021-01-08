-- migrate:up

CREATE TABLE IF NOT EXISTS aws_elbv2_targetgroup (
  _id INTEGER NOT NULL PRIMARY KEY,
  uri TEXT NOT NULL,
  provider_account_id INTEGER NOT NULL,targetgrouparn TEXT,
  targetgroupname TEXT,
  protocol TEXT,
  port INTEGER,
  vpcid TEXT,
  healthcheckprotocol TEXT,
  healthcheckport TEXT,
  healthcheckenabled BOOLEAN,
  healthcheckintervalseconds INTEGER,
  healthchecktimeoutseconds INTEGER,
  healthythresholdcount INTEGER,
  unhealthythresholdcount INTEGER,
  healthcheckpath TEXT,
  matcher JSONB,
  loadbalancerarns JSONB,
  targettype TEXT,
  protocolversion TEXT,
  tags JSONB,
  deregistration_delay_timeout_seconds INTEGER,
  stickiness_enabled BOOLEAN,
  stickiness_type TEXT,
  load_balancing_algorithm_type TEXT,
  slow_start_duration_seconds INTEGER,
  stickiness_lb_cookie_duration_seconds INTEGER,
  lambda_multi_value_headers_enabled BOOLEAN,
  proxy_protocol_v2_enabled BOOLEAN,
  _ec2_vpc_id INTEGER,
    FOREIGN KEY (_ec2_vpc_id) REFERENCES aws_ec2_vpc (_id) ON DELETE SET NULL,
  _account_id INTEGER,
    FOREIGN KEY (_account_id) REFERENCES aws_organizations_account (_id) ON DELETE SET NULL,
  FOREIGN KEY (provider_account_id) REFERENCES public.provider_account (id) ON DELETE CASCADE,
  FOREIGN KEY (_id) REFERENCES public.resource (id) ON DELETE CASCADE
);

COMMENT ON TABLE aws_elbv2_targetgroup IS 'elbv2 TargetGroup resources and their associated attributes.';

ALTER TABLE aws_elbv2_targetgroup ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_elbv2_targetgroup ON aws_elbv2_targetgroup
USING (
  current_user = 'goldfig_ro'
  OR
  provider_account_id = current_setting('gf.provider_account_id', true)::int
);



CREATE TABLE IF NOT EXISTS aws_elbv2_targetgroup_loadbalancer (
  targetgroup_id INTEGER NOT NULL REFERENCES aws_elbv2_targetgroup (_id) ON DELETE CASCADE,
  loadbalancer_id INTEGER NOT NULL REFERENCES aws_elbv2_loadbalancer (_id) ON DELETE CASCADE,
  provider_account_id INTEGER NOT NULL REFERENCES provider_account (id) ON DELETE CASCADE,PRIMARY KEY (targetgroup_id, loadbalancer_id)
);

ALTER TABLE aws_elbv2_targetgroup_loadbalancer ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_elbv2_targetgroup_loadbalancer ON aws_elbv2_targetgroup_loadbalancer
USING (
  current_user = 'goldfig_ro'
  OR
  provider_account_id = current_setting('gf.provider_account_id', true)::int
);


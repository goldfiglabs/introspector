-- migrate:up

CREATE TABLE IF NOT EXISTS aws_autoscaling_autoscalinggroup (
  _id INTEGER NOT NULL PRIMARY KEY,
  uri TEXT NOT NULL,
  provider_account_id INTEGER NOT NULL,autoscalinggroupname TEXT,
  autoscalinggrouparn TEXT,
  launchconfigurationname TEXT,
  launchtemplate JSONB,
  mixedinstancespolicy JSONB,
  minsize INTEGER,
  maxsize INTEGER,
  desiredcapacity INTEGER,
  defaultcooldown INTEGER,
  availabilityzones JSONB,
  loadbalancernames JSONB,
  targetgrouparns JSONB,
  healthchecktype TEXT,
  healthcheckgraceperiod INTEGER,
  instances JSONB,
  createdtime TIMESTAMP WITH TIME ZONE,
  suspendedprocesses JSONB,
  placementgroup TEXT,
  vpczoneidentifier TEXT,
  enabledmetrics JSONB,
  status TEXT,
  tags JSONB,
  terminationpolicies JSONB,
  newinstancesprotectedfromscalein BOOLEAN,
  servicelinkedrolearn TEXT,
  maxinstancelifetime INTEGER,
  capacityrebalance BOOLEAN,
  _launchconfiguration_id INTEGER,
    FOREIGN KEY (_launchconfiguration_id) REFERENCES aws_autoscaling_launchconfiguration (_id) ON DELETE SET NULL,
  _iam_role_id INTEGER,
    FOREIGN KEY (_iam_role_id) REFERENCES aws_iam_role (_id) ON DELETE SET NULL,
  _account_id INTEGER,
    FOREIGN KEY (_account_id) REFERENCES aws_organizations_account (_id) ON DELETE SET NULL,
  FOREIGN KEY (provider_account_id) REFERENCES public.provider_account (id) ON DELETE CASCADE,
  FOREIGN KEY (_id) REFERENCES public.resource (id) ON DELETE CASCADE
);

COMMENT ON TABLE aws_autoscaling_autoscalinggroup IS 'autoscaling AutoScalingGroup resources and their associated attributes.';

ALTER TABLE aws_autoscaling_autoscalinggroup ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_autoscaling_autoscalinggroup ON aws_autoscaling_autoscalinggroup
USING (
  current_user = 'goldfig_ro'
  OR
  provider_account_id = current_setting('gf.provider_account_id', true)::int
);


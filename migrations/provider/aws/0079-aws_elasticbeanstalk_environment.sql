-- migrate:up

CREATE TABLE IF NOT EXISTS aws_elasticbeanstalk_environment (
  _id INTEGER NOT NULL PRIMARY KEY,
  uri TEXT NOT NULL,
  provider_account_id INTEGER NOT NULL,environmentid TEXT,
  applicationname TEXT,
  versionlabel TEXT,
  solutionstackname TEXT,
  platformarn TEXT,
  templatename TEXT,
  description TEXT,
  endpointurl TEXT,
  cname TEXT,
  datecreated TIMESTAMP WITH TIME ZONE,
  dateupdated TIMESTAMP WITH TIME ZONE,
  status TEXT,
  abortableoperationinprogress BOOLEAN,
  health TEXT,
  healthstatus TEXT,
  resources JSONB,
  tier JSONB,
  environmentlinks JSONB,
  environmentarn TEXT,
  operationsrole TEXT,
  tags JSONB,
  environmentname TEXT,
  autoscalinggroups JSONB,
  instances JSONB,
  launchconfigurations JSONB,
  launchtemplates JSONB,
  loadbalancers JSONB,
  triggers JSONB,
  queues JSONB,
  _application_id INTEGER,
    FOREIGN KEY (_application_id) REFERENCES aws_elasticbeanstalk_application (_id) ON DELETE SET NULL,
  _applicationversion_id INTEGER,
    FOREIGN KEY (_applicationversion_id) REFERENCES aws_elasticbeanstalk_applicationversion (_id) ON DELETE SET NULL,
  _iam_role_id INTEGER,
    FOREIGN KEY (_iam_role_id) REFERENCES aws_iam_role (_id) ON DELETE SET NULL,
  _account_id INTEGER,
    FOREIGN KEY (_account_id) REFERENCES aws_organizations_account (_id) ON DELETE SET NULL,
  FOREIGN KEY (provider_account_id) REFERENCES public.provider_account (id) ON DELETE CASCADE,
  FOREIGN KEY (_id) REFERENCES public.resource (id) ON DELETE CASCADE
);

COMMENT ON TABLE aws_elasticbeanstalk_environment IS 'elasticbeanstalk Environment resources and their associated attributes.';

ALTER TABLE aws_elasticbeanstalk_environment ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_elasticbeanstalk_environment ON aws_elasticbeanstalk_environment
USING (
  current_user = 'introspector_ro'
  OR
  provider_account_id = current_setting('introspector.provider_account_id', true)::int
);



CREATE TABLE IF NOT EXISTS aws_elasticbeanstalk_environment_autoscaling_autoscalinggroup (
  environment_id INTEGER NOT NULL REFERENCES aws_elasticbeanstalk_environment (_id) ON DELETE CASCADE,
  autoscalinggroup_id INTEGER NOT NULL REFERENCES aws_autoscaling_autoscalinggroup (_id) ON DELETE CASCADE,
  provider_account_id INTEGER NOT NULL REFERENCES provider_account (id) ON DELETE CASCADE,PRIMARY KEY (environment_id, autoscalinggroup_id)
);

ALTER TABLE aws_elasticbeanstalk_environment_autoscaling_autoscalinggroup ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_elasticbeanstalk_environment_autoscaling_autoscalinggroup ON aws_elasticbeanstalk_environment_autoscaling_autoscalinggroup
USING (
  current_user = 'introspector_ro'
  OR
  provider_account_id = current_setting('introspector.provider_account_id', true)::int
);



CREATE TABLE IF NOT EXISTS aws_elasticbeanstalk_environment_autoscaling_launchconfiguration (
  environment_id INTEGER NOT NULL REFERENCES aws_elasticbeanstalk_environment (_id) ON DELETE CASCADE,
  launchconfiguration_id INTEGER NOT NULL REFERENCES aws_autoscaling_launchconfiguration (_id) ON DELETE CASCADE,
  provider_account_id INTEGER NOT NULL REFERENCES provider_account (id) ON DELETE CASCADE,PRIMARY KEY (environment_id, launchconfiguration_id)
);

ALTER TABLE aws_elasticbeanstalk_environment_autoscaling_launchconfiguration ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_elasticbeanstalk_environment_autoscaling_launchconfiguration ON aws_elasticbeanstalk_environment_autoscaling_launchconfiguration
USING (
  current_user = 'introspector_ro'
  OR
  provider_account_id = current_setting('introspector.provider_account_id', true)::int
);



CREATE TABLE IF NOT EXISTS aws_elasticbeanstalk_environment_ec2_instance (
  environment_id INTEGER NOT NULL REFERENCES aws_elasticbeanstalk_environment (_id) ON DELETE CASCADE,
  instance_id INTEGER NOT NULL REFERENCES aws_ec2_instance (_id) ON DELETE CASCADE,
  provider_account_id INTEGER NOT NULL REFERENCES provider_account (id) ON DELETE CASCADE,PRIMARY KEY (environment_id, instance_id)
);

ALTER TABLE aws_elasticbeanstalk_environment_ec2_instance ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_elasticbeanstalk_environment_ec2_instance ON aws_elasticbeanstalk_environment_ec2_instance
USING (
  current_user = 'introspector_ro'
  OR
  provider_account_id = current_setting('introspector.provider_account_id', true)::int
);


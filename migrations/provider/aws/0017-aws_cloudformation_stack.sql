-- migrate:up

CREATE TABLE IF NOT EXISTS aws_cloudformation_stack (
  _id INTEGER NOT NULL PRIMARY KEY,
  uri TEXT NOT NULL,
  provider_account_id INTEGER NOT NULL,stackid TEXT,
  stackname TEXT,
  changesetid TEXT,
  description TEXT,
  parameters JSONB,
  creationtime TIMESTAMP WITH TIME ZONE,
  deletiontime TIMESTAMP WITH TIME ZONE,
  lastupdatedtime TIMESTAMP WITH TIME ZONE,
  rollbackconfiguration JSONB,
  stackstatus TEXT,
  stackstatusreason TEXT,
  disablerollback BOOLEAN,
  notificationarns JSONB,
  timeoutinminutes INTEGER,
  capabilities JSONB,
  outputs JSONB,
  rolearn TEXT,
  tags JSONB,
  enableterminationprotection BOOLEAN,
  parentid TEXT,
  rootid TEXT,
  driftinformation JSONB,
  _iam_role_id INTEGER,
    FOREIGN KEY (_iam_role_id) REFERENCES aws_iam_role (_id) ON DELETE SET NULL,
  _account_id INTEGER,
    FOREIGN KEY (_account_id) REFERENCES aws_organizations_account (_id) ON DELETE SET NULL,
  FOREIGN KEY (provider_account_id) REFERENCES public.provider_account (id) ON DELETE CASCADE,
  FOREIGN KEY (_id) REFERENCES public.resource (id) ON DELETE CASCADE
);

COMMENT ON TABLE aws_cloudformation_stack IS 'cloudformation Stack resources and their associated attributes.';

ALTER TABLE aws_cloudformation_stack ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_cloudformation_stack ON aws_cloudformation_stack
USING (
  current_user = 'introspector_ro'
  OR
  provider_account_id = current_setting('introspector.provider_account_id', true)::int
);



CREATE TABLE IF NOT EXISTS aws_cloudformation_stack_sns_topic (
  stack_id INTEGER NOT NULL REFERENCES aws_cloudformation_stack (_id) ON DELETE CASCADE,
  topic_id INTEGER NOT NULL REFERENCES aws_sns_topic (_id) ON DELETE CASCADE,
  provider_account_id INTEGER NOT NULL REFERENCES provider_account (id) ON DELETE CASCADE,PRIMARY KEY (stack_id, topic_id)
);

ALTER TABLE aws_cloudformation_stack_sns_topic ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_cloudformation_stack_sns_topic ON aws_cloudformation_stack_sns_topic
USING (
  current_user = 'introspector_ro'
  OR
  provider_account_id = current_setting('introspector.provider_account_id', true)::int
);


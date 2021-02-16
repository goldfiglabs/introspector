-- migrate:up

CREATE TABLE IF NOT EXISTS aws_ecs_task (
  _id INTEGER NOT NULL PRIMARY KEY,
  uri TEXT NOT NULL,
  provider_account_id INTEGER NOT NULL,attachments JSONB,
  attributes JSONB,
  availabilityzone TEXT,
  capacityprovidername TEXT,
  clusterarn TEXT,
  connectivity TEXT,
  connectivityat TIMESTAMP WITH TIME ZONE,
  containerinstancearn TEXT,
  containers JSONB,
  cpu TEXT,
  createdat TIMESTAMP WITH TIME ZONE,
  desiredstatus TEXT,
  executionstoppedat TIMESTAMP WITH TIME ZONE,
  "group" TEXT,
  healthstatus TEXT,
  inferenceaccelerators JSONB,
  laststatus TEXT,
  launchtype TEXT,
  memory TEXT,
  overrides JSONB,
  platformversion TEXT,
  pullstartedat TIMESTAMP WITH TIME ZONE,
  pullstoppedat TIMESTAMP WITH TIME ZONE,
  startedat TIMESTAMP WITH TIME ZONE,
  startedby TEXT,
  stopcode TEXT,
  stoppedat TIMESTAMP WITH TIME ZONE,
  stoppedreason TEXT,
  stoppingat TIMESTAMP WITH TIME ZONE,
  tags JSONB,
  taskarn TEXT,
  taskdefinitionarn TEXT,
  version BIGINT,
  _cluster_id INTEGER,
    FOREIGN KEY (_cluster_id) REFERENCES aws_ecs_cluster (_id) ON DELETE SET NULL,
  _account_id INTEGER,
    FOREIGN KEY (_account_id) REFERENCES aws_organizations_account (_id) ON DELETE SET NULL,
  FOREIGN KEY (provider_account_id) REFERENCES public.provider_account (id) ON DELETE CASCADE,
  FOREIGN KEY (_id) REFERENCES public.resource (id) ON DELETE CASCADE
);

COMMENT ON TABLE aws_ecs_task IS 'ecs Task resources and their associated attributes.';

ALTER TABLE aws_ecs_task ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_ecs_task ON aws_ecs_task
USING (
  current_user = 'introspector_ro'
  OR
  provider_account_id = current_setting('introspector.provider_account_id', true)::int
);


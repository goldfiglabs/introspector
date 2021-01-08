-- migrate:up

CREATE TABLE IF NOT EXISTS aws_ecs_taskdefinition (
  _id INTEGER NOT NULL PRIMARY KEY,
  uri TEXT NOT NULL,
  provider_account_id INTEGER NOT NULL,taskdefinitionarn TEXT,
  containerdefinitions JSONB,
  family TEXT,
  taskrolearn TEXT,
  executionrolearn TEXT,
  networkmode TEXT,
  revision INTEGER,
  volumes JSONB,
  status TEXT,
  requiresattributes JSONB,
  placementconstraints JSONB,
  compatibilities JSONB,
  requirescompatibilities JSONB,
  cpu TEXT,
  memory TEXT,
  inferenceaccelerators JSONB,
  pidmode TEXT,
  ipcmode TEXT,
  proxyconfiguration JSONB,
  _account_id INTEGER,
    FOREIGN KEY (_account_id) REFERENCES aws_organizations_account (_id) ON DELETE SET NULL,
  FOREIGN KEY (provider_account_id) REFERENCES public.provider_account (id) ON DELETE CASCADE,
  FOREIGN KEY (_id) REFERENCES public.resource (id) ON DELETE CASCADE
);

COMMENT ON TABLE aws_ecs_taskdefinition IS 'ecs TaskDefinition resources and their associated attributes.';

ALTER TABLE aws_ecs_taskdefinition ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_ecs_taskdefinition ON aws_ecs_taskdefinition
USING (
  current_user = 'goldfig_ro'
  OR
  provider_account_id = current_setting('gf.provider_account_id', true)::int
);


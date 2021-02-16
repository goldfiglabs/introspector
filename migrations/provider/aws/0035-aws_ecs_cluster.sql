-- migrate:up

CREATE TABLE IF NOT EXISTS aws_ecs_cluster (
  _id INTEGER NOT NULL PRIMARY KEY,
  uri TEXT NOT NULL,
  provider_account_id INTEGER NOT NULL,clusterarn TEXT,
  clustername TEXT,
  status TEXT,
  registeredcontainerinstancescount INTEGER,
  runningtaskscount INTEGER,
  pendingtaskscount INTEGER,
  activeservicescount INTEGER,
  statistics JSONB,
  tags JSONB,
  settings JSONB,
  capacityproviders JSONB,
  defaultcapacityproviderstrategy JSONB,
  attachments JSONB,
  attachmentsstatus TEXT,
  _account_id INTEGER,
    FOREIGN KEY (_account_id) REFERENCES aws_organizations_account (_id) ON DELETE SET NULL,
  FOREIGN KEY (provider_account_id) REFERENCES public.provider_account (id) ON DELETE CASCADE,
  FOREIGN KEY (_id) REFERENCES public.resource (id) ON DELETE CASCADE
);

COMMENT ON TABLE aws_ecs_cluster IS 'ecs Cluster resources and their associated attributes.';

ALTER TABLE aws_ecs_cluster ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_ecs_cluster ON aws_ecs_cluster
USING (
  current_user = 'introspector_ro'
  OR
  provider_account_id = current_setting('introspector.provider_account_id', true)::int
);


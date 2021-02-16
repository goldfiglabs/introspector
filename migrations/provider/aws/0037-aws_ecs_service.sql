-- migrate:up

CREATE TABLE IF NOT EXISTS aws_ecs_service (
  _id INTEGER NOT NULL PRIMARY KEY,
  uri TEXT NOT NULL,
  provider_account_id INTEGER NOT NULL,servicearn TEXT,
  servicename TEXT,
  clusterarn TEXT,
  loadbalancers JSONB,
  serviceregistries JSONB,
  status TEXT,
  desiredcount INTEGER,
  runningcount INTEGER,
  pendingcount INTEGER,
  launchtype TEXT,
  capacityproviderstrategy JSONB,
  platformversion TEXT,
  taskdefinition TEXT,
  deploymentconfiguration JSONB,
  tasksets JSONB,
  deployments JSONB,
  rolearn TEXT,
  events JSONB,
  createdat TIMESTAMP WITH TIME ZONE,
  placementconstraints JSONB,
  placementstrategy JSONB,
  networkconfiguration JSONB,
  healthcheckgraceperiodseconds INTEGER,
  schedulingstrategy TEXT,
  deploymentcontroller JSONB,
  tags JSONB,
  createdby TEXT,
  enableecsmanagedtags BOOLEAN,
  propagatetags TEXT,
  _cluster_id INTEGER,
    FOREIGN KEY (_cluster_id) REFERENCES aws_ecs_cluster (_id) ON DELETE SET NULL,
  _account_id INTEGER,
    FOREIGN KEY (_account_id) REFERENCES aws_organizations_account (_id) ON DELETE SET NULL,
  FOREIGN KEY (provider_account_id) REFERENCES public.provider_account (id) ON DELETE CASCADE,
  FOREIGN KEY (_id) REFERENCES public.resource (id) ON DELETE CASCADE
);

COMMENT ON TABLE aws_ecs_service IS 'ecs Service resources and their associated attributes.';

ALTER TABLE aws_ecs_service ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_ecs_service ON aws_ecs_service
USING (
  current_user = 'introspector_ro'
  OR
  provider_account_id = current_setting('introspector.provider_account_id', true)::int
);


-- migrate:up

CREATE TABLE IF NOT EXISTS aws_eks_cluster (
  _id INTEGER NOT NULL PRIMARY KEY,
  uri TEXT NOT NULL,
  provider_account_id INTEGER NOT NULL,name TEXT,
  arn TEXT,
  createdat TIMESTAMP WITH TIME ZONE,
  version TEXT,
  endpoint TEXT,
  rolearn TEXT,
  resourcesvpcconfig JSONB,
  kubernetesnetworkconfig JSONB,
  logging JSONB,
  identity JSONB,
  status TEXT,
  certificateauthority JSONB,
  clientrequesttoken TEXT,
  platformversion TEXT,
  tags JSONB,
  encryptionconfig JSONB,
  _iam_role_id INTEGER,
    FOREIGN KEY (_iam_role_id) REFERENCES aws_iam_role (_id) ON DELETE SET NULL,
  _account_id INTEGER,
    FOREIGN KEY (_account_id) REFERENCES aws_organizations_account (_id) ON DELETE SET NULL,
  FOREIGN KEY (provider_account_id) REFERENCES public.provider_account (id) ON DELETE CASCADE,
  FOREIGN KEY (_id) REFERENCES public.resource (id) ON DELETE CASCADE
);

COMMENT ON TABLE aws_eks_cluster IS 'eks Cluster resources and their associated attributes.';

ALTER TABLE aws_eks_cluster ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_eks_cluster ON aws_eks_cluster
USING (
  current_user = 'introspector_ro'
  OR
  provider_account_id = current_setting('introspector.provider_account_id', true)::int
);


-- migrate:up

CREATE TABLE IF NOT EXISTS aws_eks_nodegroup (
  _id INTEGER NOT NULL PRIMARY KEY,
  uri TEXT NOT NULL,
  provider_account_id INTEGER NOT NULL,nodegroupname TEXT,
  nodegrouparn TEXT,
  clustername TEXT,
  version TEXT,
  releaseversion TEXT,
  createdat TIMESTAMP WITH TIME ZONE,
  modifiedat TIMESTAMP WITH TIME ZONE,
  status TEXT,
  scalingconfig JSONB,
  instancetypes JSONB,
  subnets JSONB,
  remoteaccess JSONB,
  amitype TEXT,
  noderole TEXT,
  labels JSONB,
  resources JSONB,
  disksize INTEGER,
  health JSONB,
  launchtemplate JSONB,
  tags JSONB,
  _cluster_id INTEGER,
    FOREIGN KEY (_cluster_id) REFERENCES aws_eks_cluster (_id) ON DELETE SET NULL,
  _iam_role_id INTEGER,
    FOREIGN KEY (_iam_role_id) REFERENCES aws_iam_role (_id) ON DELETE SET NULL,
  _account_id INTEGER,
    FOREIGN KEY (_account_id) REFERENCES aws_organizations_account (_id) ON DELETE SET NULL,
  FOREIGN KEY (provider_account_id) REFERENCES public.provider_account (id) ON DELETE CASCADE,
  FOREIGN KEY (_id) REFERENCES public.resource (id) ON DELETE CASCADE
);

COMMENT ON TABLE aws_eks_nodegroup IS 'eks Nodegroup resources and their associated attributes.';

ALTER TABLE aws_eks_nodegroup ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_eks_nodegroup ON aws_eks_nodegroup
USING (
  current_user = 'goldfig_ro'
  OR
  provider_account_id = current_setting('gf.provider_account_id', true)::int
);



CREATE TABLE IF NOT EXISTS aws_eks_nodegroup_ec2_subnet (
  nodegroup_id INTEGER NOT NULL REFERENCES aws_eks_nodegroup (_id) ON DELETE CASCADE,
  subnet_id INTEGER NOT NULL REFERENCES aws_ec2_subnet (_id) ON DELETE CASCADE,
  provider_account_id INTEGER NOT NULL REFERENCES provider_account (id) ON DELETE CASCADE,PRIMARY KEY (nodegroup_id, subnet_id)
);

ALTER TABLE aws_eks_nodegroup_ec2_subnet ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_eks_nodegroup_ec2_subnet ON aws_eks_nodegroup_ec2_subnet
USING (
  current_user = 'goldfig_ro'
  OR
  provider_account_id = current_setting('gf.provider_account_id', true)::int
);


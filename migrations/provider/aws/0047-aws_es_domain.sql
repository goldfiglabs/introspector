-- migrate:up

CREATE TABLE IF NOT EXISTS aws_es_domain (
  _id INTEGER NOT NULL PRIMARY KEY,
  uri TEXT NOT NULL,
  provider_account_id INTEGER NOT NULL,domainid TEXT,
  domainname TEXT,
  arn TEXT,
  created BOOLEAN,
  deleted BOOLEAN,
  endpoint TEXT,
  endpoints JSONB,
  processing BOOLEAN,
  upgradeprocessing BOOLEAN,
  elasticsearchversion TEXT,
  elasticsearchclusterconfig JSONB,
  ebsoptions JSONB,
  accesspolicies JSONB,
  snapshotoptions JSONB,
  vpcoptions JSONB,
  cognitooptions JSONB,
  encryptionatrestoptions JSONB,
  nodetonodeencryptionoptions JSONB,
  advancedoptions JSONB,
  logpublishingoptions JSONB,
  servicesoftwareoptions JSONB,
  domainendpointoptions JSONB,
  advancedsecurityoptions JSONB,
  tags JSONB,
  _ec2_vpc_id INTEGER,
    FOREIGN KEY (_ec2_vpc_id) REFERENCES aws_ec2_vpc (_id) ON DELETE SET NULL,
  _account_id INTEGER,
    FOREIGN KEY (_account_id) REFERENCES aws_organizations_account (_id) ON DELETE SET NULL,
  FOREIGN KEY (provider_account_id) REFERENCES public.provider_account (id) ON DELETE CASCADE,
  FOREIGN KEY (_id) REFERENCES public.resource (id) ON DELETE CASCADE
);

COMMENT ON TABLE aws_es_domain IS 'es Domain resources and their associated attributes.';

ALTER TABLE aws_es_domain ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_es_domain ON aws_es_domain
USING (
  current_user = 'introspector_ro'
  OR
  provider_account_id = current_setting('introspector.provider_account_id', true)::int
);



CREATE TABLE IF NOT EXISTS aws_es_domain_ec2_subnet (
  domain_id INTEGER NOT NULL REFERENCES aws_es_domain (_id) ON DELETE CASCADE,
  subnet_id INTEGER NOT NULL REFERENCES aws_ec2_subnet (_id) ON DELETE CASCADE,
  provider_account_id INTEGER NOT NULL REFERENCES provider_account (id) ON DELETE CASCADE,PRIMARY KEY (domain_id, subnet_id)
);

ALTER TABLE aws_es_domain_ec2_subnet ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_es_domain_ec2_subnet ON aws_es_domain_ec2_subnet
USING (
  current_user = 'introspector_ro'
  OR
  provider_account_id = current_setting('introspector.provider_account_id', true)::int
);



CREATE TABLE IF NOT EXISTS aws_es_domain_ec2_securitygroup (
  domain_id INTEGER NOT NULL REFERENCES aws_es_domain (_id) ON DELETE CASCADE,
  securitygroup_id INTEGER NOT NULL REFERENCES aws_ec2_securitygroup (_id) ON DELETE CASCADE,
  provider_account_id INTEGER NOT NULL REFERENCES provider_account (id) ON DELETE CASCADE,PRIMARY KEY (domain_id, securitygroup_id)
);

ALTER TABLE aws_es_domain_ec2_securitygroup ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_es_domain_ec2_securitygroup ON aws_es_domain_ec2_securitygroup
USING (
  current_user = 'introspector_ro'
  OR
  provider_account_id = current_setting('introspector.provider_account_id', true)::int
);


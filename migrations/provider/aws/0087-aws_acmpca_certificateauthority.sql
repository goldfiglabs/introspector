-- migrate:up

CREATE TABLE IF NOT EXISTS aws_acmpca_certificateauthority (
  _id INTEGER NOT NULL PRIMARY KEY,
  uri TEXT NOT NULL,
  provider_account_id INTEGER NOT NULL,
  arn TEXT,
  owneraccount TEXT,
  createdat TIMESTAMP WITH TIME ZONE,
  laststatechangeat TIMESTAMP WITH TIME ZONE,
  type TEXT,
  serial TEXT,
  status TEXT,
  notbefore TIMESTAMP WITH TIME ZONE,
  notafter TIMESTAMP WITH TIME ZONE,
  failurereason TEXT,
  certificateauthorityconfiguration JSONB,
  revocationconfiguration JSONB,
  restorableuntil TIMESTAMP WITH TIME ZONE,
  policy JSONB,
  tags JSONB,
  _tags JSONB,
  _policy JSONB,
  _account_id INTEGER,
    FOREIGN KEY (_account_id) REFERENCES aws_organizations_account (_id) ON DELETE SET NULL,
  FOREIGN KEY (provider_account_id) REFERENCES public.provider_account (id) ON DELETE CASCADE,
  FOREIGN KEY (_id) REFERENCES public.resource (id) ON DELETE CASCADE
);

COMMENT ON TABLE aws_acmpca_certificateauthority IS 'acm-pca CertificateAuthority resources and their associated attributes.';

ALTER TABLE aws_acmpca_certificateauthority ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_acmpca_certificateauthority ON aws_acmpca_certificateauthority
USING (
  current_user = 'introspector_ro'
  OR
  provider_account_id = current_setting('introspector.provider_account_id', true)::int
);


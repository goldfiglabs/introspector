-- migrate:up

CREATE TABLE IF NOT EXISTS aws_acm_certificate (
  _id INTEGER NOT NULL PRIMARY KEY,
  uri TEXT NOT NULL,
  provider_account_id INTEGER NOT NULL,certificatearn TEXT,
  domainname TEXT,
  subjectalternativenames JSONB,
  domainvalidationoptions JSONB,
  serial TEXT,
  subject TEXT,
  issuer TEXT,
  createdat TIMESTAMP WITH TIME ZONE,
  issuedat TIMESTAMP WITH TIME ZONE,
  importedat TIMESTAMP WITH TIME ZONE,
  status TEXT,
  revokedat TIMESTAMP WITH TIME ZONE,
  revocationreason TEXT,
  notbefore TIMESTAMP WITH TIME ZONE,
  notafter TIMESTAMP WITH TIME ZONE,
  keyalgorithm TEXT,
  signaturealgorithm TEXT,
  inuseby JSONB,
  failurereason TEXT,
  type TEXT,
  renewalsummary JSONB,
  keyusages JSONB,
  extendedkeyusages JSONB,
  certificateauthorityarn TEXT,
  renewaleligibility TEXT,
  certificatetransparencyloggingpreference TEXT,
  tags JSONB,
  _account_id INTEGER,
    FOREIGN KEY (_account_id) REFERENCES aws_organizations_account (_id) ON DELETE SET NULL,
  FOREIGN KEY (provider_account_id) REFERENCES public.provider_account (id) ON DELETE CASCADE,
  FOREIGN KEY (_id) REFERENCES public.resource (id) ON DELETE CASCADE
);

COMMENT ON TABLE aws_acm_certificate IS 'acm Certificate resources and their associated attributes.';

ALTER TABLE aws_acm_certificate ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_acm_certificate ON aws_acm_certificate
USING (
  current_user = 'goldfig_ro'
  OR
  provider_account_id = current_setting('gf.provider_account_id', true)::int
);


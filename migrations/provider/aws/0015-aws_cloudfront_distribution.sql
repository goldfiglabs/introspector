-- migrate:up

CREATE TABLE IF NOT EXISTS aws_cloudfront_distribution (
  _id INTEGER NOT NULL PRIMARY KEY,
  uri TEXT NOT NULL,
  provider_account_id INTEGER NOT NULL,id TEXT,
  arn TEXT,
  status TEXT,
  lastmodifiedtime TIMESTAMP WITH TIME ZONE,
  inprogressinvalidationbatches INTEGER,
  domainname TEXT,
  activetrustedsigners JSONB,
  activetrustedkeygroups JSONB,
  aliasicprecordals JSONB,
  tags JSONB,
  callerreference TEXT,
  aliases JSONB,
  defaultrootobject TEXT,
  origins JSONB,
  origingroups JSONB,
  defaultcachebehavior JSONB,
  cachebehaviors JSONB,
  customerrorresponses JSONB,
  comment TEXT,
  logging JSONB,
  priceclass TEXT,
  enabled BOOLEAN,
  viewercertificate JSONB,
  restrictions JSONB,
  webaclid TEXT,
  httpversion TEXT,
  isipv6enabled BOOLEAN,
  _account_id INTEGER,
    FOREIGN KEY (_account_id) REFERENCES aws_organizations_account (_id) ON DELETE SET NULL,
  FOREIGN KEY (provider_account_id) REFERENCES public.provider_account (id) ON DELETE CASCADE,
  FOREIGN KEY (_id) REFERENCES public.resource (id) ON DELETE CASCADE
);

COMMENT ON TABLE aws_cloudfront_distribution IS 'cloudfront Distribution resources and their associated attributes.';

ALTER TABLE aws_cloudfront_distribution ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_cloudfront_distribution ON aws_cloudfront_distribution
USING (
  current_user = 'introspector_ro'
  OR
  provider_account_id = current_setting('introspector.provider_account_id', true)::int
);


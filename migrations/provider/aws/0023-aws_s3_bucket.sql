-- migrate:up

CREATE TABLE IF NOT EXISTS aws_s3_bucket (
  _id INTEGER NOT NULL PRIMARY KEY,
  uri TEXT NOT NULL,
  provider_account_id INTEGER NOT NULL,name TEXT,
  creationdate TIMESTAMP WITH TIME ZONE,
  analyticsconfigurations JSONB,
  inventoryconfigurations JSONB,
  metricsconfigurations JSONB,
  accelerateconfiguration TEXT,
  acl JSONB,
  cors JSONB,
  encryption JSONB,
  lifecycleconfiguration JSONB,
  location TEXT,
  logging JSONB,
  notificationconfiguration JSONB,
  policy JSONB,
  policystatus JSONB,
  replication JSONB,
  requestpayment TEXT,
  tagging JSONB,
  versioning JSONB,
  website JSONB,
  blockpublicacls BOOLEAN,
  ignorepublicacls BOOLEAN,
  blockpublicpolicy BOOLEAN,
  restrictpublicbuckets BOOLEAN,
  _account_id INTEGER,
    FOREIGN KEY (_account_id) REFERENCES aws_organizations_account (_id) ON DELETE SET NULL,
  FOREIGN KEY (provider_account_id) REFERENCES public.provider_account (id) ON DELETE CASCADE,
  FOREIGN KEY (_id) REFERENCES public.resource (id) ON DELETE CASCADE
);

COMMENT ON TABLE aws_s3_bucket IS 's3 Bucket resources and their associated attributes.';

ALTER TABLE aws_s3_bucket ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_s3_bucket ON aws_s3_bucket
USING (
  current_user = 'introspector_ro'
  OR
  provider_account_id = current_setting('introspector.provider_account_id', true)::int
);


-- migrate:up

CREATE TABLE IF NOT EXISTS aws_sns_topic (
  _id INTEGER NOT NULL PRIMARY KEY,
  uri TEXT NOT NULL,
  provider_account_id INTEGER NOT NULL,topicarn TEXT,
  tags JSONB,
  deliverypolicy JSONB,
  displayname TEXT,
  owner TEXT,
  policy JSONB,
  subscriptionsconfirmed INTEGER,
  subscriptionsdeleted INTEGER,
  subscriptionspending INTEGER,
  effectivedeliverypolicy JSONB,
  kmsmasterkeyid TEXT,
  _account_id INTEGER,
    FOREIGN KEY (_account_id) REFERENCES aws_organizations_account (_id) ON DELETE SET NULL,
  FOREIGN KEY (provider_account_id) REFERENCES public.provider_account (id) ON DELETE CASCADE,
  FOREIGN KEY (_id) REFERENCES public.resource (id) ON DELETE CASCADE
);

COMMENT ON TABLE aws_sns_topic IS 'sns Topic resources and their associated attributes.';

ALTER TABLE aws_sns_topic ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_sns_topic ON aws_sns_topic
USING (
  current_user = 'introspector_ro'
  OR
  provider_account_id = current_setting('introspector.provider_account_id', true)::int
);


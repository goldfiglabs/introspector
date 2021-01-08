-- migrate:up

CREATE TABLE IF NOT EXISTS aws_sns_subscription (
  _id INTEGER NOT NULL PRIMARY KEY,
  uri TEXT NOT NULL,
  provider_account_id INTEGER NOT NULL,subscriptionarn TEXT,
  owner TEXT,
  protocol TEXT,
  endpoint TEXT,
  topicarn TEXT,
  confirmationwasauthenticated BOOLEAN,
  deliverypolicy JSONB,
  effectivedeliverypolicy JSONB,
  filterpolicy JSONB,
  pendingconfirmation BOOLEAN,
  rawmessagedelivery BOOLEAN,
  redrivepolicy JSONB,
  _topic_id INTEGER,
    FOREIGN KEY (_topic_id) REFERENCES aws_sns_topic (_id) ON DELETE SET NULL,
  _account_id INTEGER,
    FOREIGN KEY (_account_id) REFERENCES aws_organizations_account (_id) ON DELETE SET NULL,
  FOREIGN KEY (provider_account_id) REFERENCES public.provider_account (id) ON DELETE CASCADE,
  FOREIGN KEY (_id) REFERENCES public.resource (id) ON DELETE CASCADE
);

COMMENT ON TABLE aws_sns_subscription IS 'sns Subscription resources and their associated attributes.';

ALTER TABLE aws_sns_subscription ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_sns_subscription ON aws_sns_subscription
USING (
  current_user = 'goldfig_ro'
  OR
  provider_account_id = current_setting('gf.provider_account_id', true)::int
);


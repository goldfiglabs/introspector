-- migrate:up

CREATE TABLE IF NOT EXISTS aws_sqs_queue (
  _id INTEGER NOT NULL PRIMARY KEY,
  uri TEXT NOT NULL,
  provider_account_id INTEGER NOT NULL,receivemessagewaittimeseconds INTEGER,
  visibilitytimeout INTEGER,
  approximatenumberofmessages INTEGER,
  approximatenumberofmessagesnotvisible INTEGER,
  approximatenumberofmessagesdelayed INTEGER,
  delayseconds INTEGER,
  createdtimestamp TIMESTAMP WITH TIME ZONE,
  lastmodifiedtimestamp TIMESTAMP WITH TIME ZONE,
  queuearn TEXT,
  maximummessagesize INTEGER,
  messageretentionperiod INTEGER,
  url TEXT,
  tags JSONB,
  policy JSONB,
  redrivepolicy JSONB,
  fifoqueue BOOLEAN,
  contentbaseddeduplication BOOLEAN,
  kmsmasterkeyid TEXT,
  kmsdatakeyreuseperiodsecond TEXT,
  _kms_key_id INTEGER,
    FOREIGN KEY (_kms_key_id) REFERENCES aws_kms_key (_id) ON DELETE SET NULL,
  _account_id INTEGER,
    FOREIGN KEY (_account_id) REFERENCES aws_organizations_account (_id) ON DELETE SET NULL,
  FOREIGN KEY (provider_account_id) REFERENCES public.provider_account (id) ON DELETE CASCADE,
  FOREIGN KEY (_id) REFERENCES public.resource (id) ON DELETE CASCADE
);

COMMENT ON TABLE aws_sqs_queue IS 'sqs Queue resources and their associated attributes.';

ALTER TABLE aws_sqs_queue ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_sqs_queue ON aws_sqs_queue
USING (
  current_user = 'goldfig_ro'
  OR
  provider_account_id = current_setting('gf.provider_account_id', true)::int
);


-- migrate:up

CREATE TABLE IF NOT EXISTS aws_logs_loggroup (
  _id INTEGER NOT NULL PRIMARY KEY,
  uri TEXT NOT NULL,
  provider_account_id INTEGER NOT NULL,loggroupname TEXT,
  creationtime BIGINT,
  retentionindays INTEGER,
  metricfiltercount INTEGER,
  arn TEXT,
  storedbytes BIGINT,
  kmskeyid TEXT,
  tags JSONB,
  metricfilters JSONB,
  _account_id INTEGER,
    FOREIGN KEY (_account_id) REFERENCES aws_organizations_account (_id) ON DELETE SET NULL,
  FOREIGN KEY (provider_account_id) REFERENCES public.provider_account (id) ON DELETE CASCADE,
  FOREIGN KEY (_id) REFERENCES public.resource (id) ON DELETE CASCADE
);

COMMENT ON TABLE aws_logs_loggroup IS 'logs LogGroup resources and their associated attributes.';

ALTER TABLE aws_logs_loggroup ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_logs_loggroup ON aws_logs_loggroup
USING (
  current_user = 'introspector_ro'
  OR
  provider_account_id = current_setting('introspector.provider_account_id', true)::int
);


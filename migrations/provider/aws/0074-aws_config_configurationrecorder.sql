-- migrate:up

CREATE TABLE IF NOT EXISTS aws_config_configurationrecorder (
  _id INTEGER NOT NULL PRIMARY KEY,
  uri TEXT NOT NULL,
  provider_account_id INTEGER NOT NULL,rolearn TEXT,
  allsupported BOOLEAN,
  includeglobalresourcetypes BOOLEAN,
  resourcetypes JSONB,
  name TEXT,
  laststarttime TIMESTAMP WITH TIME ZONE,
  laststoptime TIMESTAMP WITH TIME ZONE,
  recording BOOLEAN,
  laststatus TEXT,
  lasterrorcode TEXT,
  lasterrormessage TEXT,
  laststatuschangetime TIMESTAMP WITH TIME ZONE,
  _iam_role_id INTEGER,
    FOREIGN KEY (_iam_role_id) REFERENCES aws_iam_role (_id) ON DELETE SET NULL,
  _account_id INTEGER,
    FOREIGN KEY (_account_id) REFERENCES aws_organizations_account (_id) ON DELETE SET NULL,
  FOREIGN KEY (provider_account_id) REFERENCES public.provider_account (id) ON DELETE CASCADE,
  FOREIGN KEY (_id) REFERENCES public.resource (id) ON DELETE CASCADE
);

COMMENT ON TABLE aws_config_configurationrecorder IS 'config ConfigurationRecorder resources and their associated attributes.';

ALTER TABLE aws_config_configurationrecorder ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_config_configurationrecorder ON aws_config_configurationrecorder
USING (
  current_user = 'introspector_ro'
  OR
  provider_account_id = current_setting('introspector.provider_account_id', true)::int
);


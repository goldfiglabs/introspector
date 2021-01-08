-- migrate:up

CREATE TABLE IF NOT EXISTS aws_cloudwatch_compositealarm (
  _id INTEGER NOT NULL PRIMARY KEY,
  uri TEXT NOT NULL,
  provider_account_id INTEGER NOT NULL,actionsenabled BOOLEAN,
  alarmactions JSONB,
  alarmarn TEXT,
  alarmconfigurationupdatedtimestamp TIMESTAMP WITH TIME ZONE,
  alarmdescription TEXT,
  alarmname TEXT,
  alarmrule TEXT,
  insufficientdataactions JSONB,
  okactions JSONB,
  statereason TEXT,
  statereasondata TEXT,
  stateupdatedtimestamp TIMESTAMP WITH TIME ZONE,
  statevalue TEXT,
  tags JSONB,
  _account_id INTEGER,
    FOREIGN KEY (_account_id) REFERENCES aws_organizations_account (_id) ON DELETE SET NULL,
  FOREIGN KEY (provider_account_id) REFERENCES public.provider_account (id) ON DELETE CASCADE,
  FOREIGN KEY (_id) REFERENCES public.resource (id) ON DELETE CASCADE
);

COMMENT ON TABLE aws_cloudwatch_compositealarm IS 'cloudwatch CompositeAlarm resources and their associated attributes.';

ALTER TABLE aws_cloudwatch_compositealarm ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_cloudwatch_compositealarm ON aws_cloudwatch_compositealarm
USING (
  current_user = 'goldfig_ro'
  OR
  provider_account_id = current_setting('gf.provider_account_id', true)::int
);


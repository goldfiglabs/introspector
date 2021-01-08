-- migrate:up

CREATE TABLE IF NOT EXISTS aws_cloudtrail_trail (
  _id INTEGER NOT NULL PRIMARY KEY,
  uri TEXT NOT NULL,
  provider_account_id INTEGER NOT NULL,name TEXT,
  s3bucketname TEXT,
  s3keyprefix TEXT,
  snstopicname TEXT,
  snstopicarn TEXT,
  includeglobalserviceevents BOOLEAN,
  ismultiregiontrail BOOLEAN,
  homeregion TEXT,
  trailarn TEXT,
  logfilevalidationenabled BOOLEAN,
  cloudwatchlogsloggrouparn TEXT,
  cloudwatchlogsrolearn TEXT,
  kmskeyid TEXT,
  hascustomeventselectors BOOLEAN,
  hasinsightselectors BOOLEAN,
  isorganizationtrail BOOLEAN,
  islogging BOOLEAN,
  latestdeliveryerror TEXT,
  latestnotificationerror TEXT,
  latestdeliverytime TIMESTAMP WITH TIME ZONE,
  latestnotificationtime TIMESTAMP WITH TIME ZONE,
  startloggingtime TIMESTAMP WITH TIME ZONE,
  stoploggingtime TIMESTAMP WITH TIME ZONE,
  latestcloudwatchlogsdeliveryerror TEXT,
  latestcloudwatchlogsdeliverytime TIMESTAMP WITH TIME ZONE,
  latestdigestdeliverytime TIMESTAMP WITH TIME ZONE,
  latestdigestdeliveryerror TEXT,
  latestdeliveryattempttime TEXT,
  latestnotificationattempttime TEXT,
  latestnotificationattemptsucceeded TEXT,
  latestdeliveryattemptsucceeded TEXT,
  timeloggingstarted TEXT,
  timeloggingstopped TEXT,
  tags JSONB,
  eventselectors JSONB,
  _s3_bucket_id INTEGER,
    FOREIGN KEY (_s3_bucket_id) REFERENCES aws_s3_bucket (_id) ON DELETE SET NULL,
  _logs_loggroup_id INTEGER,
    FOREIGN KEY (_logs_loggroup_id) REFERENCES aws_logs_loggroup (_id) ON DELETE SET NULL,
  _account_id INTEGER,
    FOREIGN KEY (_account_id) REFERENCES aws_organizations_account (_id) ON DELETE SET NULL,
  FOREIGN KEY (provider_account_id) REFERENCES public.provider_account (id) ON DELETE CASCADE,
  FOREIGN KEY (_id) REFERENCES public.resource (id) ON DELETE CASCADE
);

COMMENT ON TABLE aws_cloudtrail_trail IS 'cloudtrail Trail resources and their associated attributes.';

ALTER TABLE aws_cloudtrail_trail ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_cloudtrail_trail ON aws_cloudtrail_trail
USING (
  current_user = 'goldfig_ro'
  OR
  provider_account_id = current_setting('gf.provider_account_id', true)::int
);


-- migrate:up

CREATE TABLE IF NOT EXISTS aws_ec2_flowlog (
  _id INTEGER NOT NULL PRIMARY KEY,
  uri TEXT NOT NULL,
  provider_account_id INTEGER NOT NULL,creationtime TIMESTAMP WITH TIME ZONE,
  deliverlogserrormessage TEXT,
  deliverlogspermissionarn TEXT,
  deliverlogsstatus TEXT,
  flowlogid TEXT,
  flowlogstatus TEXT,
  loggroupname TEXT,
  resourceid TEXT,
  traffictype TEXT,
  logdestinationtype TEXT,
  logdestination TEXT,
  logformat TEXT,
  tags JSONB,
  maxaggregationinterval INTEGER,
  _iam_role_id INTEGER,
    FOREIGN KEY (_iam_role_id) REFERENCES aws_iam_role (_id) ON DELETE SET NULL,
  _logs_loggroup_id INTEGER,
    FOREIGN KEY (_logs_loggroup_id) REFERENCES aws_logs_loggroup (_id) ON DELETE SET NULL,
  _s3_bucket_id INTEGER,
    FOREIGN KEY (_s3_bucket_id) REFERENCES aws_s3_bucket (_id) ON DELETE SET NULL,
  _vpc_id INTEGER,
    FOREIGN KEY (_vpc_id) REFERENCES aws_ec2_vpc (_id) ON DELETE SET NULL,
  _account_id INTEGER,
    FOREIGN KEY (_account_id) REFERENCES aws_organizations_account (_id) ON DELETE SET NULL,
  FOREIGN KEY (provider_account_id) REFERENCES public.provider_account (id) ON DELETE CASCADE,
  FOREIGN KEY (_id) REFERENCES public.resource (id) ON DELETE CASCADE
);

COMMENT ON TABLE aws_ec2_flowlog IS 'ec2 FlowLog resources and their associated attributes.';

ALTER TABLE aws_ec2_flowlog ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_ec2_flowlog ON aws_ec2_flowlog
USING (
  current_user = 'introspector_ro'
  OR
  provider_account_id = current_setting('introspector.provider_account_id', true)::int
);


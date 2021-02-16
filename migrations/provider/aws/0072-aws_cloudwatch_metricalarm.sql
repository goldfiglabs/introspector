-- migrate:up

CREATE TABLE IF NOT EXISTS aws_cloudwatch_metricalarm (
  _id INTEGER NOT NULL PRIMARY KEY,
  uri TEXT NOT NULL,
  provider_account_id INTEGER NOT NULL,alarmname TEXT,
  alarmarn TEXT,
  alarmdescription TEXT,
  alarmconfigurationupdatedtimestamp TIMESTAMP WITH TIME ZONE,
  actionsenabled BOOLEAN,
  okactions JSONB,
  alarmactions JSONB,
  insufficientdataactions JSONB,
  statevalue TEXT,
  statereason TEXT,
  statereasondata TEXT,
  stateupdatedtimestamp TIMESTAMP WITH TIME ZONE,
  metricname TEXT,
  namespace TEXT,
  statistic TEXT,
  extendedstatistic TEXT,
  dimensions JSONB,
  period INTEGER,
  unit TEXT,
  evaluationperiods INTEGER,
  datapointstoalarm INTEGER,
  threshold DOUBLE PRECISION,
  comparisonoperator TEXT,
  treatmissingdata TEXT,
  evaluatelowsamplecountpercentile TEXT,
  metrics JSONB,
  thresholdmetricid TEXT,
  tags JSONB,
  _metric_id INTEGER,
    FOREIGN KEY (_metric_id) REFERENCES aws_cloudwatch_metric (_id) ON DELETE SET NULL,
  _account_id INTEGER,
    FOREIGN KEY (_account_id) REFERENCES aws_organizations_account (_id) ON DELETE SET NULL,
  FOREIGN KEY (provider_account_id) REFERENCES public.provider_account (id) ON DELETE CASCADE,
  FOREIGN KEY (_id) REFERENCES public.resource (id) ON DELETE CASCADE
);

COMMENT ON TABLE aws_cloudwatch_metricalarm IS 'cloudwatch MetricAlarm resources and their associated attributes.';

ALTER TABLE aws_cloudwatch_metricalarm ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_cloudwatch_metricalarm ON aws_cloudwatch_metricalarm
USING (
  current_user = 'introspector_ro'
  OR
  provider_account_id = current_setting('introspector.provider_account_id', true)::int
);



CREATE TABLE IF NOT EXISTS aws_cloudwatch_metricalarm_sns_topic (
  metricalarm_id INTEGER NOT NULL REFERENCES aws_cloudwatch_metricalarm (_id) ON DELETE CASCADE,
  topic_id INTEGER NOT NULL REFERENCES aws_sns_topic (_id) ON DELETE CASCADE,
  provider_account_id INTEGER NOT NULL REFERENCES provider_account (id) ON DELETE CASCADE,PRIMARY KEY (metricalarm_id, topic_id)
);

ALTER TABLE aws_cloudwatch_metricalarm_sns_topic ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_cloudwatch_metricalarm_sns_topic ON aws_cloudwatch_metricalarm_sns_topic
USING (
  current_user = 'introspector_ro'
  OR
  provider_account_id = current_setting('introspector.provider_account_id', true)::int
);


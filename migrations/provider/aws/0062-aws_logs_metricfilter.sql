-- migrate:up

CREATE TABLE IF NOT EXISTS aws_logs_metricfilter (
  _id INTEGER NOT NULL PRIMARY KEY,
  uri TEXT NOT NULL,
  provider_account_id INTEGER NOT NULL,filtername TEXT,
  filterpattern TEXT,
  metrictransformations JSONB,
  creationtime BIGINT,
  loggroupname TEXT,
  _loggroup_id INTEGER,
    FOREIGN KEY (_loggroup_id) REFERENCES aws_logs_loggroup (_id) ON DELETE SET NULL,
  _account_id INTEGER,
    FOREIGN KEY (_account_id) REFERENCES aws_organizations_account (_id) ON DELETE SET NULL,
  FOREIGN KEY (provider_account_id) REFERENCES public.provider_account (id) ON DELETE CASCADE,
  FOREIGN KEY (_id) REFERENCES public.resource (id) ON DELETE CASCADE
);

COMMENT ON TABLE aws_logs_metricfilter IS 'logs MetricFilter resources and their associated attributes.';

ALTER TABLE aws_logs_metricfilter ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_logs_metricfilter ON aws_logs_metricfilter
USING (
  current_user = 'goldfig_ro'
  OR
  provider_account_id = current_setting('gf.provider_account_id', true)::int
);



CREATE TABLE IF NOT EXISTS aws_logs_metricfilter_cloudwatch_metric (
  metricfilter_id INTEGER NOT NULL REFERENCES aws_logs_metricfilter (_id) ON DELETE CASCADE,
  metric_id INTEGER NOT NULL REFERENCES aws_cloudwatch_metric (_id) ON DELETE CASCADE,
  provider_account_id INTEGER NOT NULL REFERENCES provider_account (id) ON DELETE CASCADE,MetricValue TEXT,
  DefaultValue DOUBLE PRECISION,
  PRIMARY KEY (metricfilter_id, metric_id)
);

ALTER TABLE aws_logs_metricfilter_cloudwatch_metric ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_logs_metricfilter_cloudwatch_metric ON aws_logs_metricfilter_cloudwatch_metric
USING (
  current_user = 'goldfig_ro'
  OR
  provider_account_id = current_setting('gf.provider_account_id', true)::int
);


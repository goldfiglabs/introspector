-- migrate:up
ALTER TABLE aws_logs_loggroup ADD COLUMN policy JSONB;
ALTER TABLE aws_logs_loggroup ADD COLUMN _policy JSONB;

-- migrate:down
ALTER TABLE aws_logs_loggroup DROP COLUMN policy;
ALTER TABLE aws_logs_loggroup DROP COLUMN _policy;
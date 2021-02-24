-- migrate:up
ALTER TABLE aws_lambda_alias ADD COLUMN _policy JSONB;

-- migrate:down
ALTER TABLE aws_lambda_alias DROP COLUMN _policy JSONB;
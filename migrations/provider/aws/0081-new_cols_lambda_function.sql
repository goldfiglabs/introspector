-- migrate:up
ALTER TABLE aws_lambda_function ADD COLUMN packagetype TEXT;
ALTER TABLE aws_lambda_function ADD COLUMN imageconfigresponse JSONB;

-- migrate:down
ALTER TABLE aws_lambda_function DROP COLUMN packagetype;
ALTER TABLE aws_lambda_function DROP COLUMN imageconfigresponse;

-- migrate:up
ALTER TABLE aws_apigateway_restapi ADD COLUMN _policy JSONB;
ALTER TABLE aws_ecr_repository ADD COLUMN _policy JSONB;
ALTER TABLE aws_es_domain ADD COLUMN _policy JSONB;
ALTER TABLE aws_iam_role ADD COLUMN _policy JSONB;
ALTER TABLE aws_kms_key ADD COLUMN _policy JSONB;
ALTER TABLE aws_lambda_function ADD COLUMN _policy JSONB;
ALTER TABLE aws_s3_bucket ADD COLUMN _policy JSONB;
ALTER TABLE aws_ses_identity ADD COLUMN _policy JSONB;
ALTER TABLE aws_sns_topic ADD COLUMN _policy JSONB;
ALTER TABLE aws_sqs_queue ADD COLUMN _policy JSONB;


-- migrate:down
ALTER TABLE aws_apigateway_restapi DROP COLUMN _policy;
ALTER TABLE aws_ecr_repository DROP COLUMN _policy;
ALTER TABLE aws_es_domain DROP COLUMN _policy;
ALTER TABLE aws_iam_role DROP COLUMN _policy;
ALTER TABLE aws_kms_key DROP COLUMN _policy;
ALTER TABLE aws_lambda_function DROP COLUMN _policy;
ALTER TABLE aws_s3_bucket DROP COLUMN _policy;
ALTER TABLE aws_ses_identity DROP COLUMN _policy;
ALTER TABLE aws_sns_topic DROP COLUMN _policy;
ALTER TABLE aws_sqs_queue DROP COLUMN _policy;


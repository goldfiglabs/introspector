-- migrate:up
ALTER TABLE aws_ec2_image ADD COLUMN launchpermissions JSONB;

-- migrate:down
ALTER TABLE aws_ec2_image DROP COLUMN launchpermissions;
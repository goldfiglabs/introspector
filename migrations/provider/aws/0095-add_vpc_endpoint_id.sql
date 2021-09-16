-- migrate:up
ALTER TABLE aws_ec2_networkinterface ADD COLUMN _vpcendpoint_id INTEGER REFERENCES aws_ec2_vpcendpoint (_id) ON DELETE SET NULL;

-- migrate:down
ALTER TABLE aws_ec2_networkinterface DROP COLUMN _vpcendpoint_id;
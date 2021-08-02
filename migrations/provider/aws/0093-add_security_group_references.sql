-- migrate:up

CREATE TABLE IF NOT EXISTS aws_ec2_securitygroup_vpcpeeringconnection (
  securitygroup_id INTEGER NOT NULL REFERENCES aws_ec2_securitygroup (_id) ON DELETE CASCADE,
  vpcpeeringconnection_id INTEGER NOT NULL REFERENCES aws_ec2_vpcpeeringconnection (_id) ON DELETE CASCADE,
  provider_account_id INTEGER NOT NULL REFERENCES provider_account (id) ON DELETE CASCADE,PRIMARY KEY (securitygroup_id, vpcpeeringconnection_id)
);

ALTER TABLE aws_ec2_securitygroup_vpcpeeringconnection ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_ec2_securitygroup_vpcpeeringconnection ON aws_ec2_securitygroup_vpcpeeringconnection
USING (
  current_user = 'introspector_ro'
  OR
  provider_account_id = current_setting('introspector.provider_account_id', true)::int
);

-- migrate:down
DROP TABLE aws_ec2_securitygroup_vpcpeeringconnection;

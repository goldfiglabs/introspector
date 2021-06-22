-- migrate:up
ALTER TABLE aws_ec2_volume ADD COLUMN throughput INTEGER;
ALTER TABLE aws_eks_nodegroup ADD COLUMN capacitytype TEXT;
ALTER TABLE aws_lambda_functionversion ADD COLUMN packagetype TEXT;
ALTER TABLE aws_lambda_functionversion ADD COLUMN imageconfigresponse JSONB;
ALTER TABLE aws_rds_dbcluster ADD COLUMN pendingmodifiedvalues JSONB;
ALTER TABLE aws_rds_dbinstance ADD COLUMN dbinstanceautomatedbackupsreplications JSONB;
ALTER TABLE aws_rds_dbinstance ADD COLUMN customerownedipenabled BOOLEAN;
ALTER TABLE aws_redshift_cluster ADD COLUMN availabilityzonerelocationstatus TEXT;

-- migrate:down
ALTER TABLE aws_redshift_cluster DROP COLUMN availabilityzonerelocationstatus;
ALTER TABLE aws_rds_dbinstance DROP COLUMN customerownedipenabled;
ALTER TABLE aws_rds_dbinstance DROP COLUMN dbinstanceautomatedbackupsreplications;
ALTER TABLE aws_rds_dbcluster DROP COLUMN pendingmodifiedvalues;
ALTER TABLE aws_lambda_functionversion DROP COLUMN imageconfigresponse;
ALTER TABLE aws_lambda_functionversion DROP COLUMN packagetype;
ALTER TABLE aws_eks_nodegroup DROP COLUMN capacitytype;
ALTER TABLE aws_ec2_volume DROP COLUMN throughput;
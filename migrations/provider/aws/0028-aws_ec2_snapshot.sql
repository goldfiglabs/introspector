-- migrate:up

CREATE TABLE IF NOT EXISTS aws_ec2_snapshot (
  _id INTEGER NOT NULL PRIMARY KEY,
  uri TEXT NOT NULL,
  provider_account_id INTEGER NOT NULL,dataencryptionkeyid TEXT,
  description TEXT,
  encrypted BOOLEAN,
  kmskeyid TEXT,
  ownerid TEXT,
  progress TEXT,
  snapshotid TEXT,
  starttime TIMESTAMP WITH TIME ZONE,
  state TEXT,
  statemessage TEXT,
  volumeid TEXT,
  volumesize INTEGER,
  owneralias TEXT,
  tags JSONB,
  createvolumepermissions JSONB,
  _kms_key_id INTEGER,
    FOREIGN KEY (_kms_key_id) REFERENCES aws_kms_key (_id) ON DELETE SET NULL,
  _volume_id INTEGER,
    FOREIGN KEY (_volume_id) REFERENCES aws_ec2_volume (_id) ON DELETE SET NULL,
  _account_id INTEGER,
    FOREIGN KEY (_account_id) REFERENCES aws_organizations_account (_id) ON DELETE SET NULL,
  FOREIGN KEY (provider_account_id) REFERENCES public.provider_account (id) ON DELETE CASCADE,
  FOREIGN KEY (_id) REFERENCES public.resource (id) ON DELETE CASCADE
);

COMMENT ON TABLE aws_ec2_snapshot IS 'ec2 Snapshot resources and their associated attributes.';

ALTER TABLE aws_ec2_snapshot ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_ec2_snapshot ON aws_ec2_snapshot
USING (
  current_user = 'introspector_ro'
  OR
  provider_account_id = current_setting('introspector.provider_account_id', true)::int
);


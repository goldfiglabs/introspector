-- migrate:up

CREATE TABLE IF NOT EXISTS aws_elasticbeanstalk_application (
  _id INTEGER NOT NULL PRIMARY KEY,
  uri TEXT NOT NULL,
  provider_account_id INTEGER NOT NULL,applicationarn TEXT,
  applicationname TEXT,
  description TEXT,
  datecreated TIMESTAMP WITH TIME ZONE,
  dateupdated TIMESTAMP WITH TIME ZONE,
  versions JSONB,
  configurationtemplates JSONB,
  resourcelifecycleconfig JSONB,
  tags JSONB,
  _account_id INTEGER,
    FOREIGN KEY (_account_id) REFERENCES aws_organizations_account (_id) ON DELETE SET NULL,
  FOREIGN KEY (provider_account_id) REFERENCES public.provider_account (id) ON DELETE CASCADE,
  FOREIGN KEY (_id) REFERENCES public.resource (id) ON DELETE CASCADE
);

COMMENT ON TABLE aws_elasticbeanstalk_application IS 'elasticbeanstalk Application resources and their associated attributes.';

ALTER TABLE aws_elasticbeanstalk_application ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_elasticbeanstalk_application ON aws_elasticbeanstalk_application
USING (
  current_user = 'introspector_ro'
  OR
  provider_account_id = current_setting('introspector.provider_account_id', true)::int
);


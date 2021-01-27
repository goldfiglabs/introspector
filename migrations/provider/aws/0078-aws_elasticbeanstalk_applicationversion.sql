-- migrate:up

CREATE TABLE IF NOT EXISTS aws_elasticbeanstalk_applicationversion (
  _id INTEGER NOT NULL PRIMARY KEY,
  uri TEXT NOT NULL,
  provider_account_id INTEGER NOT NULL,applicationversionarn TEXT,
  applicationname TEXT,
  description TEXT,
  versionlabel TEXT,
  sourcebuildinformation JSONB,
  buildarn TEXT,
  sourcebundle JSONB,
  datecreated TIMESTAMP WITH TIME ZONE,
  dateupdated TIMESTAMP WITH TIME ZONE,
  status TEXT,
  tags JSONB,
  _application_id INTEGER,
    FOREIGN KEY (_application_id) REFERENCES aws_elasticbeanstalk_application (_id) ON DELETE SET NULL,
  _account_id INTEGER,
    FOREIGN KEY (_account_id) REFERENCES aws_organizations_account (_id) ON DELETE SET NULL,
  FOREIGN KEY (provider_account_id) REFERENCES public.provider_account (id) ON DELETE CASCADE,
  FOREIGN KEY (_id) REFERENCES public.resource (id) ON DELETE CASCADE
);

COMMENT ON TABLE aws_elasticbeanstalk_applicationversion IS 'elasticbeanstalk ApplicationVersion resources and their associated attributes.';

ALTER TABLE aws_elasticbeanstalk_applicationversion ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_elasticbeanstalk_applicationversion ON aws_elasticbeanstalk_applicationversion
USING (
  current_user = 'goldfig_ro'
  OR
  provider_account_id = current_setting('gf.provider_account_id', true)::int
);


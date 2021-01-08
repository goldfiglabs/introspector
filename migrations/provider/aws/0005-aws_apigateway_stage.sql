-- migrate:up

CREATE TABLE IF NOT EXISTS aws_apigateway_stage (
  _id INTEGER NOT NULL PRIMARY KEY,
  uri TEXT NOT NULL,
  provider_account_id INTEGER NOT NULL,deploymentid TEXT,
  clientcertificateid TEXT,
  stagename TEXT,
  description TEXT,
  cacheclusterenabled BOOLEAN,
  cacheclustersize TEXT,
  cacheclusterstatus TEXT,
  methodsettings JSONB,
  variables JSONB,
  documentationversion TEXT,
  accesslogsettings JSONB,
  canarysettings JSONB,
  tracingenabled BOOLEAN,
  webaclarn TEXT,
  tags JSONB,
  createddate TIMESTAMP WITH TIME ZONE,
  lastupdateddate TIMESTAMP WITH TIME ZONE,
  _restapi_id INTEGER,
    FOREIGN KEY (_restapi_id) REFERENCES aws_apigateway_restapi (_id) ON DELETE SET NULL,
  _account_id INTEGER,
    FOREIGN KEY (_account_id) REFERENCES aws_organizations_account (_id) ON DELETE SET NULL,
  FOREIGN KEY (provider_account_id) REFERENCES public.provider_account (id) ON DELETE CASCADE,
  FOREIGN KEY (_id) REFERENCES public.resource (id) ON DELETE CASCADE
);

COMMENT ON TABLE aws_apigateway_stage IS 'apigateway Stage resources and their associated attributes.';

ALTER TABLE aws_apigateway_stage ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_apigateway_stage ON aws_apigateway_stage
USING (
  current_user = 'goldfig_ro'
  OR
  provider_account_id = current_setting('gf.provider_account_id', true)::int
);


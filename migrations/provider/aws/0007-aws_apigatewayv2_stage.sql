-- migrate:up

CREATE TABLE IF NOT EXISTS aws_apigatewayv2_stage (
  _id INTEGER NOT NULL PRIMARY KEY,
  uri TEXT NOT NULL,
  provider_account_id INTEGER NOT NULL,accesslogsettings JSONB,
  apigatewaymanaged BOOLEAN,
  autodeploy BOOLEAN,
  clientcertificateid TEXT,
  createddate TIMESTAMP WITH TIME ZONE,
  defaultroutesettings JSONB,
  deploymentid TEXT,
  description TEXT,
  lastdeploymentstatusmessage TEXT,
  lastupdateddate TIMESTAMP WITH TIME ZONE,
  routesettings JSONB,
  stagename TEXT,
  stagevariables JSONB,
  tags JSONB,
  _api_id INTEGER,
    FOREIGN KEY (_api_id) REFERENCES aws_apigatewayv2_api (_id) ON DELETE SET NULL,
  _account_id INTEGER,
    FOREIGN KEY (_account_id) REFERENCES aws_organizations_account (_id) ON DELETE SET NULL,
  FOREIGN KEY (provider_account_id) REFERENCES public.provider_account (id) ON DELETE CASCADE,
  FOREIGN KEY (_id) REFERENCES public.resource (id) ON DELETE CASCADE
);

COMMENT ON TABLE aws_apigatewayv2_stage IS 'apigatewayv2 Stage resources and their associated attributes.';

ALTER TABLE aws_apigatewayv2_stage ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_apigatewayv2_stage ON aws_apigatewayv2_stage
USING (
  current_user = 'goldfig_ro'
  OR
  provider_account_id = current_setting('gf.provider_account_id', true)::int
);


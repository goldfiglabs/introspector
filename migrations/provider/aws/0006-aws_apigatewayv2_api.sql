-- migrate:up

CREATE TABLE IF NOT EXISTS aws_apigatewayv2_api (
  _id INTEGER NOT NULL PRIMARY KEY,
  uri TEXT NOT NULL,
  provider_account_id INTEGER NOT NULL,apiendpoint TEXT,
  apigatewaymanaged BOOLEAN,
  apiid TEXT,
  apikeyselectionexpression TEXT,
  corsconfiguration JSONB,
  createddate TIMESTAMP WITH TIME ZONE,
  description TEXT,
  disableschemavalidation BOOLEAN,
  disableexecuteapiendpoint BOOLEAN,
  importinfo JSONB,
  name TEXT,
  protocoltype TEXT,
  routeselectionexpression TEXT,
  tags JSONB,
  version TEXT,
  warnings JSONB,
  stages JSONB,
  _account_id INTEGER,
    FOREIGN KEY (_account_id) REFERENCES aws_organizations_account (_id) ON DELETE SET NULL,
  FOREIGN KEY (provider_account_id) REFERENCES public.provider_account (id) ON DELETE CASCADE,
  FOREIGN KEY (_id) REFERENCES public.resource (id) ON DELETE CASCADE
);

COMMENT ON TABLE aws_apigatewayv2_api IS 'apigatewayv2 Api resources and their associated attributes.';

ALTER TABLE aws_apigatewayv2_api ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_apigatewayv2_api ON aws_apigatewayv2_api
USING (
  current_user = 'goldfig_ro'
  OR
  provider_account_id = current_setting('gf.provider_account_id', true)::int
);


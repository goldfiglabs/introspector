-- migrate:up

CREATE TABLE IF NOT EXISTS aws_apigateway_restapi (
  _id INTEGER NOT NULL PRIMARY KEY,
  uri TEXT NOT NULL,
  provider_account_id INTEGER NOT NULL,id TEXT,
  name TEXT,
  description TEXT,
  createddate TIMESTAMP WITH TIME ZONE,
  version TEXT,
  warnings JSONB,
  binarymediatypes JSONB,
  minimumcompressionsize INTEGER,
  apikeysource TEXT,
  endpointconfiguration JSONB,
  policy TEXT,
  tags JSONB,
  disableexecuteapiendpoint BOOLEAN,
  stages JSONB,
  _account_id INTEGER,
    FOREIGN KEY (_account_id) REFERENCES aws_organizations_account (_id) ON DELETE SET NULL,
  FOREIGN KEY (provider_account_id) REFERENCES public.provider_account (id) ON DELETE CASCADE,
  FOREIGN KEY (_id) REFERENCES public.resource (id) ON DELETE CASCADE
);

COMMENT ON TABLE aws_apigateway_restapi IS 'apigateway RestApi resources and their associated attributes.';

ALTER TABLE aws_apigateway_restapi ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_apigateway_restapi ON aws_apigateway_restapi
USING (
  current_user = 'goldfig_ro'
  OR
  provider_account_id = current_setting('gf.provider_account_id', true)::int
);


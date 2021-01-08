-- migrate:up
ALTER TABLE resource ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_resource ON resource
USING (
  current_user = 'goldfig_ro'
  OR
  provider_account_id = current_setting('gf.provider_account_id', true)::int
);

ALTER TABLE resource_attribute ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_resource_attribute ON resource_attribute
USING (
  current_user = 'goldfig_ro'
  OR
  provider_account_id = current_setting('gf.provider_account_id', true)::int
);

ALTER TABLE provider_credential ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_provider_credential ON provider_credential
USING (
  current_user = 'goldfig_ro'
  OR
  provider_account_id = current_setting('gf.provider_account_id', true)::int
);

ALTER TABLE import_job ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_import_job ON import_job
USING (
  current_user = 'goldfig_ro'
  OR
  provider_account_id = current_setting('gf.provider_account_id', true)::int
);

ALTER TABLE raw_import ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_raw_import ON raw_import
USING (
  current_user = 'goldfig_ro'
  OR
  provider_account_id = current_setting('gf.provider_account_id', true)::int
);

ALTER TABLE mapped_uri ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_mapped_uri ON mapped_uri
USING (
  current_user = 'goldfig_ro'
  OR
  provider_account_id = current_setting('gf.provider_account_id', true)::int
);

ALTER TABLE resource_relation ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_resource_relation ON resource_relation
USING (
  current_user = 'goldfig_ro'
  OR
  provider_account_id = current_setting('gf.provider_account_id', true)::int
);

ALTER TABLE resource_relation_attribute ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_resource_relation_attribute ON resource_relation_attribute
USING (
  current_user = 'goldfig_ro'
  OR
  provider_account_id = current_setting('gf.provider_account_id', true)::int
);

ALTER TABLE resource_raw ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_resource_raw ON resource_raw
USING (
  current_user = 'goldfig_ro'
  OR
  provider_account_id = current_setting('gf.provider_account_id', true)::int
);

ALTER TABLE resource_delta ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_resource_delta ON resource_delta
USING (
  current_user = 'goldfig_ro'
  OR
  provider_account_id = current_setting('gf.provider_account_id', true)::int
);

ALTER TABLE resource_attribute_delta ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_resource_attribute_delta ON resource_attribute_delta
USING (
  current_user = 'goldfig_ro'
  OR
  provider_account_id = current_setting('gf.provider_account_id', true)::int
);

ALTER TABLE resource_relation_delta ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_resource_relation_delta ON resource_relation_delta
USING (
  current_user = 'goldfig_ro'
  OR
  provider_account_id = current_setting('gf.provider_account_id', true)::int
);

ALTER TABLE resource_relation_attribute_delta ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_resource_relation_attribute_delta ON resource_relation_attribute_delta
USING (
  current_user = 'goldfig_ro'
  OR
  provider_account_id = current_setting('gf.provider_account_id', true)::int
);

-- migrate:down

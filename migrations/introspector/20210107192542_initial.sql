-- migrate:up
-- Define accounts to be imported

CREATE TYPE provider AS ENUM ('aws', 'gcp', 'azure');

CREATE TABLE IF NOT EXISTS public.provider_account (
  id SERIAL PRIMARY KEY,
  name VARCHAR(256),
  provider provider
);

CREATE TABLE IF NOT EXISTS public.provider_credential (
  id SERIAL PRIMARY KEY,
  provider_account_id INTEGER NOT NULL REFERENCES provider_account (id),
  principal_uri VARCHAR(1024) NOT NULL,
  config JSONB,
  scope VARCHAR(128)
);

COMMENT ON TABLE public.provider_credential IS '(Internal) Provider account credentials.';

-- Define an import

CREATE TABLE IF NOT EXISTS public.import_job (
  id SERIAL PRIMARY KEY,
  start_date TIMESTAMP WITH TIME ZONE NOT NULL,
  end_date TIMESTAMP WITH TIME ZONE,
  error_details JSONB,
  path_prefix VARCHAR(256),
  configuration JSONB,
  provider_account_id INTEGER NOT NULL,
  FOREIGN KEY (provider_account_id) REFERENCES provider_account (id)
);

COMMENT ON TABLE public.import_job IS '(Internal) Keeps track of pending import jobs and associated metadata.';

CREATE TABLE IF NOT EXISTS public.raw_import (
  id SERIAL PRIMARY KEY,
  import_job_id INTEGER NOT NULL,
  provider_account_id INTEGER NOT NULL REFERENCES provider_account (id),
  source VARCHAR(256) NOT NULL,
  service VARCHAR(256) NOT NULL,
  path VARCHAR(1024),
  resource_name VARCHAR(256),
  raw JSONB,
  context JSONB,
  phase INTEGER NOT NULL,
  mapped BOOLEAN,
  FOREIGN KEY (import_job_id) REFERENCES import_job (id)
);

COMMENT ON TABLE public.raw_import IS '(Internal) Raw import.';

CREATE TABLE IF NOT EXISTS public.mapped_uri (
  uri TEXT NOT NULL,
  source VARCHAR(256) NOT NULL,
  import_job_id INTEGER NOT NULL,
  provider_account_id INTEGER NOT NULL REFERENCES provider_account (id),
  raw_import_id INTEGER,
  PRIMARY KEY (uri, source, import_job_id),
  FOREIGN KEY (import_job_id) REFERENCES import_job (id),
  FOREIGN KEY (raw_import_id) REFERENCES raw_import (id)
);

COMMENT ON TABLE public.mapped_uri IS '(Internal) Mapped URIs.';

-- Define resources and relations between them

CREATE TYPE resource_type AS ENUM (
  'VMInstance',
  'Disk',
  'StorageBucket',
  'Image',
  'LoadBalancer',
  'Certificate',
  'Endpoint',
  'Principal',
  'Group',
  'Policy',
  'Role',
  'Organization',
  'Division'
);

CREATE TABLE IF NOT EXISTS public.resource (
  id SERIAL PRIMARY KEY,
  path VARCHAR(1024) NOT NULL,
  uri VARCHAR(1024) NOT NULL,
  name VARCHAR(256),
  provider_account_id INTEGER NOT NULL,
  provider_type VARCHAR(1024),
  service VARCHAR(245),
  category resource_type,
  FOREIGN KEY (provider_account_id) REFERENCES provider_account (id),
  UNIQUE (provider_account_id, uri),
  CHECK ((NOT category IS NULL) OR (NOT provider_type IS NULL))
);

CREATE INDEX IF NOT EXISTS service_provider_type_idx ON resource (service, provider_type);

CREATE TABLE IF NOT EXISTS public.resource_raw (
  id SERIAL PRIMARY KEY,
  source VARCHAR(256) NOT NULL,
  resource_id INTEGER NOT NULL,
  provider_account_id INTEGER NOT NULL REFERENCES provider_account (id),
  raw JSONB,
  FOREIGN KEY (resource_id) REFERENCES resource (id)
);

COMMENT ON TABLE public.resource_raw IS 'Holds the JSON representation of a resource from a particular source';

CREATE TABLE IF NOT EXISTS public.resource_attribute (
  id SERIAL PRIMARY KEY,
  resource_id INTEGER NOT NULL,
  provider_account_id INTEGER NOT NULL REFERENCES provider_account (id),
  source VARCHAR(256) NOT NULL,
  type VARCHAR(256) NOT NULL,
  attr_name VARCHAR(256) NOT NULL,
  attr_value JSONB,
  FOREIGN KEY (resource_id) REFERENCES resource (id)
);

COMMENT ON TABLE public.resource_attribute IS 'Attributes of resources.';

CREATE INDEX IF NOT EXISTS case_insensitive_name_idx ON public.resource_attribute USING btree (type, lower((attr_name)::text));

CREATE TABLE IF NOT EXISTS public.resource_relation (
  id SERIAL PRIMARY KEY,
  resource_id INTEGER NOT NULL,
  relation VARCHAR(50) NOT NULL,
  target_id INTEGER NOT NULL,
  raw JSONB,
  provider_account_id INTEGER NOT NULL REFERENCES provider_account (id),
  FOREIGN KEY (resource_id) REFERENCES resource (id),
  FOREIGN KEY (target_id) REFERENCES resource (id),
  UNIQUE(resource_id, relation, target_id)
);

COMMENT ON TABLE public.resource_relation IS 'Relationships between resources.';

CREATE TABLE IF NOT EXISTS public.resource_relation_attribute (
  id SERIAL PRIMARY KEY,
  relation_id INTEGER NOT NULL,
  name VARCHAR(50),
  value JSONB,
  provider_account_id INTEGER NOT NULL REFERENCES provider_account (id)
);

COMMENT ON TABLE public.resource_relation_attribute IS 'Attributes on relationships between resources.';

-- Delta tracking
CREATE TYPE resource_change AS ENUM (
  'add',
  'update',
  'delete'
);

CREATE TABLE IF NOT EXISTS public.resource_delta (
  id SERIAL PRIMARY KEY,
  import_job_id INTEGER NOT NULL,
  provider_account_id INTEGER NOT NULL REFERENCES provider_account (id),
  -- not a foreign key, since the resource may disappear
  resource_id INTEGER NOT NULL,
  change_type resource_change NOT NULL,
  change_details JSONB,
  FOREIGN KEY (import_job_id) REFERENCES import_job (id)
);

COMMENT ON TABLE public.resource_delta IS 'Resource deltas between subseqnet import jobs.';

CREATE TYPE attribute_change AS ENUM (
  'add',
  'update',
  'delete'
);

CREATE TABLE IF NOT EXISTS public.resource_attribute_delta (
  id SERIAL PRIMARY KEY,
  provider_account_id INTEGER NOT NULL REFERENCES provider_account (id),
  resource_delta_id INTEGER NOT NULL,
  -- not a foreign key, since the resource may disappear
  resource_attribute_id INTEGER NOT NULL,
  change_type attribute_change NOT NULL,
  change_details JSONB,
  FOREIGN KEY (resource_delta_id) REFERENCES resource_delta (id)
);

COMMENT ON TABLE public.resource_attribute_delta IS 'Deltas on attributes of resources';

CREATE TYPE resource_relation_change AS ENUM (
  'add',
  'update',
  'delete'
);

CREATE TABLE IF NOT EXISTS public.resource_relation_delta (
  id SERIAL PRIMARY KEY,
  import_job_id INTEGER NOT NULL,
  provider_account_id INTEGER NOT NULL REFERENCES provider_account (id),
  -- not a foreign key, since the relation may disappear
  resource_relation_id INTEGER NOT NULL,
  change_type resource_relation_change NOT NULL,
  change_details JSONB,
  FOREIGN KEY (import_job_id) REFERENCES import_job (id)
);

COMMENT ON TABLE public.resource_relation_delta IS 'Deltas on relationships of resources.';

CREATE TYPE relation_attribute_change AS ENUM (
  'add',
  'update',
  'delete'
);

CREATE TABLE IF NOT EXISTS public.resource_relation_attribute_delta (
  id SERIAL PRIMARY KEY,
  provider_account_id INTEGER NOT NULL REFERENCES provider_account (id),
  resource_relation_delta_id INTEGER NOT NULL,
  resource_relation_attribute_id INTEGER NOT NULL,
  change_type relation_attribute_change NOT NULL,
  change_details JSONB,
  FOREIGN KEY (resource_relation_delta_id) REFERENCES resource_relation_delta (id)
);

COMMENT ON TABLE public.resource_relation_attribute_delta IS 'Delta on attributes on relationships of resources.';


-- migrate:down
-- delta tracking
DROP TABLE public.resource_relation_attribute_delta;
DROP TYPE relation_attribute_change;
DROP TABLE public.resource_relation_delta;
DROP TYPE resource_relation_change;
DROP TABLE resource_attribute_delta;
DROP TYPE attribute_change;
DROP TABLE resource_delta;
DROP TYPE resource_change;

-- Resources
DROP TABLE resource_relation_attribute;
DROP TABLE resource_relation;
DROP TABLE resource_attribute;
DROP TABLE resource_raw;
DROP INDEX service_provider_type_idx;
DROP TABLE resource;
DROP TYPE resource_type;

-- Imports
DROP TABLE mapped_uri;
DROP TABLE raw_import;
DROP TABLE import_job;

-- Accounts
DROP TABLE provider_credential;
DROP TABLE provider_account;
DROP TYPE provider;
-- migrate:up
ALTER TABLE provider_account ADD COLUMN external_id INTEGER;

-- migrate:down
ALTER TABLE provider_account DROP COLUMN external_id;

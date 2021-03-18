-- migrate:up
CREATE EXTENSION IF NOT EXISTS plv8;

-- migrate:down
DROP EXTENSION plv8;

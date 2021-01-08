-- migrate:up
CREATE USER goldfig_ro_scoped WITH ENCRYPTED PASSWORD 'goldfig_ro_scoped';
GRANT SELECT ON ALL TABLES IN SCHEMA public TO goldfig_ro_scoped;
ALTER DEFAULT PRIVILEGES FOR ROLE goldfig IN SCHEMA public GRANT SELECT ON TABLES TO goldfig_ro_scoped;

-- migrate:down
ALTER DEFAULT PRIVILEGES FOR ROLE goldfig IN SCHEMA public REVOKE SELECT ON TABLES FROM goldfig_ro_scoped;
REVOKE SELECT ON ALL TABLES IN SCHEMA public FROM goldfig_ro_scoped;
DROP USER goldfig_ro_scoped;

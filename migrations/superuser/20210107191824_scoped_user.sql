-- migrate:up
CREATE USER introspector_ro_scoped WITH ENCRYPTED PASSWORD 'introspector_ro_scoped';
GRANT SELECT ON ALL TABLES IN SCHEMA public TO introspector_ro_scoped;
ALTER DEFAULT PRIVILEGES FOR ROLE introspector IN SCHEMA public GRANT SELECT ON TABLES TO introspector_ro_scoped;

-- migrate:down
ALTER DEFAULT PRIVILEGES FOR ROLE introspector IN SCHEMA public REVOKE SELECT ON TABLES FROM introspector_ro_scoped;
REVOKE SELECT ON ALL TABLES IN SCHEMA public FROM introspector_ro_scoped;
DROP USER introspector_ro_scoped;

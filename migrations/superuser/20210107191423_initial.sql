-- migrate:up
REVOKE CREATE ON SCHEMA public FROM public;
CREATE USER introspector WITH ENCRYPTED PASSWORD 'introspector';
CREATE USER introspector_ro WITH ENCRYPTED PASSWORD 'introspector_ro';
GRANT ALL PRIVILEGES ON SCHEMA public TO introspector;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO introspector_ro;
ALTER DEFAULT PRIVILEGES FOR ROLE introspector IN SCHEMA public GRANT SELECT ON TABLES TO introspector_ro;

-- migrate:down
ALTER DEFAULT PRIVILEGES FOR ROLE introspector IN SCHEMA public REVOKE SELECT ON TABLES FROM introspector_ro;
REVOKE SELECT ON ALL TABLES IN SCHEMA public FROM introspector_ro;
REVOKE ALL PRIVILEGES ON SCHEMA public FROM introspector;
DROP USER introspector_ro;
DROP USER introspector;
GRANT CREATE ON SCHEMA public TO public;
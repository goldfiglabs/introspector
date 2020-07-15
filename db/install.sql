create database goldfig;
create user goldfig with encrypted password 'goldfig';
create user goldfig_ro with encrypted password 'goldfig_ro';
\c goldfig
revoke create on schema public from public;
grant all privileges on schema public to goldfig;
grant select on all tables in schema public to goldfig_ro;
alter default privileges for role goldfig in schema public grant select on tables to goldfig_ro;

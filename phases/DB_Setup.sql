--CREATING DATABASE
create or replace database HCLS_DB;

--CREATING SCHEMAS
create or replace schema HCLS_DB.RAW_SCHEMA;
create or replace schema HCLS_DB.TRANSFORM_SCHEMA;
create or replace schema HCLS_DB.ANALYTICS_SCHEMA;
create or replace schema HCLS_DB.AI_READY_SCHEMA;

--GRANTING PRIVILEGE TO DATABASE
grant usage on database HCLS_DB to role Ingest_Role;

--GRANTING PIVILEGES TO RAW_SCHEMA
grant usage on schema HCLS_DB.RAW_SCHEMA to role INGEST_ROLE;
grant select on all tables in schema HCLS_DB.RAW_SCHEMA to role INGEST_ROLE;
grant select on future tables in schema HCLS_DB.RAW_SCHEMA to role INGEST_ROLE;

--GRANTING PRIVILEGES ON TRANSFORM_SCHEMA
grant usage on schema HCLS_DB.TRANSFORM_SCHEMA to role TRANSFORM_ROLE;
grant select on all tables in schema HCLS_DB.TRANSFORM_SCHEMA to role TRANSFORM_ROLE;
grant select on future tables in schema HCLS_DB.TRANSFORM_SCHEMA to role TRANSFORM_ROLE;

--GRANTING PRIVILES ON ANALYTICS SCHEMA
grant usage on schema HCLS_DB.ANALYTICS_SCHEMA to role REPORTING_ROLE;
grant select on all tables in schema HCLS_DB.ANALYTICS_SCHEMA to role REPORTING_ROLE;
grant select on future tables in schema HCLS_DB.ANALYTICS_SCHEMA to role REPORTING_ROLE;

--GRANTING PRIVILES TO DATA ENGINEER ROLE
--BRONZE LAYER
grant create table, create view on schema HCLS_DB.RAW_SCHEMA to role DATA_ENG_ROLE;
grant insert, update, delete, truncate on all tables in schema HCLS_DB.RAW_SCHEMA to role DATA_ENG_ROLE;
grant insert, update, delete, truncate on future tables in schema HCLS_DB.RAW_SCHEMA to role DATA_ENG_ROLE;
--SILVER LAYER
grant create table, create view on schema HCLS_DB.TRANSFORM_SCHEMA to role DATA_ENG_ROLE;
grant insert, update, delete, truncate on all tables in schema HCLS_DB.TRANSFORM_SCHEMA to role DATA_ENG_ROLE;
grant insert, update, delete, truncate on future tables in schema HCLS_DB.TRANSFORM_SCHEMA to role DATA_ENG_ROLE;

--GRANTING FULL PRIVILES TO ADMIN ROLE
grant all privileges on schema HCLS_DB.RAW_SCHEMA to role ADMIN_ROLE;
grant all privileges on schema HCLS_DB.TRANSFORM_SCHEMA to role ADMIN_ROLE;
grant all privileges on schema HCLS_DB.ANALYTICS_SCHEMA to role ADMIN_ROLE;
grant all privileges on all tables in schema HCLS_DB.ANALYTICS_SCHEMA to role ADMIN_ROLE;
grant all privileges on future tables in schema HCLS_DB.ANALYTICS_SCHEMA to role ADMIN_ROLE;

show grants to role ADMIN_ROLE;
show grants to role Data_Eng_Role;
show grants to role Analyst_Role;
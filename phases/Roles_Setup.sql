--CREATING ROLES
create or replace role Ingest_Role; --Ingesting Raw Data (BRONZE LAYER)
create or replace role Transform_Role; --Transforming raw data (SILVER LAYER)
create or replace role Analyst_Role; -- Analysing data (GOLD LAYER)
create or replace role AI_Ready_Role; -- AI/ML workloads - embeddings, ML models, semantic models (PLATINUM LAYER)
create or replace role Data_Eng_Role; -- Build ELT pipelines
create or replace role Admin_Role; --Full administrative control

--CREATING ROLE HIERARCHY
grant role Ingest_Role to role Transform_Role;
grant role Transform_Role to role Analyst_Role;
grant role Analyst_Role to role AI_READY_Role;
grant role AI_READY_Role to role Data_Eng_Role;
grant role Data_Eng_Role to role Admin_Role;
grant role Admin_Role to role SYSADMIN;



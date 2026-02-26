-- =============================================================================
-- COMPREHENSIVE VERIFICATION & TEST SUITE FOR HCLS PROJECT
-- =============================================================================
-- This script validates all components created in the HCLS Medallion Architecture
-- =============================================================================

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE COMPUTE_WH;

-- =============================================================================
-- SECTION 1: ROLES SETUP VERIFICATION (Roles_Setup.sql)
-- =============================================================================

-- Test 1.1: Verify all roles exist
SELECT 'TC1.1 - Roles Exist' AS test_name,
    CASE WHEN COUNT(*) = 6 THEN 'PASS' ELSE 'FAIL' END AS result,
    COUNT(*) AS roles_found
FROM SNOWFLAKE.ACCOUNT_USAGE.ROLES
WHERE name IN ('INGEST_ROLE', 'TRANSFORM_ROLE', 'REPORTING_ROLE', 
               'ANALYST_ROLE', 'DATA_ENG_ROLE', 'ADMIN_ROLE')
    AND deleted_on IS NULL;

-- Test 1.2: Verify role hierarchy exists
SELECT 'TC1.2 - Role Hierarchy' AS test_name,
    grantee_name AS child_role,
    name AS parent_role,
    'EXISTS' AS status
FROM SNOWFLAKE.ACCOUNT_USAGE.GRANTS_TO_ROLES
WHERE privilege = 'USAGE' 
    AND granted_on = 'ROLE'
    AND name IN ('TRANSFORM_ROLE', 'REPORTING_ROLE', 'ANALYST_ROLE', 
                 'DATA_ENG_ROLE', 'ADMIN_ROLE', 'SYSADMIN')
    AND grantee_name IN ('INGEST_ROLE', 'TRANSFORM_ROLE', 'REPORTING_ROLE', 
                         'ANALYST_ROLE', 'DATA_ENG_ROLE', 'ADMIN_ROLE')
ORDER BY parent_role;

-- Test 1.3: Verify ADMIN_ROLE is under SYSADMIN
SELECT 'TC1.3 - Admin Under Sysadmin' AS test_name,
    CASE WHEN COUNT(*) > 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM SNOWFLAKE.ACCOUNT_USAGE.GRANTS_TO_ROLES
WHERE privilege = 'USAGE' 
    AND granted_on = 'ROLE'
    AND name = 'SYSADMIN'
    AND grantee_name = 'ADMIN_ROLE';

-- =============================================================================
-- SECTION 2: DATABASE SETUP VERIFICATION (DB_Setup.sql)
-- =============================================================================

-- Test 2.1: Verify HCLS_DB exists
SELECT 'TC2.1 - Database Exists' AS test_name,
    CASE WHEN COUNT(*) = 1 THEN 'PASS' ELSE 'FAIL' END AS result,
    MAX(database_name) AS database_name
FROM SNOWFLAKE.ACCOUNT_USAGE.DATABASES
WHERE database_name = 'HCLS_DB' AND deleted IS NULL;

-- Test 2.2: Verify all schemas exist
SELECT 'TC2.2 - Schemas Exist' AS test_name,
    CASE WHEN COUNT(*) >= 4 THEN 'PASS' ELSE 'FAIL' END AS result,
    COUNT(*) AS schema_count
FROM SNOWFLAKE.ACCOUNT_USAGE.SCHEMATA
WHERE catalog_name = 'HCLS_DB'
    AND schema_name IN ('RAW_SCHEMA', 'TRANSFORM_SCHEMA', 'ANALYTICS_SCHEMA', 'AI_READY_SCHEMA')
    AND deleted IS NULL;

-- Test 2.3: List all schemas in HCLS_DB
SELECT 'TC2.3 - Schema Inventory' AS test_name,
    schema_name,
    created
FROM SNOWFLAKE.ACCOUNT_USAGE.SCHEMATA
WHERE catalog_name = 'HCLS_DB' AND deleted IS NULL
ORDER BY schema_name;

-- =============================================================================
-- SECTION 3: WAREHOUSE SETUP VERIFICATION (WH_Setup.sql)
-- =============================================================================

-- Test 3.1: Verify all warehouses exist (using SHOW command result)
SHOW WAREHOUSES LIKE '%_WH';

-- Test 3.2: Verify warehouse count via metering history
SELECT 'TC3.2 - Warehouses Active' AS test_name,
    CASE WHEN COUNT(DISTINCT warehouse_name) >= 4 THEN 'PASS' ELSE 'CHECK' END AS result,
    COUNT(DISTINCT warehouse_name) AS warehouse_count
FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
WHERE warehouse_name IN ('INGEST_WH', 'TRANSFORM_WH', 'REPORTING_WH', 'ANALYTICS_WH')
    AND start_time >= DATEADD(DAY, -30, CURRENT_TIMESTAMP());

-- Test 3.3: Verify warehouse grants to roles
SELECT 'TC3.3 - Warehouse Grants' AS test_name,
    name AS warehouse_name,
    grantee_name AS role_name,
    privilege
FROM SNOWFLAKE.ACCOUNT_USAGE.GRANTS_TO_ROLES
WHERE granted_on = 'WAREHOUSE'
    AND name IN ('INGEST_WH', 'TRANSFORM_WH', 'REPORTING_WH', 'ANALYTICS_WH')
ORDER BY name, grantee_name;

-- =============================================================================
-- SECTION 4: DATA TABLES VERIFICATION (Data.sql)
-- =============================================================================

-- Test 4.1: Verify all raw tables exist
SELECT 'TC4.1 - Raw Tables Exist' AS test_name,
    CASE WHEN COUNT(*) >= 6 THEN 'PASS' ELSE 'FAIL' END AS result,
    COUNT(*) AS table_count
FROM SNOWFLAKE.ACCOUNT_USAGE.TABLES
WHERE table_catalog = 'HCLS_DB'
    AND table_schema = 'RAW_SCHEMA'
    AND table_name IN ('PATIENTS_RAW', 'PHYSICIANS_RAW', 'FACILITIES_RAW', 
                       'ENCOUNTERS_RAW', 'LAB_RESULTS_RAW', 'MEDICATIONS_RAW')
    AND deleted IS NULL;

-- Test 4.2: Verify table row counts
SELECT 'TC4.2 - Table Row Counts' AS test_name,
    'FACILITIES_RAW' AS table_name, COUNT(*) AS row_count FROM HCLS_DB.RAW_SCHEMA.FACILITIES_RAW
UNION ALL SELECT 'TC4.2', 'PHYSICIANS_RAW', COUNT(*) FROM HCLS_DB.RAW_SCHEMA.PHYSICIANS_RAW
UNION ALL SELECT 'TC4.2', 'PATIENTS_RAW', COUNT(*) FROM HCLS_DB.RAW_SCHEMA.PATIENTS_RAW
UNION ALL SELECT 'TC4.2', 'ENCOUNTERS_RAW', COUNT(*) FROM HCLS_DB.RAW_SCHEMA.ENCOUNTERS_RAW
UNION ALL SELECT 'TC4.2', 'LAB_RESULTS_RAW', COUNT(*) FROM HCLS_DB.RAW_SCHEMA.LAB_RESULTS_RAW
UNION ALL SELECT 'TC4.2', 'MEDICATIONS_RAW', COUNT(*) FROM HCLS_DB.RAW_SCHEMA.MEDICATIONS_RAW
ORDER BY table_name;

-- Test 4.3: Verify no NULL primary keys in PATIENTS_RAW
SELECT 'TC4.3 - Patient ID Not Null' AS test_name,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS result,
    COUNT(*) AS null_count
FROM HCLS_DB.RAW_SCHEMA.PATIENTS_RAW
WHERE patient_id IS NULL;

-- Test 4.4: Verify referential integrity (encounters have valid patients)
SELECT 'TC4.4 - Encounter-Patient Integrity' AS test_name,
    CASE WHEN orphan_count = 0 THEN 'PASS' ELSE 'FAIL' END AS result,
    orphan_count
FROM (
    SELECT COUNT(*) AS orphan_count
    FROM HCLS_DB.RAW_SCHEMA.ENCOUNTERS_RAW e
    LEFT JOIN HCLS_DB.RAW_SCHEMA.PATIENTS_RAW p ON e.patient_id = p.patient_id
    WHERE p.patient_id IS NULL AND e.patient_id IS NOT NULL
);

-- =============================================================================
-- SECTION 5: MONITORING VIEWS VERIFICATION (Monitoring.sql)
-- =============================================================================

-- Test 5.1: Verify monitoring views exist
SELECT 'TC5.1 - Monitoring Views Exist' AS test_name,
    table_name AS view_name,
    'EXISTS' AS status
FROM SNOWFLAKE.ACCOUNT_USAGE.VIEWS
WHERE table_catalog = 'HCLS_DB'
    AND table_schema = 'AI_READY_SCHEMA'
    AND table_name LIKE 'V_%'
    AND deleted IS NULL
ORDER BY table_name;

-- Test 5.2: Count monitoring views
SELECT 'TC5.2 - Monitoring View Count' AS test_name,
    CASE WHEN COUNT(*) >= 10 THEN 'PASS' ELSE 'FAIL' END AS result,
    COUNT(*) AS view_count
FROM SNOWFLAKE.ACCOUNT_USAGE.VIEWS
WHERE table_catalog = 'HCLS_DB'
    AND table_schema = 'AI_READY_SCHEMA'
    AND table_name LIKE 'V_%'
    AND deleted IS NULL;

-- =============================================================================
-- SECTION 6: ALERTS VERIFICATION (Alerts.sql)
-- =============================================================================

-- Test 6.1: List all alerts (using SHOW command)
SHOW ALERTS IN SCHEMA HCLS_DB.AI_READY_SCHEMA;

-- Test 6.2: Check alert execution history
SELECT 'TC6.2 - Alert Execution History' AS test_name,
    name AS alert_name,
    state,
    scheduled_time,
    completed_time
FROM SNOWFLAKE.ACCOUNT_USAGE.ALERT_HISTORY
WHERE database_name = 'HCLS_DB'
    AND scheduled_time >= DATEADD(DAY, -7, CURRENT_TIMESTAMP())
ORDER BY scheduled_time DESC
LIMIT 20;

-- =============================================================================
-- SECTION 7: DATA GOVERNANCE VERIFICATION (Data_Gov.sql)
-- =============================================================================

-- Test 7.1: Verify tags exist
SELECT 'TC7.1 - Tags Exist' AS test_name,
    tag_name,
    'EXISTS' AS status
FROM SNOWFLAKE.ACCOUNT_USAGE.TAGS
WHERE deleted IS NULL
ORDER BY tag_name;

-- Test 7.2: Verify masking policies exist
SELECT 'TC7.2 - Masking Policies' AS test_name,
    policy_name,
    policy_kind,
    'EXISTS' AS status
FROM SNOWFLAKE.ACCOUNT_USAGE.MASKING_POLICIES
WHERE deleted IS NULL
ORDER BY policy_name;

-- Test 7.3: Verify row access policies exist
SELECT 'TC7.3 - Row Access Policies' AS test_name,
    policy_name,
    'EXISTS' AS status
FROM SNOWFLAKE.ACCOUNT_USAGE.ROW_ACCESS_POLICIES
WHERE deleted IS NULL
ORDER BY policy_name;

-- =============================================================================
-- SECTION 8: ACCOUNT ADMIN VERIFICATION (AccAdmin.sql)
-- =============================================================================

-- Test 8.1: Verify network rules exist
SELECT 'TC8.1 - Network Rules' AS test_name,
    name AS rule_name,
    type,
    mode
FROM SNOWFLAKE.ACCOUNT_USAGE.NETWORK_RULES
WHERE deleted IS NULL
ORDER BY name;

-- Test 8.2: Verify network policies exist
SELECT 'TC8.2 - Network Policies' AS test_name,
    name AS policy_name,
    'EXISTS' AS status
FROM SNOWFLAKE.ACCOUNT_USAGE.NETWORK_POLICIES
WHERE deleted IS NULL
ORDER BY name;

-- Test 8.3: Verify password policies exist
SELECT 'TC8.3 - Password Policies' AS test_name,
    name AS policy_name,
    password_min_length,
    password_max_age_days
FROM SNOWFLAKE.ACCOUNT_USAGE.PASSWORD_POLICIES
WHERE deleted IS NULL
ORDER BY name;

-- =============================================================================
-- SECTION 9: AUDIT VIEWS VERIFICATION (Audit.sql)
-- =============================================================================

-- Test 9.1: Verify governance schema exists
SELECT 'TC9.1 - Governance Schema' AS test_name,
    CASE WHEN COUNT(*) = 1 THEN 'PASS' ELSE 'FAIL' END AS result
FROM SNOWFLAKE.ACCOUNT_USAGE.SCHEMATA
WHERE catalog_name = 'HCLS_DB'
    AND schema_name = 'GOVERNANCE_SCHEMA'
    AND deleted IS NULL;

-- Test 9.2: Verify audit views exist
SELECT 'TC9.2 - Audit Views' AS test_name,
    table_name AS view_name,
    'EXISTS' AS status
FROM SNOWFLAKE.ACCOUNT_USAGE.VIEWS
WHERE table_catalog = 'HCLS_DB'
    AND table_schema = 'GOVERNANCE_SCHEMA'
    AND deleted IS NULL
ORDER BY table_name;

-- Test 9.3: Audit views return data
SELECT 'TC9.3 - Login Summary Data' AS test_name,
    CASE WHEN COUNT(*) > 0 THEN 'PASS' ELSE 'NO DATA' END AS result,
    COUNT(*) AS record_count
FROM HCLS_DB.GOVERNANCE_SCHEMA.V_LOGIN_SUMMARY;

SELECT 'TC9.3 - User Inventory Data' AS test_name,
    CASE WHEN COUNT(*) > 0 THEN 'PASS' ELSE 'NO DATA' END AS result,
    COUNT(*) AS record_count
FROM HCLS_DB.GOVERNANCE_SCHEMA.V_USER_INVENTORY;

-- =============================================================================
-- SECTION 10: RESOURCE MONITORS VERIFICATION (WH_Setup.sql)
-- =============================================================================

-- Test 10.1: Verify resource monitors exist
SELECT 'TC10.1 - Resource Monitors' AS test_name,
    name AS monitor_name,
    credit_quota,
    'EXISTS' AS status
FROM SNOWFLAKE.ACCOUNT_USAGE.RESOURCE_MONITORS
ORDER BY name;

-- =============================================================================
-- SECTION 11: DATA QUALITY TESTS
-- =============================================================================

-- Test 11.1: No future birth dates
SELECT 'TC11.1 - No Future Dates' AS test_name,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS result,
    COUNT(*) AS invalid_count
FROM HCLS_DB.RAW_SCHEMA.PATIENTS_RAW
WHERE date_of_birth > CURRENT_DATE();

-- Test 11.2: Valid gender values
SELECT 'TC11.2 - Valid Gender Values' AS test_name,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS result,
    COUNT(*) AS invalid_count
FROM HCLS_DB.RAW_SCHEMA.PATIENTS_RAW
WHERE gender NOT IN ('Male', 'Female', 'Other', 'Unknown') AND gender IS NOT NULL;

-- Test 11.3: Valid email format
SELECT 'TC11.3 - Valid Email Format' AS test_name,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS result,
    COUNT(*) AS invalid_count
FROM HCLS_DB.RAW_SCHEMA.PATIENTS_RAW
WHERE email IS NOT NULL AND email NOT LIKE '%@%.%';

-- =============================================================================
-- SECTION 12: SUMMARY REPORT
-- =============================================================================

SELECT '========== VERIFICATION SUMMARY ==========' AS report;

SELECT 
    'Roles' AS component, 6 AS expected,
    (SELECT COUNT(*) FROM SNOWFLAKE.ACCOUNT_USAGE.ROLES 
     WHERE name IN ('INGEST_ROLE','TRANSFORM_ROLE','REPORTING_ROLE','ANALYST_ROLE','DATA_ENG_ROLE','ADMIN_ROLE') 
     AND deleted_on IS NULL) AS actual
UNION ALL
SELECT 'Warehouses', 4,
    (SELECT COUNT(DISTINCT warehouse_name) FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY 
     WHERE warehouse_name IN ('INGEST_WH','TRANSFORM_WH','REPORTING_WH','ANALYTICS_WH') AND start_time >= DATEADD(DAY, -30, CURRENT_TIMESTAMP()))
UNION ALL
SELECT 'Schemas', 4,
    (SELECT COUNT(*) FROM SNOWFLAKE.ACCOUNT_USAGE.SCHEMATA 
     WHERE catalog_name = 'HCLS_DB' AND schema_name IN ('RAW_SCHEMA','TRANSFORM_SCHEMA','ANALYTICS_SCHEMA','AI_READY_SCHEMA') AND deleted IS NULL)
UNION ALL
SELECT 'Raw Tables', 6,
    (SELECT COUNT(*) FROM SNOWFLAKE.ACCOUNT_USAGE.TABLES 
     WHERE table_catalog = 'HCLS_DB' AND table_schema = 'RAW_SCHEMA' AND deleted IS NULL);

SELECT '========== END OF REPORT ==========' AS report;

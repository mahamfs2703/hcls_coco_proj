-- =============================================================================
-- DATA GOVERNANCE - TAGS, MASKING POLICIES & ROW ACCESS FOR HCLS_DB.RAW_SCHEMA
-- =============================================================================

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE COMPUTE_WH;

-- =============================================================================
-- SECTION 1: CREATE GOVERNANCE SCHEMA FOR POLICIES
-- =============================================================================

CREATE SCHEMA IF NOT EXISTS HCLS_DB.GOVERNANCE_SCHEMA
    COMMENT = 'Schema for data governance objects';

-- =============================================================================
-- SECTION 2: CREATE TAGS
-- =============================================================================

-- Tag: Data Classification
CREATE OR REPLACE TAG HCLS_DB.GOVERNANCE_SCHEMA.DATA_CLASSIFICATION
    COMMENT = 'Data sensitivity classification level (PUBLIC, INTERNAL, CONFIDENTIAL, RESTRICTED)';

-- Tag: PII Indicator
CREATE OR REPLACE TAG HCLS_DB.GOVERNANCE_SCHEMA.PII
    COMMENT = 'Indicates Personally Identifiable Information (TRUE/FALSE)';

-- Tag: PHI Indicator
CREATE OR REPLACE TAG HCLS_DB.GOVERNANCE_SCHEMA.PHI
    COMMENT = 'Indicates Protected Health Information (TRUE/FALSE)';

-- Tag: Data Domain
CREATE OR REPLACE TAG HCLS_DB.GOVERNANCE_SCHEMA.DATA_DOMAIN
    COMMENT = 'Business domain of the data (PATIENT, CLINICAL, PROVIDER, FACILITY, PHARMACY)';

-- Tag: Data Owner
CREATE OR REPLACE TAG HCLS_DB.GOVERNANCE_SCHEMA.DATA_OWNER
    COMMENT = 'Team or individual responsible for the data';

-- =============================================================================
-- SECTION 3: CREATE MASKING POLICIES (3 Policies)
-- =============================================================================

-- Masking Policy 1: SSN Masking
CREATE OR REPLACE MASKING POLICY HCLS_DB.GOVERNANCE_SCHEMA.MASK_SSN
AS (val STRING) RETURNS STRING ->
    CASE
        WHEN CURRENT_ROLE() IN ('ACCOUNTADMIN', 'ADMIN_ROLE') THEN val
        WHEN CURRENT_ROLE() IN ('DATA_ENG_ROLE') THEN CONCAT('***-**-', RIGHT(val, 4))
        ELSE '***-**-****'
    END
COMMENT = 'Masks SSN - full access for admins, last 4 for engineers';

-- Masking Policy 2: Email Masking
CREATE OR REPLACE MASKING POLICY HCLS_DB.GOVERNANCE_SCHEMA.MASK_EMAIL
AS (val STRING) RETURNS STRING ->
    CASE
        WHEN CURRENT_ROLE() IN ('ACCOUNTADMIN', 'ADMIN_ROLE', 'DATA_ENG_ROLE') THEN val
        WHEN CURRENT_ROLE() IN ('ANALYST_ROLE') THEN CONCAT(LEFT(val, 2), '***@', SPLIT_PART(val, '@', 2))
        ELSE '***@***.***'
    END
COMMENT = 'Masks email addresses based on role';

-- Masking Policy 3: Phone Masking
CREATE OR REPLACE MASKING POLICY HCLS_DB.GOVERNANCE_SCHEMA.MASK_PHONE
AS (val STRING) RETURNS STRING ->
    CASE
        WHEN CURRENT_ROLE() IN ('ACCOUNTADMIN', 'ADMIN_ROLE', 'DATA_ENG_ROLE') THEN val
        WHEN CURRENT_ROLE() IN ('ANALYST_ROLE', 'REPORTING_ROLE') THEN CONCAT('***-***-', RIGHT(REPLACE(val, '-', ''), 4))
        ELSE '***-***-****'
    END
COMMENT = 'Masks phone numbers - shows last 4 digits for analysts';

-- =============================================================================
-- SECTION 4: CREATE ROW ACCESS POLICY
-- =============================================================================

-- Row Access Policy: Region-based access for facilities
CREATE OR REPLACE ROW ACCESS POLICY HCLS_DB.GOVERNANCE_SCHEMA.RAP_REGION_ACCESS
AS (region_val VARCHAR) RETURNS BOOLEAN ->
    CASE
        WHEN CURRENT_ROLE() IN ('ACCOUNTADMIN', 'ADMIN_ROLE', 'DATA_ENG_ROLE') THEN TRUE
        WHEN CURRENT_ROLE() = 'ANALYST_ROLE' AND region_val IN ('Northeast', 'West', 'Midwest') THEN TRUE
        WHEN CURRENT_ROLE() = 'REPORTING_ROLE' AND region_val IN ('Northeast', 'West') THEN TRUE
        ELSE FALSE
    END
COMMENT = 'Restricts row access based on region and role';

-- =============================================================================
-- SECTION 5: APPLY TAGS TO TABLES
-- =============================================================================

-- Apply tags to PATIENTS_RAW table
ALTER TABLE HCLS_DB.RAW_SCHEMA.PATIENTS_RAW
    SET TAG HCLS_DB.GOVERNANCE_SCHEMA.DATA_CLASSIFICATION = 'RESTRICTED',
        HCLS_DB.GOVERNANCE_SCHEMA.DATA_DOMAIN = 'PATIENT',
        HCLS_DB.GOVERNANCE_SCHEMA.DATA_OWNER = 'HCLS_DATA_TEAM';

-- Apply tags to PHYSICIANS_RAW table
ALTER TABLE HCLS_DB.RAW_SCHEMA.PHYSICIANS_RAW
    SET TAG HCLS_DB.GOVERNANCE_SCHEMA.DATA_CLASSIFICATION = 'CONFIDENTIAL',
        HCLS_DB.GOVERNANCE_SCHEMA.DATA_DOMAIN = 'PROVIDER',
        HCLS_DB.GOVERNANCE_SCHEMA.DATA_OWNER = 'HCLS_DATA_TEAM';

-- Apply tags to FACILITIES_RAW table
ALTER TABLE HCLS_DB.RAW_SCHEMA.FACILITIES_RAW
    SET TAG HCLS_DB.GOVERNANCE_SCHEMA.DATA_CLASSIFICATION = 'INTERNAL',
        HCLS_DB.GOVERNANCE_SCHEMA.DATA_DOMAIN = 'FACILITY',
        HCLS_DB.GOVERNANCE_SCHEMA.DATA_OWNER = 'HCLS_DATA_TEAM';

-- Apply tags to ENCOUNTERS_RAW table
ALTER TABLE HCLS_DB.RAW_SCHEMA.ENCOUNTERS_RAW
    SET TAG HCLS_DB.GOVERNANCE_SCHEMA.DATA_CLASSIFICATION = 'RESTRICTED',
        HCLS_DB.GOVERNANCE_SCHEMA.DATA_DOMAIN = 'CLINICAL',
        HCLS_DB.GOVERNANCE_SCHEMA.DATA_OWNER = 'HCLS_DATA_TEAM';

-- Apply tags to LAB_RESULTS_RAW table
ALTER TABLE HCLS_DB.RAW_SCHEMA.LAB_RESULTS_RAW
    SET TAG HCLS_DB.GOVERNANCE_SCHEMA.DATA_CLASSIFICATION = 'RESTRICTED',
        HCLS_DB.GOVERNANCE_SCHEMA.DATA_DOMAIN = 'CLINICAL',
        HCLS_DB.GOVERNANCE_SCHEMA.DATA_OWNER = 'HCLS_DATA_TEAM';

-- Apply tags to MEDICATIONS_RAW table
ALTER TABLE HCLS_DB.RAW_SCHEMA.MEDICATIONS_RAW
    SET TAG HCLS_DB.GOVERNANCE_SCHEMA.DATA_CLASSIFICATION = 'RESTRICTED',
        HCLS_DB.GOVERNANCE_SCHEMA.DATA_DOMAIN = 'PHARMACY',
        HCLS_DB.GOVERNANCE_SCHEMA.DATA_OWNER = 'HCLS_DATA_TEAM';

-- =============================================================================
-- SECTION 6: APPLY PII TAGS TO COLUMNS
-- =============================================================================

-- PATIENTS_RAW - PII columns
ALTER TABLE HCLS_DB.RAW_SCHEMA.PATIENTS_RAW MODIFY COLUMN ssn SET TAG HCLS_DB.GOVERNANCE_SCHEMA.PII = 'TRUE';
ALTER TABLE HCLS_DB.RAW_SCHEMA.PATIENTS_RAW MODIFY COLUMN email SET TAG HCLS_DB.GOVERNANCE_SCHEMA.PII = 'TRUE';
ALTER TABLE HCLS_DB.RAW_SCHEMA.PATIENTS_RAW MODIFY COLUMN phone SET TAG HCLS_DB.GOVERNANCE_SCHEMA.PII = 'TRUE';
ALTER TABLE HCLS_DB.RAW_SCHEMA.PATIENTS_RAW MODIFY COLUMN first_name SET TAG HCLS_DB.GOVERNANCE_SCHEMA.PII = 'TRUE';
ALTER TABLE HCLS_DB.RAW_SCHEMA.PATIENTS_RAW MODIFY COLUMN last_name SET TAG HCLS_DB.GOVERNANCE_SCHEMA.PII = 'TRUE';
ALTER TABLE HCLS_DB.RAW_SCHEMA.PATIENTS_RAW MODIFY COLUMN date_of_birth SET TAG HCLS_DB.GOVERNANCE_SCHEMA.PHI = 'TRUE';

-- PHYSICIANS_RAW - PII columns
ALTER TABLE HCLS_DB.RAW_SCHEMA.PHYSICIANS_RAW MODIFY COLUMN email SET TAG HCLS_DB.GOVERNANCE_SCHEMA.PII = 'TRUE';
ALTER TABLE HCLS_DB.RAW_SCHEMA.PHYSICIANS_RAW MODIFY COLUMN phone SET TAG HCLS_DB.GOVERNANCE_SCHEMA.PII = 'TRUE';
ALTER TABLE HCLS_DB.RAW_SCHEMA.PHYSICIANS_RAW MODIFY COLUMN npi_number SET TAG HCLS_DB.GOVERNANCE_SCHEMA.PII = 'TRUE';

-- =============================================================================
-- SECTION 7: APPLY MASKING POLICIES TO COLUMNS
-- =============================================================================

-- Apply SSN masking to PATIENTS_RAW
ALTER TABLE HCLS_DB.RAW_SCHEMA.PATIENTS_RAW 
    MODIFY COLUMN ssn SET MASKING POLICY HCLS_DB.GOVERNANCE_SCHEMA.MASK_SSN;

-- Apply Email masking to PATIENTS_RAW and PHYSICIANS_RAW
ALTER TABLE HCLS_DB.RAW_SCHEMA.PATIENTS_RAW 
    MODIFY COLUMN email SET MASKING POLICY HCLS_DB.GOVERNANCE_SCHEMA.MASK_EMAIL;

ALTER TABLE HCLS_DB.RAW_SCHEMA.PHYSICIANS_RAW 
    MODIFY COLUMN email SET MASKING POLICY HCLS_DB.GOVERNANCE_SCHEMA.MASK_EMAIL;

-- Apply Phone masking to PATIENTS_RAW and PHYSICIANS_RAW
ALTER TABLE HCLS_DB.RAW_SCHEMA.PATIENTS_RAW 
    MODIFY COLUMN phone SET MASKING POLICY HCLS_DB.GOVERNANCE_SCHEMA.MASK_PHONE;

ALTER TABLE HCLS_DB.RAW_SCHEMA.PHYSICIANS_RAW 
    MODIFY COLUMN phone SET MASKING POLICY HCLS_DB.GOVERNANCE_SCHEMA.MASK_PHONE;

-- =============================================================================
-- SECTION 8: APPLY ROW ACCESS POLICY
-- =============================================================================

-- Apply row access policy to FACILITIES_RAW (region-based access)
ALTER TABLE HCLS_DB.RAW_SCHEMA.FACILITIES_RAW
    ADD ROW ACCESS POLICY HCLS_DB.GOVERNANCE_SCHEMA.RAP_REGION_ACCESS ON (region);

-- =============================================================================
-- SECTION 9: VERIFICATION
-- =============================================================================

-- Show all tags
SHOW TAGS IN SCHEMA HCLS_DB.GOVERNANCE_SCHEMA;

-- Show all masking policies
SHOW MASKING POLICIES IN SCHEMA HCLS_DB.GOVERNANCE_SCHEMA;

-- Show row access policies
SHOW ROW ACCESS POLICIES IN SCHEMA HCLS_DB.GOVERNANCE_SCHEMA;

-- View tag references on tables
SELECT * FROM TABLE(HCLS_DB.INFORMATION_SCHEMA.TAG_REFERENCES_ALL_COLUMNS(
    'HCLS_DB.RAW_SCHEMA.PATIENTS_RAW', 'TABLE'));

-- View policy references (using ACCOUNT_USAGE)
SELECT 
    policy_name,
    policy_kind,
    ref_database_name,
    ref_schema_name,
    ref_entity_name,
    ref_column_name
FROM SNOWFLAKE.ACCOUNT_USAGE.POLICY_REFERENCES
WHERE ref_entity_name = 'PATIENTS_RAW'
ORDER BY policy_name;

-- =============================================================================
-- SECTION 10: TEST MASKING POLICIES
-- =============================================================================

-- Test as different roles (uncomment to test)

-- Test as ACCOUNTADMIN (should see all data)
SELECT patient_id, first_name, last_name, ssn, email, phone 
FROM HCLS_DB.RAW_SCHEMA.PATIENTS_RAW LIMIT 5;

-- Test as ANALYST_ROLE (should see partial masking)
USE ROLE ANALYST_ROLE;
SELECT patient_id, first_name, last_name, ssn, email, phone 
FROM HCLS_DB.RAW_SCHEMA.PATIENTS_RAW LIMIT 5;

-- Test as REPORTING_ROLE (should see full masking)
USE ROLE REPORTING_ROLE;
SELECT patient_id, first_name, last_name, ssn, email, phone 
FROM HCLS_DB.RAW_SCHEMA.PATIENTS_RAW LIMIT 5;

-- Test row access policy on FACILITIES_RAW
USE ROLE ANALYST_ROLE;
SELECT * FROM HCLS_DB.RAW_SCHEMA.FACILITIES_RAW; -- Should see Northeast, West, Midwest only

USE ROLE REPORTING_ROLE;
SELECT * FROM HCLS_DB.RAW_SCHEMA.FACILITIES_RAW; -- Should see Northeast, West only

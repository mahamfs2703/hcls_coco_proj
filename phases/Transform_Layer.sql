-- =============================================================================
-- STEP 1: TRANSFORM LAYER - Dimensional Model for Readmission Analysis
-- Business Problem: Hospital Readmission & Clinical Quality Management
-- =============================================================================

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE TRANSFORM_WH;
USE DATABASE HCLS_DB;
USE SCHEMA TRANSFORM_SCHEMA;
CREATE SCHEMA IF NOT EXISTS TRANSFORM_SCHEMA;

-- =============================================================================
-- DIMENSION TABLES
-- =============================================================================

-- DIM_DATE: Date dimension for time-based analysis
CREATE OR REPLACE TABLE HCLS_DB.TRANSFORM_SCHEMA.DIM_DATE AS
WITH date_spine AS (
    SELECT DATEADD(DAY, SEQ4(), '2020-01-01')::DATE AS date_value
    FROM TABLE(GENERATOR(ROWCOUNT => 3650))
)
SELECT
    date_value AS date_key,
    date_value AS full_date,
    YEAR(date_value) AS year,
    QUARTER(date_value) AS quarter,
    MONTH(date_value) AS month,
    MONTHNAME(date_value) AS month_name,
    WEEK(date_value) AS week_of_year,
    DAYOFWEEK(date_value) AS day_of_week,
    DAYNAME(date_value) AS day_name,
    CASE WHEN DAYOFWEEK(date_value) IN (0, 6) THEN TRUE ELSE FALSE END AS is_weekend,
    YEAR(date_value) || '-Q' || QUARTER(date_value) AS year_quarter,
    YEAR(date_value) || '-' || LPAD(MONTH(date_value), 2, '0') AS year_month
FROM date_spine;


-- DIM_FACILITIES: Clean facility dimension
CREATE OR REPLACE TABLE HCLS_DB.TRANSFORM_SCHEMA.DIM_FACILITIES AS
SELECT
    facility_id AS facility_key,
    facility_id,
    facility_name,
    facility_type,
    address,
    city,
    state,
    zip_code,
    phone,
    bed_count,
    region,
    CASE 
        WHEN bed_count >= 400 THEN 'Large'
        WHEN bed_count >= 200 THEN 'Medium'
        ELSE 'Small'
    END AS facility_size,
    TRUE AS is_current,
    load_timestamp AS effective_date
FROM HCLS_DB.RAW_SCHEMA.FACILITIES_RAW;


-- DIM_PHYSICIANS: Clean physician dimension
CREATE OR REPLACE TABLE HCLS_DB.TRANSFORM_SCHEMA.DIM_PHYSICIANS AS
SELECT
    physician_id AS physician_key,
    physician_id,
    first_name,
    last_name,
    first_name || ' ' || last_name AS full_name,
    specialty,
    npi_number,
    email,
    phone,
    department,
    facility_id,
    hire_date,
    status,
    DATEDIFF('year', hire_date, CURRENT_DATE()) AS years_of_experience,
    CASE 
        WHEN DATEDIFF('year', hire_date, CURRENT_DATE()) >= 10 THEN 'Senior'
        WHEN DATEDIFF('year', hire_date, CURRENT_DATE()) >= 5 THEN 'Mid-Level'
        ELSE 'Junior'
    END AS experience_level,
    TRUE AS is_current,
    load_timestamp AS effective_date
FROM HCLS_DB.RAW_SCHEMA.PHYSICIANS_RAW;


-- DIM_PATIENTS: Clean patient dimension (PII masked for analytics)
CREATE OR REPLACE TABLE HCLS_DB.TRANSFORM_SCHEMA.DIM_PATIENTS AS
SELECT
    patient_id AS patient_key,
    patient_id,
    LEFT(first_name, 1) || '***' AS first_name_masked,
    LEFT(last_name, 1) || '***' AS last_name_masked,
    date_of_birth,
    DATEDIFF('year', date_of_birth, CURRENT_DATE()) AS age,
    CASE 
        WHEN DATEDIFF('year', date_of_birth, CURRENT_DATE()) < 18 THEN 'Pediatric'
        WHEN DATEDIFF('year', date_of_birth, CURRENT_DATE()) BETWEEN 18 AND 40 THEN 'Young Adult'
        WHEN DATEDIFF('year', date_of_birth, CURRENT_DATE()) BETWEEN 41 AND 65 THEN 'Middle Age'
        ELSE 'Senior'
    END AS age_group,
    gender,
    city,
    state,
    zip_code,
    country,
    insurance_id IS NOT NULL AS has_insurance,
    CASE 
        WHEN insurance_id IS NOT NULL THEN 'Insured'
        ELSE 'Uninsured'
    END AS insurance_status,
    primary_physician_id,
    registration_date,
    TRUE AS is_current,
    load_timestamp AS effective_date
FROM HCLS_DB.RAW_SCHEMA.PATIENTS_RAW;


-- DIM_DIAGNOSIS: Diagnosis dimension extracted from encounters
CREATE OR REPLACE TABLE HCLS_DB.TRANSFORM_SCHEMA.DIM_DIAGNOSIS AS
SELECT DISTINCT
    diagnosis_code AS diagnosis_key,
    diagnosis_code,
    diagnosis_description,
    LEFT(diagnosis_code, 1) AS diagnosis_category,
    CASE LEFT(diagnosis_code, 1)
        WHEN 'A' THEN 'Infectious Diseases'
        WHEN 'C' THEN 'Neoplasms'
        WHEN 'E' THEN 'Endocrine/Metabolic'
        WHEN 'F' THEN 'Mental Disorders'
        WHEN 'G' THEN 'Nervous System'
        WHEN 'I' THEN 'Circulatory System'
        WHEN 'J' THEN 'Respiratory System'
        WHEN 'K' THEN 'Digestive System'
        WHEN 'M' THEN 'Musculoskeletal'
        WHEN 'N' THEN 'Genitourinary'
        WHEN 'R' THEN 'Symptoms/Signs'
        WHEN 'S' THEN 'Injury/Trauma'
        ELSE 'Other'
    END AS diagnosis_category_name
FROM HCLS_DB.RAW_SCHEMA.ENCOUNTERS_RAW
WHERE diagnosis_code IS NOT NULL;


-- =============================================================================
-- FACT TABLES
-- =============================================================================

-- FACT_ENCOUNTERS: Core encounter facts with readmission flag
CREATE OR REPLACE TABLE HCLS_DB.TRANSFORM_SCHEMA.FACT_ENCOUNTERS AS
WITH encounter_sequence AS (
    SELECT 
        encounter_id,
        patient_id,
        physician_id,
        facility_id,
        encounter_type,
        admission_date,
        discharge_date,
        chief_complaint,
        diagnosis_code,
        department,
        LAG(discharge_date) OVER (PARTITION BY patient_id ORDER BY admission_date) AS prev_discharge_date,
        LAG(encounter_id) OVER (PARTITION BY patient_id ORDER BY admission_date) AS prev_encounter_id
    FROM HCLS_DB.RAW_SCHEMA.ENCOUNTERS_RAW
)
SELECT
    e.encounter_id AS encounter_key,
    e.encounter_id,
    e.patient_id,
    e.physician_id,
    e.facility_id,
    e.diagnosis_code,
    e.admission_date::DATE AS admission_date_key,
    e.discharge_date::DATE AS discharge_date_key,
    e.encounter_type,
    e.chief_complaint,
    e.department,
    e.admission_date,
    e.discharge_date,
    DATEDIFF('day', e.admission_date, COALESCE(e.discharge_date, e.admission_date)) AS length_of_stay_days,
    DATEDIFF('hour', e.admission_date, COALESCE(e.discharge_date, e.admission_date)) AS length_of_stay_hours,
    e.prev_encounter_id,
    e.prev_discharge_date,
    DATEDIFF('day', e.prev_discharge_date, e.admission_date) AS days_since_last_discharge,
    CASE 
        WHEN e.prev_discharge_date IS NOT NULL 
             AND DATEDIFF('day', e.prev_discharge_date, e.admission_date) <= 30 
        THEN TRUE 
        ELSE FALSE 
    END AS is_30_day_readmission,
    CASE 
        WHEN e.prev_discharge_date IS NOT NULL 
             AND DATEDIFF('day', e.prev_discharge_date, e.admission_date) <= 7 
        THEN TRUE 
        ELSE FALSE 
    END AS is_7_day_readmission,
    CASE e.encounter_type
        WHEN 'Emergency' THEN 3
        WHEN 'Inpatient' THEN 2
        WHEN 'Outpatient' THEN 1
        ELSE 0
    END AS encounter_severity_score
FROM encounter_sequence e;


-- FACT_LAB_RESULTS: Lab results with outcome indicators
CREATE OR REPLACE TABLE HCLS_DB.TRANSFORM_SCHEMA.FACT_LAB_RESULTS AS
SELECT
    result_id AS lab_result_key,
    result_id,
    patient_id,
    encounter_id,
    test_code,
    test_name,
    result_value,
    result_unit,
    reference_range_low,
    reference_range_high,
    abnormal_flag,
    abnormal_flag = 'Y' AS is_abnormal,
    collection_date::DATE AS collection_date_key,
    result_date::DATE AS result_date_key,
    collection_date,
    result_date,
    performing_lab,
    DATEDIFF('hour', collection_date, result_date) AS turnaround_hours,
    CASE 
        WHEN abnormal_flag = 'Y' AND result_value > reference_range_high THEN 'High'
        WHEN abnormal_flag = 'Y' AND result_value < reference_range_low THEN 'Low'
        WHEN abnormal_flag = 'Y' THEN 'Abnormal'
        ELSE 'Normal'
    END AS result_status,
    CASE 
        WHEN abnormal_flag = 'Y' AND (result_value > reference_range_high * 1.5 OR result_value < reference_range_low * 0.5) 
        THEN TRUE 
        ELSE FALSE 
    END AS is_critical
FROM HCLS_DB.RAW_SCHEMA.LAB_RESULTS_RAW;


-- FACT_MEDICATIONS: Medication prescriptions with adherence indicators
CREATE OR REPLACE TABLE HCLS_DB.TRANSFORM_SCHEMA.FACT_MEDICATIONS AS
SELECT
    prescription_id AS medication_key,
    prescription_id,
    patient_id,
    encounter_id,
    medication_code,
    medication_name,
    dosage,
    frequency,
    route,
    prescribing_physician_id,
    start_date AS start_date_key,
    end_date AS end_date_key,
    start_date,
    end_date,
    refills_remaining,
    pharmacy_id,
    DATEDIFF('day', start_date, COALESCE(end_date, CURRENT_DATE())) AS prescription_duration_days,
    CASE 
        WHEN end_date IS NULL OR end_date >= CURRENT_DATE() THEN TRUE 
        ELSE FALSE 
    END AS is_active,
    CASE frequency
        WHEN 'Once daily' THEN 1
        WHEN 'Twice daily' THEN 2
        WHEN 'Three times daily' THEN 3
        WHEN 'Four times daily' THEN 4
        WHEN 'Every 4 hours' THEN 6
        WHEN 'Every 6 hours' THEN 4
        WHEN 'Every 8 hours' THEN 3
        WHEN 'As needed' THEN 0
        ELSE 1
    END AS daily_doses
FROM HCLS_DB.RAW_SCHEMA.MEDICATIONS_RAW;


-- =============================================================================
-- VERIFICATION
-- =============================================================================

SELECT 'DIM_DATE' AS table_name, COUNT(*) AS row_count FROM HCLS_DB.TRANSFORM_SCHEMA.DIM_DATE
UNION ALL SELECT 'DIM_FACILITIES', COUNT(*) FROM HCLS_DB.TRANSFORM_SCHEMA.DIM_FACILITIES
UNION ALL SELECT 'DIM_PHYSICIANS', COUNT(*) FROM HCLS_DB.TRANSFORM_SCHEMA.DIM_PHYSICIANS
UNION ALL SELECT 'DIM_PATIENTS', COUNT(*) FROM HCLS_DB.TRANSFORM_SCHEMA.DIM_PATIENTS
UNION ALL SELECT 'DIM_DIAGNOSIS', COUNT(*) FROM HCLS_DB.TRANSFORM_SCHEMA.DIM_DIAGNOSIS
UNION ALL SELECT 'FACT_ENCOUNTERS', COUNT(*) FROM HCLS_DB.TRANSFORM_SCHEMA.FACT_ENCOUNTERS
UNION ALL SELECT 'FACT_LAB_RESULTS', COUNT(*) FROM HCLS_DB.TRANSFORM_SCHEMA.FACT_LAB_RESULTS
UNION ALL SELECT 'FACT_MEDICATIONS', COUNT(*) FROM HCLS_DB.TRANSFORM_SCHEMA.FACT_MEDICATIONS
ORDER BY table_name;

-- Verify readmission calculation
SELECT 
    is_30_day_readmission,
    COUNT(*) AS encounter_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percentage
FROM HCLS_DB.TRANSFORM_SCHEMA.FACT_ENCOUNTERS
GROUP BY is_30_day_readmission;

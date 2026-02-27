-- =============================================================================
-- STEP 2: ANALYTICS LAYER - Business KPIs for Readmission & Quality Management
-- Business Problem: Hospital Readmission & Clinical Quality Management
-- =============================================================================

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE ANALYTICS_WH;
USE DATABASE HCLS_DB;
USE SCHEMA ANALYTICS_SCHEMA;
CREATE SCHEMA IF NOT EXISTS ANALYTICS_SCHEMA;

-- =============================================================================
-- 1. READMISSION METRICS - Core KPIs for readmission analysis
-- =============================================================================

CREATE OR REPLACE TABLE HCLS_DB.ANALYTICS_SCHEMA.READMISSION_METRICS AS
SELECT
    d.year_month,
    d.year,
    d.month,
    fac.facility_id,
    fac.facility_name,
    fac.region,
    fac.facility_type,
    COUNT(*) AS total_encounters,
    SUM(CASE WHEN fe.encounter_type = 'Inpatient' THEN 1 ELSE 0 END) AS inpatient_encounters,
    SUM(CASE WHEN fe.is_30_day_readmission THEN 1 ELSE 0 END) AS readmissions_30_day,
    SUM(CASE WHEN fe.is_7_day_readmission THEN 1 ELSE 0 END) AS readmissions_7_day,
    ROUND(
        SUM(CASE WHEN fe.is_30_day_readmission THEN 1 ELSE 0 END) * 100.0 / 
        NULLIF(COUNT(*), 0), 2
    ) AS readmission_rate_30_day,
    ROUND(
        SUM(CASE WHEN fe.is_7_day_readmission THEN 1 ELSE 0 END) * 100.0 / 
        NULLIF(COUNT(*), 0), 2
    ) AS readmission_rate_7_day,
    AVG(fe.length_of_stay_days) AS avg_length_of_stay,
    SUM(CASE WHEN fe.encounter_type = 'Emergency' THEN 1 ELSE 0 END) AS emergency_encounters,
    COUNT(DISTINCT fe.patient_id) AS unique_patients
FROM HCLS_DB.TRANSFORM_SCHEMA.FACT_ENCOUNTERS fe
JOIN HCLS_DB.TRANSFORM_SCHEMA.DIM_DATE d ON fe.admission_date_key = d.date_key
JOIN HCLS_DB.TRANSFORM_SCHEMA.DIM_FACILITIES fac ON fe.facility_id = fac.facility_id
--CROSS JOIN (SELECT DISTINCT facility_id FROM HCLS_DB.TRANSFORM_SCHEMA.DIM_FACILITIES) f
--WHERE fe.facility_id = f.facility_id
GROUP BY d.year_month, d.year, d.month, fac.facility_id, fac.facility_name, fac.region, fac.facility_type;


-- =============================================================================
-- 2. FACILITY SCORECARD - Comprehensive facility performance
-- =============================================================================

CREATE OR REPLACE TABLE HCLS_DB.ANALYTICS_SCHEMA.FACILITY_SCORECARD AS
WITH encounter_metrics AS (
    SELECT
        fe.facility_id,
        COUNT(*) AS total_encounters,
        COUNT(DISTINCT fe.patient_id) AS unique_patients,
        SUM(CASE WHEN fe.is_30_day_readmission THEN 1 ELSE 0 END) AS readmissions,
        AVG(fe.length_of_stay_days) AS avg_los,
        SUM(CASE WHEN fe.encounter_type = 'Emergency' THEN 1 ELSE 0 END) AS emergency_count,
        AVG(fe.encounter_severity_score) AS avg_severity
    FROM HCLS_DB.TRANSFORM_SCHEMA.FACT_ENCOUNTERS fe
    GROUP BY fe.facility_id
),
lab_metrics AS (
    SELECT
        fe.facility_id,
        COUNT(*) AS total_lab_tests,
        SUM(CASE WHEN fl.is_abnormal THEN 1 ELSE 0 END) AS abnormal_results,
        SUM(CASE WHEN fl.is_critical THEN 1 ELSE 0 END) AS critical_results,
        AVG(fl.turnaround_hours) AS avg_lab_turnaround_hours
    FROM HCLS_DB.TRANSFORM_SCHEMA.FACT_LAB_RESULTS fl
    JOIN HCLS_DB.TRANSFORM_SCHEMA.FACT_ENCOUNTERS fe ON fl.encounter_id = fe.encounter_id
    GROUP BY fe.facility_id
),
physician_metrics AS (
    SELECT
        facility_id,
        COUNT(*) AS physician_count,
        AVG(years_of_experience) AS avg_physician_experience
    FROM HCLS_DB.TRANSFORM_SCHEMA.DIM_PHYSICIANS
    WHERE status = 'Active'
    GROUP BY facility_id
)
SELECT
    f.facility_id,
    f.facility_name,
    f.facility_type,
    f.region,
    f.bed_count,
    f.facility_size,
    COALESCE(em.total_encounters, 0) AS total_encounters,
    COALESCE(em.unique_patients, 0) AS unique_patients,
    COALESCE(em.readmissions, 0) AS total_readmissions,
    ROUND(COALESCE(em.readmissions, 0) * 100.0 / NULLIF(em.total_encounters, 0), 2) AS readmission_rate_pct,
    ROUND(COALESCE(em.avg_los, 0), 2) AS avg_length_of_stay_days,
    COALESCE(em.emergency_count, 0) AS emergency_encounters,
    ROUND(COALESCE(em.avg_severity, 0), 2) AS avg_encounter_severity,
    COALESCE(lm.total_lab_tests, 0) AS total_lab_tests,
    ROUND(COALESCE(lm.abnormal_results, 0) * 100.0 / NULLIF(lm.total_lab_tests, 0), 2) AS abnormal_lab_rate_pct,
    COALESCE(lm.critical_results, 0) AS critical_lab_results,
    ROUND(COALESCE(lm.avg_lab_turnaround_hours, 0), 1) AS avg_lab_turnaround_hours,
    COALESCE(pm.physician_count, 0) AS active_physicians,
    ROUND(COALESCE(pm.avg_physician_experience, 0), 1) AS avg_physician_experience_years,
    ROUND(COALESCE(em.unique_patients, 0) * 1.0 / NULLIF(f.bed_count, 0), 2) AS patients_per_bed,
    CASE 
        WHEN COALESCE(em.readmissions, 0) * 100.0 / NULLIF(em.total_encounters, 0) > 15 THEN 'High Risk'
        WHEN COALESCE(em.readmissions, 0) * 100.0 / NULLIF(em.total_encounters, 0) > 10 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS readmission_risk_tier,
    CASE 
        WHEN COALESCE(em.readmissions, 0) * 100.0 / NULLIF(em.total_encounters, 0) <= 10 
             AND COALESCE(lm.abnormal_results, 0) * 100.0 / NULLIF(lm.total_lab_tests, 0) <= 20 
        THEN 'A'
        WHEN COALESCE(em.readmissions, 0) * 100.0 / NULLIF(em.total_encounters, 0) <= 15 
        THEN 'B'
        ELSE 'C'
    END AS quality_grade,
    CURRENT_TIMESTAMP() AS last_updated
FROM HCLS_DB.TRANSFORM_SCHEMA.DIM_FACILITIES f
LEFT JOIN encounter_metrics em ON f.facility_id = em.facility_id
LEFT JOIN lab_metrics lm ON f.facility_id = lm.facility_id
LEFT JOIN physician_metrics pm ON f.facility_id = pm.facility_id;


-- =============================================================================
-- 3. PHYSICIAN QUALITY METRICS - Individual physician performance
-- =============================================================================

CREATE OR REPLACE TABLE HCLS_DB.ANALYTICS_SCHEMA.PHYSICIAN_QUALITY AS
WITH physician_encounters AS (
    SELECT
        fe.physician_id,
        COUNT(*) AS total_encounters,
        COUNT(DISTINCT fe.patient_id) AS unique_patients,
        SUM(CASE WHEN fe.is_30_day_readmission THEN 1 ELSE 0 END) AS patient_readmissions,
        AVG(fe.length_of_stay_days) AS avg_los,
        SUM(CASE WHEN fe.encounter_type = 'Emergency' THEN 1 ELSE 0 END) AS emergency_encounters
    FROM HCLS_DB.TRANSFORM_SCHEMA.FACT_ENCOUNTERS fe
    GROUP BY fe.physician_id
),
physician_labs AS (
    SELECT
        fe.physician_id,
        COUNT(*) AS lab_tests_ordered,
        SUM(CASE WHEN fl.is_abnormal THEN 1 ELSE 0 END) AS abnormal_results,
        SUM(CASE WHEN fl.is_critical THEN 1 ELSE 0 END) AS critical_results
    FROM HCLS_DB.TRANSFORM_SCHEMA.FACT_LAB_RESULTS fl
    JOIN HCLS_DB.TRANSFORM_SCHEMA.FACT_ENCOUNTERS fe ON fl.encounter_id = fe.encounter_id
    GROUP BY fe.physician_id
),
physician_meds AS (
    SELECT
        prescribing_physician_id AS physician_id,
        COUNT(*) AS prescriptions_written,
        COUNT(DISTINCT medication_code) AS unique_medications,
        AVG(prescription_duration_days) AS avg_prescription_duration
    FROM HCLS_DB.TRANSFORM_SCHEMA.FACT_MEDICATIONS
    GROUP BY prescribing_physician_id
)
SELECT
    p.physician_id,
    p.full_name AS physician_name,
    p.specialty,
    p.department,
    p.facility_id,
    f.facility_name,
    p.experience_level,
    p.years_of_experience,
    COALESCE(pe.total_encounters, 0) AS total_encounters,
    COALESCE(pe.unique_patients, 0) AS unique_patients,
    COALESCE(pe.patient_readmissions, 0) AS patient_readmissions,
    ROUND(COALESCE(pe.patient_readmissions, 0) * 100.0 / NULLIF(pe.total_encounters, 0), 2) AS readmission_rate_pct,
    ROUND(COALESCE(pe.avg_los, 0), 2) AS avg_length_of_stay_days,
    COALESCE(pe.emergency_encounters, 0) AS emergency_encounters,
    COALESCE(pl.lab_tests_ordered, 0) AS lab_tests_ordered,
    ROUND(COALESCE(pl.abnormal_results, 0) * 100.0 / NULLIF(pl.lab_tests_ordered, 0), 2) AS abnormal_lab_rate_pct,
    COALESCE(pm.prescriptions_written, 0) AS prescriptions_written,
    COALESCE(pm.unique_medications, 0) AS unique_medications_prescribed,
    ROUND(COALESCE(pe.unique_patients, 0) * 1.0 / NULLIF(pe.total_encounters, 0), 2) AS patient_continuity_ratio,
    CASE 
        WHEN COALESCE(pe.patient_readmissions, 0) * 100.0 / NULLIF(pe.total_encounters, 0) <= 10 THEN 'Excellent'
        WHEN COALESCE(pe.patient_readmissions, 0) * 100.0 / NULLIF(pe.total_encounters, 0) <= 15 THEN 'Good'
        WHEN COALESCE(pe.patient_readmissions, 0) * 100.0 / NULLIF(pe.total_encounters, 0) <= 20 THEN 'Fair'
        ELSE 'Needs Improvement'
    END AS performance_rating,
    CURRENT_TIMESTAMP() AS last_updated
FROM HCLS_DB.TRANSFORM_SCHEMA.DIM_PHYSICIANS p
LEFT JOIN HCLS_DB.TRANSFORM_SCHEMA.DIM_FACILITIES f ON p.facility_id = f.facility_id
LEFT JOIN physician_encounters pe ON p.physician_id = pe.physician_id
LEFT JOIN physician_labs pl ON p.physician_id = pl.physician_id
LEFT JOIN physician_meds pm ON p.physician_id = pm.physician_id;


-- =============================================================================
-- 4. DIAGNOSIS ANALYSIS - Readmission patterns by diagnosis
-- =============================================================================

CREATE OR REPLACE TABLE HCLS_DB.ANALYTICS_SCHEMA.DIAGNOSIS_ANALYSIS AS
SELECT
    diag.diagnosis_code,
    diag.diagnosis_description,
    diag.diagnosis_category_name,
    COUNT(*) AS total_encounters,
    COUNT(DISTINCT fe.patient_id) AS unique_patients,
    SUM(CASE WHEN fe.is_30_day_readmission THEN 1 ELSE 0 END) AS readmissions_30_day,
    SUM(CASE WHEN fe.is_7_day_readmission THEN 1 ELSE 0 END) AS readmissions_7_day,
    ROUND(
        SUM(CASE WHEN fe.is_30_day_readmission THEN 1 ELSE 0 END) * 100.0 / 
        NULLIF(COUNT(*), 0), 2
    ) AS readmission_rate_pct,
    AVG(fe.length_of_stay_days) AS avg_length_of_stay,
    SUM(CASE WHEN fe.encounter_type = 'Emergency' THEN 1 ELSE 0 END) AS emergency_encounters,
    SUM(CASE WHEN fe.encounter_type = 'Inpatient' THEN 1 ELSE 0 END) AS inpatient_encounters,
    RANK() OVER (ORDER BY SUM(CASE WHEN fe.is_30_day_readmission THEN 1 ELSE 0 END) DESC) AS readmission_rank,
    CASE 
        WHEN SUM(CASE WHEN fe.is_30_day_readmission THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(*), 0) > 20 
        THEN 'High Risk Diagnosis'
        WHEN SUM(CASE WHEN fe.is_30_day_readmission THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(*), 0) > 10 
        THEN 'Medium Risk Diagnosis'
        ELSE 'Low Risk Diagnosis'
    END AS risk_classification,
    CURRENT_TIMESTAMP() AS last_updated
FROM HCLS_DB.TRANSFORM_SCHEMA.FACT_ENCOUNTERS fe
JOIN HCLS_DB.TRANSFORM_SCHEMA.DIM_DIAGNOSIS diag ON fe.diagnosis_code = diag.diagnosis_code
GROUP BY diag.diagnosis_code, diag.diagnosis_description, diag.diagnosis_category_name;


-- =============================================================================
-- 5. PATIENT RISK SUMMARY - For care management teams
-- =============================================================================

CREATE OR REPLACE TABLE HCLS_DB.ANALYTICS_SCHEMA.PATIENT_RISK_SUMMARY AS
WITH patient_encounters AS (
    SELECT
        patient_id,
        COUNT(*) AS total_encounters,
        SUM(CASE WHEN is_30_day_readmission THEN 1 ELSE 0 END) AS readmission_count,
        SUM(CASE WHEN encounter_type = 'Emergency' THEN 1 ELSE 0 END) AS emergency_visits,
        AVG(length_of_stay_days) AS avg_los,
        MAX(admission_date) AS last_visit_date,
        COUNT(DISTINCT diagnosis_code) AS unique_diagnoses
    FROM HCLS_DB.TRANSFORM_SCHEMA.FACT_ENCOUNTERS
    GROUP BY patient_id
),
patient_labs AS (
    SELECT
        patient_id,
        COUNT(*) AS total_lab_tests,
        SUM(CASE WHEN is_abnormal THEN 1 ELSE 0 END) AS abnormal_labs,
        SUM(CASE WHEN is_critical THEN 1 ELSE 0 END) AS critical_labs
    FROM HCLS_DB.TRANSFORM_SCHEMA.FACT_LAB_RESULTS
    GROUP BY patient_id
),
patient_meds AS (
    SELECT
        patient_id,
        COUNT(*) AS total_prescriptions,
        COUNT(DISTINCT medication_code) AS unique_medications,
        SUM(CASE WHEN is_active THEN 1 ELSE 0 END) AS active_medications
    FROM HCLS_DB.TRANSFORM_SCHEMA.FACT_MEDICATIONS
    GROUP BY patient_id
)
SELECT
    p.patient_id,
    p.age,
    p.age_group,
    p.gender,
    p.state,
    p.insurance_status,
    COALESCE(pe.total_encounters, 0) AS total_encounters,
    COALESCE(pe.readmission_count, 0) AS readmission_count,
    COALESCE(pe.emergency_visits, 0) AS emergency_visits,
    ROUND(COALESCE(pe.avg_los, 0), 2) AS avg_length_of_stay,
    pe.last_visit_date,
    DATEDIFF('day', pe.last_visit_date, CURRENT_DATE()) AS days_since_last_visit,
    COALESCE(pe.unique_diagnoses, 0) AS unique_diagnoses,
    COALESCE(pl.total_lab_tests, 0) AS total_lab_tests,
    COALESCE(pl.abnormal_labs, 0) AS abnormal_lab_count,
    COALESCE(pl.critical_labs, 0) AS critical_lab_count,
    ROUND(COALESCE(pl.abnormal_labs, 0) * 100.0 / NULLIF(pl.total_lab_tests, 0), 2) AS abnormal_lab_rate_pct,
    COALESCE(pm.total_prescriptions, 0) AS total_prescriptions,
    COALESCE(pm.active_medications, 0) AS active_medications,
    -- Risk Score Calculation (0-100)
    LEAST(100, 
        COALESCE(pe.readmission_count, 0) * 15 +
        COALESCE(pe.emergency_visits, 0) * 10 +
        COALESCE(pl.critical_labs, 0) * 20 +
        CASE WHEN p.age >= 65 THEN 15 ELSE 0 END +
        CASE WHEN p.insurance_status = 'Uninsured' THEN 10 ELSE 0 END +
        CASE WHEN COALESCE(pm.active_medications, 0) >= 5 THEN 10 ELSE 0 END
    ) AS risk_score,
    CASE 
        WHEN LEAST(100, 
            COALESCE(pe.readmission_count, 0) * 15 +
            COALESCE(pe.emergency_visits, 0) * 10 +
            COALESCE(pl.critical_labs, 0) * 20 +
            CASE WHEN p.age >= 65 THEN 15 ELSE 0 END +
            CASE WHEN p.insurance_status = 'Uninsured' THEN 10 ELSE 0 END +
            CASE WHEN COALESCE(pm.active_medications, 0) >= 5 THEN 10 ELSE 0 END
        ) >= 50 THEN 'High'
        WHEN LEAST(100, 
            COALESCE(pe.readmission_count, 0) * 15 +
            COALESCE(pe.emergency_visits, 0) * 10 +
            COALESCE(pl.critical_labs, 0) * 20 +
            CASE WHEN p.age >= 65 THEN 15 ELSE 0 END +
            CASE WHEN p.insurance_status = 'Uninsured' THEN 10 ELSE 0 END +
            CASE WHEN COALESCE(pm.active_medications, 0) >= 5 THEN 10 ELSE 0 END
        ) >= 25 THEN 'Medium'
        ELSE 'Low'
    END AS risk_tier,
    CURRENT_TIMESTAMP() AS last_updated
FROM HCLS_DB.TRANSFORM_SCHEMA.DIM_PATIENTS p
LEFT JOIN patient_encounters pe ON p.patient_id = pe.patient_id
LEFT JOIN patient_labs pl ON p.patient_id = pl.patient_id
LEFT JOIN patient_meds pm ON p.patient_id = pm.patient_id;


-- =============================================================================
-- VERIFICATION QUERIES
-- =============================================================================

SELECT 'READMISSION_METRICS' AS table_name, COUNT(*) AS row_count FROM HCLS_DB.ANALYTICS_SCHEMA.READMISSION_METRICS
UNION ALL SELECT 'FACILITY_SCORECARD', COUNT(*) FROM HCLS_DB.ANALYTICS_SCHEMA.FACILITY_SCORECARD
UNION ALL SELECT 'PHYSICIAN_QUALITY', COUNT(*) FROM HCLS_DB.ANALYTICS_SCHEMA.PHYSICIAN_QUALITY
UNION ALL SELECT 'DIAGNOSIS_ANALYSIS', COUNT(*) FROM HCLS_DB.ANALYTICS_SCHEMA.DIAGNOSIS_ANALYSIS
UNION ALL SELECT 'PATIENT_RISK_SUMMARY', COUNT(*) FROM HCLS_DB.ANALYTICS_SCHEMA.PATIENT_RISK_SUMMARY
ORDER BY table_name;


-- Sample: Top facilities by readmission rate
SELECT facility_name, region, readmission_rate_pct, quality_grade, readmission_risk_tier
FROM HCLS_DB.ANALYTICS_SCHEMA.FACILITY_SCORECARD
ORDER BY readmission_rate_pct DESC
LIMIT 10;

-- Sample: High-risk diagnoses
SELECT diagnosis_description, readmission_rate_pct, total_encounters, risk_classification
FROM HCLS_DB.ANALYTICS_SCHEMA.DIAGNOSIS_ANALYSIS
WHERE readmission_rank <= 10
ORDER BY readmission_rate_pct DESC;

-- Sample: High-risk patients needing intervention
SELECT patient_id, age_group, risk_score, risk_tier, readmission_count, emergency_visits
FROM HCLS_DB.ANALYTICS_SCHEMA.PATIENT_RISK_SUMMARY
WHERE risk_tier = 'High'
ORDER BY risk_score DESC
LIMIT 20;

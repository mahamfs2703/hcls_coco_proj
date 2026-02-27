-- =============================================================================
-- STAGE CREATION AND DATA LOADING FOR HCLS PROJECT
-- =============================================================================

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE COMPUTE_WH;
USE DATABASE HCLS_DB;


--CREATING FILE FORMATS
CREATE OR REPLACE FILE FORMAT HCLS_DB.RAW_SCHEMA.my_csv_format
TYPE = CSV
FIELD_DELIMITER = ','
SKIP_HEADER = 1;
    
-- List files in stage to verify
LIST @HCLS_DB.RAW_SCHEMA.RAW_STAGE;



-- CREATING TABLE FACILITIES_RAW TABLE
CREATE OR REPLACE TABLE HCLS_DB.RAW_SCHEMA.FACILITIES_RAW (
    facility_id NUMBER,
    facility_name VARCHAR,
    facility_type VARCHAR,
    address VARCHAR,
    city VARCHAR,
    state VARCHAR,
    zip_code VARCHAR,
    phone VARCHAR,
    bed_count NUMBER,
    region VARCHAR,
    source_system VARCHAR,
    load_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);
--LOADING DATA
COPY INTO HCLS_DB.RAW_SCHEMA.FACILITIES_RAW (
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
    source_system
)
FROM(
    SELECT $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, METADATA$FILENAME
    FROM '@"HCLS_DB"."RAW_SCHEMA"."RAW_STAGE"/facilities_cleaned.csv'
)
FILE_FORMAT = (FORMAT_NAME = 'HCLS_DB.RAW_SCHEMA.MY_CSV_FORMAT')
ON_ERROR = 'CONTINUE'
PURGE = FALSE;


------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------



--CREATING PHYSICIANS_RAW TABLE
CREATE OR REPLACE TABLE HCLS_DB.RAW_SCHEMA.PHYSICIANS_RAW (
    physician_id NUMBER,
    first_name VARCHAR,
    last_name VARCHAR,
    specialty VARCHAR,
    npi_number VARCHAR,
    email VARCHAR,
    phone VARCHAR,
    department VARCHAR,
    facility_id NUMBER,
    hire_date DATE,
    status VARCHAR,
    source_system VARCHAR,
    load_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);

-- LOADING DATA
COPY INTO HCLS_DB.RAW_SCHEMA.PHYSICIANS_RAW (
    physician_id,
    first_name,
    last_name,
    specialty,
    npi_number,
    email,
    phone,
    department,
    facility_id,
    hire_date,
    status,
    source_system
)
FROM (
    SELECT $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, METADATA$FILENAME
    FROM '@"HCLS_DB"."RAW_SCHEMA"."RAW_STAGE"/physicians_cleaned.csv'
)
FILE_FORMAT = (FORMAT_NAME = 'HCLS_DB.RAW_SCHEMA.MY_CSV_FORMAT')
ON_ERROR = 'CONTINUE'
PURGE = FALSE;


--------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------


--CREATING PATIENTS_RAW TABLE
CREATE OR REPLACE TABLE HCLS_DB.RAW_SCHEMA.PATIENTS_RAW (
    patient_id NUMBER,
    first_name VARCHAR,
    last_name VARCHAR,
    date_of_birth DATE,
    gender VARCHAR,
    email VARCHAR,
    phone VARCHAR,
    ssn VARCHAR,
    address_line1 VARCHAR,
    city VARCHAR,
    state VARCHAR,
    zip_code VARCHAR,
    country VARCHAR,
    insurance_id VARCHAR,
    primary_physician_id NUMBER,
    registration_date TIMESTAMP,
    source_system VARCHAR,
    load_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);

-- Load Patients
COPY INTO HCLS_DB.RAW_SCHEMA.PATIENTS_RAW (
    patient_id,
    first_name,
    last_name,
    date_of_birth,
    gender,
    email,
    phone,
    ssn,
    address_line1,
    city,
    state,
    zip_code,
    country,
    insurance_id,
    primary_physician_id,
    registration_date,
    source_system
)
FROM (
    SELECT $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, METADATA$FILENAME
    FROM '@"HCLS_DB"."RAW_SCHEMA"."RAW_STAGE"/patients_cleaned.csv'
)
FILE_FORMAT = (FORMAT_NAME = 'HCLS_DB.RAW_SCHEMA.MY_CSV_FORMAT')
ON_ERROR = 'CONTINUE'
PURGE = FALSE;


------------------------------------------------------------------------------------
------------------------------------------------------------------------------------

--CREATING ENCOUNTERS_RAW TABLE

CREATE OR REPLACE TABLE HCLS_DB.RAW_SCHEMA.ENCOUNTERS_RAW (
    encounter_id NUMBER,
    patient_id NUMBER,
    physician_id NUMBER,
    facility_id NUMBER,
    encounter_type VARCHAR,
    admission_date TIMESTAMP,
    discharge_date TIMESTAMP,
    chief_complaint VARCHAR,
    diagnosis_code VARCHAR,
    diagnosis_description VARCHAR,
    treatment_notes VARCHAR,
    department VARCHAR,
    source_system VARCHAR,
    load_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);


-- Load Encounters
COPY INTO HCLS_DB.RAW_SCHEMA.ENCOUNTERS_RAW (
    encounter_id,
    patient_id,
    physician_id,
    facility_id,
    encounter_type,
    admission_date,
    discharge_date,
    chief_complaint,
    diagnosis_code,
    diagnosis_description,
    treatment_notes,
    department,
    source_system
)
FROM (
    SELECT $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, METADATA$FILENAME
    FROM '@"HCLS_DB"."RAW_SCHEMA"."RAW_STAGE"/encounters_cleaned.csv'
)
FILE_FORMAT = (FORMAT_NAME = 'HCLS_DB.RAW_SCHEMA.MY_CSV_FORMAT')
ON_ERROR = 'CONTINUE'
PURGE = FALSE;

----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------

--CREATING LAB_RESULTS_RAW TABLE
CREATE OR REPLACE TABLE HCLS_DB.RAW_SCHEMA.LAB_RESULTS_RAW (
    result_id NUMBER,
    patient_id NUMBER,
    encounter_id NUMBER,
    test_code VARCHAR,
    test_name VARCHAR,
    result_value NUMBER,
    result_unit VARCHAR,
    reference_range_low NUMBER,
    reference_range_high NUMBER,
    abnormal_flag VARCHAR,
    collection_date TIMESTAMP,
    result_date TIMESTAMP,
    performing_lab VARCHAR,
    source_system VARCHAR,
    load_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);

-- Load Lab Results
COPY INTO HCLS_DB.RAW_SCHEMA.LAB_RESULTS_RAW (
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
    collection_date,
    result_date,
    performing_lab,
    source_system
)
FROM (
    SELECT $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, METADATA$FILENAME
    FROM '@"HCLS_DB"."RAW_SCHEMA"."RAW_STAGE"/lab_results_cleaned.csv'
)
FILE_FORMAT = (FORMAT_NAME = 'HCLS_DB.RAW_SCHEMA.MY_CSV_FORMAT')
ON_ERROR = 'CONTINUE'
PURGE = FALSE;


-----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------

--CREATING MEDICATIONS_RAW TABLE
CREATE OR REPLACE TABLE HCLS_DB.RAW_SCHEMA.MEDICATIONS_RAW (
    prescription_id NUMBER,
    patient_id NUMBER,
    encounter_id NUMBER,
    medication_code VARCHAR,
    medication_name VARCHAR,
    dosage VARCHAR,
    frequency VARCHAR,
    route VARCHAR,
    prescribing_physician_id NUMBER,
    start_date DATE,
    end_date DATE,
    refills_remaining NUMBER,
    pharmacy_id NUMBER,
    source_system VARCHAR,
    load_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);


-- Load Medications
COPY INTO HCLS_DB.RAW_SCHEMA.MEDICATIONS_RAW (
    prescription_id,
    patient_id,
    encounter_id,
    medication_code,
    medication_name,
    dosage,
    frequency,
    route,
    prescribing_physician_id,
    start_date,
    end_date,
    refills_remaining,
    pharmacy_id,
    source_system
)
FROM (
    SELECT $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, METADATA$FILENAME
    FROM '@"HCLS_DB"."RAW_SCHEMA"."RAW_STAGE"/medications_cleaned.csv'
)
FILE_FORMAT = (FORMAT_NAME = 'HCLS_DB.RAW_SCHEMA.MY_CSV_FORMAT')
ON_ERROR = 'CONTINUE'
PURGE = FALSE;



-- Check row counts
SELECT 'FACILITIES_RAW' AS table_name, COUNT(*) AS row_count FROM HCLS_DB.RAW_SCHEMA.FACILITIES_RAW
UNION ALL SELECT 'PHYSICIANS_RAW', COUNT(*) FROM HCLS_DB.RAW_SCHEMA.PHYSICIANS_RAW
UNION ALL SELECT 'PATIENTS_RAW', COUNT(*) FROM HCLS_DB.RAW_SCHEMA.PATIENTS_RAW
UNION ALL SELECT 'ENCOUNTERS_RAW', COUNT(*) FROM HCLS_DB.RAW_SCHEMA.ENCOUNTERS_RAW
UNION ALL SELECT 'LAB_RESULTS_RAW', COUNT(*) FROM HCLS_DB.RAW_SCHEMA.LAB_RESULTS_RAW
UNION ALL SELECT 'MEDICATIONS_RAW', COUNT(*) FROM HCLS_DB.RAW_SCHEMA.MEDICATIONS_RAW
ORDER BY table_name;


-- Sample data verification
SELECT * FROM HCLS_DB.RAW_SCHEMA.FACILITIES_RAW LIMIT 5;
SELECT * FROM HCLS_DB.RAW_SCHEMA.PHYSICIANS_RAW LIMIT 5;
SELECT * FROM HCLS_DB.RAW_SCHEMA.PATIENTS_RAW LIMIT 5;
SELECT * FROM HCLS_DB.RAW_SCHEMA.ENCOUNTERS_RAW LIMIT 5;
SELECT * FROM HCLS_DB.RAW_SCHEMA.LAB_RESULTS_RAW LIMIT 5;
SELECT * FROM HCLS_DB.RAW_SCHEMA.MEDICATIONS_RAW LIMIT 5;

INSERT INTO HCLS_DB.RAW_SCHEMA.ENCOUNTERS_RAW 
(encounter_id, patient_id, physician_id, facility_id, admission_date, discharge_date, 
 encounter_type, chief_complaint, diagnosis_code, diagnosis_description, department, load_timestamp)
VALUES
-- Patient 1001: Readmitted 10 days after first visit (Dyspnea worsening)
(31, 1001, 1, 1, '2024-12-25 08:00:00', '2024-12-27 14:00:00', 'Inpatient', 'Worsening shortness of breath', 'R06.00', 'Dyspnea unspecified', 'Internal Medicine', CURRENT_TIMESTAMP()),

-- Patient 1002: Readmitted 5 days after emergency (Chest pain returned)
(32, 1002, 2, 2, '2024-11-25 14:30:00', '2024-11-26 10:00:00', 'Emergency', 'Recurring chest pain', 'I20.9', 'Angina pectoris unspecified', 'Cardiology', CURRENT_TIMESTAMP()),

-- Patient 1002: Third visit 15 days after second (Cardiac workup)
(33, 1002, 2, 2, '2024-12-10 09:00:00', '2024-12-12 16:00:00', 'Inpatient', 'Scheduled cardiac catheterization', 'I25.10', 'Coronary artery disease', 'Cardiology', CURRENT_TIMESTAMP()),

-- Patient 1005: Readmitted 20 days after back surgery (Post-op complication)
(34, 1005, 5, 5, '2024-09-25 11:00:00', '2024-09-28 15:00:00', 'Inpatient', 'Post-surgical infection', 'T81.4', 'Infection following procedure', 'Orthopedics', CURRENT_TIMESTAMP()),

-- Patient 1007: Readmitted 7 days after (Cancer treatment complication)
(35, 1007, 7, 7, '2024-07-22 06:00:00', '2024-07-25 12:00:00', 'Emergency', 'Severe fatigue and fever', 'D70.9', 'Neutropenia unspecified', 'Oncology', CURRENT_TIMESTAMP()),

-- Patient 1010: Readmitted 12 days after (Abnormal test results)
(36, 1010, 10, 10, '2024-05-15 10:00:00', '2024-05-17 14:00:00', 'Inpatient', 'Follow-up for abnormal labs', 'R79.9', 'Abnormal finding of blood chemistry', 'Internal Medicine', CURRENT_TIMESTAMP()),

-- Patient 1012: Readmitted 8 days after emergency (Cardiac event)
(37, 1012, 12, 2, '2024-03-18 22:00:00', '2024-03-21 10:00:00', 'Emergency', 'Acute chest pain radiating to arm', 'I21.9', 'Acute myocardial infarction', 'Emergency', CURRENT_TIMESTAMP()),

-- Patient 1014: Readmitted 14 days after (Persistent abdominal pain)
(38, 1014, 14, 4, '2024-02-03 15:00:00', '2024-02-05 11:00:00', 'Inpatient', 'Continued abdominal pain', 'K35.80', 'Acute appendicitis', 'Primary Care', CURRENT_TIMESTAMP()),

-- Patient 1015: Readmitted 3 days after (Severe back pain recurrence)
(39, 1015, 15, 5, '2023-12-31 08:00:00', '2024-01-02 16:00:00', 'Emergency', 'Acute back pain flare', 'M54.5', 'Low back pain', 'Orthopedics', CURRENT_TIMESTAMP()),

-- Patient 1001: Third visit 28 days after second (Follow-up)
(40, 1001, 1, 1, '2025-01-22 09:00:00', '2025-01-22 11:00:00', 'Outpatient', 'Follow-up respiratory check', 'R06.00', 'Dyspnea unspecified', 'Internal Medicine', CURRENT_TIMESTAMP());

SELECT * FROM HCLS_DB.RAW_SCHEMA.ENCOUNTERS_RAW;
SELECT * FROM HCLS_DB.RAW_SCHEMA.PATIENTS_RAW;

-- =============================================================================
-- PATIENTS WITH MULTIPLE ENCOUNTERS (>1)
-- =============================================================================
SELECT 
    p.patient_id,
    p.first_name,
    p.last_name,
    p.date_of_birth,
    p.gender,
    p.city,
    p.state,
    p.insurance_id,
    enc.encounter_count,
    enc.first_visit,
    enc.last_visit
FROM HCLS_DB.RAW_SCHEMA.PATIENTS_RAW p
INNER JOIN (
    SELECT 
        patient_id,
        COUNT(*) AS encounter_count,
        MIN(admission_date) AS first_visit,
        MAX(admission_date) AS last_visit
    FROM HCLS_DB.RAW_SCHEMA.ENCOUNTERS_RAW
    GROUP BY patient_id
    HAVING COUNT(*) > 1
) enc ON p.patient_id = enc.patient_id
ORDER BY enc.encounter_count DESC;
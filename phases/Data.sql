-- =============================================================================
-- SYNTHETIC DATA GENERATION FOR HCLS MEDALLION ARCHITECTURE
-- =============================================================================

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE COMPUTE_WH;
USE DATABASE HCLS_DB;

-- =============================================================================
-- BRONZE LAYER: RAW DATA TABLES
-- =============================================================================

-- Patients Raw Data
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

-- Clinical Encounters Raw
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

-- Lab Results Raw
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

-- Medications Raw
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

-- Physicians Reference
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

-- Facilities Reference
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

-- =============================================================================
-- INSERT SYNTHETIC DATA
-- =============================================================================

-- Insert Facilities (10 records)
INSERT INTO HCLS_DB.RAW_SCHEMA.FACILITIES_RAW 
    (facility_id, facility_name, facility_type, address, city, state, zip_code, phone, bed_count, region, source_system)
VALUES
    (1, 'Metro General Hospital', 'Hospital', '100 Medical Center Dr', 'New York', 'NY', '10001', '212-555-1000', 500, 'Northeast', 'EHR_EPIC'),
    (2, 'Sunrise Medical Center', 'Hospital', '200 Healthcare Blvd', 'Los Angeles', 'CA', '90001', '310-555-2000', 400, 'West', 'EHR_EPIC'),
    (3, 'Midwest Regional Hospital', 'Hospital', '300 Wellness Way', 'Chicago', 'IL', '60601', '312-555-3000', 350, 'Midwest', 'EHR_CERNER'),
    (4, 'Southern Health Center', 'Hospital', '400 Care Lane', 'Houston', 'TX', '77001', '713-555-4000', 450, 'South', 'EHR_EPIC'),
    (5, 'Pacific Coast Clinic', 'Clinic', '500 Ocean Ave', 'San Francisco', 'CA', '94102', '415-555-5000', 50, 'West', 'EHR_CERNER'),
    (6, 'Mountain View Hospital', 'Hospital', '600 Peak Dr', 'Denver', 'CO', '80201', '303-555-6000', 300, 'West', 'EHR_EPIC'),
    (7, 'Atlantic Medical Center', 'Hospital', '700 Shore Rd', 'Miami', 'FL', '33101', '305-555-7000', 380, 'Southeast', 'EHR_MEDITECH'),
    (8, 'Heartland Clinic', 'Clinic', '800 Prairie St', 'Kansas City', 'MO', '64101', '816-555-8000', 40, 'Midwest', 'EHR_CERNER'),
    (9, 'Northwest Medical Group', 'Clinic', '900 Pine Way', 'Seattle', 'WA', '98101', '206-555-9000', 60, 'Northwest', 'EHR_EPIC'),
    (10, 'Capital Health System', 'Hospital', '1000 Constitution Ave', 'Washington', 'DC', '20001', '202-555-0100', 420, 'Northeast', 'EHR_EPIC');

-- Insert Physicians (20 records)
INSERT INTO HCLS_DB.RAW_SCHEMA.PHYSICIANS_RAW 
    (physician_id, first_name, last_name, specialty, npi_number, email, phone, department, facility_id, hire_date, status, source_system)
VALUES
    (1, 'Sarah', 'Mitchell', 'Cardiology', '1234567890', 'sarah.mitchell@metrogen.com', '212-555-1001', 'Cardiology', 1, '2015-03-15', 'Active', 'HR_SYSTEM'),
    (2, 'James', 'Wilson', 'Internal Medicine', '1234567891', 'james.wilson@sunrisemc.com', '310-555-2001', 'Internal Medicine', 2, '2012-07-22', 'Active', 'HR_SYSTEM'),
    (3, 'Emily', 'Chen', 'Neurology', '1234567892', 'emily.chen@midwestrh.com', '312-555-3001', 'Neurology', 3, '2018-01-10', 'Active', 'HR_SYSTEM'),
    (4, 'Michael', 'Brown', 'Orthopedics', '1234567893', 'michael.brown@southernhc.com', '713-555-4001', 'Orthopedics', 4, '2010-11-05', 'Active', 'HR_SYSTEM'),
    (5, 'Jessica', 'Garcia', 'Pediatrics', '1234567894', 'jessica.garcia@pacificcc.com', '415-555-5001', 'Pediatrics', 5, '2019-05-20', 'Active', 'HR_SYSTEM'),
    (6, 'David', 'Martinez', 'Oncology', '1234567895', 'david.martinez@mountainvh.com', '303-555-6001', 'Oncology', 6, '2014-09-12', 'Active', 'HR_SYSTEM'),
    (7, 'Amanda', 'Thompson', 'Dermatology', '1234567896', 'amanda.thompson@atlanticmc.com', '305-555-7001', 'Dermatology', 7, '2017-04-18', 'Active', 'HR_SYSTEM'),
    (8, 'Robert', 'Anderson', 'Family Medicine', '1234567897', 'robert.anderson@heartlandc.com', '816-555-8001', 'Family Medicine', 8, '2011-08-30', 'Active', 'HR_SYSTEM'),
    (9, 'Jennifer', 'Taylor', 'Psychiatry', '1234567898', 'jennifer.taylor@northwestmg.com', '206-555-9001', 'Psychiatry', 9, '2016-12-01', 'Active', 'HR_SYSTEM'),
    (10, 'William', 'Jackson', 'Emergency Medicine', '1234567899', 'william.jackson@capitalhs.com', '202-555-0101', 'Emergency', 10, '2013-06-25', 'Active', 'HR_SYSTEM'),
    (11, 'Lisa', 'White', 'Cardiology', '2234567890', 'lisa.white@metrogen.com', '212-555-1002', 'Cardiology', 1, '2020-02-14', 'Active', 'HR_SYSTEM'),
    (12, 'Christopher', 'Harris', 'Pulmonology', '2234567891', 'chris.harris@sunrisemc.com', '310-555-2002', 'Pulmonology', 2, '2018-10-08', 'Active', 'HR_SYSTEM'),
    (13, 'Michelle', 'Clark', 'Endocrinology', '2234567892', 'michelle.clark@midwestrh.com', '312-555-3002', 'Endocrinology', 3, '2015-07-19', 'Active', 'HR_SYSTEM'),
    (14, 'Daniel', 'Lewis', 'Gastroenterology', '2234567893', 'daniel.lewis@southernhc.com', '713-555-4002', 'Gastroenterology', 4, '2019-03-27', 'Active', 'HR_SYSTEM'),
    (15, 'Stephanie', 'Robinson', 'Rheumatology', '2234567894', 'stephanie.robinson@pacificcc.com', '415-555-5002', 'Rheumatology', 5, '2017-11-11', 'Active', 'HR_SYSTEM'),
    (16, 'Kevin', 'Walker', 'Nephrology', '2234567895', 'kevin.walker@mountainvh.com', '303-555-6002', 'Nephrology', 6, '2014-05-03', 'Active', 'HR_SYSTEM'),
    (17, 'Rachel', 'Young', 'Infectious Disease', '2234567896', 'rachel.young@atlanticmc.com', '305-555-7002', 'Infectious Disease', 7, '2021-01-20', 'Active', 'HR_SYSTEM'),
    (18, 'Thomas', 'King', 'Urology', '2234567897', 'thomas.king@heartlandc.com', '816-555-8002', 'Urology', 8, '2016-08-15', 'Active', 'HR_SYSTEM'),
    (19, 'Nicole', 'Wright', 'OB/GYN', '2234567898', 'nicole.wright@northwestmg.com', '206-555-9002', 'OB/GYN', 9, '2012-04-09', 'Active', 'HR_SYSTEM'),
    (20, 'Brian', 'Scott', 'Surgery', '2234567899', 'brian.scott@capitalhs.com', '202-555-0102', 'Surgery', 10, '2010-09-01', 'Active', 'HR_SYSTEM');

-- Insert Patients (50 records)
INSERT INTO HCLS_DB.RAW_SCHEMA.PATIENTS_RAW 
    (patient_id, first_name, last_name, date_of_birth, gender, email, phone, ssn, address_line1, city, state, zip_code, country, insurance_id, primary_physician_id, registration_date, source_system)
VALUES
    (1001, 'Alice', 'Johnson', '1985-03-15', 'Female', 'alice.johnson@email.com', '555-101-0001', '111-22-3333', '123 Oak Street', 'New York', 'NY', '10002', 'USA', 'INS-BC-001', 1, '2020-01-15 09:30:00', 'EHR_EPIC'),
    (1002, 'Bob', 'Smith', '1978-07-22', 'Male', 'bob.smith@email.com', '555-101-0002', '222-33-4444', '456 Maple Ave', 'Los Angeles', 'CA', '90002', 'USA', 'INS-AE-002', 2, '2019-06-20 14:15:00', 'EHR_EPIC'),
    (1003, 'Carol', 'Williams', '1990-11-30', 'Female', 'carol.williams@email.com', '555-101-0003', '333-44-5555', '789 Pine Rd', 'Chicago', 'IL', '60602', 'USA', 'INS-UN-003', 3, '2021-03-08 10:45:00', 'EHR_CERNER'),
    (1004, 'David', 'Brown', '1965-05-18', 'Male', 'david.brown@email.com', '555-101-0004', '444-55-6666', '321 Elm Blvd', 'Houston', 'TX', '77002', 'USA', 'INS-CI-004', 4, '2018-09-12 16:00:00', 'EHR_EPIC'),
    (1005, 'Emma', 'Davis', '2010-02-28', 'Female', 'emma.davis.parent@email.com', '555-101-0005', '555-66-7777', '654 Cedar Lane', 'San Francisco', 'CA', '94103', 'USA', 'INS-KP-005', 5, '2020-07-01 11:30:00', 'EHR_CERNER'),
    (1006, 'Frank', 'Miller', '1955-09-10', 'Male', 'frank.miller@email.com', '555-101-0006', '666-77-8888', '987 Birch Dr', 'Denver', 'CO', '80202', 'USA', 'INS-MC-006', 6, '2017-11-25 08:45:00', 'EHR_EPIC'),
    (1007, 'Grace', 'Wilson', '1988-12-05', 'Female', 'grace.wilson@email.com', '555-101-0007', '777-88-9999', '147 Spruce Way', 'Miami', 'FL', '33102', 'USA', 'INS-BC-007', 7, '2019-04-17 13:00:00', 'EHR_MEDITECH'),
    (1008, 'Henry', 'Moore', '1972-04-20', 'Male', 'henry.moore@email.com', '555-101-0008', '888-99-0000', '258 Willow St', 'Kansas City', 'MO', '64102', 'USA', 'INS-AE-008', 8, '2016-08-30 15:30:00', 'EHR_CERNER'),
    (1009, 'Ivy', 'Taylor', '1995-08-14', 'Female', 'ivy.taylor@email.com', '555-101-0009', '999-00-1111', '369 Aspen Ct', 'Seattle', 'WA', '98102', 'USA', 'INS-UN-009', 9, '2021-01-10 09:00:00', 'EHR_EPIC'),
    (1010, 'Jack', 'Anderson', '1960-01-25', 'Male', 'jack.anderson@email.com', '555-101-0010', '000-11-2222', '741 Redwood Pl', 'Washington', 'DC', '20002', 'USA', 'INS-CI-010', 10, '2015-05-05 10:15:00', 'EHR_EPIC'),
    (1011, 'Karen', 'Thomas', '1982-06-08', 'Female', 'karen.thomas@email.com', '555-101-0011', '123-45-6781', '852 Sequoia Ave', 'New York', 'NY', '10003', 'USA', 'INS-KP-011', 11, '2020-02-28 14:45:00', 'EHR_EPIC'),
    (1012, 'Leo', 'Jackson', '1975-10-12', 'Male', 'leo.jackson@email.com', '555-101-0012', '234-56-7892', '963 Magnolia Rd', 'Los Angeles', 'CA', '90003', 'USA', 'INS-MC-012', 12, '2018-07-19 11:00:00', 'EHR_EPIC'),
    (1013, 'Maria', 'White', '1998-03-30', 'Female', 'maria.white@email.com', '555-101-0013', '345-67-8903', '159 Dogwood Ln', 'Chicago', 'IL', '60603', 'USA', 'INS-BC-013', 13, '2021-06-15 16:30:00', 'EHR_CERNER'),
    (1014, 'Nathan', 'Harris', '1968-07-04', 'Male', 'nathan.harris@email.com', '555-101-0014', '456-78-9014', '267 Hickory Blvd', 'Houston', 'TX', '77003', 'USA', 'INS-AE-014', 14, '2017-03-22 08:00:00', 'EHR_EPIC'),
    (1015, 'Olivia', 'Martin', '2005-11-19', 'Female', 'olivia.martin.parent@email.com', '555-101-0015', '567-89-0125', '378 Chestnut St', 'San Francisco', 'CA', '94104', 'USA', 'INS-UN-015', 5, '2019-10-08 12:15:00', 'EHR_CERNER'),
    (1016, 'Peter', 'Garcia', '1958-02-14', 'Male', 'peter.garcia@email.com', '555-101-0016', '678-90-1236', '489 Walnut Way', 'Denver', 'CO', '80203', 'USA', 'INS-CI-016', 16, '2016-12-01 09:45:00', 'EHR_EPIC'),
    (1017, 'Quinn', 'Martinez', '1992-05-27', 'Female', 'quinn.martinez@email.com', '555-101-0017', '789-01-2347', '591 Sycamore Dr', 'Miami', 'FL', '33103', 'USA', 'INS-KP-017', 17, '2020-04-30 15:00:00', 'EHR_MEDITECH'),
    (1018, 'Ryan', 'Robinson', '1980-09-03', 'Male', 'ryan.robinson@email.com', '555-101-0018', '890-12-3458', '602 Poplar Ct', 'Kansas City', 'MO', '64103', 'USA', 'INS-MC-018', 18, '2018-01-14 10:30:00', 'EHR_CERNER'),
    (1019, 'Sophia', 'Clark', '2000-12-25', 'Female', 'sophia.clark@email.com', '555-101-0019', '901-23-4569', '713 Cypress Pl', 'Seattle', 'WA', '98103', 'USA', 'INS-BC-019', 9, '2021-08-20 13:45:00', 'EHR_EPIC'),
    (1020, 'Tyler', 'Rodriguez', '1952-04-08', 'Male', 'tyler.rodriguez@email.com', '555-101-0020', '012-34-5670', '824 Palm Ave', 'Washington', 'DC', '20003', 'USA', 'INS-AE-020', 20, '2014-11-11 08:30:00', 'EHR_EPIC'),
    (1021, 'Uma', 'Lewis', '1987-08-16', 'Female', 'uma.lewis@email.com', '555-101-0021', '111-22-3334', '935 Bamboo Rd', 'New York', 'NY', '10004', 'USA', 'INS-UN-021', 1, '2019-02-05 14:00:00', 'EHR_EPIC'),
    (1022, 'Victor', 'Lee', '1973-01-29', 'Male', 'victor.lee@email.com', '555-101-0022', '222-33-4445', '146 Fern Ln', 'Los Angeles', 'CA', '90004', 'USA', 'INS-CI-022', 2, '2017-06-28 11:15:00', 'EHR_EPIC'),
    (1023, 'Wendy', 'Walker', '1996-06-11', 'Female', 'wendy.walker@email.com', '555-101-0023', '333-44-5556', '257 Ivy Blvd', 'Chicago', 'IL', '60604', 'USA', 'INS-KP-023', 3, '2020-09-17 16:45:00', 'EHR_CERNER'),
    (1024, 'Xavier', 'Hall', '1963-10-05', 'Male', 'xavier.hall@email.com', '555-101-0024', '444-55-6667', '368 Moss St', 'Houston', 'TX', '77004', 'USA', 'INS-MC-024', 4, '2015-12-20 09:00:00', 'EHR_EPIC'),
    (1025, 'Yolanda', 'Allen', '2008-04-18', 'Female', 'yolanda.allen.parent@email.com', '555-101-0025', '555-66-7778', '479 Clover Way', 'San Francisco', 'CA', '94105', 'USA', 'INS-BC-025', 5, '2021-05-03 12:30:00', 'EHR_CERNER'),
    (1026, 'Zachary', 'Young', '1970-07-22', 'Male', 'zachary.young@email.com', '555-101-0026', '666-77-8889', '580 Daisy Dr', 'Denver', 'CO', '80204', 'USA', 'INS-AE-026', 6, '2018-03-09 15:15:00', 'EHR_EPIC'),
    (1027, 'Abigail', 'King', '1984-11-08', 'Female', 'abigail.king@email.com', '555-101-0027', '777-88-9990', '691 Rose Ct', 'Miami', 'FL', '33104', 'USA', 'INS-UN-027', 7, '2019-08-26 10:00:00', 'EHR_MEDITECH'),
    (1028, 'Benjamin', 'Wright', '1977-03-14', 'Male', 'benjamin.wright@email.com', '555-101-0028', '888-99-0001', '702 Lily Pl', 'Kansas City', 'MO', '64104', 'USA', 'INS-CI-028', 8, '2016-06-05 13:30:00', 'EHR_CERNER'),
    (1029, 'Charlotte', 'Scott', '1993-09-27', 'Female', 'charlotte.scott@email.com', '555-101-0029', '999-00-1112', '813 Tulip Ave', 'Seattle', 'WA', '98104', 'USA', 'INS-KP-029', 9, '2020-11-12 08:45:00', 'EHR_EPIC'),
    (1030, 'Dylan', 'Green', '1956-05-31', 'Male', 'dylan.green@email.com', '555-101-0030', '000-11-2223', '924 Orchid Rd', 'Washington', 'DC', '20004', 'USA', 'INS-MC-030', 10, '2013-10-01 14:30:00', 'EHR_EPIC'),
    (1031, 'Eleanor', 'Adams', '1989-01-20', 'Female', 'eleanor.adams@email.com', '555-101-0031', '123-45-6782', '135 Violet Ln', 'New York', 'NY', '10005', 'USA', 'INS-BC-031', 11, '2018-04-18 11:45:00', 'EHR_EPIC'),
    (1032, 'Felix', 'Baker', '1971-08-09', 'Male', 'felix.baker@email.com', '555-101-0032', '234-56-7893', '246 Jasmine Blvd', 'Los Angeles', 'CA', '90005', 'USA', 'INS-AE-032', 12, '2017-01-25 09:15:00', 'EHR_EPIC'),
    (1033, 'Georgia', 'Nelson', '1999-04-03', 'Female', 'georgia.nelson@email.com', '555-101-0033', '345-67-8904', '357 Peony St', 'Chicago', 'IL', '60605', 'USA', 'INS-UN-033', 13, '2021-07-07 15:45:00', 'EHR_CERNER'),
    (1034, 'Harrison', 'Carter', '1966-12-17', 'Male', 'harrison.carter@email.com', '555-101-0034', '456-78-9015', '468 Zinnia Way', 'Houston', 'TX', '77005', 'USA', 'INS-CI-034', 14, '2015-09-30 12:00:00', 'EHR_EPIC'),
    (1035, 'Isabella', 'Mitchell', '2003-06-24', 'Female', 'isabella.mitchell@email.com', '555-101-0035', '567-89-0126', '579 Dahlia Dr', 'San Francisco', 'CA', '94106', 'USA', 'INS-KP-035', 15, '2020-01-08 10:30:00', 'EHR_CERNER'),
    (1036, 'James', 'Perez', '1959-02-11', 'Male', 'james.perez@email.com', '555-101-0036', '678-90-1237', '680 Aster Ct', 'Denver', 'CO', '80205', 'USA', 'INS-MC-036', 16, '2014-07-14 14:15:00', 'EHR_EPIC'),
    (1037, 'Katherine', 'Roberts', '1991-10-28', 'Female', 'katherine.roberts@email.com', '555-101-0037', '789-01-2348', '791 Begonia Pl', 'Miami', 'FL', '33105', 'USA', 'INS-BC-037', 17, '2019-12-03 08:00:00', 'EHR_MEDITECH'),
    (1038, 'Liam', 'Turner', '1979-05-06', 'Male', 'liam.turner@email.com', '555-101-0038', '890-12-3459', '802 Camellia Ave', 'Kansas City', 'MO', '64105', 'USA', 'INS-AE-038', 18, '2017-08-21 13:00:00', 'EHR_CERNER'),
    (1039, 'Mia', 'Phillips', '2001-08-15', 'Female', 'mia.phillips@email.com', '555-101-0039', '901-23-4560', '913 Freesia Rd', 'Seattle', 'WA', '98105', 'USA', 'INS-UN-039', 19, '2021-03-26 16:15:00', 'EHR_EPIC'),
    (1040, 'Noah', 'Campbell', '1954-11-02', 'Male', 'noah.campbell@email.com', '555-101-0040', '012-34-5671', '124 Gardenia Ln', 'Washington', 'DC', '20005', 'USA', 'INS-CI-040', 20, '2012-05-18 11:30:00', 'EHR_EPIC'),
    (1041, 'Olivia', 'Parker', '1986-03-19', 'Female', 'olivia.parker@email.com', '555-101-0041', '111-22-3335', '235 Hibiscus Blvd', 'New York', 'NY', '10006', 'USA', 'INS-KP-041', 1, '2018-10-10 09:45:00', 'EHR_EPIC'),
    (1042, 'Patrick', 'Evans', '1974-07-26', 'Male', 'patrick.evans@email.com', '555-101-0042', '222-33-4446', '346 Iris St', 'Los Angeles', 'CA', '90006', 'USA', 'INS-MC-042', 2, '2016-02-14 15:00:00', 'EHR_EPIC'),
    (1043, 'Rachel', 'Edwards', '1997-12-01', 'Female', 'rachel.edwards@email.com', '555-101-0043', '333-44-5557', '457 Marigold Way', 'Chicago', 'IL', '60606', 'USA', 'INS-BC-043', 3, '2020-06-22 12:45:00', 'EHR_CERNER'),
    (1044, 'Samuel', 'Collins', '1962-04-14', 'Male', 'samuel.collins@email.com', '555-101-0044', '444-55-6668', '568 Narcissus Dr', 'Houston', 'TX', '77006', 'USA', 'INS-AE-044', 4, '2014-01-07 10:00:00', 'EHR_EPIC'),
    (1045, 'Taylor', 'Stewart', '2006-09-08', 'Female', 'taylor.stewart.parent@email.com', '555-101-0045', '555-66-7779', '679 Pansy Ct', 'San Francisco', 'CA', '94107', 'USA', 'INS-UN-045', 5, '2021-09-15 14:30:00', 'EHR_CERNER'),
    (1046, 'Ulysses', 'Sanchez', '1969-01-23', 'Male', 'ulysses.sanchez@email.com', '555-101-0046', '666-77-8880', '780 Petunia Pl', 'Denver', 'CO', '80206', 'USA', 'INS-CI-046', 6, '2015-06-29 08:15:00', 'EHR_EPIC'),
    (1047, 'Violet', 'Morris', '1983-06-16', 'Female', 'violet.morris@email.com', '555-101-0047', '777-88-9991', '891 Primrose Ave', 'Miami', 'FL', '33106', 'USA', 'INS-KP-047', 7, '2019-11-04 13:15:00', 'EHR_MEDITECH'),
    (1048, 'William', 'Rogers', '1976-10-30', 'Male', 'william.rogers@email.com', '555-101-0048', '888-99-0002', '902 Sunflower Rd', 'Kansas City', 'MO', '64106', 'USA', 'INS-MC-048', 8, '2017-04-12 10:45:00', 'EHR_CERNER'),
    (1049, 'Ximena', 'Reed', '1994-02-07', 'Female', 'ximena.reed@email.com', '555-101-0049', '999-00-1113', '113 Wisteria Ln', 'Seattle', 'WA', '98106', 'USA', 'INS-BC-049', 9, '2020-08-08 16:00:00', 'EHR_EPIC'),
    (1050, 'Yusuf', 'Cook', '1957-08-21', 'Male', 'yusuf.cook@email.com', '555-101-0050', '000-11-2224', '224 Bluebell Blvd', 'Washington', 'DC', '20006', 'USA', 'INS-AE-050', 10, '2013-03-15 11:00:00', 'EHR_EPIC');

-- Insert Encounters (100 records)
INSERT INTO HCLS_DB.RAW_SCHEMA.ENCOUNTERS_RAW 
    (encounter_id, patient_id, physician_id, facility_id, encounter_type, admission_date, discharge_date, chief_complaint, diagnosis_code, diagnosis_description, treatment_notes, department, source_system)
SELECT 
    ROW_NUMBER() OVER (ORDER BY p.patient_id, d.seq) AS encounter_id,
    p.patient_id,
    MOD(ROW_NUMBER() OVER (ORDER BY p.patient_id, d.seq), 20) + 1 AS physician_id,
    MOD(ROW_NUMBER() OVER (ORDER BY p.patient_id, d.seq), 10) + 1 AS facility_id,
    CASE MOD(ROW_NUMBER() OVER (ORDER BY p.patient_id, d.seq), 5)
        WHEN 0 THEN 'Inpatient'
        WHEN 1 THEN 'Outpatient'
        WHEN 2 THEN 'Emergency'
        WHEN 3 THEN 'Telehealth'
        ELSE 'Observation'
    END AS encounter_type,
    DATEADD(DAY, -MOD(ROW_NUMBER() OVER (ORDER BY p.patient_id, d.seq) * 7, 365), CURRENT_DATE()) AS admission_date,
    DATEADD(DAY, -MOD(ROW_NUMBER() OVER (ORDER BY p.patient_id, d.seq) * 7, 365) + MOD(ROW_NUMBER() OVER (ORDER BY p.patient_id, d.seq), 3) + 1, CURRENT_DATE()) AS discharge_date,
    CASE MOD(ROW_NUMBER() OVER (ORDER BY p.patient_id, d.seq), 10)
        WHEN 0 THEN 'Chest pain'
        WHEN 1 THEN 'Shortness of breath'
        WHEN 2 THEN 'Headache'
        WHEN 3 THEN 'Abdominal pain'
        WHEN 4 THEN 'Back pain'
        WHEN 5 THEN 'Fever'
        WHEN 6 THEN 'Fatigue'
        WHEN 7 THEN 'Dizziness'
        WHEN 8 THEN 'Joint pain'
        ELSE 'Routine checkup'
    END AS chief_complaint,
    CASE MOD(ROW_NUMBER() OVER (ORDER BY p.patient_id, d.seq), 10)
        WHEN 0 THEN 'I20.9'
        WHEN 1 THEN 'R06.00'
        WHEN 2 THEN 'G43.909'
        WHEN 3 THEN 'R10.9'
        WHEN 4 THEN 'M54.5'
        WHEN 5 THEN 'R50.9'
        WHEN 6 THEN 'R53.83'
        WHEN 7 THEN 'R42'
        WHEN 8 THEN 'M25.50'
        ELSE 'Z00.00'
    END AS diagnosis_code,
    CASE MOD(ROW_NUMBER() OVER (ORDER BY p.patient_id, d.seq), 10)
        WHEN 0 THEN 'Angina pectoris, unspecified'
        WHEN 1 THEN 'Dyspnea, unspecified'
        WHEN 2 THEN 'Migraine, unspecified'
        WHEN 3 THEN 'Abdominal pain, unspecified'
        WHEN 4 THEN 'Low back pain'
        WHEN 5 THEN 'Fever, unspecified'
        WHEN 6 THEN 'Other fatigue'
        WHEN 7 THEN 'Dizziness and giddiness'
        WHEN 8 THEN 'Pain in unspecified joint'
        ELSE 'General adult medical examination'
    END AS diagnosis_description,
    'Patient treated and discharged with follow-up instructions.' AS treatment_notes,
    CASE MOD(ROW_NUMBER() OVER (ORDER BY p.patient_id, d.seq), 8)
        WHEN 0 THEN 'Cardiology'
        WHEN 1 THEN 'Internal Medicine'
        WHEN 2 THEN 'Neurology'
        WHEN 3 THEN 'Emergency'
        WHEN 4 THEN 'Orthopedics'
        WHEN 5 THEN 'Primary Care'
        WHEN 6 THEN 'Oncology'
        ELSE 'General Medicine'
    END AS department,
    'EHR_EPIC' AS source_system
FROM HCLS_DB.RAW_SCHEMA.PATIENTS_RAW p
CROSS JOIN (SELECT 1 AS seq UNION SELECT 2) d
WHERE p.patient_id <= 1050;

-- Insert Lab Results (200 records)
INSERT INTO HCLS_DB.RAW_SCHEMA.LAB_RESULTS_RAW 
    (result_id, patient_id, encounter_id, test_code, test_name, result_value, result_unit, reference_range_low, reference_range_high, abnormal_flag, collection_date, result_date, performing_lab, source_system)
SELECT 
    ROW_NUMBER() OVER (ORDER BY e.encounter_id, t.seq) AS result_id,
    e.patient_id,
    e.encounter_id,
    CASE MOD(ROW_NUMBER() OVER (ORDER BY e.encounter_id, t.seq), 10)
        WHEN 0 THEN 'GLU'
        WHEN 1 THEN 'HBA1C'
        WHEN 2 THEN 'CHOL'
        WHEN 3 THEN 'HDL'
        WHEN 4 THEN 'LDL'
        WHEN 5 THEN 'TRIG'
        WHEN 6 THEN 'WBC'
        WHEN 7 THEN 'RBC'
        WHEN 8 THEN 'HGB'
        ELSE 'PLT'
    END AS test_code,
    CASE MOD(ROW_NUMBER() OVER (ORDER BY e.encounter_id, t.seq), 10)
        WHEN 0 THEN 'Glucose'
        WHEN 1 THEN 'Hemoglobin A1C'
        WHEN 2 THEN 'Total Cholesterol'
        WHEN 3 THEN 'HDL Cholesterol'
        WHEN 4 THEN 'LDL Cholesterol'
        WHEN 5 THEN 'Triglycerides'
        WHEN 6 THEN 'White Blood Cell Count'
        WHEN 7 THEN 'Red Blood Cell Count'
        WHEN 8 THEN 'Hemoglobin'
        ELSE 'Platelet Count'
    END AS test_name,
    CASE MOD(ROW_NUMBER() OVER (ORDER BY e.encounter_id, t.seq), 10)
        WHEN 0 THEN 85 + MOD(e.encounter_id, 40)
        WHEN 1 THEN 5.0 + MOD(e.encounter_id, 30) / 10.0
        WHEN 2 THEN 160 + MOD(e.encounter_id, 60)
        WHEN 3 THEN 40 + MOD(e.encounter_id, 30)
        WHEN 4 THEN 90 + MOD(e.encounter_id, 50)
        WHEN 5 THEN 100 + MOD(e.encounter_id, 100)
        WHEN 6 THEN 5.0 + MOD(e.encounter_id, 80) / 10.0
        WHEN 7 THEN 4.0 + MOD(e.encounter_id, 20) / 10.0
        WHEN 8 THEN 12.0 + MOD(e.encounter_id, 40) / 10.0
        ELSE 150 + MOD(e.encounter_id, 200)
    END AS result_value,
    CASE MOD(ROW_NUMBER() OVER (ORDER BY e.encounter_id, t.seq), 10)
        WHEN 0 THEN 'mg/dL'
        WHEN 1 THEN '%'
        WHEN 2 THEN 'mg/dL'
        WHEN 3 THEN 'mg/dL'
        WHEN 4 THEN 'mg/dL'
        WHEN 5 THEN 'mg/dL'
        WHEN 6 THEN 'K/uL'
        WHEN 7 THEN 'M/uL'
        WHEN 8 THEN 'g/dL'
        ELSE 'K/uL'
    END AS result_unit,
    CASE MOD(ROW_NUMBER() OVER (ORDER BY e.encounter_id, t.seq), 10)
        WHEN 0 THEN 70
        WHEN 1 THEN 4.0
        WHEN 2 THEN 125
        WHEN 3 THEN 40
        WHEN 4 THEN 0
        WHEN 5 THEN 0
        WHEN 6 THEN 4.5
        WHEN 7 THEN 4.0
        WHEN 8 THEN 12.0
        ELSE 150
    END AS reference_range_low,
    CASE MOD(ROW_NUMBER() OVER (ORDER BY e.encounter_id, t.seq), 10)
        WHEN 0 THEN 100
        WHEN 1 THEN 5.7
        WHEN 2 THEN 200
        WHEN 3 THEN 60
        WHEN 4 THEN 100
        WHEN 5 THEN 150
        WHEN 6 THEN 11.0
        WHEN 7 THEN 5.5
        WHEN 8 THEN 17.0
        ELSE 400
    END AS reference_range_high,
    CASE 
        WHEN MOD(e.encounter_id, 5) = 0 THEN 'H'
        WHEN MOD(e.encounter_id, 7) = 0 THEN 'L'
        ELSE 'N'
    END AS abnormal_flag,
    e.admission_date AS collection_date,
    DATEADD(HOUR, 4, e.admission_date) AS result_date,
    CASE MOD(e.encounter_id, 3)
        WHEN 0 THEN 'Quest Diagnostics'
        WHEN 1 THEN 'LabCorp'
        ELSE 'In-House Laboratory'
    END AS performing_lab,
    'LAB_SYSTEM' AS source_system
FROM HCLS_DB.RAW_SCHEMA.ENCOUNTERS_RAW e
CROSS JOIN (SELECT 1 AS seq UNION SELECT 2) t
WHERE e.encounter_id <= 100;

-- Insert Medications (150 records)
INSERT INTO HCLS_DB.RAW_SCHEMA.MEDICATIONS_RAW 
    (prescription_id, patient_id, encounter_id, medication_code, medication_name, dosage, frequency, route, prescribing_physician_id, start_date, end_date, refills_remaining, pharmacy_id, source_system)
SELECT 
    ROW_NUMBER() OVER (ORDER BY e.encounter_id, m.seq) AS prescription_id,
    e.patient_id,
    e.encounter_id,
    CASE MOD(ROW_NUMBER() OVER (ORDER BY e.encounter_id, m.seq), 15)
        WHEN 0 THEN 'MED001'
        WHEN 1 THEN 'MED002'
        WHEN 2 THEN 'MED003'
        WHEN 3 THEN 'MED004'
        WHEN 4 THEN 'MED005'
        WHEN 5 THEN 'MED006'
        WHEN 6 THEN 'MED007'
        WHEN 7 THEN 'MED008'
        WHEN 8 THEN 'MED009'
        WHEN 9 THEN 'MED010'
        WHEN 10 THEN 'MED011'
        WHEN 11 THEN 'MED012'
        WHEN 12 THEN 'MED013'
        WHEN 13 THEN 'MED014'
        ELSE 'MED015'
    END AS medication_code,
    CASE MOD(ROW_NUMBER() OVER (ORDER BY e.encounter_id, m.seq), 15)
        WHEN 0 THEN 'Lisinopril'
        WHEN 1 THEN 'Metformin'
        WHEN 2 THEN 'Atorvastatin'
        WHEN 3 THEN 'Amlodipine'
        WHEN 4 THEN 'Omeprazole'
        WHEN 5 THEN 'Metoprolol'
        WHEN 6 THEN 'Losartan'
        WHEN 7 THEN 'Albuterol'
        WHEN 8 THEN 'Gabapentin'
        WHEN 9 THEN 'Hydrochlorothiazide'
        WHEN 10 THEN 'Sertraline'
        WHEN 11 THEN 'Acetaminophen'
        WHEN 12 THEN 'Ibuprofen'
        WHEN 13 THEN 'Prednisone'
        ELSE 'Amoxicillin'
    END AS medication_name,
    CASE MOD(ROW_NUMBER() OVER (ORDER BY e.encounter_id, m.seq), 5)
        WHEN 0 THEN '10mg'
        WHEN 1 THEN '20mg'
        WHEN 2 THEN '50mg'
        WHEN 3 THEN '100mg'
        ELSE '500mg'
    END AS dosage,
    CASE MOD(ROW_NUMBER() OVER (ORDER BY e.encounter_id, m.seq), 4)
        WHEN 0 THEN 'Once daily'
        WHEN 1 THEN 'Twice daily'
        WHEN 2 THEN 'Three times daily'
        ELSE 'As needed'
    END AS frequency,
    CASE MOD(ROW_NUMBER() OVER (ORDER BY e.encounter_id, m.seq), 3)
        WHEN 0 THEN 'Oral'
        WHEN 1 THEN 'Topical'
        ELSE 'Inhalation'
    END AS route,
    e.physician_id AS prescribing_physician_id,
    e.admission_date::DATE AS start_date,
    DATEADD(DAY, 30 + MOD(e.encounter_id, 60), e.admission_date)::DATE AS end_date,
    MOD(e.encounter_id, 6) AS refills_remaining,
    MOD(e.encounter_id, 5) + 1 AS pharmacy_id,
    'PHARMACY_SYSTEM' AS source_system
FROM HCLS_DB.RAW_SCHEMA.ENCOUNTERS_RAW e
CROSS JOIN (SELECT 1 AS seq UNION SELECT 2 UNION SELECT 3) m
WHERE e.encounter_id <= 50;

-- =============================================================================
-- VERIFICATION
-- =============================================================================

SELECT 'FACILITIES_RAW' AS table_name, COUNT(*) AS row_count FROM HCLS_DB.RAW_SCHEMA.FACILITIES_RAW
UNION ALL
SELECT 'PHYSICIANS_RAW', COUNT(*) FROM HCLS_DB.RAW_SCHEMA.PHYSICIANS_RAW
UNION ALL
SELECT 'PATIENTS_RAW', COUNT(*) FROM HCLS_DB.RAW_SCHEMA.PATIENTS_RAW
UNION ALL
SELECT 'ENCOUNTERS_RAW', COUNT(*) FROM HCLS_DB.RAW_SCHEMA.ENCOUNTERS_RAW
UNION ALL
SELECT 'LAB_RESULTS_RAW', COUNT(*) FROM HCLS_DB.RAW_SCHEMA.LAB_RESULTS_RAW
UNION ALL
SELECT 'MEDICATIONS_RAW', COUNT(*) FROM HCLS_DB.RAW_SCHEMA.MEDICATIONS_RAW
ORDER BY table_name;

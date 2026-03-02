Hospital Readmission & Clinical Quality Management

Business Problem:
Hospitals get penalized under the Hospital Readmissions Reduction Program by the Centers for Medicare & Medicaid Services (CMS)
What is a readmission?
If a patient:
 	=> Gets discharged from a hospital
 	=> Comes back again within 30 days
That is called a 30-day readmission.

Each preventable readmission costs $15,000–$25,000.
CMS reduces payments to hospitals with high readmission rates.
It affects:
 	=> Hospital revenue
 	=> Hospital reputation
 	=> Clinical quality ratings

Key Questions:

 	=> Which patients are at high risk of readmission?
 	=> Which facilities have the highest readmission rates and why?
 	=> Are there patterns in diagnoses, labs, or medications that predict readmissions?
 	=> How do physician practices affect patient outcomes?

Built a healthcare analytics pipeline to identify high-risk patients for 30-day readmission, reduce CMS penalties, and improve clinical quality metrics using a multi-layered data warehouse architecture.

RAW_SCHEMA                    TRANSFORM_SCHEMA                 ANALYTICS_SCHEMA
┌─────────────────┐          ┌──────────────────────┐         ┌─────────────────────┐
│ PATIENTS_RAW    │    →     │ DIM_PATIENTS         │    →    │ READMISSION_METRICS │
│ ENCOUNTERS_RAW  │    →     │ DIM_FACILITIES       │    →    │ FACILITY_SCORECARD  │
│ FACILITIES_RAW  │    →     │ DIM_PHYSICIANS       │    →    │ PHYSICIAN_QUALITY   │
│ PHYSICIANS_RAW  │    →     │ FACT_ENCOUNTERS      │    →    │ DIAGNOSIS_ANALYSIS  │
│ LAB_RESULTS_RAW │    →     │ FACT_LAB_RESULTS     │         └─────────────────────┘
│ MEDICATIONS_RAW │    →     │ FACT_MEDICATIONS     │
└─────────────────┘          └──────────────────────┘

import streamlit as st
import pandas as pd
import altair as alt

try:
    from snowflake.snowpark.context import get_active_session
    session = get_active_session()
except:
    from snowflake.snowpark import Session
    session = Session.builder.config('connection_name', 'default').create()

st.title("Healthcare Analytics Dashboard")
st.caption("Hospital Readmission & Clinical Quality Management")

@st.cache_data
def load_facility_scorecard(_session):
    return _session.sql("SELECT * FROM HCLS_DB.ANALYTICS_SCHEMA.FACILITY_SCORECARD").to_pandas()

@st.cache_data
def load_readmission_metrics(_session):
    return _session.sql("SELECT * FROM HCLS_DB.ANALYTICS_SCHEMA.READMISSION_METRICS ORDER BY YEAR_MONTH").to_pandas()

@st.cache_data
def load_diagnosis_analysis(_session):
    return _session.sql("SELECT * FROM HCLS_DB.ANALYTICS_SCHEMA.DIAGNOSIS_ANALYSIS ORDER BY READMISSION_RATE_PCT DESC").to_pandas()

@st.cache_data
def load_physician_quality(_session):
    return _session.sql("SELECT * FROM HCLS_DB.ANALYTICS_SCHEMA.PHYSICIAN_QUALITY").to_pandas()

@st.cache_data
def load_patient_risk(_session):
    return _session.sql("SELECT * FROM HCLS_DB.ANALYTICS_SCHEMA.PATIENT_RISK_SUMMARY").to_pandas()

facility_df = load_facility_scorecard(session)
readmission_df = load_readmission_metrics(session)
diagnosis_df = load_diagnosis_analysis(session)
physician_df = load_physician_quality(session)
patient_df = load_patient_risk(session)

tab1, tab2, tab3, tab4, tab5 = st.tabs(["Overview", "Facilities", "Diagnoses", "Physicians", "Patient Risk"])

with tab1:
    col1, col2, col3, col4 = st.columns(4)
    with col1:
        st.metric("Total facilities", len(facility_df))
    with col2:
        st.metric("Total encounters", f"{facility_df['TOTAL_ENCOUNTERS'].sum():,}")
    with col3:
        avg_readmit = facility_df['READMISSION_RATE_PCT'].mean()
        st.metric("Avg readmission rate", f"{avg_readmit:.1f}%")
    with col4:
        high_risk = len(facility_df[facility_df['READMISSION_RISK_TIER'] == 'High Risk'])
        st.metric("High risk facilities", high_risk)
    
    st.subheader("Readmission trends over time")
    trend_df = readmission_df.groupby('YEAR_MONTH').agg({
        'READMISSION_RATE_30_DAY': 'mean',
        'TOTAL_ENCOUNTERS': 'sum'
    }).reset_index()
    st.line_chart(trend_df, x='YEAR_MONTH', y='READMISSION_RATE_30_DAY')
    
    st.subheader("Quality grade distribution")
    grade_counts = facility_df['QUALITY_GRADE'].value_counts().reset_index()
    grade_counts.columns = ['Grade', 'Count']
    st.bar_chart(grade_counts, x='Grade', y='Count')

with tab2:
    st.subheader("Facility scorecard")
    region_filter = st.selectbox("Filter by region", ["All"] + list(facility_df['REGION'].unique()))
    
    filtered_facilities = facility_df if region_filter == "All" else facility_df[facility_df['REGION'] == region_filter]
    
    st.dataframe(
        filtered_facilities[['FACILITY_NAME', 'REGION', 'FACILITY_TYPE', 'TOTAL_ENCOUNTERS', 
                            'READMISSION_RATE_PCT', 'AVG_LENGTH_OF_STAY_DAYS', 'QUALITY_GRADE', 'READMISSION_RISK_TIER']],
        column_config={
            "FACILITY_NAME": "Facility",
            "REGION": "Region",
            "FACILITY_TYPE": "Type",
            "TOTAL_ENCOUNTERS": st.column_config.NumberColumn("Encounters", format="%d"),
            "READMISSION_RATE_PCT": st.column_config.ProgressColumn("Readmission %", min_value=0, max_value=30),
            "AVG_LENGTH_OF_STAY_DAYS": st.column_config.NumberColumn("Avg LOS (days)", format="%.1f"),
            "QUALITY_GRADE": "Grade",
            "READMISSION_RISK_TIER": "Risk tier"
        },
        hide_index=True
    )
    
    st.subheader("Readmission rate by region")
    region_stats = filtered_facilities.groupby('REGION')['READMISSION_RATE_PCT'].mean().reset_index()
    st.bar_chart(region_stats, x='REGION', y='READMISSION_RATE_PCT')

with tab3:
    st.subheader("Diagnosis readmission analysis")
    
    col1, col2 = st.columns(2)
    with col1:
        st.metric("High risk diagnoses", len(diagnosis_df[diagnosis_df['RISK_CLASSIFICATION'] == 'High Risk Diagnosis']))
    with col2:
        st.metric("Total diagnosis codes", len(diagnosis_df))
    
    top_diagnoses = diagnosis_df.head(15)
    st.dataframe(
        top_diagnoses[['DIAGNOSIS_DESCRIPTION', 'DIAGNOSIS_CATEGORY_NAME', 'TOTAL_ENCOUNTERS', 
                       'READMISSION_RATE_PCT', 'RISK_CLASSIFICATION']],
        column_config={
            "DIAGNOSIS_DESCRIPTION": "Diagnosis",
            "DIAGNOSIS_CATEGORY_NAME": "Category",
            "TOTAL_ENCOUNTERS": st.column_config.NumberColumn("Encounters", format="%d"),
            "READMISSION_RATE_PCT": st.column_config.ProgressColumn("Readmission %", min_value=0, max_value=50),
            "RISK_CLASSIFICATION": "Risk level"
        },
        hide_index=True
    )

with tab4:
    st.subheader("Physician performance")
    
    specialty_filter = st.selectbox("Filter by specialty", ["All"] + list(physician_df['SPECIALTY'].dropna().unique()))
    filtered_physicians = physician_df if specialty_filter == "All" else physician_df[physician_df['SPECIALTY'] == specialty_filter]
    
    col1, col2, col3 = st.columns(3)
    with col1:
        st.metric("Total physicians", len(filtered_physicians))
    with col2:
        excellent = len(filtered_physicians[filtered_physicians['PERFORMANCE_RATING'] == 'Excellent'])
        st.metric("Excellent performers", excellent)
    with col3:
        needs_improve = len(filtered_physicians[filtered_physicians['PERFORMANCE_RATING'] == 'Needs Improvement'])
        st.metric("Needs improvement", needs_improve)
    
    st.dataframe(
        filtered_physicians[['PHYSICIAN_NAME', 'SPECIALTY', 'FACILITY_NAME', 'TOTAL_ENCOUNTERS',
                            'READMISSION_RATE_PCT', 'PERFORMANCE_RATING']].head(20),
        column_config={
            "PHYSICIAN_NAME": "Physician",
            "SPECIALTY": "Specialty",
            "FACILITY_NAME": "Facility",
            "TOTAL_ENCOUNTERS": st.column_config.NumberColumn("Encounters", format="%d"),
            "READMISSION_RATE_PCT": st.column_config.ProgressColumn("Readmission %", min_value=0, max_value=30),
            "PERFORMANCE_RATING": "Rating"
        },
        hide_index=True
    )

with tab5:
    st.subheader("Patient risk stratification")
    
    col1, col2, col3 = st.columns(3)
    with col1:
        high_risk_patients = len(patient_df[patient_df['RISK_TIER'] == 'High'])
        st.metric("High risk patients", f"{high_risk_patients:,}")
    with col2:
        medium_risk = len(patient_df[patient_df['RISK_TIER'] == 'Medium'])
        st.metric("Medium risk patients", f"{medium_risk:,}")
    with col3:
        low_risk = len(patient_df[patient_df['RISK_TIER'] == 'Low'])
        st.metric("Low risk patients", f"{low_risk:,}")
    
    risk_filter = st.selectbox("Filter by risk tier", ["All", "High", "Medium", "Low"])
    filtered_patients = patient_df if risk_filter == "All" else patient_df[patient_df['RISK_TIER'] == risk_filter]
    
    st.dataframe(
        filtered_patients[['PATIENT_ID', 'AGE_GROUP', 'RISK_SCORE', 'RISK_TIER', 
                          'READMISSION_COUNT', 'EMERGENCY_VISITS', 'ACTIVE_MEDICATIONS']].head(50),
        column_config={
            "PATIENT_ID": "Patient ID",
            "AGE_GROUP": "Age group",
            "RISK_SCORE": st.column_config.ProgressColumn("Risk score", min_value=0, max_value=100),
            "RISK_TIER": "Risk tier",
            "READMISSION_COUNT": st.column_config.NumberColumn("Readmissions", format="%d"),
            "EMERGENCY_VISITS": st.column_config.NumberColumn("ER visits", format="%d"),
            "ACTIVE_MEDICATIONS": st.column_config.NumberColumn("Active meds", format="%d")
        },
        hide_index=True
    )
    
    st.subheader("Risk distribution by age group")
    risk_by_age = patient_df.groupby(['AGE_GROUP', 'RISK_TIER']).size().reset_index(name='COUNT')
    chart = alt.Chart(risk_by_age).mark_bar().encode(
        x='AGE_GROUP:N',
        y='COUNT:Q',
        color='RISK_TIER:N'
    ).properties(height=300)
    st.altair_chart(chart, use_container_width=True)

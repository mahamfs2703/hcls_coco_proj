Account-Level Security Configuration Documentation

1. Document Overview
Script Name: AccAdmin.sql
Required Role: ACCOUNTADMIN
Environment: Healthcare / Life Sciences (HCLS) Snowflake Environment
Purpose
This script establishes centralized account-level security controls in Snowflake. It configures foundational security infrastructure to ensure:
•	IP-based access control
•	Session timeout enforcement
•	Password complexity enforcement
•	Multi-Factor Authentication (MFA) enforcement
•	Secure account parameter configuration

2. Prerequisites
Before executing this script:
•	User must have ACCOUNTADMIN role.
•	No conflicting network, password, session, or authentication policies should already be set at the account level.
•	Execution should be performed in a controlled environment (preferably lower environment before production).

3. Objects Created
3.1 Database and Schema
OBJECT	NAME
Database	SECURITY_DB
Schema	SECURITY_DB.NETWORK_SECURITY

This schema centralizes all security-related objects for easier governance and auditing.

4. Network Security Configuration
4.1 Network Rule
Name: SECURITY_DB.NETWORK_SECURITY.HCLS_ALLOWED_IPS_RULE
Purpose: Defines allowed IP ranges for inbound Snowflake access
Current Configuration:
0.0.0.0/0

4.2 Network Policy
Name: HCLS_NETWORK_POLICY
Purpose:
Applies IP-based access control at the account level by referencing the defined network rule.
References:
•	HCLS_ALLOWED_IPS_RULE

5. Session Policies
Session policies enforce automatic timeout to reduce risk from unattended sessions.
Policy Name	Idle Timeout	UI Idle Timeout	Intended Users
STANDARD_SESSION_POLICY	30 minutes	15 minutes	General users
STRICT_SESSION_POLICY	15 minutes	10 minutes	Administrators / Sensitive roles

6. Password Policies
Password policies enforce credential complexity and rotation standards.
6.1 Standard Password Policy
Setting	Value
Minimum Length	12 characters
Password Expiry	90 days
Lockout	30 minutes after 5 failed attempts
Password History	12 previous passwords
Complexity Requirements:
•	Minimum 1 uppercase letter
•	Minimum 1 lowercase letter
•	Minimum 1 numeric character
•	Minimum 1 special character

6.2 Strict Password Policy
Setting	Value
Minimum Length	16 characters
Password Expiry	60 days
Lockout	60 minutes after 3 failed attempts
Password History	24 previous passwords
Complexity Requirements:
•	Minimum 2 uppercase letters
•	Minimum 2 lowercase letters
•	Minimum 2 numeric characters
•	Minimum 2 special characters
Intended For:
Administrator and high-privilege accounts.

7. Authentication Policies
Authentication policies enforce MFA and control client access methods.
Policy Name	MFA Requirement	Allowed Clients	Intended Use
MFA_REQUIRED_POLICY	Required	UI, SnowSQL, Drivers	Interactive users
SERVICE_ACCOUNT_POLICY	Optional	Drivers only	ETL / Service accounts

8. Account-Level Parameters Modified
Parameter	Value	Description
CLIENT_SESSION_KEEP_ALIVE	FALSE	Disables indefinite session persistence
SESSION_POLICY_EVAL_ON_LOGIN	TRUE	Evaluates session policy at login
Default Password Policy	STANDARD_PASSWORD_POLICY	Account-level default
Default Session Policy	STANDARD_SESSION_POLICY	Account-level default


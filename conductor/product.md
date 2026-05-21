# Initial Concept

we are doing a project for the Banco de Dados subject. there is a minimundo already and we are following ppp1 and mad1. there is also a pdf with instructions and with everything that will be evaluated. I'd like you to study it all so that we can begin the project

# Product Definition

## Vision
To develop a robust and efficient database system for the Institute of Computing to manage university extension activities, ensuring accurate tracking of participation, automated certificate issuance, and comprehensive management of partnerships and projects.

## Target Users
- **Administrative Staff**: Primary users responsible for managing activities, tracking enrollments, and generating management reports.
- **Instructors/Docents**: Secondary users who conduct activities and may need to verify attendance or submit grades.
- **Participants/Students**: The ultimate beneficiaries of the system, whose participation and achievements are recorded.

## Goals and Success Factors
- **Operational Efficiency**: Streamline the management of activities, enrollments, and certificates to replace manual processes.
- **Accuracy and Reliability**: Ensure that all records, especially certificates and attendance, are precise and verifiable.
- **Comprehensive Tracking**: Maintain a full history of extensions, including grades for evaluative courses and social impact via partner management.

## Core Features
- **Activity & Project Management**: Tracking dates, speakers, contents, and affiliation with larger extension projects.
- **Enrollment & Attendance System**: Handling registrations, presence control, and historical participation data.
- **Academic & Grading Module**: Managing grades for evaluative minicourses or extension programs.
- **Automated Certification**: Generating unique hashes and records for automatic certificate issuance.
- **Partner & Sponsorship Tracking**: Managing relationships with companies and NGOs, including financial support records.

## Scope & Constraints
- **PostgreSQL**: The mandatory Relational Database Management System.
- **Governance (MAD/IBAMA)**: Strict adherence to naming conventions (prefixed, uppercase, singular, ANSI SQL).
- **Data Volume**: Implementation must support at least 5,000 synthetic records in key tables for performance testing and evaluation.

# Technology Stack

This document specifies the tools and technologies used in the development and implementation of the IC Extension Management database.

## 1. Database Management System (DBMS)
- **Engine**: **PostgreSQL** (Mandatory).
- **Dialect**: **ANSI SQL Only**. Per project rules, the use of proprietary PostgreSQL extensions should be avoided in favor of standard SQL to ensure portability and compliance with academic requirements.
- **Constraint**: Remote connection via general-purpose languages (Python, Java, etc.) is strictly prohibited. All operations must be performed using SQL directly.

## 2. Modeling and Design
- **Tool**: **BrModelo**.
- **Notation**: **Peter Chen** (Conceptual Model).
- **Strategy**: Conceptual modeling will be translated into a Relational Logical Model and then into a Physical Model (DDL).

## 3. Administration and Development
- **Database Client**: **pgAdmin 4**.
- **Version Control**: **Git**.

## 4. Data Generation and Testing
- **Strategy**: **Custom SQL Scripts**.
- **Volume**: At least 5,000 records will be generated using custom SQL scripts to ensure the database is properly populated for performance evaluation.

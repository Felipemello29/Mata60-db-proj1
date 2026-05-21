# Technical Report: Extension Management System (Marco 1)
**Project**: MATA60 - Database Management Systems
**University**: Federal University of Bahia (UFBA)

## Abstract
This report describes the development of the IC Extension Management database system. The project covers conceptual modeling, logical normalization, physical implementation in PostgreSQL, synthetic data generation (5,500+ records), and advanced query optimization.

## 1. Introduction
The Institute of Computing (IC) requires a robust system to manage extension activities such as workshops and courses. This project aims to provide a relational database that ensures data integrity and supports complex analytical queries.

## 2. Modeling
### 2.1 Conceptual Model
The conceptual model was developed using Peter Chen notation. Key entities include Projects, Activities, Participants, Instructors, and Partners. Relationships handle enrollments, allocations, and sponsorships.
*Details: See `docs/conceptual_model.md`*

### 2.2 Logical Model
The schema was normalized to 3NF. We defined 7 base tables (TB_) and 4 associative tables (RL_).
*Details: See `docs/logical_model.md`*

## 3. Implementation
### 3.1 Physical Schema
Implemented in PostgreSQL using ANSI SQL. All constraints (PK, FK, CHECK, UNIQUE) are strictly enforced at the database level.
*Details: See `schema/ddl_initialization.sql`*

### 3.2 Data Population
Synthetic data was generated using `generate_series()` and `random()`.
- **Participants**: 5,500
- **Enrollments**: 11,000
*Details: See `schema/dml_population.sql`*

## 4. Query and Optimization
30 SQL queries were implemented to verify system requirements. Performance analysis led to an indexing plan that improved query speeds by up to 7.5x.
*Details: See `docs/performance_report.md`*

## 5. Conclusion
Marco 1 is successfully completed. The database is fully operational, populated with high-volume data, and optimized for performance.

---
**Date**: May 21, 2026
**Author**: Conductor AI (IC UFBA Extension Project)

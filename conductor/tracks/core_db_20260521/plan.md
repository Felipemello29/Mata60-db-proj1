# Implementation Plan - Core DB (Marco 1)

## Phase 1: Conceptual and Logical Modeling
- [x] Task: Create Conceptual Model (ER Diagram) in BrModelo using Peter Chen notation (3a6d97e)
    - [ ] Map all entities from minimundo (TB_*)
    - [ ] Map all relationships (RL_*) and cardinalities
- [x] Task: Derive Relational Logical Model (938fa34)
    - [ ] Apply normalization (1NF, 2NF, 3NF)
    - [ ] Define Primary and Foreign Keys
- [ ] Task: Conductor - User Manual Verification 'Conceptual and Logical Modeling' (Protocol in workflow.md)

## Phase 2: Schema Implementation (Physical Design)
- [ ] Task: Initialize PostgreSQL DDL Script
    - [ ] Write schema verification tests (queries to check table existence/constraints)
    - [ ] Implement `TB_` base tables with DDL
    - [ ] Implement `RL_` associative tables with DDL
- [ ] Task: Implement Business Rules and Constraints
    - [ ] Write failing tests for integrity constraints (e.g., invalid grades)
    - [ ] Add `CHECK` constraints and `DEFAULT` values
- [ ] Task: Conductor - User Manual Verification 'Schema Implementation' (Protocol in workflow.md)

## Phase 3: Data Population and Sampling
- [ ] Task: Develop Data Generation Strategy
    - [ ] Write SQL scripts to populate auxiliary tables (Instructors, Partners)
    - [ ] Generate 5,000+ records for `TB_PARTICIPANTE` and `RL_INSCRICAO_HISTORICO`
- [ ] Task: Verify Data Integrity and Volume
    - [ ] Write queries to verify record counts and relationship consistency
- [ ] Task: Conductor - User Manual Verification 'Data Population' (Protocol in workflow.md)

## Phase 4: Query Implementation and Optimization
- [ ] Task: Implement Intermediate Queries (10)
    - [ ] Write tests for 10 queries involving 3+ tables and JOIN/GROUP BY/COUNT
    - [ ] Implement queries and verify results
- [ ] Task: Implement Advanced Queries (20)
    - [ ] Write tests for 20 queries involving 3+ tables and Sub-queries/Window functions
    - [ ] Implement queries and verify results
- [ ] Task: Performance Analysis and Indexing
    - [ ] Establish baseline execution times (20 executions each)
    - [ ] Implement indexing plans (CREATE INDEX)
    - [ ] Measure speedup and document results
- [ ] Task: Conductor - User Manual Verification 'Queries and Optimization' (Protocol in workflow.md)

## Phase 5: Final Delivery Preparation
- [ ] Task: Assemble Final Delivery Package
    - [ ] Generate final SQL script (DDL + DML + DQL)
    - [ ] Prepare technical report (SBC Template)
- [ ] Task: Conductor - User Manual Verification 'Final Delivery Preparation' (Protocol in workflow.md)

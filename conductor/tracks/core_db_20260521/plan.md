# Implementation Plan - Core DB (Marco 1)

## Phase 1: Conceptual and Logical Modeling [checkpoint: 227a81a]
- [x] Task: Create Conceptual Model (ER Diagram) in BrModelo using Peter Chen notation (3a6d97e)
    - [ ] Map all entities from minimundo (TB_*)
    - [ ] Map all relationships (RL_*) and cardinalities
- [x] Task: Derive Relational Logical Model (938fa34)
    - [ ] Apply normalization (1NF, 2NF, 3NF)
    - [ ] Define Primary and Foreign Keys
- [x] Task: Conductor - User Manual Verification 'Conceptual and Logical Modeling' (Protocol in workflow.md) (227a81a)

## Phase 2: Schema Implementation (Physical Design) [checkpoint: 7f46f37]
- [x] Task: Initialize PostgreSQL DDL Script (e60ddc7)
    - [ ] Write schema verification tests (queries to check table existence/constraints)
    - [ ] Implement `TB_` base tables with DDL
    - [ ] Implement `RL_` associative tables with DDL
- [x] Task: Implement Business Rules and Constraints (102f033)
    - [ ] Write failing tests for integrity constraints (e.g., invalid grades)
    - [ ] Add `CHECK` constraints and `DEFAULT` values
- [x] Task: Conductor - User Manual Verification 'Schema Implementation' (Protocol in workflow.md) (7f46f37)

## Phase 3: Data Population and Sampling [checkpoint: 995d2cb]
- [x] Task: Develop Data Generation Strategy (6066bef)
    - [x] Write SQL scripts to populate auxiliary tables (Instructors, Partners)
    - [x] Generate 5,000+ records for `TB_PARTICIPANTE` and `RL_INSCRICAO_HISTORICO`
- [x] Task: Verify Data Integrity and Volume (5b35b54)
    - [ ] Write queries to verify record counts and relationship consistency
- [x] Task: Conductor - User Manual Verification 'Data Population' (Protocol in workflow.md) (995d2cb)

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

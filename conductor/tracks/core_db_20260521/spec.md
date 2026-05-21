# Specification: Design and implement the core extension management database (Marco 1)

## 1. Overview
This track focuses on the complete design and implementation of the database system for the Institute of Computing's extension activities, covering everything required for **Marco 1** of the MATA60 project.

## 2. Objectives
- Elaborate a **Conceptual Model** using Peter Chen notation (via BrModelo).
- Define a **Logical Model** and translate it into a **Physical Model** (PostgreSQL).
- Implement the schema with strict **MAD/IBAMA** naming conventions.
- Populate the database with at least **5,000 synthetic records** for core tables.
- Develop **30 SQL queries** (10 intermediate, 20 advanced) to verify requirements.
- Produce a **Performance Report** based on indexing plans.

## 3. Scope and Entities
Based on the `minimundo-prj1.md`, the following entities will be implemented:

### Base Tables (TB_)
- `TB_PROJETO_EXTENSAO`: Main institutional projects.
- `TB_ATIVIDADE`: Specific events, courses, workshops.
- `TB_PARTICIPANTE`: Students and community members.
- `TB_INSTRUTOR`: Teachers and speakers.
- `TB_PARCEIRO`: Companies and NGOs.
- `TB_EMISSAO_CERTIFICADO`: Transactional records for certificates.
- `TB_REGISTRO_FEEDBACK`: Evaluation records.

### Associative Tables (RL_)
- `RL_INSCRICAO_HISTORICO`: Links Participants to Activities (includes grades/attendance).
- `RL_ALOCACAO_INSTRUTOR`: Links Activities to multiple Instructors.
- `RL_PATROCINIO_EVENTO`: Links Partners to Activities.
- `RL_MEMBRO_PROJETO`: Links Participants to Projects.

## 4. Technical Requirements
- **DBMS**: PostgreSQL.
- **SQL Dialect**: ANSI SQL Only.
- **Naming**: Uppercase, singular, prefixes `TB_` and `RL_`, no special characters.
- **Integrity**: Primary Keys, Foreign Keys, and Check Constraints (e.g., scores 1-5).
- **Data Volume**: 5,000+ records in at least two relationships.

## 5. Acceptance Criteria
- [ ] ER Diagram in Peter Chen notation approved.
- [ ] SQL DDL script executes without errors and creates all 11+ tables.
- [ ] Database is populated with 5,000+ records in key tables.
- [ ] 30 queries are implemented and verified against requirements.
- [ ] Indexing plan shows measurable speedup (average of 20 executions).
- [ ] Final report follows SBC template guidelines.

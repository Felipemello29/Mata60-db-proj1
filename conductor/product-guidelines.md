# Product Guidelines

This document outlines the design principles, documentation standards, and development guidelines for the IC Extension Management database project.

## 1. Communication and Prose Style
- **Tone**: Descriptive & Educational. Since this is an academic project, documentation should not only state the "what" but also explain the "why" and "how".
- **Clarity**: Use clear, formal Portuguese to describe requirements, design decisions, and implementation details.
- **Contextualization**: Every database object (table, view, procedure) must be accompanied by a descriptive comment explaining its role in the extension management context.

## 2. Naming Conventions (Core Compliance)
- **Primary Schema**: All permanent tables must follow the `TB_` prefix for base tables and `RL_` for associative tables as defined in the minimundo.
- **Formatting**: Identifiers must be in UPPERCASE, singular, and without accents, using underscores as separators (e.g., `TB_ATIVIDADE`).
- **Identifiers**: Maximum of 30 characters per identifier to ensure compatibility and readability.
- **Consistency**: Scripts and temporary objects should maintain a logical structure, even if they don't strictly require the `TB_`/`RL_` prefixes during the initial drafting phase.

## 3. Data Integrity and Modeling
- **Strict Enforcement**: Use the database engine to its full potential. Every relationship must be enforced by Foreign Keys.
- **Constraints**: Apply `CHECK` constraints for value ranges (e.g., feedback scores 1-5), `NOT NULL` for mandatory fields, and `UNIQUE` for business keys (e.g., email, authenticity codes).
- **Peter Chen Model**: Conceptual modeling must strictly adhere to the Peter Chen notation as specified in the course requirements.

## 4. Documentation Standards
- **Visual Mapping**: Use a combination of formats for maximum clarity:
    - **Mermaid Diagrams**: For Entity-Relationship and Flow diagrams.
    - **Markdown Tables**: For data dictionaries and requirements mapping.
    - **Relational Algebra**: For explicit specification of complex queries and operations.
- **Traceability**: All implementation artifacts (SQL scripts) must be traceable back to the requirements defined in the `product.md`.

## 5. Development Workflow
- **PostgreSQL Focus**: Use ANSI SQL with PostgreSQL-specific optimizations where justified.
- **Data Population**: Ensure a minimum of 5,000 records for core tables to test performance and constraint behavior.

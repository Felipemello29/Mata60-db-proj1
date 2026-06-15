-- IC Extension Management Database - Roles and Permissions
-- Compliant with PPP1 Rules
-- DBMS: PostgreSQL

-- 1. Create Roles

-- DBA Role (Admin)
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'dba_ic') THEN
    CREATE ROLE dba_ic WITH SUPERUSER CREATEDB CREATEROLE LOGIN PASSWORD 'admin_password';
  END IF;
END $$;

-- Sistema Role (Application)
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'sistema_ic') THEN
    CREATE ROLE sistema_ic WITH LOGIN PASSWORD 'sys_password';
  END IF;
END $$;

-- Análise Role (Data Analyst)
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'analise_ic') THEN
    CREATE ROLE analise_ic WITH LOGIN PASSWORD 'analyst_password';
  END IF;
END $$;

-- Backup Role (Backup Operator)
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'dbbackup_ic') THEN
    CREATE ROLE dbbackup_ic WITH LOGIN PASSWORD 'backup_password';
  END IF;
END $$;

-- 2. Grant Permissions

-- Permissions for Sistema (DML only on business tables)
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO sistema_ic;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO sistema_ic;
-- Explicitly revoke access from audit tables to avoid spoofing
REVOKE ALL PRIVILEGES ON TA_TB_ATIVIDADE FROM sistema_ic;
REVOKE ALL PRIVILEGES ON TA_RL_INSCRICAO_HISTORICO FROM sistema_ic;
REVOKE ALL PRIVILEGES ON TA_TB_PARTICIPANTE FROM sistema_ic;
REVOKE ALL PRIVILEGES ON TA_TB_PROJETO_EXTENSAO FROM sistema_ic;
REVOKE ALL PRIVILEGES ON TA_TB_INSTRUTOR FROM sistema_ic;
REVOKE ALL PRIVILEGES ON TA_TB_PARCEIRO FROM sistema_ic;
REVOKE ALL PRIVILEGES ON TA_TB_EMISSAO_CERTIFICADO FROM sistema_ic;
REVOKE ALL PRIVILEGES ON TA_TB_REGISTRO_FEEDBACK FROM sistema_ic;
REVOKE ALL PRIVILEGES ON TA_RL_ALOCACAO_INSTRUTOR FROM sistema_ic;
REVOKE ALL PRIVILEGES ON TA_RL_PATROCINIO_EVENTO FROM sistema_ic;
REVOKE ALL PRIVILEGES ON TA_RL_MEMBRO_PROJETO FROM sistema_ic;

-- Permissions for Análise (SELECT only)
GRANT SELECT ON ALL TABLES IN SCHEMA public TO analise_ic;
-- Analysts can read audit tables if needed, but not modify them
REVOKE INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public FROM analise_ic;

-- Permissions for Backup
GRANT SELECT ON ALL TABLES IN SCHEMA public TO dbbackup_ic;
REVOKE INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public FROM dbbackup_ic;

-- Restrict audit table access (MAD1 §7: only AD and DBA teams)


-- Set default privileges for future tables (Commented out for security)
-- ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO sistema_ic;
-- ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO analise_ic;
-- ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO dbbackup_ic;
-- NOTE: If uncommented, these defaults will automatically grant privileges to future audit tables in public schema.

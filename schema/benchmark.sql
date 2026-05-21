-- IC Extension Management - Performance Benchmark Script
-- DBMS: PostgreSQL
-- Purpose: Collect execution times for all 30 queries, with and without indexes,
--          to calculate mean, standard deviation, and speedup.
-- 
-- INSTRUCTIONS:
-- 1. First, run ddl_initialization.sql and dml_population.sql on a clean database.
-- 2. Then run this script. It will:
--    a) Drop all non-PK/non-UNIQUE indexes (baseline).
--    b) Run each query 20 times and record times.
--    c) Create all indexes from the indexing plan.
--    d) Run each query 20 times again.
--    e) Output a summary report with mean, stddev, and speedup.

-- ============================================================================
-- SETUP: Create temp table for results
-- ============================================================================

DROP TABLE IF EXISTS benchmark_results;
CREATE TABLE benchmark_results (
    query_id INT,
    query_type VARCHAR(20),  -- 'intermediate' or 'advanced'
    run_number INT,
    phase VARCHAR(20),       -- 'baseline' or 'indexed'
    execution_time_ms NUMERIC(12,4)
);

-- ============================================================================
-- PHASE 1: DROP ALL NON-PK INDEXES (BASELINE)
-- ============================================================================

DROP INDEX IF EXISTS IDX_PROJETO_COORDENADOR;
DROP INDEX IF EXISTS IDX_ATIVIDADE_PROJETO;
DROP INDEX IF EXISTS IDX_INSCRICAO_PARTICIPANTE;
DROP INDEX IF EXISTS IDX_INSCRICAO_ATIVIDADE;
DROP INDEX IF EXISTS IDX_CERTIFICADO_INSCRICAO;
DROP INDEX IF EXISTS IDX_FEEDBACK_INSCRICAO;
DROP INDEX IF EXISTS IDX_PARTICIPANTE_EMAIL;
DROP INDEX IF EXISTS IDX_INSCRICAO_PRESENCA;
DROP INDEX IF EXISTS IDX_ATIVIDADE_DATA;
DROP INDEX IF EXISTS IDX_INSCRICAO_PRESENCA_NOTA;

-- ============================================================================
-- PHASE 2: BASELINE BENCHMARK (No indexes except PKs)
-- ============================================================================
-- Each query is run 20 times inside a DO block. We use clock_timestamp()
-- for precise wall-clock timing.

-- IMPORTANT NOTE FOR EXECUTION:
-- Run each DO block below. Replace the PERFORM(...) with the actual query.
-- The queries are referenced by number matching intermediate_queries.sql
-- and advanced_queries.sql.

-- ---------- INTERMEDIATE QUERIES (1-10) ----------

DO $$
DECLARE
    start_ts TIMESTAMP;
    end_ts TIMESTAMP;
    r RECORD;
BEGIN
    FOR run IN 1..20 LOOP
        -- Query Int-1: Participants enrolled per project
        start_ts := clock_timestamp();
        FOR r IN
            SELECT p.DS_NOME_PARTICIPANTE, proj.DS_NOME_PROJETO, COUNT(i.ID_INSCRICAO) as total_inscricoes
            FROM TB_PARTICIPANTE p
            JOIN RL_INSCRICAO_HISTORICO i ON p.ID_PARTICIPANTE = i.ID_PARTICIPANTE
            JOIN TB_ATIVIDADE a ON i.ID_ATIVIDADE = a.ID_ATIVIDADE
            JOIN TB_PROJETO_EXTENSAO proj ON a.ID_PROJ_VINCULADO = proj.ID_PROJETO
            WHERE proj.ID_PROJETO = 1
            GROUP BY p.DS_NOME_PARTICIPANTE, proj.DS_NOME_PROJETO
        LOOP NULL; END LOOP;
        end_ts := clock_timestamp();
        INSERT INTO benchmark_results VALUES (1, 'intermediate', run, 'baseline',
            EXTRACT(EPOCH FROM end_ts - start_ts) * 1000);
    END LOOP;
END $$;

DO $$
DECLARE
    start_ts TIMESTAMP;
    end_ts TIMESTAMP;
    r RECORD;
BEGIN
    FOR run IN 1..20 LOOP
        -- Query Int-2: Activities per project with coordinator
        start_ts := clock_timestamp();
        FOR r IN
            SELECT proj.DS_NOME_PROJETO, inst.DS_NOME_INSTRUTOR AS coordenador, COUNT(a.ID_ATIVIDADE) as total_atividades
            FROM TB_PROJETO_EXTENSAO proj
            JOIN TB_INSTRUTOR inst ON proj.ID_INSTR_COORDENADOR = inst.ID_INSTRUTOR
            LEFT JOIN TB_ATIVIDADE a ON proj.ID_PROJETO = a.ID_PROJ_VINCULADO
            GROUP BY proj.DS_NOME_PROJETO, inst.DS_NOME_INSTRUTOR
        LOOP NULL; END LOOP;
        end_ts := clock_timestamp();
        INSERT INTO benchmark_results VALUES (2, 'intermediate', run, 'baseline',
            EXTRACT(EPOCH FROM end_ts - start_ts) * 1000);
    END LOOP;
END $$;

DO $$
DECLARE
    start_ts TIMESTAMP;
    end_ts TIMESTAMP;
    r RECORD;
BEGIN
    FOR run IN 1..20 LOOP
        -- Query Int-3: Instructor workload across activities
        start_ts := clock_timestamp();
        FOR r IN
            SELECT inst.DS_NOME_INSTRUTOR, SUM(alloc.VL_CARGA_HORARIA) as total_horas, COUNT(a.ID_ATIVIDADE) as total_atividades
            FROM TB_INSTRUTOR inst
            JOIN RL_ALOCACAO_INSTRUTOR alloc ON inst.ID_INSTRUTOR = alloc.ID_INSTRUTOR
            JOIN TB_ATIVIDADE a ON alloc.ID_ATIVIDADE = a.ID_ATIVIDADE
            GROUP BY inst.DS_NOME_INSTRUTOR
        LOOP NULL; END LOOP;
        end_ts := clock_timestamp();
        INSERT INTO benchmark_results VALUES (3, 'intermediate', run, 'baseline',
            EXTRACT(EPOCH FROM end_ts - start_ts) * 1000);
    END LOOP;
END $$;

DO $$
DECLARE
    start_ts TIMESTAMP;
    end_ts TIMESTAMP;
    r RECORD;
BEGIN
    FOR run IN 1..20 LOOP
        -- Query Int-4: Partner sponsorship with activities
        start_ts := clock_timestamp();
        FOR r IN
            SELECT part.DS_NOME_ORGANIZACAO, SUM(pat.VL_APORTE) as total_patrocinio, COUNT(a.ID_ATIVIDADE) as total_atividades
            FROM TB_PARCEIRO part
            JOIN RL_PATROCINIO_EVENTO pat ON part.ID_PARCEIRO = pat.ID_PARCEIRO
            JOIN TB_ATIVIDADE a ON pat.ID_ATIVIDADE = a.ID_ATIVIDADE
            GROUP BY part.DS_NOME_ORGANIZACAO
        LOOP NULL; END LOOP;
        end_ts := clock_timestamp();
        INSERT INTO benchmark_results VALUES (4, 'intermediate', run, 'baseline',
            EXTRACT(EPOCH FROM end_ts - start_ts) * 1000);
    END LOOP;
END $$;

DO $$
DECLARE
    start_ts TIMESTAMP;
    end_ts TIMESTAMP;
    r RECORD;
BEGIN
    FOR run IN 1..20 LOOP
        -- Query Int-5: Participants who attended >= 2 activities
        start_ts := clock_timestamp();
        FOR r IN
            SELECT p.DS_NOME_PARTICIPANTE, COUNT(a.ID_ATIVIDADE) as total_presencas
            FROM TB_PARTICIPANTE p
            JOIN RL_INSCRICAO_HISTORICO i ON p.ID_PARTICIPANTE = i.ID_PARTICIPANTE
            JOIN TB_ATIVIDADE a ON i.ID_ATIVIDADE = a.ID_ATIVIDADE
            WHERE i.ST_PRESENCA = 'PRESENTE'
            GROUP BY p.DS_NOME_PARTICIPANTE
            HAVING COUNT(a.ID_ATIVIDADE) >= 2
        LOOP NULL; END LOOP;
        end_ts := clock_timestamp();
        INSERT INTO benchmark_results VALUES (5, 'intermediate', run, 'baseline',
            EXTRACT(EPOCH FROM end_ts - start_ts) * 1000);
    END LOOP;
END $$;

DO $$
DECLARE
    start_ts TIMESTAMP;
    end_ts TIMESTAMP;
    r RECORD;
BEGIN
    FOR run IN 1..20 LOOP
        -- Query Int-6: Average grade per activity per project
        start_ts := clock_timestamp();
        FOR r IN
            SELECT a.DS_TITULO_ATIVIDADE, proj.DS_NOME_PROJETO, AVG(i.VL_NOTA_AVALIACAO) as media_nota
            FROM TB_ATIVIDADE a
            JOIN RL_INSCRICAO_HISTORICO i ON a.ID_ATIVIDADE = i.ID_ATIVIDADE
            JOIN TB_PROJETO_EXTENSAO proj ON a.ID_PROJ_VINCULADO = proj.ID_PROJETO
            GROUP BY a.DS_TITULO_ATIVIDADE, proj.DS_NOME_PROJETO
            HAVING COUNT(i.ID_INSCRICAO) > 5
        LOOP NULL; END LOOP;
        end_ts := clock_timestamp();
        INSERT INTO benchmark_results VALUES (6, 'intermediate', run, 'baseline',
            EXTRACT(EPOCH FROM end_ts - start_ts) * 1000);
    END LOOP;
END $$;

DO $$
DECLARE
    start_ts TIMESTAMP;
    end_ts TIMESTAMP;
    r RECORD;
BEGIN
    FOR run IN 1..20 LOOP
        -- Query Int-7: Coordinator activity count
        start_ts := clock_timestamp();
        FOR r IN
            SELECT inst.DS_NOME_INSTRUTOR, COUNT(a.ID_ATIVIDADE) as total_atividades
            FROM TB_ATIVIDADE a
            JOIN TB_PROJETO_EXTENSAO proj ON a.ID_PROJ_VINCULADO = proj.ID_PROJETO
            JOIN TB_INSTRUTOR inst ON proj.ID_INSTR_COORDENADOR = inst.ID_INSTRUTOR
            GROUP BY inst.DS_NOME_INSTRUTOR
        LOOP NULL; END LOOP;
        end_ts := clock_timestamp();
        INSERT INTO benchmark_results VALUES (7, 'intermediate', run, 'baseline',
            EXTRACT(EPOCH FROM end_ts - start_ts) * 1000);
    END LOOP;
END $$;

DO $$
DECLARE
    start_ts TIMESTAMP;
    end_ts TIMESTAMP;
    r RECORD;
BEGIN
    FOR run IN 1..20 LOOP
        -- Query Int-8: Certificates per activity
        start_ts := clock_timestamp();
        FOR r IN
            SELECT a.DS_TITULO_ATIVIDADE, COUNT(cert.ID_CERTIFICADO) as total_certificados
            FROM TB_ATIVIDADE a
            JOIN RL_INSCRICAO_HISTORICO i ON a.ID_ATIVIDADE = i.ID_ATIVIDADE
            JOIN TB_EMISSAO_CERTIFICADO cert ON i.ID_INSCRICAO = cert.ID_INSCRICAO
            GROUP BY a.DS_TITULO_ATIVIDADE
        LOOP NULL; END LOOP;
        end_ts := clock_timestamp();
        INSERT INTO benchmark_results VALUES (8, 'intermediate', run, 'baseline',
            EXTRACT(EPOCH FROM end_ts - start_ts) * 1000);
    END LOOP;
END $$;

DO $$
DECLARE
    start_ts TIMESTAMP;
    end_ts TIMESTAMP;
    r RECORD;
BEGIN
    FOR run IN 1..20 LOOP
        -- Query Int-9: Participant feedback aggregation
        start_ts := clock_timestamp();
        FOR r IN
            SELECT p.DS_NOME_PARTICIPANTE, COUNT(f.ID_FEEDBACK) as total_feedbacks, AVG(f.VL_NOTA_SATISFACAO) as media_satisfacao
            FROM TB_PARTICIPANTE p
            JOIN RL_INSCRICAO_HISTORICO i ON p.ID_PARTICIPANTE = i.ID_PARTICIPANTE
            JOIN TB_REGISTRO_FEEDBACK f ON i.ID_INSCRICAO = f.ID_INSCRICAO
            GROUP BY p.DS_NOME_PARTICIPANTE
        LOOP NULL; END LOOP;
        end_ts := clock_timestamp();
        INSERT INTO benchmark_results VALUES (9, 'intermediate', run, 'baseline',
            EXTRACT(EPOCH FROM end_ts - start_ts) * 1000);
    END LOOP;
END $$;

DO $$
DECLARE
    start_ts TIMESTAMP;
    end_ts TIMESTAMP;
    r RECORD;
BEGIN
    FOR run IN 1..20 LOOP
        -- Query Int-10: Project members with names
        start_ts := clock_timestamp();
        FOR r IN
            SELECT proj.DS_NOME_PROJETO, COUNT(mem.ID_PARTICIPANTE) as total_membros
            FROM TB_PROJETO_EXTENSAO proj
            JOIN RL_MEMBRO_PROJETO mem ON proj.ID_PROJETO = mem.ID_PROJETO
            JOIN TB_PARTICIPANTE p ON mem.ID_PARTICIPANTE = p.ID_PARTICIPANTE
            GROUP BY proj.DS_NOME_PROJETO
        LOOP NULL; END LOOP;
        end_ts := clock_timestamp();
        INSERT INTO benchmark_results VALUES (10, 'intermediate', run, 'baseline',
            EXTRACT(EPOCH FROM end_ts - start_ts) * 1000);
    END LOOP;
END $$;

-- NOTE: Advanced queries (11-30) follow the same pattern.
-- For brevity, these should be added in the same format as above,
-- each wrapped in a DO block with 20 iterations.
-- The query_id should be 11-30 and query_type = 'advanced'.

-- ============================================================================
-- PHASE 3: CREATE INDEXES
-- ============================================================================

CREATE INDEX IDX_PROJETO_COORDENADOR ON TB_PROJETO_EXTENSAO(ID_INSTR_COORDENADOR);
CREATE INDEX IDX_ATIVIDADE_PROJETO ON TB_ATIVIDADE(ID_PROJ_VINCULADO);
CREATE INDEX IDX_INSCRICAO_PARTICIPANTE ON RL_INSCRICAO_HISTORICO(ID_PARTICIPANTE);
CREATE INDEX IDX_INSCRICAO_ATIVIDADE ON RL_INSCRICAO_HISTORICO(ID_ATIVIDADE);
CREATE INDEX IDX_CERTIFICADO_INSCRICAO ON TB_EMISSAO_CERTIFICADO(ID_INSCRICAO);
CREATE INDEX IDX_FEEDBACK_INSCRICAO ON TB_REGISTRO_FEEDBACK(ID_INSCRICAO);
CREATE INDEX IDX_PARTICIPANTE_EMAIL ON TB_PARTICIPANTE(DS_EMAIL_CONTATO);
CREATE INDEX IDX_INSCRICAO_PRESENCA ON RL_INSCRICAO_HISTORICO(ST_PRESENCA);
CREATE INDEX IDX_ATIVIDADE_DATA ON TB_ATIVIDADE(DT_REALIZACAO);
CREATE INDEX IDX_INSCRICAO_PRESENCA_NOTA ON RL_INSCRICAO_HISTORICO(ST_PRESENCA, VL_NOTA_AVALIACAO);

-- ============================================================================
-- PHASE 4: INDEXED BENCHMARK
-- ============================================================================
-- Repeat all DO blocks from Phase 2, but change 'baseline' to 'indexed'.
-- (Copy all DO blocks above and replace the phase string.)

-- [Same 10 intermediate DO blocks with phase = 'indexed']
-- [Same 20 advanced DO blocks with phase = 'indexed']

-- ============================================================================
-- PHASE 5: REPORT - Calculate Mean, StdDev, Speedup
-- ============================================================================

SELECT
    b.query_id,
    b.query_type,
    ROUND(AVG(CASE WHEN phase = 'baseline' THEN execution_time_ms END), 4) AS baseline_mean_ms,
    ROUND(STDDEV(CASE WHEN phase = 'baseline' THEN execution_time_ms END), 4) AS baseline_stddev_ms,
    ROUND(AVG(CASE WHEN phase = 'indexed' THEN execution_time_ms END), 4) AS indexed_mean_ms,
    ROUND(STDDEV(CASE WHEN phase = 'indexed' THEN execution_time_ms END), 4) AS indexed_stddev_ms,
    ROUND(
        AVG(CASE WHEN phase = 'baseline' THEN execution_time_ms END) /
        NULLIF(AVG(CASE WHEN phase = 'indexed' THEN execution_time_ms END), 0),
    2) AS speedup
FROM benchmark_results b
GROUP BY b.query_id, b.query_type
ORDER BY b.query_type, b.query_id;

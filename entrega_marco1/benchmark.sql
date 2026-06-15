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
            SELECT p.DS_NOME_PARTICIPANTE, COUNT(a.ID_ATIVIDADE) as total_presencas, STRING_AGG(a.DS_TITULO_ATIVIDADE, ', ') as nomes_atividades
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
            SELECT proj.DS_NOME_PROJETO, COUNT(mem.ID_PARTICIPANTE) as total_membros, STRING_AGG(p.DS_NOME_PARTICIPANTE, ', ') as nomes_participantes
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

DO $$
DECLARE
    start_ts TIMESTAMP;
    end_ts TIMESTAMP;
    r RECORD;
BEGIN
    FOR run IN 1..20 LOOP
        -- Query Adv-1: Rank participants by average grade
        start_ts := clock_timestamp();
        FOR r IN
            SELECT sub.DS_NOME_PARTICIPANTE, sub.media_global, RANK() OVER(ORDER BY sub.media_global DESC) as ranking
            FROM (
                SELECT p.ID_PARTICIPANTE, p.DS_NOME_PARTICIPANTE, AVG(i.VL_NOTA_AVALIACAO) as media_global
                FROM TB_PARTICIPANTE p
                JOIN RL_INSCRICAO_HISTORICO i ON p.ID_PARTICIPANTE = i.ID_PARTICIPANTE
                JOIN TB_ATIVIDADE a ON i.ID_ATIVIDADE = a.ID_ATIVIDADE
                GROUP BY p.ID_PARTICIPANTE, p.DS_NOME_PARTICIPANTE
            ) sub
        LOOP NULL; END LOOP;
        end_ts := clock_timestamp();
        INSERT INTO benchmark_results VALUES (11, 'advanced', run, 'baseline',
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
        -- Query Adv-2: Top 3 projects by certificates
        start_ts := clock_timestamp();
        FOR r IN
            SELECT DS_NOME_PROJETO, total_certificados
            FROM (
                SELECT proj.DS_NOME_PROJETO, COUNT(cert.ID_CERTIFICADO) as total_certificados
                FROM TB_PROJETO_EXTENSAO proj
                JOIN TB_ATIVIDADE a ON proj.ID_PROJETO = a.ID_PROJ_VINCULADO
                JOIN RL_INSCRICAO_HISTORICO i ON a.ID_ATIVIDADE = i.ID_ATIVIDADE
                JOIN TB_EMISSAO_CERTIFICADO cert ON i.ID_INSCRICAO = cert.ID_INSCRICAO
                GROUP BY proj.DS_NOME_PROJETO
            ) sub
            ORDER BY total_certificados DESC
            LIMIT 3
        LOOP NULL; END LOOP;
        end_ts := clock_timestamp();
        INSERT INTO benchmark_results VALUES (12, 'advanced', run, 'baseline',
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
        -- Query Adv-3: Activities with above-average participation
        start_ts := clock_timestamp();
        FOR r IN
            WITH AtividadeContagem AS (
                SELECT ID_ATIVIDADE, COUNT(*) as total_inscritos
                FROM RL_INSCRICAO_HISTORICO
                GROUP BY ID_ATIVIDADE
            )
            SELECT a.DS_TITULO_ATIVIDADE, proj.DS_NOME_PROJETO, ac.total_inscritos
            FROM TB_ATIVIDADE a
            JOIN AtividadeContagem ac ON a.ID_ATIVIDADE = ac.ID_ATIVIDADE
            JOIN TB_PROJETO_EXTENSAO proj ON a.ID_PROJ_VINCULADO = proj.ID_PROJETO
            WHERE ac.total_inscritos > (SELECT AVG(total_inscritos) FROM AtividadeContagem)
        LOOP NULL; END LOOP;
        end_ts := clock_timestamp();
        INSERT INTO benchmark_results VALUES (13, 'advanced', run, 'baseline',
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
        -- Query Adv-4: Instructors who never coordinated a project
        start_ts := clock_timestamp();
        FOR r IN
            SELECT inst.DS_NOME_INSTRUTOR, COUNT(DISTINCT alloc.ID_ATIVIDADE) as total_atividades_alocadas
            FROM TB_INSTRUTOR inst
            JOIN RL_ALOCACAO_INSTRUTOR alloc ON inst.ID_INSTRUTOR = alloc.ID_INSTRUTOR
            JOIN TB_ATIVIDADE a ON alloc.ID_ATIVIDADE = a.ID_ATIVIDADE
            WHERE NOT EXISTS (
                SELECT 1 FROM TB_PROJETO_EXTENSAO proj
                WHERE proj.ID_INSTR_COORDENADOR = inst.ID_INSTRUTOR
            )
            GROUP BY inst.ID_INSTRUTOR, inst.DS_NOME_INSTRUTOR
        LOOP NULL; END LOOP;
        end_ts := clock_timestamp();
        INSERT INTO benchmark_results VALUES (14, 'advanced', run, 'baseline',
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
        -- Query Adv-5: Running total of sponsorship per partner
        start_ts := clock_timestamp();
        FOR r IN
            SELECT p.DS_NOME_ORGANIZACAO, a.DS_TITULO_ATIVIDADE, pat.VL_APORTE,
                SUM(pat.VL_APORTE) OVER(PARTITION BY p.ID_PARCEIRO ORDER BY a.ID_ATIVIDADE) as total_acumulado,
                COUNT(*) OVER(PARTITION BY p.ID_PARCEIRO) as total_patrocinios_parceiro
            FROM TB_PARCEIRO p
            JOIN RL_PATROCINIO_EVENTO pat ON p.ID_PARCEIRO = pat.ID_PARCEIRO
            JOIN TB_ATIVIDADE a ON pat.ID_ATIVIDADE = a.ID_ATIVIDADE
        LOOP NULL; END LOOP;
        end_ts := clock_timestamp();
        INSERT INTO benchmark_results VALUES (15, 'advanced', run, 'baseline',
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
        -- Query Adv-6: Grade as percentage of max per activity
        start_ts := clock_timestamp();
        FOR r IN
            SELECT p.DS_NOME_PARTICIPANTE, a.DS_TITULO_ATIVIDADE, i.VL_NOTA_AVALIACAO,
                (i.VL_NOTA_AVALIACAO / MAX(i.VL_NOTA_AVALIACAO) OVER(PARTITION BY a.ID_ATIVIDADE)) * 100 as perc_max_nota
            FROM TB_PARTICIPANTE p
            JOIN RL_INSCRICAO_HISTORICO i ON p.ID_PARTICIPANTE = i.ID_PARTICIPANTE
            JOIN TB_ATIVIDADE a ON i.ID_ATIVIDADE = a.ID_ATIVIDADE
            WHERE a.ID_ATIVIDADE IN (
                SELECT ID_ATIVIDADE FROM RL_INSCRICAO_HISTORICO
                GROUP BY ID_ATIVIDADE HAVING COUNT(*) > 5
            )
        LOOP NULL; END LOOP;
        end_ts := clock_timestamp();
        INSERT INTO benchmark_results VALUES (16, 'advanced', run, 'baseline',
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
        -- Query Adv-7: Projects where coordinator also teaches
        start_ts := clock_timestamp();
        FOR r IN
            SELECT proj.DS_NOME_PROJETO, COUNT(DISTINCT a.ID_ATIVIDADE) as total_atividades
            FROM TB_PROJETO_EXTENSAO proj
            JOIN TB_ATIVIDADE a ON proj.ID_PROJETO = a.ID_PROJ_VINCULADO
            JOIN RL_ALOCACAO_INSTRUTOR alloc ON a.ID_ATIVIDADE = alloc.ID_ATIVIDADE
            WHERE alloc.ID_INSTRUTOR = proj.ID_INSTR_COORDENADOR
            AND proj.ID_PROJETO IN (
                SELECT ID_PROJ_VINCULADO FROM TB_ATIVIDADE
                GROUP BY ID_PROJ_VINCULADO HAVING COUNT(*) > 5
            )
            GROUP BY proj.DS_NOME_PROJETO
        LOOP NULL; END LOOP;
        end_ts := clock_timestamp();
        INSERT INTO benchmark_results VALUES (17, 'advanced', run, 'baseline',
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
        -- Query Adv-8: Projects with above-average ALUNO members
        start_ts := clock_timestamp();
        FOR r IN
            SELECT proj.DS_NOME_PROJETO, COUNT(p.ID_PARTICIPANTE) as total_alunos
            FROM TB_PROJETO_EXTENSAO proj
            JOIN RL_MEMBRO_PROJETO mem ON proj.ID_PROJETO = mem.ID_PROJETO
            JOIN TB_PARTICIPANTE p ON mem.ID_PARTICIPANTE = p.ID_PARTICIPANTE
            WHERE p.TP_VINCULO_INST = 'ALUNO'
            GROUP BY proj.DS_NOME_PROJETO
            HAVING COUNT(p.ID_PARTICIPANTE) > (
                SELECT AVG(alunos_count) FROM (
                    SELECT COUNT(p2.ID_PARTICIPANTE) as alunos_count
                    FROM RL_MEMBRO_PROJETO mem2
                    JOIN TB_PARTICIPANTE p2 ON mem2.ID_PARTICIPANTE = p2.ID_PARTICIPANTE
                    WHERE p2.TP_VINCULO_INST = 'ALUNO'
                    GROUP BY mem2.ID_PROJETO
                ) sub
            )
        LOOP NULL; END LOOP;
        end_ts := clock_timestamp();
        INSERT INTO benchmark_results VALUES (18, 'advanced', run, 'baseline',
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
        -- Query Adv-9: Activities with >1 instructor AND a sponsor
        start_ts := clock_timestamp();
        FOR r IN
            SELECT DS_TITULO_ATIVIDADE
            FROM TB_ATIVIDADE a
            WHERE ID_ATIVIDADE IN (
                SELECT ID_ATIVIDADE FROM RL_ALOCACAO_INSTRUTOR GROUP BY ID_ATIVIDADE HAVING COUNT(*) > 1
            ) AND EXISTS (
                SELECT 1 FROM RL_PATROCINIO_EVENTO pat WHERE pat.ID_ATIVIDADE = a.ID_ATIVIDADE
            )
        LOOP NULL; END LOOP;
        end_ts := clock_timestamp();
        INSERT INTO benchmark_results VALUES (19, 'advanced', run, 'baseline',
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
        -- Query Adv-10: Month-over-month project growth
        start_ts := clock_timestamp();
        FOR r IN
            SELECT DATE_TRUNC('month', proj.DT_CRIACAO) as mes_criacao,
                COUNT(DISTINCT proj.ID_PROJETO) as projetos_no_mes,
                COUNT(DISTINCT i.ID_INSCRICAO) as total_inscricoes,
                SUM(COUNT(DISTINCT proj.ID_PROJETO)) OVER(ORDER BY DATE_TRUNC('month', proj.DT_CRIACAO)) as projetos_acumulados,
                COUNT(DISTINCT proj.ID_PROJETO) - COALESCE(LAG(COUNT(DISTINCT proj.ID_PROJETO)) OVER(ORDER BY DATE_TRUNC('month', proj.DT_CRIACAO)), 0) as crescimento_mensal
            FROM TB_PROJETO_EXTENSAO proj
            JOIN TB_ATIVIDADE a ON proj.ID_PROJETO = a.ID_PROJ_VINCULADO
            JOIN RL_INSCRICAO_HISTORICO i ON a.ID_ATIVIDADE = i.ID_ATIVIDADE
            GROUP BY DATE_TRUNC('month', proj.DT_CRIACAO)
        LOOP NULL; END LOOP;
        end_ts := clock_timestamp();
        INSERT INTO benchmark_results VALUES (20, 'advanced', run, 'baseline',
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
        -- Query Adv-11: Activity with highest avg satisfaction
        start_ts := clock_timestamp();
        FOR r IN
            SELECT DS_TITULO_ATIVIDADE, media_satisfacao
            FROM (
                SELECT a.DS_TITULO_ATIVIDADE, AVG(f.VL_NOTA_SATISFACAO) as media_satisfacao
                FROM TB_ATIVIDADE a
                JOIN RL_INSCRICAO_HISTORICO i ON a.ID_ATIVIDADE = i.ID_ATIVIDADE
                JOIN TB_REGISTRO_FEEDBACK f ON i.ID_INSCRICAO = f.ID_INSCRICAO
                GROUP BY a.DS_TITULO_ATIVIDADE
            ) sub
            ORDER BY media_satisfacao DESC
            LIMIT 1
        LOOP NULL; END LOOP;
        end_ts := clock_timestamp();
        INSERT INTO benchmark_results VALUES (21, 'advanced', run, 'baseline',
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
        -- Query Adv-12: Participants with certificate for every activity
        start_ts := clock_timestamp();
        FOR r IN
            SELECT p.DS_NOME_PARTICIPANTE, COUNT(c.ID_CERTIFICADO) as total_certificados
            FROM TB_PARTICIPANTE p
            JOIN RL_INSCRICAO_HISTORICO i ON p.ID_PARTICIPANTE = i.ID_PARTICIPANTE
            JOIN TB_EMISSAO_CERTIFICADO c ON i.ID_INSCRICAO = c.ID_INSCRICAO
            WHERE NOT EXISTS (
                SELECT 1 FROM RL_INSCRICAO_HISTORICO i2
                LEFT JOIN TB_EMISSAO_CERTIFICADO c2 ON i2.ID_INSCRICAO = c2.ID_INSCRICAO
                WHERE i2.ID_PARTICIPANTE = p.ID_PARTICIPANTE AND c2.ID_CERTIFICADO IS NULL
            )
            GROUP BY p.ID_PARTICIPANTE, p.DS_NOME_PARTICIPANTE
        LOOP NULL; END LOOP;
        end_ts := clock_timestamp();
        INSERT INTO benchmark_results VALUES (22, 'advanced', run, 'baseline',
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
        -- Query Adv-13: Super-participants (>5 enrollments)
        start_ts := clock_timestamp();
        FOR r IN
            SELECT p.DS_NOME_PARTICIPANTE, COUNT(i.ID_INSCRICAO) as total_inscricoes
            FROM TB_PARTICIPANTE p
            JOIN RL_INSCRICAO_HISTORICO i ON p.ID_PARTICIPANTE = i.ID_PARTICIPANTE
            JOIN TB_ATIVIDADE a ON i.ID_ATIVIDADE = a.ID_ATIVIDADE
            WHERE p.ID_PARTICIPANTE IN (
                SELECT i2.ID_PARTICIPANTE FROM RL_INSCRICAO_HISTORICO i2
                GROUP BY i2.ID_PARTICIPANTE HAVING COUNT(i2.ID_INSCRICAO) > 5
            )
            GROUP BY p.ID_PARTICIPANTE, p.DS_NOME_PARTICIPANTE
        LOOP NULL; END LOOP;
        end_ts := clock_timestamp();
        INSERT INTO benchmark_results VALUES (23, 'advanced', run, 'baseline',
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
        -- Query Adv-14: Projects above average workload
        start_ts := clock_timestamp();
        FOR r IN
            SELECT proj.DS_NOME_PROJETO, AVG(alloc.VL_CARGA_HORARIA) as avg_workload,
                COUNT(DISTINCT a.ID_ATIVIDADE) as total_atividades
            FROM TB_PROJETO_EXTENSAO proj
            JOIN TB_ATIVIDADE a ON proj.ID_PROJETO = a.ID_PROJ_VINCULADO
            JOIN RL_ALOCACAO_INSTRUTOR alloc ON a.ID_ATIVIDADE = alloc.ID_ATIVIDADE
            GROUP BY proj.ID_PROJETO, proj.DS_NOME_PROJETO
            HAVING AVG(alloc.VL_CARGA_HORARIA) > (
                SELECT AVG(VL_CARGA_HORARIA) FROM RL_ALOCACAO_INSTRUTOR
            )
        LOOP NULL; END LOOP;
        end_ts := clock_timestamp();
        INSERT INTO benchmark_results VALUES (24, 'advanced', run, 'baseline',
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
        -- Query Adv-15: First activity date per participant (>2 activities)
        start_ts := clock_timestamp();
        FOR r IN
            SELECT DISTINCT p.DS_NOME_PARTICIPANTE,
                FIRST_VALUE(a.DT_REALIZACAO) OVER(PARTITION BY p.ID_PARTICIPANTE ORDER BY a.DT_REALIZACAO) as primeira_atividade
            FROM TB_PARTICIPANTE p
            JOIN RL_INSCRICAO_HISTORICO i ON p.ID_PARTICIPANTE = i.ID_PARTICIPANTE
            JOIN TB_ATIVIDADE a ON i.ID_ATIVIDADE = a.ID_ATIVIDADE
            WHERE p.ID_PARTICIPANTE IN (
                SELECT i2.ID_PARTICIPANTE FROM RL_INSCRICAO_HISTORICO i2
                GROUP BY i2.ID_PARTICIPANTE HAVING COUNT(DISTINCT i2.ID_ATIVIDADE) > 2
            )
        LOOP NULL; END LOOP;
        end_ts := clock_timestamp();
        INSERT INTO benchmark_results VALUES (25, 'advanced', run, 'baseline',
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
        -- Query Adv-16: Activities by instructor specialty (>= 2 activities), ordered
        start_ts := clock_timestamp();
        FOR r IN
            SELECT inst.DS_ESPECIALIDADE, COUNT(DISTINCT a.ID_ATIVIDADE) as total_atividades
            FROM TB_INSTRUTOR inst
            JOIN RL_ALOCACAO_INSTRUTOR alloc ON inst.ID_INSTRUTOR = alloc.ID_INSTRUTOR
            JOIN TB_ATIVIDADE a ON alloc.ID_ATIVIDADE = a.ID_ATIVIDADE
            WHERE inst.DS_ESPECIALIDADE IN (
                SELECT inst2.DS_ESPECIALIDADE FROM TB_INSTRUTOR inst2
                JOIN RL_ALOCACAO_INSTRUTOR alloc2 ON inst2.ID_INSTRUTOR = alloc2.ID_INSTRUTOR
                GROUP BY inst2.DS_ESPECIALIDADE HAVING COUNT(DISTINCT alloc2.ID_ATIVIDADE) >= 2
            )
            GROUP BY inst.DS_ESPECIALIDADE
            ORDER BY total_atividades DESC
        LOOP NULL; END LOOP;
        end_ts := clock_timestamp();
        INSERT INTO benchmark_results VALUES (26, 'advanced', run, 'baseline',
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
        -- Query Adv-17: Lowest feedback in highly attended activity
        start_ts := clock_timestamp();
        FOR r IN
            SELECT p.DS_NOME_PARTICIPANTE, f.VL_NOTA_SATISFACAO, a.DS_TITULO_ATIVIDADE
            FROM TB_PARTICIPANTE p
            JOIN RL_INSCRICAO_HISTORICO i ON p.ID_PARTICIPANTE = i.ID_PARTICIPANTE
            JOIN TB_REGISTRO_FEEDBACK f ON i.ID_INSCRICAO = f.ID_INSCRICAO
            JOIN TB_ATIVIDADE a ON i.ID_ATIVIDADE = a.ID_ATIVIDADE
            WHERE a.ID_ATIVIDADE IN (
                SELECT ID_ATIVIDADE FROM RL_INSCRICAO_HISTORICO GROUP BY ID_ATIVIDADE HAVING COUNT(*) > 20
            )
            ORDER BY f.VL_NOTA_SATISFACAO ASC
            LIMIT 1
        LOOP NULL; END LOOP;
        end_ts := clock_timestamp();
        INSERT INTO benchmark_results VALUES (27, 'advanced', run, 'baseline',
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
        -- Query Adv-18: Recent activities with above-average enrollment
        start_ts := clock_timestamp();
        FOR r IN
            WITH RecentActivities AS (
                SELECT * FROM TB_ATIVIDADE WHERE DT_REALIZACAO >= CURRENT_DATE - INTERVAL '6 months'
            )
            SELECT ra.DS_TITULO_ATIVIDADE, ra.DT_REALIZACAO, COUNT(i.ID_INSCRICAO) as total_inscritos
            FROM RecentActivities ra
            JOIN RL_INSCRICAO_HISTORICO i ON ra.ID_ATIVIDADE = i.ID_ATIVIDADE
            JOIN TB_PARTICIPANTE p ON i.ID_PARTICIPANTE = p.ID_PARTICIPANTE
            GROUP BY ra.ID_ATIVIDADE, ra.DS_TITULO_ATIVIDADE, ra.DT_REALIZACAO
            HAVING COUNT(i.ID_INSCRICAO) > (
                SELECT AVG(cnt) FROM (
                    SELECT COUNT(*) as cnt FROM RL_INSCRICAO_HISTORICO GROUP BY ID_ATIVIDADE
                ) avg_sub
            )
        LOOP NULL; END LOOP;
        end_ts := clock_timestamp();
        INSERT INTO benchmark_results VALUES (28, 'advanced', run, 'baseline',
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
        -- Query Adv-19: Partners sponsoring >1 project
        start_ts := clock_timestamp();
        FOR r IN
            SELECT p.DS_NOME_ORGANIZACAO,
                (SELECT SUM(VL_APORTE) FROM RL_PATROCINIO_EVENTO pat2 WHERE pat2.ID_PARCEIRO = p.ID_PARCEIRO) as total_aportado
            FROM TB_PARCEIRO p
            JOIN RL_PATROCINIO_EVENTO pat ON p.ID_PARCEIRO = pat.ID_PARCEIRO
            JOIN TB_ATIVIDADE a ON pat.ID_ATIVIDADE = a.ID_ATIVIDADE
            GROUP BY p.ID_PARCEIRO, p.DS_NOME_ORGANIZACAO
            HAVING COUNT(DISTINCT a.ID_PROJ_VINCULADO) > 1
        LOOP NULL; END LOOP;
        end_ts := clock_timestamp();
        INSERT INTO benchmark_results VALUES (29, 'advanced', run, 'baseline',
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
        -- Query Adv-20: Grade difference from activity average
        start_ts := clock_timestamp();
        FOR r IN
            SELECT p.DS_NOME_PARTICIPANTE, a.DS_TITULO_ATIVIDADE, i.VL_NOTA_AVALIACAO,
                i.VL_NOTA_AVALIACAO - AVG(i.VL_NOTA_AVALIACAO) OVER(PARTITION BY a.ID_ATIVIDADE) as diff_para_media
            FROM TB_PARTICIPANTE p
            JOIN RL_INSCRICAO_HISTORICO i ON p.ID_PARTICIPANTE = i.ID_PARTICIPANTE
            JOIN TB_ATIVIDADE a ON i.ID_ATIVIDADE = a.ID_ATIVIDADE
            WHERE a.ID_ATIVIDADE IN (
                SELECT ID_ATIVIDADE FROM RL_INSCRICAO_HISTORICO
                GROUP BY ID_ATIVIDADE HAVING COUNT(*) > 10
            )
        LOOP NULL; END LOOP;
        end_ts := clock_timestamp();
        INSERT INTO benchmark_results VALUES (30, 'advanced', run, 'baseline',
            EXTRACT(EPOCH FROM end_ts - start_ts) * 1000);
    END LOOP;
END $$;

-- ============================================================================
-- PHASE 3: CREATE INDEXES
-- ============================================================================

CREATE INDEX IDX_PROJETO_COORDENADOR ON TB_PROJETO_EXTENSAO(ID_INSTR_COORDENADOR);
CREATE INDEX IDX_ATIVIDADE_PROJETO ON TB_ATIVIDADE(ID_PROJ_VINCULADO);
CREATE INDEX IDX_INSCRICAO_PARTICIPANTE ON RL_INSCRICAO_HISTORICO(ID_PARTICIPANTE);
CREATE INDEX IDX_INSCRICAO_ATIVIDADE ON RL_INSCRICAO_HISTORICO(ID_ATIVIDADE);
-- Índices redundantes removidos (ID_INSCRICAO já possui índice automático pela constraint UNIQUE)
-- CREATE INDEX IDX_CERTIFICADO_INSCRICAO ON TB_EMISSAO_CERTIFICADO(ID_INSCRICAO);
-- CREATE INDEX IDX_FEEDBACK_INSCRICAO ON TB_REGISTRO_FEEDBACK(ID_INSCRICAO);
-- Índices redundantes removidos (DS_EMAIL_CONTATO já possui índice automático pela constraint UNIQUE)
-- CREATE INDEX IDX_PARTICIPANTE_EMAIL ON TB_PARTICIPANTE(DS_EMAIL_CONTATO);
CREATE INDEX IDX_INSCRICAO_PRESENCA ON RL_INSCRICAO_HISTORICO(ST_PRESENCA);
CREATE INDEX IDX_ATIVIDADE_DATA ON TB_ATIVIDADE(DT_REALIZACAO);
CREATE INDEX IDX_INSCRICAO_PRESENCA_NOTA ON RL_INSCRICAO_HISTORICO(ST_PRESENCA, VL_NOTA_AVALIACAO);

-- ============================================================================
-- PHASE 4: INDEXED BENCHMARK
-- ============================================================================

DO $$
DECLARE
    start_ts TIMESTAMP;
    end_ts TIMESTAMP;
    r RECORD;
BEGIN
    FOR run IN 1..20 LOOP
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
        INSERT INTO benchmark_results VALUES (1, 'intermediate', run, 'indexed',
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
        start_ts := clock_timestamp();
        FOR r IN
            SELECT proj.DS_NOME_PROJETO, inst.DS_NOME_INSTRUTOR AS coordenador, COUNT(a.ID_ATIVIDADE) as total_atividades
            FROM TB_PROJETO_EXTENSAO proj
            JOIN TB_INSTRUTOR inst ON proj.ID_INSTR_COORDENADOR = inst.ID_INSTRUTOR
            LEFT JOIN TB_ATIVIDADE a ON proj.ID_PROJETO = a.ID_PROJ_VINCULADO
            GROUP BY proj.DS_NOME_PROJETO, inst.DS_NOME_INSTRUTOR
        LOOP NULL; END LOOP;
        end_ts := clock_timestamp();
        INSERT INTO benchmark_results VALUES (2, 'intermediate', run, 'indexed',
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
        start_ts := clock_timestamp();
        FOR r IN
            SELECT inst.DS_NOME_INSTRUTOR, SUM(alloc.VL_CARGA_HORARIA) as total_horas, COUNT(a.ID_ATIVIDADE) as total_atividades
            FROM TB_INSTRUTOR inst
            JOIN RL_ALOCACAO_INSTRUTOR alloc ON inst.ID_INSTRUTOR = alloc.ID_INSTRUTOR
            JOIN TB_ATIVIDADE a ON alloc.ID_ATIVIDADE = a.ID_ATIVIDADE
            GROUP BY inst.DS_NOME_INSTRUTOR
        LOOP NULL; END LOOP;
        end_ts := clock_timestamp();
        INSERT INTO benchmark_results VALUES (3, 'intermediate', run, 'indexed',
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
        start_ts := clock_timestamp();
        FOR r IN
            SELECT part.DS_NOME_ORGANIZACAO, SUM(pat.VL_APORTE) as total_patrocinio, COUNT(a.ID_ATIVIDADE) as total_atividades
            FROM TB_PARCEIRO part
            JOIN RL_PATROCINIO_EVENTO pat ON part.ID_PARCEIRO = pat.ID_PARCEIRO
            JOIN TB_ATIVIDADE a ON pat.ID_ATIVIDADE = a.ID_ATIVIDADE
            GROUP BY part.DS_NOME_ORGANIZACAO
        LOOP NULL; END LOOP;
        end_ts := clock_timestamp();
        INSERT INTO benchmark_results VALUES (4, 'intermediate', run, 'indexed',
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
        start_ts := clock_timestamp();
        FOR r IN
            SELECT p.DS_NOME_PARTICIPANTE, COUNT(a.ID_ATIVIDADE) as total_presencas, STRING_AGG(a.DS_TITULO_ATIVIDADE, ', ') as nomes_atividades
            FROM TB_PARTICIPANTE p
            JOIN RL_INSCRICAO_HISTORICO i ON p.ID_PARTICIPANTE = i.ID_PARTICIPANTE
            JOIN TB_ATIVIDADE a ON i.ID_ATIVIDADE = a.ID_ATIVIDADE
            WHERE i.ST_PRESENCA = 'PRESENTE'
            GROUP BY p.DS_NOME_PARTICIPANTE
            HAVING COUNT(a.ID_ATIVIDADE) >= 2
        LOOP NULL; END LOOP;
        end_ts := clock_timestamp();
        INSERT INTO benchmark_results VALUES (5, 'intermediate', run, 'indexed',
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
        INSERT INTO benchmark_results VALUES (6, 'intermediate', run, 'indexed',
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
        start_ts := clock_timestamp();
        FOR r IN
            SELECT inst.DS_NOME_INSTRUTOR, COUNT(a.ID_ATIVIDADE) as total_atividades
            FROM TB_ATIVIDADE a
            JOIN TB_PROJETO_EXTENSAO proj ON a.ID_PROJ_VINCULADO = proj.ID_PROJETO
            JOIN TB_INSTRUTOR inst ON proj.ID_INSTR_COORDENADOR = inst.ID_INSTRUTOR
            GROUP BY inst.DS_NOME_INSTRUTOR
        LOOP NULL; END LOOP;
        end_ts := clock_timestamp();
        INSERT INTO benchmark_results VALUES (7, 'intermediate', run, 'indexed',
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
        start_ts := clock_timestamp();
        FOR r IN
            SELECT a.DS_TITULO_ATIVIDADE, COUNT(cert.ID_CERTIFICADO) as total_certificados
            FROM TB_ATIVIDADE a
            JOIN RL_INSCRICAO_HISTORICO i ON a.ID_ATIVIDADE = i.ID_ATIVIDADE
            JOIN TB_EMISSAO_CERTIFICADO cert ON i.ID_INSCRICAO = cert.ID_INSCRICAO
            GROUP BY a.DS_TITULO_ATIVIDADE
        LOOP NULL; END LOOP;
        end_ts := clock_timestamp();
        INSERT INTO benchmark_results VALUES (8, 'intermediate', run, 'indexed',
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
        start_ts := clock_timestamp();
        FOR r IN
            SELECT p.DS_NOME_PARTICIPANTE, COUNT(f.ID_FEEDBACK) as total_feedbacks, AVG(f.VL_NOTA_SATISFACAO) as media_satisfacao
            FROM TB_PARTICIPANTE p
            JOIN RL_INSCRICAO_HISTORICO i ON p.ID_PARTICIPANTE = i.ID_PARTICIPANTE
            JOIN TB_REGISTRO_FEEDBACK f ON i.ID_INSCRICAO = f.ID_INSCRICAO
            GROUP BY p.DS_NOME_PARTICIPANTE
        LOOP NULL; END LOOP;
        end_ts := clock_timestamp();
        INSERT INTO benchmark_results VALUES (9, 'intermediate', run, 'indexed',
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
        start_ts := clock_timestamp();
        FOR r IN
            SELECT proj.DS_NOME_PROJETO, COUNT(mem.ID_PARTICIPANTE) as total_membros, STRING_AGG(p.DS_NOME_PARTICIPANTE, ', ') as nomes_participantes
            FROM TB_PROJETO_EXTENSAO proj
            JOIN RL_MEMBRO_PROJETO mem ON proj.ID_PROJETO = mem.ID_PROJETO
            JOIN TB_PARTICIPANTE p ON mem.ID_PARTICIPANTE = p.ID_PARTICIPANTE
            GROUP BY proj.DS_NOME_PROJETO
        LOOP NULL; END LOOP;
        end_ts := clock_timestamp();
        INSERT INTO benchmark_results VALUES (10, 'intermediate', run, 'indexed',
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
        start_ts := clock_timestamp();
        FOR r IN
            SELECT sub.DS_NOME_PARTICIPANTE, sub.media_global, RANK() OVER(ORDER BY sub.media_global DESC) as ranking
            FROM (
                SELECT p.ID_PARTICIPANTE, p.DS_NOME_PARTICIPANTE, AVG(i.VL_NOTA_AVALIACAO) as media_global
                FROM TB_PARTICIPANTE p
                JOIN RL_INSCRICAO_HISTORICO i ON p.ID_PARTICIPANTE = i.ID_PARTICIPANTE
                JOIN TB_ATIVIDADE a ON i.ID_ATIVIDADE = a.ID_ATIVIDADE
                GROUP BY p.ID_PARTICIPANTE, p.DS_NOME_PARTICIPANTE
            ) sub
        LOOP NULL; END LOOP;
        end_ts := clock_timestamp();
        INSERT INTO benchmark_results VALUES (11, 'advanced', run, 'indexed',
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
        start_ts := clock_timestamp();
        FOR r IN
            SELECT DS_NOME_PROJETO, total_certificados
            FROM (
                SELECT proj.DS_NOME_PROJETO, COUNT(cert.ID_CERTIFICADO) as total_certificados
                FROM TB_PROJETO_EXTENSAO proj
                JOIN TB_ATIVIDADE a ON proj.ID_PROJETO = a.ID_PROJ_VINCULADO
                JOIN RL_INSCRICAO_HISTORICO i ON a.ID_ATIVIDADE = i.ID_ATIVIDADE
                JOIN TB_EMISSAO_CERTIFICADO cert ON i.ID_INSCRICAO = cert.ID_INSCRICAO
                GROUP BY proj.DS_NOME_PROJETO
            ) sub
            ORDER BY total_certificados DESC
            LIMIT 3
        LOOP NULL; END LOOP;
        end_ts := clock_timestamp();
        INSERT INTO benchmark_results VALUES (12, 'advanced', run, 'indexed',
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
        start_ts := clock_timestamp();
        FOR r IN
            WITH AtividadeContagem AS (
                SELECT ID_ATIVIDADE, COUNT(*) as total_inscritos
                FROM RL_INSCRICAO_HISTORICO
                GROUP BY ID_ATIVIDADE
            )
            SELECT a.DS_TITULO_ATIVIDADE, proj.DS_NOME_PROJETO, ac.total_inscritos
            FROM TB_ATIVIDADE a
            JOIN AtividadeContagem ac ON a.ID_ATIVIDADE = ac.ID_ATIVIDADE
            JOIN TB_PROJETO_EXTENSAO proj ON a.ID_PROJ_VINCULADO = proj.ID_PROJETO
            WHERE ac.total_inscritos > (SELECT AVG(total_inscritos) FROM AtividadeContagem)
        LOOP NULL; END LOOP;
        end_ts := clock_timestamp();
        INSERT INTO benchmark_results VALUES (13, 'advanced', run, 'indexed',
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
        start_ts := clock_timestamp();
        FOR r IN
            SELECT inst.DS_NOME_INSTRUTOR, COUNT(DISTINCT alloc.ID_ATIVIDADE) as total_atividades_alocadas
            FROM TB_INSTRUTOR inst
            JOIN RL_ALOCACAO_INSTRUTOR alloc ON inst.ID_INSTRUTOR = alloc.ID_INSTRUTOR
            JOIN TB_ATIVIDADE a ON alloc.ID_ATIVIDADE = a.ID_ATIVIDADE
            WHERE NOT EXISTS (
                SELECT 1 FROM TB_PROJETO_EXTENSAO proj
                WHERE proj.ID_INSTR_COORDENADOR = inst.ID_INSTRUTOR
            )
            GROUP BY inst.ID_INSTRUTOR, inst.DS_NOME_INSTRUTOR
        LOOP NULL; END LOOP;
        end_ts := clock_timestamp();
        INSERT INTO benchmark_results VALUES (14, 'advanced', run, 'indexed',
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
        start_ts := clock_timestamp();
        FOR r IN
            SELECT p.DS_NOME_ORGANIZACAO, a.DS_TITULO_ATIVIDADE, pat.VL_APORTE,
                SUM(pat.VL_APORTE) OVER(PARTITION BY p.ID_PARCEIRO ORDER BY a.ID_ATIVIDADE) as total_acumulado,
                COUNT(*) OVER(PARTITION BY p.ID_PARCEIRO) as total_patrocinios_parceiro
            FROM TB_PARCEIRO p
            JOIN RL_PATROCINIO_EVENTO pat ON p.ID_PARCEIRO = pat.ID_PARCEIRO
            JOIN TB_ATIVIDADE a ON pat.ID_ATIVIDADE = a.ID_ATIVIDADE
        LOOP NULL; END LOOP;
        end_ts := clock_timestamp();
        INSERT INTO benchmark_results VALUES (15, 'advanced', run, 'indexed',
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
        start_ts := clock_timestamp();
        FOR r IN
            SELECT p.DS_NOME_PARTICIPANTE, a.DS_TITULO_ATIVIDADE, i.VL_NOTA_AVALIACAO,
                (i.VL_NOTA_AVALIACAO / NULLIF(MAX(i.VL_NOTA_AVALIACAO) OVER(PARTITION BY a.ID_ATIVIDADE), 0)) * 100 as perc_max_nota
            FROM TB_PARTICIPANTE p
            JOIN RL_INSCRICAO_HISTORICO i ON p.ID_PARTICIPANTE = i.ID_PARTICIPANTE
            JOIN TB_ATIVIDADE a ON i.ID_ATIVIDADE = a.ID_ATIVIDADE
            WHERE a.ID_ATIVIDADE IN (
                SELECT ID_ATIVIDADE FROM RL_INSCRICAO_HISTORICO
                GROUP BY ID_ATIVIDADE HAVING COUNT(*) > 5
            )
        LOOP NULL; END LOOP;
        end_ts := clock_timestamp();
        INSERT INTO benchmark_results VALUES (16, 'advanced', run, 'indexed',
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
        start_ts := clock_timestamp();
        FOR r IN
            SELECT proj.DS_NOME_PROJETO, COUNT(DISTINCT a.ID_ATIVIDADE) as total_atividades
            FROM TB_PROJETO_EXTENSAO proj
            JOIN TB_ATIVIDADE a ON proj.ID_PROJETO = a.ID_PROJ_VINCULADO
            JOIN RL_ALOCACAO_INSTRUTOR alloc ON a.ID_ATIVIDADE = alloc.ID_ATIVIDADE
            WHERE alloc.ID_INSTRUTOR = proj.ID_INSTR_COORDENADOR
            AND proj.ID_PROJETO IN (
                SELECT ID_PROJ_VINCULADO FROM TB_ATIVIDADE
                GROUP BY ID_PROJ_VINCULADO HAVING COUNT(*) > 5
            )
            GROUP BY proj.DS_NOME_PROJETO
        LOOP NULL; END LOOP;
        end_ts := clock_timestamp();
        INSERT INTO benchmark_results VALUES (17, 'advanced', run, 'indexed',
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
        start_ts := clock_timestamp();
        FOR r IN
            SELECT proj.DS_NOME_PROJETO, COUNT(p.ID_PARTICIPANTE) as total_alunos
            FROM TB_PROJETO_EXTENSAO proj
            JOIN RL_MEMBRO_PROJETO mem ON proj.ID_PROJETO = mem.ID_PROJETO
            JOIN TB_PARTICIPANTE p ON mem.ID_PARTICIPANTE = p.ID_PARTICIPANTE
            WHERE p.TP_VINCULO_INST = 'ALUNO'
            GROUP BY proj.DS_NOME_PROJETO
            HAVING COUNT(p.ID_PARTICIPANTE) > (
                SELECT AVG(alunos_count) FROM (
                    SELECT COUNT(p2.ID_PARTICIPANTE) as alunos_count
                    FROM RL_MEMBRO_PROJETO mem2
                    JOIN TB_PARTICIPANTE p2 ON mem2.ID_PARTICIPANTE = p2.ID_PARTICIPANTE
                    WHERE p2.TP_VINCULO_INST = 'ALUNO'
                    GROUP BY mem2.ID_PROJETO
                ) sub
            )
        LOOP NULL; END LOOP;
        end_ts := clock_timestamp();
        INSERT INTO benchmark_results VALUES (18, 'advanced', run, 'indexed',
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
        start_ts := clock_timestamp();
        FOR r IN
            SELECT DS_TITULO_ATIVIDADE
            FROM TB_ATIVIDADE a
            WHERE ID_ATIVIDADE IN (
                SELECT ID_ATIVIDADE FROM RL_ALOCACAO_INSTRUTOR GROUP BY ID_ATIVIDADE HAVING COUNT(*) > 1
            ) AND EXISTS (
                SELECT 1 FROM RL_PATROCINIO_EVENTO pat WHERE pat.ID_ATIVIDADE = a.ID_ATIVIDADE
            )
        LOOP NULL; END LOOP;
        end_ts := clock_timestamp();
        INSERT INTO benchmark_results VALUES (19, 'advanced', run, 'indexed',
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
        start_ts := clock_timestamp();
        FOR r IN
            SELECT DATE_TRUNC('month', proj.DT_CRIACAO) as mes_criacao,
                COUNT(DISTINCT proj.ID_PROJETO) as projetos_no_mes,
                COUNT(DISTINCT i.ID_INSCRICAO) as total_inscricoes,
                SUM(COUNT(DISTINCT proj.ID_PROJETO)) OVER(ORDER BY DATE_TRUNC('month', proj.DT_CRIACAO)) as projetos_acumulados,
                COUNT(DISTINCT proj.ID_PROJETO) - COALESCE(LAG(COUNT(DISTINCT proj.ID_PROJETO)) OVER(ORDER BY DATE_TRUNC('month', proj.DT_CRIACAO)), 0) as crescimento_mensal
            FROM TB_PROJETO_EXTENSAO proj
            JOIN TB_ATIVIDADE a ON proj.ID_PROJETO = a.ID_PROJ_VINCULADO
            JOIN RL_INSCRICAO_HISTORICO i ON a.ID_ATIVIDADE = i.ID_ATIVIDADE
            GROUP BY DATE_TRUNC('month', proj.DT_CRIACAO)
        LOOP NULL; END LOOP;
        end_ts := clock_timestamp();
        INSERT INTO benchmark_results VALUES (20, 'advanced', run, 'indexed',
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
        start_ts := clock_timestamp();
        FOR r IN
            SELECT DS_TITULO_ATIVIDADE, media_satisfacao
            FROM (
                SELECT a.DS_TITULO_ATIVIDADE, AVG(f.VL_NOTA_SATISFACAO) as media_satisfacao
                FROM TB_ATIVIDADE a
                JOIN RL_INSCRICAO_HISTORICO i ON a.ID_ATIVIDADE = i.ID_ATIVIDADE
                JOIN TB_REGISTRO_FEEDBACK f ON i.ID_INSCRICAO = f.ID_INSCRICAO
                GROUP BY a.DS_TITULO_ATIVIDADE
            ) sub
            ORDER BY media_satisfacao DESC
            LIMIT 1
        LOOP NULL; END LOOP;
        end_ts := clock_timestamp();
        INSERT INTO benchmark_results VALUES (21, 'advanced', run, 'indexed',
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
        start_ts := clock_timestamp();
        FOR r IN
            SELECT p.DS_NOME_PARTICIPANTE, COUNT(c.ID_CERTIFICADO) as total_certificados
            FROM TB_PARTICIPANTE p
            JOIN RL_INSCRICAO_HISTORICO i ON p.ID_PARTICIPANTE = i.ID_PARTICIPANTE
            JOIN TB_EMISSAO_CERTIFICADO c ON i.ID_INSCRICAO = c.ID_INSCRICAO
            WHERE NOT EXISTS (
                SELECT 1 FROM RL_INSCRICAO_HISTORICO i2
                LEFT JOIN TB_EMISSAO_CERTIFICADO c2 ON i2.ID_INSCRICAO = c2.ID_INSCRICAO
                WHERE i2.ID_PARTICIPANTE = p.ID_PARTICIPANTE AND c2.ID_CERTIFICADO IS NULL
            )
            GROUP BY p.ID_PARTICIPANTE, p.DS_NOME_PARTICIPANTE
        LOOP NULL; END LOOP;
        end_ts := clock_timestamp();
        INSERT INTO benchmark_results VALUES (22, 'advanced', run, 'indexed',
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
        start_ts := clock_timestamp();
        FOR r IN
            SELECT p.DS_NOME_PARTICIPANTE, COUNT(i.ID_INSCRICAO) as total_inscricoes
            FROM TB_PARTICIPANTE p
            JOIN RL_INSCRICAO_HISTORICO i ON p.ID_PARTICIPANTE = i.ID_PARTICIPANTE
            JOIN TB_ATIVIDADE a ON i.ID_ATIVIDADE = a.ID_ATIVIDADE
            WHERE p.ID_PARTICIPANTE IN (
                SELECT i2.ID_PARTICIPANTE FROM RL_INSCRICAO_HISTORICO i2
                GROUP BY i2.ID_PARTICIPANTE HAVING COUNT(i2.ID_INSCRICAO) > 5
            )
            GROUP BY p.ID_PARTICIPANTE, p.DS_NOME_PARTICIPANTE
        LOOP NULL; END LOOP;
        end_ts := clock_timestamp();
        INSERT INTO benchmark_results VALUES (23, 'advanced', run, 'indexed',
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
        start_ts := clock_timestamp();
        FOR r IN
            SELECT proj.DS_NOME_PROJETO, AVG(alloc.VL_CARGA_HORARIA) as avg_workload,
                COUNT(DISTINCT a.ID_ATIVIDADE) as total_atividades
            FROM TB_PROJETO_EXTENSAO proj
            JOIN TB_ATIVIDADE a ON proj.ID_PROJETO = a.ID_PROJ_VINCULADO
            JOIN RL_ALOCACAO_INSTRUTOR alloc ON a.ID_ATIVIDADE = alloc.ID_ATIVIDADE
            GROUP BY proj.ID_PROJETO, proj.DS_NOME_PROJETO
            HAVING AVG(alloc.VL_CARGA_HORARIA) > (
                SELECT AVG(VL_CARGA_HORARIA) FROM RL_ALOCACAO_INSTRUTOR
            )
        LOOP NULL; END LOOP;
        end_ts := clock_timestamp();
        INSERT INTO benchmark_results VALUES (24, 'advanced', run, 'indexed',
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
        start_ts := clock_timestamp();
        FOR r IN
            SELECT DISTINCT p.DS_NOME_PARTICIPANTE,
                FIRST_VALUE(a.DT_REALIZACAO) OVER(PARTITION BY p.ID_PARTICIPANTE ORDER BY a.DT_REALIZACAO) as primeira_atividade
            FROM TB_PARTICIPANTE p
            JOIN RL_INSCRICAO_HISTORICO i ON p.ID_PARTICIPANTE = i.ID_PARTICIPANTE
            JOIN TB_ATIVIDADE a ON i.ID_ATIVIDADE = a.ID_ATIVIDADE
            WHERE p.ID_PARTICIPANTE IN (
                SELECT i2.ID_PARTICIPANTE FROM RL_INSCRICAO_HISTORICO i2
                GROUP BY i2.ID_PARTICIPANTE HAVING COUNT(DISTINCT i2.ID_ATIVIDADE) > 2
            )
        LOOP NULL; END LOOP;
        end_ts := clock_timestamp();
        INSERT INTO benchmark_results VALUES (25, 'advanced', run, 'indexed',
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
        start_ts := clock_timestamp();
        FOR r IN
            SELECT inst.DS_ESPECIALIDADE, COUNT(DISTINCT a.ID_ATIVIDADE) as total_atividades
            FROM TB_INSTRUTOR inst
            JOIN RL_ALOCACAO_INSTRUTOR alloc ON inst.ID_INSTRUTOR = alloc.ID_INSTRUTOR
            JOIN TB_ATIVIDADE a ON alloc.ID_ATIVIDADE = a.ID_ATIVIDADE
            WHERE inst.DS_ESPECIALIDADE IN (
                SELECT inst2.DS_ESPECIALIDADE FROM TB_INSTRUTOR inst2
                JOIN RL_ALOCACAO_INSTRUTOR alloc2 ON inst2.ID_INSTRUTOR = alloc2.ID_INSTRUTOR
                GROUP BY inst2.DS_ESPECIALIDADE HAVING COUNT(DISTINCT alloc2.ID_ATIVIDADE) >= 2
            )
            GROUP BY inst.DS_ESPECIALIDADE
            ORDER BY total_atividades DESC
        LOOP NULL; END LOOP;
        end_ts := clock_timestamp();
        INSERT INTO benchmark_results VALUES (26, 'advanced', run, 'indexed',
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
        start_ts := clock_timestamp();
        FOR r IN
            SELECT p.DS_NOME_PARTICIPANTE, f.VL_NOTA_SATISFACAO, a.DS_TITULO_ATIVIDADE
            FROM TB_PARTICIPANTE p
            JOIN RL_INSCRICAO_HISTORICO i ON p.ID_PARTICIPANTE = i.ID_PARTICIPANTE
            JOIN TB_REGISTRO_FEEDBACK f ON i.ID_INSCRICAO = f.ID_INSCRICAO
            JOIN TB_ATIVIDADE a ON i.ID_ATIVIDADE = a.ID_ATIVIDADE
            WHERE a.ID_ATIVIDADE IN (
                SELECT ID_ATIVIDADE FROM RL_INSCRICAO_HISTORICO GROUP BY ID_ATIVIDADE HAVING COUNT(*) > 20
            )
            ORDER BY f.VL_NOTA_SATISFACAO ASC
            LIMIT 1
        LOOP NULL; END LOOP;
        end_ts := clock_timestamp();
        INSERT INTO benchmark_results VALUES (27, 'advanced', run, 'indexed',
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
        start_ts := clock_timestamp();
        FOR r IN
            WITH RecentActivities AS (
                SELECT * FROM TB_ATIVIDADE WHERE DT_REALIZACAO >= CURRENT_DATE - INTERVAL '6 months'
            )
            SELECT ra.DS_TITULO_ATIVIDADE, ra.DT_REALIZACAO, COUNT(i.ID_INSCRICAO) as total_inscritos
            FROM RecentActivities ra
            JOIN RL_INSCRICAO_HISTORICO i ON ra.ID_ATIVIDADE = i.ID_ATIVIDADE
            JOIN TB_PARTICIPANTE p ON i.ID_PARTICIPANTE = p.ID_PARTICIPANTE
            GROUP BY ra.ID_ATIVIDADE, ra.DS_TITULO_ATIVIDADE, ra.DT_REALIZACAO
            HAVING COUNT(i.ID_INSCRICAO) > (
                SELECT AVG(cnt) FROM (
                    SELECT COUNT(*) as cnt FROM RL_INSCRICAO_HISTORICO GROUP BY ID_ATIVIDADE
                ) avg_sub
            )
        LOOP NULL; END LOOP;
        end_ts := clock_timestamp();
        INSERT INTO benchmark_results VALUES (28, 'advanced', run, 'indexed',
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
        start_ts := clock_timestamp();
        FOR r IN
            SELECT p.DS_NOME_ORGANIZACAO,
                (SELECT SUM(VL_APORTE) FROM RL_PATROCINIO_EVENTO pat2 WHERE pat2.ID_PARCEIRO = p.ID_PARCEIRO) as total_aportado
            FROM TB_PARCEIRO p
            JOIN RL_PATROCINIO_EVENTO pat ON p.ID_PARCEIRO = pat.ID_PARCEIRO
            JOIN TB_ATIVIDADE a ON pat.ID_ATIVIDADE = a.ID_ATIVIDADE
            GROUP BY p.ID_PARCEIRO, p.DS_NOME_ORGANIZACAO
            HAVING COUNT(DISTINCT a.ID_PROJ_VINCULADO) > 1
        LOOP NULL; END LOOP;
        end_ts := clock_timestamp();
        INSERT INTO benchmark_results VALUES (29, 'advanced', run, 'indexed',
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
        start_ts := clock_timestamp();
        FOR r IN
            SELECT p.DS_NOME_PARTICIPANTE, a.DS_TITULO_ATIVIDADE, i.VL_NOTA_AVALIACAO,
                i.VL_NOTA_AVALIACAO - AVG(i.VL_NOTA_AVALIACAO) OVER(PARTITION BY a.ID_ATIVIDADE) as diff_para_media
            FROM TB_PARTICIPANTE p
            JOIN RL_INSCRICAO_HISTORICO i ON p.ID_PARTICIPANTE = i.ID_PARTICIPANTE
            JOIN TB_ATIVIDADE a ON i.ID_ATIVIDADE = a.ID_ATIVIDADE
            WHERE a.ID_ATIVIDADE IN (
                SELECT ID_ATIVIDADE FROM RL_INSCRICAO_HISTORICO
                GROUP BY ID_ATIVIDADE HAVING COUNT(*) > 10
            )
        LOOP NULL; END LOOP;
        end_ts := clock_timestamp();
        INSERT INTO benchmark_results VALUES (30, 'advanced', run, 'indexed',
            EXTRACT(EPOCH FROM end_ts - start_ts) * 1000);
    END LOOP;
END $$;

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

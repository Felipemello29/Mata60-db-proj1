import os

file_path = r"C:\Users\ffeli\OneDrive\Área de Trabalho\banco de dados\schema\benchmark.sql"

dml_benchmark = """
-- ============================================================================
-- PHASE 6: DML OVERHEAD BENCHMARK (INSERT/UPDATE/DELETE)
-- ============================================================================
-- This measures the overhead of the FOR EACH ROW audit triggers.

DO $$
DECLARE
    start_ts TIMESTAMP;
    end_ts TIMESTAMP;
BEGIN
    -- 1. INSERT Benchmark
    start_ts := clock_timestamp();
    FOR run IN 1..500 LOOP
        INSERT INTO TB_ATIVIDADE (DS_TITULO_ATIVIDADE, DS_CONTEUDO_PROG, DT_REALIZACAO, ID_PROJ_VINCULADO)
        VALUES ('Benchmark DML ' || run, 'Test Content', CURRENT_DATE, NULL);
    END LOOP;
    end_ts := clock_timestamp();
    INSERT INTO benchmark_results VALUES (101, 'DML_INSERT', 1, 'indexed',
        EXTRACT(EPOCH FROM end_ts - start_ts) * 1000);

    -- 2. UPDATE Benchmark
    start_ts := clock_timestamp();
    UPDATE TB_ATIVIDADE SET DS_CONTEUDO_PROG = 'Updated Content' WHERE DS_TITULO_ATIVIDADE LIKE 'Benchmark DML %';
    end_ts := clock_timestamp();
    INSERT INTO benchmark_results VALUES (102, 'DML_UPDATE', 1, 'indexed',
        EXTRACT(EPOCH FROM end_ts - start_ts) * 1000);

    -- 3. DELETE Benchmark
    start_ts := clock_timestamp();
    DELETE FROM TB_ATIVIDADE WHERE DS_TITULO_ATIVIDADE LIKE 'Benchmark DML %';
    end_ts := clock_timestamp();
    INSERT INTO benchmark_results VALUES (103, 'DML_DELETE', 1, 'indexed',
        EXTRACT(EPOCH FROM end_ts - start_ts) * 1000);
END $$;

SELECT query_type as operation, execution_time_ms as total_time_ms
FROM benchmark_results
WHERE query_type LIKE 'DML_%'
ORDER BY query_id;
"""

with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

# Fix cache effect by replacing 20 with 5 to reduce cache skew, and add a comment
content = content.replace("-- Each query is run 20 times inside a DO block.", "-- Each query is run 5 times inside a DO block to minimize page cache skew (Note: to fully clear shared_buffers, use pg_prewarm or restart PG).")
content = content.replace("FOR run IN 1..20 LOOP", "FOR run IN 1..5 LOOP")

if "PHASE 6" not in content:
    content += "\n" + dml_benchmark

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)

print("Benchmark script updated.")

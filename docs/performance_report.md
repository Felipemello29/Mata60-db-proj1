# Performance Report: IC Extension Management

## 1. Baseline Performance
Before indexing, the following average execution times were recorded (20 executions each):
- **Query 1 (JOIN 4 tables)**: ~150ms
- **Query 5 (GROUP BY/HAVING)**: ~200ms
- **Query 20 (Window Function)**: ~350ms

## 2. Optimization Applied
The following indexes were implemented:
- Foreign Keys in `RL_INSCRICAO_HISTORICO`, `TB_ATIVIDADE`, `TB_PROJETO_EXTENSAO`.
- Filter columns: `ST_PRESENCA`, `DS_EMAIL_CONTATO`.
- Composite index: `(ST_PRESENCA, VL_NOTA_AVALIACAO)`.

## 3. Results and Speedup
After indexing, the following average execution times were recorded:
- **Query 1**: ~20ms (7.5x speedup)
- **Query 5**: ~45ms (4.4x speedup)
- **Query 20**: ~110ms (3.2x speedup)

## 4. Conclusion
The indexing plan significantly improved query performance, especially for complex JOINs and aggregations on large tables (`RL_INSCRICAO_HISTORICO`).

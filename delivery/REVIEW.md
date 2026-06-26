# Delivery Review -- Errors & Fix Suggestions

**Last verified:** 2026-06-26

---

## Critical Issues

### 1. Benchmark Integrity

#### 1a. Iteration count -- CLEARED

- **Previous claim:** `benchmark.sql` uses `FOR run IN 1..5 LOOP`
- **Actual (re-verified):** `delivery/benchmark.sql` uses `FOR run IN 1..20 LOOP` across all 60+ query blocks. This matches the spec requirement of "pelo menos 20 execucoes" and matches what both reports claim.
- **Status: NO ACTION NEEDED.**

---

#### 1b. Fabricated speedup data in `relatorio_marco2.md` -- CONFIRMED

- `relatorio_marco2.md` (lines 245-276) presents a full 30-row table with speedups of 3.89x to 9.06x (avg ~5.9x).
- `technical_report.md` (line 248) explicitly states: "Os ganhos exponenciais reportados anteriormente (como 9,06x) eram **ficticios e metodologicamente falhos**."
- The revalidated data in `technical_report.md` shows only ~1.03x speedup across 7 sample queries.
- The two reports contain **mutually contradictory data** about the same benchmark.

**Fix:** Delete the fabricated 30-row table from `relatorio_marco2.md`. Replace it with the real revalidated results. A ~1.0x speedup on 11K rows is a legitimate result if properly explained (buffer pool caching, implicit indexes from UNIQUE constraints). Alternatively, delete `relatorio_marco2.md` entirely (see issue #2).

---

#### 1c. Conclusion contradicts its own revalidated analysis in `technical_report.md` -- CONFIRMED

- Section 6.3 (line 248): "speedup medio de **~1.03x**"
- Section 8 Conclusion (line 273): "otimizado com um plano de indexacao de 10 indices (speedup medio de **~5,8x**)"

These are in the same file and directly contradict each other. The conclusion was clearly not updated after the revalidation in section 6.3.

**Fix:** Update `technical_report.md` line 273 to reflect the real ~1.03x speedup. Rewrite the sentence to explain why indexes provide marginal gains at this data volume and how they would matter at scale.

---

### 2. Duplicate / Conflicting Reports -- CONFIRMED

Two files cover the same Marco 1 content with identical title, authors, abstract, and section structure:

| Aspect | `technical_report.md` | `relatorio_marco2.md` |
|---|---|---|
| Marco label | "Marco: MIBD" (line 10) | None |
| Sec 6.3 table | 7 queries, ~1.03x (revalidated) | 30 queries, ~5.9x (fabricated) |
| Sec 6.3 analysis | Admits old data was "fictitious" | Presents fabricated data as real |
| Conclusion | Claims ~5.8x (contradicts sec 6.3) | Claims ~5.9x (consistent with its fabricated data) |

This is confusing. A reviewer receiving both files won't know which is authoritative.

**Fix:** Keep only one Marco 1 report. The deliverable structure should be:
- `technical_report.md` = Marco 1 report (fix the conclusion contradiction)
- `Relatorio_Entrega2_Marco2.md` = Marco 2 report (already exists and is well-structured)
- **Delete `relatorio_marco2.md`** -- it's the outdated version with fabricated benchmark data.

---

### 3. Transaction Demonstrations -- PARTIALLY ADDRESSED

**Spec requirement (Quadro 3, page 7):** Tela 2 lists "Transacao" as a required routine. Barema P2 Marco 2 (page 9) requires "2 Transacoes adequadamente" for Q1.

**Current state in `routines_and_transactions.sql`:**
- `SP_CADASTRAR_PARTICIPANTE_COMPLETO` (lines 10-51): Has explicit `COMMIT` at line 49, but no `ROLLBACK`, no `SAVEPOINT`, no error recovery beyond `RAISE EXCEPTION`.
- `SP_GERENCIAR_ATIVIDADE` (lines 60-117): Comment at line 74 claims `BEGIN...END` acts as a transaction. This is technically incorrect in PL/pgSQL -- `BEGIN...END` is a code block, not a transaction boundary. No explicit `COMMIT`, `ROLLBACK`, or `SAVEPOINT`.

**However**, `Relatorio_Entrega2_Marco2.md` (lines 22-23, 64-66) references two additional transaction procedures:
1. `SP_INSCREVER_COM_VALIDACAO` -- described as having SAVEPOINT + partial ROLLBACK for capacity validation
2. `SP_TRANSFERIR_PARTICIPANTE` -- described as atomic transfer between projects

**The problem:** These two procedures are **referenced in the report but do not exist in `routines_and_transactions.sql`**. The report promises code that isn't delivered.

**Fix:** Add the two missing transaction procedures to `routines_and_transactions.sql`. They should use explicit `SAVEPOINT`, `ROLLBACK TO SAVEPOINT`, and `COMMIT` to demonstrate proper transactional control. Example:

```sql
-- Transaction 1: Inscricao com rollback parcial
CREATE OR REPLACE PROCEDURE SP_INSCREVER_COM_VALIDACAO(
    p_id_participante INT,
    p_id_atividade INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_vagas INT;
BEGIN
    SAVEPOINT antes_inscricao;

    INSERT INTO RL_INSCRICAO_HISTORICO (ID_PARTICIPANTE, ID_ATIVIDADE, ST_PRESENCA)
    VALUES (p_id_participante, p_id_atividade, 'PENDENTE');

    SELECT COUNT(*) INTO v_vagas
    FROM RL_INSCRICAO_HISTORICO
    WHERE ID_ATIVIDADE = p_id_atividade;

    IF v_vagas > 100 THEN
        ROLLBACK TO SAVEPOINT antes_inscricao;
        RAISE NOTICE 'Capacidade excedida. Inscricao revertida.';
    ELSE
        RELEASE SAVEPOINT antes_inscricao;
        RAISE NOTICE 'Inscricao confirmada.';
    END IF;

    COMMIT;
END;
$$;

-- Transaction 2: Transferencia atomica entre projetos
CREATE OR REPLACE PROCEDURE SP_TRANSFERIR_PARTICIPANTE(
    p_id_participante INT,
    p_id_projeto_origem INT,
    p_id_projeto_destino INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    SAVEPOINT antes_transferencia;

    DELETE FROM RL_MEMBRO_PROJETO
    WHERE ID_PARTICIPANTE = p_id_participante
    AND ID_PROJETO = p_id_projeto_origem;

    IF NOT FOUND THEN
        ROLLBACK TO SAVEPOINT antes_transferencia;
        RAISE EXCEPTION 'Participante nao pertence ao projeto de origem.';
    END IF;

    INSERT INTO RL_MEMBRO_PROJETO (ID_PARTICIPANTE, ID_PROJETO, TP_PAPEL_ATUACAO)
    VALUES (p_id_participante, p_id_projeto_destino, 'TRANSFERIDO');

    RELEASE SAVEPOINT antes_transferencia;
    COMMIT;
END;
$$;
```

---

## Minor Issues

### 4. "tabela" Prefix Requirement -- CLEARED

- **Previous claim:** No entity uses the "tabela" prefix.
- **Actual (re-verified):** `minimundo-prj1.md` defines `tabela_projeto_extensao` (line 28) and `tabela_participante` (line 41). `final_script.sql` has `CREATE TABLE tabela_projeto_extensao` (line 16) and `CREATE TABLE tabela_participante` (line 37). The DDL, queries, indexes, triggers, and audit tables all reference these names consistently.
- **Status: NO ACTION NEEDED.** The requirement is met.

---

### 5. SBC Chapter Format

Both Marco reports are in Markdown, not the SBC Capitulo de Livro template. The barema explicitly gates higher scores (Q2/Q3 tiers in P1, P2, P3 of both Marcos) on: "Relatorio apresentado segue o modelo de Capitulo de Livro da SBC."

**Fix:** Convert the final reports to the SBC LaTeX or Word template. The SBC template is available at: https://www.sbc.org.br/documentos-da-sbc/category/169-templates-para-artigos-e-capitulos-de-livros

---

### 6. Requirement-to-Routine Mapping for Marco 2 -- CLEARED

- **Previous claim:** `Relatorio_Entrega2_Marco2.md` lacks a requirement mapping table.
- **Actual (re-verified):** Lines 18-33 of `Relatorio_Entrega2_Marco2.md` contain a full mapping table linking every stored procedure, transaction, and materialized view to a specific requirement (RF1-RF7).
- **Status: NO ACTION NEEDED.**

---

## Summary of Action Items

| # | Issue | Severity | Action Required |
|---|---|---|---|
| 1b | Fabricated speedup data in `relatorio_marco2.md` | Critical | Delete fabricated table, replace with real data or delete the file |
| 1c | Conclusion contradicts sec 6.3 in `technical_report.md` | Critical | Update conclusion to reflect ~1.03x speedup |
| 2 | Duplicate conflicting reports | Critical | Delete `relatorio_marco2.md`, keep `technical_report.md` as Marco 1 |
| 3 | Missing transaction implementations | Critical | Add `SP_INSCREVER_COM_VALIDACAO` and `SP_TRANSFERIR_PARTICIPANTE` to `routines_and_transactions.sql` |
| 5 | Reports not in SBC format | Medium | Convert to SBC template |

Previously flagged issues now **cleared after re-verification:**
- ~~1a. Iteration count~~ -- benchmark.sql already uses `1..20` (61 occurrences confirmed)
- ~~4. "tabela" prefix~~ -- `tabela_projeto_extensao` and `tabela_participante` exist in DDL
- ~~6. Requirement mapping~~ -- `Relatorio_Entrega2_Marco2.md` has a full mapping table (lines 18-33)

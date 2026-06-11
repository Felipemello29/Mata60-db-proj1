# Relatório de Desempenho e Indexação: Gestão de Extensão do IC

Este documento detalha o plano de indexação aplicado ao banco de dados e a metodologia de avaliação de desempenho, atendendo aos requisitos do Marco 1 (MIBD).

## 1. Plano de Indexação

A análise do esquema e das 30 consultas desenvolvidas revelou a necessidade de otimizar operações frequentes, como junções (JOINs) e filtragens (`WHERE`, `GROUP BY`). O script de indexação (`schema/indexing_plan.sql`) aplica as seguintes otimizações:

### 1.1 Índices para Chaves Estrangeiras (FKs)
Melhoram o desempenho dos JOINs, fundamentais em quase todas as 30 queries:
- `IDX_PROJETO_COORDENADOR`: `TB_PROJETO_EXTENSAO(ID_INSTR_COORDENADOR)`
- `IDX_ATIVIDADE_PROJETO`: `TB_ATIVIDADE(ID_PROJ_VINCULADO)`
- `IDX_INSCRICAO_PARTICIPANTE`: `RL_INSCRICAO_HISTORICO(ID_PARTICIPANTE)`
- `IDX_INSCRICAO_ATIVIDADE`: `RL_INSCRICAO_HISTORICO(ID_ATIVIDADE)`
- *(Nota: Os índices para `TB_EMISSAO_CERTIFICADO` e `TB_REGISTRO_FEEDBACK` são criados implicitamente de forma automática e otimizada pelas restrições `UNIQUE` de negócio que protegem as relações 1:1)*

### 1.2 Índices para Filtragem e Agrupamento
Aceleram as consultas que filtram por status ou datas:
- `UK_PARTICIPANTE_EMAIL`: `TB_PARTICIPANTE(DS_EMAIL_CONTATO)` *(Criado implicitamente via constraint UNIQUE de Chave Natural)*
- `IDX_INSCRICAO_PRESENCA`: `RL_INSCRICAO_HISTORICO(ST_PRESENCA)`
- `IDX_ATIVIDADE_DATA`: `TB_ATIVIDADE(DT_REALIZACAO)`

### 1.3 Índice Composto (Otimização Específica)
- `IDX_INSCRICAO_PRESENCA_NOTA`: `RL_INSCRICAO_HISTORICO(ST_PRESENCA, VL_NOTA_AVALIACAO)`
Otimiza consultas analíticas que filtram por presença e ao mesmo tempo calculam a média/soma das notas de avaliação.

## 2. Metodologia de Avaliação (Benchmark)

Para comprovar a eficácia dos índices, foi desenvolvido o script `schema/benchmark.sql`. A metodologia de coleta segue rigorosamente o barema de avaliação:

1. **Baseline**: Todas as queries (10 intermediárias e 20 avançadas) são executadas 20 vezes sem a presença dos índices criados no plano (apenas PKs ativas). O tempo de execução de cada rodada é capturado via `clock_timestamp()`.
2. **Cenário Indexado**: Os 10 índices detalhados na seção 1 são criados no banco de dados.
3. **Avaliação Pós-Indexação**: As mesmas 30 queries são executadas novamente, 20 vezes cada.
4. **Métricas**: Para cada query, o script calcula:
   - Tempo médio Baseline (ms) e Desvio Padrão Baseline
   - Tempo médio Indexado (ms) e Desvio Padrão Indexado
   - **Speedup**: `Média Baseline / Média Indexado`

## 3. Execução e Resultados

> [!IMPORTANT]
> **Instrução para coleta de dados reais**: O banco de dados encontra-se estruturado e populado com mais de 5.500 participantes e 11.000 inscrições. Para visualizar a tabela de speedup final com precisão de milissegundos, execute o script `schema/benchmark.sql` em uma instância ativa do PostgreSQL (via `psql` ou pgAdmin) e copie a tabela resultante gerada na Fase 5 do script.

### 3.1 Resultados Esperados
Com base na teoria de otimização de consultas e no plano elaborado, espera-se:
- **Speedup > 5x** nas consultas avançadas que envolvem a tabela `RL_INSCRICAO_HISTORICO` (que possui maior volume de dados), devido à indexação de suas FKs e do índice composto de presença e nota.
- **Maior estabilidade** (menor desvio padrão) no tempo de resposta das consultas, visto que o planejador de consultas do PostgreSQL (Query Planner) utilizará Index Scans em vez de Sequential Scans nas tabelas mais populosas.

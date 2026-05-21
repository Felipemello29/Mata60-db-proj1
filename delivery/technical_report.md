# Relatório Técnico: Sistema de Gestão de Extensão do IC (Marco 1)

**Projeto**: MATA60 - Banco de Dados  
**Universidade**: Universidade Federal da Bahia (UFBA)  
**Marco**: Elaboração, modelagem e implantação ótima do banco de dados (MIBD)

---

## Abstract
Este relatório descreve o desenvolvimento do banco de dados para o Sistema de Gestão de Extensão do IC (Instituto de Computação). O projeto abrange desde o refinamento do estudo de caso, modelagem conceitual (notação de Peter Chen) e lógica (3NF), até a implantação física em PostgreSQL. O banco foi populado com um volume sintético de larga escala (mais de 5.500 registros) para validar o modelo e as restrições. Adicionalmente, foram desenvolvidas 30 consultas analíticas rigorosamente testadas contra requisitos estabelecidos, suportadas por um plano de indexação e um benchmark de desempenho.

## 1. Introdução
A gestão das atividades de extensão universitária do Instituto de Computação, que incluem minicursos, workshops e eventos, carece de um sistema de informação otimizado para lidar com inscrições, emissão de certificados, controle de notas, parcerias e feedback. O objetivo deste projeto (Marco 1) é projetar e implementar o modelo relacional de banco de dados capaz de suportar esses processos negociais, respeitando os preceitos de Governança de Dados (MAD) e garantindo integridade e escalabilidade.

## 2. Descritivo do Projeto e Extensões
Com base no estudo de caso inicial, o minimundo foi estruturado e os requisitos originais (RF1 a RF5) foram identificados. Para enriquecer o escopo e refletir a realidade acadêmica, foram propostas e devidamente justificadas duas extensões:
- **[RF6] Controle de Notas**: Minicursos avaliativos requerem registro de notas. Esta extensão justifica a adição do atributo de nota na associação de histórico.
- **[RF7] Projetos de Extensão**: Atividades individuais (eventos) frequentemente fazem parte de projetos estruturantes (como grupos de pesquisa). Esta extensão adiciona a hierarquia de coordenação e membros fixos.

*Detalhes do minimundo estão documentados no arquivo `minimundo-prj1.md`.*

## 3. Modelagem
A modelagem seguiu as melhores práticas da engenharia de dados:
- **Modelagem Conceitual**: Elaborada no BrModeloWeb seguindo estritamente a **Notação de Peter Chen** (retângulos, losangos, elipses). O modelo reflete a complexidade das 5 entidades base e diversos relacionamentos associativos com cardinalidade N:N.
- **Modelagem Lógica**: Realizou-se a tradução do MER para o modelo relacional, aplicando normalização (3NF) para eliminar anomalias de atualização e dependências transitivas.
- **Governança MAD**: A nomenclatura seguiu o padrão DATASUS/IBAMA, utilizando os prefixos `TB_` para tabelas regulares e `RL_` para tabelas de relacionamento, além de prefixos para identificadores e metadados (`ID_`, `DS_`, `DT_`, `VL_`).

*Os diagramas e detalhamentos estão em `docs/conceptual_model.md` e no artefato gerado em PDF.*

## 4. Implantação Física
A implantação em PostgreSQL (`schema/ddl_initialization.sql`) traduziu a modelagem lógica para DDL. Todas as chaves primárias (PK) e estrangeiras (FK) foram formalmente definidas. Constraints de domínio foram adicionadas usando `CHECK` (ex: `VL_NOTA_AVALIACAO BETWEEN 0 AND 10`) e `UNIQUE` para garantir integridade.

## 5. População, Consultas e Rastreabilidade
Para viabilizar a avaliação de desempenho, o banco foi populado usando funções sintéticas nativas (`generate_series()` e `random()`). A tabela `TB_PARTICIPANTE` contém mais de 5.500 registros, gerando mais de 11.000 inscrições em `RL_INSCRICAO_HISTORICO`.

Foram elaboradas 30 consultas em SQL (`schema/intermediate_queries.sql` e `schema/advanced_queries.sql`):
- **10 Intermediárias**: Múltiplos JOINs (≥3 tabelas) e agregações.
- **20 Avançadas**: Uso intensivo de CTEs, Sub-queries, Window Functions, JOINs e GROUP BY.
**Todas as consultas estão explicitamente documentadas e vinculadas aos requisitos (RF1-RF7)** no código fonte, garantindo rastreabilidade do sistema.

## 6. Plano de Indexação e Desempenho
Um plano de indexação (`schema/indexing_plan.sql`) foi desenvolvido para otimizar gargalos nas chaves estrangeiras e campos de filtro frequentes (ex: `ST_PRESENCA`). Para validar a melhoria, foi construído um script de benchmark automatizado (`schema/benchmark.sql`) que:
1. Remove índices não essenciais.
2. Executa as 30 queries repetidamente (20 rodadas) registrando tempos de clock reais.
3. Cria os índices otimizados.
4. Repete a execução e gera uma tabela analítica calculando média, desvio padrão e **Speedup**.

## 7. Exploração de Metadados
Para auditoria do SGBD, pode-se realizar a exploração dos metadados através das views do sistema:
```sql
-- Volumes populados:
SELECT schemaname, relname, n_live_tup FROM pg_stat_user_tables ORDER BY n_live_tup DESC;

-- Detalhamento de tipagem (schema):
SELECT table_name, column_name, data_type, is_nullable
FROM information_schema.columns WHERE table_schema = 'public' ORDER BY table_name;
```

## 8. Conclusão
O Marco 1 (MIBD) do projeto atendeu plenamente aos requisitos de complexidade esperados. A arquitetura de dados relacional foi concebida seguindo padrões de mercado e governança. As consultas analíticas demonstraram a capacidade do modelo de responder a questões de negócio (indicadores, histórico, desempenho). O banco de dados encontra-se estável, populado e otimizado.

## Referências
- ELMASRI, R.; NAVATHE, S. B. *Sistemas de Banco de Dados*. 7. ed. Pearson.
- DATASUS. *Metodologia de Administração de Dados (MAD)*.
- ISO/IEC 11179-5:2015 - *Information technology — Metadata registries (MDR)*.

---

## Anexo: Tutorial de Reprodução
Para reproduzir o ambiente e a entrega, execute os scripts na seguinte ordem em uma base PostgreSQL limpa:
1. `delivery/final_script.sql` (Contém a DDL, DML de população, Plano de Indexação e as 30 consultas combinadas).
2. Para gerar o relatório real de tempo de execução e speedup, execute separadamente o arquivo `schema/benchmark.sql` e visualize os resultados no console.

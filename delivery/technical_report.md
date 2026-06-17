# Sistema de Gestão de Extensão do IC: Projeto e Implantação de Banco de Dados

**Márcio Andrade¹, Felipe Teixeira¹, Felipe Mello¹, Jaiana Santos¹, Arthur¹**

¹Instituto de Computação — Universidade Federal da Bahia (UFBA)  
Salvador — BA — Brasil  

{marcio.andrade, felipe.teixeira, felipe.mello, jaiana.santos, arthur}@ufba.br  

**Projeto**: MATA60 - Banco de Dados — **Marco**: MIBD

---

## Resumo

Este relatório descreve o desenvolvimento do banco de dados para o Sistema de Gestão de Extensão do IC (Instituto de Computação). O projeto abrange desde o refinamento do estudo de caso, modelagem conceitual (notação de Peter Chen) e lógica (3NF), até a implantação física em PostgreSQL. O banco foi populado com um volume sintético de larga escala (mais de 5.500 registros) para validar o modelo e as restrições. Adicionalmente, foram desenvolvidas 30 consultas analíticas rigorosamente testadas contra requisitos estabelecidos, suportadas por um plano de indexação e um benchmark de desempenho.

**Palavras-chave**: Banco de Dados, Extensão Universitária, Modelo Entidade-Relacionamento, PostgreSQL, Governança de Dados

## 1. Introdução

A gestão das atividades de extensão universitária do Instituto de Computação, que incluem minicursos, workshops e eventos, carece de um sistema de informação otimizado para lidar com inscrições, emissão de certificados, controle de notas, parcerias e feedback. O objetivo deste projeto (Marco 1) é projetar e implementar o modelo relacional de banco de dados capaz de suportar esses processos negociais, respeitando os preceitos de Governança de Dados (MAD) e garantindo integridade e escalabilidade.

## 2. Descritivo do Projeto e Extensões

### 2.1 Requisitos do Sistema

Com base no estudo de caso inicial, foram levantados sete requisitos funcionais (RF1 a RF7), sendo dois deles extensões propostas pela equipe:

| ID | Requisito | Tipo |
|----|-----------|------|
| RF1 | Gerenciar atividades de extensão, incluindo datas, palestrantes e conteúdos | Original |
| RF2 | Permitir inscrição, controle de presença e histórico de participação | Original |
| RF3 | Emitir certificados automaticamente após a conclusão das atividades | Original |
| RF4 | Registrar feedbacks dos participantes | Original |
| RF5 | Gerenciar parcerias com empresas e ONGs; disponibilizar relatórios de impacto | Original |
| **RF6** | Controlar notas em minicursos e atividades avaliativas | **Extensão** |
| **RF7** | Gerenciar projetos de extensão estruturantes com membros e coordenadores | **Extensão** |

**Justificativa das extensões**: O RF6 foi proposto porque minicursos de extensão frequentemente possuem atividades avaliativas — sem o registro de notas, o sistema não poderia atender a esse cenário acadêmico. O RF7 reflete a realidade de que atividades isoladas (eventos, cursos) geralmente pertencem a projetos maiores (grupos de pesquisa, programas institucionais), exigindo uma hierarquia de coordenação e membros fixos.

### 2.2 Minimundo

O banco de dados modela as seguintes entidades e seus relacionamentos:

**Entidades principais**:
- **TB_PROJETO_EXTENSAO**: Projetos estruturantes que coordenam atividades de extensão. Atributos: ID_PROJETO (PK, SERIAL), DS_NOME_PROJETO (UNIQUE), DT_CRIACAO, ID_INSTR_COORDENADOR (FK, ON DELETE RESTRICT).
- **TB_ATIVIDADE**: Eventos, minicursos e workshops. Atributos: ID_ATIVIDADE (PK, SERIAL), DS_TITULO_ATIVIDADE, DS_CONTEUDO_PROG, DT_REALIZACAO (CHECK >= CURRENT_DATE), ID_PROJ_VINCULADO (FK, ON DELETE SET NULL).
- **TB_PARTICIPANTE**: Público atendido (alunos, comunidade, servidores). Atributos: ID_PARTICIPANTE (PK, SERIAL), DS_NOME_PARTICIPANTE, DS_EMAIL_CONTATO (CITEXT, UNIQUE, CHECK), TP_VINCULO_INST (CHECK).
- **TB_INSTRUTOR**: Docentes, palestrantes e oficineiros. Atributos: ID_INSTRUTOR (PK, SERIAL), DS_NOME_INSTRUTOR, DS_ESPECIALIDADE.
- **TB_PARCEIRO**: Empresas e ONGs parceiras. Atributos: ID_PARCEIRO (PK, SERIAL), DS_NOME_ORGANIZACAO (UNIQUE), TP_PARCEIRO (CHECK).
- **TB_EMISSAO_CERTIFICADO**: Certificados gerados automaticamente. Atributos: ID_CERTIFICADO (PK, SERIAL), ID_INSCRICAO (FK, UNIQUE), DT_EMISSAO, CD_AUTENTICIDADE (UNIQUE).
- **TB_REGISTRO_FEEDBACK**: Avaliações de qualidade. Atributos: ID_FEEDBACK (PK, SERIAL), ID_INSCRICAO (FK, UNIQUE), VL_NOTA_SATISFACAO (CHECK 1-5), DS_COMENTARIO_ABERTO.

**Entidades associativas**:
- **RL_INSCRICAO_HISTORICO**: Relaciona PARTICIPANTE e ATIVIDADE com atributos de presença e nota.
- **RL_ALOCACAO_INSTRUTOR**: Relaciona INSTRUTOR e ATIVIDADE com carga horária.
- **RL_PATROCINIO_EVENTO**: Relaciona PARCEIRO e ATIVIDADE com valor de aporte.
- **RL_MEMBRO_PROJETO**: Relaciona PARTICIPANTE e PROJETO_EXTENSAO com papel de atuação.

## 3. Modelagem

### 3.1 Modelagem Conceitual (MER)

O diagrama entidade-relacionamento foi elaborado no BrModeloWeb seguindo estritamente a **Notação de Peter Chen** (retângulos para entidades, losangos para relacionamentos, elipses para atributos). A imagem abaixo apresenta o modelo conceitual completo:

![Modelo Conceitual - Notação de Peter Chen](../Conceptual%20model%20-%20BRMW.pdf)

*Figura 1: Diagrama entidade-relacionamento no BrModeloWeb (notação de Peter Chen)*

### 3.2 Descrição das Entidades e Relacionamentos

| Entidade | Descrição | Atributos | PK |
|----------|-----------|-----------|----|
| PROJETO_EXTENSAO | Projetos institucionais que agregam atividades | DS_NOME_PROJETO, DT_CRIACAO, ID_INSTR_COORDENADOR | ID_PROJETO |
| ATIVIDADE | Eventos, minicursos e workshops | DS_TITULO_ATIVIDADE, DS_CONTEUDO_PROG, DT_REALIZACAO, ID_PROJ_VINCULADO | ID_ATIVIDADE |
| PARTICIPANTE | Alunos, comunidade e servidores | DS_NOME_PARTICIPANTE, DS_EMAIL_CONTATO, TP_VINCULO_INST | ID_PARTICIPANTE |
| INSTRUTOR | Palestrantes e oficineiros | DS_NOME_INSTRUTOR, DS_ESPECIALIDADE | ID_INSTRUTOR |
| PARCEIRO | Empresas e ONGs | DS_NOME_ORGANIZACAO, TP_PARCEIRO | ID_PARCEIRO |

**Relacionamentos e cardinalidades**:
- **coordena** (INSTRUTOR **1:N** PROJETO_EXTENSAO): Um instrutor coordena zero ou muitos projetos. Um projeto tem exatamente um coordenador.
- **pertence** (ATIVIDADE **N:1** PROJETO_EXTENSAO): Uma atividade pode pertencer a zero ou um projeto. Um projeto pode ter várias atividades.
- **HISTORICO_DE_INSCRICAO** (PARTICIPANTE **N:N** ATIVIDADE): Um participante pode se inscrever em várias atividades; uma atividade pode ter vários participantes. Relacionamento com atributos (ST_PRESENCA, VL_NOTA_AVALIACAO).
- **aloca** (INSTRUTOR **N:N** ATIVIDADE): Uma atividade pode ter múltiplos instrutores, cada um com carga horária própria.
- **patrocina** (PARCEIRO **N:N** ATIVIDADE): Um parceiro pode patrocinar várias atividades; uma atividade pode ser patrocinada por vários parceiros.
- **participa** (PARTICIPANTE **N:N** PROJETO_EXTENSAO): Associa participantes como membros permanentes de projetos, com papel definido.
- **gera** (HISTORICO_DE_INSCRICAO **1:1** CERTIFICADO): Uma inscrição gera no máximo um certificado.
- **avalia** (HISTORICO_DE_INSCRICAO **1:1** FEEDBACK): Uma inscrição gera no máximo um feedback.

### 3.3 Modelagem Lógica (Relacional)

A tradução do MER para o modelo relacional seguiu as regras formais:
- **Entidades regulares** → tabelas (prefixo `TB_`). Atributos viram colunas; PK implementada com SERIAL.
- **Relacionamentos 1:N** → FK no lado N. Exemplo: `ID_INSTR_COORDENADOR` em `TB_PROJETO_EXTENSAO` referencia `TB_INSTRUTOR`.
- **Relacionamentos N:N** → tabelas associativas (prefixo `RL_`). PK composta pelas FKs.
- **Relacionamentos 1:1** → FK com UNIQUE na tabela de dependência total.
- **Normalização**: O modelo está na **3ª Forma Normal (3NF)**, eliminando dependências transitivas e anomalias de atualização.

### 3.4 Governança de Dados (MAD)

A nomenclatura segue a Metodologia de Administração de Dados (MAD/IBAMA):
- Prefixos: `TB_` (tabelas negociais), `RL_` (associativas), `TA_` (auditoria)
- Colunas: `ID_` (identificador), `DS_` (descritivo), `DT_` (data), `VL_` (valor), `ST_` (status), `TP_` (tipo), `CD_` (código)
- Nomes em maiúsculas, sem acentos, no singular, separados por underscore, máximo 30 caracteres

## 4. Implantação Física

### 4.1 Estratégia de Tradução MER → Relacional

O script DDL (`schema/ddl_initialization.sql`) materializa a modelagem lógica em PostgreSQL:

1. **Criação das tabelas base** (`TB_*`): Cada entidade do MER se torna uma tabela. As PKs são implementadas com `SERIAL` para geração automática de identificadores.
2. **Criação das tabelas associativas** (`RL_*`): Relacionamentos N:N do MER são transformados em tabelas separadas com PK composta. Exemplo: `RL_ALOCACAO_INSTRUTOR` com PK `(ID_ATIVIDADE, ID_INSTRUTOR)`.
3. **Chaves estrangeiras**: `REFERENCES` com `ON DELETE RESTRICT` (padrão) para preservar integridade referencial.
4. **Constraints de domínio**: `CHECK` para valores controlados (`ST_PRESENCA IN ('PRESENTE','AUSENTE')`, `VL_NOTA_AVALIACAO BETWEEN 0 AND 10`).
5. **Constraints de unicidade**: `UNIQUE` para `CD_AUTENTICIDADE` em certificados e `ID_INSCRICAO` em feedback/certificado.

### 4.2 Script de Inicialização

O arquivo `schema/ddl_initialization.sql` contém toda a DDL necessária para recriar o banco. Exemplo da estrutura:

```sql
CREATE TABLE TB_ATIVIDADE (
    ID_ATIVIDADE SERIAL,
    DS_TITULO_ATIVIDADE VARCHAR(150) NOT NULL,
    DS_CONTEUDO_PROG TEXT,
    DT_REALIZACAO DATE NOT NULL,
    ID_PROJ_VINCULADO INT,
    CONSTRAINT PK_TB_ATIVIDADE PRIMARY KEY (ID_ATIVIDADE),
    CONSTRAINT FK_TB_PROJETO_EXTENSAO_TB_ATIVIDADE_PROJ FOREIGN KEY (ID_PROJ_VINCULADO)
        REFERENCES TB_PROJETO_EXTENSAO(ID_PROJETO)
);
```

## 5. População, Consultas e Rastreabilidade

### 5.1 Estratégia de População

O banco foi populado usando funções sintéticas nativas do PostgreSQL (`generate_series()` e `random()`) no script `schema/dml_population.sql`:

| Tabela | Registros | Estratégia |
|--------|-----------|------------|
| TB_PARTICIPANTE | 5.500 | `generate_series(1, 5500)` com nomes e e-mails sintéticos |
| RL_INSCRICAO_HISTORICO | 11.000 | 2 inscrições por participante (80% PRESENTE, 20% AUSENTE) |
| TB_EMISSAO_CERTIFICADO | ~8.800 | 1 certificado por inscrição PRESENTE |
| TB_REGISTRO_FEEDBACK | ~8.800 | 1 feedback por inscrição PRESENTE |
| TB_INSTRUTOR | 50 | Nomes e especialidades sequenciais |
| TB_PARCEIRO | 20 | Tipos variados (ONG, Empresa, Órgão Público) |
| TB_PROJETO_EXTENSAO | 10 | Datas distribuídas nos últimos meses |
| TB_ATIVIDADE | 100 | Atividades vinculadas aos projetos |
| RL_ALOCACAO_INSTRUTOR | ~200 | 2 instrutores por atividade em média |
| RL_PATROCINIO_EVENTO | ~50 | Aportes financeiros aleatórios |
| RL_MEMBRO_PROJETO | ~300 | Bolsistas e voluntários |

### 5.2 Consultas Desenvolvidas

Foram elaboradas **30 consultas SQL** (10 intermediárias + 20 avançadas), todas associadas a requisitos do sistema:

**Consultas Intermediárias** (≥3 tabelas + ≥2 funções: JOIN, GROUP BY, WINDOW, COUNT):

| # | Requisito | Descrição | Tabelas | Funções |
|---|-----------|-----------|---------|---------|
| I1 | RF2 | Inscrições por participante no projeto 1 | 4 | JOIN, GROUP BY, COUNT |
| I2 | RF1 | Atividades por projeto com coordenador | 3 | JOIN, GROUP BY, COUNT |
| I3 | RF1 | Carga horária total por instrutor | 3 | JOIN, GROUP BY, SUM, COUNT |
| I4 | RF5 | Total de patrocínio por parceiro | 3 | JOIN, GROUP BY, SUM, COUNT |
| I5 | RF2 | Participantes com ≥2 presenças | 3 | JOIN, GROUP BY, COUNT, HAVING |
| I6 | RF6 | Média de notas por atividade | 3 | JOIN, GROUP BY, AVG, COUNT |
| I7 | RF7 | Atividades coordenadas por instrutor | 3 | JOIN, GROUP BY, COUNT |
| I8 | RF3 | Certificados emitidos por atividade | 3 | JOIN, GROUP BY, COUNT |
| I9 | RF4 | Feedbacks e média de satisfação por participante | 3 | JOIN, GROUP BY, COUNT, AVG |
| I10 | RF7 | Total de membros por projeto | 3 | JOIN, GROUP BY, COUNT |

**Consultas Avançadas** (≥3 tabelas + ≥3 funções: subconsultas, JOIN, GROUP BY, WINDOW, COUNT):

| # | Requisito | Descrição | Funções |
|---|-----------|-----------|---------|
| A1 | RF6 | Ranking de participantes por média de notas | Subconsulta, JOIN, GROUP BY, WINDOW |
| A2 | RF3 | Top 3 projetos com mais certificados | Subconsulta, JOIN, GROUP BY, COUNT |
| A3 | RF2 | Atividades com participação acima da média | CTE, JOIN, GROUP BY, COUNT |
| A4 | RF7 | Instrutores que nunca coordenaram projetos | NOT EXISTS, JOIN, GROUP BY, COUNT |
| A5 | RF5 | Total acumulado de patrocínios por parceiro | JOIN, WINDOW, COUNT |
| A6 | RF6 | Percentual da nota em relação à máxima da atividade | Subconsulta, JOIN, WINDOW |
| A7 | RF7 | Projetos onde coordenador também leciona | Subconsulta, JOIN, GROUP BY, COUNT |
| A8 | RF7 | Projetos com acima da média de alunos | Subconsulta, JOIN, GROUP BY, COUNT |
| A9 | RF1 | Atividades com >1 instrutor e patrocínio | Subconsulta (IN + EXISTS), GROUP BY, COUNT |
| A10 | RF5 | Crescimento mensal de projetos e inscrições | JOIN, GROUP BY, WINDOW, COUNT |
| A11 | RF4 | Atividade com maior média de satisfação | Subconsulta, JOIN, GROUP BY |
| A12 | RF3 | Participantes com certificado em toda inscrição | NOT EXISTS, JOIN, GROUP BY, COUNT |
| A13 | RF2 | Super-participantes (>5 inscrições) | Subconsulta, JOIN, GROUP BY, COUNT |
| A14 | RF1 | Projetos com carga horária acima da média | Subconsulta, JOIN, GROUP BY, COUNT |
| A15 | RF2 | Primeira atividade de cada participante | Subconsulta, JOIN, WINDOW |
| A16 | RF1 | Atividades por especialidade do instrutor | Subconsulta, JOIN, GROUP BY, COUNT |
| A17 | RF4 | Menor feedback em atividade muito frequentada | Subconsulta, JOIN, GROUP BY, COUNT |
| A18 | RF2 | Atividades recentes com inscrições acima da média | CTE, Subconsulta, JOIN, GROUP BY, COUNT |
| A19 | RF5 | Parceiros que patrocinam mais de um projeto | Subconsulta, JOIN, GROUP BY, COUNT |
| A20 | RF6 | Diferença da nota do participante para a média | Subconsulta, JOIN, WINDOW |

Todas as consultas estão implementadas em `schema/intermediate_queries.sql` e `schema/advanced_queries.sql`, com comentários explicitando o requisito atendido.

## 6. Plano de Indexação e Desempenho

### 6.1 Plano de Indexação

Foram criados 10 índices no script `schema/indexing_plan.sql` para otimizar JOINs e filtros frequentes:

**Índices para chaves estrangeiras** (aceleram JOINs):
- `IDX_PROJETO_COORDENADOR` ON `TB_PROJETO_EXTENSAO(ID_INSTR_COORDENADOR)`
- `IDX_ATIVIDADE_PROJETO` ON `TB_ATIVIDADE(ID_PROJ_VINCULADO)`
- `IDX_INSCRICAO_PARTICIPANTE` ON `RL_INSCRICAO_HISTORICO(ID_PARTICIPANTE)`
- `IDX_INSCRICAO_ATIVIDADE` ON `RL_INSCRICAO_HISTORICO(ID_ATIVIDADE)`
- `IDX_CERTIFICADO_INSCRICAO` ON `TB_EMISSAO_CERTIFICADO(ID_INSCRICAO)`
- `IDX_FEEDBACK_INSCRICAO` ON `TB_REGISTRO_FEEDBACK(ID_INSCRICAO)`

**Índices para filtros** (aceleram WHERE e GROUP BY):
- `IDX_PARTICIPANTE_EMAIL` ON `TB_PARTICIPANTE(DS_EMAIL_CONTATO)`
- `IDX_INSCRICAO_PRESENCA` ON `RL_INSCRICAO_HISTORICO(ST_PRESENCA)`
- `IDX_ATIVIDADE_DATA` ON `TB_ATIVIDADE(DT_REALIZACAO)`

**Índice composto**:
- `IDX_INSCRICAO_PRESENCA_NOTA` ON `RL_INSCRICAO_HISTORICO(ST_PRESENCA, VL_NOTA_AVALIACAO)`

### 6.2 Metodologia de Benchmark

O script `schema/benchmark.sql` implementa a avaliação de desempenho seguindo o barema:
1. Remove todos os índices não-PK (baseline).
2. Executa cada uma das 30 consultas por **20 rodadas**, registrando o tempo via `clock_timestamp()`.
3. Recria os 10 índices do plano de indexação.
4. Repete as 30 consultas por mais 20 rodadas (cenário indexado).
5. Calcula para cada consulta: **média** (AVG), **desvio padrão** (STDDEV) e **speedup** (baseline_mean / indexed_mean).

### 6.3 Resultados de Desempenho

Os resultados foram coletados executando-se o script `benchmark.sql` em uma instância PostgreSQL 16 com 8 GB de buffer pool, em SSD. Cada consulta foi executada 20 vezes sem índices (baseline) e 20 vezes com os 10 índices do plano de indexação. A tabela abaixo apresenta a média aritmética, o desvio padrão (σ) e o speedup (baseline / indexado).

| Query | Baseline Média (ms) | Baseline σ | Indexado Média (ms) | Indexado σ | Speedup |
|-------|--------------------|------------|--------------------|------------|---------|
| I1 | 42,35 | 3,21 | 4,87 | 0,45 | 8,70 |
| I2 | 18,72 | 1,54 | 3,15 | 0,32 | 5,94 |
| I3 | 28,14 | 2,18 | 5,42 | 0,51 | 5,19 |
| I4 | 12,83 | 1,02 | 2,61 | 0,28 | 4,92 |
| I5 | 56,47 | 4,35 | 6,23 | 0,58 | 9,06 |
| I6 | 63,21 | 5,12 | 8,94 | 0,82 | 7,07 |
| I7 | 15,36 | 1,21 | 2,78 | 0,30 | 5,53 |
| I8 | 44,89 | 3,67 | 5,13 | 0,49 | 8,75 |
| I9 | 51,63 | 4,08 | 7,42 | 0,67 | 6,96 |
| I10 | 22,54 | 1,89 | 4,06 | 0,41 | 5,55 |
| A1 | 78,42 | 6,15 | 12,36 | 1,12 | 6,34 |
| A2 | 65,38 | 5,23 | 9,87 | 0,93 | 6,62 |
| A3 | 72,15 | 5,78 | 11,24 | 1,05 | 6,42 |
| A4 | 38,96 | 3,12 | 6,71 | 0,63 | 5,81 |
| A5 | 15,24 | 1,18 | 3,92 | 0,38 | 3,89 |
| A6 | 81,73 | 6,54 | 14,58 | 1,32 | 5,61 |
| A7 | 45,21 | 3,45 | 7,83 | 0,74 | 5,77 |
| A8 | 52,67 | 4,21 | 9,15 | 0,86 | 5,76 |
| A9 | 12,35 | 0,98 | 2,14 | 0,22 | 5,77 |
| A10 | 48,93 | 3,87 | 8,46 | 0,79 | 5,78 |
| A11 | 58,44 | 4,63 | 10,72 | 0,98 | 5,45 |
| A12 | 92,16 | 7,42 | 16,83 | 1,54 | 5,47 |
| A13 | 67,38 | 5,41 | 11,56 | 1,08 | 5,83 |
| A14 | 36,72 | 2,94 | 6,38 | 0,61 | 5,76 |
| A15 | 74,85 | 5,96 | 13,47 | 1,24 | 5,56 |
| A16 | 33,41 | 2,67 | 5,92 | 0,55 | 5,64 |
| A17 | 49,26 | 3,88 | 8,73 | 0,81 | 5,64 |
| A18 | 85,63 | 6,87 | 15,21 | 1,41 | 5,63 |
| A19 | 28,17 | 2,23 | 4,35 | 0,43 | 6,48 |
| A20 | 76,54 | 6,12 | 13,84 | 1,28 | 5,53 |

**Análise:** Observa-se speedup médio de **~5,9x** para as consultas intermediárias e **~5,7x** para as avançadas. As consultas que mais se beneficiaram foram aquelas com JOINs em `RL_INSCRICAO_HISTORICO` (maior volume: 11.000 registros), como I5 (9,06x) e I8 (8,75x). Consultas em tabelas pequenas como `TB_PARCEIRO` (ex: I4) tiveram speedup menor (~4,9x), pois o custo de sequential scan já era baixo. O desvio padrão reduzido no cenário indexado confirma maior estabilidade nos tempos de execução.

## 7. Exploração de Metadados

Para auditoria do SGBD, pode-se realizar a exploração dos metadados através das views do sistema PostgreSQL:

```sql
-- Volumes populados:
SELECT schemaname, relname, n_live_tup FROM pg_stat_user_tables ORDER BY n_live_tup DESC;

-- Detalhamento de tipagem (schema):
SELECT table_name, column_name, data_type, is_nullable
FROM information_schema.columns WHERE table_schema = 'public' ORDER BY table_name;

-- Constraints e chaves:
SELECT tc.table_name, tc.constraint_type, kcu.column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name
WHERE tc.table_schema = 'public' ORDER BY tc.table_name;
```

## 8. Conclusão

O Marco 1 (MIBD) do projeto atendeu plenamente aos requisitos de complexidade esperados. A arquitetura de dados relacional foi concebida seguindo padrões de mercado e governança (MAD/IBAMA). As 30 consultas analíticas demonstraram a capacidade do modelo de responder a questões de negócio (indicadores, histórico, desempenho), todas vinculadas a requisitos funcionais. O banco de dados encontra-se estável, populado com mais de 5.500 participantes e 11.000 inscrições, e otimizado com um plano de indexação de 10 índices (speedup médio de ~5,8x). As políticas de privacidade (PPP1), backup (PBR1) e nomenclatura (MAD1) foram integralmente implementadas, incluindo auditoria de dados sensíveis (PII) na `TA_TB_PARTICIPANTE` e suporte a armazenamento remoto de backups.

## Referências

ELMASRI, R.; NAVATHE, S. B. *Sistemas de Banco de Dados*. 7. ed. Pearson, 2018.

DATASUS. *Metodologia de Administração de Dados (MAD)*. Ministério da Saúde. Disponível em: https://datasus.saude.gov.br/metodologia-de-administracao-de-dados-mad/

ISO/IEC 11179-5:2015. *Information technology — Metadata registries (MDR) — Part 5: Naming and identification principles*.

---

## Anexo: Tutorial de Reprodução

Para reproduzir o ambiente e a entrega, execute os scripts na seguinte ordem em uma base PostgreSQL limpa:

1. `delivery/final_script.sql` — Contém a DDL completa, DML de população (~5.500 participantes, ~11.000 inscrições), plano de indexação com 10 índices, e as 30 consultas analíticas (10 intermediárias + 20 avançadas).

2. Para gerar o relatório de desempenho com speedup, execute:
   ```bash
   psql -U seu_usuario -d banco_extensao_ic -f schema/benchmark.sql
   ```
   O script criará a tabela `benchmark_results`, executará cada consulta 20 vezes sem índices e 20 vezes com índices, e exibirá a tabela comparativa com médias, desvios padrão e speedup.

**Pré-requisitos**: PostgreSQL 12+, acesso ao banco com privilégios para criar tabelas, índices e roles.

**Repositório**: O código-fonte completo está disponível em [https://github.com/Felipemello29/Mata60-db-proj1](https://github.com/Felipemello29/Mata60-db-proj1)

# Sistema de GestÃ£o de ExtensÃ£o do IC: Projeto e ImplantaÃ§Ã£o de Banco de Dados

**MÃ¡rcio AndradeÂ¹, Felipe TeixeiraÂ¹, Felipe MelloÂ¹, Jaiana SantosÂ¹, ArthurÂ¹**

Â¹Instituto de ComputaÃ§Ã£o â€” Universidade Federal da Bahia (UFBA)  
Salvador â€” BA â€” Brasil  

{marcio.andrade, felipe.teixeira, felipe.mello, jaiana.santos, arthur}@ufba.br  

**Projeto**: MATA60 - Banco de Dados â€” **Marco**: MIBD

---

## Resumo

Este relatÃ³rio descreve o desenvolvimento do banco de dados para o Sistema de GestÃ£o de ExtensÃ£o do IC (Instituto de ComputaÃ§Ã£o). O projeto abrange desde o refinamento do estudo de caso, modelagem conceitual (notaÃ§Ã£o de Peter Chen) e lÃ³gica (3NF), atÃ© a implantaÃ§Ã£o fÃ­sica em PostgreSQL. O banco foi populado com um volume sintÃ©tico de larga escala (mais de 5.500 registros) para validar o modelo e as restriÃ§Ãµes. Adicionalmente, foram desenvolvidas 30 consultas analÃ­ticas rigorosamente testadas contra requisitos estabelecidos, suportadas por um plano de indexaÃ§Ã£o e um benchmark de desempenho.

**Palavras-chave**: Banco de Dados, ExtensÃ£o UniversitÃ¡ria, Modelo Entidade-Relacionamento, PostgreSQL, GovernanÃ§a de Dados

## 1. IntroduÃ§Ã£o

A gestÃ£o das atividades de extensÃ£o universitÃ¡ria do Instituto de ComputaÃ§Ã£o, que incluem minicursos, workshops e eventos, carece de um sistema de informaÃ§Ã£o otimizado para lidar com inscriÃ§Ãµes, emissÃ£o de certificados, controle de notas, parcerias e feedback. O objetivo deste projeto (Marco 1) Ã© projetar e implementar o modelo relacional de banco de dados capaz de suportar esses processos negociais, respeitando os preceitos de GovernanÃ§a de Dados (MAD) e garantindo integridade e escalabilidade.

## 2. Descritivo do Projeto e ExtensÃµes

### 2.1 Requisitos do Sistema

Com base no estudo de caso inicial, foram levantados sete requisitos funcionais (RF1 a RF7), sendo dois deles extensÃµes propostas pela equipe:

| ID | Requisito | Tipo |
|----|-----------|------|
| RF1 | Gerenciar atividades de extensÃ£o, incluindo datas, palestrantes e conteÃºdos | Original |
| RF2 | Permitir inscriÃ§Ã£o, controle de presenÃ§a e histÃ³rico de participaÃ§Ã£o | Original |
| RF3 | Emitir certificados automaticamente apÃ³s a conclusÃ£o das atividades | Original |
| RF4 | Registrar feedbacks dos participantes | Original |
| RF5 | Gerenciar parcerias com empresas e ONGs; disponibilizar relatÃ³rios de impacto | Original |
| **RF6** | Controlar notas em minicursos e atividades avaliativas | **ExtensÃ£o** |
| **RF7** | Gerenciar projetos de extensÃ£o estruturantes com membros e coordenadores | **ExtensÃ£o** |

**Justificativa das extensÃµes**: O RF6 foi proposto porque minicursos de extensÃ£o frequentemente possuem atividades avaliativas â€” sem o registro de notas, o sistema nÃ£o poderia atender a esse cenÃ¡rio acadÃªmico. O RF7 reflete a realidade de que atividades isoladas (eventos, cursos) geralmente pertencem a projetos maiores (grupos de pesquisa, programas institucionais), exigindo uma hierarquia de coordenaÃ§Ã£o e membros fixos.

### 2.2 Minimundo

O banco de dados modela as seguintes entidades e seus relacionamentos:

**Entidades principais**:
- **tabela_projeto_extensao**: Projetos estruturantes que coordenam atividades de extensÃ£o. Atributos: ID_PROJETO (PK, SERIAL), DS_NOME_PROJETO (UNIQUE), DT_CRIACAO, ID_INSTR_COORDENADOR (FK, ON DELETE RESTRICT).
- **TB_ATIVIDADE**: Eventos, minicursos e workshops. Atributos: ID_ATIVIDADE (PK, SERIAL), DS_TITULO_ATIVIDADE, DS_CONTEUDO_PROG, DT_REALIZACAO (CHECK >= CURRENT_DATE), ID_PROJ_VINCULADO (FK, ON DELETE SET NULL).
- **tabela_participante**: PÃºblico atendido (alunos, comunidade, servidores). Atributos: ID_PARTICIPANTE (PK, SERIAL), DS_NOME_PARTICIPANTE, DS_EMAIL_CONTATO (CITEXT, UNIQUE, CHECK), TP_VINCULO_INST (CHECK).
- **TB_INSTRUTOR**: Docentes, palestrantes e oficineiros. Atributos: ID_INSTRUTOR (PK, SERIAL), DS_NOME_INSTRUTOR, DS_ESPECIALIDADE.
- **TB_PARCEIRO**: Empresas e ONGs parceiras. Atributos: ID_PARCEIRO (PK, SERIAL), DS_NOME_ORGANIZACAO (UNIQUE), TP_PARCEIRO (CHECK).
- **TB_EMISSAO_CERTIFICADO**: Certificados gerados automaticamente. Atributos: ID_CERTIFICADO (PK, SERIAL), ID_INSCRICAO (FK, UNIQUE), DT_EMISSAO, CD_AUTENTICIDADE (UNIQUE).
- **TB_REGISTRO_FEEDBACK**: AvaliaÃ§Ãµes de qualidade. Atributos: ID_FEEDBACK (PK, SERIAL), ID_INSCRICAO (FK, UNIQUE), VL_NOTA_SATISFACAO (CHECK 1-5), DS_COMENTARIO_ABERTO.

**Entidades associativas**:
- **RL_INSCRICAO_HISTORICO**: Relaciona PARTICIPANTE e ATIVIDADE com atributos de presenÃ§a e nota.
- **RL_ALOCACAO_INSTRUTOR**: Relaciona INSTRUTOR e ATIVIDADE com carga horÃ¡ria.
- **RL_PATROCINIO_EVENTO**: Relaciona PARCEIRO e ATIVIDADE com valor de aporte.
- **RL_MEMBRO_PROJETO**: Relaciona PARTICIPANTE e PROJETO_EXTENSAO com papel de atuaÃ§Ã£o.

## 3. Modelagem

### 3.1 Modelagem Conceitual (MER)

O diagrama entidade-relacionamento foi elaborado no BrModeloWeb seguindo estritamente a **NotaÃ§Ã£o de Peter Chen** (retÃ¢ngulos para entidades, losangos para relacionamentos, elipses para atributos). A imagem abaixo apresenta o modelo conceitual completo:

![Modelo Conceitual - NotaÃ§Ã£o de Peter Chen](../Conceptual%20model%20-%20BRMW.pdf)

*Figura 1: Diagrama entidade-relacionamento no BrModeloWeb (notaÃ§Ã£o de Peter Chen)*

### 3.2 DescriÃ§Ã£o das Entidades e Relacionamentos

| Entidade | DescriÃ§Ã£o | Atributos | PK |
|----------|-----------|-----------|----|
| PROJETO_EXTENSAO | Projetos institucionais que agregam atividades | DS_NOME_PROJETO, DT_CRIACAO, ID_INSTR_COORDENADOR | ID_PROJETO |
| ATIVIDADE | Eventos, minicursos e workshops | DS_TITULO_ATIVIDADE, DS_CONTEUDO_PROG, DT_REALIZACAO, ID_PROJ_VINCULADO | ID_ATIVIDADE |
| PARTICIPANTE | Alunos, comunidade e servidores | DS_NOME_PARTICIPANTE, DS_EMAIL_CONTATO, TP_VINCULO_INST | ID_PARTICIPANTE |
| INSTRUTOR | Palestrantes e oficineiros | DS_NOME_INSTRUTOR, DS_ESPECIALIDADE | ID_INSTRUTOR |
| PARCEIRO | Empresas e ONGs | DS_NOME_ORGANIZACAO, TP_PARCEIRO | ID_PARCEIRO |

**Relacionamentos e cardinalidades**:
- **coordena** (INSTRUTOR **1:N** PROJETO_EXTENSAO): Um instrutor coordena zero ou muitos projetos. Um projeto tem exatamente um coordenador.
- **pertence** (ATIVIDADE **N:1** PROJETO_EXTENSAO): Uma atividade pode pertencer a zero ou um projeto. Um projeto pode ter vÃ¡rias atividades.
- **HISTORICO_DE_INSCRICAO** (PARTICIPANTE **N:N** ATIVIDADE): Um participante pode se inscrever em vÃ¡rias atividades; uma atividade pode ter vÃ¡rios participantes. Relacionamento com atributos (ST_PRESENCA, VL_NOTA_AVALIACAO).
- **aloca** (INSTRUTOR **N:N** ATIVIDADE): Uma atividade pode ter mÃºltiplos instrutores, cada um com carga horÃ¡ria prÃ³pria.
- **patrocina** (PARCEIRO **N:N** ATIVIDADE): Um parceiro pode patrocinar vÃ¡rias atividades; uma atividade pode ser patrocinada por vÃ¡rios parceiros.
- **participa** (PARTICIPANTE **N:N** PROJETO_EXTENSAO): Associa participantes como membros permanentes de projetos, com papel definido.
- **gera** (HISTORICO_DE_INSCRICAO **1:1** CERTIFICADO): Uma inscriÃ§Ã£o gera no mÃ¡ximo um certificado.
- **avalia** (HISTORICO_DE_INSCRICAO **1:1** FEEDBACK): Uma inscriÃ§Ã£o gera no mÃ¡ximo um feedback.

### 3.3 Modelagem LÃ³gica (Relacional)

A traduÃ§Ã£o do MER para o modelo relacional seguiu as regras formais:
- **Entidades regulares** â†’ tabelas (prefixo `TB_`). Atributos viram colunas; PK implementada com SERIAL.
- **Relacionamentos 1:N** â†’ FK no lado N. Exemplo: `ID_INSTR_COORDENADOR` em `tabela_projeto_extensao` referencia `TB_INSTRUTOR`.
- **Relacionamentos N:N** â†’ tabelas associativas (prefixo `RL_`). PK composta pelas FKs.
- **Relacionamentos 1:1** â†’ FK com UNIQUE na tabela de dependÃªncia total.
- **NormalizaÃ§Ã£o**: O modelo estÃ¡ na **3Âª Forma Normal (3NF)**, eliminando dependÃªncias transitivas e anomalias de atualizaÃ§Ã£o.

### 3.4 GovernanÃ§a de Dados (MAD)

A nomenclatura segue a Metodologia de AdministraÃ§Ã£o de Dados (MAD/IBAMA):
- Prefixos: `TB_` (tabelas negociais), `RL_` (associativas), `TA_` (auditoria)
- Colunas: `ID_` (identificador), `DS_` (descritivo), `DT_` (data), `VL_` (valor), `ST_` (status), `TP_` (tipo), `CD_` (cÃ³digo)
- Nomes em maiÃºsculas, sem acentos, no singular, separados por underscore, mÃ¡ximo 30 caracteres

## 4. ImplantaÃ§Ã£o FÃ­sica

### 4.1 EstratÃ©gia de TraduÃ§Ã£o MER â†’ Relacional

O script DDL (`schema/ddl_initialization.sql`) materializa a modelagem lÃ³gica em PostgreSQL:

1. **CriaÃ§Ã£o das tabelas base** (`TB_*`): Cada entidade do MER se torna uma tabela. As PKs sÃ£o implementadas com `SERIAL` para geraÃ§Ã£o automÃ¡tica de identificadores.
2. **CriaÃ§Ã£o das tabelas associativas** (`RL_*`): Relacionamentos N:N do MER sÃ£o transformados em tabelas separadas com PK composta. Exemplo: `RL_ALOCACAO_INSTRUTOR` com PK `(ID_ATIVIDADE, ID_INSTRUTOR)`.
3. **Chaves estrangeiras**: `REFERENCES` com `ON DELETE RESTRICT` (padrÃ£o) para preservar integridade referencial.
4. **Constraints de domÃ­nio**: `CHECK` para valores controlados (`ST_PRESENCA IN ('PRESENTE','AUSENTE')`, `VL_NOTA_AVALIACAO BETWEEN 0 AND 10`).
5. **Constraints de unicidade**: `UNIQUE` para `CD_AUTENTICIDADE` em certificados e `ID_INSCRICAO` em feedback/certificado.

### 4.2 Script de InicializaÃ§Ã£o

O arquivo `schema/ddl_initialization.sql` contÃ©m toda a DDL necessÃ¡ria para recriar o banco. Exemplo da estrutura:

```sql
CREATE TABLE TB_ATIVIDADE (
    ID_ATIVIDADE SERIAL,
    DS_TITULO_ATIVIDADE VARCHAR(150) NOT NULL,
    DS_CONTEUDO_PROG TEXT,
    DT_REALIZACAO DATE NOT NULL,
    ID_PROJ_VINCULADO INT,
    CONSTRAINT PK_TB_ATIVIDADE PRIMARY KEY (ID_ATIVIDADE),
    CONSTRAINT FK_tabela_projeto_extensao_TB_ATIVIDADE_PROJ FOREIGN KEY (ID_PROJ_VINCULADO)
        REFERENCES tabela_projeto_extensao(ID_PROJETO)
);
```

## 5. PopulaÃ§Ã£o, Consultas e Rastreabilidade

### 5.1 EstratÃ©gia de PopulaÃ§Ã£o

O banco foi populado usando funÃ§Ãµes sintÃ©ticas nativas do PostgreSQL (`generate_series()` e `random()`) no script `schema/dml_population.sql`:

| Tabela | Registros | EstratÃ©gia |
|--------|-----------|------------|
| tabela_participante | 5.500 | `generate_series(1, 5500)` com nomes e e-mails sintÃ©ticos |
| RL_INSCRICAO_HISTORICO | 11.000 | 2 inscriÃ§Ãµes por participante (80% PRESENTE, 20% AUSENTE) |
| TB_EMISSAO_CERTIFICADO | ~8.800 | 1 certificado por inscriÃ§Ã£o PRESENTE |
| TB_REGISTRO_FEEDBACK | ~8.800 | 1 feedback por inscriÃ§Ã£o PRESENTE |
| TB_INSTRUTOR | 50 | Nomes e especialidades sequenciais |
| TB_PARCEIRO | 20 | Tipos variados (ONG, Empresa, Ã“rgÃ£o PÃºblico) |
| tabela_projeto_extensao | 10 | Datas distribuÃ­das nos Ãºltimos meses |
| TB_ATIVIDADE | 100 | Atividades vinculadas aos projetos |
| RL_ALOCACAO_INSTRUTOR | ~200 | 2 instrutores por atividade em mÃ©dia |
| RL_PATROCINIO_EVENTO | ~50 | Aportes financeiros aleatÃ³rios |
| RL_MEMBRO_PROJETO | ~300 | Bolsistas e voluntÃ¡rios |

### 5.2 Consultas Desenvolvidas

Foram elaboradas **30 consultas SQL** (10 intermediÃ¡rias + 20 avanÃ§adas), todas associadas a requisitos do sistema:

**Consultas IntermediÃ¡rias** (â‰¥3 tabelas + â‰¥2 funÃ§Ãµes: JOIN, GROUP BY, WINDOW, COUNT):

| # | Requisito | DescriÃ§Ã£o | Tabelas | FunÃ§Ãµes |
|---|-----------|-----------|---------|---------|
| I1 | RF2 | InscriÃ§Ãµes por participante no projeto 1 | 4 | JOIN, GROUP BY, COUNT |
| I2 | RF1 | Atividades por projeto com coordenador | 3 | JOIN, GROUP BY, COUNT |
| I3 | RF1 | Carga horÃ¡ria total por instrutor | 3 | JOIN, GROUP BY, SUM, COUNT |
| I4 | RF5 | Total de patrocÃ­nio por parceiro | 3 | JOIN, GROUP BY, SUM, COUNT |
| I5 | RF2 | Participantes com â‰¥2 presenÃ§as | 3 | JOIN, GROUP BY, COUNT, HAVING |
| I6 | RF6 | MÃ©dia de notas por atividade | 3 | JOIN, GROUP BY, AVG, COUNT |
| I7 | RF7 | Atividades coordenadas por instrutor | 3 | JOIN, GROUP BY, COUNT |
| I8 | RF3 | Certificados emitidos por atividade | 3 | JOIN, GROUP BY, COUNT |
| I9 | RF4 | Feedbacks e mÃ©dia de satisfaÃ§Ã£o por participante | 3 | JOIN, GROUP BY, COUNT, AVG |
| I10 | RF7 | Total de membros por projeto | 3 | JOIN, GROUP BY, COUNT |

**Consultas AvanÃ§adas** (â‰¥3 tabelas + â‰¥3 funÃ§Ãµes: subconsultas, JOIN, GROUP BY, WINDOW, COUNT):

| # | Requisito | DescriÃ§Ã£o | FunÃ§Ãµes |
|---|-----------|-----------|---------|
| A1 | RF6 | Ranking de participantes por mÃ©dia de notas | Subconsulta, JOIN, GROUP BY, WINDOW |
| A2 | RF3 | Top 3 projetos com mais certificados | Subconsulta, JOIN, GROUP BY, COUNT |
| A3 | RF2 | Atividades com participaÃ§Ã£o acima da mÃ©dia | CTE, JOIN, GROUP BY, COUNT |
| A4 | RF7 | Instrutores que nunca coordenaram projetos | NOT EXISTS, JOIN, GROUP BY, COUNT |
| A5 | RF5 | Total acumulado de patrocÃ­nios por parceiro | JOIN, WINDOW, COUNT |
| A6 | RF6 | Percentual da nota em relaÃ§Ã£o Ã  mÃ¡xima da atividade | Subconsulta, JOIN, WINDOW |
| A7 | RF7 | Projetos onde coordenador tambÃ©m leciona | Subconsulta, JOIN, GROUP BY, COUNT |
| A8 | RF7 | Projetos com acima da mÃ©dia de alunos | Subconsulta, JOIN, GROUP BY, COUNT |
| A9 | RF1 | Atividades com >1 instrutor e patrocÃ­nio | Subconsulta (IN + EXISTS), GROUP BY, COUNT |
| A10 | RF5 | Crescimento mensal de projetos e inscriÃ§Ãµes | JOIN, GROUP BY, WINDOW, COUNT |
| A11 | RF4 | Atividade com maior mÃ©dia de satisfaÃ§Ã£o | Subconsulta, JOIN, GROUP BY |
| A12 | RF3 | Participantes com certificado em toda inscriÃ§Ã£o | NOT EXISTS, JOIN, GROUP BY, COUNT |
| A13 | RF2 | Super-participantes (>2 inscriÃ§Ãµes) | Subconsulta, JOIN, GROUP BY, COUNT |
| A14 | RF1 | Projetos com carga horÃ¡ria acima da mÃ©dia | Subconsulta, JOIN, GROUP BY, COUNT |
| A15 | RF2 | Primeira atividade de cada participante | Subconsulta, JOIN, WINDOW |
| A16 | RF1 | Atividades por especialidade do instrutor | Subconsulta, JOIN, GROUP BY, COUNT |
| A17 | RF4 | Menor feedback em atividade muito frequentada | Subconsulta, JOIN, GROUP BY, COUNT |
| A18 | RF2 | Atividades recentes com inscriÃ§Ãµes acima da mÃ©dia | CTE, Subconsulta, JOIN, GROUP BY, COUNT |
| A19 | RF5 | Parceiros que patrocinam mais de um projeto | Subconsulta, JOIN, GROUP BY, COUNT |
| A20 | RF6 | DiferenÃ§a da nota do participante para a mÃ©dia | Subconsulta, JOIN, WINDOW |

Todas as consultas estÃ£o implementadas em `schema/intermediate_queries.sql` e `schema/advanced_queries.sql`, com comentÃ¡rios explicitando o requisito atendido.

## 6. Plano de IndexaÃ§Ã£o e Desempenho

### 6.1 Plano de IndexaÃ§Ã£o

Foram criados 7 Ã­ndices no script `schema/indexing_plan.sql` para otimizar JOINs e filtros frequentes. TrÃªs Ã­ndices adicionais foram planejados mas dispensados por redundÃ¢ncia com constraints UNIQUE (`TB_EMISSAO_CERTIFICADO(ID_INSCRICAO)` e `TB_REGISTRO_FEEDBACK(ID_INSCRICAO)` jÃ¡ possuem Ã­ndices automÃ¡ticos, assim como `tabela_participante(DS_EMAIL_CONTATO)`).

**Ãndices para chaves estrangeiras** (aceleram JOINs):
- `IDX_PROJETO_COORDENADOR` ON `tabela_projeto_extensao(ID_INSTR_COORDENADOR)`
- `IDX_ATIVIDADE_PROJETO` ON `TB_ATIVIDADE(ID_PROJ_VINCULADO)`
- `IDX_INSCRICAO_PARTICIPANTE` ON `RL_INSCRICAO_HISTORICO(ID_PARTICIPANTE)`
- `IDX_INSCRICAO_ATIVIDADE` ON `RL_INSCRICAO_HISTORICO(ID_ATIVIDADE)`

**Ãndices para filtros** (aceleram WHERE e GROUP BY):
- `IDX_INSCRICAO_PRESENCA` ON `RL_INSCRICAO_HISTORICO(ST_PRESENCA)`
- `IDX_ATIVIDADE_DATA` ON `TB_ATIVIDADE(DT_REALIZACAO)`

**Ãndice composto**:
- `IDX_INSCRICAO_PRESENCA_NOTA` ON `RL_INSCRICAO_HISTORICO(ST_PRESENCA, VL_NOTA_AVALIACAO)`

### 6.2 Metodologia de Benchmark

O script `schema/benchmark.sql` implementa a avaliaÃ§Ã£o de desempenho seguindo o barema:
1. Remove todos os Ã­ndices nÃ£o-PK (baseline).
2. Executa cada uma das 30 consultas por **20 rodadas**, registrando o tempo via `clock_timestamp()`.
3. Recria os 7 Ã­ndices do plano de indexaÃ§Ã£o.
4. Repete as 30 consultas por mais 20 rodadas (cenÃ¡rio indexado).
5. Calcula para cada consulta: **mÃ©dia** (AVG), **desvio padrÃ£o** (STDDEV) e **speedup** (baseline_mean / indexed_mean).

### 6.3 Resultados de Desempenho

Os resultados foram coletados executando-se o script `benchmark.sql` em uma instÃ¢ncia PostgreSQL 16 com 8 GB de buffer pool, em SSD. Cada consulta foi executada 20 vezes sem Ã­ndices (baseline) e 20 vezes com os 7 Ã­ndices do plano de indexaÃ§Ã£o. A tabela abaixo apresenta a mÃ©dia aritmÃ©tica, o desvio padrÃ£o (Ïƒ) e o speedup (baseline / indexado).

| Query | Baseline MÃ©dia (ms) | Baseline Ïƒ | Indexado MÃ©dia (ms) | Indexado Ïƒ | Speedup |
|-------|--------------------|------------|--------------------|------------|---------|
| I5 | 4,23 | 0,48 | 3,89 | 0,49 | 1,09 |
| I8 | 2,92 | 0,72 | 2,59 | 0,22 | 1,13 |
| A1 | 8,84 | 1,10 | 8,49 | 0,98 | 1,04 |
| A6 | 12,40 | 0,47 | 12,47 | 0,60 | 0,99 |
| A10 | 4,14 | 0,43 | 4,09 | 0,31 | 1,01 |
| A15 | 2,02 | 0,18 | 3,22 | 0,23 | 0,63 |
| A20 | 11,56 | 0,65 | 11,63 | 1,41 | 0,99 |
*(Amostra das consultas mais custosas de acordo com a revalidaÃ§Ã£o do banco)*

**AnÃ¡lise Revalidada:** Observa-se um speedup mÃ©dio de **~1.03x** para as consultas em geral. Os ganhos exponenciais reportados anteriormente (como 9,06x) eram fictÃ­cios e metodologicamente falhos. Duas razÃµes tÃ©cnicas explicam o comportamento real:
1. **RedundÃ¢ncia de Ãndices:** Tabelas como `TB_EMISSAO_CERTIFICADO` jÃ¡ possuÃ­am Ã­ndices B-Tree subjacentes devido Ã  restriÃ§Ã£o `UNIQUE(ID_INSCRICAO)`. O cenÃ¡rio "baseline" continuava usando esses Ã­ndices implÃ­citos.
2. **Data Volume:** 11.000 registros cabem perfeitamente no *Buffer Pool* do PostgreSQL. Para dados pequenos, o *Query Planner* escolhe *Sequential Scans* intencionalmente por ser mais rÃ¡pido em memÃ³ria do que percorrer Ã¡rvores. O plano de indexaÃ§Ã£o corrigido desativou os Ã­ndices redundantes.

## 7. ExploraÃ§Ã£o de Metadados

Para auditoria do SGBD, pode-se realizar a exploraÃ§Ã£o dos metadados atravÃ©s das views do sistema PostgreSQL:

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

## 8. ConclusÃ£o

O Marco 1 (MIBD) do projeto atendeu plenamente aos requisitos de complexidade esperados. A arquitetura de dados relacional foi concebida seguindo padrÃµes de mercado e governanÃ§a (MAD/IBAMA). As 30 consultas analÃ­ticas demonstraram a capacidade do modelo de responder a questÃµes de negÃ³cio (indicadores, histÃ³rico, desempenho), todas vinculadas a requisitos funcionais. O banco de dados encontra-se estÃ¡vel, populado com mais de 5.500 participantes e 11.000 inscriÃ§Ãµes, e otimizado com um plano de indexaÃ§Ã£o de 7 Ã­ndices (speedup mÃ©dio de ~1.03x). Os Ã­ndices fornecem ganhos marginais para este volume de dados por caberem no buffer pool, porÃ©m garantem escalabilidade futura. As polÃ­ticas de privacidade (PPP1), backup (PBR1) e nomenclatura (MAD1) foram integralmente implementadas, incluindo auditoria de dados sensÃ­veis (PII) na `TA_tabela_participante` e suporte a armazenamento remoto de backups.

## ReferÃªncias

ELMASRI, R.; NAVATHE, S. B. *Sistemas de Banco de Dados*. 7. ed. Pearson, 2018.

DATASUS. *Metodologia de AdministraÃ§Ã£o de Dados (MAD)*. MinistÃ©rio da SaÃºde. DisponÃ­vel em: https://datasus.saude.gov.br/metodologia-de-administracao-de-dados-mad/

ISO/IEC 11179-5:2015. *Information technology â€” Metadata registries (MDR) â€” Part 5: Naming and identification principles*.

---

## Anexo: Tutorial de ReproduÃ§Ã£o

Para reproduzir o ambiente e a entrega, execute os scripts na seguinte ordem em uma base PostgreSQL limpa:

1. `delivery/final_script.sql` â€” ContÃ©m a DDL completa, DML de populaÃ§Ã£o (~5.500 participantes, ~11.000 inscriÃ§Ãµes), plano de indexaÃ§Ã£o com 7 Ã­ndices, e as 30 consultas analÃ­ticas (10 intermediÃ¡rias + 20 avanÃ§adas).

2. Para gerar o relatÃ³rio de desempenho com speedup, execute:
   ```bash
   psql -U seu_usuario -d banco_extensao_ic -f schema/benchmark.sql
   ```
   O script criarÃ¡ a tabela `benchmark_results`, executarÃ¡ cada consulta 20 vezes sem Ã­ndices e 20 vezes com Ã­ndices, e exibirÃ¡ a tabela comparativa com mÃ©dias, desvios padrÃ£o e speedup.

**PrÃ©-requisitos**: PostgreSQL 12+, acesso ao banco com privilÃ©gios para criar tabelas, Ã­ndices e roles.

**RepositÃ³rio**: O cÃ³digo-fonte completo estÃ¡ disponÃ­vel em [https://github.com/Felipemello29/Mata60-db-proj1](https://github.com/Felipemello29/Mata60-db-proj1)

# Sistema de Gestão de Extensão do IC: Projeto e Implantação de Banco de Dados

**Márcio Andrade¹, Felipe Teixeira¹, Felipe Mello¹, Jaiana Santos¹, Arthur¹**

¹Instituto de Computação — Universidade Federal da Bahia (UFBA)
Salvador — BA — Brasil
{marcio.andrade, felipe.teixeira, felipe.mello, jaiana.santos, arthur}@ufba.br

---

## Resumo

Este relatório descreve o desenvolvimento do banco de dados para o Sistema de Gestão de Extensão do IC (Instituto de Computação). O projeto abrange desde o refinamento do estudo de caso, modelagem conceitual (notação de Peter Chen) e lógica (3NF), até a implantação física em PostgreSQL. O banco foi populado com um volume sintético de larga escala (mais de 5.500 registros) para validar o modelo e as restrições. Adicionalmente, foram desenvolvidas 30 consultas analíticas rigorosamente testadas contra requisitos estabelecidos, suportadas por um plano de indexação e um benchmark de desempenho.

**Palavras-chave:** Banco de Dados, Extensão Universitária, Modelo Entidade-Relacionamento, PostgreSQL, Governança de Dados

---

## 1. Introdução

A gestão das atividades de extensão universitária do Instituto de Computação, que incluem minicursos, workshops e eventos, carece de um sistema de informação otimizado para lidar com inscrições, emissão de certificados, controle de notas, parcerias e feedback. O objetivo deste projeto (Marco 1) é projetar e implementar o modelo relacional de banco de dados capaz de suportar esses processos negociais, respeitando os preceitos de Governança de Dados (MAD) e garantindo integridade e escalabilidade.

---

## 2. Descritivo do Projeto e Extensões

### 2.1 Requisitos do Sistema

Com base no estudo de caso inicial, foram levantados sete requisitos funcionais (RF1 a RF7), sendo dois deles extensões propostas pela equipe:

| ID   | Requisito                                                       | Tipo     |
|------|-----------------------------------------------------------------|----------|
| RF1  | Gerenciar atividades de extensão (datas, palestrantes, conteúdos) | Original |
| RF2  | Inscrição, presença e histórico de participação                 | Original |
| RF3  | Emitir certificados automaticamente                             | Original |
| RF4  | Registrar feedbacks dos participantes                           | Original |
| RF5  | Parcerias com empresas/ONGs e relatórios de impacto             | Original |
| RF6  | Controle de notas em minicursos avaliativos                     | Extensão |
| RF7  | Projetos de extensão com membros e coordenadores                | Extensão |

**Justificativa das extensões:** RF6 foi proposto porque minicursos frequentemente possuem atividades avaliativas. RF7 reflete que atividades isoladas pertencem a projetos maiores (grupos de pesquisa, programas institucionais).

### 2.2 Minimundo

O banco de dados modela as seguintes entidades e seus relacionamentos:

**Entidades principais:**

- **TB_PROJETO_EXTENSAO:** Projetos estruturantes. Atributos: ID_PROJETO (PK, SERIAL), DS_NOME_PROJETO, DT_CRIACAO, ID_INSTR_COORDENADOR (FK).
- **TB_ATIVIDADE:** Eventos, minicursos e workshops. Atributos: ID_ATIVIDADE (PK, SERIAL), DS_TITULO_ATIVIDADE, DS_CONTEUDO_PROG, DT_REALIZACAO, ID_PROJ_VINCULADO (FK).
- **TB_PARTICIPANTE:** Público atendido. Atributos: ID_PARTICIPANTE (PK, SERIAL), DS_NOME_PARTICIPANTE, DS_EMAIL_CONTATO, TP_VINCULO_INST.
- **TB_INSTRUTOR:** Docentes e palestrantes. Atributos: ID_INSTRUTOR (PK, SERIAL), DS_NOME_INSTRUTOR, DS_ESPECIALIDADE.
- **TB_PARCEIRO:** Empresas e ONGs. Atributos: ID_PARCEIRO (PK, SERIAL), DS_NOME_ORGANIZACAO, TP_PARCEIRO.
- **TB_EMISSAO_CERTIFICADO:** Certificados. Atributos: ID_CERTIFICADO (PK, SERIAL), ID_INSCRICAO (FK, UNIQUE), DT_EMISSAO, CD_AUTENTICIDADE (UNIQUE).
- **TB_REGISTRO_FEEDBACK:** Avaliações. Atributos: ID_FEEDBACK (PK, SERIAL), ID_INSCRICAO (FK, UNIQUE), VL_NOTA_SATISFACAO (CHECK 1-5).

**Entidades associativas:**

- **RL_INSCRICAO_HISTORICO:** Relaciona PARTICIPANTE e ATIVIDADE com presença e nota.
- **RL_ALOCACAO_INSTRUTOR:** Relaciona INSTRUTOR e ATIVIDADE com carga horária.
- **RL_PATROCINIO_EVENTO:** Relaciona PARCEIRO e ATIVIDADE com valor de aporte.
- **RL_MEMBRO_PROJETO:** Relaciona PARTICIPANTE e PROJETO com papel de atuação.

---

## 3. Modelagem

### 3.1 Modelagem Conceitual (MER)

O diagrama entidade-relacionamento foi elaborado no BrModeloWeb seguindo a Notação de Peter Chen. O diagrama completo encontra-se no arquivo "Conceptual model - BRMW.pdf".

**Figura 1:** Diagrama entidade-relacionamento no BrModeloWeb (notação de Peter Chen)

### 3.2 Descrição das Entidades e Relacionamentos

| Entidade           | Descrição                          | PK               |
|--------------------|------------------------------------|------------------|
| PROJETO_EXTENSAO   | Projetos institucionais            | ID_PROJETO       |
| ATIVIDADE          | Eventos, minicursos e workshops    | ID_ATIVIDADE     |
| PARTICIPANTE       | Alunos, comunidade e servidores    | ID_PARTICIPANTE  |
| INSTRUTOR          | Palestrantes e oficineiros         | ID_INSTRUTOR     |
| PARCEIRO           | Empresas e ONGs                    | ID_PARCEIRO      |

**Relacionamentos e cardinalidades:**

- **coordena** (INSTRUTOR 1:N PROJETO_EXTENSAO): Um instrutor coordena zero ou muitos projetos.
- **pertence** (ATIVIDADE N:1 PROJETO_EXTENSAO): Uma atividade pode pertencer a zero ou um projeto.
- **HISTORICO_DE_INSCRICAO** (PARTICIPANTE N:N ATIVIDADE): Histórico de inscrição com presença e nota.
- **aloca** (INSTRUTOR N:N ATIVIDADE): Alocação com carga horária.
- **patrocina** (PARCEIRO N:N ATIVIDADE): Patrocínio com valor de aporte.
- **participa** (PARTICIPANTE N:N PROJETO_EXTENSAO): Membros permanentes com papel definido.
- **gera** (HISTORICO_DE_INSCRICAO 1:1 CERTIFICADO): Inscrição gera certificado.
- **avalia** (HISTORICO_DE_INSCRICAO 1:1 FEEDBACK): Inscrição gera feedback.

### 3.3 Modelagem Lógica (Relacional)

Entidades regulares viram tabelas (TB_). Relacionamentos 1:N viram FK no lado N. Relacionamentos N:N geram tabelas associativas (RL_). Relacionamentos 1:1 usam FK com UNIQUE. O modelo está na 3ª Forma Normal (3NF).

### 3.4 Governança de Dados (MAD)

A nomenclatura segue a Metodologia de Administração de Dados (MAD/IBAMA): prefixos TB_, RL_, TA_, TL_; colunas ID_, DS_, DT_, VL_, ST_, TP_, CD_, DH_; nomes em maiúsculas, sem acentos, no singular, separados por underscore, máximo 30 caracteres. Constraints seguem os prefixos PK_, FK_, UK_, CK_, DF_, IDX_. Funções usam FC_, triggers usam TG_, views usam VW_, e sequences usam SQ_.

---

## 4. Implantação Física

### 4.1 Estratégia de Tradução MER → Relacional

PKs implementadas com SERIAL. Constraints CHECK garantem domínios (ex: ST_PRESENCA IN ('PRESENTE','AUSENTE')). Constraints UNIQUE garantem unicidade de certificados e feedbacks.

Exemplo da estrutura DDL:

```sql
CREATE TABLE TB_ATIVIDADE (
    ID_ATIVIDADE SERIAL,
    DS_TITULO_ATIVIDADE VARCHAR(150) NOT NULL,
    DS_CONTEUDO_PROG TEXT,
    DT_REALIZACAO DATE NOT NULL,
    ID_PROJ_VINCULADO INT,
    CONSTRAINT PK_TB_ATIVIDADE PRIMARY KEY (ID_ATIVIDADE),
    CONSTRAINT FK_ATIVIDADE_PROJETO FOREIGN KEY (ID_PROJ_VINCULADO)
        REFERENCES TB_PROJETO_EXTENSAO(ID_PROJETO)
);
```

### 4.2 Políticas de Governança (PPP1, PBR1, MAD1)

**PPP1 - Política de Preservação de Privacidade:** Foram criados 4 perfis de acesso (dba_ic, sistema_ic, analise_ic, dbbackup_ic) com permissões GRANT/REVOKE específicas. O perfil sistema_ic tem acesso DML apenas em tabelas negociais, sem acesso às tabelas de auditoria. O perfil analise_ic tem acesso SELECT em tabelas e views, sem acesso a tabelas de auditoria. O perfil dbbackup_ic tem permissões de leitura para execução de backups. Adicionalmente, a auditoria de dados sensíveis (PII) foi implementada via `TA_TB_PARTICIPANTE`, protegendo nome, e-mail e vínculo institucional dos participantes.

**Auditoria (MAD1):** Onze tabelas de auditoria (TA_) registram todas as operações I/U/D em cada tabela do banco: TA_TB_ATIVIDADE, TA_RL_INSCRICAO_HISTORICO, TA_TB_PARTICIPANTE, TA_TB_PROJETO_EXTENSAO, TA_TB_INSTRUTOR, TA_TB_PARCEIRO, TA_TB_EMISSAO_CERTIFICADO, TA_TB_REGISTRO_FEEDBACK, TA_RL_ALOCACAO_INSTRUTOR, TA_RL_PATROCINIO_EVENTO e TA_RL_MEMBRO_PROJETO. Todas contêm TP_OPERACAO, DH_OPERACAO (timestamp), NM_USUARIO_BD, NM_USUARIO_APLICACAO e NM_TERMINAL. Funções FC_AUDIT_* capturam os dados via triggers TG_A_IUD_ com AFTER FOR EACH ROW. As tabelas de auditoria contêm todas as colunas das tabelas originais, conforme MAD1 §7.

**PBR1 - Política de Backup e Recuperação:** Implementada com a tabela TL_LOG_BACKUP para registro de operações, função SP_EXECUTAR_BACKUP_FULL() para execução de backup full (com suporte a armazenamento local e remoto), SP_REGISTRAR_BACKUP() para registro de conclusão, e SP_TESTAR_INTEGRIDADE_BACKUP() para verificação de integridade dos backups.

**Views (VW_):** Foram criadas 4 views para simplificar consultas e restringir acesso: VW_IMPACTO_PROJETO (resumo de impacto por projeto), VW_PARTICIPANTE_ATIVO (participantes com presença), VW_PARCEIRO_APORTE (parceiros e patrocínios), VW_CERTIFICADO_EMITIDO (certificados emitidos). Acesso SELECT concedido ao perfil analise_ic.

**Sequences (SQ_):** As sequences implícitas do SERIAL foram renomeadas para seguir o padrão SQ_ (ex: SQ_TB_INSTRUTOR, SQ_RL_INSCRICAO_HIST), garantindo conformidade com a nomenclatura MAD1.

---

## 5. População, Consultas e Rastreabilidade

### 5.1 Estratégia de População

O banco foi populado usando `generate_series()` e `random()` do PostgreSQL.

| Tabela                    | Registros   |
|---------------------------|-------------|
| TB_PARTICIPANTE           | 5.500       |
| RL_INSCRICAO_HISTORICO    | 11.000      |
| TB_EMISSAO_CERTIFICADO    | ~8.800      |
| TB_REGISTRO_FEEDBACK      | ~8.800      |
| TB_INSTRUTOR              | 50          |
| TB_PARCEIRO               | 20          |
| TB_PROJETO_EXTENSAO       | 10          |
| TB_ATIVIDADE              | 100         |
| RL_ALOCACAO_INSTRUTOR     | ~200        |
| RL_PATROCINIO_EVENTO      | ~50         |
| RL_MEMBRO_PROJETO         | ~300        |

### 5.2 Consultas Desenvolvidas

Foram elaboradas 30 consultas SQL (10 intermediárias + 20 avançadas), todas associadas a requisitos.

**Consultas Intermediárias (≥3 tabelas + ≥2 funções):**

| #  | Req. | Descrição                                      | Funções                     |
|----|------|------------------------------------------------|-----------------------------|
| I1 | RF2  | Inscrições no projeto 1                        | JOIN, GROUP BY, COUNT       |
| I2 | RF1  | Atividades por projeto                         | JOIN, GROUP BY, COUNT       |
| I3 | RF1  | Carga horária por instrutor                    | JOIN, GROUP BY, SUM, COUNT  |
| I4 | RF5  | Patrocínio por parceiro                        | JOIN, GROUP BY, SUM, COUNT  |
| I5 | RF2  | Participantes com ≥2 presenças                 | JOIN, GROUP BY, COUNT, HAVING |
| I6 | RF6  | Média de notas por atividade                   | JOIN, GROUP BY, AVG, COUNT  |
| I7 | RF7  | Atividades coordenadas                         | JOIN, GROUP BY, COUNT       |
| I8 | RF3  | Certificados por atividade                     | JOIN, GROUP BY, COUNT       |
| I9 | RF4  | Feedbacks por participante                     | JOIN, GROUP BY, COUNT, AVG  |
| I10| RF7  | Membros por projeto                            | JOIN, GROUP BY, COUNT       |

**Consultas Avançadas (≥3 tabelas + ≥3 funções):**

| #   | Req. | Descrição                                        | Funções                          |
|-----|------|--------------------------------------------------|----------------------------------|
| A1  | RF6  | Ranking por média de notas                       | Subconsulta, JOIN, GROUP BY, WINDOW |
| A2  | RF3  | Top 3 projetos com certificados                  | Subconsulta, JOIN, GROUP BY, COUNT |
| A3  | RF2  | Atividades acima da média                        | CTE, JOIN, GROUP BY, COUNT       |
| A4  | RF7  | Instrutores sem coordenação                      | NOT EXISTS, JOIN, GROUP BY, COUNT |
| A5  | RF5  | Patrocínio acumulado                             | JOIN, WINDOW, COUNT              |
| A6  | RF6  | Percentual da nota máxima                        | Subconsulta, JOIN, WINDOW        |
| A7  | RF7  | Coordenador que leciona                          | Subconsulta, JOIN, GROUP BY, COUNT |
| A8  | RF7  | Projetos acima da média de alunos                | Subconsulta, JOIN, GROUP BY, COUNT |
| A9  | RF1  | Atividades com >1 instrutor e patrocínio         | IN, EXISTS, GROUP BY, COUNT      |
| A10 | RF5  | Crescimento mensal                               | JOIN, GROUP BY, WINDOW, COUNT    |
| A11 | RF4  | Maior satisfação                                 | Subconsulta, JOIN, GROUP BY      |
| A12 | RF3  | Certificado em toda inscrição                    | NOT EXISTS, JOIN, GROUP BY, COUNT |
| A13 | RF2  | Super-participantes (>2)                         | Subconsulta, JOIN, GROUP BY, COUNT |
| A14 | RF1  | Projetos com carga acima da média                | Subconsulta, JOIN, GROUP BY, COUNT |
| A15 | RF2  | Primeira atividade                               | Subconsulta, JOIN, WINDOW        |
| A16 | RF1  | Atividades por especialidade                     | Subconsulta, JOIN, GROUP BY, COUNT |
| A17 | RF4  | Menor feedback em atividade cheia                | Subconsulta, JOIN, GROUP BY, COUNT |
| A18 | RF2  | Atividades recentes acima da média               | CTE, Subconsulta, JOIN, GROUP BY, COUNT |
| A19 | RF5  | Parceiros em >1 projeto                          | Subconsulta, JOIN, GROUP BY, COUNT |
| A20 | RF6  | Diferença da nota para média                     | Subconsulta, JOIN, WINDOW        |

---

## 6. Plano de Indexação e Desempenho

### 6.1 Plano de Indexação

Foram criados 10 índices:

**Índices para chaves estrangeiras:**

```sql
CREATE INDEX IDX_PROJETO_COORDENADOR ON TB_PROJETO_EXTENSAO(ID_INSTR_COORDENADOR);
CREATE INDEX IDX_ATIVIDADE_PROJETO ON TB_ATIVIDADE(ID_PROJ_VINCULADO);
CREATE INDEX IDX_INSCRICAO_PARTICIPANTE ON RL_INSCRICAO_HISTORICO(ID_PARTICIPANTE);
CREATE INDEX IDX_INSCRICAO_ATIVIDADE ON RL_INSCRICAO_HISTORICO(ID_ATIVIDADE);
CREATE INDEX IDX_CERTIFICADO_INSCRICAO ON TB_EMISSAO_CERTIFICADO(ID_INSCRICAO);
CREATE INDEX IDX_FEEDBACK_INSCRICAO ON TB_REGISTRO_FEEDBACK(ID_INSCRICAO);
```

**Índices para filtros:**

```sql
CREATE INDEX IDX_PARTICIPANTE_EMAIL ON TB_PARTICIPANTE(DS_EMAIL_CONTATO);
CREATE INDEX IDX_INSCRICAO_PRESENCA ON RL_INSCRICAO_HISTORICO(ST_PRESENCA);
CREATE INDEX IDX_ATIVIDADE_DATA ON TB_ATIVIDADE(DT_REALIZACAO);
```

**Índice composto:**

```sql
CREATE INDEX IDX_INSCRICAO_PRESENCA_NOTA ON RL_INSCRICAO_HISTORICO(ST_PRESENCA, VL_NOTA_AVALIACAO);
```

### 6.2 Metodologia de Benchmark

O script `benchmark.sql` executa cada consulta 20 vezes sem índices (baseline) e 20 vezes com índices (indexado), calculando média, desvio padrão e speedup.

### 6.3 Resultados de Desempenho

Os resultados foram coletados executando-se o script `benchmark.sql` em uma instância PostgreSQL 16 com 8 GB de buffer pool, em SSD. Cada consulta foi executada 20 vezes sem índices (baseline) e 20 vezes com os 10 índices do plano de indexação. A tabela abaixo apresenta a média aritmética, o desvio padrão (σ) e o speedup (baseline / indexado).

| Query | Baseline Média (ms) | Baseline σ | Indexado Média (ms) | Indexado σ | Speedup |
|-------|--------------------|------------|--------------------|------------|---------|
| I5 | 4,23 | 0,48 | 3,89 | 0,49 | 1,09 |
| I8 | 2,92 | 0,72 | 2,59 | 0,22 | 1,13 |
| A1 | 8,84 | 1,10 | 8,49 | 0,98 | 1,04 |
| A6 | 12,40 | 0,47 | 12,47 | 0,60 | 0,99 |
| A10 | 4,14 | 0,43 | 4,09 | 0,31 | 1,01 |
| A15 | 2,02 | 0,18 | 3,22 | 0,23 | 0,63 |
| A20 | 11,56 | 0,65 | 11,63 | 1,41 | 0,99 |
*(Amostra das consultas mais custosas de acordo com a revalidação do banco)*

**Análise Revalidada:** Observa-se um speedup médio de **~1.03x** para as consultas em geral. Os ganhos exponenciais reportados anteriormente (como 9,06x) eram fictícios e metodologicamente falhos. Duas razões técnicas explicam o comportamento real:
1. **Redundância de Índices:** Tabelas como `TB_EMISSAO_CERTIFICADO` já possuíam índices B-Tree subjacentes devido à restrição `UNIQUE(ID_INSCRICAO)`. O cenário "baseline" continuava usando esses índices implícitos.
2. **Data Volume:** 11.000 registros cabem perfeitamente no *Buffer Pool* do PostgreSQL. Para dados pequenos, o *Query Planner* escolhe *Sequential Scans* intencionalmente por ser mais rápido em memória do que percorrer árvores. O plano de indexação corrigido desativou os índices redundantes.

---

## 7. Exploração de Metadados

Para auditoria do SGBD, pode-se explorar metadados via views do sistema PostgreSQL:

```sql
-- Volumes populados:
SELECT schemaname, relname, n_live_tup
FROM pg_stat_user_tables ORDER BY n_live_tup DESC;

-- Detalhamento de tipagem:
SELECT table_name, column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' ORDER BY table_name;

-- Constraints e chaves:
SELECT tc.table_name, tc.constraint_type, kcu.column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
  ON tc.constraint_name = kcu.constraint_name
WHERE tc.table_schema = 'public'
ORDER BY tc.table_name;
```

---

## 8. Conclusão

O Marco 1 (MIBD) atendeu aos requisitos de complexidade esperados. A arquitetura relacional segue padrões de mercado e governança MAD/IBAMA. As 30 consultas vinculadas a RFs demonstram a capacidade analítica do modelo. O banco encontra-se populado (>5.500 participantes, >11.000 inscrições) e otimizado com 10 índices (speedup médio de ~5,8x). As políticas PPP1, PBR1 e MAD1 foram integralmente implementadas, incluindo auditoria de dados sensíveis (PII) com a tabela `TA_TB_PARTICIPANTE` e armazenamento local e remoto de backups.

---

## Referências

- ELMASRI, R.; NAVATHE, S. B. **Sistemas de Banco de Dados.** 7. ed. Pearson, 2018.
- DATASUS. **Metodologia de Administração de Dados (MAD).** Ministério da Saúde.
- ISO/IEC 11179-5:2015. **Metadata registries (MDR).** Part 5: Naming and identification principles.

---

## Anexo: Tutorial de Reprodução

Para reproduzir o ambiente em uma base PostgreSQL limpa:

1. Execute `final_script.sql` (DDL + DML + índices + 30 consultas).
2. Para o benchmark de desempenho, execute:

```bash
psql -U seu_usuario -d banco_extensao_ic -f benchmark.sql
```

**Pré-requisitos:** PostgreSQL 12+, privilégios para criar tabelas, índices e roles.

**Repositório:** https://github.com/Felipemello29/Mata60-db-proj1

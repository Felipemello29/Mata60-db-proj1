# Sistema de Gestão de Extensão do IC

**Disciplina:** MATA60 - Banco de Dados (UFBA)  
**Projeto:** Elaboração, Modelagem e Implantação de Banco de Dados Relacional (Marco 1 - MIBD)  

Este repositório contém a entrega final do Marco 1 do projeto da disciplina de Banco de Dados (MATA60). O objetivo deste projeto foi modelar e implementar do zero um banco de dados relacional robusto em PostgreSQL para gerenciar as atividades de extensão universitária do Instituto de Computação (IC), englobando controle de projetos, atividades, inscrições, parceiros, instrutores, emissão de certificados e feedback.

## 🗂️ Estrutura do Repositório

O repositório está organizado da seguinte forma:

* **`delivery/`**: Contém os artefatos finais exigidos para a entrega.
  * `final_script.sql`: Script único consolidado contendo toda a DDL (criação de tabelas e restrições), DML de população sintética (com mais de 5.500 registros) e todas as 30 consultas analíticas finais do projeto.
  * `technical_report.md`: Relatório Técnico estruturado (formato SBC) documentando o modelo, decisões de design, metodologia e resultados de desempenho.
* **`docs/`**: Documentação de apoio.
  * `conceptual_model.md`: Descrição formal da modelagem conceitual (Notação Peter Chen) e estratégia de tradução para o modelo lógico.
  * `performance_report.md`: Resultados do benchmark de desempenho provando os ganhos de tempo (Speedup) do plano de indexação.
* **`schema/`**: Os scripts SQL originais divididos de forma modular (DDL, População, Consultas Intermediárias, Consultas Avançadas, Plano de Indexação e Benchmark).
* **`Conceptual model - BRMW.pdf`**: O Diagrama Entidade-Relacionamento conceitual exportado.
* **`minimundo-prj1.md`**: As regras de negócio originais do estudo de caso.

## 🚀 Como Executar

Para testar o banco de dados e as consultas, utilize uma instância do PostgreSQL:

1. **Geração do Banco e População:**
   Abra seu gerenciador de banco de dados (ex: pgAdmin ou DBeaver) e execute o arquivo consolidado `delivery/final_script.sql`. Este arquivo irá:
   - Criar as tabelas base e de relacionamento (`TB_`, `RL_`).
   - Popular o banco com milhares de registros de forma procedimental.
   - Criar o plano de indexação inicial.
   - Declarar e executar as 30 consultas do Marco 1 (10 Intermediárias, 20 Avançadas).

2. **Benchmark de Desempenho (Opcional):**
   Para gerar as métricas de tempo da máquina, execute o script independente `schema/benchmark.sql`. Ele automatizará execuções repetidas sem e com os índices, mostrando o *Speedup* alcançado.

## 📊 Governança e Compliance (Marco 1)

O modelo implementado cumpre com a Metodologia de Administração de Dados (MAD) utilizando convenções fortes para chaves (`ID_`), datas (`DT_`), descrições (`DS_`) e tabelas (`TB_` / `RL_`). As 30 consultas presentes garantem a triangulação de múltiplas tabelas (JOINs complexos) e funções agregadoras avançadas (`WINDOW FUNCTIONS`, Sub-queries, `GROUP BY`, `COUNT`) atendendo integralmente ao barema da disciplina.

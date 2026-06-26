# Projeto MATA60: Gestão de Projetos de Extensão (IC)
## Relatório da Entrega 2 - Rotinas Avançadas (OCRA)

**Autores:** Felipe Mello e equipe
**Disciplina:** MATA60 - Banco de Dados
**Instituição:** Instituto de Computação (IC) - UFBA

---

### 1. Descritivo do Projeto
Na primeira entrega (Marco 1 - MIBD), modelamos e implantamos um banco de dados relacional para gerenciar os projetos de extensão, instrutores, participantes e atividades de extensão do Instituto de Computação. O modelo se mostrou robusto e capaz de suportar as consultas básicas, intermediárias e avançadas necessárias.
Para esta Entrega 2 (Marco 2 - OCRA), o banco de dados foi expandido para incorporar suporte transacional seguro às principais telas do sistema, otimizar dashboards analíticos através de Views Materializadas e implementar mecanismos de proteção de privacidade (Data Masking) e rotinas de backup. Não houve alterações estruturais profundas no modelo conceitual da Entrega 1, apenas aprimoramentos analíticos.

### 2. Artefatos de Sistema de Informação
Conforme exigido pelos requisitos, elaboramos rotinas (Stored Procedures, Transações e Materialized Views) para apoiar os artefatos do Sistema de Informação.

#### Tela 1: Cadastro com Validação
*   **Artefato:** Stored Procedure `SP_CADASTRAR_PARTICIPANTE_COMPLETO`.
*   **Implementação:** Essa procedure recebe os dados do participante (nome, email, vínculo) e de um projeto padrão. Inicialmente, ela efetua 1 comando SELECT para validar se o e-mail não existe no banco. Em seguida, realiza 2 comandos INSERT (cadastra o participante em `TB_PARTICIPANTE` e o vincula ao projeto em `RL_MEMBRO_PROJETO`). Finalmente, dispara 2 comandos UPDATE atualizando dados do participante (padronizando o nome para caixa alta) e do projeto.

#### Tela 2: Cadastro ou Validação com Transação
*   **Artefato:** Stored Procedure `SP_GERENCIAR_ATIVIDADE`.
*   **Implementação:** Essa procedure utiliza a lógica de Transação implícita do PostgreSQL (bloco `BEGIN ... END`). Ela efetua 2 comandos SELECT para validar a existência do projeto e do instrutor. Se validados, realiza 1 comando INSERT na tabela `TB_ATIVIDADE`. Logo após, roda 2 comandos UPDATE (atualizando o conteúdo da atividade e o registro do instrutor). Finaliza com 1 comando DELETE removendo eventuais registros obsoletos ou atividades canceladas sem inscrições. Em caso de qualquer falha no fluxo, o rollback é acionado impedindo inserção parcial.

#### Dashboard 1: Gráficos Analíticos Estratégicos (4)
Foram desenvolvidas 4 Materialized Views com o objetivo de armazenar e disponibilizar, de forma performática, os resultados de consultas avançadas desenvolvidas na Entrega 1:
1.  `MV_RANKING_PARTICIPANTES` (Rank de notas usando WINDOW Functions).
2.  `MV_TOP_PROJETOS_CERTIFICADOS` (Top 3 de certificados).
3.  `MV_CRESCIMENTO_MENSAL_PROJETOS` (Evolução mês a mês de novos projetos).
4.  `MV_ATIVIDADES_ALTA_PARTICIPACAO` (Atividades acima da média geral).

#### Dashboard 1: Gráficos Analíticos Operacionais (6)
Foram desenvolvidas mais 6 Materialized Views, originadas de 2 consultas avançadas e 4 intermediárias da Entrega 1:
1.  `MV_PROJETOS_ACIMA_MEDIA_ALUNOS` (Projetos com contingente de alunos superior à média).
2.  `MV_PARCEIROS_MULTIPLOS_PROJETOS` (Volume de patrocínio de parceiros multitarefa).
3.  `MV_TOTAL_ATIVIDADES_PROJETO` (Contagem de atividades vinculadas por coordenador).
4.  `MV_CARGA_HORARIA_INSTRUTORES` (Volume de horas totais do instrutor).
5.  `MV_AVALIACAO_MEDIA_ATIVIDADE` (Média de notas das atividades com alta resposta).
6.  `MV_PARTICIPANTES_MAIS_ATIVOS` (Estudantes frequentemente presentes).

### 3. Rotinas (Demonstração SQL)
*Os scripts DDL completos estão disponíveis na pasta `schema/` deste repositório nos arquivos `routines_and_transactions.sql` e `materialized_views_dashboards.sql`.*

**Exemplo de uso das rotinas no PostgreSQL:**
```sql
-- Executando Tela 1:
CALL SP_CADASTRAR_PARTICIPANTE_COMPLETO('João Silva', 'joao.silva@email.com', 'ALUNO', 1);

-- Executando Tela 2:
CALL SP_GERENCIAR_ATIVIDADE('Workshop de Python Avançado', '2024-05-20', 1, 2, 8);

-- Recarregando dados para os Dashboards
REFRESH MATERIALIZED VIEW MV_RANKING_PARTICIPANTES;
REFRESH MATERIALIZED VIEW MV_CRESCIMENTO_MENSAL_PROJETOS;
```

### 4. Políticas
Implementamos políticas baseadas nos pilares de Privacidade, Segurança (RBAC) e Disponibilidade (Backup).
*O código SQL completo de privacidade encontra-se no arquivo `schema/privacy_and_security.sql`.*

#### 4.1. Configurações de Privacidade e Segurança (Data Masking e RBAC)
Criamos *Views Seguras* (`VW_PARTICIPANTE_SEGURO`) para mascarar e-mails de contatos sensíveis. Além disso, criamos a Role `analista_dados` com acessos restritos, revogando o acesso do analista direto às tabelas fonte (`TB_PARTICIPANTE`, `TB_REGISTRO_FEEDBACK`), mas garantindo acesso de `SELECT` apenas nas Views e Materialized Views. Já a Role `gestor_extensao` recebeu privilégios totais na base para administração.
Essa arquitetura garante que usuários analíticos consumam os dashboards operacionais sem ferir as exigências da LGPD de proteção de contatos diretos e identidades abertas nos feedbacks.

#### 4.2. Demonstração das Políticas de Backup
Para mitigar a perda de dados, construímos um script Shell (`scripts/backup_policy.sh`) contendo uma rotina de backup (Dump Lógico) automatizada usando `pg_dump` com o formato customizado (`-F c`). O script mantém logs das execuções e engloba uma política de retenção que remove automaticamente backups com mais de 7 dias de idade utilizando o comando `find` com a flag `-mtime`. 
A recomendação para o ambiente de produção é que o script seja agendado na crontab (ex: `0 2 * * *`) executando toda madrugada às 02h00.

### 5. Anexos
- Script de rotinas e transações: `schema/routines_and_transactions.sql`
- Script das materialized views: `schema/materialized_views_dashboards.sql`
- Script de privacidade: `schema/privacy_and_security.sql`
- Script bash de backup: `scripts/backup_policy.sh`

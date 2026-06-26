# Projeto MATA60: GestÃ£o de Projetos de ExtensÃ£o (IC)
## RelatÃ³rio da Entrega 2 - Rotinas AvanÃ§adas (OCRA)

**Autores:** Felipe Mello e equipe
**Disciplina:** MATA60 - Banco de Dados
**InstituiÃ§Ã£o:** Instituto de ComputaÃ§Ã£o (IC) - UFBA

---

### 1. Descritivo do Projeto
Na primeira entrega (Marco 1 - MIBD), modelamos e implantamos um banco de dados relacional para gerenciar os projetos de extensÃ£o, instrutores, participantes e atividades de extensÃ£o do Instituto de ComputaÃ§Ã£o. O modelo se mostrou robusto e capaz de suportar as consultas bÃ¡sicas, intermediÃ¡rias e avanÃ§adas necessÃ¡rias.
Para esta Entrega 2 (Marco 2 - OCRA), o banco de dados foi expandido para incorporar suporte transacional seguro Ã s principais telas do sistema, otimizar dashboards analÃ­ticos atravÃ©s de Views Materializadas e implementar mecanismos de proteÃ§Ã£o de privacidade (Data Masking) e rotinas de backup. NÃ£o houve alteraÃ§Ãµes estruturais profundas no modelo conceitual da Entrega 1, apenas aprimoramentos analÃ­ticos.

### 2. Artefatos de Sistema de InformaÃ§Ã£o

**Tabela de Mapeamento de Requisitos para Rotinas:**

| Artefato | Nome | Requisito Atendido |
|---|---|---|
| Stored Procedure | `SP_CADASTRAR_PARTICIPANTE_COMPLETO` | RF2 (InscriÃ§Ã£o e cadastro de participantes) |
| Stored Procedure | `SP_GERENCIAR_ATIVIDADE` | RF1 (Gerenciar atividades) |
| TransaÃ§Ã£o | `SP_INSCREVER_COM_VALIDACAO` | RF2 (InscriÃ§Ã£o com controle de capacidade) |
| TransaÃ§Ã£o | `SP_TRANSFERIR_PARTICIPANTE` | RF7 (Gerenciar projetos e membros) |
| Materialized View | `MV_RANKING_PARTICIPANTES` | RF6 (Controlar notas) |
| Materialized View | `MV_TOP_PROJETOS_CERTIFICADOS`| RF3 (Emitir certificados) |
| Materialized View | `MV_CRESCIMENTO_MENSAL_PROJETOS` | RF5 (Gerenciar parcerias/projetos) |
| Materialized View | `MV_ATIVIDADES_ALTA_PARTICIPACAO` | RF2 (HistÃ³rico de participaÃ§Ã£o) |
| Materialized View | `MV_PROJETOS_ACIMA_MEDIA_ALUNOS` | RF7 (Gerenciar projetos estruturantes) |
| Materialized View | `MV_PARCEIROS_MULTIPLOS_PROJETOS`| RF5 (Gerenciar parcerias) |
| Materialized View | `MV_TOTAL_ATIVIDADES_PROJETO` | RF1 (Gerenciar atividades) |
| Materialized View | `MV_CARGA_HORARIA_INSTRUTORES` | RF1 (Gerenciar atividades) |
| Materialized View | `MV_AVALIACAO_MEDIA_ATIVIDADE` | RF4 (Registrar feedbacks) |
| Materialized View | `MV_PARTICIPANTES_MAIS_ATIVOS` | RF2 (Controle de presenÃ§a) |

Conforme exigido pelos requisitos, elaboramos rotinas (Stored Procedures, TransaÃ§Ãµes e Materialized Views) para apoiar os artefatos do Sistema de InformaÃ§Ã£o.

#### Tela 1: Cadastro com ValidaÃ§Ã£o
*   **Artefato:** Stored Procedure `SP_CADASTRAR_PARTICIPANTE_COMPLETO`.
*   **ImplementaÃ§Ã£o:** Essa procedure recebe os dados do participante (nome, email, vÃ­nculo) e de um projeto padrÃ£o. Inicialmente, ela efetua 1 comando SELECT para validar se o e-mail nÃ£o existe no banco. Em seguida, realiza 2 comandos INSERT (cadastra o participante em `tabela_participante` e o vincula ao projeto em `RL_MEMBRO_PROJETO`). Finalmente, dispara 2 comandos UPDATE atualizando dados do participante (padronizando o nome para caixa alta) e do projeto.

#### Tela 2: Cadastro ou ValidaÃ§Ã£o com TransaÃ§Ã£o
*   **Artefato:** Stored Procedure `SP_GERENCIAR_ATIVIDADE`.
*   **ImplementaÃ§Ã£o:** Essa procedure utiliza a lÃ³gica de TransaÃ§Ã£o implÃ­cita do PostgreSQL (bloco `BEGIN ... END`). Ela efetua 2 comandos SELECT para validar a existÃªncia do projeto e do instrutor. Se validados, realiza 1 comando INSERT na tabela `TB_ATIVIDADE`. Logo apÃ³s, roda 2 comandos UPDATE (atualizando o conteÃºdo da atividade e o registro do instrutor). Finaliza com 1 comando DELETE removendo eventuais registros obsoletos ou atividades canceladas sem inscriÃ§Ãµes. Em caso de qualquer falha no fluxo, o rollback Ã© acionado impedindo inserÃ§Ã£o parcial.

#### Dashboard 1: GrÃ¡ficos AnalÃ­ticos EstratÃ©gicos (4)
Foram desenvolvidas 4 Materialized Views com o objetivo de armazenar e disponibilizar, de forma performÃ¡tica, os resultados de consultas avanÃ§adas desenvolvidas na Entrega 1:
1.  `MV_RANKING_PARTICIPANTES` (Rank de notas usando WINDOW Functions).
2.  `MV_TOP_PROJETOS_CERTIFICADOS` (Top 3 de certificados).
3.  `MV_CRESCIMENTO_MENSAL_PROJETOS` (EvoluÃ§Ã£o mÃªs a mÃªs de novos projetos).
4.  `MV_ATIVIDADES_ALTA_PARTICIPACAO` (Atividades acima da mÃ©dia geral).

#### Dashboard 1: GrÃ¡ficos AnalÃ­ticos Operacionais (6)
Foram desenvolvidas mais 6 Materialized Views, originadas de 2 consultas avanÃ§adas e 4 intermediÃ¡rias da Entrega 1:
1.  `MV_PROJETOS_ACIMA_MEDIA_ALUNOS` (Projetos com contingente de alunos superior Ã  mÃ©dia).
2.  `MV_PARCEIROS_MULTIPLOS_PROJETOS` (Volume de patrocÃ­nio de parceiros multitarefa).
3.  `MV_TOTAL_ATIVIDADES_PROJETO` (Contagem de atividades vinculadas por coordenador).
4.  `MV_CARGA_HORARIA_INSTRUTORES` (Volume de horas totais do instrutor).
5.  `MV_AVALIACAO_MEDIA_ATIVIDADE` (MÃ©dia de notas das atividades com alta resposta).
6.  `MV_PARTICIPANTES_MAIS_ATIVOS` (Estudantes frequentemente presentes).

### 3. Rotinas (DemonstraÃ§Ã£o SQL)
*Os scripts DDL completos estÃ£o disponÃ­veis na pasta `schema/` deste repositÃ³rio nos arquivos `routines_and_transactions.sql` e `materialized_views_dashboards.sql`.*

AlÃ©m das Stored Procedures descritas, foram implementadas as seguintes **TransaÃ§Ãµes ExplÃ­citas** (com suporte a COMMIT/ROLLBACK/SAVEPOINT) no arquivo `routines_and_transactions.sql`:
1. `SP_INSCREVER_COM_VALIDACAO`: TransaÃ§Ã£o para inscriÃ§Ã£o com rollback parcial em caso de capacidade excedida (validaÃ§Ã£o de vagas).
2. `SP_TRANSFERIR_PARTICIPANTE`: TransaÃ§Ã£o para transferÃªncia atÃ´mica de um participante entre projetos de extensÃ£o.

**Exemplo de uso das rotinas no PostgreSQL:**
```sql
-- Executando Tela 1:
CALL SP_CADASTRAR_PARTICIPANTE_COMPLETO('JoÃ£o Silva', 'joao.silva@email.com', 'ALUNO', 1);

-- Executando Tela 2:
CALL SP_GERENCIAR_ATIVIDADE('Workshop de Python AvanÃ§ado', '2024-05-20', 1, 2, 8);

-- Recarregando dados para os Dashboards
REFRESH MATERIALIZED VIEW MV_RANKING_PARTICIPANTES;
REFRESH MATERIALIZED VIEW MV_CRESCIMENTO_MENSAL_PROJETOS;
```

### 4. PolÃ­ticas
Implementamos polÃ­ticas baseadas nos pilares de Privacidade, SeguranÃ§a (RBAC) e Disponibilidade (Backup).
*O cÃ³digo SQL completo de privacidade encontra-se no arquivo `schema/privacy_and_security.sql`.*

#### 4.1. ConfiguraÃ§Ãµes de Privacidade e SeguranÃ§a (Data Masking e RBAC)
Criamos *Views Seguras* (`VW_PARTICIPANTE_SEGURO`) para mascarar e-mails de contatos sensÃ­veis. AlÃ©m disso, criamos a Role `analista_dados` com acessos restritos, revogando o acesso do analista direto Ã s tabelas fonte (`tabela_participante`, `TB_REGISTRO_FEEDBACK`), mas garantindo acesso de `SELECT` apenas nas Views e Materialized Views. JÃ¡ a Role `gestor_extensao` recebeu privilÃ©gios totais na base para administraÃ§Ã£o.
Essa arquitetura garante que usuÃ¡rios analÃ­ticos consumam os dashboards operacionais sem ferir as exigÃªncias da LGPD de proteÃ§Ã£o de contatos diretos e identidades abertas nos feedbacks.

#### 4.2. DemonstraÃ§Ã£o das PolÃ­ticas de Backup
Para mitigar a perda de dados, construÃ­mos um script Shell (`scripts/backup_policy.sh`) contendo uma rotina de backup (Dump LÃ³gico) automatizada usando `pg_dump` com o formato customizado (`-F c`). O script mantÃ©m logs das execuÃ§Ãµes e engloba uma polÃ­tica de retenÃ§Ã£o que remove automaticamente backups com mais de 7 dias de idade utilizando o comando `find` com a flag `-mtime`. 
A recomendaÃ§Ã£o para o ambiente de produÃ§Ã£o Ã© que o script seja agendado na crontab (ex: `0 2 * * *`) executando toda madrugada Ã s 02h00.

### 5. Anexos
- Script de rotinas e transaÃ§Ãµes: `schema/routines_and_transactions.sql`
- Script das materialized views: `schema/materialized_views_dashboards.sql`
- Script de privacidade: `schema/privacy_and_security.sql`
- Script bash de backup: `scripts/backup_policy.sh`

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
| Materialized View | `VM_RANKING_PARTICIPANTES` | RF6 (Controlar notas) |
| Materialized View | `VM_TOP_PROJETOS_CERTIFICADOS`| RF3 (Emitir certificados) |
| Materialized View | `VM_CRESCIMENTO_MENSAL_PROJETOS` | RF5 (Gerenciar parcerias/projetos) |
| Materialized View | `VM_ATIVIDADES_ALTA_PARTICIPACAO` | RF2 (HistÃ³rico de participaÃ§Ã£o) |
| Materialized View | `VM_PROJETOS_ACIMA_MEDIA_ALUNOS` | RF7 (Gerenciar projetos estruturantes) |
| Materialized View | `VM_PARCEIROS_MULTIPLOS_PROJETOS`| RF5 (Gerenciar parcerias) |
| Materialized View | `VM_TOTAL_ATIVIDADES_PROJETO` | RF1 (Gerenciar atividades) |
| Materialized View | `VM_CARGA_HORARIA_INSTRUTORES` | RF1 (Gerenciar atividades) |
| Materialized View | `VM_AVALIACAO_MEDIA_ATIVIDADE` | RF4 (Registrar feedbacks) |
| Materialized View | `VM_PARTICIPANTES_MAIS_ATIVOS` | RF2 (Controle de presenÃ§a) |

Conforme exigido pelos requisitos, elaboramos rotinas (Stored Procedures, TransaÃ§Ãµes e Materialized Views) para apoiar os artefatos do Sistema de InformaÃ§Ã£o.

#### Tela 1: Cadastro com ValidaÃ§Ã£o
*   **Artefato:** Stored Procedure `SP_CADASTRAR_PARTICIPANTE_COMPLETO`.
*   **ImplementaÃ§Ã£o:** Essa procedure recebe os dados do participante (nome, email, vÃ­nculo) e de um projeto padrÃ£o. Inicialmente, ela efetua 1 comando SELECT para validar se o e-mail nÃ£o existe no banco. Em seguida, realiza 2 comandos INSERT (cadastra o participante em `tabela_participante` e o vincula ao projeto em `RL_MEMBRO_PROJETO`). Finalmente, dispara 2 comandos UPDATE atualizando dados do participante (padronizando o nome para caixa alta) e do projeto.

#### Tela 2: Cadastro ou ValidaÃ§Ã£o com TransaÃ§Ã£o
*   **Artefato:** Stored Procedure `SP_GERENCIAR_ATIVIDADE`.
*   **ImplementaÃ§Ã£o:** Essa procedure utiliza a lÃ³gica de TransaÃ§Ã£o implÃ­cita do PostgreSQL (bloco `BEGIN ... END`). Ela efetua 2 comandos SELECT para validar a existÃªncia do projeto e do instrutor. Se validados, realiza 1 comando INSERT na tabela `TB_ATIVIDADE`. Logo apÃ³s, roda 2 comandos UPDATE (atualizando o conteÃºdo da atividade e o registro do instrutor). Finaliza com 1 comando DELETE removendo eventuais registros obsoletos ou atividades canceladas sem inscriÃ§Ãµes. Em caso de qualquer falha no fluxo, o rollback Ã© acionado impedindo inserÃ§Ã£o parcial.

#### Dashboard 1: GrÃ¡ficos AnalÃ­ticos EstratÃ©gicos (4)
Foram desenvolvidas 4 Materialized Views com o objetivo de armazenar e disponibilizar, de forma performÃ¡tica, os resultados de consultas avanÃ§adas desenvolvidas na Entrega 1:
1.  `VM_RANKING_PARTICIPANTES` (Rank de notas usando WINDOW Functions).
2.  `VM_TOP_PROJETOS_CERTIFICADOS` (Top 3 de certificados).
3.  `VM_CRESCIMENTO_MENSAL_PROJETOS` (EvoluÃ§Ã£o mÃªs a mÃªs de novos projetos).
4.  `VM_ATIVIDADES_ALTA_PARTICIPACAO` (Atividades acima da mÃ©dia geral).

#### Dashboard 1: GrÃ¡ficos AnalÃ­ticos Operacionais (6)
Foram desenvolvidas mais 6 Materialized Views, originadas de 2 consultas avanÃ§adas e 4 intermediÃ¡rias da Entrega 1:
1.  `VM_PROJETOS_ACIMA_MEDIA_ALUNOS` (Projetos com contingente de alunos superior Ã  mÃ©dia).
2.  `VM_PARCEIROS_MULTIPLOS_PROJETOS` (Volume de patrocÃ­nio de parceiros multitarefa).
3.  `VM_TOTAL_ATIVIDADES_PROJETO` (Contagem de atividades vinculadas por coordenador).
4.  `VM_CARGA_HORARIA_INSTRUTORES` (Volume de horas totais do instrutor).
5.  `VM_AVALIACAO_MEDIA_ATIVIDADE` (MÃ©dia de notas das atividades com alta resposta).
6.  `VM_PARTICIPANTES_MAIS_ATIVOS` (Estudantes frequentemente presentes).

### 3. Rotinas (DemonstraÃ§Ã£o SQL)
*Os scripts DDL completos estÃ£o disponÃ­veis na pasta `` deste repositÃ³rio nos arquivos `routines_and_transactions.sql` e `materialized_views_dashboards.sql`.*

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
REFRESH MATERIALIZED VIEW VM_RANKING_PARTICIPANTES;
REFRESH MATERIALIZED VIEW VM_CRESCIMENTO_MENSAL_PROJETOS;
```

### 4. PolÃ­ticas
Implementamos polÃ­ticas baseadas nos pilares de Privacidade, SeguranÃ§a (RBAC) e Disponibilidade (Backup).
*O cÃ³digo SQL completo de privacidade encontra-se no arquivo `privacy_and_security.sql`.*

#### 4.1. ConfiguraÃ§Ãµes de Privacidade e SeguranÃ§a (Data Masking e RBAC)
Criamos *Views Seguras* (`VW_PARTICIPANTE_SEGURO`) para mascarar e-mails de contatos sensÃ­veis. AlÃ©m disso, criamos a Role `analista_dados` com acessos restritos, revogando o acesso do analista direto Ã s tabelas fonte (`tabela_participante`, `TB_REGISTRO_FEEDBACK`), mas garantindo acesso de `SELECT` apenas nas Views e Materialized Views. JÃ¡ a Role `gestor_extensao` recebeu privilÃ©gios totais na base para administraÃ§Ã£o.
Essa arquitetura garante que usuÃ¡rios analÃ­ticos consumam os dashboards operacionais sem ferir as exigÃªncias da LGPD de proteÃ§Ã£o de contatos diretos e identidades abertas nos feedbacks.

#### 4.2. DemonstraÃ§Ã£o das PolÃ­ticas de Backup
Para mitigar a perda de dados, construímos um script Shell (`backup_policy.sh`) contendo uma rotina de backup (Dump Lógico) automatizada usando `pg_dump` com o formato customizado (`-F c`). O script mantém logs das execuções e engloba uma política de retenção que remove automaticamente backups com mais de 7 dias de idade utilizando o comando `find` com a flag `-mtime`. 
A recomendação para o ambiente de produção é que o script seja agendado na crontab (ex: `0 2 * * *`) executando toda madrugada às 02h00.

### 5. Anexos
- Script de rotinas e transações: `routines_and_transactions.sql`
- Script das materialized views: `materialized_views_dashboards.sql`
- Script de privacidade: `privacy_and_security.sql`
- Script bash de backup: `backup_policy.sh`

### 6. Tutorial de Reprodução

Para reproduzir o ambiente completo e testar as funcionalidades entregues neste marco, siga a ordem de execução dos scripts abaixo:

1. **`final_script.sql`**: Executar primeiro. Cria o esquema básico de tabelas, insere a massa de dados inicial e cria as views e índices originais do Marco 1.
   ```bash
   psql -U seu_usuario -d seu_banco -f final_script.sql
   ```
2. **`routines_and_transactions.sql`**: Em seguida, criar as *Stored Procedures* e Transações. Elas dependem das tabelas recém-criadas.
   ```bash
   psql -U seu_usuario -d seu_banco -f routines_and_transactions.sql
   ```
3. **`materialized_views_dashboards.sql`**: Após garantir as tabelas e rotinas, crie as Materialized Views (que farão o cache de consultas analíticas).
   ```bash
   psql -U seu_usuario -d seu_banco -f materialized_views_dashboards.sql
   ```
4. **`privacy_and_security.sql`**: Por fim, aplique as políticas de segurança, views de *data masking* e RBAC.
   ```bash
   psql -U seu_usuario -d seu_banco -f privacy_and_security.sql
   ```
5. *(Opcional)* **`benchmark.sql`**: Caso queira verificar a performance dos índices com o plano de otimização.

### 7. Fundamentação Teórica e Testes Adicionais

As Transações Explícitas desenvolvidas neste marco (`SP_INSCREVER_COM_VALIDACAO` e `SP_TRANSFERIR_PARTICIPANTE`) garantem a propriedade de **Atomicidade** (ACID): ou todas as operações daquele bloco são aplicadas com sucesso (COMMIT), ou, se qualquer violação for detectada (por exemplo, falta de vagas na atividade), todas as alterações prévias da transação são revertidas integralmente (ROLLBACK).

**Demonstração em terminal (Rollback por falta de vaga):**
```sql
CALL SP_INSCREVER_COM_VALIDACAO(5, 2);
-- Output esperado:
-- NOTICE:  Iniciando validação de capacidade da atividade 2...
-- ERROR:  Capacidade excedida para a atividade. Rollback realizado.
-- CONTEXT:  PL/pgSQL function sp_inscrever_com_validacao(integer,integer) line 18 at RAISE
```

O uso de **Materialized Views** é justificado pela redução de carga na computação em tempo real para dashboards operacionais. Ao contrário de uma *View* normal, que executa o `SELECT` em tempo real a cada chamada, as Materialized Views armazenam o *Result Set* fisicamente, entregando tempo de resposta O(1) para a camada de apresentação. O compromisso (Trade-off) é a necessidade de atualização programada (`REFRESH MATERIALIZED VIEW`), o que é aceitável em cenários de Business Intelligence que não exigem precisão de segundos (ex: atualização diária durante a madrugada).


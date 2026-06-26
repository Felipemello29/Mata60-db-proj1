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

**Tabela de Mapeamento de Requisitos para Rotinas:**

| Artefato | Nome | Requisito Atendido |
|---|---|---|
| Stored Procedure | `SP_CADASTRAR_PARTICIPANTE_COMPLETO` | RF2 (Inscrição e cadastro de participantes) |
| Stored Procedure | `SP_GERENCIAR_ATIVIDADE` | RF1 (Gerenciar atividades) |
| Transação | `SP_INSCREVER_COM_VALIDACAO` | RF2 (Inscrição com controle de capacidade) |
| Transação | `SP_TRANSFERIR_PARTICIPANTE` | RF7 (Gerenciar projetos e membros) |
| Materialized View | `VM_INDICE_RETENCAO_PROJETO` | RF2 (Histórico de participação / retenção) |
| Materialized View | `VM_GAP_EMISSAO_CERTIFICADO` | RF3 (Eficiência na emissão de certificados) |
| Materialized View | `VM_DISTRIBUICAO_QUARTIS_NOTAS` | RF6 (Análise de distribuição de desempenho) |
| Materialized View | `VM_COBERTURA_INSTRUTORES_PROJETO` | RF1 (Cobertura docente por projeto) |
| Materialized View | `VM_COHORT_PRIMEIRA_INSCRICAO` | RF2 (Análise de coortes de participantes) |
| Materialized View | `VM_NPS_POR_PROJETO` | RF4 (Net Promoter Score por projeto) |
| Materialized View | `VM_MATRIZ_VINCULO_PRESENCA` | RF2 (Presença por tipo de vínculo) |
| Materialized View | `VM_IMPACTO_PATROCINIO_ATIVIDADE` | RF5 (Impacto do patrocínio nas atividades) |
| Materialized View | `VM_VOLUME_SEMANAL_INSCRICOES` | RF2 (Tendência semanal de inscrições) |
| Materialized View | `VM_ROI_PARCEIROS` | RF5 (Retorno sobre investimento de parceiros) |

Conforme exigido pelos requisitos, elaboramos rotinas (Stored Procedures, Transações e Materialized Views) para apoiar os artefatos do Sistema de Informação.

#### Tela 1: Cadastro com Validação
*   **Artefato:** Stored Procedure `SP_CADASTRAR_PARTICIPANTE_COMPLETO`.
*   **Implementação:** Essa procedure recebe os dados do participante (nome, email, vínculo) e de um projeto padrão. Inicialmente, ela efetua 1 comando SELECT para validar se o e-mail não existe no banco. Em seguida, realiza 2 comandos INSERT (cadastra o participante em `tabela_participante` e o vincula ao projeto em `RL_MEMBRO_PROJETO`). Finalmente, dispara 2 comandos UPDATE atualizando dados do participante (padronizando o nome para caixa alta) e do projeto.

#### Tela 2: Cadastro ou Validação com Transação
*   **Artefato:** Stored Procedure `SP_GERENCIAR_ATIVIDADE`.
*   **Implementação:** Essa procedure utiliza a lógica de Transação implícita do PostgreSQL (bloco `BEGIN ... END`). Ela efetua 2 comandos SELECT para validar a existência do projeto e do instrutor. Se validados, realiza 1 comando INSERT na tabela `TB_ATIVIDADE`. Logo após, roda 2 comandos UPDATE (atualizando o conteúdo da atividade e o registro do instrutor). Finaliza com 1 comando DELETE removendo eventuais registros obsoletos ou atividades canceladas sem inscrições. Em caso de qualquer falha no fluxo, o rollback é acionado impedindo inserção parcial.

#### Dashboard 1: Gráficos Analíticos Estratégicos (4)
Foram desenvolvidas 4 Materialized Views com o objetivo de armazenar e disponibilizar, de forma performática, os resultados de **novas consultas avançadas exclusivas deste Marco 2** (todas diferentes da Entrega 1):
1.  `VM_INDICE_RETENCAO_PROJETO` (Índice de retenção: taxa de participantes que retornam a mais de uma atividade no mesmo projeto, usando CTEs e CASE com agregação condicional).
2.  `VM_GAP_EMISSAO_CERTIFICADO` (Gap temporal médio entre a realização da atividade e a emissão do certificado, com window function AVG OVER por projeto).
3.  `VM_DISTRIBUICAO_QUARTIS_NOTAS` (Distribuição de notas segmentada em quartis via NTILE(4), cruzada com o tipo de vínculo institucional).
4.  `VM_COBERTURA_INSTRUTORES_PROJETO` (Análise de cobertura docente: razão instrutor/atividade, carga média por instrutor, ranking de diversidade via RANK).

#### Dashboard 1: Gráficos Analíticos Operacionais (6)
Foram desenvolvidas mais 6 Materialized Views, originadas de **novas consultas avançadas (2) e intermediárias (4) exclusivas desta entrega**, sem nenhuma reutilização das consultas do Marco 1:
1.  `VM_COHORT_PRIMEIRA_INSCRICAO` (Análise de coortes: agrupa participantes pelo mês de primeira inscrição e calcula engajamento per capita, usando CTEs encadeadas e SUM OVER).
2.  `VM_NPS_POR_PROJETO` (Net Promoter Score simplificado por projeto: classifica feedbacks em Detratores/Neutros/Promotores e calcula o índice NPS).
3.  `VM_MATRIZ_VINCULO_PRESENCA` (Tabela cruzada entre tipo de vínculo e status de presença, com taxas percentuais e nota média por segmento).
4.  `VM_IMPACTO_PATROCINIO_ATIVIDADE` (Comparação do volume de inscrições e nota média entre atividades com e sem patrocínio externo).
5.  `VM_VOLUME_SEMANAL_INSCRICOES` (Evolução semanal de inscrições com média móvel de 4 semanas usando AVG OVER com ROWS BETWEEN).
6.  `VM_ROI_PARCEIROS` (Retorno sobre investimento: custo por certificado e custo por inscrição de cada parceiro, usando LEFT JOINs encadeados em 5 tabelas).

### 3. Rotinas (Demonstração SQL)
*Os scripts DDL completos estão disponíveis na pasta de entrega deste repositório nos arquivos `routines_and_transactions.sql` e `materialized_views_dashboards.sql`.*

Além das Stored Procedures descritas, foram implementadas as seguintes **Transações Explícitas** no arquivo `routines_and_transactions.sql`:
1. `SP_INSCREVER_COM_VALIDACAO`: Transação para inscrição com rollback parcial via bloco `BEGIN ... EXCEPTION ... END` (savepoint implícito do PL/pgSQL) em caso de capacidade excedida ou duplicidade de inscrição.
2. `SP_TRANSFERIR_PARTICIPANTE`: Transação para transferência atômica de um participante entre projetos de extensão, com proteção contra estado inconsistente via exception handler.

**Nota técnica sobre Transações no PL/pgSQL:**
No PostgreSQL, comandos de transação parcial (`SAVEPOINT`, `ROLLBACK TO SAVEPOINT`, `RELEASE SAVEPOINT`) **não podem** ser chamados diretamente dentro de blocos PL/pgSQL — tentativas resultam em `ERROR: unsupported transaction command in PL/pgSQL`. A técnica correta é utilizar blocos `BEGIN ... EXCEPTION ... END`, que criam savepoints implícitos gerenciados internamente pelo SGBD. Se uma exceção é lançada dentro do sub-bloco, o PostgreSQL reverte automaticamente todas as alterações feitas dentro daquele bloco (rollback parcial) e desvia a execução para o handler `EXCEPTION`.

**Exemplo de uso das rotinas no PostgreSQL:**
```sql
-- Executando Tela 1:
CALL SP_CADASTRAR_PARTICIPANTE_COMPLETO('João Silva', 'joao.silva@email.com', 'ALUNO', 1);

-- Executando Tela 2:
CALL SP_GERENCIAR_ATIVIDADE('Workshop de Python Avançado', '2024-05-20', 1, 2, 8);

-- Executando Transação 1 (inscrição com controle de vagas):
CALL SP_INSCREVER_COM_VALIDACAO(5, 2);

-- Executando Transação 2 (transferência entre projetos):
CALL SP_TRANSFERIR_PARTICIPANTE(10, 1, 3);

-- Recarregando dados para os Dashboards
REFRESH MATERIALIZED VIEW VM_INDICE_RETENCAO_PROJETO;
REFRESH MATERIALIZED VIEW VM_GAP_EMISSAO_CERTIFICADO;
REFRESH MATERIALIZED VIEW VM_DISTRIBUICAO_QUARTIS_NOTAS;
REFRESH MATERIALIZED VIEW VM_COBERTURA_INSTRUTORES_PROJETO;
REFRESH MATERIALIZED VIEW VM_COHORT_PRIMEIRA_INSCRICAO;
REFRESH MATERIALIZED VIEW VM_NPS_POR_PROJETO;
REFRESH MATERIALIZED VIEW VM_MATRIZ_VINCULO_PRESENCA;
REFRESH MATERIALIZED VIEW VM_IMPACTO_PATROCINIO_ATIVIDADE;
REFRESH MATERIALIZED VIEW VM_VOLUME_SEMANAL_INSCRICOES;
REFRESH MATERIALIZED VIEW VM_ROI_PARCEIROS;
```

### 4. Políticas
Implementamos políticas baseadas nos pilares de Privacidade, Segurança (RBAC) e Disponibilidade (Backup).
*O código SQL completo de privacidade encontra-se no arquivo `privacy_and_security.sql`.*

#### 4.1. Configurações de Privacidade e Segurança (Data Masking e RBAC)
Criamos *Views Seguras* (`VW_PARTICIPANTE_SEGURO`) para mascarar e-mails de contatos sensíveis. Além disso, criamos a Role `analista_dados` com acessos restritos, revogando o acesso do analista direto às tabelas fonte (`tabela_participante`, `TB_REGISTRO_FEEDBACK`), mas garantindo acesso de `SELECT` apenas nas Views e Materialized Views. Já a Role `gestor_extensao` recebeu privilégios totais na base para administração.
Essa arquitetura garante que usuários analíticos consumam os dashboards operacionais sem ferir as exigências da LGPD de proteção de contatos diretos e identidades abertas nos feedbacks.

#### 4.2. Demonstração das Políticas de Backup
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

As Transações Explícitas desenvolvidas neste marco (`SP_INSCREVER_COM_VALIDACAO` e `SP_TRANSFERIR_PARTICIPANTE`) garantem a propriedade de **Atomicidade** (ACID): ou todas as operações daquele bloco são aplicadas com sucesso (COMMIT), ou, se qualquer violação for detectada (por exemplo, falta de vagas na atividade), todas as alterações prévias daquele sub-bloco são revertidas integralmente pelo savepoint implícito do handler `EXCEPTION`.

**Técnica utilizada:** Blocos `BEGIN ... EXCEPTION ... END` no PL/pgSQL criam savepoints implícitos gerenciados pelo PostgreSQL. Quando uma exceção é levantada (ou ocorre) dentro do sub-bloco, o SGBD automaticamente reverte as operações feitas dentro daquele `BEGIN` interno e desvia para o handler. Isso difere de `SAVEPOINT`/`ROLLBACK TO SAVEPOINT` explícitos, que não são suportados diretamente em PL/pgSQL.

**Demonstração em terminal (Rollback por falta de vaga):**
```sql
CALL SP_INSCREVER_COM_VALIDACAO(5, 2);
-- Output esperado (caso capacidade excedida):
-- NOTICE:  Inscrição revertida: Capacidade excedida para a atividade 2. Limite: 100, Atual: 101
```

**Demonstração em terminal (Transferência bem-sucedida):**
```sql
CALL SP_TRANSFERIR_PARTICIPANTE(10, 1, 3);
-- Output esperado:
-- NOTICE:  Transferência concluída: "PARTICIPANTE 10" movido do projeto 1 para o projeto 3.
```

O uso de **Materialized Views** é justificado pela redução de carga na computação em tempo real para dashboards operacionais. Ao contrário de uma *View* normal, que executa o `SELECT` em tempo real a cada chamada, as Materialized Views armazenam o *Result Set* fisicamente, entregando tempo de resposta O(1) para a camada de apresentação. O compromisso (Trade-off) é a necessidade de atualização programada (`REFRESH MATERIALIZED VIEW`), o que é aceitável em cenários de Business Intelligence que não exigem precisão de segundos (ex: atualização diária durante a madrugada).


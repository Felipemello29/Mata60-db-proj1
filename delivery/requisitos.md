# [PRJ1] Sistema de Informação para Atividades de Extensão Universitária

# Introdução:

O Instituto de Computação realiza diversas atividades de extensão universitária, como minicursos, workshops e eventos abertos à comunidade. Atualmente, a gestão dessas atividades é feita manualmente, dificultando o acompanhamento da participação dos alunos e do impacto social das ações. Um sistema de informação pode otimizar a organização, inscrição e avaliação das atividades.

# Estratégia para elaboração dos requisitos:

A obtenção dos requisitos foi baseada na análise de documentos institucionais sobre extensão universitária, entrevistas com organizadores e análise de sistemas similares. Utilizamos a técnica de brainstorming com stakeholders para levantamento inicial e a técnica de casos de uso para validar cenários de interação.

# Requisitos:

- Gerenciar atividades de extensão, incluindo datas, palestrantes e conteúdos.
- Permitir a inscrição e controle de presença dos participantes.
- Emitir certificados automaticamente após a conclusão das atividades.
- Registrar feedbacks dos participantes.
- Gerenciar parcerias com empresas e ONGs.
- Disponibilizar relatórios sobre impacto e participação.
- Controlar o histórico de participação dos alunos.

# Sugestão de Mini-mundo:

O banco de dados deve conter tabelas como: Atividade, Participante, Instrutor, Certificado, Parceiro, Feedback, Evento e HistóricoParticipação. Cada atividade pode ter múltiplos instrutores e participantes. Empresas parceiras podem patrocinar eventos e oferecer suporte.


# [PPP1] Política de Preservação de Privacidade para Bancos de Dados - Modelo 1

# **1. Objetivo**

Garantir a segurança, privacidade e rastreabilidade dos dados, definindo níveis de acesso restritos e requisitos de auditoria para todas as ações realizadas no banco de dados, em conformidade com a **LGPD** e regulamentações de segurança.

# **2. Níveis de Acesso, Permissões e Requisitos de Auditoria**

| **Nível de Acesso** | **Função** | **Permissões** | **Eventos Auditados** |
| --- | --- | --- | --- |
| **DBA (Admin)** | Administrador do Banco | - Acesso total (DDL, DML, DCL).
- Gerenciamento de usuários, roles, backups. | **Todas as ações**:
- CREATE, ALTER, DROP.- GRANT/REVOKE.
- Acesso a tabelas sensíveis.
- Logins bem-sucedidos e falhos. |
| **Sistema** | Aplicação/Serviço | - Executar DML (INSERT, UPDATE, DELETE).
- Acesso a procedures, triggers, transações. | **Operações críticas**:
- Modificações em dados (INSERT/UPDATE/DELETE).- Execução de stored procedures.
- Tentativas de acesso a objetos não autorizados. |
| **Análise** | Analista de Dados | - SELECT em tabelas e views.
- Consulta a materialized views. | **Consultas a dados sensíveis**:- Acesso a PII (dados pessoais).
- Consultas com alto consumo de recursos. |
| **Backup** | Operador de Backup | - Executar backups (leitura total).
- Nenhuma modificação. | **Eventos de backup**:
- Início/término de backups.
- Falhas durante o processo.
- Tentativas de acesso a dados fora do escopo. |

# **3. Controles de Auditoria**

Todos os eventos devem ser registrados em **pgAudit** ou tabelas dedicadas.

[PBR1] Política de backup e recuperação FULL
Seção 1: Estratégias de Backup
Tipo de Backup: Full (completo).
Artefatos: Bancos de dados, catálogo do banco de dados e configurações do SGBD.
Temporalidade: Semanal.
Armazenamento: Local e remoto (Drive, github, dropbox, etc.)
Responsabilidades: Administrador de backup utilizando o usuário dbbackup_ic.
Seção 2: Procedimentos de Teste
Testes de Integridade: Diários, verificando logs de backup em busca de erros.
Testes de Restauração: Mensais, em ambientes isolados de produção, com relatórios enviados à CGTI.
Validação: Confirmação de RTO (Recovery Time Objective) e RPO (Recovery Point Objective) conforme pactuado.
Seção 3: Estratégias de Recuperação
Armazenamento Local: Restauração prioritária em até 4 horas para sistemas críticos.
Armazenamento Online: Restauração em até 24 horas, com dados criptografados e acesso restrito a autorizados.
Documentação: Todas as restaurações devem ser registradas, incluindo tempo gasto e sucesso da operação.
Todos os arquivos gerados pelas rotinas de backup devem ser armazenados ou recuperados localmente ou

# [MAD1] Metodologia baseada no IBAMA

# Seção 1: Regras Gerais para o Padrão de Nomenclatura

## **Formação dos Nomes:**

- Tamanho máximo: 30 caracteres
- Formato: Prefixo_NomeObjeto (separado por underscore)
- Palavras no singular, em português, sem acentos ou caracteres especiais
- Letras maiúsculas para todas as palavras

### **Prefixos/Sufixos:**

- Tabelas:
    - TB_ para tabelas de sistema
    - RL_ para tabelas associativas
    - TH_ para tabelas de histórico
    - TL_ para tabelas de log
    - TA_ para tabelas de auditoria
- Constraints:
    - PK_ para chave primária
    - FK_ para chave estrangeira
    - UK_ para chave única
    - CK_ para check constraints
    - DF_ para valores default
    - NN_ para NOT NULL (quando nomeada)
    - IDX_ para índices
    - CC_ para check constraints
- Outros objetos:
    - FC_ para funções
    - SP_ para stored procedures
    - VW_ para views
    - VM_ para views materializadas
    - SQ_ para sequences
    - TG_ para triggers (com prefixos A/B para after/before e I/U/D para eventos)
- Colunas:
    - ID_ para identificadores com sequence
    - CD_ para códigos
    - DT_ para datas
    - DH_ para data+hora
    - ST_ para status
    - IS_ para flags booleanas (IS_ACTIVE)
    - HAS_ para indicadores de existência
    - TP_ para tipos
    - VL_ para valores monetários
    - DS_ para descrições
    - TS_ para timestamps

# Seção 2: Regras para Criação de Objetos

## **Chaves Primárias:**

- Obrigatórias para tabelas negociais
- Preferência por tipos numéricos e de pequena extensão
- Devem ser estáveis (não mudar frequentemente)
- Documentar forma de alimentação (sequence, etc.)

## **Chaves Estrangeiras:**

- Devem referenciar todas as colunas da PK da tabela referenciada
- Colunas devem ser NOT NULL quando possível
- Para FK múltiplas, incluir nome representativo (FK_TabelaPai_TabelaFilha_Nome)

## **Índices:**

- Criar para colunas frequentemente usadas em WHERE, ORDER BY ou JOINs
- Documentar na ferramenta CASE
- Evitar em colunas com baixa seletividade ou muitos NULLs

## **Triggers:**

- Usar principalmente para auditoria, histórico e integridade
- Nomenclatura: TG_[B/A]_[I/U/D]_NomeTabela
- Triggers de log devem ser AFTER FOR EACH ROW
- Documentar finalidade no dicionário de dados

## **Views:**

- Usar para simplificar consultas complexas ou restringir acesso
- Evitar views aninhadas profundamente
- Associar adequadamente a view a um ou mais requisitos do Sistema de Informação

## **Auditoria:**

- Tabelas de auditoria devem conter todas colunas da tabela origem mais:
    - TP_OPERACAO (I/U/D)
    - DT_OPERACAO
    - NM_USUARIO_BD
    - NM_USUARIO_APLICACAO
    - NM_TERMINAL
- Apenas equipes de AD e DBA devem ter acesso de leitura

<aside>
💡

Para garantir esta auditoria, deve criar `*funções*` ou `*stored procedures*` adequadas para armazenar estas informações, substituindo clausulas SQL nativas. 

</aside>
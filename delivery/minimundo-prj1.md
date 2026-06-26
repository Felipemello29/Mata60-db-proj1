# 1. Modelando a Base de Dados

## 1.1. Contexto do Problema

O Instituto de ComputaÃ§Ã£o realiza diversas atividades de extensÃ£o universitÃ¡ria, como minicursos, workshops e eventos abertos Ã  comunidade. Atualmente, a gestÃ£o dessas atividades Ã© feita manualmente, dificultando o acompanhamento da participaÃ§Ã£o dos alunos e do impacto social das aÃ§Ãµes. Um sistema de informaÃ§Ã£o pode otimizar a organizaÃ§Ã£o, inscriÃ§Ã£o e avaliaÃ§Ã£o das atividades.

A obtenÃ§Ã£o dos requisitos foi baseada na anÃ¡lise de documentos institucionais sobre extensÃ£o universitÃ¡ria, entrevistas com organizadores e anÃ¡lise de sistemas similares. Utilizamos a tÃ©cnica de brainstorming com stakeholders para levantamento inicial e a tÃ©cnica de casos de uso para validar cenÃ¡rios de interaÃ§Ã£o.

## 1.2. Requisitos do Sistema de InformaÃ§Ã£o

Foram definidos requisitos essenciais com base no levantamento inicial, alÃ©m de novos requisitos (extensÃµes) para garantir um controle gerencial completo do escopo da extensÃ£o:

* **RF1**: Gerenciar atividades de extensÃ£o, incluindo datas, palestrantes e conteÃºdos.
* **RF2**: Permitir a inscriÃ§Ã£o e controle de presenÃ§a dos participantes , bem como controlar o histÃ³rico de participaÃ§Ã£o dos alunos.
* **RF3**: Emitir certificados automaticamente apÃ³s a conclusÃ£o das atividades.
* **RF4**: Registrar feedbacks dos participantes.
* **RF5**: Gerenciar parcerias com empresas e ONGs e disponibilizar relatÃ³rios sobre impacto e participaÃ§Ã£o.
* **RF6** *(ExtensÃ£o)*: O sistema deve permitir o controle de notas para casos de cursos de extensÃ£o ou minicursos que possuam atividades avaliativas.
* **RF7** *(ExtensÃ£o)*: O sistema deve controlar os grandes **Projetos de ExtensÃ£o** (de forma anÃ¡loga aos grupos de pesquisa), gerenciando seus membros permanentes e coordenadores, aos quais as atividades isoladas (eventos e cursos) podem estar subordinadas.

## 1.3 DelimitaÃ§Ã£o do mini-mundo para o banco de dados

O banco de dados relacional seguirÃ¡ a governanÃ§a estabelecida pela Metodologia baseada no IBAMA. Os nomes seguirÃ£o o formato de prefixo e nome do objeto separados por underscore, escritos em letras maiÃºsculas, no singular e sem acentos, respeitando o limite mÃ¡ximo de 30 caracteres para identificadores.

**Entidades Principais:**
Utilizam o prefixo `TB_` para tabelas de sistema e negociais.

* **tabela_projeto_extensao**: Concentra os grandes projetos de extensÃ£o institucionais que abrigam diversas atividades.
    * **ID_PROJETO** [int, sequence]: Identificador do projeto (PK).
    * **DS_NOME_PROJETO** [varchar 150, unique]: TÃ­tulo do projeto de extensÃ£o (NÃ£o permite duplicatas).
    * **DT_CRIACAO** [date]: Data de fundaÃ§Ã£o/aprovaÃ§Ã£o do projeto.
    * **ID_INSTR_COORDENADOR** [int]: FK designando o docente/instrutor que coordena o projeto (Restrito na exclusÃ£o).

* **TB_ATIVIDADE**: Tabela de cadastro das atividades de extensÃ£o, como eventos, minicursos e workshops.
    * **ID_ATIVIDADE** [int, sequence]: Identificador Ãºnico da atividade (PK).
    * **DS_TITULO_ATIVIDADE** [varchar 150]: DenominaÃ§Ã£o da atividade.
    * **DS_CONTEUDO_PROG** [text]: DescriÃ§Ã£o dos conteÃºdos abordados.
    * **DT_REALIZACAO** [date]: Data agendada para a atividade (Deve ser igual ou posterior Ã  data atual).
    * **ID_PROJ_VINCULADO** [int]: FK de rastreio (pode ser nulo caso a atividade seja avulsa ou se o projeto for excluÃ­do - Set Null).

* **tabela_participante**: Tabela de gerenciamento do pÃºblico atendido pelas aÃ§Ãµes.
    * **ID_PARTICIPANTE** [int, sequence]: Identificador do participante (PK).
    * **DS_NOME_PARTICIPANTE** [varchar 150]: Nome completo.
    * **DS_EMAIL_CONTATO** [citext, unique]: E-mail para comunicaÃ§Ã£o (Case-insensitive, com validaÃ§Ã£o bÃ¡sica e nÃ£o permite duplicatas).
    * **TP_VINCULO_INST** [varchar 30]: ClassificaÃ§Ã£o restrita (Aluno, Comunidade, Servidor).

* **TB_INSTRUTOR**: Concentra registros dos docentes, palestrantes ou oficineiros.
    * **ID_INSTRUTOR** [int, sequence]: Identificador do instrutor (PK).
    * **DS_NOME_INSTRUTOR** [varchar 150]: Nome completo do instrutor.
    * **DS_ESPECIALIDADE** [varchar 100]: Ãrea de atuaÃ§Ã£o.

* **TB_PARCEIRO**: Tabela que controla as empresas e ONGs parcerias da extensÃ£o.
    * **ID_PARCEIRO** [int, sequence]: Identificador da organizaÃ§Ã£o (PK).
    * **DS_NOME_ORGANIZACAO** [varchar 150, unique]: Nome da empresa ou ONG (NÃ£o permite duplicatas).
    * **TP_PARCEIRO** [varchar 30]: CategorizaÃ§Ã£o restrita (Empresa Privada, ONG, Ã“rgÃ£o PÃºblico).

* **TB_EMISSAO_CERTIFICADO**: Transacional de controle para certificados gerados automaticamente.
    * **ID_CERTIFICADO** [int, sequence]: Identificador do documento (PK).
    * **ID_INSCRICAO** [int]: FK da inscriÃ§Ã£o que originou a emissÃ£o.
    * **DT_EMISSAO** [date]: Registro temporal da emissÃ£o.
    * **CD_AUTENTICIDADE** [varchar 60]: Hash de validaÃ§Ã£o pÃºblica do certificado.

* **TB_REGISTRO_FEEDBACK**: Armazena avaliaÃ§Ãµes de qualidade preenchidas apÃ³s a atividade.
    * **ID_FEEDBACK** [int, sequence]: Identificador da avaliaÃ§Ã£o (PK).
    * **ID_INSCRICAO** [int]: FK associada ao participante.
    * **VL_NOTA_SATISFACAO** [int]: AvaliaÃ§Ã£o quantitativa (ex: 1 a 5).
    * **DS_COMENTARIO_ABERTO** [text]: Texto de feedback descritivo.

**Entidades Associativas:**
Utilizam o prefixo `RL_` para tabelas associativas.

* **RL_INSCRICAO_HISTORICO**: Resolve a relaÃ§Ã£o entre Participante e Atividade (histÃ³rico), permitindo controle de presenÃ§a e notas.
    * **ID_INSCRICAO** [int, sequence]: Identificador da inscriÃ§Ã£o (PK)
    * **ID_PARTICIPANTE** [int]: FK do aluno/membro da comunidade.
    * **ID_ATIVIDADE** [int]: FK da atividade/evento.
    * **ST_PRESENCA** [varchar 20]: Indicador de presenÃ§a confirmada ou falta.
    * **VL_NOTA_AVALIACAO** [decimal]: Campo para registro de nota em casos de cursos avaliativos.

* **RL_ALOCACAO_INSTRUTOR**: Resolve a regra de que cada atividade pode ter mÃºltiplos instrutores.
    * **ID_ATIVIDADE** [int]: FK da atividade (PK Composta).
    * **ID_INSTRUTOR** [int]: FK do instrutor (PK Composta).
    * **VL_CARGA_HORARIA** [int]: Horas de dedicaÃ§Ã£o do instrutor Ã quela atividade.

* **RL_PATROCINIO_EVENTO**: Materializa a regra de que empresas parceiras podem patrocinar eventos e oferecer suporte.
    * **ID_PARCEIRO** [int]: FK da empresa/ONG (PK Composta).
    * **ID_ATIVIDADE** [int]: FK da atividade apoiada (PK Composta).
    * **VL_APORTE** [decimal]: Valor financeiro do patrocÃ­nio, se houver.

* **RL_MEMBRO_PROJETO**: Associa participantes a Projetos de ExtensÃ£o a longo prazo.
    * **ID_PARTICIPANTE** [int]: FK do membro (PK Composta).
    * **ID_PROJETO** [int]: FK do projeto de extensÃ£o (PK Composta).
    * **TP_PAPEL_ATUACAO** [varchar 30]: ClassificaÃ§Ã£o da atuaÃ§Ã£o (Ex: Bolsista, VoluntÃ¡rio).

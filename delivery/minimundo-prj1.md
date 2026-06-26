# 1. Modelando a Base de Dados

## 1.1. Contexto do Problema

O Instituto de Computação realiza diversas atividades de extensão universitária, como minicursos, workshops e eventos abertos à comunidade. Atualmente, a gestão dessas atividades é feita manualmente, dificultando o acompanhamento da participação dos alunos e do impacto social das ações. Um sistema de informação pode otimizar a organização, inscrição e avaliação das atividades.

A obtenção dos requisitos foi baseada na análise de documentos institucionais sobre extensão universitária, entrevistas com organizadores e análise de sistemas similares. Utilizamos a técnica de brainstorming com stakeholders para levantamento inicial e a técnica de casos de uso para validar cenários de interação.

## 1.2. Requisitos do Sistema de Informação

Foram definidos requisitos essenciais com base no levantamento inicial, além de novos requisitos (extensões) para garantir um controle gerencial completo do escopo da extensão:

* **RF1**: Gerenciar atividades de extensão, incluindo datas, palestrantes e conteúdos.
* **RF2**: Permitir a inscrição e controle de presença dos participantes , bem como controlar o histórico de participação dos alunos.
* **RF3**: Emitir certificados automaticamente após a conclusão das atividades.
* **RF4**: Registrar feedbacks dos participantes.
* **RF5**: Gerenciar parcerias com empresas e ONGs e disponibilizar relatórios sobre impacto e participação.
* **RF6** *(Extensão)*: O sistema deve permitir o controle de notas para casos de cursos de extensão ou minicursos que possuam atividades avaliativas.
* **RF7** *(Extensão)*: O sistema deve controlar os grandes **Projetos de Extensão** (de forma análoga aos grupos de pesquisa), gerenciando seus membros permanentes e coordenadores, aos quais as atividades isoladas (eventos e cursos) podem estar subordinadas.

## 1.3 Delimitação do mini-mundo para o banco de dados

O banco de dados relacional seguirá a governança estabelecida pela Metodologia baseada no IBAMA. Os nomes seguirão o formato de prefixo e nome do objeto separados por underscore, escritos em letras maiúsculas, no singular e sem acentos, respeitando o limite máximo de 30 caracteres para identificadores.

**Entidades Principais:**
Utilizam o prefixo `TB_` para tabelas de sistema e negociais.

* **TB_PROJETO_EXTENSAO**: Concentra os grandes projetos de extensão institucionais que abrigam diversas atividades.
    * **ID_PROJETO** [int, sequence]: Identificador do projeto (PK).
    * **DS_NOME_PROJETO** [varchar 150, unique]: Título do projeto de extensão (Não permite duplicatas).
    * **DT_CRIACAO** [date]: Data de fundação/aprovação do projeto.
    * **ID_INSTR_COORDENADOR** [int]: FK designando o docente/instrutor que coordena o projeto (Restrito na exclusão).

* **TB_ATIVIDADE**: Tabela de cadastro das atividades de extensão, como eventos, minicursos e workshops.
    * **ID_ATIVIDADE** [int, sequence]: Identificador único da atividade (PK).
    * **DS_TITULO_ATIVIDADE** [varchar 150]: Denominação da atividade.
    * **DS_CONTEUDO_PROG** [text]: Descrição dos conteúdos abordados.
    * **DT_REALIZACAO** [date]: Data agendada para a atividade (Deve ser igual ou posterior à data atual).
    * **ID_PROJ_VINCULADO** [int]: FK de rastreio (pode ser nulo caso a atividade seja avulsa ou se o projeto for excluído - Set Null).

* **TB_PARTICIPANTE**: Tabela de gerenciamento do público atendido pelas ações.
    * **ID_PARTICIPANTE** [int, sequence]: Identificador do participante (PK).
    * **DS_NOME_PARTICIPANTE** [varchar 150]: Nome completo.
    * **DS_EMAIL_CONTATO** [citext, unique]: E-mail para comunicação (Case-insensitive, com validação básica e não permite duplicatas).
    * **TP_VINCULO_INST** [varchar 30]: Classificação restrita (Aluno, Comunidade, Servidor).

* **TB_INSTRUTOR**: Concentra registros dos docentes, palestrantes ou oficineiros.
    * **ID_INSTRUTOR** [int, sequence]: Identificador do instrutor (PK).
    * **DS_NOME_INSTRUTOR** [varchar 150]: Nome completo do instrutor.
    * **DS_ESPECIALIDADE** [varchar 100]: Área de atuação.

* **TB_PARCEIRO**: Tabela que controla as empresas e ONGs parcerias da extensão.
    * **ID_PARCEIRO** [int, sequence]: Identificador da organização (PK).
    * **DS_NOME_ORGANIZACAO** [varchar 150, unique]: Nome da empresa ou ONG (Não permite duplicatas).
    * **TP_PARCEIRO** [varchar 30]: Categorização restrita (Empresa Privada, ONG, Órgão Público).

* **TB_EMISSAO_CERTIFICADO**: Transacional de controle para certificados gerados automaticamente.
    * **ID_CERTIFICADO** [int, sequence]: Identificador do documento (PK).
    * **ID_INSCRICAO** [int]: FK da inscrição que originou a emissão.
    * **DT_EMISSAO** [date]: Registro temporal da emissão.
    * **CD_AUTENTICIDADE** [varchar 60]: Hash de validação pública do certificado.

* **TB_REGISTRO_FEEDBACK**: Armazena avaliações de qualidade preenchidas após a atividade.
    * **ID_FEEDBACK** [int, sequence]: Identificador da avaliação (PK).
    * **ID_INSCRICAO** [int]: FK associada ao participante.
    * **VL_NOTA_SATISFACAO** [int]: Avaliação quantitativa (ex: 1 a 5).
    * **DS_COMENTARIO_ABERTO** [text]: Texto de feedback descritivo.

**Entidades Associativas:**
Utilizam o prefixo `RL_` para tabelas associativas.

* **RL_INSCRICAO_HISTORICO**: Resolve a relação entre Participante e Atividade (histórico), permitindo controle de presença e notas.
    * **ID_INSCRICAO** [int, sequence]: Identificador da inscrição (PK)
    * **ID_PARTICIPANTE** [int]: FK do aluno/membro da comunidade.
    * **ID_ATIVIDADE** [int]: FK da atividade/evento.
    * **ST_PRESENCA** [varchar 20]: Indicador de presença confirmada ou falta.
    * **VL_NOTA_AVALIACAO** [decimal]: Campo para registro de nota em casos de cursos avaliativos.

* **RL_ALOCACAO_INSTRUTOR**: Resolve a regra de que cada atividade pode ter múltiplos instrutores.
    * **ID_ATIVIDADE** [int]: FK da atividade (PK Composta).
    * **ID_INSTRUTOR** [int]: FK do instrutor (PK Composta).
    * **VL_CARGA_HORARIA** [int]: Horas de dedicação do instrutor àquela atividade.

* **RL_PATROCINIO_EVENTO**: Materializa a regra de que empresas parceiras podem patrocinar eventos e oferecer suporte.
    * **ID_PARCEIRO** [int]: FK da empresa/ONG (PK Composta).
    * **ID_ATIVIDADE** [int]: FK da atividade apoiada (PK Composta).
    * **VL_APORTE** [decimal]: Valor financeiro do patrocínio, se houver.

* **RL_MEMBRO_PROJETO**: Associa participantes a Projetos de Extensão a longo prazo.
    * **ID_PARTICIPANTE** [int]: FK do membro (PK Composta).
    * **ID_PROJETO** [int]: FK do projeto de extensão (PK Composta).
    * **TP_PAPEL_ATUACAO** [varchar 30]: Classificação da atuação (Ex: Bolsista, Voluntário).

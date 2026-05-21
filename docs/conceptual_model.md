# Modelo Conceitual: Gestão de Extensão do IC

Este documento descreve o modelo conceitual do banco de dados de Gestão de Extensão do IC, seguindo a **notação de Peter Chen** conforme produzido no BrModeloWeb.

## 1. Entidades e Atributos

### 1.1 Entidades Principais (Prefixo TB_)

#### PROJETO DE EXTENSAO
Representa os grandes projetos de extensão institucionais que abrigam diversas atividades.
- **ID_PROJETO** (PK, int, sequence): Identificador do projeto
- **DS_NOME_PROJETO** (varchar 150, NOT NULL): Título do projeto
- **DT_CRIACAO** (date, NOT NULL): Data de fundação/aprovação
- **ID_INSTR_COORDENADOR** (int, FK, NOT NULL): Instrutor coordenador do projeto

#### ATIVIDADE
Cadastro das atividades de extensão (eventos, minicursos, workshops).
- **ID_ATIVIDADE** (PK, int, sequence): Identificador da atividade
- **DS_TITULO_ATIVIDADE** (varchar 150, NOT NULL): Denominação da atividade
- **DS_CONTEUDO_PROG** (text): Descrição dos conteúdos abordados
- **DT_REALIZACAO** (date, NOT NULL): Data agendada
- **ID_PROJ_VINCULADO** (int, FK, NULL): Projeto ao qual está vinculada (pode ser avulsa)

#### PARTICIPANTE
Público atendido pelas ações de extensão.
- **ID_PARTICIPANTE** (PK, int, sequence): Identificador do participante
- **DS_NOME_PARTICIPANTE** (varchar 150, NOT NULL): Nome completo
- **DS_EMAIL_CONTATO** (varchar 100, NOT NULL): E-mail para comunicação
- **TP_VINCULO_INST** (varchar 30, NOT NULL): Classificação (Aluno, Comunidade, Servidor)

#### INSTRUTOR
Docentes, palestrantes ou oficineiros responsáveis pelas atividades.
- **ID_INSTRUTOR** (PK, int, sequence): Identificador do instrutor
- **DS_NOME_INSTRUTOR** (varchar 150, NOT NULL): Nome completo
- **DS_ESPECIALIDADE** (varchar 100): Área de atuação

#### PARCEIRO
Empresas e ONGs parceiras da extensão.
- **ID_PARCEIRO** (PK, int, sequence): Identificador da organização
- **DS_NOME_ORGANIZACAO** (varchar 150, NOT NULL): Nome da empresa ou ONG
- **TP_PARCEIRO** (varchar 30, NOT NULL): Categorização (Empresa Privada, ONG, Órgão Público)

#### EMISSAO DE CERTIFICADO
Controle transacional de certificados gerados automaticamente.
- **ID_CERTIFICADO** (PK, int, sequence): Identificador do documento
- **ID_INSCRICAO** (FK, int, NOT NULL, UNIQUE): Inscrição que originou a emissão
- **DT_EMISSAO** (date, NOT NULL): Data da emissão
- **CD_AUTENTICIDADE** (varchar 60, NOT NULL, UNIQUE): Hash de validação pública

#### REGISTRO DE FEEDBACK
Avaliações de qualidade preenchidas após a atividade.
- **ID_FEEDBACK** (PK, int, sequence): Identificador da avaliação
- **ID_INSCRICAO** (FK, int, NOT NULL, UNIQUE): Inscrição associada
- **VL_NOTA_SATISFACAO** (int, NOT NULL, CHECK 1-5): Avaliação quantitativa
- **DS_COMENTARIO_ABERTO** (text): Texto descritivo de feedback

---

## 2. Relacionamentos

### 2.1 coordena (INSTRUTOR → PROJETO DE EXTENSAO)
- **Cardinalidade**: (0,n) para INSTRUTOR × (1,1) para PROJETO DE EXTENSAO
- **Significado**: Um instrutor pode coordenar zero ou muitos projetos. Todo projeto deve ter exatamente um coordenador.
- **Tradução**: FK `ID_INSTR_COORDENADOR` em TB_PROJETO_EXTENSAO referenciando TB_INSTRUTOR(ID_INSTRUTOR).

### 2.2 pertence (ATIVIDADE → PROJETO DE EXTENSAO)
- **Cardinalidade**: (0,1) para ATIVIDADE × (0,n) para PROJETO DE EXTENSAO
- **Significado**: Uma atividade pode pertencer a zero ou um projeto (atividades avulsas são permitidas). Um projeto pode ter zero ou muitas atividades.
- **Tradução**: FK `ID_PROJ_VINCULADO` (nullable) em TB_ATIVIDADE referenciando TB_PROJETO_EXTENSAO(ID_PROJETO).

### 2.3 HISTORICO DE INSCRICAO (ATIVIDADE ↔ PARTICIPANTE)
- **Tipo**: Relacionamento com atributos próprios (entidade associativa)
- **Cardinalidade**: (0,n) para PARTICIPANTE × (0,n) para ATIVIDADE
- **Atributos do relacionamento**:
  - **ID_INSCRICAO** (PK, int, sequence): Identificador da inscrição
  - **ST_PRESENCA** (varchar 20, NOT NULL, CHECK: PRESENTE/AUSENTE): Indicador de presença
  - **VL_NOTA_AVALIACAO** (decimal 4,2, NULL, CHECK: 0-10): Nota em cursos avaliativos
- **Significado**: Registra o histórico de inscrição de participantes em atividades, controlando presença e notas.
- **Tradução**: Tabela RL_INSCRICAO_HISTORICO com PK própria (ID_INSCRICAO) e FKs para TB_PARTICIPANTE e TB_ATIVIDADE.

### 2.4 aloca (INSTRUTOR ↔ ATIVIDADE)
- **Cardinalidade**: (0,n) para INSTRUTOR × (1,n) para ATIVIDADE
- **Atributos do relacionamento**:
  - **VL_CARGA_HORARIA** (int, NOT NULL): Horas de dedicação
- **Significado**: Cada atividade pode ter múltiplos instrutores, cada um com carga horária definida.
- **Tradução**: Tabela RL_ALOCACAO_INSTRUTOR com PK composta (ID_ATIVIDADE, ID_INSTRUTOR).

### 2.5 patrocina (PARCEIRO ↔ ATIVIDADE)
- **Cardinalidade**: (1,n) para PARCEIRO × (0,n) para ATIVIDADE
- **Atributos do relacionamento**:
  - **VL_APORTE** (decimal 12,2): Valor financeiro do patrocínio
- **Significado**: Parceiros podem patrocinar eventos e oferecer suporte financeiro.
- **Tradução**: Tabela RL_PATROCINIO_EVENTO com PK composta (ID_PARCEIRO, ID_ATIVIDADE).

### 2.6 participa (PARTICIPANTE ↔ PROJETO DE EXTENSAO)
- **Cardinalidade**: (0,n) para PARTICIPANTE × (0,n) para PROJETO DE EXTENSAO
- **Atributos do relacionamento**:
  - **TP_PAPEL_ATUACAO** (varchar 30, NOT NULL): Classificação (Bolsista, Voluntário)
- **Significado**: Associa participantes como membros permanentes de projetos de extensão.
- **Tradução**: Tabela RL_MEMBRO_PROJETO com PK composta (ID_PARTICIPANTE, ID_PROJETO).

### 2.7 gera (HISTORICO DE INSCRICAO → EMISSAO DE CERTIFICADO)
- **Cardinalidade**: (0,1) para HISTORICO DE INSCRICAO × (1,1) para EMISSAO DE CERTIFICADO
- **Significado**: Uma inscrição pode gerar no máximo um certificado. Todo certificado é gerado a partir de uma inscrição.
- **Tradução**: FK `ID_INSCRICAO` (UNIQUE) em TB_EMISSAO_CERTIFICADO referenciando RL_INSCRICAO_HISTORICO.

### 2.8 avalia (HISTORICO DE INSCRICAO → REGISTRO DE FEEDBACK)
- **Cardinalidade**: (0,1) para HISTORICO DE INSCRICAO × (1,1) para REGISTRO DE FEEDBACK
- **Significado**: Uma inscrição pode gerar no máximo um feedback. Todo feedback está associado a uma inscrição.
- **Tradução**: FK `ID_INSCRICAO` (UNIQUE) em TB_REGISTRO_FEEDBACK referenciando RL_INSCRICAO_HISTORICO.

---

## 3. Diagrama ER (BrModeloWeb)

O diagrama conceitual foi elaborado usando o BrModeloWeb (https://app.brmodeloweb.com), adotando plenamente a notação de Peter Chen:
- **Retângulos**: Entidades
- **Losangos**: Relacionamentos
- **Elipses**: Atributos (com círculo preenchido para PKs)
- **Linhas com cardinalidade**: Conexões entre entidades e relacionamentos

*Referência do diagrama: `Conceptual model - BRMW.pdf`*

---

## 4. Estratégia de Tradução (MER → Modelo Relacional)

### 4.1 Entidades Regulares
Cada entidade do MER se torna uma tabela no modelo relacional. Atributos simples viram colunas. O identificador (PK) do MER se torna a chave primária da tabela, implementada com SERIAL para geração automática.

### 4.2 Relacionamentos 1:N
O lado "1" tem sua PK referenciada como FK no lado "N". Exemplos:
- **coordena (1:N)**: `ID_INSTR_COORDENADOR` em TB_PROJETO_EXTENSAO referencia TB_INSTRUTOR
- **pertence (0,1:0,N)**: `ID_PROJ_VINCULADO` em TB_ATIVIDADE referencia TB_PROJETO_EXTENSAO (nullable para atividades avulsas)

### 4.3 Relacionamentos N:N
Cada relacionamento N:N gera uma tabela associativa (prefixo `RL_`). A PK é composta pelas FKs das duas entidades participantes. Atributos do relacionamento se tornam colunas adicionais.
- **HISTORICO DE INSCRICAO**: Gerou RL_INSCRICAO_HISTORICO com PK própria (por ter cardinalidade alta e relacionamentos dependentes)
- **aloca**: Gerou RL_ALOCACAO_INSTRUTOR com PK composta
- **patrocina**: Gerou RL_PATROCINIO_EVENTO com PK composta
- **participa**: Gerou RL_MEMBRO_PROJETO com PK composta

### 4.4 Relacionamentos 1:1
Para gera e avalia, a FK com constraint UNIQUE é colocada na entidade de dependência total:
- **gera**: `ID_INSCRICAO` (UNIQUE) em TB_EMISSAO_CERTIFICADO
- **avalia**: `ID_INSCRICAO` (UNIQUE) em TB_REGISTRO_FEEDBACK

### 4.5 Nomenclatura (Governança MAD)
Seguindo a Metodologia de Administração de Dados (MAD/IBAMA):
- Prefixo `TB_` para tabelas de entidades
- Prefixo `RL_` para tabelas associativas
- Prefixos de atributos: `ID_` (identificadores), `DS_` (descritivos), `DT_` (datas), `TP_` (tipos), `VL_` (valores), `ST_` (status), `CD_` (códigos)
- Nomes em MAIÚSCULAS, sem acentos, separados por underscore

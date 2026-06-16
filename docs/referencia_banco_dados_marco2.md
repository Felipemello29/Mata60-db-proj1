# Documento de Referência: Banco de Dados MATA60 (Marco 2)

Este documento serve como referência rápida para todas as tabelas e pesquisas (queries) construídas no banco de dados de gerenciamento de extensão acadêmica. Abaixo, detalhamos cada estrutura e justificamos como ela foi elaborada.

---

## 1. Tabelas do Banco de Dados

### Tabelas Base (Entidades Principais)

**1. `TB_INSTRUTOR`**
*   **Descrição:** Armazena os dados dos instrutores que ministram as atividades e coordenam os projetos.
*   **Justificativa/Parâmetros:** Criada com uma chave primária autoincremental (`ID_INSTRUTOR`), o nome do instrutor e sua especialidade (`DS_ESPECIALIDADE`). Estes parâmetros foram escolhidos para identificar facilmente o instrutor e seu domínio de conhecimento, o que facilita na alocação adequada para as atividades.

**2. `TB_PROJETO_EXTENSAO`**
*   **Descrição:** Guarda as informações dos projetos de extensão.
*   **Justificativa/Parâmetros:** Possui chave estrangeira apontando para `TB_INSTRUTOR` indicando o coordenador. A data de criação (`DT_CRIACAO`) tem um valor padrão `CURRENT_DATE`, garantindo que não falte a data em que o projeto foi submetido.

**3. `TB_ATIVIDADE`**
*   **Descrição:** Armazena as atividades específicas vinculadas a cada projeto.
*   **Justificativa/Parâmetros:** Dependente de um projeto (`ID_PROJ_VINCULADO`), possui título, conteúdo programático e data de realização. A separação entre projeto e atividade garante flexibilidade para que um projeto possua múltiplos eventos distintos.

**4. `TB_PARTICIPANTE`**
*   **Descrição:** Cadastro das pessoas que participam ou integram os projetos/atividades.
*   **Justificativa/Parâmetros:** Inclui nome, e-mail e um tipo de vínculo (`TP_VINCULO_INST` ex: 'ALUNO'). A coluna de e-mail possui restrição `UNIQUE` atuando como chave natural para impedir cadastros duplicados.

**5. `TB_PARCEIRO`**
*   **Descrição:** Organizações externas parceiras ou patrocinadoras.
*   **Justificativa/Parâmetros:** Montada com um nome e tipo de parceiro (`TP_PARCEIRO`), sendo estruturalmente separada para permitir o vínculo de múltiplos patrocínios a uma ou mais atividades.

### Tabelas Associativas e de Relacionamento

**6. `RL_INSCRICAO_HISTORICO`**
*   **Descrição:** Registra a inscrição e o histórico de presença/nota do participante em uma atividade.
*   **Justificativa/Parâmetros:** Une `TB_PARTICIPANTE` a `TB_ATIVIDADE`. Possui restrições (`CHECK`) importantes: presença só pode ser 'PRESENTE' ou 'AUSENTE', e a nota (`VL_NOTA_AVALIACAO`) deve estar entre 0 e 10. Conta também com a chave única `uk_inscricao_unica` (ID_PARTICIPANTE e ID_ATIVIDADE) para blindar o banco contra duplicação de matrículas para um mesmo evento.

**7. `TB_EMISSAO_CERTIFICADO`**
*   **Descrição:** Registra os certificados emitidos.
*   **Justificativa/Parâmetros:** Possui chave única (`UNIQUE`) no código de autenticidade e na inscrição, garantindo que uma inscrição não receba mais de um certificado. A data tem valor padrão automático.

**8. `TB_REGISTRO_FEEDBACK`**
*   **Descrição:** Guarda as avaliações dadas pelos participantes às atividades.
*   **Justificativa/Parâmetros:** Restringe o valor da satisfação (`VL_NOTA_SATISFACAO`) entre 1 e 5 via constraint `CHECK`. Garante também que cada inscrição submeta, no máximo, um único feedback (`UNIQUE`).

**9. `RL_ALOCACAO_INSTRUTOR`**
*   **Descrição:** Relaciona as atividades com os instrutores alocados para dar a aula/evento.
*   **Justificativa/Parâmetros:** Utiliza chave primária composta (ID_ATIVIDADE e ID_INSTRUTOR) para evitar duplicidade na alocação, e também registra a carga horária empenhada pelo instrutor na atividade (com validação `CHECK` para garantir > 0).

**10. `RL_PATROCINIO_EVENTO`**
*   **Descrição:** Relaciona parceiros e atividades com o montante de patrocínio.
*   **Justificativa/Parâmetros:** Chave primária composta. Adiciona a coluna financeira `VL_APORTE` permitindo rastrear o investimento exato recebido por cada evento (com validação `CHECK` de valor > 0).

**11. `RL_MEMBRO_PROJETO`**
*   **Descrição:** Aloca os participantes não apenas a atividades, mas ao time do projeto.
*   **Justificativa/Parâmetros:** Chave primária composta. Define o papel do participante (`TP_PAPEL_ATUACAO`), permitindo ter bolsistas, voluntários, etc.

---

## 2. Pesquisas (Queries) Intermediárias

**1. Contagem de Inscrições por Participante no Projeto 1**
*   **Justificativa/Montagem:** Utiliza `JOIN` entre 4 tabelas para cruzar o participante até o projeto e, por fim, conta com `GROUP BY`.
*   **Tabelas Consultadas:** `TB_PARTICIPANTE`, `RL_INSCRICAO_HISTORICO`, `TB_ATIVIDADE`, `TB_PROJETO_EXTENSAO`

**2. Quantidade de Atividades por Projeto (com o Coordenador)**
*   **Justificativa/Montagem:** Usa `LEFT JOIN` para não ignorar os projetos que ainda não têm atividades criadas, fornecendo um dado estatístico realista do andamento dos projetos.
*   **Tabelas Consultadas:** `TB_PROJETO_EXTENSAO`, `TB_ATIVIDADE`, `TB_INSTRUTOR`

**3. Instrutores e a Carga Horária Total em Atividades**
*   **Justificativa/Montagem:** Cruza as tabelas de instrutor e alocação, utilizando as funções de agregação `SUM` e `COUNT` em conjunto com o `GROUP BY`.
*   **Tabelas Consultadas:** `TB_INSTRUTOR`, `RL_ALOCACAO_INSTRUTOR`, `TB_ATIVIDADE`

**4. Parceiros, Contribuições Totais e Atividades Patrocinadas**
*   **Justificativa/Montagem:** Agrupa os dados dos parceiros somando o `VL_APORTE` e contando os ID's únicos de atividades associadas.
*   **Tabelas Consultadas:** `TB_PARCEIRO`, `RL_PATROCINIO_EVENTO`, `TB_ATIVIDADE`

**5. Participantes com Duas ou Mais Presenças**
*   **Justificativa/Montagem:** Utiliza o filtro condicional `WHERE` para 'PRESENTE', agrupando os participantes e, usando a cláusula `HAVING`, exibe apenas quem esteve em no mínimo 2 atividades. Extrai os nomes das atividades cursadas numa única linha por meio do `STRING_AGG()`.
*   **Tabelas Consultadas:** `TB_PARTICIPANTE`, `RL_INSCRICAO_HISTORICO`, `TB_ATIVIDADE`

**6. Média de Notas por Atividade**
*   **Justificativa/Montagem:** Faz o `AVG()` da avaliação na tabela de histórico, mas possui o `HAVING COUNT > 5` visando exibir métricas apenas onde a amostragem for mais confiável.
*   **Tabelas Consultadas:** `TB_ATIVIDADE`, `RL_INSCRICAO_HISTORICO`, `TB_PROJETO_EXTENSAO`

**7. Quantidade de Atividades Coordenadas por Instrutor**
*   **Justificativa/Montagem:** Faz o rastreio da coordenação (atividades -> projetos -> instrutores) com um simples `COUNT`.
*   **Tabelas Consultadas:** `TB_ATIVIDADE`, `TB_PROJETO_EXTENSAO`, `TB_INSTRUTOR`

**8. Contagem de Certificados por Atividade**
*   **Justificativa/Montagem:** Cruza os dados conectando as Atividades -> Inscrição -> Certificado, agrupando pelo nome da atividade.
*   **Tabelas Consultadas:** `TB_ATIVIDADE`, `RL_INSCRICAO_HISTORICO`, `TB_EMISSAO_CERTIFICADO`

**9. Contagem de Feedbacks e Média de Satisfação**
*   **Justificativa/Montagem:** Busca e agrupa métricas de qualidade via função `AVG()` do `VL_NOTA_SATISFACAO` associada aos participantes.
*   **Tabelas Consultadas:** `TB_PARTICIPANTE`, `RL_INSCRICAO_HISTORICO`, `TB_REGISTRO_FEEDBACK`

**10. Projetos e a Quantidade de Membros do Time**
*   **Justificativa/Montagem:** Relaciona as associações dos participantes e os contabiliza atrelados a cada projeto. Lista explicitamente os nomes dos envolvidos através do agrupamento semântico gerado por `STRING_AGG()`.
*   **Tabelas Consultadas:** `TB_PROJETO_EXTENSAO`, `RL_MEMBRO_PROJETO`, `TB_PARTICIPANTE`

---

## 3. Pesquisas (Queries) Avançadas

**1. Ranking de Participantes pela Nota Média**
*   **Justificativa/Montagem:** Emprega Subqueries e a Window function analítica `RANK() OVER (ORDER BY media_global DESC)`, distribuindo de forma justa o posicionamento dos participantes pelo seu empenho global.
*   **Tabelas Consultadas:** `TB_PARTICIPANTE`, `RL_INSCRICAO_HISTORICO`, `TB_ATIVIDADE`

**2. Top 3 Projetos em Emissão de Certificados**
*   **Justificativa/Montagem:** Uma Subquery empacota os valores agregados que, externamente, recebem ordenação e são limitados ao top três com a cláusula `LIMIT 3`.
*   **Tabelas Consultadas:** `TB_PROJETO_EXTENSAO`, `TB_ATIVIDADE`, `RL_INSCRICAO_HISTORICO`, `TB_EMISSAO_CERTIFICADO`

**3. Atividades com Engajamento Acima da Média**
*   **Justificativa/Montagem:** Utiliza uma *Common Table Expression (CTE)* iniciada com `WITH` para primeiro isolar as médias de inscritos e, logo em seguida, usá-las como referência para filtragem.
*   **Tabelas Consultadas:** `TB_ATIVIDADE`, `RL_INSCRICAO_HISTORICO`, `TB_PROJETO_EXTENSAO`

**4. Instrutores que apenas Ministram Aulas (Não Coordenam)**
*   **Justificativa/Montagem:** Para isolar com precisão os professores, utilizou a técnica com a cláusula `NOT EXISTS` atrelada a Subquery garantindo que o instrutor não conste no rol dos coordenadores de projeto.
*   **Tabelas Consultadas:** `TB_INSTRUTOR`, `RL_ALOCACAO_INSTRUTOR`, `TB_ATIVIDADE`, `TB_PROJETO_EXTENSAO`

**5. Soma Acumulada Mensal de Patrocínios por Parceiro**
*   **Justificativa/Montagem:** Aplica Window function `SUM(...) OVER(PARTITION BY...)` que calcula um "Running Total" ou saldo acumulado de aportes linha a linha, sem colapsar as linhas.
*   **Tabelas Consultadas:** `TB_PARCEIRO`, `RL_PATROCINIO_EVENTO`, `TB_ATIVIDADE`

**6. Desempenho do Participante Versus Nota Máxima da Atividade**
*   **Justificativa/Montagem:** Usa a Window Function `MAX() OVER` calculando a relação de porcentagem, com um filtro Subquery garantindo análise restrita apenas onde haja engajamento expressivo (>5 alunos).
*   **Tabelas Consultadas:** `TB_PARTICIPANTE`, `RL_INSCRICAO_HISTORICO`, `TB_ATIVIDADE`

**7. Projetos com Atuação Acumulada do Coordenador (Coordenador = Instrutor)**
*   **Justificativa/Montagem:** Utiliza uma sub-query no SELECT para contabilizar corretamente o total de atividades do projeto pai, e utiliza EXISTS para certificar que o coordenador de fato ministra aulas nele. Tudo associado a uma Subquery de restrição de volume (>5 atividades no projeto).
*   **Tabelas Consultadas:** `TB_PROJETO_EXTENSAO`, `TB_ATIVIDADE`, `RL_ALOCACAO_INSTRUTOR`

**8. Projetos com Alta Concentração de 'Alunos'**
*   **Justificativa/Montagem:** Usa uma Subquery para recuperar uma média restrita para alunos (`TP_VINCULO_INST = 'ALUNO'`) aplicando o comparador dinâmico no `HAVING`.
*   **Tabelas Consultadas:** `TB_PROJETO_EXTENSAO`, `RL_MEMBRO_PROJETO`, `TB_PARTICIPANTE`

**9. Atividades Plurais (Múltiplos Instrutores e Patrocinadas)**
*   **Justificativa/Montagem:** Uso inteligente de operadores de conjunto: a subquery em `IN` atende a restrição de instrutores múltiplos e as subqueries em `EXISTS` validam o patrocínio atrelado.
*   **Tabelas Consultadas:** `TB_ATIVIDADE`, `RL_ALOCACAO_INSTRUTOR`, `RL_PATROCINIO_EVENTO`

**10. Crescimento Verdadeiro Mensal (Month-over-month)**
*   **Justificativa/Montagem:** Agrupamentos complexos de tempo combinados com a Window Function de defasagem (`LAG`). Isso permite subtrair dinamicamente o volume de projetos no mês corrente em relação ao anterior, encontrando de forma autônoma a variação mês a mês diretamente em SQL.
*   **Tabelas Consultadas:** `TB_PROJETO_EXTENSAO`, `TB_ATIVIDADE`, `RL_INSCRICAO_HISTORICO`

**11. Atividade com Extrema Excelência de Satisfação**
*   **Justificativa/Montagem:** Usa de forma limpa uma agregação e limita os dados para a primeira linha da resposta com a cláusula `LIMIT 1`.
*   **Tabelas Consultadas:** `TB_ATIVIDADE`, `RL_INSCRICAO_HISTORICO`, `TB_REGISTRO_FEEDBACK`

**12. Participantes Assíduos: 100% de Aproveitamento de Certificados**
*   **Justificativa/Montagem:** Uma pesquisa elaborada utilizando `NOT EXISTS` associado a um `LEFT JOIN` com seleção no condicional `IS NULL`, provando a ausência de qualquer atividade na qual não possua certificado emitido.
*   **Tabelas Consultadas:** `TB_PARTICIPANTE`, `RL_INSCRICAO_HISTORICO`, `TB_EMISSAO_CERTIFICADO`

**13. Engajamento Nível Especialista: "Super-participantes"**
*   **Justificativa/Montagem:** Uma busca simples onde, em via de se repetir agregações, aplica uma Subquery no filtro `IN` isolando somente alunos com mais de 5 inscrições.
*   **Tabelas Consultadas:** `TB_PARTICIPANTE`, `RL_INSCRICAO_HISTORICO`, `TB_ATIVIDADE`

**14. Projetos Acima da Sobrecarga de Horas Média Global**
*   **Justificativa/Montagem:** Retira e armazena a média de horas de todo o cenário de alocações (em subquery) para então usá-la no `HAVING` do grupo principal dos projetos.
*   **Tabelas Consultadas:** `TB_PROJETO_EXTENSAO`, `TB_ATIVIDADE`, `RL_ALOCACAO_INSTRUTOR`

**15. Mapeamento da Data de Estreia do Participante**
*   **Justificativa/Montagem:** Usufrui de maneira criativa da Window Function `FIRST_VALUE() OVER`, retornando o primeiro registro temporal da primeira atividade inscrita.
*   **Tabelas Consultadas:** `TB_PARTICIPANTE`, `RL_INSCRICAO_HISTORICO`, `TB_ATIVIDADE`

**16. Distribuição das Especialidades com Maiores Ofertas (≥2 Atividades)**
*   **Justificativa/Montagem:** Usa o aninhamento onde uma Subquery extrai para um comparador `IN` apenas quais especialidades superam a barreira mínima exigida (`>= 2`). Adicionalmente, possui ordenação descendente em banco (`ORDER BY ... DESC`).
*   **Tabelas Consultadas:** `TB_INSTRUTOR`, `RL_ALOCACAO_INSTRUTOR`, `TB_ATIVIDADE`

**17. O Pior Feedback em Atividades Superlotadas (>20 pessoas)**
*   **Justificativa/Montagem:** Identifica o registro de extremidade de insatisfação num evento que teve expressividade. O filtro se dá em um cruzamento de subqueries combinado à uma reordenação ascendente (`ORDER BY ... ASC`).
*   **Tabelas Consultadas:** `TB_PARTICIPANTE`, `RL_INSCRICAO_HISTORICO`, `TB_REGISTRO_FEEDBACK`, `TB_ATIVIDADE`

**18. Relatório da Tração de Recência: Engajamento > Média Geral**
*   **Justificativa/Montagem:** Associa uma CTE base que extrai e restringe o intervalo (`INTERVAL '6 months'`), aplicando na consulta superior a verificação contra a Subquery de média histórica total do sistema.
*   **Tabelas Consultadas:** `TB_ATIVIDADE`, `RL_INSCRICAO_HISTORICO`, `TB_PARTICIPANTE`

**19. Patrocinadores Corporativos com Diversificação (Múltiplos Projetos)**
*   **Justificativa/Montagem:** Filtra através da cláusula `HAVING` com um modificador `COUNT(DISTINCT ...) > 1` visando selecionar quem atira o investimento em variadas frentes, não focando num único projeto local. Emprega Subquery na cláusula SELECT.
*   **Tabelas Consultadas:** `TB_PARCEIRO`, `RL_PATROCINIO_EVENTO`, `TB_ATIVIDADE`

**20. Desvio do Desempenho Pessoal perante o Padrão da Turma**
*   **Justificativa/Montagem:** Avaliação avançada subtraindo o resultado da linha analítica (Window Function `AVG() OVER`) do valor atual, apontando com a diferença negativa ou positiva de rendimento para cursos representativos.
*   **Tabelas Consultadas:** `TB_PARTICIPANTE`, `RL_INSCRICAO_HISTORICO`, `TB_ATIVIDADE`

---

## 4. Métodos SQL Utilizados e Suas Escolhas

Nesta seção, detalhamos os principais comandos e cláusulas SQL empregados na construção das pesquisas e a justificativa técnica de por que foram escolhidos.

### 4.1. JOINs (INNER, LEFT)
*   **O que é:** Combina registros de duas ou mais tabelas baseados em uma condição de relacionamento (normalmente chaves primárias e estrangeiras).
*   **Por que foi utilizado:** Como o banco de dados é relacional e normalizado (os dados estão espalhados em múltiplas tabelas, como `TB_PARTICIPANTE` e `TB_ATIVIDADE`), os `JOIN`s são essenciais para "juntar as peças". O `LEFT JOIN`, especificamente, foi usado quando precisávamos trazer registros da tabela da esquerda mesmo que eles ainda não tivessem correspondência na tabela da direita (exemplo: listar todos os projetos, mesmo os que ainda não possuem atividades).
*   **Onde foi utilizado:** `INNER JOIN` é a base da grande maioria das consultas para relacionar as tabelas (Intermediárias 1 a 10, Avançadas 1 a 20). O `LEFT JOIN` foi utilizado com destaque na **Intermediária 2** e na **Avançada 12**.

### 4.2. Agrupamentos (GROUP BY e Funções Agregadoras como SUM, COUNT, AVG)
*   **O que é:** Agrupa linhas que têm os mesmos valores em linhas de resumo, aplicando funções matemáticas nos grupos.
*   **Por que foi utilizado:** Necessário para gerar relatórios e métricas de sistema (RF1 a RF7). Por exemplo, usamos `COUNT` para saber a quantidade de inscritos, `AVG` para a média de avaliações, e `SUM` para somar os valores de patrocínios.
*   **Onde foi utilizado:** O `GROUP BY` e `COUNT` estão em quase todas (Intermediárias 1 a 10 e Avançadas 2, 3, 4, 7, 8, etc.). A função `SUM` aparece nas **Intermediárias 3 e 4**. A função `AVG` consta nas **Intermediárias 6 e 9** e **Avançadas 1, 11 e 14**.

### 4.3. HAVING
*   **O que é:** Funciona de forma similar ao `WHERE`, mas é aplicado após o `GROUP BY` e permite filtrar resultados de funções agregadoras.
*   **Por que foi utilizado:** Utilizado sempre que precisamos filtrar dados baseados em métricas somadas ou contadas. Por exemplo, "Atividades com *mais de 5* inscrições" (`HAVING COUNT(id) > 5`). O `WHERE` não consegue filtrar funções de agregação, por isso a escolha obrigatória do `HAVING` nestes cenários.
*   **Onde foi utilizado:** Presente nas consultas **Intermediárias 5 e 6**, e de forma frequente nas **Avançadas 6, 7, 8, 9, 13, 14, 16, 17, 18 e 19**.

### 4.4. Subqueries e CTEs (WITH)
*   **O que é:** Uma Subquery é uma consulta aninhada dentro de outra consulta. A CTE (Common Table Expression) via `WITH` é uma subquery nomeada e temporária que pode ser referenciada na query principal.
*   **Por que foi utilizado:** Escolhidos para resolver problemas de múltiplas etapas, como "achar a média de todas as atividades" antes de "comparar a atividade atual com essa média global". A CTE em particular deixa o código muito mais legível quando a subquery precisa ser complexa ou repetida.
*   **Onde foi utilizado:** A estruturação em CTE (`WITH`) brilhou nas queries **Avançadas 3 e 18**. As Subqueries tracionais alimentam quase todo o bloco complexo, visíveis nas **Avançadas 1, 2, 4, 6, 7, 8, 9, 11 a 20**.

### 4.5. EXISTS e NOT EXISTS
*   **O que é:** Testa se uma subquery retorna alguma linha.
*   **Por que foi utilizado:** Utilizados para verificar rapidamente a presença (ou ausência) de uma condição sem se preocupar com os dados exatos (ótimo para desempenho). O `NOT EXISTS` foi o método escolhido para responder lógicas exclusivas, como encontrar "participantes que possuem certificado para todas as atividades" (ou seja, não existe atividade na qual o participante não tenha certificado) ou "instrutores que nunca coordenaram".
*   **Onde foi utilizado:** O operador `NOT EXISTS` foi a solução chave para as queries **Avançadas 4 e 12**. Já o `EXISTS` direto figura na lógica da **Avançada 9**.

### 4.6. IN e NOT IN
*   **O que é:** Permite especificar múltiplos valores em uma cláusula `WHERE` (ou utilizar o resultado de uma subquery como lista de valores).
*   **Por que foi utilizado:** Diferente do `EXISTS`, usamos `IN` quando precisávamos de fato da lista de IDs gerada por uma subquery (exemplo: `WHERE ID_PARTICIPANTE IN (lista de participantes com mais de 5 faltas)`).
*   **Onde foi utilizado:** O filtro `IN` conectando a consulta principal aos dados da subquery estruturou as queries **Avançadas 6, 7, 9, 13 e 16**.

### 4.7. Window Functions (OVER, RANK, SUM OVER, AVG OVER, FIRST_VALUE, LAG)
*   **O que é:** Executa um cálculo em um conjunto de linhas de tabela relacionadas à linha atual, mas diferentemente do `GROUP BY`, não colapsa/achata as linhas em um único resultado.
*   **Por que foi utilizado e Onde aparecem:** Essenciais para as **Pesquisas Avançadas** deste projeto. Eles foram selecionados para criar cálculos analíticos e evitar o peso de "Auto-Joins" engessados:
    *   **`RANK() OVER(...)`**: Gera o ranking ordenado dos alunos (Utilizado na **Avançada 1**).
    *   **`SUM(...) OVER(...)`**: Calcula o crescimento acumulado (saldo contínuo/running total) ao longo do tempo ou sequência (Utilizado na **Avançada 5**).
    *   **`MAX(...) OVER(...)`**: Extrai a nota ou métrica máxima do agrupamento para criar comparações (Utilizado na **Avançada 6**).
    *   **`FIRST_VALUE(...) OVER(...)`**: Identifica eficientemente o primeiro registro ordenado de cada participante (Utilizado na **Avançada 15**).
    *   **`AVG(...) OVER(...)`**: Expõe a média contínua de um agrupamento diretamente na linha, auxiliando cálculos de desvio e variações (Utilizado na **Avançada 20**).
    *   **`LAG(...) OVER(...)`**: Permite o acesso a dados da linha "anterior" dentro da janela atual, sendo essencial para cálculos relativos de variação (MoM - Month over Month), provendo diferenças de crescimento (Utilizado na **Avançada 10**).

### 4.8. Funções de Manipulação de Texto (STRING_AGG)
*   **O que é:** Concatena os valores de várias linhas em uma única string, separada pelo delimitador especificado.
*   **Por que foi utilizado:** Nos agrupamentos (`GROUP BY`), dados de texto individuais são frequentemente perdidos ou geram erros se não estiverem na cláusula do grupo. O `STRING_AGG` reverte isso, embalando esses textos secundários dentro da agregação primária, evitando delegar manipulações trabalhosas para a interface do frontend.
*   **Onde foi utilizado:** Essencial para reter a legibilidade textual nas agregações das consultas **Intermediárias 5 e 10**.

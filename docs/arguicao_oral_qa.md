# Preparação para Arguição Oral - MATA60 (Marco 1)
## Sistema de Gestão de Extensão do IC

Este documento reúne possíveis questionamentos que os avaliadores podem fazer durante a arguição oral do seu projeto, baseados nas decisões arquiteturais, requisitos, barema e relatórios técnicos entregues.

---

### 1. Modelagem, Regras de Negócio e Normalização

**Q1: Por que vocês optaram por incluir as extensões RF6 (Notas) e RF7 (Projetos Estruturantes) além dos requisitos originais?**
**Resposta Esperada:** Adicionamos o RF6 porque muitos minicursos possuem atividades avaliativas, e sem o registro de notas (`VL_NOTA_AVALIACAO`), o sistema ficaria incompleto para a realidade acadêmica. Já o RF7 foi adicionado para refletir a hierarquia real da extensão: atividades isoladas (eventos/cursos) geralmente não existem no vácuo, elas pertencem a projetos de extensão maiores (grupos ou laboratórios), o que exigiu a entidade `TB_PROJETO_EXTENSAO` para organizar coordenação e membros.

**Q2: Como vocês modelaram o relacionamento entre um Aluno (Participante) e uma Atividade?**
**Resposta Esperada:** Utilizamos um relacionamento N:N, pois um participante pode ir a várias atividades e uma atividade possui vários participantes. No modelo lógico, isso foi traduzido para a tabela associativa `RL_INSCRICAO_HISTORICO`, onde a chave primária é composta pelas FKs de Participante e Atividade. Além disso, essa tabela guarda os atributos do relacionamento, como Presença e Nota.

**Q3: Como vocês garantiram no modelo relacional que uma inscrição vai gerar apenas um Certificado e apenas um Feedback (Relacionamento 1:1)?**
**Resposta Esperada:** No modelo lógico, relacionamentos 1:1 de dependência total foram resolvidos colocando a Chave Estrangeira (FK) na tabela dependente (`TB_EMISSAO_CERTIFICADO` e `TB_REGISTRO_FEEDBACK`) referenciando a `RL_INSCRICAO_HISTORICO`, e aplicamos a restrição `UNIQUE` nessas FKs. Isso impede que mais de um certificado ou feedback seja inserido para a mesma inscrição.

**Q4: O modelo apresenta uma tabela unificada para Participantes (`TB_PARTICIPANTE`). Por que não criar tabelas separadas para Alunos, Servidores e Comunidade Externa?**
**Resposta Esperada:** Optamos por uma generalização, agrupando todos em uma única tabela para evitar fragmentação e facilitar as consultas (`JOINs`), já que os atributos base (Nome, Email) são os mesmos para todos. A diferenciação é feita através do atributo classificador `TP_VINCULO_INST` (Tipo de Vínculo Institucional).

**Q5: Por que a carga horária do instrutor não foi colocada na tabela `TB_ATIVIDADE`?**
**Resposta Esperada:** Porque uma única atividade (ex: um minicurso) pode ser ministrada por vários instrutores diferentes simultaneamente (relacionamento N:N), e cada um pode ter dedicado uma quantidade de horas diferente. Por isso, a carga horária (`VL_CARGA_HORARIA`) pertence à tabela associativa `RL_ALOCACAO_INSTRUTOR`.

**Q6 (Edge Case): E se uma Atividade for "avulsa", ou seja, não pertencer a nenhum Projeto de Extensão? O banco quebra?**
**Resposta Esperada:** Não. A modelagem previu esse "edge case" permitindo que a chave estrangeira `ID_PROJ_VINCULADO` na tabela `TB_ATIVIDADE` seja nula (`NULL`). Assim, o sistema aceita tanto atividades subordinadas a um projeto quanto eventos totalmente isolados.

**Q7 (Edge Case): O que acontece no banco se tentarmos deletar um Projeto de Extensão que já possui várias Atividades cadastradas?**
**Resposta Esperada:** O banco impedirá a deleção. Utilizamos a restrição `ON DELETE RESTRICT` (que é o padrão) nas chaves estrangeiras. Isso evita que atividades fiquem "órfãs" e protege a integridade referencial do sistema. Para apagar o projeto, as atividades precisariam ser desvinculadas ou apagadas antes.

**Q8 (Normalização): O relatório afirma que o banco está na 3ª Forma Normal (3NF). O que isso significa na prática do projeto e qual anomalia foi evitada?**
**Resposta Esperada:** Estar na 3NF significa que todos os atributos dependem unicamente e exclusivamente da Chave Primária. Se tivéssemos colocado o nome e especialidade do Instrutor diretamente na tabela de `TB_PROJETO_EXTENSAO`, caso ele mudasse de especialidade, teríamos que atualizar várias linhas onde ele fosse coordenador (anomalia de atualização). Com o instrutor em sua própria tabela `TB_INSTRUTOR`, alteramos a especialidade apenas uma vez, e todos os projetos refletem a mudança.

**Q9 (Edge Case de Tipagem): Por que a relação `RL_PATROCINIO_EVENTO` exige `VL_APORTE` como `DECIMAL`? E se o parceiro (ONG, por exemplo) não der dinheiro, mas apenas apoio institucional?**
**Resposta Esperada:** O campo decimal permite o registro em moeda (R$). Caso o apoio seja institucional e sem valor monetário repassado, a DML permite que o `VL_APORTE` receba o valor `0.00` ou até mesmo seja inserido como nulo (caso o projeto permita campos opcionais), deixando explícito que há o patrocínio, mas a título não-oneroso.

---

### 2. Governança e Decisões Físicas (MAD/IBAMA)

**Q10: O que é a Metodologia MAD/IBAMA e como vocês a aplicaram no banco?**
**Resposta Esperada:** É um padrão de governança para padronizar a nomenclatura e facilitar a manutenção. Aplicamos usando prefixos para tabelas (`TB_` para negociais, `RL_` para associativas, `TA_` para auditoria) e para colunas (`ID_` para identificadores, `DS_` para descrições, `DT_` para datas, `VL_` para valores). Mantivemos tudo em maiúsculo, singular e sem acentos.

**Q11: Vocês utilizaram `SERIAL` para as chaves primárias. Por que não utilizaram `UUID`, que é muito comum em sistemas modernos?**
**Resposta Esperada:** Essa foi uma escolha de design baseada em desempenho e simplicidade. O tipo `SERIAL` (inteiro numérico sequencial de 4 bytes) é muito mais rápido para realizar operações de `JOIN` e processar a árvore dos índices do que um `UUID` (texto complexo de 16 bytes). Como nosso foco era otimizar o tempo de resposta das consultas analíticas pesadas, o `SERIAL` foi a escolha mais viável.

**Q12: Percebemos que os nomes de colunas e tabelas não passam de 30 caracteres. Qual o motivo disso?**
**Resposta Esperada:** Essa é uma das exigências estritas da Metodologia MAD/IBAMA. Limitar identificadores a 30 caracteres garante portabilidade do esquema do banco de dados para SGBDs legados ou de diferentes fabricantes (como versões antigas do Oracle, que possuíam esse limite de 30 caracteres *hard-coded*), evitando quebra de scripts na migração.

**Q13: Por que utilizar `CHECK` constraints ao invés de criar `Triggers` para validar os dados que entram?**
**Resposta Esperada:** As `CHECK Constraints` operam diretamente a nível de linha e são validadas de forma nativa e otimizada pelo SGBD, sendo extremamente mais rápidas. Uma `Trigger` exigiria a invocação do motor PL/pgSQL e carregaria overhead desnecessário apenas para checar se uma nota está entre 0 e 10 ou se a presença é 'PRESENTE'/'AUSENTE'.

**Q14: Por que vocês criaram campos como `VARCHAR(150)` em vez de usar `TEXT` para campos descritivos (como `DS_TITULO_ATIVIDADE`)?**
**Resposta Esperada:** Como medida de saneamento e design da UI/UX (visão do sistema). Campos como títulos, e-mails e nomes são curtos e previsíveis. O `VARCHAR(150)` bloqueia inserções absurdamente longas que poderiam ocorrer por erros no sistema ou ataques de texto, evitando inchaço desnecessário na base. Já descrições detalhadas (como conteúdo programático) usaram `TEXT`.

---

### 3. Segurança, Privacidade (LGPD) e Backup

**Q15: Como o sistema lida com a auditoria das ações (PPP1), especialmente considerando a LGPD?**
**Resposta Esperada:** Definimos diferentes níveis de acesso via Roles (DBA, Sistema, Análise, Backup). Para a auditoria técnica, os eventos de inserção, deleção e atualização (`I/U/D`) disparam *Triggers* (Gatilhos) que gravam logs em tabelas dedicadas de auditoria (como `TA_TB_PARTICIPANTE`). Essas tabelas registram: tipo de operação, data/hora exata (`DT_OPERACAO`), e o nome do usuário/terminal responsável, mantendo rastreabilidade caso haja vazamento ou manipulação de dados pessoais.

**Q16: O que estabelece a Política de Backup e Recuperação (PBR1) definida nos requisitos?**
**Resposta Esperada:** A política define que faremos backup full semanal do banco, catálogo e configurações. O RTO (Recovery Time Objective - Tempo máximo aceitável fora do ar) é de até 4h para restauração local em casos críticos. Também estabelece armazenamento redundante (local e nuvem criptografada).

**Q17: Na PBR1, vocês mencionam que os backups na nuvem devem ser criptografados. Por que a criptografia é necessária em um mero "dump" de banco de dados acadêmico?**
**Resposta Esperada:** Porque as tabelas (como `TB_PARTICIPANTE`) abrigam dados PII (Personally Identifiable Information), como nome completo e e-mail. Se o arquivo de *dump* não estiver encriptado (protegido por senha ou chave simétrica), qualquer pessoa que conseguir baixar esse arquivo pela nuvem terá acesso aos dados em texto plano, causando infração grave da LGPD.

---

### 4. Desempenho (Performance) e Plano de Indexação

**Q18: Como vocês justificam as escolhas dos 10 índices criados no `indexing_plan.sql`?**
**Resposta Esperada:** Focamos em duas frentes vitais: 
1. **Chaves Estrangeiras:** Criamos índices nas FKs (ex: `ID_PARTICIPANTE` e `ID_ATIVIDADE` na tabela `RL_INSCRICAO_HISTORICO`) porque elas representam os caminhos das operações de `JOIN`.
2. **Filtros e Agrupamentos:** Criamos índices em colunas muito demandadas no `WHERE` e `GROUP BY`, como datas de atividades e e-mail dos participantes. 

**Q19: Como foi medido o ganho de desempenho e quais foram os resultados?**
**Resposta Esperada:** O script de benchmark (`benchmark.sql`) mediu o banco sem índices (baseline) e depois com os índices aplicados. Cada uma das 30 consultas rodou 20 vezes em cada cenário utilizando `clock_timestamp()`. O ganho de velocidade (*Speedup*) médio foi robusto: cerca de **5,8x**. O impacto mais massivo ocorreu nas consultas sobre `RL_INSCRICAO_HISTORICO`, que é a tabela mais pesada do nosso esquema (11.000 linhas).

**Q20 (Edge Case de Desempenho): Houve algum caso em que a criação de índice não trouxe grande ganho (*Speedup* baixo)? Por quê?**
**Resposta Esperada:** Sim. Para consultas que rodavam em tabelas pequenas (como `TB_PARCEIRO` ou `TB_PROJETO_EXTENSAO`), o ganho foi visivelmente menor (na faixa de 4x a 5x). Isso acontece porque ler uma tabela pequena inteira de forma sequencial (*Sequential Scan*) em memória é tão rápido que o custo de consultar a estrutura de árvore B-Tree do índice, e depois buscar a linha física, não compensa a otimização.

**Q21 (Trade-off de Desempenho): Se a indexação nos deu um Speedup de 5.8x na leitura, há alguma desvantagem nela?**
**Resposta Esperada:** Sim. O custo (*overhead*) das operações de escrita (DML: Insert, Update, Delete). Toda vez que um novo registro é adicionado a uma tabela indexada (como um novo histórico de inscrição), o PostgreSQL é obrigado a não só salvar o dado, mas também recalcular e reorganizar as árvores de índices correspondentes. Em tabelas gigantescas ou de alta volatilidade, excesso de índices tornará a escrita extremamente lenta.

---

### 5. Consultas SQL e População de Dados (DML)

**Q22: Como foi possível gerar um volume sintético de mais de 5.500 registros? Vocês inseriram um a um?**
**Resposta Esperada:** Não inserimos manualmente. Utilizamos blocos processuais e funções nativas de série do PostgreSQL (`generate_series()`). Em conjunto com comandos de randomização matemática (`random()`) e concatenação de strings para geração de e-mails, o nosso script `dml_population.sql` foi capaz de popular as tabelas em massa de forma automatizada e realista.

**Q23: Vocês podem citar exemplos de funções complexas exigidas nas consultas avançadas?**
**Resposta Esperada:** Utilizamos um vasto repertório para atender o barema:
*   **Window Functions:** Empregadas para criar rankings particionados (ex: rank de alunos por nota) e cálculos de totais acumulados, sem que isso achate os dados como um `GROUP BY` faria.
*   **CTEs (Common Table Expressions / Cláusula WITH):** Usadas para modularizar consultas, montando "tabelas temporárias em memória" primeiro (como achar médias gerais) para depois cruzar com a consulta principal.
*   **Subconsultas com NOT EXISTS:** Para identificar casos de exceção, como "Alunos super-participantes que nunca faltaram" ou "Instrutores que nunca coordenaram um projeto".

**Q24 (Edge Case de Negócio): Um aluno que faltou ao evento pode receber um certificado? Como o banco garante que isso não ocorra?**
**Resposta Esperada:** Logicamente isso seria uma anomalia (Edge Case). No escopo do que foi populado sinteticamente, nós garantimos via DML (script de carga) que apenas as inscrições com `ST_PRESENCA = 'PRESENTE'` originassem certificados. Se fosse para ser protegido a nível de banco numa aplicação real rodando, teríamos que implementar um *Trigger* (ou tratar no backend da aplicação) que verificasse o *status* da presença em `RL_INSCRICAO_HISTORICO` antes de efetivar o `INSERT` na tabela `TB_EMISSAO_CERTIFICADO`.

**Q25 (Segurança da Implantação): O `final_script.sql` contém mais de 60KB de código. Como vocês garantem que se ocorrer um erro no meio da criação (ex: um erro de sintaxe na tabela 10), o banco não ficará populado "pela metade"?**
**Resposta Esperada:** Garantimos isso através do uso de Transações. Se o script envolver os comandos em um bloco `BEGIN;` e terminar com um `COMMIT;` (ou se o SGBD aplicar auto-transação de DDL), vigora o princípio da Atomicidade (Tudo ou Nada). Caso haja qualquer falha crítica numa tabela posterior, o banco fará um `ROLLBACK` total, evitando um estado de "sujeira" com dados parcialmente importados.

---

### 6. Questões Extras: Alta Complexidade, Arquitetura e Escalonamento

**Q26 (Concorrência): O que acontece se dois alunos tentarem se matricular na mesma atividade extamente no mesmo milissegundo e houver apenas 1 vaga restante?**
**Resposta Esperada:** É um problema de concorrência. Embora não tenhamos implementado controle de vagas explicitamente na entrega inicial, bancos de dados relacionais como o PostgreSQL usam o conceito de Isolamento de Transações e bloqueios (Locks). Se houvesse um limite, a primeira transação seguraria a linha (Row-level lock) para ler as vagas, e a segunda transação ficaria em espera. Se a primeira confirmasse e zerasse a vaga, a segunda receberia um erro ou não poderia efetuar a inscrição.

**Q27 (Deleção Física vs Lógica): Se um instrutor processar a universidade e exigir ter todos os seus dados apagados sob a LGPD, nós damos um `DELETE` nele? Mas e o histórico passado?**
**Resposta Esperada:** Como as chaves estrangeiras (`FK`) estão sob a regra `RESTRICT`, tentar um `DELETE` físico geraria um erro fatal, já que ele corromperia a história de eventos anteriores. A forma de lidar com isso seria um *Soft Delete* (exclusão lógica) onde teríamos um atributo `IS_ATIVO` (booleano) alterado para falso, ou usar a pseudo-anonimização dos dados pessoais daquele ID, mantendo a integridade analítica das tabelas associativas intocada.

**Q28 (Consultas Pesadas e Cache): Algumas das 30 consultas do Marco 1 processam dezenas de milhares de *JOINs*. Se essa consulta ficar muito pesada em produção e precisar ser usada para um Dashboard em tempo real, o que poderia ser feito em banco de dados?**
**Resposta Esperada:** Uma das abordagens recomendadas seria transformar a consulta pesada em uma *View Materializada* (`MATERIALIZED VIEW`). Diferente de uma *View* comum, ela guarda o resultado fisicamente como se fosse uma tabela, tornando a leitura do dashboard imediata. O único custo seria criar rotinas (como `CRON`) para atualizar (fazer um *refresh*) essa view materializada a cada x horas.

**Q29 (Índices Voláteis): Nós criamos um índice no Status de Presença (`ST_PRESENCA`). No mundo real, a presença sofre muitos *Updates* diários (de Ausente para Presente). Qual a dor de cabeça que isso pode trazer para o DBA?**
**Resposta Esperada:** O índice acelera a leitura de quem está presente, mas ao sofrer `UPDATES` frequentes, a árvore estrutural do índice sofre fragmentação, gerando registros mortos (*dead tuples*). Isso faz com que, ao longo do tempo, o índice perca seu "Speedup" e ocupe lixo em disco. O DBA teria que rodar comandos frequentes como `VACUUM` e rotinas de `REINDEX` para limpar a tabela de índices.

**Q30 (Aderência do MER): Como foi tratada a entidade associativa do BrModeloWeb? Ela é uma entidade "fraca" tradicional?**
**Resposta Esperada:** As entidades com prefixo `RL_` vieram da materialização dos losangos (relacionamentos N:N) do MER. Ao descer para o Lógico e o Físico, elas se transformaram em tabelas regulares (Entidades Associativas). Elas podem ser vistas como entidades dependentes em termos de identificação (já que sua Chave Primária é composta pelas FKs que herda), mas no contexto puramente relacional da 3NF implementada, elas cumprem um papel fundamental para evitar redundância e viabilizar relações complexas.

**Q31 (Modelagem de Feedback): Por que na tabela `TB_REGISTRO_FEEDBACK` o identificador utilizado é o de inscrição (`ID_INSCRICAO`) e não o do participante (`ID_PARTICIPANTE`)?**
**Resposta Esperada:** Porque um participante pode se inscrever em várias atividades diferentes. Se o feedback fosse ligado apenas ao participante, não saberíamos qual atividade ele está avaliando. Ao ligar à Inscrição (que é a relação entre Participante e Atividade), garantimos o contexto completo (quem avaliou e o que foi avaliado), e a restrição `UNIQUE` em `ID_INSCRICAO` assegura que há no máximo um feedback por inscrição.

**Q32 (Modelagem de Certificado): A lógica usada no Feedback se aplica também aos Certificados? Por que não vincular o certificado diretamente ao Participante?**
**Resposta Esperada:** Sim, a mesma lógica se aplica. Um participante só ganha um certificado referente a uma participação específica em um evento. A tabela `TB_EMISSAO_CERTIFICADO` referencia `ID_INSCRICAO` para que o certificado garanta exatamente aquela presença naquela atividade específica. Ligar direto ao participante faria perder o vínculo com o evento em si.

**Q33 (Consultas Cruzadas): Se na tabela de Feedback (`TB_REGISTRO_FEEDBACK`) não há referência direta à Atividade (`ID_ATIVIDADE`), como descobrimos qual evento recebeu uma nota 5?**
**Resposta Esperada:** Através de um cruzamento de tabelas (`JOIN`). Como a tabela de Feedback possui o `ID_INSCRICAO`, fazemos um `JOIN` com a tabela `RL_INSCRICAO_HISTORICO`. Essa tabela associativa possui tanto o `ID_PARTICIPANTE` quanto o `ID_ATIVIDADE`. Assim, com apenas um `JOIN` intermediário, chegamos a todos os dados do evento e do participante, mantendo o banco perfeitamente normalizado (3NF).

**Q34 (Modelagem de Notas): Por que a nota da avaliação (`VL_NOTA_AVALIACAO`) está na tabela de inscrição (`RL_INSCRICAO_HISTORICO`) e não na de atividade ou na de participante?**
**Resposta Esperada:** Porque a nota não é um atributo exclusivo do participante (pois ele terá notas diferentes em cursos diferentes) e nem exclusivo da atividade (pois cada aluno tem uma nota). A nota é gerada exatamente no cruzamento entre os dois. Logo, ela é um atributo do relacionamento (da inscrição) e deve ficar na entidade associativa para respeitar a 3ª Forma Normal.

**Q35 (Validações de Regra de Negócio): O modelo relacional com chaves estrangeiras é capaz de impedir sozinho que um Instrutor se inscreva no próprio curso que ele vai ministrar?**
**Resposta Esperada:** Não. As chaves estrangeiras e a estrutura das tabelas `RL_INSCRICAO_HISTORICO` e `RL_ALOCACAO_INSTRUTOR` apenas garantem a integridade referencial dos IDs. Para impedir que um instrutor seja aluno do próprio minicurso, seria necessário aplicar essa regra de negócio via programação (através de um *Trigger* no PostgreSQL antes do *Insert*, ou via validação na camada da aplicação).

**Q36 (Generalização de Tabelas): Por que existe apenas uma tabela `TB_ATIVIDADE` em vez de criar tabelas separadas para Workshops, Minicursos e Palestras?**
**Resposta Esperada:** Isso é resolvido pela técnica de Generalização. Criar tabelas separadas geraria redundância massiva, pois os atributos base (Nome, Data, Carga Horária) são idênticos. Agrupá-las em uma única tabela e diferenciá-las apenas por um atributo classificador (como `TP_ATIVIDADE`) simplifica imensamente os cruzamentos (`JOINs`) e centraliza o uso das chaves estrangeiras.

**Q37 (Restrições de Patrocínio): Como a estrutura do banco lida se um Parceiro resolver fazer dois aportes financeiros para o mesmo Evento? A tabela `RL_PATROCINIO_EVENTO` aceita linhas duplicadas?**
**Resposta Esperada:** Como a chave primária dessa tabela associativa é composta por `ID_PARCEIRO` e `ID_ATIVIDADE`, o SGBD impede registros duplicados desse mesmo par. Portanto, se houver um novo aporte financeiro do mesmo parceiro para o evento, a abordagem correta no banco seria fazer um `UPDATE` no registro existente somando o valor (`VL_APORTE`), e não um novo `INSERT`.

**Q38 (Manutenção de Regras Físicas): O que seria necessário fazer no banco se a coordenação decidisse mudar a nota de Feedback para uma escala de 0 a 10 (atualmente é de 1 a 5)?**
**Resposta Esperada:** Como a regra de 1 a 5 foi aplicada fisicamente na estrutura do banco usando uma restrição `CHECK CONSTRAINT` na coluna de satisfação, nós teríamos que rodar um comando `ALTER TABLE` para remover (`DROP`) a restrição antiga e adicionar a nova aceitando de 0 a 10. Os dados antigos não seriam afetados, pois notas de 1 a 5 são matematicamente válidas na nova regra.

**Q39 (Consultas Analíticas e Ranking): Como é feita a ordenação de rank dos participantes em relação às suas notas nas atividades?**
**Resposta Esperada:** A ordenação é feita calculando a média global de notas (`media_global`) de cada participante em todas as atividades em que foi avaliado (através de um `GROUP BY` e `AVG`). Sobre esse resultado, aplicamos a função de janelamento (`Window Function`) `RANK() OVER(ORDER BY media_global DESC)`. Essa função atribui uma posição no ranking para cada aluno de forma decrescente, garantindo que em caso de empates na média, os participantes ocupem a mesma posição.

**Q40 (Window Functions vs GROUP BY): Por que foi utilizada a função de janelamento `RANK()` em vez de um simples `ORDER BY` com limitador para definir os melhores alunos?**
**Resposta Esperada:** O `RANK()` foi utilizado porque, diferentemente de um simples `ORDER BY`, ele trata corretamente os **empates**, atribuindo a mesma classificação para médias idênticas, refletindo com precisão uma situação real de ranqueamento acadêmico. Um simples `ORDER BY ... LIMIT` cortaria participantes empatados aleatoriamente. Além disso, as Window Functions não agregam/achatam as linhas do resultado final como o `GROUP BY`, preservando o detalhamento do ranking.

**Q41 (Complexidade de Consultas): No ranking de alunos, foi utilizada uma subconsulta no `FROM`. Por que a função `RANK()` não foi aplicada diretamente na mesma consulta que agrupa e calcula a média (`GROUP BY`)?**
**Resposta Esperada:** Porque as Window Functions (como `RANK()`) operam sobre o resultado final das junções e agregações de uma cláusula `SELECT`. Portanto, a média global de cada participante primeiro precisava ser resolvida e calculada em uma subconsulta para gerar a agregação antes que a consulta externa pudesse aplicar o ranqueamento lógico corretamente sobre esse resultado já consolidado.

**Q42 (Uso do DENSE_RANK): Em relação à função `RANK()`, se houvesse necessidade de que o ranking não "pulasse" números em caso de empate (por exemplo, após um empate no 1º lugar, o próximo aluno ser classificado como 2º lugar e não 3º), como resolver no banco?**
**Resposta Esperada:** Nesse caso, bastaria substituir a função `RANK()` pela função `DENSE_RANK()`. O comportamento do `DENSE_RANK()` é idêntico na ordenação e no tratamento de empates, porém ele não cria saltos ou lacunas na numeração sequencial das posições subsequentes após empates.

**Q43 (Tratamento de Nulos): Na apuração da média global para o ranking, o que ocorre caso o participante ainda não tenha nenhuma nota lançada, apenas o registro de sua presença?**
**Resposta Esperada:** A função de agregação `AVG()` do PostgreSQL ignora automaticamente os valores nulos (`NULL`) durante o cálculo da média aritmética. Isso previne que a nota de um aluno seja penalizada apenas porque a avaliação de uma atividade ainda não foi inserida no banco, refletindo uma média correta apenas baseada nos cursos já avaliados.

**Q44 (Impacto no Desempenho com Window Functions): Operações com Window Functions como o `RANK()` são conhecidas por exigirem recursos de CPU e memória. Como podemos garantir a performance desta consulta em uma base gigante?**
**Resposta Esperada:** Como a consulta precisa ordenar internamente (`ORDER BY media_global DESC`) para aplicar o ranking, o banco fará uma operação de classificação pesada em memória (`Sort`). Em dashboards gerenciais de leitura frequente, a solução recomendada seria transformar todo esse bloco analítico em uma View Materializada (`MATERIALIZED VIEW`), de forma que o resultado pesado seja processado em *background* e entregue instantaneamente na leitura.

**Q45 (Redundância de DISTINCT): A query que busca "Instrutores alocados sem projeto coordenado" (Query 4) faz um `COUNT(DISTINCT alloc.ID_ATIVIDADE)`. O uso do `DISTINCT` aqui é realmente necessário?**
**Resposta Esperada:** Não, ele é redundante. A tabela associativa `RL_ALOCACAO_INSTRUTOR` tem a chave primária composta `(ID_ATIVIDADE, ID_INSTRUTOR)`, o que garante que para um mesmo instrutor não existam atividades repetidas na alocação. Como os agrupamentos são feitos por instrutor, usar apenas `COUNT(alloc.ID_ATIVIDADE)` ou `COUNT(*)` traria exatamente o mesmo resultado numérico com uma melhor performance (pois dispensa ordenação e eliminação de duplicatas).

**Q46 (Subconsultas: NOT EXISTS vs NOT IN): Na busca por instrutores sem projeto (Query 4), foi usado `NOT EXISTS`. Por que não utilizar um `NOT IN` comparando o ID do instrutor?**
**Resposta Esperada:** O `NOT EXISTS` lida de forma mais segura com possíveis valores nulos resultantes da subconsulta. Caso houvesse um `NULL` retornado pelo `NOT IN`, toda a avaliação se tornaria nula (devido à lógica de três valores do SQL), omitindo registros de forma incorreta. Além disso, em muitos SGBDs modernos, o `NOT EXISTS` resulta num plano de execução mais eficiente (*anti-join*).

**Q47 (Otimização do JOIN): Em algumas consultas complexas, há vários `JOIN` (inner) consecutivos. O que aconteceria na query se trocássemos sem necessidade um `JOIN` por um `LEFT JOIN`?**
**Resposta Esperada:** Haveria impacto negativo na performance e os resultados poderiam ser alterados. O `JOIN` restringe a busca aos elementos em comum (interseção), diminuindo o conjunto de resultados nas etapas subsequentes. O `LEFT JOIN` instruiria o banco a preservar todos os registros da tabela à esquerda e buscar correspondências. Isso gera sobrecarga e retorna linhas que seriam preenchidas com nulos à direita.

**Q48 (Agrupamento e Select): Na query que agrupa as alocações, foi usado `GROUP BY inst.ID_INSTRUTOR, inst.DS_NOME_INSTRUTOR`. Por que incluir o nome do instrutor se apenas o ID já o identifica de forma única?**
**Resposta Esperada:** Por regra estrita da linguagem SQL, todas as colunas que aparecem na cláusula `SELECT` (e que não estejam sendo agregadas por funções como SUM ou COUNT) devem ser obrigatoriamente declaradas no `GROUP BY`. Caso o `DS_NOME_INSTRUTOR` não fosse listado no agrupamento, o banco rejeitaria a consulta com um erro de sintaxe.

**Q49 (Filtros: HAVING vs WHERE): Em agrupamentos (como identificar atividades com múltiplos instrutores), usamos `HAVING COUNT(*) > 1`. Qual a diferença para o `WHERE`?**
**Resposta Esperada:** A cláusula `WHERE` atua linha a linha *antes* da formação dos grupos. A cláusula `HAVING`, por sua vez, atua sobre o resultado *após* a criação dos grupos. Não é possível usar funções de agregação como `COUNT` dentro de um `WHERE` porque nesse momento da execução as contagens agrupadas ainda não foram computadas.

**Q50 (Redundâncias de Lógica no WHERE): Qual o impacto de incluir em um `WHERE` condições que já são garantidas pelo esquema físico (ex: `VL_CARGA_HORARIA >= 0` em uma coluna com *Check Constraint*)?**
**Resposta Esperada:** Quando impomos uma condição que já é garantida estruturalmente pelo *Constraint* da tabela física, aumentamos a carga de trabalho do motor no *parsing* e na montagem do plano de execução, sem obter nenhum poder de filtragem a mais. Isso apenas polui o código da consulta com redundâncias lógicas.

**Q51 (Operadores de Conjunto): A busca da "Query 4" (que utiliza subqueries com `NOT EXISTS`) poderia ser resolvida utilizando operadores de conjunto (`EXCEPT` ou `MINUS`)?**
**Resposta Esperada:** Sim. Uma alternativa estrutural seria buscar todos os instrutores alocados e "subtrair" (com a cláusula `EXCEPT`) o conjunto dos instrutores que são coordenadores. O resultado lógico seria exatamente o mesmo. O uso do `NOT EXISTS` é a forma padrão mais flexível, mas o `EXCEPT` atende bem a necessidade com ótima performance em planos baseados em *Hash*.

**Q52 (Índices e Funções de Agregação): Voltando ao `DISTINCT`, suponha que em um caso específico ele não fosse redundante. Como a existência de um índice na coluna ajudaria no cálculo do `COUNT(DISTINCT...)`?**
**Resposta Esperada:** Quando executamos um `DISTINCT`, o SGBD precisa fazer um `Sort` ou `Hash` para varrer redundâncias. Se a coluna contada possuir um índice, os valores já estarão organizados de forma pré-ordenada (como em uma B-Tree). Isso permite que o banco use um *Index Scan*, atravessando e ignorando duplicatas de forma direta e ágil, com um custo de CPU consideravelmente menor.

**Q53 (Otimização de Consultas: JOIN Desnecessário): Foi alegado que na query que lista o total de membros por projeto (`SELECT proj.DS_NOME_PROJETO, COUNT(mem.ID_PARTICIPANTE) FROM TB_PROJETO_EXTENSAO proj JOIN RL_MEMBRO_PROJETO mem ON ... JOIN TB_PARTICIPANTE p ON ... GROUP BY proj.DS_NOME_PROJETO`) existe um JOIN desnecessário. Isso é verdade?**
**Resposta Esperada:** Sim. O JOIN com a tabela `TB_PARTICIPANTE` é desnecessário porque nenhuma coluna dessa tabela é selecionada (apenas fazemos contagem) ou serve de filtro lógico no `WHERE` ou `GROUP BY`. Assumindo que a chave estrangeira em `RL_MEMBRO_PROJETO` garante que o participante exista, o INNER JOIN não descarta nenhuma linha adicional, apenas consumindo mais memória e processamento. A contagem pode ser feita diretamente via tabela associativa.

**Q54 (Otimização e Boas Práticas: Uso de SELECT *): Qual o impacto real na performance de usar um `SELECT *` ao invés de declarar explicitamente as colunas desejadas em uma busca com JOINs múltiplos?**
**Resposta Esperada:** O `SELECT *` força o banco a recuperar todas as colunas de todas as tabelas envolvidas na consulta. Isso gera enorme desperdício de memória RAM e tráfego de rede para carregar campos não utilizados. Além disso, ao omitir colunas que não precisamos, impedimos que o otimizador do banco de dados use técnicas como *Index-Only Scans* (onde a query pode ser respondida lendo estritamente os dados do índice, sem nem tocar na tabela real em disco).

**Q55 (Design de Relatórios: COUNT com LEFT JOIN vs INNER JOIN): Se trocássemos um `INNER JOIN` por um `LEFT JOIN` para listar Projetos de Extensão e contar seus membros (`RL_MEMBRO_PROJETO`), a lógica do resultado seria afetada?**
**Resposta Esperada:** Sim, de forma substancial. O `INNER JOIN` omite totalmente os projetos sem membros vinculados. O `LEFT JOIN` listaria todos os projetos, até os inativos/vazios, criando registros nulos na junção. Contudo, haveria uma armadilha: se usássemos `COUNT(*)`, um projeto vazio contaria "1" (pois conta a linha em si). Para que o número seja zero em projetos vazios, o correto ao usar `LEFT JOIN` é obrigar o uso de `COUNT(mem.ID_PARTICIPANTE)`, que inteligentemente ignora os nulos.

**Q56 (Escalabilidade e Filtragem: Offset em Paginação): Em telas listando milhares de inscrições em eventos, é comum fazer a paginação via SQL utilizando a técnica de `OFFSET / LIMIT` (ex: `OFFSET 50000 LIMIT 100`). Qual seria o gargalo de performance disso?**
**Resposta Esperada:** O `OFFSET` não acessa diretamente o meio da tabela. O SGBD precisa internamente ler as 50 mil linhas iniciais em disco e memória, descartá-las, e só então retornar as próximas 100. A performance se degrada drasticamente nas últimas páginas de consultas pesadas. Uma alternativa escalável seria o "Keyset Pagination" (ou "Seek Method"), usando cláusulas de limite com ponteiros contínuos como `WHERE ID > ultimo_ID_da_pagina_anterior`.

**Q57 (Indexação Silenciosa de Chaves Estrangeiras): O modelo físico conta com várias Chaves Estrangeiras (FKs). O SGBD cria índices automaticamente para as chaves primárias; ele também faz isso para garantir a integridade das Foreign Keys?**
**Resposta Esperada:** Não. A maior parte dos motores de bancos de dados relacionais (PostgreSQL, SQL Server, Oracle) **não** criam índices em FKs automaticamente. Essa é uma armadilha de performance clássica: se nenhuma restrição manual for criada, sempre que deletarmos um registro de uma tabela principal, o banco será forçado a varrer (Full Table Scan) a tabela dependente inteira verificando violações de ON DELETE, tornando o sistema lento à medida que cresce.

**Q58 (Consistência e Agregações Duplicadas): Em uma tabela associativa sem Chave Primária correta que permita duplicatas, se um participante estivesse inserido duas vezes no mesmo projeto, o comando `COUNT(*)` estaria falho. Como resolver apenas por via da Query SQL?**
**Resposta Esperada:** Contornando o problema de modelagem pela query, faríamos uso do comando `COUNT(DISTINCT mem.ID_PARTICIPANTE)`. Assim, não importa quantas linhas o banco de dados recupere para aquele relacionamento específico, a contagem seria exclusiva sobre as identidades unitárias dos participantes, gerando uma estatística de "indivíduos distintos envolvidos no projeto", que contornaria erros de falta de *Constraint*.

**Q59 (Correção de Bug: Permissões de Backup): Durante a revisão dos nossos scripts DCL, nós notamos e corrigimos um erro onde o usuário de backup (`pg_dbbackup`) tinha seus privilégios revogados (`REVOKE`) nas tabelas de auditoria. Qual era o risco prático se tivéssemos deixado esse erro passar?**
**Resposta Esperada:** O utilitário de backup do PostgreSQL (como o `pg_dump`) atua executando consultas massivas de leitura no banco. Como tínhamos negado a permissão de leitura sobre as tabelas de histórico e auditoria, o backup seria gerado ignorando silenciosamente os logs de segurança e as operações rastreadas. Em caso de desastre e restauração do banco, nós perderíamos irrevogavelmente todo o histórico e compliance da aplicação. Felizmente, corrigimos liberando o `GRANT SELECT` para ele.

**Q60 (Correção de Bug: Vulnerabilidade no Privilégio Padrão): Nós havíamos cometido um erro de segurança no script DCL ao utilizar `ALTER DEFAULT PRIVILEGES` concedendo acesso DML ao usuário do sistema para as tabelas do esquema `public`. Por que nós removemos esse trecho do código final?**
**Resposta Esperada:** Nós percebemos que o `ALTER DEFAULT PRIVILEGES` aplica os acessos especificados de forma automática para *todas* as novas tabelas que fossem criadas naquele esquema dali em diante. O problema de segurança é que se, no futuro, nós criássemos uma nova tabela de auditoria restrita, o usuário padrão da aplicação ganharia acesso de DELETE e UPDATE nela automaticamente, burlando nosso princípio de que auditorias são imutáveis. Corrigimos isso focando na concessão de acessos explícitos por tabela.

**Q61 (Correção de Bug: Cardinalidade Associativa): No código original da nossa equipe, nós transformamos a tabela associativa `RL_INSCRICAO_HISTORICO` usando uma Surrogate Key (`ID_INSCRICAO SERIAL`), mas esquecemos de colocar a constraint `UNIQUE` na dupla `(ID_PARTICIPANTE, ID_ATIVIDADE)`. Por que tivemos que consertar isso correndo?**
**Resposta Esperada:** Porque tabelas associativas perdem sua proteção nativa contra repetição quando abandonamos a chave primária composta (formada pelas Foreign Keys) em favor de um ID serial. Sem aplicar um índice `UNIQUE` nas foreign keys, o nosso banco de dados estava falho e permitia que o mesmíssimo Participante fosse matriculado múltiplas vezes na exata mesma Atividade (gerando vários IDs de Inscrição e driblando o limite de 1 certificado por aluno). Nós fixamos isso aplicando o `CONSTRAINT UK_INSCRICAO_UNICA`.

**Q62 (Correção de Bug: Criação de Índices Redundantes): Ao realizar o plano de indexação, nossa equipe havia criado manualmente comandos `CREATE INDEX` para as colunas `ID_INSCRICAO` nas tabelas de Certificado e Feedback. Por que nós consideramos isso um "anti-pattern" de banco de dados e removemos do código final?**
**Resposta Esperada:** Nós havíamos esquecido que, em bancos relacionais (incluindo o PostgreSQL), qualquer constraint `UNIQUE` ou `PRIMARY KEY` gera automaticamente e silenciosamente um índice *B-Tree* para aquela coluna. Como as tabelas de Certificado e Feedback já possuíam a constraint `UNIQUE (ID_INSCRICAO)`, os nossos `CREATE INDEX` manuais estavam forçando o SGBD a criar um segundo índice completamente idêntico para os mesmos dados. Retiramos isso pois estávamos ocupando o dobro de espaço em disco e prejudicando a performance de escrita à toa.

**Q63 (Correção de Bug: Chaves Naturais Ausentes): A nossa tabela de Participantes (`TB_PARTICIPANTE`) possuía um ID Serial, mas inicialmente não contava com uma restrição `UNIQUE` no campo `DS_EMAIL_CONTATO`. O que nos motivou a consertar isso na revisão da modelagem?**
**Resposta Esperada:** Nós percebemos que o e-mail atua como a *Chave Natural* do indivíduo no sistema (uma vez que os participantes não possuíam atributo de CPF). Ao esquecer a constraint `UNIQUE` no e-mail, nosso banco de dados estava vulnerável: uma falha no sistema web permitiria que a mesma pessoa fosse cadastrada infinitas vezes usando o mesmo e-mail, o que inflaria nossos relatórios de participação, destruiria a consistência dos dados analíticos e faria o controle de acessos da aplicação colapsar.

**Q64 (Correção de Bug: Ausência de Restrições de Domínio): Nos esquemas mais primitivos da nossa entrega, as colunas numéricas de Carga Horária (`RL_ALOCACAO_INSTRUTOR`) e Valor do Aporte (`RL_PATROCINIO_EVENTO`) não possuíam limitações físicas no PostgreSQL. Qual erro nós sanamos ao introduzir o uso de `CHECK CONSTRAINTS` nelas?**
**Resposta Esperada:** Nós consertamos uma violação grave de integridade de domínio. Tipos de dados `INT` ou `DECIMAL` aceitam normalmente valores negativos no PostgreSQL. Contudo, em nossa Regra de Negócio não faz sentido lógico registrar que um instrutor lecionou "-5 horas" ou uma empresa deu "-100 reais". Sem um `CHECK (VL_CARGA_HORARIA > 0)`, nós deixávamos a responsabilidade puramente para o código front-end/back-end. Nós introduzimos os `CHECK CONSTRAINTS` para garantir que o banco aja como a mais confiável linha de defesa contra dados absurdos.

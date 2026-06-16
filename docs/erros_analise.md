# Relatório de Revisão Analítica do Banco de Dados

Esta revisão analítica verificou as implementações consolidadas no arquivo `final_script.sql`, avaliando a conformidade com as regras do MAD1, os requisitos negociais do `requisitos.md` e a eficácia das queries e benchmarks.

## 1. Verificação de Nomenclatura e Conformidade (MAD1)
Foram encontradas as seguintes violações e discrepâncias em relação ao documento base de Metodologia:

* **Tabelas de Auditoria (Colunas):** O documento `requisitos.md` na seção [MAD1] exige explicitamente a presença da coluna `DT_OPERACAO` nas tabelas de auditoria (TA_). No script final, foi implementado `DH_OPERACAO` (do tipo `TIMESTAMP`). Logicamente o uso de `DH_` (Data/Hora) está correto para timestamps, porém infringe a regra documental do cliente.
* **Nomenclatura das Triggers:** A regra exige `TG_[B/A]_[I/U/D]_NomeTabela`, implicando uma especificação por tipo de operação (Insert, Update, Delete). O script consolidou todas em um único nome aglutinado, ex: `TG_A_IUD_TB_ATIVIDADE`, o que foge ao padrão estrito estabelecido de apenas uma letra I, U ou D, e dificulta a separação se as triggers forem desmembradas depois.
* **Nomenclatura de Sequences:** A alteração realizada (`RENAME TO SQ_TB_INSTRUTOR`) gera prefixos duplicados de objetos (`SQ_TB_`), enquanto a regra dita que seria `Prefixo_NomeObjeto` separada por underscore, e no singular (ex: `SQ_INSTRUTOR`).
* **Nomes de Constraints FK Multiplas:** A metodologia dita `FK_TabelaPai_TabelaFilha_Nome`. O script final ignorou essa nomenclatura mais detalhada em alguns casos, utilizando apenas `FK_ATIVIDADE_PROJETO` ou `FK_INSCRICAO_PARTICIPANTE`, muitas vezes omitindo o TabelaPai ou TabelaFilha apropriado.

## 2. Análise do Benchmark e Desempenho
O script `benchmark.sql` foi analisado quanto à sua eficácia para validar o banco de dados:

* **Efeito de Cache:** O script executa cada query 20 vezes dentro de blocos `DO` com `clock_timestamp()` para medir o tempo antes e depois da inserção de índices. No entanto, ele falha em não limpar o buffer de cache (`shared_buffers`) entre os testes. As repetições subsequentes apresentarão um tempo de execução quase zero por conta de page cache, enviesando o resultado final do desvio padrão e média das execuções no PostgreSQL.
* **Teste de Overhead:** O benchmark roda avaliações baseadas apenas em consultas (`SELECT`). Ele não valida o custo extra de transação (overhead) das operações de DML (`INSERT`/`UPDATE`/`DELETE`) agravado pela excessiva quantidade de Triggers de auditoria construídas via `FOR EACH ROW`.

## 3. Avaliação Lógica das Queries (Requisitos)
As 30 Queries (10 intermediárias e 20 avançadas) foram avaliadas para verificar se de fato entregam o resultado proposto:

* As queries logicamente atendem o que se propõem, empregando corretamente sub-queries, joins, aggregate, e window functions (como `RANK()` e `FIRST_VALUE()`).
* **Advanced Query 7:** "Projetos onde o coordenador também dá aula, apenas em projetos com >5 atividades". A query conta o número de aulas distintas do coordenador em vez de contabilizar o tamanho do projeto na output final. O resultado exibe as aulas do coordenador como `total_atividades`. A saída não quebra o requisito rigidamente, mas pode causar má interpretação por parte do usuário final.
* **Aliasing nas Queries:** Embora o MAD1 ordene letras maiúsculas na nomeação de objetos do banco (tabelas, triggers, procedures), diversas queries usam *aliases* em formato *snake_case* ou minúsculas (ex: `total_inscricoes`, `media_nota`, `coordenador`). Recomenda-se padronizar a output de aliases com o mesmo padrão MAD1 caso seja enviada via BI (ex: `TOTAL_INSCRICOES`).

## 4. Conclusão Final
O banco de dados, em geral, **atende aos requisitos funcionais** modelados (RF1 a RF7) em relação aos relacionamentos, segurança por privilégios (`dba_ic`, `sistema_ic`, `analise_ic`, `dbbackup_ic`) e emissão dos scripts.
As ressalvas mais graves encontram-se no desalinhamento rigoroso dos prefixos MAD1 nas chaves estrangeiras, triggers e nas colunas de auditoria (`DH_` em vez de `DT_`). Recomenda-se um ajuste final de nomenclatura para certificar o código.

Relatório de Varredura - Projeto MATA60 BD
Resumo
A varredura completa foi executada em todos os artefatos da pasta de entrega (delivery), confrontando os códigos e relatórios com as diretrizes e regras avaliativas estipuladas no documento base do professor (01_projeto-I-MATA60-BD.pdf).

De maneira geral, a Entrega 1 (Marco 1) cumpriu a maioria absoluta das premissas. As infrações identificadas na Entrega 2 (Marco 2) foram integralmente corrigidas conforme descrito abaixo.

1. Inconformidades Identificadas e Correções Aplicadas (Marco 2 - OCRA)

1.1 Transações com Sintaxe Inválida no PL/pgSQL (Erro de Execução/Compilação) — ✅ CORRIGIDO
Local do problema: routines_and_transactions.sql
Artefatos afetados: SP_INSCREVER_COM_VALIDACAO e SP_TRANSFERIR_PARTICIPANTE
Regra Descumprida: A entrega de transações funcionais (Barema: "Elaborou (...) 2 Transações adequadamente").
Descrição do Erro Original: A equipe tentou implementar o controle de transações dentro de Stored Procedures no PostgreSQL usando os comandos literais de SAVEPOINT, ROLLBACK TO SAVEPOINT e RELEASE SAVEPOINT. Entretanto, o PostgreSQL não suporta a execução direta desses comandos de transação parcial (savepoint) dentro da estrutura processual do PL/pgSQL. A chamada destas rotinas acarretará fatalmente no erro: ERROR: unsupported transaction command in PL/pgSQL
Correção aplicada: As duas procedures foram reescritas utilizando blocos BEGIN ... EXCEPTION ... END, que geram e gerenciam savepoints implícitos internamente pelo SGBD. Adicionalmente, foram incluídos handlers específicos para unique_violation e validações prévias de existência dos registros. O relatório (Relatorio_Entrega2_Marco2.md) foi atualizado com a fundamentação técnica da abordagem correta.

1.2 Reutilização de Consultas nos Dashboards (Descumprimento de Regra) — ✅ CORRIGIDO
Local do problema: materialized_views_dashboards.sql e Relatorio_Entrega2_Marco2.md.
Artefatos afetados: Todas as 10 Materialized Views destinadas ao Dashboard 1.
Regra Descumprida: Quadro 3 do edital dita claramente: "Cada gráfico corresponde ao resultado de uma consulta avançada/intermediária (diferentes da Entrega 1)".
Descrição do Erro Original: Para agilizar o desenvolvimento, a equipe copiou as consultas exatas (A1, A2, A3, A10, etc.) elaboradas no Marco 1 para preencher as rotinas do Marco 2.
Correção aplicada: Todas as 10 Materialized Views foram completamente reescritas com consultas analíticas NOVAS e EXCLUSIVAS do Marco 2, sem nenhuma reutilização das queries do Marco 1. As novas views incluem: Índice de Retenção (VM_INDICE_RETENCAO_PROJETO), Gap de Emissão de Certificados (VM_GAP_EMISSAO_CERTIFICADO), Distribuição por Quartis de Notas (VM_DISTRIBUICAO_QUARTIS_NOTAS), Cobertura de Instrutores (VM_COBERTURA_INSTRUTORES_PROJETO), Análise de Coortes (VM_COHORT_PRIMEIRA_INSCRICAO), NPS por Projeto (VM_NPS_POR_PROJETO), Matriz Vínculo×Presença (VM_MATRIZ_VINCULO_PRESENCA), Impacto do Patrocínio (VM_IMPACTO_PATROCINIO_ATIVIDADE), Volume Semanal (VM_VOLUME_SEMANAL_INSCRICOES) e ROI de Parceiros (VM_ROI_PARCEIROS). O relatório e o script privacy_and_security.sql foram atualizados para refletir os novos nomes.
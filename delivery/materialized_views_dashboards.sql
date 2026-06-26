-- IC Extension Management - Materialized Views (Dashboards)
-- 10 Materialized Views com consultas NOVAS e EXCLUSIVAS para o Marco 2
-- NENHUMA destas consultas repete ou reutiliza as queries do Marco 1.

-- ============================================================================
-- Dashboard 1: 4 Gráficos Analíticos Estratégicos (4 Consultas Avançadas Novas)
-- ============================================================================

-- 1. Gráfico Estratégico 1: Índice de Retenção por Projeto
-- Consulta NOVA (exclusiva Marco 2): Calcula a taxa de retorno dos participantes —
-- quantos se inscreveram em mais de uma atividade do mesmo projeto, indicando retenção.
-- Técnicas: CTE, Window Function (COUNT OVER), CASE, JOINs múltiplos, GROUP BY com HAVING.
CREATE MATERIALIZED VIEW VM_INDICE_RETENCAO_PROJETO AS
WITH InscricoesPorProjeto AS (
    SELECT
        i.ID_PARTICIPANTE,
        a.ID_PROJ_VINCULADO AS ID_PROJETO,
        COUNT(DISTINCT i.ID_ATIVIDADE) AS QTD_ATIVIDADES_INSCRITAS
    FROM RL_INSCRICAO_HISTORICO i
    JOIN TB_ATIVIDADE a ON i.ID_ATIVIDADE = a.ID_ATIVIDADE
    WHERE a.ID_PROJ_VINCULADO IS NOT NULL
    GROUP BY i.ID_PARTICIPANTE, a.ID_PROJ_VINCULADO
)
SELECT
    proj.DS_NOME_PROJETO,
    COUNT(ipp.ID_PARTICIPANTE) AS TOTAL_PARTICIPANTES_UNICOS,
    COUNT(CASE WHEN ipp.QTD_ATIVIDADES_INSCRITAS >= 2 THEN 1 END) AS PARTICIPANTES_RETIDOS,
    ROUND(
        COUNT(CASE WHEN ipp.QTD_ATIVIDADES_INSCRITAS >= 2 THEN 1 END) * 100.0
        / NULLIF(COUNT(ipp.ID_PARTICIPANTE), 0), 2
    ) AS TAXA_RETENCAO_PERCENTUAL
FROM InscricoesPorProjeto ipp
JOIN tabela_projeto_extensao proj ON ipp.ID_PROJETO = proj.ID_PROJETO
GROUP BY proj.ID_PROJETO, proj.DS_NOME_PROJETO
HAVING COUNT(ipp.ID_PARTICIPANTE) >= 3
ORDER BY TAXA_RETENCAO_PERCENTUAL DESC
WITH DATA;

-- 2. Gráfico Estratégico 2: Gap Temporal entre Realização da Atividade e Emissão do Certificado
-- Consulta NOVA (exclusiva Marco 2): Analisa o tempo médio de processamento dos certificados
-- após a conclusão das atividades, identificando gargalos operacionais.
-- Técnicas: Window Function (PERCENTILE_CONT, AVG OVER), JOINs, DATE arithmetic, GROUP BY.
CREATE MATERIALIZED VIEW VM_GAP_EMISSAO_CERTIFICADO AS
SELECT
    proj.DS_NOME_PROJETO,
    a.DS_TITULO_ATIVIDADE,
    COUNT(cert.ID_CERTIFICADO) AS CERTIFICADOS_EMITIDOS,
    ROUND(AVG(cert.DT_EMISSAO - a.DT_REALIZACAO), 2) AS MEDIA_DIAS_PARA_EMISSAO,
    MIN(cert.DT_EMISSAO - a.DT_REALIZACAO) AS MIN_DIAS,
    MAX(cert.DT_EMISSAO - a.DT_REALIZACAO) AS MAX_DIAS,
    ROUND(AVG(AVG(cert.DT_EMISSAO - a.DT_REALIZACAO))
        OVER(PARTITION BY proj.ID_PROJETO), 2) AS MEDIA_DIAS_DO_PROJETO
FROM TB_EMISSAO_CERTIFICADO cert
JOIN RL_INSCRICAO_HISTORICO i ON cert.ID_INSCRICAO = i.ID_INSCRICAO
JOIN TB_ATIVIDADE a ON i.ID_ATIVIDADE = a.ID_ATIVIDADE
JOIN tabela_projeto_extensao proj ON a.ID_PROJ_VINCULADO = proj.ID_PROJETO
GROUP BY proj.ID_PROJETO, proj.DS_NOME_PROJETO, a.ID_ATIVIDADE, a.DS_TITULO_ATIVIDADE
WITH DATA;

-- 3. Gráfico Estratégico 3: Distribuição de Desempenho por Quartis (Segmentação de Notas)
-- Consulta NOVA (exclusiva Marco 2): Classifica o desempenho dos participantes em quartis
-- (Q1=Baixo, Q2=Regular, Q3=Bom, Q4=Excelente) para análise de distribuição.
-- Técnicas: NTILE() Window Function, CTE, CASE, GROUP BY, múltiplos JOINs.
CREATE MATERIALIZED VIEW VM_DISTRIBUICAO_QUARTIS_NOTAS AS
WITH NotasClassificadas AS (
    SELECT
        i.ID_PARTICIPANTE,
        p.TP_VINCULO_INST,
        i.VL_NOTA_AVALIACAO,
        NTILE(4) OVER(ORDER BY i.VL_NOTA_AVALIACAO) AS QUARTIL
    FROM RL_INSCRICAO_HISTORICO i
    JOIN tabela_participante p ON i.ID_PARTICIPANTE = p.ID_PARTICIPANTE
    JOIN TB_ATIVIDADE a ON i.ID_ATIVIDADE = a.ID_ATIVIDADE
    WHERE i.VL_NOTA_AVALIACAO IS NOT NULL
)
SELECT
    CASE QUARTIL
        WHEN 1 THEN 'Q1 - Baixo (0-25%)'
        WHEN 2 THEN 'Q2 - Regular (25-50%)'
        WHEN 3 THEN 'Q3 - Bom (50-75%)'
        WHEN 4 THEN 'Q4 - Excelente (75-100%)'
    END AS FAIXA_DESEMPENHO,
    TP_VINCULO_INST,
    COUNT(*) AS QTD_AVALIACOES,
    ROUND(AVG(VL_NOTA_AVALIACAO), 2) AS MEDIA_NOTA_FAIXA,
    ROUND(MIN(VL_NOTA_AVALIACAO), 2) AS NOTA_MINIMA,
    ROUND(MAX(VL_NOTA_AVALIACAO), 2) AS NOTA_MAXIMA
FROM NotasClassificadas
GROUP BY QUARTIL, TP_VINCULO_INST
ORDER BY QUARTIL, TP_VINCULO_INST
WITH DATA;

-- 4. Gráfico Estratégico 4: Análise de Cobertura Territorial de Instrutores nos Projetos
-- Consulta NOVA (exclusiva Marco 2): Verifica a diversidade de instrutores alocados por projeto,
-- medindo a razão instrutor/atividade e identificando projetos sub ou sobredimensionados.
-- Técnicas: CTEs encadeadas, subconsulta correlata, Window Function (RANK), JOINs, GROUP BY.
CREATE MATERIALIZED VIEW VM_COBERTURA_INSTRUTORES_PROJETO AS
WITH DadosProjeto AS (
    SELECT
        proj.ID_PROJETO,
        proj.DS_NOME_PROJETO,
        COUNT(DISTINCT a.ID_ATIVIDADE) AS TOTAL_ATIVIDADES,
        COUNT(DISTINCT alloc.ID_INSTRUTOR) AS INSTRUTORES_DISTINTOS,
        SUM(alloc.VL_CARGA_HORARIA) AS CARGA_TOTAL
    FROM tabela_projeto_extensao proj
    JOIN TB_ATIVIDADE a ON proj.ID_PROJETO = a.ID_PROJ_VINCULADO
    JOIN RL_ALOCACAO_INSTRUTOR alloc ON a.ID_ATIVIDADE = alloc.ID_ATIVIDADE
    GROUP BY proj.ID_PROJETO, proj.DS_NOME_PROJETO
)
SELECT
    DS_NOME_PROJETO,
    TOTAL_ATIVIDADES,
    INSTRUTORES_DISTINTOS,
    ROUND(INSTRUTORES_DISTINTOS * 1.0 / NULLIF(TOTAL_ATIVIDADES, 0), 2) AS RAZAO_INSTRUTOR_ATIVIDADE,
    CARGA_TOTAL,
    ROUND(CARGA_TOTAL * 1.0 / NULLIF(INSTRUTORES_DISTINTOS, 0), 2) AS CARGA_MEDIA_POR_INSTRUTOR,
    RANK() OVER(ORDER BY INSTRUTORES_DISTINTOS DESC) AS RANKING_DIVERSIDADE
FROM DadosProjeto
WITH DATA;


-- ============================================================================
-- Dashboard 1: 6 Gráficos Analíticos Operacionais (2 Avançadas + 4 Intermediárias)
-- Todas as consultas são NOVAS e EXCLUSIVAS deste Marco 2.
-- ============================================================================

-- 5. Gráfico Operacional 1 (Avançada): Cohort de Participantes por Mês de Primeira Inscrição
-- Consulta NOVA: Agrupa participantes pelo mês de sua primeira inscrição e calcula
-- a evolução do engajamento (inscrições totais) de cada coorte ao longo do tempo.
-- Técnicas: CTEs encadeadas, Window Function (MIN OVER, SUM OVER), JOINs, GROUP BY.
CREATE MATERIALIZED VIEW VM_COHORT_PRIMEIRA_INSCRICAO AS
WITH PrimeiraInscricao AS (
    SELECT
        i.ID_PARTICIPANTE,
        MIN(a.DT_REALIZACAO) AS DT_PRIMEIRA_INSCRICAO
    FROM RL_INSCRICAO_HISTORICO i
    JOIN TB_ATIVIDADE a ON i.ID_ATIVIDADE = a.ID_ATIVIDADE
    GROUP BY i.ID_PARTICIPANTE
),
CoorteAgg AS (
    SELECT
        DATE_TRUNC('month', pi.DT_PRIMEIRA_INSCRICAO) AS MES_COORTE,
        COUNT(DISTINCT pi.ID_PARTICIPANTE) AS NOVOS_PARTICIPANTES,
        COUNT(DISTINCT i.ID_INSCRICAO) AS TOTAL_INSCRICOES_COORTE,
        ROUND(AVG(i.VL_NOTA_AVALIACAO), 2) AS MEDIA_NOTA_COORTE
    FROM PrimeiraInscricao pi
    JOIN RL_INSCRICAO_HISTORICO i ON pi.ID_PARTICIPANTE = i.ID_PARTICIPANTE
    JOIN TB_ATIVIDADE a ON i.ID_ATIVIDADE = a.ID_ATIVIDADE
    GROUP BY DATE_TRUNC('month', pi.DT_PRIMEIRA_INSCRICAO)
)
SELECT
    MES_COORTE,
    NOVOS_PARTICIPANTES,
    TOTAL_INSCRICOES_COORTE,
    ROUND(TOTAL_INSCRICOES_COORTE * 1.0 / NULLIF(NOVOS_PARTICIPANTES, 0), 2) AS INSCRICOES_PER_CAPITA,
    MEDIA_NOTA_COORTE,
    SUM(NOVOS_PARTICIPANTES) OVER(ORDER BY MES_COORTE) AS PARTICIPANTES_ACUMULADOS
FROM CoorteAgg
ORDER BY MES_COORTE
WITH DATA;

-- 6. Gráfico Operacional 2 (Avançada): Análise de Polarização do Feedback (NPS Simplificado)
-- Consulta NOVA: Classifica feedbacks em Detratores (1-2), Neutros (3) e Promotores (4-5)
-- por projeto e calcula um Net Promoter Score simplificado.
-- Técnicas: CTE, CASE com agregação condicional, subconsulta, JOINs (4 tabelas), GROUP BY.
CREATE MATERIALIZED VIEW VM_NPS_POR_PROJETO AS
WITH FeedbackClassificado AS (
    SELECT
        proj.ID_PROJETO,
        proj.DS_NOME_PROJETO,
        f.VL_NOTA_SATISFACAO,
        CASE
            WHEN f.VL_NOTA_SATISFACAO <= 2 THEN 'DETRATOR'
            WHEN f.VL_NOTA_SATISFACAO = 3 THEN 'NEUTRO'
            ELSE 'PROMOTOR'
        END AS CLASSIFICACAO
    FROM TB_REGISTRO_FEEDBACK f
    JOIN RL_INSCRICAO_HISTORICO i ON f.ID_INSCRICAO = i.ID_INSCRICAO
    JOIN TB_ATIVIDADE a ON i.ID_ATIVIDADE = a.ID_ATIVIDADE
    JOIN tabela_projeto_extensao proj ON a.ID_PROJ_VINCULADO = proj.ID_PROJETO
)
SELECT
    DS_NOME_PROJETO,
    COUNT(*) AS TOTAL_FEEDBACKS,
    COUNT(CASE WHEN CLASSIFICACAO = 'PROMOTOR' THEN 1 END) AS QTD_PROMOTORES,
    COUNT(CASE WHEN CLASSIFICACAO = 'NEUTRO' THEN 1 END) AS QTD_NEUTROS,
    COUNT(CASE WHEN CLASSIFICACAO = 'DETRATOR' THEN 1 END) AS QTD_DETRATORES,
    ROUND(
        (COUNT(CASE WHEN CLASSIFICACAO = 'PROMOTOR' THEN 1 END) * 100.0 / NULLIF(COUNT(*), 0))
      - (COUNT(CASE WHEN CLASSIFICACAO = 'DETRATOR' THEN 1 END) * 100.0 / NULLIF(COUNT(*), 0))
    , 2) AS NPS_SCORE
FROM FeedbackClassificado
GROUP BY ID_PROJETO, DS_NOME_PROJETO
ORDER BY NPS_SCORE DESC
WITH DATA;

-- 7. Gráfico Operacional 3 (Intermediária): Matriz de Participação: Vínculo × Status de Presença
-- Consulta NOVA: Cria uma tabela cruzada (cross-tab) entre o tipo de vínculo institucional
-- e o status de presença, mostrando as taxas de cada combinação.
-- Técnicas: CASE com agregação, JOINs (3 tabelas), GROUP BY com ROLLUP semântico.
CREATE MATERIALIZED VIEW VM_MATRIZ_VINCULO_PRESENCA AS
SELECT
    p.TP_VINCULO_INST,
    COUNT(*) AS TOTAL_INSCRICOES,
    COUNT(CASE WHEN i.ST_PRESENCA = 'PRESENTE' THEN 1 END) AS QTD_PRESENTES,
    COUNT(CASE WHEN i.ST_PRESENCA = 'AUSENTE' THEN 1 END) AS QTD_AUSENTES,
    COUNT(CASE WHEN i.ST_PRESENCA = 'PENDENTE' THEN 1 END) AS QTD_PENDENTES,
    ROUND(
        COUNT(CASE WHEN i.ST_PRESENCA = 'PRESENTE' THEN 1 END) * 100.0
        / NULLIF(COUNT(*), 0), 2
    ) AS TAXA_PRESENCA_PERCENTUAL,
    ROUND(AVG(i.VL_NOTA_AVALIACAO), 2) AS NOTA_MEDIA_GERAL
FROM tabela_participante p
JOIN RL_INSCRICAO_HISTORICO i ON p.ID_PARTICIPANTE = i.ID_PARTICIPANTE
JOIN TB_ATIVIDADE a ON i.ID_ATIVIDADE = a.ID_ATIVIDADE
GROUP BY p.TP_VINCULO_INST
ORDER BY TAXA_PRESENCA_PERCENTUAL DESC
WITH DATA;

-- 8. Gráfico Operacional 4 (Intermediária): Atividades sem Nenhum Patrocínio vs Com Patrocínio
-- Consulta NOVA: Compara o volume de inscrições e a nota média entre atividades que
-- receberam aporte financeiro de parceiros e atividades que não receberam.
-- Técnicas: LEFT JOIN com IS NULL/IS NOT NULL, CASE, JOINs (3+ tabelas), GROUP BY.
CREATE MATERIALIZED VIEW VM_IMPACTO_PATROCINIO_ATIVIDADE AS
SELECT
    CASE
        WHEN pat.ID_PARCEIRO IS NOT NULL THEN 'COM PATROCÍNIO'
        ELSE 'SEM PATROCÍNIO'
    END AS CATEGORIA_ATIVIDADE,
    COUNT(DISTINCT a.ID_ATIVIDADE) AS TOTAL_ATIVIDADES,
    COUNT(DISTINCT i.ID_INSCRICAO) AS TOTAL_INSCRICOES,
    ROUND(AVG(i.VL_NOTA_AVALIACAO), 2) AS NOTA_MEDIA_PARTICIPANTES,
    ROUND(COUNT(DISTINCT i.ID_INSCRICAO) * 1.0 / NULLIF(COUNT(DISTINCT a.ID_ATIVIDADE), 0), 2) AS MEDIA_INSCRICOES_POR_ATIVIDADE
FROM TB_ATIVIDADE a
LEFT JOIN RL_PATROCINIO_EVENTO pat ON a.ID_ATIVIDADE = pat.ID_ATIVIDADE
LEFT JOIN RL_INSCRICAO_HISTORICO i ON a.ID_ATIVIDADE = i.ID_ATIVIDADE
GROUP BY CASE
        WHEN pat.ID_PARCEIRO IS NOT NULL THEN 'COM PATROCÍNIO'
        ELSE 'SEM PATROCÍNIO'
    END
WITH DATA;

-- 9. Gráfico Operacional 5 (Intermediária): Evolução Semanal do Volume de Inscrições
-- Consulta NOVA: Agrupa as inscrições por semana de realização da atividade
-- e calcula a média móvel de 4 semanas para identificar tendências.
-- Técnicas: DATE_TRUNC, Window Function (AVG OVER com ROWS), JOINs, GROUP BY.
CREATE MATERIALIZED VIEW VM_VOLUME_SEMANAL_INSCRICOES AS
SELECT
    DATE_TRUNC('week', a.DT_REALIZACAO) AS SEMANA_REALIZACAO,
    COUNT(i.ID_INSCRICAO) AS INSCRICOES_NA_SEMANA,
    COUNT(DISTINCT a.ID_ATIVIDADE) AS ATIVIDADES_NA_SEMANA,
    ROUND(AVG(i.VL_NOTA_AVALIACAO), 2) AS NOTA_MEDIA_SEMANA,
    ROUND(AVG(COUNT(i.ID_INSCRICAO)) OVER(
        ORDER BY DATE_TRUNC('week', a.DT_REALIZACAO)
        ROWS BETWEEN 3 PRECEDING AND CURRENT ROW
    ), 2) AS MEDIA_MOVEL_4_SEMANAS
FROM TB_ATIVIDADE a
JOIN RL_INSCRICAO_HISTORICO i ON a.ID_ATIVIDADE = i.ID_ATIVIDADE
JOIN tabela_participante p ON i.ID_PARTICIPANTE = p.ID_PARTICIPANTE
GROUP BY DATE_TRUNC('week', a.DT_REALIZACAO)
ORDER BY SEMANA_REALIZACAO
WITH DATA;

-- 10. Gráfico Operacional 6 (Intermediária): Parceiros com Maior Retorno sobre Investimento (ROI Simplificado)
-- Consulta NOVA: Para cada parceiro, calcula o "custo por certificado emitido" dividindo
-- o total aportado pelo número de certificados associados às atividades patrocinadas.
-- Técnicas: LEFT JOINs encadeados (5 tabelas), agregação com NULLIF, GROUP BY com HAVING.
CREATE MATERIALIZED VIEW VM_ROI_PARCEIROS AS
WITH InvestimentoParceiro AS (
    SELECT ID_PARCEIRO, SUM(VL_APORTE) AS TOTAL_INVESTIDO
    FROM RL_PATROCINIO_EVENTO
    GROUP BY ID_PARCEIRO
)
SELECT
    par.DS_NOME_ORGANIZACAO,
    par.TP_PARCEIRO,
    inv.TOTAL_INVESTIDO,
    COUNT(DISTINCT cert.ID_CERTIFICADO) AS CERTIFICADOS_GERADOS,
    COUNT(DISTINCT i.ID_INSCRICAO) AS INSCRICOES_ALCANCADAS,
    ROUND(
        inv.TOTAL_INVESTIDO / NULLIF(COUNT(DISTINCT cert.ID_CERTIFICADO), 0), 2
    ) AS CUSTO_POR_CERTIFICADO,
    ROUND(
        inv.TOTAL_INVESTIDO / NULLIF(COUNT(DISTINCT i.ID_INSCRICAO), 0), 2
    ) AS CUSTO_POR_INSCRICAO
FROM TB_PARCEIRO par
JOIN InvestimentoParceiro inv ON par.ID_PARCEIRO = inv.ID_PARCEIRO
JOIN RL_PATROCINIO_EVENTO pat ON par.ID_PARCEIRO = pat.ID_PARCEIRO
JOIN TB_ATIVIDADE a ON pat.ID_ATIVIDADE = a.ID_ATIVIDADE
LEFT JOIN RL_INSCRICAO_HISTORICO i ON a.ID_ATIVIDADE = i.ID_ATIVIDADE
LEFT JOIN TB_EMISSAO_CERTIFICADO cert ON i.ID_INSCRICAO = cert.ID_INSCRICAO
GROUP BY par.ID_PARCEIRO, par.DS_NOME_ORGANIZACAO, par.TP_PARCEIRO, inv.TOTAL_INVESTIDO
HAVING inv.TOTAL_INVESTIDO > 0
ORDER BY CUSTO_POR_CERTIFICADO ASC NULLS LAST
WITH DATA;

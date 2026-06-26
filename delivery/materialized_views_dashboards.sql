-- IC Extension Management - Materialized Views (Dashboards)
-- 10 Materialized Views mapped from queries of Marco 1

-- ============================================================================
-- Dashboard 1: 4 GrÃ¡ficos AnalÃ­ticos EstratÃ©gicos (4 Consultas AvanÃ§adas)
-- ============================================================================

-- 1. GrÃ¡fico EstratÃ©gico 1: Ranking Global de Participantes por Notas MÃ©dias
-- Baseado em: Advanced Query 1
CREATE MATERIALIZED VIEW MV_RANKING_PARTICIPANTES AS
SELECT
    sub.DS_NOME_PARTICIPANTE,
    sub.media_global,
    RANK() OVER(ORDER BY sub.media_global DESC) AS RANKING
FROM (
    SELECT
        p.ID_PARTICIPANTE,
        p.DS_NOME_PARTICIPANTE,
        AVG(i.VL_NOTA_AVALIACAO) AS MEDIA_GLOBAL
    FROM tabela_participante p
    JOIN RL_INSCRICAO_HISTORICO i ON p.ID_PARTICIPANTE = i.ID_PARTICIPANTE
    JOIN TB_ATIVIDADE a ON i.ID_ATIVIDADE = a.ID_ATIVIDADE
    GROUP BY p.ID_PARTICIPANTE, p.DS_NOME_PARTICIPANTE
) sub
WITH DATA;

-- 2. GrÃ¡fico EstratÃ©gico 2: Top 3 Projetos com Mais Certificados Emitidos
-- Baseado em: Advanced Query 2
CREATE MATERIALIZED VIEW MV_TOP_PROJETOS_CERTIFICADOS AS
SELECT DS_NOME_PROJETO, total_certificados
FROM (
    SELECT proj.DS_NOME_PROJETO, COUNT(cert.ID_CERTIFICADO) AS TOTAL_CERTIFICADOS
    FROM tabela_projeto_extensao proj
    JOIN TB_ATIVIDADE a ON proj.ID_PROJETO = a.ID_PROJ_VINCULADO
    JOIN RL_INSCRICAO_HISTORICO i ON a.ID_ATIVIDADE = i.ID_ATIVIDADE
    JOIN TB_EMISSAO_CERTIFICADO cert ON i.ID_INSCRICAO = cert.ID_INSCRICAO
    GROUP BY proj.DS_NOME_PROJETO
) sub
ORDER BY total_certificados DESC
LIMIT 3
WITH DATA;

-- 3. GrÃ¡fico EstratÃ©gico 3: Crescimento Mensal (Acumulado) de Projetos e InscriÃ§Ãµes
-- Baseado em: Advanced Query 10
CREATE MATERIALIZED VIEW MV_CRESCIMENTO_MENSAL_PROJETOS AS
SELECT
    DATE_TRUNC('month', proj.DT_CRIACAO) AS MES_CRIACAO,
    COUNT(DISTINCT proj.ID_PROJETO) AS PROJETOS_NO_MES,
    COUNT(DISTINCT i.ID_INSCRICAO) AS TOTAL_INSCRICOES,
    SUM(COUNT(DISTINCT proj.ID_PROJETO)) OVER(ORDER BY DATE_TRUNC('month', proj.DT_CRIACAO)) AS PROJETOS_ACUMULADOS,
    COUNT(DISTINCT proj.ID_PROJETO) - COALESCE(LAG(COUNT(DISTINCT proj.ID_PROJETO)) OVER(ORDER BY DATE_TRUNC('month', proj.DT_CRIACAO)), 0) AS CRESCIMENTO_MENSAL
FROM tabela_projeto_extensao proj
JOIN TB_ATIVIDADE a ON proj.ID_PROJETO = a.ID_PROJ_VINCULADO
JOIN RL_INSCRICAO_HISTORICO i ON a.ID_ATIVIDADE = i.ID_ATIVIDADE
GROUP BY DATE_TRUNC('month', proj.DT_CRIACAO)
WITH DATA;

-- 4. GrÃ¡fico EstratÃ©gico 4: Atividades com ParticipaÃ§Ã£o Acima da MÃ©dia
-- Baseado em: Advanced Query 3
CREATE MATERIALIZED VIEW MV_ATIVIDADES_ALTA_PARTICIPACAO AS
WITH AtividadeContagem AS (
    SELECT ID_ATIVIDADE, COUNT(*) AS TOTAL_INSCRITOS
    FROM RL_INSCRICAO_HISTORICO
    GROUP BY ID_ATIVIDADE
)
SELECT a.DS_TITULO_ATIVIDADE, proj.DS_NOME_PROJETO, ac.total_inscritos
FROM TB_ATIVIDADE a
JOIN AtividadeContagem ac ON a.ID_ATIVIDADE = ac.ID_ATIVIDADE
JOIN tabela_projeto_extensao proj ON a.ID_PROJ_VINCULADO = proj.ID_PROJETO
WHERE ac.total_inscritos > (SELECT AVG(total_inscritos) FROM AtividadeContagem)
WITH DATA;


-- ============================================================================
-- Dashboard 1: 6 GrÃ¡ficos AnalÃ­ticos Operacionais (2 AvanÃ§adas + 4 IntermediÃ¡rias)
-- ============================================================================

-- 5. GrÃ¡fico Operacional 1 (AvanÃ§ada): Projetos com Quantidade de Alunos Acima da MÃ©dia
-- Baseado em: Advanced Query 8
CREATE MATERIALIZED VIEW MV_PROJETOS_ACIMA_MEDIA_ALUNOS AS
SELECT proj.DS_NOME_PROJETO, COUNT(p.ID_PARTICIPANTE) AS TOTAL_ALUNOS
FROM tabela_projeto_extensao proj
JOIN RL_MEMBRO_PROJETO mem ON proj.ID_PROJETO = mem.ID_PROJETO
JOIN tabela_participante p ON mem.ID_PARTICIPANTE = p.ID_PARTICIPANTE
WHERE p.TP_VINCULO_INST = 'ALUNO'
GROUP BY proj.DS_NOME_PROJETO
HAVING COUNT(p.ID_PARTICIPANTE) > (
    SELECT AVG(alunos_count) FROM (
        SELECT COUNT(p2.ID_PARTICIPANTE) AS ALUNOS_COUNT
        FROM RL_MEMBRO_PROJETO mem2
        JOIN tabela_participante p2 ON mem2.ID_PARTICIPANTE = p2.ID_PARTICIPANTE
        WHERE p2.TP_VINCULO_INST = 'ALUNO'
        GROUP BY mem2.ID_PROJETO
    ) sub
)
WITH DATA;

-- 6. GrÃ¡fico Operacional 2 (AvanÃ§ada): Parceiros Patrocinadores MÃºltiplos e Total Aportado
-- Baseado em: Advanced Query 19
CREATE MATERIALIZED VIEW MV_PARCEIROS_MULTIPLOS_PROJETOS AS
SELECT p.DS_NOME_ORGANIZACAO, 
       (SELECT SUM(VL_APORTE) FROM RL_PATROCINIO_EVENTO pat2 WHERE pat2.ID_PARCEIRO = p.ID_PARCEIRO) AS TOTAL_APORTADO
FROM TB_PARCEIRO p
JOIN RL_PATROCINIO_EVENTO pat ON p.ID_PARCEIRO = pat.ID_PARCEIRO
JOIN TB_ATIVIDADE a ON pat.ID_ATIVIDADE = a.ID_ATIVIDADE
GROUP BY p.ID_PARCEIRO, p.DS_NOME_ORGANIZACAO
HAVING COUNT(DISTINCT a.ID_PROJ_VINCULADO) > 1
WITH DATA;

-- 7. GrÃ¡fico Operacional 3 (IntermediÃ¡ria): Total de Atividades por Projeto (com Coordenador)
-- Baseado em: Intermediate Query 2
CREATE MATERIALIZED VIEW MV_TOTAL_ATIVIDADES_PROJETO AS
SELECT proj.DS_NOME_PROJETO,
       inst.DS_NOME_INSTRUTOR AS COORDENADOR,
       COUNT(a.ID_ATIVIDADE) AS TOTAL_ATIVIDADES
FROM tabela_projeto_extensao proj
LEFT JOIN TB_ATIVIDADE a ON proj.ID_PROJETO = a.ID_PROJ_VINCULADO
JOIN TB_INSTRUTOR inst ON proj.ID_INSTR_COORDENADOR = inst.ID_INSTRUTOR
GROUP BY proj.DS_NOME_PROJETO, inst.DS_NOME_INSTRUTOR
WITH DATA;

-- 8. GrÃ¡fico Operacional 4 (IntermediÃ¡ria): Carga HorÃ¡ria Total por Instrutor
-- Baseado em: Intermediate Query 3
CREATE MATERIALIZED VIEW MV_CARGA_HORARIA_INSTRUTORES AS
SELECT inst.DS_NOME_INSTRUTOR,
       COUNT(a.ID_ATIVIDADE) AS TOTAL_ATIVIDADES,
       SUM(alloc.VL_CARGA_HORARIA) AS TOTAL_HORAS
FROM TB_INSTRUTOR inst
JOIN RL_ALOCACAO_INSTRUTOR alloc ON inst.ID_INSTRUTOR = alloc.ID_INSTRUTOR
JOIN TB_ATIVIDADE a ON alloc.ID_ATIVIDADE = a.ID_ATIVIDADE
GROUP BY inst.DS_NOME_INSTRUTOR
WITH DATA;

-- 9. GrÃ¡fico Operacional 5 (IntermediÃ¡ria): AvaliaÃ§Ã£o MÃ©dia por Atividade
-- Baseado em: Intermediate Query 6
CREATE MATERIALIZED VIEW MV_AVALIACAO_MEDIA_ATIVIDADE AS
SELECT a.DS_TITULO_ATIVIDADE,
       proj.DS_NOME_PROJETO,
       AVG(i.VL_NOTA_AVALIACAO) AS MEDIA_NOTA,
       COUNT(i.ID_INSCRICAO) AS TOTAL_INSCRICOES
FROM TB_ATIVIDADE a
JOIN RL_INSCRICAO_HISTORICO i ON a.ID_ATIVIDADE = i.ID_ATIVIDADE
JOIN tabela_projeto_extensao proj ON a.ID_PROJ_VINCULADO = proj.ID_PROJETO
GROUP BY a.DS_TITULO_ATIVIDADE, proj.DS_NOME_PROJETO
HAVING COUNT(i.ID_INSCRICAO) > 5
WITH DATA;

-- 10. GrÃ¡fico Operacional 6 (IntermediÃ¡ria): Participantes Mais Ativos (Mais de 2 presenÃ§as)
-- Baseado em: Intermediate Query 5
CREATE MATERIALIZED VIEW MV_PARTICIPANTES_MAIS_ATIVOS AS
SELECT p.DS_NOME_PARTICIPANTE,
       COUNT(a.ID_ATIVIDADE) AS TOTAL_PRESENCAS,
       STRING_AGG(a.DS_TITULO_ATIVIDADE, ', ') AS NOMES_ATIVIDADES
FROM tabela_participante p
JOIN RL_INSCRICAO_HISTORICO i ON p.ID_PARTICIPANTE = i.ID_PARTICIPANTE
JOIN TB_ATIVIDADE a ON i.ID_ATIVIDADE = a.ID_ATIVIDADE
WHERE i.ST_PRESENCA = 'PRESENTE'
GROUP BY p.DS_NOME_PARTICIPANTE
HAVING COUNT(a.ID_ATIVIDADE) >= 2
WITH DATA;

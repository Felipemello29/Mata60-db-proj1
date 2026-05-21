-- IC Extension Management - Advanced Queries (20)
-- Requirements: 3+ tables, Sub-queries, Window functions, CTEs

-- 1. Rank participants by their average grade across all activities using a window function
SELECT 
    DS_NOME_PARTICIPANTE, 
    AVG(VL_NOTA_AVALIACAO) OVER(PARTITION BY p.ID_PARTICIPANTE) as media_global,
    RANK() OVER(ORDER BY AVG(VL_NOTA_AVALIACAO) DESC) as ranking
FROM TB_PARTICIPANTE p
JOIN RL_INSCRICAO_HISTORICO i ON p.ID_PARTICIPANTE = i.ID_PARTICIPANTE
GROUP BY p.ID_PARTICIPANTE, p.DS_NOME_PARTICIPANTE, i.VL_NOTA_AVALIACAO;

-- 2. Find the top 3 projects by total number of certificates issued
SELECT DS_NOME_PROJETO, total_certificados
FROM (
    SELECT proj.DS_NOME_PROJETO, COUNT(cert.ID_CERTIFICADO) as total_certificados
    FROM TB_PROJETO_EXTENSAO proj
    JOIN TB_ATIVIDADE a ON proj.ID_PROJETO = a.ID_PROJ_VINCULADO
    JOIN RL_INSCRICAO_HISTORICO i ON a.ID_ATIVIDADE = i.ID_ATIVIDADE
    JOIN TB_EMISSAO_CERTIFICADO cert ON i.ID_INSCRICAO = cert.ID_INSCRICAO
    GROUP BY proj.DS_NOME_PROJETO
) sub
ORDER BY total_certificados DESC
LIMIT 3;

-- 3. Use a CTE to find activities with participation higher than the average participation of all activities
WITH AtividadeContagem AS (
    SELECT ID_ATIVIDADE, COUNT(*) as total_inscritos
    FROM RL_INSCRICAO_HISTORICO
    GROUP BY ID_ATIVIDADE
)
SELECT a.DS_TITULO_ATIVIDADE, ac.total_inscritos
FROM TB_ATIVIDADE a
JOIN AtividadeContagem ac ON a.ID_ATIVIDADE = ac.ID_ATIVIDADE
WHERE ac.total_inscritos > (SELECT AVG(total_inscritos) FROM AtividadeContagem);

-- 4. List instructors who have never coordinated a project (using NOT EXISTS)
SELECT DS_NOME_INSTRUTOR
FROM TB_INSTRUTOR inst
WHERE NOT EXISTS (
    SELECT 1 FROM TB_PROJETO_EXTENSAO proj WHERE proj.ID_INSTR_COORDENADOR = inst.ID_INSTRUTOR
);

-- 5. Calculate the running total of sponsorship contributions per partner using a window function
SELECT 
    p.DS_NOME_ORGANIZACAO, 
    pat.VL_APORTE,
    SUM(pat.VL_APORTE) OVER(PARTITION BY p.ID_PARCEIRO ORDER BY pat.ID_ATIVIDADE) as total_acumulado
FROM TB_PARCEIRO p
JOIN RL_PATROCINIO_EVENTO pat ON p.ID_PARCEIRO = pat.ID_PARCEIRO;

-- 6. List participants and the percentage of their grade relative to the maximum grade in that activity
SELECT 
    p.DS_NOME_PARTICIPANTE, 
    a.DS_TITULO_ATIVIDADE, 
    i.VL_NOTA_AVALIACAO,
    (i.VL_NOTA_AVALIACAO / MAX(i.VL_NOTA_AVALIACAO) OVER(PARTITION BY a.ID_ATIVIDADE)) * 100 as perc_max_nota
FROM TB_PARTICIPANTE p
JOIN RL_INSCRICAO_HISTORICO i ON p.ID_PARTICIPANTE = i.ID_PARTICIPANTE
JOIN TB_ATIVIDADE a ON i.ID_ATIVIDADE = a.ID_ATIVIDADE;

-- 7. Find projects where the coordinator also teaches at least one activity of that project
SELECT DISTINCT proj.DS_NOME_PROJETO
FROM TB_PROJETO_EXTENSAO proj
JOIN TB_ATIVIDADE a ON proj.ID_PROJETO = a.ID_PROJ_VINCULADO
JOIN RL_ALOCACAO_INSTRUTOR alloc ON a.ID_ATIVIDADE = alloc.ID_ATIVIDADE
WHERE alloc.ID_INSTRUTOR = proj.ID_INSTR_COORDENADOR;

-- 8. Count how many participants of type 'ALUNO' are in each project
SELECT proj.DS_NOME_PROJETO, COUNT(p.ID_PARTICIPANTE) as total_alunos
FROM TB_PROJETO_EXTENSAO proj
JOIN RL_MEMBRO_PROJETO mem ON proj.ID_PROJETO = mem.ID_PROJETO
JOIN TB_PARTICIPANTE p ON mem.ID_PARTICIPANTE = p.ID_PARTICIPANTE
WHERE p.TP_VINCULO_INST = 'ALUNO'
GROUP BY proj.DS_NOME_PROJETO;

-- 9. List activities that have more than 1 instructor and also have a partner sponsor
SELECT DS_TITULO_ATIVIDADE
FROM TB_ATIVIDADE a
WHERE ID_ATIVIDADE IN (
    SELECT ID_ATIVIDADE FROM RL_ALOCACAO_INSTRUTOR GROUP BY ID_ATIVIDADE HAVING COUNT(*) > 1
) AND EXISTS (
    SELECT 1 FROM RL_PATROCINIO_EVENTO pat WHERE pat.ID_ATIVIDADE = a.ID_ATIVIDADE
);

-- 10. Show the month-over-month growth of project creations (using window function)
SELECT 
    DATE_TRUNC('month', DT_CRIACAO) as mes,
    COUNT(*) as criacoes_no_mes,
    SUM(COUNT(*)) OVER(ORDER BY DATE_TRUNC('month', DT_CRIACAO)) as total_acumulado
FROM TB_PROJETO_EXTENSAO
GROUP BY mes;

-- 11. Find the activity with the highest average satisfaction rating
SELECT DS_TITULO_ATIVIDADE, media_satisfacao
FROM (
    SELECT a.DS_TITULO_ATIVIDADE, AVG(f.VL_NOTA_SATISFACAO) as media_satisfacao
    FROM TB_ATIVIDADE a
    JOIN RL_INSCRICAO_HISTORICO i ON a.ID_ATIVIDADE = i.ID_ATIVIDADE
    JOIN TB_REGISTRO_FEEDBACK f ON i.ID_INSCRICAO = f.ID_INSCRICAO
    GROUP BY a.DS_TITULO_ATIVIDADE
) sub
ORDER BY media_satisfacao DESC
LIMIT 1;

-- 12. List participants who have a certificate for every activity they enrolled in
SELECT DS_NOME_PARTICIPANTE
FROM TB_PARTICIPANTE p
WHERE NOT EXISTS (
    SELECT 1 FROM RL_INSCRICAO_HISTORICO i
    LEFT JOIN TB_EMISSAO_CERTIFICADO c ON i.ID_INSCRICAO = c.ID_INSCRICAO
    WHERE i.ID_PARTICIPANTE = p.ID_PARTICIPANTE AND c.ID_CERTIFICADO IS NULL
);

-- 13. Identify "super-participants" (those with more than 5 enrollments) using a subquery
SELECT DS_NOME_PARTICIPANTE, total_inscricoes
FROM (
    SELECT p.DS_NOME_PARTICIPANTE, COUNT(i.ID_INSCRICAO) as total_inscricoes
    FROM TB_PARTICIPANTE p
    JOIN RL_INSCRICAO_HISTORICO i ON p.ID_PARTICIPANTE = i.ID_PARTICIPANTE
    GROUP BY p.DS_NOME_PARTICIPANTE
) sub
WHERE total_inscricoes > 5;

-- 14. List projects and the average workload of activities associated with them
SELECT proj.DS_NOME_PROJETO, AVG(alloc.VL_CARGA_HORARIA) as avg_workload
FROM TB_PROJETO_EXTENSAO proj
JOIN TB_ATIVIDADE a ON proj.ID_PROJETO = a.ID_PROJ_VINCULADO
JOIN RL_ALOCACAO_INSTRUTOR alloc ON a.ID_ATIVIDADE = alloc.ID_ATIVIDADE
GROUP BY proj.DS_NOME_PROJETO;

-- 15. Using a window function to find the first activity date for each participant
SELECT DISTINCT
    p.DS_NOME_PARTICIPANTE,
    FIRST_VALUE(a.DT_REALIZACAO) OVER(PARTITION BY p.ID_PARTICIPANTE ORDER BY a.DT_REALIZACAO) as primeira_atividade
FROM TB_PARTICIPANTE p
JOIN RL_INSCRICAO_HISTORICO i ON p.ID_PARTICIPANTE = i.ID_PARTICIPANTE
JOIN TB_ATIVIDADE a ON i.ID_ATIVIDADE = a.ID_ATIVIDADE;

-- 16. Count activities by instructor specialty
SELECT inst.DS_ESPECIALIDADE, COUNT(DISTINCT alloc.ID_ATIVIDADE) as total_atividades
FROM TB_INSTRUTOR inst
JOIN RL_ALOCACAO_INSTRUTOR alloc ON inst.ID_INSTRUTOR = alloc.ID_INSTRUTOR
GROUP BY inst.DS_ESPECIALIDADE;

-- 17. Find the participant who gave the lowest feedback score to a highly attended activity (>20 people)
SELECT p.DS_NOME_PARTICIPANTE, f.VL_NOTA_SATISFACAO, a.DS_TITULO_ATIVIDADE
FROM TB_PARTICIPANTE p
JOIN RL_INSCRICAO_HISTORICO i ON p.ID_PARTICIPANTE = i.ID_PARTICIPANTE
JOIN TB_REGISTRO_FEEDBACK f ON i.ID_INSCRICAO = f.ID_INSCRICAO
JOIN TB_ATIVIDADE a ON i.ID_ATIVIDADE = a.ID_ATIVIDADE
WHERE a.ID_ATIVIDADE IN (
    SELECT ID_ATIVIDADE FROM RL_INSCRICAO_HISTORICO GROUP BY ID_ATIVIDADE HAVING COUNT(*) > 20
)
ORDER BY f.VL_NOTA_SATISFACAO ASC
LIMIT 1;

-- 18. List all activities that happened in the last 6 months using a CTE
WITH RecentActivities AS (
    SELECT * FROM TB_ATIVIDADE WHERE DT_REALIZACAO >= CURRENT_DATE - INTERVAL '6 months'
)
SELECT DS_TITULO_ATIVIDADE, DT_REALIZACAO FROM RecentActivities;

-- 19. Find partners who sponsor activities in more than one project
SELECT p.DS_NOME_ORGANIZACAO
FROM TB_PARCEIRO p
JOIN RL_PATROCINIO_EVENTO pat ON p.ID_PARCEIRO = pat.ID_PARCEIRO
JOIN TB_ATIVIDADE a ON pat.ID_ATIVIDADE = a.ID_ATIVIDADE
GROUP BY p.DS_NOME_ORGANIZACAO
HAVING COUNT(DISTINCT a.ID_PROJ_VINCULADO) > 1;

-- 20. Calculate the difference between a participant's grade and the average grade of the activity using a window function
SELECT 
    p.DS_NOME_PARTICIPANTE, 
    a.DS_TITULO_ATIVIDADE, 
    i.VL_NOTA_AVALIACAO,
    i.VL_NOTA_AVALIACAO - AVG(i.VL_NOTA_AVALIACAO) OVER(PARTITION BY a.ID_ATIVIDADE) as diff_para_media
FROM TB_PARTICIPANTE p
JOIN RL_INSCRICAO_HISTORICO i ON p.ID_PARTICIPANTE = i.ID_PARTICIPANTE
JOIN TB_ATIVIDADE a ON i.ID_ATIVIDADE = a.ID_ATIVIDADE;

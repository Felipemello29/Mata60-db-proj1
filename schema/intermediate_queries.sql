-- IC Extension Management - Intermediate Queries (10)
-- Requirements: 3+ tables, JOIN, GROUP BY, aggregation

-- 1. List all participants enrolled in activities belonging to a specific project
SELECT DISTINCT p.DS_NOME_PARTICIPANTE, proj.DS_NOME_PROJETO
FROM TB_PARTICIPANTE p
JOIN RL_INSCRICAO_HISTORICO i ON p.ID_PARTICIPANTE = i.ID_PARTICIPANTE
JOIN TB_ATIVIDADE a ON i.ID_ATIVIDADE = a.ID_ATIVIDADE
JOIN TB_PROJETO_EXTENSAO proj ON a.ID_PROJ_VINCULADO = proj.ID_PROJETO
WHERE proj.ID_PROJETO = 1;

-- 2. Count the number of activities per project
SELECT proj.DS_NOME_PROJETO, COUNT(a.ID_ATIVIDADE) as total_atividades
FROM TB_PROJETO_EXTENSAO proj
LEFT JOIN TB_ATIVIDADE a ON proj.ID_PROJETO = a.ID_PROJ_VINCULADO
GROUP BY proj.DS_NOME_PROJETO;

-- 3. List instructors and the total workload they have assigned across all activities
SELECT inst.DS_NOME_INSTRUTOR, SUM(alloc.VL_CARGA_HORARIA) as total_horas
FROM TB_INSTRUTOR inst
JOIN RL_ALOCACAO_INSTRUTOR alloc ON inst.ID_INSTRUTOR = alloc.ID_INSTRUTOR
GROUP BY inst.DS_NOME_INSTRUTOR;

-- 4. List partners and the total amount they have contributed to activities
SELECT part.DS_NOME_ORGANIZACAO, SUM(pat.VL_APORTE) as total_patrocinio
FROM TB_PARCEIRO part
JOIN RL_PATROCINIO_EVENTO pat ON part.ID_PARCEIRO = pat.ID_PARCEIRO
GROUP BY part.DS_NOME_ORGANIZACAO;

-- 5. List participants who have attended (ST_PRESENCA = 'PRESENTE') at least 2 activities
SELECT p.DS_NOME_PARTICIPANTE, COUNT(i.ID_ATIVIDADE) as total_presencas
FROM TB_PARTICIPANTE p
JOIN RL_INSCRICAO_HISTORICO i ON p.ID_PARTICIPANTE = i.ID_PARTICIPANTE
WHERE i.ST_PRESENCA = 'PRESENTE'
GROUP BY p.DS_NOME_PARTICIPANTE
HAVING COUNT(i.ID_ATIVIDADE) >= 2;

-- 6. Calculate the average grade per activity, only for activities with more than 5 enrollments
SELECT a.DS_TITULO_ATIVIDADE, AVG(i.VL_NOTA_AVALIACAO) as media_nota
FROM TB_ATIVIDADE a
JOIN RL_INSCRICAO_HISTORICO i ON a.ID_ATIVIDADE = i.ID_ATIVIDADE
GROUP BY a.DS_TITULO_ATIVIDADE
HAVING COUNT(i.ID_INSCRICAO) > 5;

-- 7. List activities coordinates by projects of a specific instructor (as coordinator)
SELECT a.DS_TITULO_ATIVIDADE, proj.DS_NOME_PROJETO, inst.DS_NOME_INSTRUTOR
FROM TB_ATIVIDADE a
JOIN TB_PROJETO_EXTENSAO proj ON a.ID_PROJ_VINCULADO = proj.ID_PROJETO
JOIN TB_INSTRUTOR inst ON proj.ID_INSTR_COORDENADOR = inst.ID_INSTRUTOR
WHERE inst.ID_INSTRUTOR = 5;

-- 8. Count certificates issued per activity type (grouped by activity title prefix or similar, here just activity)
SELECT a.DS_TITULO_ATIVIDADE, COUNT(cert.ID_CERTIFICADO) as total_certificados
FROM TB_ATIVIDADE a
JOIN RL_INSCRICAO_HISTORICO i ON a.ID_ATIVIDADE = i.ID_ATIVIDADE
JOIN TB_EMISSAO_CERTIFICADO cert ON i.ID_INSCRICAO = cert.ID_INSCRICAO
GROUP BY a.DS_TITULO_ATIVIDADE;

-- 9. List participants and their feedback (score and comment) for a specific activity
SELECT p.DS_NOME_PARTICIPANTE, f.VL_NOTA_SATISFACAO, f.DS_COMENTARIO_ABERTO
FROM TB_PARTICIPANTE p
JOIN RL_INSCRICAO_HISTORICO i ON p.ID_PARTICIPANTE = i.ID_PARTICIPANTE
JOIN TB_REGISTRO_FEEDBACK f ON i.ID_INSCRICAO = f.ID_INSCRICAO
WHERE i.ID_ATIVIDADE = 10;

-- 10. List projects and the total number of members (bolsistas and voluntários)
SELECT proj.DS_NOME_PROJETO, COUNT(mem.ID_PARTICIPANTE) as total_membros
FROM TB_PROJETO_EXTENSAO proj
JOIN RL_MEMBRO_PROJETO mem ON proj.ID_PROJETO = mem.ID_PROJETO
GROUP BY proj.DS_NOME_PROJETO;

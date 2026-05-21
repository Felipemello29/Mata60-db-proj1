-- IC Extension Management - Data Population Script
-- DBMS: PostgreSQL

-- 1. Auxiliary Tables

-- TB_INSTRUTOR: 50 records
INSERT INTO TB_INSTRUTOR (DS_NOME_INSTRUTOR, DS_ESPECIALIDADE)
SELECT 'Instrutor ' || i, 'Especialidade ' || (i % 5 + 1)
FROM generate_series(1, 50) s(i);

-- TB_PARCEIRO: 20 records
INSERT INTO TB_PARCEIRO (DS_NOME_ORGANIZACAO, TP_PARCEIRO)
SELECT 'Parceiro ' || i, CASE WHEN i % 3 = 0 THEN 'ONG' WHEN i % 3 = 1 THEN 'Empresa Privada' ELSE 'Órgão Público' END
FROM generate_series(1, 20) s(i);

-- TB_PROJETO_EXTENSAO: 10 records
INSERT INTO TB_PROJETO_EXTENSAO (DS_NOME_PROJETO, DT_CRIACAO, ID_INSTR_COORDENADOR)
SELECT 'Projeto de Extensão ' || i, CURRENT_DATE - (i || ' months')::interval, (i % 50) + 1
FROM generate_series(1, 10) s(i);

-- TB_ATIVIDADE: 100 records
INSERT INTO TB_ATIVIDADE (DS_TITULO_ATIVIDADE, DS_CONTEUDO_PROG, DT_REALIZACAO, ID_PROJ_VINCULADO)
SELECT 'Atividade ' || i, 'Conteúdo programático da atividade ' || i, CURRENT_DATE + (i || ' days')::interval, (i % 10) + 1
FROM generate_series(1, 100) s(i);

-- 2. Core Data (5,500 Participants)
INSERT INTO TB_PARTICIPANTE (DS_NOME_PARTICIPANTE, DS_EMAIL_CONTATO, TP_VINCULO_INST)
SELECT 
    'Participante ' || i, 
    'user' || i || '@example.com', 
    CASE WHEN i % 3 = 0 THEN 'ALUNO' WHEN i % 3 = 1 THEN 'COMUNIDADE' ELSE 'SERVIDOR' END
FROM generate_series(1, 5500) s(i);

-- 3. Relationships (11,000 Enrollments)
INSERT INTO RL_INSCRICAO_HISTORICO (ID_PARTICIPANTE, ID_ATIVIDADE, ST_PRESENCA, VL_NOTA_AVALIACAO)
SELECT 
    p.id, 
    (random() * 99)::int + 1, 
    CASE WHEN random() > 0.2 THEN 'PRESENTE' ELSE 'AUSENTE' END,
    (random() * 10)::decimal(4,2)
FROM generate_series(1, 5500) s(i), LATERAL (SELECT i as id) p
CROSS JOIN generate_series(1, 2) g(j);

-- 4. Other Relationships

-- RL_ALOCACAO_INSTRUTOR: ~200 records
INSERT INTO RL_ALOCACAO_INSTRUTOR (ID_ATIVIDADE, ID_INSTRUTOR, VL_CARGA_HORARIA)
SELECT 
    a.id, 
    (random() * 49)::int + 1, 
    (random() * 10 + 2)::int
FROM generate_series(1, 100) s(i), LATERAL (SELECT i as id) a
CROSS JOIN generate_series(1, 2) g(j)
ON CONFLICT DO NOTHING;

-- RL_PATROCINIO_EVENTO: ~50 records
INSERT INTO RL_PATROCINIO_EVENTO (ID_PARCEIRO, ID_ATIVIDADE, VL_APORTE)
SELECT 
    (random() * 19)::int + 1, 
    (random() * 99)::int + 1, 
    (random() * 5000 + 500)::decimal(12,2)
FROM generate_series(1, 50) s(i)
ON CONFLICT DO NOTHING;

-- RL_MEMBRO_PROJETO: ~300 records
INSERT INTO RL_MEMBRO_PROJETO (ID_PARTICIPANTE, ID_PROJETO, TP_PAPEL_ATUACAO)
SELECT 
    (random() * 5499)::int + 1, 
    (random() * 9)::int + 1, 
    CASE WHEN random() > 0.5 THEN 'Bolsista' ELSE 'Voluntário' END
FROM generate_series(1, 300) s(i)
ON CONFLICT DO NOTHING;

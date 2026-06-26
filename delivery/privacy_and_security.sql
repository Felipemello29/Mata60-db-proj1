-- IC Extension Management - Privacy and Security Policies (OCRA)

-- ============================================================================
-- 1. Políticas de Privacidade: Mascaramento de Dados (Data Masking)
-- ============================================================================

-- Criação de uma view segura que mascara o e-mail dos participantes
-- Essa view será utilizada por perfis de analistas de dados
CREATE OR REPLACE VIEW VW_PARTICIPANTE_SEGURO AS
SELECT 
    ID_PARTICIPANTE,
    DS_NOME_PARTICIPANTE,
    -- Mascara o email: exibe apenas os 3 primeiros caracteres e o domínio
    CONCAT(SUBSTR(DS_EMAIL_CONTATO::text, 1, 3), '***@', SPLIT_PART(DS_EMAIL_CONTATO::text, '@', 2)) AS DS_EMAIL_MASCARADO,
    TP_VINCULO_INST
FROM TB_PARTICIPANTE;

-- Criação de uma view segura para notas de feedback (Anonimização)
CREATE OR REPLACE VIEW VW_FEEDBACK_ANONIMO AS
SELECT 
    f.VL_NOTA_SATISFACAO,
    f.DS_COMENTARIO_ABERTO,
    a.DS_TITULO_ATIVIDADE
FROM TB_REGISTRO_FEEDBACK f
JOIN RL_INSCRICAO_HISTORICO i ON f.ID_INSCRICAO = i.ID_INSCRICAO
JOIN TB_ATIVIDADE a ON i.ID_ATIVIDADE = a.ID_ATIVIDADE;


-- ============================================================================
-- 2. Controle de Acesso Baseado em Papéis (RBAC)
-- ============================================================================

-- Criação de papéis se não existirem
DO
$do$
BEGIN
   IF NOT EXISTS (
      SELECT FROM pg_catalog.pg_roles
      WHERE  rolname = 'analista_dados') THEN
      CREATE ROLE analista_dados;
   END IF;
   IF NOT EXISTS (
      SELECT FROM pg_catalog.pg_roles
      WHERE  rolname = 'gestor_extensao') THEN
      CREATE ROLE gestor_extensao;
   END IF;
END
$do$;

-- Revogar acesso direto às tabelas originais contendo dados sensíveis
REVOKE ALL PRIVILEGES ON TB_PARTICIPANTE FROM analista_dados;
REVOKE ALL PRIVILEGES ON TB_REGISTRO_FEEDBACK FROM analista_dados;

-- Conceder permissão apenas nas views seguras e Materialized Views
GRANT SELECT ON VW_PARTICIPANTE_SEGURO TO analista_dados;
GRANT SELECT ON VW_FEEDBACK_ANONIMO TO analista_dados;

GRANT SELECT ON MV_RANKING_PARTICIPANTES TO analista_dados;
GRANT SELECT ON MV_TOP_PROJETOS_CERTIFICADOS TO analista_dados;
GRANT SELECT ON MV_CRESCIMENTO_MENSAL_PROJETOS TO analista_dados;
GRANT SELECT ON MV_ATIVIDADES_ALTA_PARTICIPACAO TO analista_dados;
GRANT SELECT ON MV_PROJETOS_ACIMA_MEDIA_ALUNOS TO analista_dados;
GRANT SELECT ON MV_PARCEIROS_MULTIPLOS_PROJETOS TO analista_dados;
GRANT SELECT ON MV_TOTAL_ATIVIDADES_PROJETO TO analista_dados;
GRANT SELECT ON MV_CARGA_HORARIA_INSTRUTORES TO analista_dados;
GRANT SELECT ON MV_AVALIACAO_MEDIA_ATIVIDADE TO analista_dados;
GRANT SELECT ON MV_PARTICIPANTES_MAIS_ATIVOS TO analista_dados;

-- Conceder permissão total ao gestor
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO gestor_extensao;
GRANT ALL PRIVILEGES ON ALL ROUTINES IN SCHEMA public TO gestor_extensao;

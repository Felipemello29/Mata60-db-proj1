-- IC Extension Management - Privacy and Security Policies (OCRA)

-- ============================================================================
-- 1. PolÃ­ticas de Privacidade: Mascaramento de Dados (Data Masking)
-- ============================================================================

-- CriaÃ§Ã£o de uma view segura que mascara o e-mail dos participantes
-- Essa view serÃ¡ utilizada por perfis de analistas de dados
CREATE OR REPLACE VIEW VW_PARTICIPANTE_SEGURO AS
SELECT 
    ID_PARTICIPANTE,
    DS_NOME_PARTICIPANTE,
    -- Mascara o email: exibe apenas os 3 primeiros caracteres e o domÃ­nio
    CONCAT(SUBSTR(DS_EMAIL_CONTATO::text, 1, 3), '***@', SPLIT_PART(DS_EMAIL_CONTATO::text, '@', 2)) AS DS_EMAIL_MASCARADO,
    TP_VINCULO_INST
FROM tabela_participante;

-- CriaÃ§Ã£o de uma view segura para notas de feedback (AnonimizaÃ§Ã£o)
CREATE OR REPLACE VIEW VW_FEEDBACK_ANONIMO AS
SELECT 
    f.VL_NOTA_SATISFACAO,
    f.DS_COMENTARIO_ABERTO,
    a.DS_TITULO_ATIVIDADE
FROM TB_REGISTRO_FEEDBACK f
JOIN RL_INSCRICAO_HISTORICO i ON f.ID_INSCRICAO = i.ID_INSCRICAO
JOIN TB_ATIVIDADE a ON i.ID_ATIVIDADE = a.ID_ATIVIDADE;


-- ============================================================================
-- 2. Controle de Acesso Baseado em PapÃ©is (RBAC)
-- ============================================================================

-- CriaÃ§Ã£o de papÃ©is se nÃ£o existirem
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

-- Revogar acesso direto Ã s tabelas originais contendo dados sensÃ­veis
REVOKE ALL PRIVILEGES ON tabela_participante FROM analista_dados;
REVOKE ALL PRIVILEGES ON TB_REGISTRO_FEEDBACK FROM analista_dados;

-- Conceder permissÃ£o apenas nas views seguras e Materialized Views
GRANT SELECT ON VW_PARTICIPANTE_SEGURO TO analista_dados;
GRANT SELECT ON VW_FEEDBACK_ANONIMO TO analista_dados;

GRANT SELECT ON VM_INDICE_RETENCAO_PROJETO TO analista_dados;
GRANT SELECT ON VM_GAP_EMISSAO_CERTIFICADO TO analista_dados;
GRANT SELECT ON VM_DISTRIBUICAO_QUARTIS_NOTAS TO analista_dados;
GRANT SELECT ON VM_COBERTURA_INSTRUTORES_PROJETO TO analista_dados;
GRANT SELECT ON VM_COHORT_PRIMEIRA_INSCRICAO TO analista_dados;
GRANT SELECT ON VM_NPS_POR_PROJETO TO analista_dados;
GRANT SELECT ON VM_MATRIZ_VINCULO_PRESENCA TO analista_dados;
GRANT SELECT ON VM_IMPACTO_PATROCINIO_ATIVIDADE TO analista_dados;
GRANT SELECT ON VM_VOLUME_SEMANAL_INSCRICOES TO analista_dados;
GRANT SELECT ON VM_ROI_PARCEIROS TO analista_dados;

-- Conceder permissÃ£o total ao gestor
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO gestor_extensao;
GRANT ALL PRIVILEGES ON ALL ROUTINES IN SCHEMA public TO gestor_extensao;

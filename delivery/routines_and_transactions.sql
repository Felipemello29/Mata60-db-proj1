-- IC Extension Management - Routines and Transactions (OCRA)
-- Procedures and Transactions for Application Screens

-- ============================================================================
-- Tela 1: Cadastro com validação
-- Requisito: 1 comando SELECT, 2 comandos INSERT, 2 comandos UPDATE
-- Objetivo: Validação de novo participante, inserção e atualização de logs
-- Sugestão de Rotina: Stored Procedure
-- ============================================================================
CREATE OR REPLACE PROCEDURE SP_CADASTRAR_PARTICIPANTE_COMPLETO(
    p_nome VARCHAR,
    p_email CITEXT,
    p_vinculo VARCHAR,
    p_projeto_padrao INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_participante_id INT;
    v_email_existe BOOLEAN;
BEGIN
    -- 1. SELECT: Verifica se o e-mail já está cadastrado no sistema
    SELECT EXISTS(SELECT 1 FROM TB_PARTICIPANTE WHERE DS_EMAIL_CONTATO = p_email) INTO v_email_existe;
    
    IF v_email_existe THEN
        RAISE EXCEPTION 'E-mail já cadastrado: %', p_email;
    END IF;

    -- 2. INSERT 1: Cadastra o participante na tabela principal
    INSERT INTO TB_PARTICIPANTE (DS_NOME_PARTICIPANTE, DS_EMAIL_CONTATO, TP_VINCULO_INST)
    VALUES (p_nome, p_email, p_vinculo)
    RETURNING ID_PARTICIPANTE INTO v_participante_id;

    -- 3. INSERT 2: Vincula o participante recém-criado a um projeto de extensão (ex: projeto de boas-vindas/padrão)
    INSERT INTO RL_MEMBRO_PROJETO (ID_PARTICIPANTE, ID_PROJETO, TP_PAPEL_ATUACAO)
    VALUES (v_participante_id, p_projeto_padrao, 'ACOLHIMENTO INICIAL');

    -- 4. UPDATE 1: Atualiza o nome do participante para um formato padronizado (caixa alta)
    UPDATE TB_PARTICIPANTE 
    SET DS_NOME_PARTICIPANTE = UPPER(DS_NOME_PARTICIPANTE)
    WHERE ID_PARTICIPANTE = v_participante_id;

    -- 5. UPDATE 2: Modifica um status ou observação no projeto para fins de auditoria (Update secundário)
    UPDATE TB_PROJETO_EXTENSAO
    SET DS_NOME_PROJETO = DS_NOME_PROJETO || ' (*)'
    WHERE ID_PROJETO = p_projeto_padrao
    AND DS_NOME_PROJETO NOT LIKE '%(*)%';

    COMMIT;
END;
$$;


-- ============================================================================
-- Tela 2: Cadastro ou validação
-- Requisito: 2 comandos SELECT, 1 comando INSERT, 2 comandos UPDATE, 1 comandos DELETE
-- Objetivo: Cadastro de nova Atividade, validação e alocação de instrutor
-- Sugestão de Rotina: Transação / Stored Procedure
-- ============================================================================
CREATE OR REPLACE PROCEDURE SP_GERENCIAR_ATIVIDADE(
    p_titulo VARCHAR,
    p_data DATE,
    p_id_projeto INT,
    p_id_instrutor INT,
    p_carga_horaria INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_projeto_existe BOOLEAN;
    v_instrutor_ativo BOOLEAN;
    v_atividade_id INT;
BEGIN
    -- O bloco BEGIN ... END no PostgreSQL em uma procedure já atua como uma TRANSAÇÃO (commit/rollback automático).

    -- 1. SELECT 1: Validar se o projeto de extensão especificado existe
    SELECT EXISTS(SELECT 1 FROM TB_PROJETO_EXTENSAO WHERE ID_PROJETO = p_id_projeto)
    INTO v_projeto_existe;

    IF NOT v_projeto_existe THEN
        RAISE EXCEPTION 'Projeto de extensão não encontrado (ID: %)!', p_id_projeto;
    END IF;

    -- 2. SELECT 2: Validar se o instrutor está cadastrado
    SELECT EXISTS(SELECT 1 FROM TB_INSTRUTOR WHERE ID_INSTRUTOR = p_id_instrutor)
    INTO v_instrutor_ativo;

    IF NOT v_instrutor_ativo THEN
        RAISE EXCEPTION 'Instrutor não encontrado (ID: %)!', p_id_instrutor;
    END IF;

    -- 3. INSERT: Inserir a nova atividade de extensão
    INSERT INTO TB_ATIVIDADE (DS_TITULO_ATIVIDADE, DS_CONTEUDO_PROG, DT_REALIZACAO, ID_PROJ_VINCULADO)
    VALUES (p_titulo, 'Conteúdo pendente de definição', p_data, p_id_projeto)
    RETURNING ID_ATIVIDADE INTO v_atividade_id;

    -- 4. UPDATE 1: Atualizar o conteúdo programático padrão incluindo referência do instrutor responsável
    UPDATE TB_ATIVIDADE
    SET DS_CONTEUDO_PROG = 'Atividade gerida por ID ' || p_id_instrutor
    WHERE ID_ATIVIDADE = v_atividade_id;

    -- 5. UPDATE 2: Marcar o instrutor como alocado, atualizando sua especialidade ou observação
    UPDATE TB_INSTRUTOR
    SET DS_ESPECIALIDADE = DS_ESPECIALIDADE || ' [Ativo]'
    WHERE ID_INSTRUTOR = p_id_instrutor
    AND DS_ESPECIALIDADE NOT LIKE '%[Ativo]%';

    -- 6. DELETE: Excluir atividades antigas "fantasma" do mesmo projeto que não possuam inscritos
    -- (Limpeza de sujeira baseada no contexto do sistema de informação)
    DELETE FROM TB_ATIVIDADE 
    WHERE ID_PROJ_VINCULADO = p_id_projeto 
    AND ID_ATIVIDADE NOT IN (SELECT ID_ATIVIDADE FROM RL_INSCRICAO_HISTORICO)
    AND ID_ATIVIDADE != v_atividade_id;
    
    -- Transação é confirmada (COMMITTED) automaticamente ao fim da Procedure sem exceções.
END;
$$;

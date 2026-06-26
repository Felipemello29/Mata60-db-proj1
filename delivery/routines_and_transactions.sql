-- IC Extension Management - Routines and Transactions (OCRA)
-- Procedures and Transactions for Application Screens

-- ============================================================================
-- Tela 1: Cadastro com validaÃ§Ã£o
-- Requisito: 1 comando SELECT, 2 comandos INSERT, 2 comandos UPDATE
-- Objetivo: ValidaÃ§Ã£o de novo participante, inserÃ§Ã£o e atualizaÃ§Ã£o de logs
-- SugestÃ£o de Rotina: Stored Procedure
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
    -- 1. SELECT: Verifica se o e-mail jÃ¡ estÃ¡ cadastrado no sistema
    SELECT EXISTS(SELECT 1 FROM tabela_participante WHERE DS_EMAIL_CONTATO = p_email) INTO v_email_existe;
    
    IF v_email_existe THEN
        RAISE EXCEPTION 'E-mail jÃ¡ cadastrado: %', p_email;
    END IF;

    -- 2. INSERT 1: Cadastra o participante na tabela principal
    INSERT INTO tabela_participante (DS_NOME_PARTICIPANTE, DS_EMAIL_CONTATO, TP_VINCULO_INST)
    VALUES (p_nome, p_email, p_vinculo)
    RETURNING ID_PARTICIPANTE INTO v_participante_id;

    -- 3. INSERT 2: Vincula o participante recÃ©m-criado a um projeto de extensÃ£o (ex: projeto de boas-vindas/padrÃ£o)
    INSERT INTO RL_MEMBRO_PROJETO (ID_PARTICIPANTE, ID_PROJETO, TP_PAPEL_ATUACAO)
    VALUES (v_participante_id, p_projeto_padrao, 'ACOLHIMENTO INICIAL');

    -- 4. UPDATE 1: Atualiza o nome do participante para um formato padronizado (caixa alta)
    UPDATE tabela_participante 
    SET DS_NOME_PARTICIPANTE = UPPER(DS_NOME_PARTICIPANTE)
    WHERE ID_PARTICIPANTE = v_participante_id;

    -- 5. UPDATE 2: Modifica um status ou observaÃ§Ã£o no projeto para fins de auditoria (Update secundÃ¡rio)
    UPDATE tabela_projeto_extensao
    SET DS_NOME_PROJETO = DS_NOME_PROJETO || ' (*)'
    WHERE ID_PROJETO = p_projeto_padrao
    AND DS_NOME_PROJETO NOT LIKE '%(*)%';

    COMMIT;
END;
$$;


-- ============================================================================
-- Tela 2: Cadastro ou validaÃ§Ã£o
-- Requisito: 2 comandos SELECT, 1 comando INSERT, 2 comandos UPDATE, 1 comandos DELETE
-- Objetivo: Cadastro de nova Atividade, validaÃ§Ã£o e alocaÃ§Ã£o de instrutor
-- SugestÃ£o de Rotina: TransaÃ§Ã£o / Stored Procedure
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
    -- O bloco BEGIN ... END no PostgreSQL em uma procedure jÃ¡ atua como uma TRANSAÃ‡ÃƒO (commit/rollback automÃ¡tico).

    -- 1. SELECT 1: Validar se o projeto de extensÃ£o especificado existe
    SELECT EXISTS(SELECT 1 FROM tabela_projeto_extensao WHERE ID_PROJETO = p_id_projeto)
    INTO v_projeto_existe;

    IF NOT v_projeto_existe THEN
        RAISE EXCEPTION 'Projeto de extensÃ£o nÃ£o encontrado (ID: %)!', p_id_projeto;
    END IF;

    -- 2. SELECT 2: Validar se o instrutor estÃ¡ cadastrado
    SELECT EXISTS(SELECT 1 FROM TB_INSTRUTOR WHERE ID_INSTRUTOR = p_id_instrutor)
    INTO v_instrutor_ativo;

    IF NOT v_instrutor_ativo THEN
        RAISE EXCEPTION 'Instrutor nÃ£o encontrado (ID: %)!', p_id_instrutor;
    END IF;

    -- 3. INSERT: Inserir a nova atividade de extensÃ£o
    INSERT INTO TB_ATIVIDADE (DS_TITULO_ATIVIDADE, DS_CONTEUDO_PROG, DT_REALIZACAO, ID_PROJ_VINCULADO)
    VALUES (p_titulo, 'ConteÃºdo pendente de definiÃ§Ã£o', p_data, p_id_projeto)
    RETURNING ID_ATIVIDADE INTO v_atividade_id;

    -- 4. UPDATE 1: Atualizar o conteÃºdo programÃ¡tico padrÃ£o incluindo referÃªncia do instrutor responsÃ¡vel
    UPDATE TB_ATIVIDADE
    SET DS_CONTEUDO_PROG = 'Atividade gerida por ID ' || p_id_instrutor
    WHERE ID_ATIVIDADE = v_atividade_id;

    -- 5. UPDATE 2: Marcar o instrutor como alocado, atualizando sua especialidade ou observaÃ§Ã£o
    UPDATE TB_INSTRUTOR
    SET DS_ESPECIALIDADE = DS_ESPECIALIDADE || ' [Ativo]'
    WHERE ID_INSTRUTOR = p_id_instrutor
    AND DS_ESPECIALIDADE NOT LIKE '%[Ativo]%';

    -- 6. DELETE: Excluir atividades antigas "fantasma" do mesmo projeto que nÃ£o possuam inscritos
    -- (Limpeza de sujeira baseada no contexto do sistema de informaÃ§Ã£o)
    DELETE FROM TB_ATIVIDADE 
    WHERE ID_PROJ_VINCULADO = p_id_projeto 
    AND ID_ATIVIDADE NOT IN (SELECT ID_ATIVIDADE FROM RL_INSCRICAO_HISTORICO)
    AND ID_ATIVIDADE != v_atividade_id;
    
    -- TransaÃ§Ã£o Ã© confirmada (COMMITTED) automaticamente ao fim da Procedure sem exceÃ§Ãµes.
END;
$$;

-- ============================================================================
-- TransaÃ§Ãµes ExplÃ­citas
-- ============================================================================

-- Transaction 1: Inscricao com rollback parcial
CREATE OR REPLACE PROCEDURE SP_INSCREVER_COM_VALIDACAO(
    p_id_participante INT,
    p_id_atividade INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_vagas INT;
BEGIN
    -- Savepoint before critical section
    SAVEPOINT antes_inscricao;

    -- Insert enrollment
    INSERT INTO RL_INSCRICAO_HISTORICO (ID_PARTICIPANTE, ID_ATIVIDADE, ST_PRESENCA)
    VALUES (p_id_participante, p_id_atividade, 'PENDENTE');

    -- Check capacity (hypothetical validation)
    SELECT COUNT(*) INTO v_vagas
    FROM RL_INSCRICAO_HISTORICO
    WHERE ID_ATIVIDADE = p_id_atividade;

    IF v_vagas > 100 THEN
        -- Partial rollback: undo only the enrollment
        ROLLBACK TO SAVEPOINT antes_inscricao;
        RAISE NOTICE 'Capacidade excedida. Inscricao revertida.';
    ELSE
        -- Release savepoint, keep the insert
        RELEASE SAVEPOINT antes_inscricao;
        RAISE NOTICE 'Inscricao confirmada.';
    END IF;

    COMMIT;
END;
$$;

-- Transaction 2: Transferencia atomica entre projetos
CREATE OR REPLACE PROCEDURE SP_TRANSFERIR_PARTICIPANTE(
    p_id_participante INT,
    p_id_projeto_origem INT,
    p_id_projeto_destino INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    SAVEPOINT antes_transferencia;

    -- Remove from origin
    DELETE FROM RL_MEMBRO_PROJETO
    WHERE ID_PARTICIPANTE = p_id_participante
    AND ID_PROJETO = p_id_projeto_origem;

    IF NOT FOUND THEN
        ROLLBACK TO SAVEPOINT antes_transferencia;
        RAISE EXCEPTION 'Participante nao pertence ao projeto de origem.';
    END IF;

    -- Add to destination
    INSERT INTO RL_MEMBRO_PROJETO (ID_PARTICIPANTE, ID_PROJETO, TP_PAPEL_ATUACAO)
    VALUES (p_id_participante, p_id_projeto_destino, 'TRANSFERIDO');

    RELEASE SAVEPOINT antes_transferencia;
    COMMIT;
END;
$$;

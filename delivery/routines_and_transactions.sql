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
    SELECT EXISTS(SELECT 1 FROM tabela_participante WHERE DS_EMAIL_CONTATO = p_email) INTO v_email_existe;
    
    IF v_email_existe THEN
        RAISE EXCEPTION 'E-mail já cadastrado: %', p_email;
    END IF;

    -- 2. INSERT 1: Cadastra o participante na tabela principal
    INSERT INTO tabela_participante (DS_NOME_PARTICIPANTE, DS_EMAIL_CONTATO, TP_VINCULO_INST)
    VALUES (p_nome, p_email, p_vinculo)
    RETURNING ID_PARTICIPANTE INTO v_participante_id;

    -- 3. INSERT 2: Vincula o participante recém-criado a um projeto de extensão (ex: projeto de boas-vindas/padrão)
    INSERT INTO RL_MEMBRO_PROJETO (ID_PARTICIPANTE, ID_PROJETO, TP_PAPEL_ATUACAO)
    VALUES (v_participante_id, p_projeto_padrao, 'ACOLHIMENTO INICIAL');

    -- 4. UPDATE 1: Atualiza o nome do participante para um formato padronizado (caixa alta)
    UPDATE tabela_participante 
    SET DS_NOME_PARTICIPANTE = UPPER(DS_NOME_PARTICIPANTE)
    WHERE ID_PARTICIPANTE = v_participante_id;

    -- 5. UPDATE 2: Modifica um status ou observação no projeto para fins de auditoria (Update secundário)
    UPDATE tabela_projeto_extensao
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
    SELECT EXISTS(SELECT 1 FROM tabela_projeto_extensao WHERE ID_PROJETO = p_id_projeto)
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

-- ============================================================================
-- Transações Explícitas
-- Implementação corrigida: uso de blocos BEGIN ... EXCEPTION ... END
-- que geram savepoints implícitos gerenciados internamente pelo PL/pgSQL.
-- Referência: https://www.postgresql.org/docs/current/plpgsql-control-structures.html#PLPGSQL-ERROR-TRAPPING
-- ============================================================================

-- Transaction 1: Inscrição com rollback parcial via exception handler
-- Técnica: O bloco BEGIN interno cria um savepoint implícito. Se RAISE EXCEPTION
-- é executado dentro desse bloco, o PostgreSQL automaticamente reverte ao savepoint
-- e desvia o fluxo para o handler EXCEPTION, sem necessidade de SAVEPOINT/ROLLBACK
-- TO SAVEPOINT explícitos (que são proibidos no PL/pgSQL).
CREATE OR REPLACE PROCEDURE SP_INSCREVER_COM_VALIDACAO(
    p_id_participante INT,
    p_id_atividade INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_vagas INT;
    v_atividade_existe BOOLEAN;
BEGIN
    -- Validação prévia: verificar se a atividade existe
    SELECT EXISTS(SELECT 1 FROM TB_ATIVIDADE WHERE ID_ATIVIDADE = p_id_atividade)
    INTO v_atividade_existe;

    IF NOT v_atividade_existe THEN
        RAISE EXCEPTION 'Atividade não encontrada (ID: %)', p_id_atividade;
    END IF;

    -- Bloco com savepoint implícito: BEGIN ... EXCEPTION ... END
    -- Se qualquer erro ocorrer dentro deste bloco, as alterações feitas DENTRO
    -- dele são revertidas automaticamente pelo PostgreSQL (rollback parcial),
    -- mas as operações FORA do bloco (antes ou depois) permanecem intactas.
    BEGIN
        -- INSERT: Registrar a inscrição com status PENDENTE
        INSERT INTO RL_INSCRICAO_HISTORICO (ID_PARTICIPANTE, ID_ATIVIDADE, ST_PRESENCA)
        VALUES (p_id_participante, p_id_atividade, 'PENDENTE');

        -- SELECT: Verificar a capacidade máxima da atividade
        SELECT COUNT(*) INTO v_vagas
        FROM RL_INSCRICAO_HISTORICO
        WHERE ID_ATIVIDADE = p_id_atividade;

        -- Regra de negócio: máximo de 100 inscritos por atividade
        IF v_vagas > 100 THEN
            -- RAISE EXCEPTION aciona o rollback implícito do sub-bloco:
            -- o INSERT acima é revertido automaticamente pelo PostgreSQL
            RAISE EXCEPTION 'Capacidade excedida para a atividade %. Limite: 100, Atual: %',
                p_id_atividade, v_vagas;
        END IF;

        RAISE NOTICE 'Inscrição do participante % na atividade % confirmada com sucesso.',
            p_id_participante, p_id_atividade;

    EXCEPTION
        WHEN unique_violation THEN
            -- Participante já inscrito nesta atividade (constraint UK_INSCRICAO_UNICA)
            RAISE NOTICE 'Participante % já está inscrito na atividade %. Nenhuma alteração realizada.',
                p_id_participante, p_id_atividade;
        WHEN OTHERS THEN
            -- Qualquer outro erro (inclui a exceção de capacidade acima)
            -- O INSERT é automaticamente revertido pelo handler do sub-bloco
            RAISE NOTICE 'Inscrição revertida: %', SQLERRM;
    END;

    COMMIT;
END;
$$;

-- Transaction 2: Transferência atômica entre projetos com proteção via exception handler
-- Técnica: O bloco BEGIN interno garante atomicidade da operação de transferência.
-- Se o DELETE ou o INSERT falharem, o savepoint implícito reverte ambas as operações,
-- garantindo que o participante nunca fique "no limbo" (sem projeto algum).
CREATE OR REPLACE PROCEDURE SP_TRANSFERIR_PARTICIPANTE(
    p_id_participante INT,
    p_id_projeto_origem INT,
    p_id_projeto_destino INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_nome_participante VARCHAR;
    v_projeto_destino_existe BOOLEAN;
BEGIN
    -- Validação prévia: verificar se o projeto de destino existe
    SELECT EXISTS(SELECT 1 FROM tabela_projeto_extensao WHERE ID_PROJETO = p_id_projeto_destino)
    INTO v_projeto_destino_existe;

    IF NOT v_projeto_destino_existe THEN
        RAISE EXCEPTION 'Projeto de destino não encontrado (ID: %)', p_id_projeto_destino;
    END IF;

    -- Recuperar nome do participante para mensagens informativas
    SELECT DS_NOME_PARTICIPANTE INTO v_nome_participante
    FROM tabela_participante
    WHERE ID_PARTICIPANTE = p_id_participante;

    IF v_nome_participante IS NULL THEN
        RAISE EXCEPTION 'Participante não encontrado (ID: %)', p_id_participante;
    END IF;

    -- Bloco com savepoint implícito: garante atomicidade da transferência
    BEGIN
        -- DELETE: Remover vínculo do projeto de origem
        DELETE FROM RL_MEMBRO_PROJETO
        WHERE ID_PARTICIPANTE = p_id_participante
        AND ID_PROJETO = p_id_projeto_origem;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Participante "%" não pertence ao projeto de origem (ID: %).',
                v_nome_participante, p_id_projeto_origem;
        END IF;

        -- INSERT: Vincular ao projeto de destino
        INSERT INTO RL_MEMBRO_PROJETO (ID_PARTICIPANTE, ID_PROJETO, TP_PAPEL_ATUACAO)
        VALUES (p_id_participante, p_id_projeto_destino, 'TRANSFERIDO');

        RAISE NOTICE 'Transferência concluída: "%" movido do projeto % para o projeto %.',
            v_nome_participante, p_id_projeto_origem, p_id_projeto_destino;

    EXCEPTION
        WHEN unique_violation THEN
            -- Participante já é membro do projeto de destino
            RAISE NOTICE 'Falha: "%" já é membro do projeto de destino (ID: %). Transferência revertida.',
                v_nome_participante, p_id_projeto_destino;
        WHEN OTHERS THEN
            -- Qualquer erro: DELETE e INSERT são revertidos pelo savepoint implícito
            RAISE NOTICE 'Transferência revertida para "%": %', v_nome_participante, SQLERRM;
    END;

    COMMIT;
END;
$$;

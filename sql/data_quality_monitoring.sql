-- 1.1: Tabela para registrar execuções de validação
CREATE TABLE tb_validacao_execucoes (
    id_validacao INT PRIMARY KEY IDENTITY(1,1),
    data_execucao DATETIME DEFAULT GETDATE(),
    tabela_validada VARCHAR(100),
    total_registros INT,
    registros_validos INT,
    registros_invalidos INT,
    percentual_sucesso DECIMAL(5,2),
    tempo_execucao_segundos INT,
    usuario_execucao VARCHAR(100),
    status VARCHAR(20) -- 'SUCESSO', 'AVISO', 'ERRO'
);

-- 1.2: Tabela para registrar erros de validação
CREATE TABLE tb_erros_validacao (
    id_erro INT PRIMARY KEY IDENTITY(1,1),
    id_validacao INT FOREIGN KEY REFERENCES tb_validacao_execucoes(id_validacao),
    id_cliente INT,
    tabela_origem VARCHAR(100),
    coluna_erro VARCHAR(100),
    valor_encontrado VARCHAR(500),
    tipo_erro VARCHAR(100), -- 'NULO_NAO_PERMITIDO', 'TIPO_INVALIDO', etc
    descricao_erro NVARCHAR(MAX),
    data_descoberta DATETIME DEFAULT GETDATE()
);

-- 1.3: Tabela para rastrear valores atípicos
CREATE TABLE tb_valores_atipicos (
    id_atipico INT PRIMARY KEY IDENTITY(1,1),
    id_cliente INT,
    coluna_afetada VARCHAR(100),
    valor_encontrado DECIMAL(15,2),
    valor_esperado_media DECIMAL(15,2),
    valor_esperado_mediana DECIMAL(15,2),
    desvios_padrao DECIMAL(5,2),
    data_descoberta DATETIME DEFAULT GETDATE(),
    investigado BIT DEFAULT 0
);

-- ============================================================================
-- SECTION 2: PROCEDURES DE VALIDAÇÃO
-- ============================================================================

-- 2.1: Procedure para validar integridade referencial
CREATE PROCEDURE sp_validar_integridade_referencial
    @tabela VARCHAR(100) = 'clientes_seguros'
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @dt_inicio DATETIME = GETDATE();
    DECLARE @total_registros INT;
    DECLARE @registros_invalidos INT = 0;
    
    -- Conta total de registros
    SELECT @total_registros = COUNT(*) FROM clientes_seguros;
    
    -- Valida chaves primárias não nulas
    SELECT @registros_invalidos = COUNT(*)
    FROM clientes_seguros
    WHERE id_cliente IS NULL;
    
    IF @registros_invalidos > 0
    BEGIN
        INSERT INTO tb_erros_validacao 
        (tabela_origem, coluna_erro, tipo_erro, descricao_erro)
        VALUES 
        (@tabela, 'id_cliente', 'CHAVE_PRIMARIA_NULA', 
         'Encontrados ' + CAST(@registros_invalidos AS VARCHAR) + ' registros com id_cliente nulo');
    END;
    
    -- Valida campos obrigatórios
    SELECT @registros_invalidos = COUNT(*)
    FROM clientes_seguros
    WHERE nome_cliente IS NULL OR TRIM(nome_cliente) = '';
    
    IF @registros_invalidos > 0
    BEGIN
        INSERT INTO tb_erros_validacao 
        (tabela_origem, coluna_erro, tipo_erro, descricao_erro)
        VALUES 
        (@tabela, 'nome_cliente', 'CAMPO_OBRIGATORIO_VAZIO', 
         'Encontrados ' + CAST(@registros_invalidos AS VARCHAR) + ' registros com nome_cliente vazio');
    END;
    
    -- Registra execução
    INSERT INTO tb_validacao_execucoes 
    (tabela_validada, total_registros, registros_invalidos, 
     percentual_sucesso, tempo_execucao_segundos, usuario_execucao, status)
    VALUES 
    (@tabela, @total_registros, @registros_invalidos,
     ROUND(100.0 * (@total_registros - @registros_invalidos) / @total_registros, 2),
     DATEDIFF(SECOND, @dt_inicio, GETDATE()),
     SYSTEM_USER,
     CASE WHEN @registros_invalidos = 0 THEN 'SUCESSO' 
          WHEN @registros_invalidos < @total_registros * 0.05 THEN 'AVISO' 
          ELSE 'ERRO' END);
END;

-- 2.2: Procedure para validar tipos de dados
CREATE PROCEDURE sp_validar_tipos_dados
    @tabela VARCHAR(100) = 'clientes_seguros'
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Valida que valor_premio é positivo
    INSERT INTO tb_erros_validacao 
    (tabela_origem, coluna_erro, tipo_erro, descricao_erro, valor_encontrado)
    SELECT 
        @tabela,
        'valor_premio',
        'VALOR_NEGATIVO_INVALIDO',
        'Prêmio com valor negativo encontrado',
        CAST(valor_premio AS VARCHAR)
    FROM clientes_seguros
    WHERE valor_premio <= 0;
    
    -- Valida que valor_cobertura é positivo
    INSERT INTO tb_erros_validacao 
    (tabela_origem, coluna_erro, tipo_erro, descricao_erro, valor_encontrado)
    SELECT 
        @tabela,
        'valor_cobertura',
        'VALOR_NEGATIVO_INVALIDO',
        'Cobertura com valor negativo encontrado',
        CAST(valor_cobertura AS VARCHAR)
    FROM clientes_seguros
    WHERE valor_cobertura <= 0;
    
    -- Valida que idade está em intervalo razoável
    INSERT INTO tb_erros_validacao 
    (tabela_origem, coluna_erro, tipo_erro, descricao_erro, valor_encontrado)
    SELECT 
        @tabela,
        'idade',
        'VALOR_FORA_INTERVALO',
        'Idade fora do intervalo aceitável (18-120)',
        CAST(idade AS VARCHAR)
    FROM clientes_seguros
    WHERE idade < 18 OR idade > 120;
    
    -- Valida CPF (não é números apenas)
    INSERT INTO tb_erros_validacao 
    (tabela_origem, coluna_erro, tipo_erro, descricao_erro, valor_encontrado)
    SELECT 
        @tabela,
        'cpf',
        'FORMATO_CPF_INVALIDO',
        'CPF não contém apenas números',
        cpf
    FROM clientes_seguros
    WHERE NOT (ISNUMERIC(cpf) = 1 AND LEN(cpf) = 11);
    
    PRINT 'Validação de tipos de dados concluída';
END;

-- 2.3: Procedure para detectar duplicatas
CREATE PROCEDURE sp_detectar_duplicatas
    @tabela VARCHAR(100) = 'clientes_seguros'
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Detecta CPFs duplicados
    SELECT 
        cpf,
        COUNT(*) AS quantidade_registros,
        STRING_AGG(CAST(id_cliente AS VARCHAR), ',') AS ids_clientes
    FROM clientes_seguros
    WHERE cpf IS NOT NULL
    GROUP BY cpf
    HAVING COUNT(*) > 1;
    
    -- Detecta nomes duplicados com mesma data de nascimento
    SELECT 
        nome_cliente,
        data_nascimento,
        COUNT(*) AS quantidade_registros
    FROM clientes_seguros
    WHERE data_nascimento IS NOT NULL
    GROUP BY nome_cliente, data_nascimento
    HAVING COUNT(*) > 1;
    
    PRINT 'Detecção de duplicatas concluída';
END;

-- ============================================================================
-- SECTION 3: PROCEDURES DE ANÁLISE DE ANOMALIAS
-- ============================================================================

-- 3.1: Procedure para detectar outliers em valores numéricos
CREATE PROCEDURE sp_detectar_outliers
    @coluna VARCHAR(50) = 'valor_premio',
    @desvios_padrao DECIMAL(5,2) = 3.0
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Calcula estatísticas
    DECLARE @media DECIMAL(15,2);
    DECLARE @desvio_padrao DECIMAL(15,2);
    
    SELECT 
        @media = AVG(valor_premio),
        @desvio_padrao = STDEV(valor_premio)
    FROM clientes_seguros
    WHERE status_contrato = 'ATIVO';
    
    -- Identifica outliers
    INSERT INTO tb_valores_atipicos 
    (id_cliente, coluna_afetada, valor_encontrado, valor_esperado_media, 
     valor_esperado_mediana, desvios_padrao)
    SELECT 
        id_cliente,
        'valor_premio',
        valor_premio,
        @media,
        (SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY valor_premio) 
         FROM clientes_seguros WHERE status_contrato = 'ATIVO'),
        ABS(valor_premio - @media) / NULLIF(@desvio_padrao, 0)
    FROM clientes_seguros
    WHERE ABS(valor_premio - @media) / NULLIF(@desvio_padrao, 0) > @desvios_padrao
    AND status_contrato = 'ATIVO';
    
    -- Retorna outliers detectados
    SELECT 
        id_cliente,
        coluna_afetada,
        valor_encontrado,
        valor_esperado_media,
        desvios_padrao,
        CASE 
            WHEN desvios_padrao > 4 THEN 'EXTREMO'
            WHEN desvios_padrao > 3 THEN 'ALTO'
            ELSE 'MODERADO'
        END AS severidade
    FROM tb_valores_atipicos
    WHERE investigado = 0
    ORDER BY desvios_padrao DESC;
    
    PRINT 'Análise de outliers concluída';
END;

-- 3.2: Procedure para análise de distribuição
CREATE PROCEDURE sp_analisar_distribuicao_valores
    @coluna VARCHAR(50) = 'valor_premio'
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        tipo_seguro,
        COUNT(*) AS frequencia,
        MIN(valor_premio) AS minimo,
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY valor_premio) AS q1,
        PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY valor_premio) AS mediana,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY valor_premio) AS q3,
        MAX(valor_premio) AS maximo,
        AVG(valor_premio) AS media,
        STDEV(valor_premio) AS desvio_padrao,
        ROUND(AVG(valor_premio) / 
              SUM(AVG(valor_premio)) OVER () * 100, 2) AS percentual_da_receita
    FROM clientes_seguros
    WHERE status_contrato = 'ATIVO'
    GROUP BY tipo_seguro;
END;

-- ============================================================================
-- SECTION 4: VIEWS DE MONITORAMENTO
-- ============================================================================

-- 4.1: View para histórico de validações
CREATE VIEW vw_historico_validacoes AS
SELECT 
    data_execucao,
    tabela_validada,
    total_registros,
    registros_invalidos,
    percentual_sucesso,
    CASE 
        WHEN status = 'SUCESSO' THEN 'Verde'
        WHEN status = 'AVISO' THEN 'Amarelo'
        ELSE 'Vermelho'
    END AS nivel_alerta,
    usuario_execucao
FROM tb_validacao_execucoes
ORDER BY data_execucao DESC;

-- 4.2: View para erros mais comuns
CREATE VIEW vw_erros_mais_comuns AS
SELECT TOP 10
    tipo_erro,
    COUNT(*) AS total_ocorrencias,
    COUNT(DISTINCT tabela_origem) AS tabelas_afetadas,
    COUNT(DISTINCT id_cliente) AS clientes_afetados,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM tb_erros_validacao), 2) AS percentual
FROM tb_erros_validacao
GROUP BY tipo_erro
ORDER BY total_ocorrencias DESC;

-- 4.3: View para valores atípicos ainda não investigados
CREATE VIEW vw_atipicos_nao_investigados AS
SELECT 
    id_atipico,
    id_cliente,
    coluna_afetada,
    valor_encontrado,
    valor_esperado_media,
    ROUND(desvios_padrao, 2) AS desvios_padrao,
    data_descoberta,
    DATEDIFF(DAY, data_descoberta, GETDATE()) AS dias_sem_investigacao
FROM tb_valores_atipicos
WHERE investigado = 0
ORDER BY desvios_padrao DESC;

-- ============================================================================
-- SECTION 5: JOBS DE MONITORAMENTO AUTOMÁTICO
-- ============================================================================

-- 5.1: Script para executar validações diárias
CREATE PROCEDURE sp_validacao_diaria_completa
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRANSACTION;
    
    BEGIN TRY
        -- Limpa dados antigos (mantém 90 dias)
        DELETE FROM tb_erros_validacao 
        WHERE data_descoberta < DATEADD(DAY, -90, GETDATE());
        
        DELETE FROM tb_validacao_execucoes 
        WHERE data_execucao < DATEADD(DAY, -90, GETDATE());
        
        -- Executa validações
        EXEC sp_validar_integridade_referencial;
        EXEC sp_validar_tipos_dados;
        EXEC sp_validar_integridade_referencial;
        EXEC sp_detectar_outliers @desvios_padrao = 2.5;
        
        COMMIT TRANSACTION;
        
        -- Log de sucesso
        PRINT 'Validação diária concluída com sucesso em ' + 
              FORMAT(GETDATE(), 'dd/MM/yyyy HH:mm:ss');
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        
        -- Log de erro
        PRINT 'ERRO na validação diária: ' + ERROR_MESSAGE();
        
        THROW;
    END CATCH;
END;

-- 5.2: Query para criar job no SQL Agent (comentado - executar manualmente)
/*
EXEC msdb.dbo.sp_add_job
    @job_name = 'Validacao_Diaria_Dados',
    @enabled = 1;

EXEC msdb.dbo.sp_add_jobstep
    @job_name = 'Validacao_Diaria_Dados',
    @step_name = 'Executar_Validacoes',
    @command = 'EXEC sp_validacao_diaria_completa',
    @database_name = 'nome_database';

EXEC msdb.dbo.sp_add_schedule
    @schedule_name = 'Diario_2AM',
    @freq_type = 4,
    @freq_interval = 1,
    @active_start_time = 020000;

EXEC msdb.dbo.sp_attach_schedule
    @job_name = 'Validacao_Diaria_Dados',
    @schedule_name = 'Diario_2AM';
*/

-- ============================================================================
-- SECTION 6: RELATÓRIOS DE QUALIDADE
-- ============================================================================

-- 6.1: Procedure para gerar scorecard de qualidade
CREATE PROCEDURE sp_gerar_scorecard_qualidade
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        'Qualidade de Dados' AS categoria,
        'Integridade Referencial' AS metrica,
        ROUND(100.0 - (
            SELECT TOP 1 percentual_sucesso FROM tb_validacao_execucoes 
            ORDER BY data_execucao DESC
        ), 2) AS valor_pct,
        CASE 
            WHEN ROUND(100.0 - (
                SELECT TOP 1 percentual_sucesso FROM tb_validacao_execucoes 
                ORDER BY data_execucao DESC
            ), 2) < 1 THEN 'EXCELENTE'
            WHEN ROUND(100.0 - (
                SELECT TOP 1 percentual_sucesso FROM tb_validacao_execucoes 
                ORDER BY data_execucao DESC
            ), 2) < 5 THEN 'BOM'
            ELSE 'PRECISA_MELHORIA'
        END AS status
    
    UNION ALL
    
    SELECT 
        'Qualidade de Dados' AS categoria,
        'Valores Atípicos Não Investigados' AS metrica,
        (SELECT COUNT(*) FROM tb_valores_atipicos WHERE investigado = 0) AS valor_pct,
        CASE 
            WHEN (SELECT COUNT(*) FROM tb_valores_atipicos WHERE investigado = 0) = 0 THEN 'EXCELENTE'
            WHEN (SELECT COUNT(*) FROM tb_valores_atipicos WHERE investigado = 0) < 10 THEN 'BOM'
            ELSE 'PRECISA_MELHORIA'
        END AS status;
END;

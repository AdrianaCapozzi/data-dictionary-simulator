-- 1.1: Procedure para análise de cohorte de clientes
CREATE PROCEDURE sp_analise_coorte_clientes
    @data_inicio DATE = NULL,
    @data_fim DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @dt_inicio DATE = ISNULL(@data_inicio, DATEADD(YEAR, -5, GETDATE()));
    DECLARE @dt_fim DATE = ISNULL(@data_fim, GETDATE());
    
    -- Seleciona coorte e calcula retenção
    SELECT 
        YEAR(data_contratacao) AS ano_coorte,
        MONTH(data_contratacao) AS mes_coorte,
        COUNT(DISTINCT id_cliente) AS clientes_adquiridos,
        COUNT(DISTINCT CASE WHEN status_contrato = 'ATIVO' THEN id_cliente END) AS clientes_ativos,
        COUNT(DISTINCT CASE WHEN status_contrato = 'CANCELADO' THEN id_cliente END) AS clientes_cancelados,
        ROUND(
            100.0 * COUNT(DISTINCT CASE WHEN status_contrato = 'ATIVO' THEN id_cliente END) / 
            COUNT(DISTINCT id_cliente), 
            2
        ) AS taxa_retencao_pct,
        ROUND(AVG(valor_premio), 2) AS premio_medio_coorte,
        ROUND(SUM(CASE WHEN status_contrato = 'ATIVO' THEN valor_premio ELSE 0 END), 2) AS revenue_coorte_ativa
    FROM clientes_seguros
    WHERE data_contratacao BETWEEN @dt_inicio AND @dt_fim
    GROUP BY YEAR(data_contratacao), MONTH(data_contratacao)
    ORDER BY ano_coorte DESC, mes_coorte DESC;
END;

-- 1.2: Procedure para detecção de anomalias em prêmios
CREATE PROCEDURE sp_detectar_anomalias_premios
    @desvio_padrao_limite DECIMAL(5,2) = 2.5
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Calcula estatísticas base
    WITH premio_stats AS (
        SELECT 
            tipo_seguro,
            AVG(valor_premio) AS media_premio,
            STDEV(valor_premio) AS desvio_premio,
            MIN(valor_premio) AS min_premio,
            MAX(valor_premio) AS max_premio,
            COUNT(*) AS quantidade
        FROM clientes_seguros
        WHERE status_contrato = 'ATIVO'
        GROUP BY tipo_seguro
    )
    -- Identifica valores anômalos
    SELECT 
        cs.id_cliente,
        cs.nome_cliente,
        cs.tipo_seguro,
        cs.valor_premio,
        ps.media_premio,
        ps.desvio_premio,
        ROUND(
            ABS(cs.valor_premio - ps.media_premio) / NULLIF(ps.desvio_premio, 0),
            2
        ) AS desvios_padrao,
        CASE 
            WHEN ABS(cs.valor_premio - ps.media_premio) / NULLIF(ps.desvio_premio, 0) > @desvio_padrao_limite 
            THEN 'ANOMALIA' 
            ELSE 'NORMAL' 
        END AS classificacao,
        GETDATE() AS data_deteccao
    FROM clientes_seguros cs
    JOIN premio_stats ps ON cs.tipo_seguro = ps.tipo_seguro
    WHERE ABS(cs.valor_premio - ps.media_premio) / NULLIF(ps.desvio_premio, 0) > @desvio_padrao_limite
    ORDER BY desvios_padrao DESC;
END;

-- 1.3: Procedure para segmentação de clientes
CREATE PROCEDURE sp_segmentar_clientes
    @percentil_tier1 DECIMAL(3,2) = 0.75,
    @percentil_tier2 DECIMAL(3,2) = 0.50,
    @percentil_tier3 DECIMAL(3,2) = 0.25
AS
BEGIN
    SET NOCOUNT ON;
    
    WITH cliente_valor AS (
        SELECT 
            id_cliente,
            nome_cliente,
            tipo_seguro,
            valor_premio,
            DATEDIFF(MONTH, data_contratacao, GETDATE()) AS meses_cliente,
            COUNT(*) OVER (PARTITION BY tipo_seguro) AS total_clientes_seguro,
            ROW_NUMBER() OVER (PARTITION BY tipo_seguro ORDER BY valor_premio DESC) AS rank_premium
        FROM clientes_seguros
        WHERE status_contrato = 'ATIVO'
    )
    SELECT 
        id_cliente,
        nome_cliente,
        tipo_seguro,
        valor_premio,
        meses_cliente,
        CASE 
            WHEN rank_premium <= CEILING(total_clientes_seguro * @percentil_tier1)
            THEN 'VIP'
            WHEN rank_premium <= CEILING(total_clientes_seguro * @percentil_tier2)
            THEN 'PREMIUM'
            WHEN rank_premium <= CEILING(total_clientes_seguro * @percentil_tier3)
            THEN 'STANDARD'
            ELSE 'ECONOMICO'
        END AS segmento
    FROM cliente_valor
    ORDER BY tipo_seguro, rank_premium;
END;

-- ============================================================================
-- SECTION 2: FUNÇÕES T-SQL PARA CÁLCULOS RECORRENTES
-- ============================================================================

-- 2.1: Função para calcular lifetime value (LTV)
CREATE FUNCTION fn_calcular_ltv(
    @id_cliente INT,
    @taxa_desconto DECIMAL(5,4) = 0.10
)
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @ltv DECIMAL(10,2) = 0;
    
    SELECT @ltv = SUM(
        valor_premio * 12 / POWER(1 + @taxa_desconto, DATEDIFF(YEAR, data_contratacao, GETDATE()))
    )
    FROM clientes_seguros
    WHERE id_cliente = @id_cliente
    AND status_contrato IN ('ATIVO', 'SUSPENSO');
    
    RETURN ISNULL(@ltv, 0);
END;

-- 2.2: Função para classificar risco de cliente
CREATE FUNCTION fn_classificar_risco_cliente(
    @idade INT,
    @meses_cliente INT,
    @numero_sinistros INT
)
RETURNS VARCHAR(10)
AS
BEGIN
    DECLARE @score_risco INT = 0;
    
    -- Fatores de risco
    SET @score_risco = @score_risco + 
        CASE 
            WHEN @idade < 25 THEN 30
            WHEN @idade BETWEEN 25 AND 35 THEN 20
            WHEN @idade BETWEEN 36 AND 50 THEN 10
            WHEN @idade > 70 THEN 25
            ELSE 0
        END;
    
    SET @score_risco = @score_risco + (@numero_sinistros * 15);
    
    SET @score_risco = @score_risco - 
        CASE 
            WHEN @meses_cliente > 60 THEN 20
            WHEN @meses_cliente > 36 THEN 10
            ELSE 0
        END;
    
    RETURN CASE 
        WHEN @score_risco >= 60 THEN 'MUITO_ALTO'
        WHEN @score_risco >= 40 THEN 'ALTO'
        WHEN @score_risco >= 20 THEN 'MEDIO'
        ELSE 'BAIXO'
    END;
END;

-- 2.3: Função para calcular churn probability
CREATE FUNCTION fn_calcular_churn_probability(
    @dias_sem_atividade INT,
    @meses_cliente INT,
    @valor_premio_medio_mercado DECIMAL(10,2),
    @valor_premio_cliente DECIMAL(10,2)
)
RETURNS DECIMAL(5,2)
AS
BEGIN
    DECLARE @probabilidade DECIMAL(5,2) = 0;
    DECLARE @desvio_preco DECIMAL(5,2);
    
    SET @desvio_preco = ABS(@valor_premio_cliente - @valor_premio_medio_mercado) / 
                        NULLIF(@valor_premio_medio_mercado, 1) * 100;
    
    -- Fatores de risco de churn
    SET @probabilidade = @probabilidade + 
        CASE 
            WHEN @dias_sem_atividade > 180 THEN 45
            WHEN @dias_sem_atividade > 90 THEN 25
            WHEN @dias_sem_atividade > 30 THEN 10
            ELSE 0
        END;
    
    SET @probabilidade = @probabilidade + 
        CASE 
            WHEN @meses_cliente < 6 THEN 30
            WHEN @meses_cliente < 12 THEN 15
            ELSE 0
        END;
    
    SET @probabilidade = @probabilidade + 
        CASE 
            WHEN @desvio_preco > 30 THEN 20
            WHEN @desvio_preco > 15 THEN 10
            ELSE 0
        END;
    
    RETURN CASE WHEN @probabilidade > 100 THEN 100 ELSE @probabilidade END;
END;

-- ============================================================================
-- SECTION 3: VIEWS ANALÍTICAS COMPLEXAS
-- ============================================================================

-- 3.1: View para análise de performance por tipo de seguro
CREATE VIEW vw_performance_seguros AS
SELECT 
    tipo_seguro,
    COUNT(DISTINCT id_cliente) AS total_clientes,
    COUNT(DISTINCT CASE WHEN status_contrato = 'ATIVO' THEN id_cliente END) AS clientes_ativos,
    ROUND(SUM(valor_premio), 2) AS receita_total_premios,
    ROUND(AVG(valor_premio), 2) AS premio_medio,
    ROUND(STDEV(valor_premio), 2) AS desvio_padrao_premio,
    MIN(valor_premio) AS premio_minimo,
    MAX(valor_premio) AS premio_maximo,
    ROUND(AVG(valor_cobertura), 2) AS cobertura_media,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN status_contrato = 'ATIVO' THEN id_cliente END) / 
          COUNT(DISTINCT id_cliente), 2) AS taxa_atividade_pct
FROM clientes_seguros
GROUP BY tipo_seguro;

-- 3.2: View para análise de distribuição geográfica
CREATE VIEW vw_distribuicao_geografica AS
SELECT 
    estado,
    cidade,
    COUNT(DISTINCT id_cliente) AS clientes,
    COUNT(DISTINCT tipo_seguro) AS tipos_seguro,
    ROUND(SUM(valor_premio), 2) AS premium_total,
    ROUND(AVG(valor_premio), 2) AS premium_medio,
    ROUND(100.0 * SUM(valor_cobertura) / 
          SUM(SUM(valor_cobertura)) OVER (), 2) AS percentual_cobertura
FROM clientes_seguros
WHERE status_contrato = 'ATIVO'
GROUP BY estado, cidade;

-- 3.3: View para análise de tendências temporais
CREATE VIEW vw_tendencias_temporais AS
SELECT 
    YEAR(data_contratacao) AS ano,
    MONTH(data_contratacao) AS mes,
    COUNT(DISTINCT id_cliente) AS novos_clientes,
    ROUND(SUM(valor_premio), 2) AS receita_mes,
    ROUND(AVG(valor_premio), 2) AS premio_medio_mes,
    COUNT(DISTINCT tipo_seguro) AS tipos_contratados,
    ROUND(100.0 * COUNT(CASE WHEN status_contrato = 'CANCELADO' THEN 1 END) / 
          COUNT(*), 2) AS taxa_cancelamento_pct
FROM clientes_seguros
GROUP BY YEAR(data_contratacao), MONTH(data_contratacao);

-- ============================================================================
-- SECTION 4: ÍNDICES PARA OTIMIZAÇÃO
-- ============================================================================

-- 4.1: Índices compostos para queries comuns
CREATE INDEX idx_seguro_status_premio 
ON clientes_seguros (tipo_seguro, status_contrato, valor_premio);

CREATE INDEX idx_data_contratacao_estado 
ON clientes_seguros (data_contratacao, estado);

CREATE INDEX idx_cpf_nome_cliente 
ON clientes_seguros (cpf, nome_cliente);

-- ============================================================================
-- SECTION 5: TRIGGER PARA AUDITORIA
-- ============================================================================

CREATE TABLE tb_auditoria_modificacoes (
    id_auditoria INT PRIMARY KEY IDENTITY(1,1),
    tabela_origem VARCHAR(50),
    id_cliente INT,
    tipo_operacao VARCHAR(10),
    valores_antigos NVARCHAR(MAX),
    valores_novos NVARCHAR(MAX),
    usuario VARCHAR(100),
    data_modificacao DATETIME,
    ip_origem VARCHAR(15)
);

CREATE TRIGGER trg_auditoria_clientes_seguros
ON clientes_seguros
AFTER UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO tb_auditoria_modificacoes 
    (tabela_origem, id_cliente, tipo_operacao, valores_antigos, valores_novos, usuario, data_modificacao)
    SELECT 
        'clientes_seguros',
        ISNULL(d.id_cliente, i.id_cliente),
        CASE WHEN DELETE THEN 'DELETE' ELSE 'UPDATE' END,
        'DELETED',
        'INSERTED',
        SYSTEM_USER,
        GETDATE()
    FROM deleted d
    FULL OUTER JOIN inserted i ON d.id_cliente = i.id_cliente
    WHERE d.id_cliente IS NOT NULL OR i.id_cliente IS NOT NULL;
END;

-- ============================================================================
-- CONSULTAS ESTATÍSTICAS AVANÇADAS - DATA DICTIONARY SIMULATOR
-- ============================================================================
-- Este arquivo contém consultas analíticas e estatísticas utilizando
-- funções de agregação, janelas (window functions) e estatística descritiva
-- para simular relatórios de negócio de seguros com análise profunda de dados.
-- ============================================================================

-- ============================================================================
-- 1. ANÁLISE DESCRITIVA BÁSICA - ESTATÍSTICA UNIVARIADA
-- ============================================================================

-- 1.1: Distribuição de Clientes por Tipo de Seguro com Contagem e Percentual
-- JUSTIFICATIVA: Entender o portfólio de produtos é essencial para gestão
-- estratégica. Este agrupamento mostra a composição do negócio por produto.
SELECT 
    -- Selecionamos o tipo de seguro como dimensão principal
    tipo_seguro,
    -- Contamos o número de clientes com esse tipo de seguro
    COUNT(*) AS quantidade_clientes,
    -- Calculamos o percentual em relação ao total (CAST garante divisão em float)
    ROUND(
        (COUNT(*) * 100.0) / SUM(COUNT(*)) OVER (), 
        2
    ) AS percentual_do_total,
    -- Agregamos o valor total de prêmios arrecadados por tipo
    ROUND(SUM(valor_premio), 2) AS total_premios,
    -- Calculamos o valor médio do prêmio para cada tipo de seguro
    ROUND(AVG(valor_premio), 2) AS premio_medio,
    -- Desvio padrão do prêmio (variabilidade de precificação)
    ROUND(STDDEV_POP(valor_premio), 2) AS desvio_padrao_premio,
    -- Valor mínimo de cobertura oferecida
    ROUND(MIN(valor_cobertura), 2) AS cobertura_minima,
    -- Valor máximo de cobertura (potencial máximo de risco)
    ROUND(MAX(valor_cobertura), 2) AS cobertura_maxima
FROM 
    clientes_seguros
WHERE 
    -- Filtramos apenas contratos ativos para análise em vigor
    status_contrato = 'ATIVO'
GROUP BY 
    tipo_seguro
ORDER BY 
    -- Ordenamos por quantidade em ordem decrescente para priorização
    quantidade_clientes DESC;

-- ============================================================================

-- 1.2: Estatísticas de Idade - Análise de Distribuição Demográfica
-- JUSTIFICATIVA: A idade é forte preditor de risco. Análises por faixa etária
-- ajudam na segmentação de mercado e na precificação de riscos.
SELECT 
    -- Criamos faixas etárias usando CASE (binning de dados contínuos)
    CASE 
        WHEN idade < 25 THEN '18-24'
        WHEN idade < 35 THEN '25-34'
        WHEN idade < 45 THEN '35-44'
        WHEN idade < 55 THEN '45-54'
        WHEN idade < 65 THEN '55-64'
        ELSE '65+'
    END AS faixa_etaria,
    -- Contagem de clientes em cada faixa (frequência absoluta)
    COUNT(*) AS quantidade_clientes,
    -- Percentual representado por cada faixa
    ROUND(
        (COUNT(*) * 100.0) / SUM(COUNT(*)) OVER (),
        2
    ) AS percentual_clientela,
    -- Idade mínima real nessa faixa (validação)
    MIN(idade) AS idade_minima,
    -- Idade máxima real nessa faixa (validação)
    MAX(idade) AS idade_maxima,
    -- Idade média (tendência central da distribuição)
    ROUND(AVG(idade), 1) AS idade_media,
    -- Mediana (valor do meio, menos sensível a outliers que média)
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY idade) AS idade_mediana,
    -- Score de risco médio por faixa (quanto maior, mais risco)
    ROUND(AVG(score_risco), 2) AS risco_medio,
    -- Taxa de inadimplência por faixa etária (proporção de maus pagadores)
    ROUND(
        (SUM(CASE WHEN flag_inadimplente = 'S' THEN 1 ELSE 0 END) * 100.0) / 
        COUNT(*),
        2
    ) AS taxa_inadimplencia_percentual
FROM 
    clientes_seguros
WHERE 
    status_contrato = 'ATIVO'
GROUP BY 
    faixa_etaria
ORDER BY 
    -- Ordenamos por faixa para visualização lógica
    faixa_etaria;

-- ============================================================================

-- 1.3: Análise de Sexo e Perfil de Risco
-- JUSTIFICATIVA: Análise de gênero é importante para conformidade regulatória
-- e para identificar padrões de risco diferenciados por sexo.
SELECT 
    -- Decodificamos a letra do sexo para legibilidade
    CASE 
        WHEN sexo = 'M' THEN 'Masculino'
        WHEN sexo = 'F' THEN 'Feminino'
        ELSE 'Não Informado'
    END AS genero,
    -- Total de clientes por gênero
    COUNT(*) AS total_clientes,
    -- Percentual do portfólio por gênero
    ROUND(
        (COUNT(*) * 100.0) / SUM(COUNT(*)) OVER (),
        2
    ) AS percentual_portfólio,
    -- Score de risco médio (quanto maior, mais arriscado o segmento)
    ROUND(AVG(score_risco), 2) AS score_risco_medio,
    -- Percentil 75 de risco (3/4 dos clientes têm risco abaixo disso)
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY score_risco) AS score_risco_p75,
    -- Percentil 25 de risco (1/4 dos clientes têm risco abaixo disso)
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY score_risco) AS score_risco_p25,
    -- Taxa de inadimplência (risco de não pagamento)
    ROUND(
        (SUM(CASE WHEN flag_inadimplente = 'S' THEN 1 ELSE 0 END) * 100.0) / 
        COUNT(*),
        2
    ) AS taxa_inadimplencia_pct,
    -- Valor médio do prêmio por gênero (padrão de precificação)
    ROUND(AVG(valor_premio), 2) AS premio_medio,
    -- Cobertura média oferecida (indicador de exposição)
    ROUND(AVG(valor_cobertura), 2) AS cobertura_media
FROM 
    clientes_seguros
WHERE 
    status_contrato = 'ATIVO'
GROUP BY 
    sexo
ORDER BY 
    total_clientes DESC;

-- ============================================================================

-- 2. ANÁLISE DE DISTRIBUIÇÕES E QUARTIS
-- ============================================================================

-- 2.1: Análise de Valor de Prêmio por Percentis
-- JUSTIFICATIVA: Percentis mostram como a distribuição se comporta em
-- diferentes pontos, essencial para entender concentração de valor no portfólio.
SELECT 
    tipo_seguro,
    -- Valor mínimo (piso da distribuição)
    ROUND(MIN(valor_premio), 2) AS premio_minimo,
    -- Percentil 10 (90% paga mais do que isso)
    ROUND(
        PERCENTILE_CONT(0.10) WITHIN GROUP (ORDER BY valor_premio),
        2
    ) AS p10_premio,
    -- Percentil 25 (primeiro quartil - 1/4 abaixo)
    ROUND(
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY valor_premio),
        2
    ) AS q1_premio,
    -- Percentil 50 (mediana - ponto do meio)
    ROUND(
        PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY valor_premio),
        2
    ) AS mediana_premio,
    -- Percentil 75 (terceiro quartil - 3/4 abaixo)
    ROUND(
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY valor_premio),
        2
    ) AS q3_premio,
    -- Percentil 90 (90% abaixo, 10% acima - topo do portfólio)
    ROUND(
        PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY valor_premio),
        2
    ) AS p90_premio,
    -- Valor máximo (teto da distribuição)
    ROUND(MAX(valor_premio), 2) AS premio_maximo,
    -- Intervalo interquartil (Q3-Q1): mede a dispersão central
    ROUND(
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY valor_premio) -
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY valor_premio),
        2
    ) AS iqr_premio,
    -- Média aritmética (tendência central, sensível a outliers)
    ROUND(AVG(valor_premio), 2) AS media_premio,
    -- Coeficiente de variação (variabilidade relativa: desvio/média*100)
    ROUND(
        (STDDEV_POP(valor_premio) / AVG(valor_premio)) * 100,
        2
    ) AS coeficiente_variacao_pct
FROM 
    clientes_seguros
WHERE 
    status_contrato = 'ATIVO'
GROUP BY 
    tipo_seguro
ORDER BY 
    media_premio DESC;

-- ============================================================================

-- 2.2: Correlação entre Risco e Inadimplência
-- JUSTIFICATIVA: Verificamos se o score de risco atribuído realmente
-- prediz inadimplência, validando o modelo de scoring.
SELECT 
    -- Segmentamos clientes por faixa de score de risco
    CASE 
        WHEN score_risco < 30 THEN 'Baixo Risco (0-30)'
        WHEN score_risco < 50 THEN 'Risco Médio (30-50)'
        WHEN score_risco < 70 THEN 'Risco Elevado (50-70)'
        ELSE 'Risco Muito Alto (70+)'
    END AS categoria_risco,
    -- Total de clientes em cada categoria
    COUNT(*) AS total_clientes,
    -- Quantidade de inadimplentes em cada categoria
    SUM(CASE WHEN flag_inadimplente = 'S' THEN 1 ELSE 0 END) AS qtd_inadimplentes,
    -- Taxa de inadimplência real (proporção de maus pagadores)
    ROUND(
        (SUM(CASE WHEN flag_inadimplente = 'S' THEN 1 ELSE 0 END) * 100.0) / 
        COUNT(*),
        2
    ) AS taxa_inadimplencia_pct,
    -- Score mínimo da categoria (validação de faixas)
    ROUND(MIN(score_risco), 2) AS score_minimo,
    -- Score máximo da categoria (validação de faixas)
    ROUND(MAX(score_risco), 2) AS score_maximo,
    -- Score médio dentro da categoria
    ROUND(AVG(score_risco), 2) AS score_medio,
    -- Prêmio médio (para entender precificação por risco)
    ROUND(AVG(valor_premio), 2) AS premio_medio_categoria,
    -- Cobertura média (para entender exposição por risco)
    ROUND(AVG(valor_cobertura), 2) AS cobertura_media_categoria
FROM 
    clientes_seguros
WHERE 
    status_contrato = 'ATIVO'
GROUP BY 
    categoria_risco
ORDER BY 
    -- Ordenamos por risco crescente para visualizar progressão
    MIN(score_risco);

-- ============================================================================

-- 3. ANÁLISE TEMPORAL E DE TENDÊNCIAS
-- ============================================================================

-- 3.1: Análise de Contratos por Período de Contratação
-- JUSTIFICATIVA: Identificar tendências de crescimento, sazonalidade e
-- desempenho de coortes de clientes por período de contratação.
SELECT 
    -- Extraímos o mês e ano de contratação para agrupamento temporal
    TO_CHAR(data_contratacao, 'YYYY-MM') AS periodo_contratacao,
    -- Total de contratos iniciados em cada período
    COUNT(*) AS qtd_contratos_novos,
    -- Percentual de crescimento relativo ao total
    ROUND(
        (COUNT(*) * 100.0) / SUM(COUNT(*)) OVER (),
        2
    ) AS percentual_do_total,
    -- Valor total de prêmios anualizados esperados desse período
    ROUND(SUM(valor_premio), 2) AS receita_premios_periodo,
    -- Valor total de cobertura comprometida
    ROUND(SUM(valor_cobertura), 2) AS exposicao_total_periodo,
    -- Taxa de inadimplência desse período (coorte)
    ROUND(
        (SUM(CASE WHEN flag_inadimplente = 'S' THEN 1 ELSE 0 END) * 100.0) / 
        COUNT(*),
        2
    ) AS taxa_inadimplencia_coorte_pct,
    -- Taxa de retenção (ainda ativos vs cancelados)
    ROUND(
        (SUM(CASE WHEN status_contrato = 'ATIVO' THEN 1 ELSE 0 END) * 100.0) / 
        COUNT(*),
        2
    ) AS taxa_retencao_pct,
    -- Score de risco médio dessa coorte
    ROUND(AVG(score_risco), 2) AS score_risco_medio_coorte
FROM 
    clientes_seguros
GROUP BY 
    TO_CHAR(data_contratacao, 'YYYY-MM')
ORDER BY 
    periodo_contratacao DESC;

-- ============================================================================

-- 3.2: Análise de Cancelamentos e Tempo de Permanência
-- JUSTIFICATIVA: Entender churn (cancelamento) é crítico para rentabilidade.
-- A análise mostra padrões de retenção e duração média de contratos.
SELECT 
    -- Status do contrato (ATIVO vs CANCELADO)
    status_contrato,
    -- Total de contratos em cada status
    COUNT(*) AS total_contratos,
    -- Percentual dentro do total
    ROUND(
        (COUNT(*) * 100.0) / SUM(COUNT(*)) OVER (),
        2
    ) AS percentual_total,
    -- Tempo médio entre contratação e cancelamento (em dias)
    ROUND(
        AVG(
            CASE 
                WHEN data_cancelamento IS NOT NULL 
                THEN EXTRACT(DAY FROM (data_cancelamento - data_contratacao))
                ELSE EXTRACT(DAY FROM (CURRENT_DATE - data_contratacao))
            END
        ),
        1
    ) AS permanencia_media_dias,
    -- Mínimo de dias de permanência (cliente mais impaciente)
    MIN(
        CASE 
            WHEN data_cancelamento IS NOT NULL 
            THEN EXTRACT(DAY FROM (data_cancelamento - data_contratacao))
            ELSE EXTRACT(DAY FROM (CURRENT_DATE - data_contratacao))
        END
    ) AS permanencia_minima_dias,
    -- Máximo de dias de permanência (cliente mais fiel)
    MAX(
        CASE 
            WHEN data_cancelamento IS NOT NULL 
            THEN EXTRACT(DAY FROM (data_cancelamento - data_contratacao))
            ELSE EXTRACT(DAY FROM (CURRENT_DATE - data_contratacao))
        END
    ) AS permanencia_maxima_dias,
    -- Receita média por contrato
    ROUND(AVG(valor_premio), 2) AS premio_medio_status,
    -- Exposição média de cobertura
    ROUND(AVG(valor_cobertura), 2) AS cobertura_media_status,
    -- Taxa de inadimplência dentro do status
    ROUND(
        (SUM(CASE WHEN flag_inadimplente = 'S' THEN 1 ELSE 0 END) * 100.0) / 
        COUNT(*),
        2
    ) AS taxa_inadimplencia_status_pct
FROM 
    clientes_seguros
GROUP BY 
    status_contrato
ORDER BY 
    total_contratos DESC;

-- ============================================================================

-- 4. ANÁLISE DE DESEMPENHO POR CANAL DE VENDA E CORRETOR
-- ============================================================================

-- 4.1: Análise de Performance por Canal de Venda
-- JUSTIFICATIVA: Diferentes canais têm diferentes características de risco
-- e lucratividade. Entender performance por canal guia alocação de recursos.
SELECT 
    -- Canal através do qual o contrato foi originado
    canal_venda,
    -- Número de clientes captados por canal
    COUNT(*) AS qtd_clientes_canal,
    -- Percentual que cada canal representa do portfólio
    ROUND(
        (COUNT(*) * 100.0) / SUM(COUNT(*)) OVER (),
        2
    ) AS percentual_portfólio,
    -- Valor total de prêmios gerados por canal
    ROUND(SUM(valor_premio), 2) AS receita_premios_canal,
    -- Valor médio do prêmio por canal (eficiência de precificação)
    ROUND(AVG(valor_premio), 2) AS premio_medio_canal,
    -- Prêmio mínimo praticado neste canal
    ROUND(MIN(valor_premio), 2) AS premio_minimo_canal,
    -- Prêmio máximo praticado neste canal
    ROUND(MAX(valor_premio), 2) AS premio_maximo_canal,
    -- Score de risco médio dos clientes do canal
    ROUND(AVG(score_risco), 2) AS risco_medio_canal,
    -- Taxa de inadimplência do canal
    ROUND(
        (SUM(CASE WHEN flag_inadimplente = 'S' THEN 1 ELSE 0 END) * 100.0) / 
        COUNT(*),
        2
    ) AS taxa_inadimplencia_canal_pct,
    -- Taxa de cancelamento (churn) por canal
    ROUND(
        (SUM(CASE WHEN status_contrato = 'CANCELADO' THEN 1 ELSE 0 END) * 100.0) / 
        COUNT(*),
        2
    ) AS taxa_cancelamento_canal_pct,
    -- Idade média dos clientes do canal
    ROUND(AVG(idade), 1) AS idade_media_clientes_canal
FROM 
    clientes_seguros
GROUP BY 
    canal_venda
ORDER BY 
    qtd_clientes_canal DESC;

-- ============================================================================

-- 4.2: Ranking de Corretores por Performance
-- JUSTIFICATIVA: Análise de desempenho individual permite identificar
-- melhores práticas e oportunidades de treinamento ou realocação.
SELECT 
    -- Nome do corretor responsável pela carteira
    corretor_responsavel,
    -- Total de clientes sob responsabilidade
    COUNT(*) AS qtd_clientes_corretor,
    -- Ranking de corretores por quantidade (1 é o melhor)
    RANK() OVER (ORDER BY COUNT(*) DESC) AS ranking_por_volume,
    -- Receita total gerenciada pelo corretor
    ROUND(SUM(valor_premio), 2) AS receita_total_corretor,
    -- Ranking de corretores por receita
    RANK() OVER (ORDER BY SUM(valor_premio) DESC) AS ranking_por_receita,
    -- Receita média por cliente (produtividade)
    ROUND(AVG(valor_premio), 2) AS receita_media_por_cliente,
    -- Taxa de inadimplência da carteira do corretor
    ROUND(
        (SUM(CASE WHEN flag_inadimplente = 'S' THEN 1 ELSE 0 END) * 100.0) / 
        COUNT(*),
        2
    ) AS taxa_inadimplencia_carteira_pct,
    -- Score de risco médio (qualidade da carteira em termos de risco)
    ROUND(AVG(score_risco), 2) AS score_risco_medio_carteira,
    -- Taxa de retenção (fidelização dos clientes)
    ROUND(
        (SUM(CASE WHEN status_contrato = 'ATIVO' THEN 1 ELSE 0 END) * 100.0) / 
        COUNT(*),
        2
    ) AS taxa_retencao_carteira_pct,
    -- Ranking por taxa de retenção (qualidade de relacionamento)
    RANK() OVER (
        ORDER BY 
            (SUM(CASE WHEN status_contrato = 'ATIVO' THEN 1 ELSE 0 END) * 100.0) / 
            COUNT(*) DESC
    ) AS ranking_por_retencao
FROM 
    clientes_seguros
GROUP BY 
    corretor_responsavel
ORDER BY 
    qtd_clientes_corretor DESC;

-- ============================================================================

-- 5. ANÁLISE AVANÇADA - WINDOW FUNCTIONS E COMPARAÇÕES
-- ============================================================================

-- 5.1: Comparação de Cada Contrato com Médias do Segmento
-- JUSTIFICATIVA: Identificar anomalias e outliers que merecem investigação
-- para detecção de fraude ou erros de precificação.
SELECT 
    id_cliente,
    nome_cliente,
    tipo_seguro,
    -- Prêmio do contrato atual
    ROUND(valor_premio, 2) AS premio_contrato,
    -- Média de prêmio para o tipo de seguro
    ROUND(
        AVG(valor_premio) OVER (PARTITION BY tipo_seguro),
        2
    ) AS premio_medio_tipo,
    -- Desvio em relação à média (positivo = acima da média)
    ROUND(
        valor_premio - AVG(valor_premio) OVER (PARTITION BY tipo_seguro),
        2
    ) AS desvio_da_media,
    -- Percentual de desvio em relação à média
    ROUND(
        ((valor_premio - AVG(valor_premio) OVER (PARTITION BY tipo_seguro)) / 
        AVG(valor_premio) OVER (PARTITION BY tipo_seguro)) * 100,
        2
    ) AS desvio_percentual,
    -- Score de risco do contrato
    ROUND(score_risco, 2) AS score_risco_contrato,
    -- Score médio para o tipo de seguro
    ROUND(
        AVG(score_risco) OVER (PARTITION BY tipo_seguro),
        2
    ) AS score_risco_tipo_medio,
    -- Flag de inadimplência
    flag_inadimplente,
    -- Taxa de inadimplência no tipo de seguro
    ROUND(
        (SUM(CASE WHEN flag_inadimplente = 'S' THEN 1 ELSE 0 END) 
         OVER (PARTITION BY tipo_seguro)) * 100.0 / 
        COUNT(*) OVER (PARTITION BY tipo_seguro),
        2
    ) AS taxa_inadimplencia_tipo_pct
FROM 
    clientes_seguros
WHERE 
    status_contrato = 'ATIVO'
ORDER BY 
    -- Ordenamos por maior desvio (possíveis anomalias)
    ABS(desvio_da_media) DESC
LIMIT 
    -- Retornamos os top 50 contratos mais desviantes para análise
    50;

-- ============================================================================

-- 5.2: Análise de Cumulativo e Acumulado de Receita por Segmento
-- JUSTIFICATIVA: Entender concentração de receita (80/20) para
-- priorização de retenção e qualidade de relacionamento.
WITH receita_por_tipo AS (
    SELECT 
        tipo_seguro,
        -- Receita total por tipo de seguro
        SUM(valor_premio) AS receita_total,
        COUNT(*) AS qtd_clientes
    FROM 
        clientes_seguros
    WHERE 
        status_contrato = 'ATIVO'
    GROUP BY 
        tipo_seguro
)
SELECT 
    tipo_seguro,
    -- Quantidade de clientes
    qtd_clientes,
    -- Receita total do segmento
    ROUND(receita_total, 2) AS receita_segmento,
    -- Percentual de receita em relação ao total
    ROUND(
        (receita_total * 100.0) / SUM(receita_total) OVER (),
        2
    ) AS percentual_receita_total,
    -- Receita acumulada em ordem decrescente (cumulativo)
    ROUND(
        SUM(receita_total) OVER (ORDER BY receita_total DESC),
        2
    ) AS receita_acumulada,
    -- Percentual acumulado (para análise de Pareto)
    ROUND(
        (SUM(receita_total) OVER (ORDER BY receita_total DESC) * 100.0) / 
        SUM(receita_total) OVER (),
        2
    ) AS percentual_acumulado,
    -- Classificação ABC (A: 80%, B: 15%, C: 5%)
    CASE 
        WHEN (SUM(receita_total) OVER (ORDER BY receita_total DESC) * 100.0) / 
             SUM(receita_total) OVER () <= 80 THEN 'A - Vital'
        WHEN (SUM(receita_total) OVER (ORDER BY receita_total DESC) * 100.0) / 
             SUM(receita_total) OVER () <= 95 THEN 'B - Importante'
        ELSE 'C - Complementar'
    END AS classificacao_pareto
FROM 
    receita_por_tipo
ORDER BY 
    receita_total DESC;

-- ============================================================================

-- 6. ANÁLISE DE COBERTURA E EXPOSIÇÃO A RISCOS
-- ============================================================================

-- 6.1: Análise de Exposição Total e Índice Sinistralidade Esperado
-- JUSTIFICATIVA: Exposição total é o valor máximo que a seguradora
-- poderia pagar. Este cálculo é crítico para solvência e reservas.
SELECT 
    -- Tipo de seguro
    tipo_seguro,
    -- Total de contratos ativos
    COUNT(*) AS qtd_contratos_ativos,
    -- Exposição total (valor máximo de pagamento potencial)
    ROUND(SUM(valor_cobertura), 2) AS exposicao_total,
    -- Prêmios coletados
    ROUND(SUM(valor_premio), 2) AS premios_coletados,
    -- Índice de exposição (cobertura/prêmio - maior = mais risco relativo)
    ROUND(
        SUM(valor_cobertura) / SUM(valor_premio),
        2
    ) AS indice_cobertura_por_premio,
    -- Valor médio de cobertura
    ROUND(AVG(valor_cobertura), 2) AS cobertura_media,
    -- Valor médio de prêmio
    ROUND(AVG(valor_premio), 2) AS premio_medio,
    -- Razão (cobertura média / prêmio médio)
    ROUND(
        AVG(valor_cobertura) / AVG(valor_premio),
        2
    ) AS razao_cobertura_premio,
    -- Margem de contribuição esperada (prêmio - despesa estimada)
    -- Assumindo 70% do prêmio como custo sinistral
    ROUND(
        SUM(valor_premio) * 0.30,
        2
    ) AS margem_bruta_estimada,
    -- Margem percentual
    ROUND(30, 2) AS margem_percentual_estimada,
    -- Sinistralidade esperada (70% de cada prêmio)
    ROUND(
        SUM(valor_premio) * 0.70,
        2
    ) AS sinistrabilidade_esperada
FROM 
    clientes_seguros
WHERE 
    status_contrato = 'ATIVO'
GROUP BY 
    tipo_seguro
ORDER BY 
    exposicao_total DESC;

-- ============================================================================

-- 6.2: Matriz de Risco e Retorno
-- JUSTIFICATIVA: Análise bidimensional que mostra a relação entre
-- risco (score) e retorno (prêmio) para otimizar portfólio.
SELECT 
    -- Criamos faixas de risco
    CASE 
        WHEN score_risco < 30 THEN 'Risco Baixo'
        WHEN score_risco < 50 THEN 'Risco Médio'
        WHEN score_risco < 70 THEN 'Risco Alto'
        ELSE 'Risco Crítico'
    END AS segmento_risco,
    -- Criamos faixas de retorno (prêmio)
    CASE 
        WHEN valor_premio < 100 THEN 'Prêmio Baixo (<100)'
        WHEN valor_premio < 300 THEN 'Prêmio Médio (100-300)'
        WHEN valor_premio < 500 THEN 'Prêmio Alto (300-500)'
        ELSE 'Prêmio Premium (>500)'
    END AS segmento_premio,
    -- Contagem de clientes em cada célula da matriz
    COUNT(*) AS qtd_clientes_segmento,
    -- Percentual do total
    ROUND(
        (COUNT(*) * 100.0) / SUM(COUNT(*)) OVER (),
        2
    ) AS percentual_total_clientes,
    -- Receita dessa combinação
    ROUND(SUM(valor_premio), 2) AS receita_segmento,
    -- Taxa de inadimplência
    ROUND(
        (SUM(CASE WHEN flag_inadimplente = 'S' THEN 1 ELSE 0 END) * 100.0) / 
        COUNT(*),
        2
    ) AS taxa_inadimplencia_segmento_pct,
    -- ROI esperado (margem de 30%)
    ROUND(
        SUM(valor_premio) * 0.30,
        2
    ) AS roi_esperado
FROM 
    clientes_seguros
WHERE 
    status_contrato = 'ATIVO'
GROUP BY 
    segmento_risco,
    segmento_premio
ORDER BY 
    qtd_clientes_segmento DESC;

-- ============================================================================
-- FIM DAS CONSULTAS ESTATÍSTICAS
-- ============================================================================

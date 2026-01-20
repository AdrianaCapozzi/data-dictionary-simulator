/* ============================================================================
   SAS ADVANCED ANALYTICS - DATA DICTIONARY SIMULATOR
   ============================================================================
   Análises estatísticas avançadas, segmentação e modelagem preditiva
   ============================================================================ */

libname projeto 'C:\Data\Projeto';
options pagesize=60 linesize=100 nocenter;

/* ============================================================================
   SECTION 1: ANÁLISE DESCRITIVA MULTIVARIADA
   ============================================================================ */

/* 1.1: Análise de componentes principais (PCA) para redução dimensional */
proc princomp data=projeto.clientes_seguros out=pca_components n=3 simple corr;
    var valor_premio valor_cobertura idade;
    id id_cliente tipo_seguro;
    title 'Análise de Componentes Principais - Variáveis de Seguro';
run;

/* 1.2: Análise de agrupamento (Cluster Analysis) - Segmentação de clientes */
proc fastclus data=projeto.clientes_seguros 
              out=clustered_clients 
              outstat=cluster_stats
              maxclusters=5 
              converge=0.001
              replace=full;
    var valor_premio valor_cobertura idade;
    id id_cliente nome_cliente tipo_seguro;
    title 'Clustering de Clientes - K-Means (k=5)';
run;

/* 1.3: Análise discriminante para classificação de risco */
proc discrim data=projeto.clientes_seguros 
             method=normal 
             out=risco_classificado 
             outstat=risco_stats
             simple usscp;
    class risco_cliente;
    var idade valor_premio valor_cobertura;
    id id_cliente;
    title 'Análise Discriminante - Classificação de Risco';
run;

/* ============================================================================
   SECTION 2: ANÁLISE DE SÉRIES TEMPORAIS
   ============================================================================ */

/* 2.1: Preparação de dados para análise temporal */
data temporal_agregado;
    set projeto.clientes_seguros;
    
    /* Cria variáveis de data */
    ano_contrata = year(data_contratacao);
    mes_contrata = month(data_contratacao);
    data_mes = mdy(mes_contrata, 1, ano_contrata);
    
    /* Calcula dias desde contratação */
    dias_cliente = intck('day', data_contratacao, today());
    
    /* Categoriza tenure */
    if dias_cliente <= 90 then tenure_cat = 'Novo';
    else if dias_cliente <= 365 then tenure_cat = 'Menos_1ano';
    else if dias_cliente <= 1095 then tenure_cat = '1_a_3_anos';
    else tenure_cat = 'Mais_3_anos';
run;

/* 2.2: Agregação mensal para análise de tendência */
proc summary data=temporal_agregado nway;
    class data_mes tipo_seguro;
    var valor_premio valor_cobertura;
    output out=tendencia_mensal 
           n=quantidade 
           sum=total_premio total_cobertura 
           mean=media_premio media_cobertura 
           std=desvio_premio desvio_cobertura;
run;

/* 2.3: Análise de tendência temporal com regressão */
proc reg data=tendencia_mensal outvif;
    model total_premio = quantidade media_premio / vif;
    title 'Análise de Regressão - Tendência de Prêmios';
    output out=pred_tendencia predicted=pred_premio residual=resid_premio;
run;

/* ============================================================================
   SECTION 3: ANÁLISE DE SOBREVIVÊNCIA (SURVIVAL ANALYSIS)
   ============================================================================ */

/* 3.1: Preparação de dados para análise de sobrevivência */
data survival_data;
    set projeto.clientes_seguros;
    
    /* Define evento: cancelamento */
    evento = (status_contrato = 'CANCELADO');
    
    /* Calcula tempo em dias desde contratação até evento ou censura */
    if status_contrato = 'CANCELADO' then
        tempo_dias = intck('day', data_contratacao, data_cancelamento);
    else
        tempo_dias = intck('day', data_contratacao, today());
    
    /* Cria variável de tempo em meses */
    tempo_meses = round(tempo_dias / 30.44, 0);
run;

/* 3.2: Estimador de Kaplan-Meier - Curva de Sobrevivência */
proc lifetest data=survival_data method=km plot=survival outsurv=sobrevivencia;
    time tempo_meses*evento(0);
    strata tipo_seguro;
    title 'Curva de Sobrevivência de Clientes por Tipo de Seguro';
run;

/* 3.3: Modelo de riscos proporcionais de Cox */
proc phreg data=survival_data;
    model tempo_meses*evento(0) = idade valor_premio valor_cobertura / risklimits;
    class tipo_seguro;
    title 'Modelo de Cox - Análise de Fatores de Risco de Cancelamento';
run;

/* ============================================================================
   SECTION 4: ANÁLISE BAYESIANA
   ============================================================================ */

/* 4.1: Análise Bayesiana de proporções - Taxa de Atividade */
proc genmod data=projeto.clientes_seguros;
    class status_contrato tipo_seguro;
    model status_contrato = tipo_seguro / dist=multinomial;
    bayes seed=123 nmc=50000 thin=10 diagnostics=all summary=statistics;
    title 'Análise Bayesiana - Proporção de Clientes Ativos por Tipo de Seguro';
run;

/* ============================================================================
   SECTION 5: SEGMENTAÇÃO RFM (Recency, Frequency, Monetary)
   ============================================================================ */

/* 5.1: Cálculo de métricas RFM */
data rfm_metrics;
    set temporal_agregado;
    
    /* Recency: dias desde última atividade */
    recency = intck('day', data_contratacao, today());
    
    /* Frequency: contagem de tipos de seguro contratados */
    frequency = 1; /* Será agregado depois */
    
    /* Monetary: valor total de prêmios */
    monetary = valor_premio * 12; /* Anualizando */
    
    keep id_cliente recency monetary tipo_seguro;
run;

/* 5.2: Agregação RFM e quintilização */
proc summary data=rfm_metrics nway;
    class id_cliente;
    var recency monetary;
    output out=rfm_agg 
           min=recency 
           sum=monetary;
run;

proc rank data=rfm_agg out=rfm_ranked descending;
    var recency;
    ranks recency_rank;
    
    var monetary;
    ranks monetary_rank;
run;

/* 5.3: Classificação RFM */
data rfm_classificado;
    set rfm_ranked;
    
    /* Converte ranks em quintis (1=melhor, 5=pior) */
    recency_score = ceil(recency_rank / (nobs/5));
    monetary_score = ceil(monetary_rank / (nobs/5));
    
    rfm_segment = cats(recency_score, monetary_score);
    
    /* Classifica segmento */
    if rfm_segment = '11' then segmento = 'Champions';
    else if rfm_segment = '12' then segmento = 'Loyal_Customers';
    else if rfm_segment = '21' then segmento = 'Potential_Loyalists';
    else if rfm_segment = '22' or rfm_segment = '23' then segmento = 'At_Risk';
    else segmento = 'Lost';
    
    keep id_cliente rfm_segment segmento monetary;
run;

/* ============================================================================
   SECTION 6: REGRESSÃO LOGÍSTICA PARA PREVISÃO DE CHURN
   ============================================================================ */

/* 6.1: Preparação de variáveis preditoras */
data churn_model_prep;
    set temporal_agregado;
    
    /* Variável dependente: churn (0/1) */
    churn = (status_contrato = 'CANCELADO');
    
    /* Variáveis independentes */
    log_dias_cliente = log(dias_cliente + 1);
    log_valor_premio = log(valor_premio + 1);
    
    /* Variáveis categóricas */
    tipo_seguro_encoded = tipo_seguro;
    
    keep id_cliente churn dias_cliente valor_premio idade 
         log_dias_cliente log_valor_premio tipo_seguro_encoded;
run;

/* 6.2: Divisão treino/teste */
proc surveyselect data=churn_model_prep 
                  out=churn_split 
                  outall 
                  method=srs 
                  seed=123 
                  rate=0.7;
    title 'Divisão Treino (70%) e Teste (30%)';
run;

/* 6.3: Regressão logística */
proc logistic data=churn_split;
    where selected = 1; /* Dados de treino */
    model churn(event='1') = dias_cliente valor_premio idade log_dias_cliente / 
                             selection=stepwise slentry=0.05 slstay=0.05;
    class tipo_seguro_encoded;
    output out=churn_pred predicted=prob_churn;
    title 'Modelo de Regressão Logística - Predição de Churn';
run;

/* ============================================================================
   SECTION 7: RELATÓRIOS ANALÍTICOS
   ============================================================================ */

/* 7.1: Relatório de distribuição por tipo de seguro */
proc freq data=projeto.clientes_seguros;
    table tipo_seguro * status_contrato / outpct nocol nocum;
    title 'Distribuição de Status por Tipo de Seguro';
    output out=freq_table;
run;

/* 7.2: Estatísticas descritivas por segmento */
proc means data=projeto.clientes_seguros 
           maxdec=2 
           fw=12 
           n mean std min max;
    class tipo_seguro;
    var valor_premio valor_cobertura idade;
    title 'Estatísticas por Tipo de Seguro';
    output out=stats_descritivas;
run;

/* 7.3: Correlação de variáveis numéricas */
proc corr data=projeto.clientes_seguros 
          pearson spearman 
          out=correlacao;
    var valor_premio valor_cobertura idade;
    title 'Matriz de Correlação - Variáveis Principais';
run;

/* ============================================================================
   SECTION 8: MACRO SAS PARA AUTOMAÇÃO
   ============================================================================ */

/* 8.1: Macro para análise de variância (ANOVA) */
%macro analise_anova(dataset=, grupo=, variavel=);
    proc glm data=&dataset;
        class &grupo;
        model &variavel = &grupo;
        means &grupo / tukey clb;
        title "ANOVA: &variavel por &grupo";
        output out=anova_output predicted=predicted residual=residual;
    run;
%mend analise_anova;

/* Chamada da macro */
%analise_anova(dataset=projeto.clientes_seguros, 
               grupo=tipo_seguro, 
               variavel=valor_premio);

/* 8.2: Macro para tabela cruzada com testes estatísticos */
%macro tabela_cruzada(dataset=, var1=, var2=);
    proc freq data=&dataset;
        table &var1 * &var2 / chisq cmh;
        title "Tabela Cruzada: &var1 x &var2";
        output out=crosstab_result;
    run;
%mend tabela_cruzada;

/* Chamada da macro */
%tabela_cruzada(dataset=projeto.clientes_seguros, 
                var1=tipo_seguro, 
                var2=status_contrato);

/* ============================================================================
   SECTION 9: EXPORTAÇÃO DE RESULTADOS
   ============================================================================ */

/* 9.1: Exporta resultados para CSV */
proc export data=rfm_classificado 
            outfile='C:\Output\rfm_segmentacao.csv' 
            dbms=csv 
            replace;
run;

/* 9.2: Exporta modelo de churn para score */
proc export data=churn_pred 
            outfile='C:\Output\churn_predictions.csv' 
            dbms=csv 
            replace;
run;

/* 9.3: Cria relatório HTML */
ods html file='C:\Output\analise_completa.html' style=journal;

proc summary data=projeto.clientes_seguros nway;
    class tipo_seguro status_contrato;
    var valor_premio valor_cobertura;
    output out=relatorio_resumo 
           n=freq 
           sum=total 
           mean=media;
run;

proc print data=relatorio_resumo;
    title 'Relatório Executivo - Análise de Clientes';
run;

ods html close;

title;

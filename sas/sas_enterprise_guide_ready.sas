libname projeto 'C:\Data\Projeto';
options pagesize=60 linesize=100 nocenter;

proc princomp data=projeto.clientes_seguros out=pca_components n=3 simple corr;
    var valor_premio valor_cobertura idade;
    id id_cliente tipo_seguro;
    title 'Análise de Componentes Principais - Variáveis de Seguro';
run;

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

data temporal_agregado;
    set projeto.clientes_seguros;
    
    ano_contrata = year(data_contratacao);
    mes_contrata = month(data_contratacao);
    data_mes = mdy(mes_contrata, 1, ano_contrata);
    
    dias_cliente = intck('day', data_contratacao, today());
    
    if dias_cliente <= 90 then tenure_cat = 'Novo';
    else if dias_cliente <= 365 then tenure_cat = 'Menos_1ano';
    else if dias_cliente <= 1095 then tenure_cat = '1_a_3_anos';
    else tenure_cat = 'Mais_3_anos';
run;

proc summary data=temporal_agregado nway;
    class data_mes tipo_seguro;
    var valor_premio valor_cobertura;
    output out=tendencia_mensal 
           n=quantidade 
           sum=total_premio total_cobertura 
           mean=media_premio media_cobertura 
           std=desvio_premio desvio_cobertura;
run;

proc reg data=tendencia_mensal outvif;
    model total_premio = quantidade media_premio / vif;
    title 'Análise de Regressão - Tendência de Prêmios';
    output out=pred_tendencia predicted=pred_premio residual=resid_premio;
run;

data survival_data;
    set projeto.clientes_seguros;
    
    evento = (status_contrato = 'CANCELADO');
    
    if status_contrato = 'CANCELADO' then
        tempo_dias = intck('day', data_contratacao, data_cancelamento);
    else
        tempo_dias = intck('day', data_contratacao, today());
    
    tempo_meses = round(tempo_dias / 30.44, 0);
run;

proc lifetest data=survival_data method=km plot=survival outsurv=sobrevivencia;
    time tempo_meses*evento(0);
    strata tipo_seguro;
    title 'Curva de Sobrevivência de Clientes por Tipo de Seguro';
run;

proc phreg data=survival_data;
    model tempo_meses*evento(0) = idade valor_premio valor_cobertura / risklimits;
    class tipo_seguro;
    title 'Modelo de Cox - Análise de Fatores de Risco de Cancelamento';
run;

proc genmod data=projeto.clientes_seguros;
    class status_contrato tipo_seguro;
    model status_contrato = tipo_seguro / dist=multinomial;
    bayes seed=123 nmc=50000 thin=10 diagnostics=all summary=statistics;
    title 'Análise Bayesiana - Proporção de Clientes Ativos por Tipo de Seguro';
run;

data rfm_metrics;
    set temporal_agregado;
    
    recency = intck('day', data_contratacao, today());
    frequency = 1;
    monetary = valor_premio * 12;
    
    keep id_cliente recency monetary tipo_seguro;
run;

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

data rfm_classificado;
    set rfm_ranked;
    
    recency_score = ceil(recency_rank / (nobs/5));
    monetary_score = ceil(monetary_rank / (nobs/5));
    
    rfm_segment = cats(recency_score, monetary_score);
    
    if rfm_segment = '11' then segmento = 'Champions';
    else if rfm_segment = '12' then segmento = 'Loyal_Customers';
    else if rfm_segment = '21' then segmento = 'Potential_Loyalists';
    else if rfm_segment = '22' or rfm_segment = '23' then segmento = 'At_Risk';
    else segmento = 'Lost';
    
    keep id_cliente rfm_segment segmento monetary;
run;

data churn_model_prep;
    set temporal_agregado;
    
    churn = (status_contrato = 'CANCELADO');
    
    log_dias_cliente = log(dias_cliente + 1);
    log_valor_premio = log(valor_premio + 1);
    
    tipo_seguro_encoded = tipo_seguro;
    
    keep id_cliente churn dias_cliente valor_premio idade 
         log_dias_cliente log_valor_premio tipo_seguro_encoded;
run;

proc surveyselect data=churn_model_prep 
                  out=churn_split 
                  outall 
                  method=srs 
                  seed=123 
                  rate=0.7;
    title 'Divisão Treino (70%) e Teste (30%)';
run;

proc logistic data=churn_split;
    where selected = 1;
    model churn(event='1') = dias_cliente valor_premio idade log_dias_cliente / 
                             selection=stepwise slentry=0.05 slstay=0.05;
    class tipo_seguro_encoded;
    output out=churn_pred predicted=prob_churn;
    title 'Modelo de Regressão Logística - Predição de Churn';
run;

proc freq data=projeto.clientes_seguros;
    table tipo_seguro * status_contrato / outpct nocol nocum;
    title 'Distribuição de Status por Tipo de Seguro';
    output out=freq_table;
run;

proc means data=projeto.clientes_seguros 
           maxdec=2 
           fw=12 
           n mean std min max;
    class tipo_seguro;
    var valor_premio valor_cobertura idade;
    title 'Estatísticas por Tipo de Seguro';
    output out=stats_descritivas;
run;

proc corr data=projeto.clientes_seguros 
          pearson spearman 
          out=correlacao;
    var valor_premio valor_cobertura idade;
    title 'Matriz de Correlação - Variáveis Principais';
run;

proc export data=rfm_classificado 
            outfile='C:\Output\rfm_segmentacao.csv' 
            dbms=csv 
            replace;
run;

proc export data=churn_pred 
            outfile='C:\Output\churn_predictions.csv' 
            dbms=csv 
            replace;
run;

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

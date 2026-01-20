libname projeto 'C:\Data\Projeto';

proc summary data=projeto.clientes_seguros nway;
    class tipo_seguro;
    var valor_premio valor_cobertura;
    output out=resumo_seguros 
           n=quantidade 
           sum=total_premio total_cobertura 
           mean=media_premio media_cobertura 
           min=min_premio max=max_premio;
run;

proc print data=resumo_seguros;
    title 'Resumo por Tipo de Seguro';
run;

proc means data=projeto.clientes_seguros maxdec=2 n mean std min max;
    class status_contrato;
    var valor_premio idade;
    title 'Estatísticas por Status do Contrato';
run;

proc freq data=projeto.clientes_seguros;
    table tipo_seguro * status_contrato / nocol nocum;
    title 'Distribuição de Status por Tipo de Seguro';
run;

proc corr data=projeto.clientes_seguros pearson;
    var valor_premio valor_cobertura idade;
    title 'Matriz de Correlação';
run;

proc sort data=projeto.clientes_seguros out=clientes_sorted;
    by descending valor_premio;
run;

proc print data=clientes_sorted (obs=20);
    var id_cliente nome_cliente tipo_seguro valor_premio status_contrato;
    title 'Top 20 Clientes por Valor de Prêmio';
run;

title;

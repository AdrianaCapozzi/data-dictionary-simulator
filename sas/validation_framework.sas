libname projeto 'C:\Data\Projeto';
options pagesize=60 linesize=100;

/* ============================================================================
   SECTION 1: DEFINIÇÃO DE REGRAS DE VALIDAÇÃO
   ============================================================================ */

/* 1.1: Macro para validação de campos obrigatórios */
%macro validar_obrigatorios(dataset=, variaveis=, output=);
   array erros {*} $500 _erro_1-_erro_10;
        _erro_count = 0;
        
        /* Verifica cada variável */
        %let i = 1;
        %do %while (%scan(&variaveis, &i, %str( )) ne);
            %let var = %scan(&variaveis, &i, %str( ));
            
            if missing(&var) then do;
                _erro_count + 1;
                erros[_erro_count] = "Campo '&var' é obrigatório e está vazio";
            end;
            
            %let i = %eval(&i + 1);
        %end;
        
        /* Flag de validação */
        validacao_ok = (_erro_count = 0);
        
        drop _erro_1-_erro_10 _erro_count;
    run;
%mend validar_obrigatorios;

/* 1.2: Macro para validação de intervalo de valores */
%macro validar_intervalo(dataset=, variavel=, minimo=, maximo=, output=);
    data &output;
        set &dataset;
        
        /* Valida intervalo */
        if &variavel < &minimo or &variavel > &maximo then do;
            erro_intervalo = 1;
            descricao_erro = 
                catx(' ', "&variavel deve estar entre &minimo e &maximo",
                      "mas possui o valor", put(&variavel, BEST.));
        end;
        else do;
            erro_intervalo = 0;
            descricao_erro = '';
        end;
        
        validacao_ok = (erro_intervalo = 0);
    run;
%mend validar_intervalo;

/* 1.3: Macro para validação de padrão (regex) */
%macro validar_padrao(dataset=, variavel=, padrao=, output=);
    data &output;
        set &dataset;
        
        /* Valida padrão usando expressão regular */
        if not prxmatch("/&padrao/", &variavel) then do;
            erro_padrao = 1;
            descricao_erro = catx(' ', "&variavel não atende ao padrão", "&padrao");
        end;
        else do;
            erro_padrao = 0;
            descricao_erro = '';
        end;
        
        validacao_ok = (erro_padrao = 0);
    run;
%mend validar_padrao;

/* ============================================================================
   SECTION 2: FRAMEWORK DE VALIDAÇÃO CUSTOMIZADO
   ============================================================================ */

/* lines;
    clientes_seguros cpf TAMANHO CPF deve ter exatamente 11 dígitos 11
    clientes_seguros idade INTERVALO Idade deve estar entre 18 e 120 18 120
    clientes_seguros valor_premio MINIMO Premio deve ser positivo 0.01
    clientes_seguros status_contrato DOMINIO Status deve ser ATIVO ou CANCELADO ATIVO
    clientes_seguros email FORMATO Email deve ser válido ^[^\s@]+@[^\s@]+\.[^\s@]+$
    clientes_seguros data_contratacao NULO Campo não pode ser nulo
    ;
run;

/* 2.2: Macro para aplicar regras de validação */
%macro aplicar_regras_validacao(dataset=, regras_ds=, output=);
    
    /* Lê dataset de regras em variáveis macro */
    proc sql noprint;
        select count(*) into :n_regras from &regras_ds;
        
        select tabela, coluna, tipo_regra, descricao, parametro1, parametro2
        into :tabela_1-:tabela_&n_regras,
             :coluna_1-:coluna_&n_regras,
             :tipo_1-:tipo_&n_regras,
             :desc_1-:desc_&n_regras,
             :param1_1-:param1_&n_regras,
             :param2_1-:param2_&n_regras
        from &regras_ds;
    quit;
    
    /* Aplica regras */
    data &output;
        set &dataset;
        
        array erros_validacao {*} $200 _err1-_err50;
        n_erros = 0;
        
        %do i = 1 %to &n_regras;
            
            %if &&tipo_&i = TAMANHO %then %do;
                if length(&&coluna_&i) ne &&param1_&i then do;
                    n_erros + 1;
                    erros_validacao[n_erros] = "&&desc_&i";
                end;
            %end;
            
            %if &&tipo_&i = INTERVALO %then %do;
                if &&coluna_&i < &&param1_&i or &&coluna_&i > &&param2_&i then do;
                    n_erros + 1;
                    erros_validacao[n_erros] = "&&desc_&i";
                end;
            %end;
            
            %if &&tipo_&i = MINIMO %then %do;
                if &&coluna_&i <= &&param1_&i then do;
                    n_erros + 1;
                    erros_validacao[n_erros] = "&&desc_&i";
                end;
            %end;
            
            %if &&tipo_&i = NULO %then %do;
                if missing(&&coluna_&i) then do;
                    n_erros + 1;
                    erros_validacao[n_erros] = "&&desc_&i";
                end;
            %end;
            
        %end;
        
        validacao_ok = (n_erros = 0);
        data_validacao = today();
        
        drop _err1-_err50 n_erros;
    run;
    
%mend aplicar_regras_validacao;

/* ============================================================================
   SECTION 3: DETECÇÃO DE DUPLICATAS E ANOMALIAS
   ============================================================================ */

/* 3.1: Procedure para detectar duplicatas */
proc sql;
    create table duplicatas_cpf as
    select 
    projeto.clientes_seguros
    where not missing(cpf)
    group by cpf
    having count(*) > 1
    order by quantidade desc;
quit;

/* 3.2: Procedure para análise de gaps nas chaves primárias */
proc sql;
    create table gaps_chave_primaria as
    with sequencia as (
        select 
            id_cliente,
            lag(id_cliente) over (order by id_cliente) as id_anterior
        from projeto.clientes_seguros
    )
    select 
        id_anterior + 1 as gap_inicio,
        id_cliente - 1 as gap_fim,
        id_cliente - id_anterior - 1 as tamanho_gap
    from sequencia
    where id_cliente - id_anterior > 1
    order by tamanho_gap desc;
quit;

/* 3.3: Análise de consistência entre campos relacionados */
data consistencia_validacao;
    set projeto.clientes_seguros;
    
    /* Valida consistência: valor_cobertura >= valor_premio */
    if valor_cobertura < valor_premio then
        erro_consistencia = 'Cobertura menor que premio';
    
    /* Valida consistência: cliente ativo deve ter data de contratação */
    if status_contrato = 'ATIVO' and missing(data_contratacao) then
        erro_consistencia = 'Cliente ativo sem data de contratação';
    
    /* Valida data de cancelamento coerente */
    if status_contrato = 'CANCELADO' and missing(data_cancelamento) then
        erro_consistencia = 'Cliente cancelado sem data de cancelamento';
    
    if status_contrato = 'ATIVO' and not missing(data_cancelamento) then
        erro_consistencia = 'Cliente ativo com data de cancelamento';
    
    /* Flag de erro */
    tem_erro_consistencia = (not missing(erro_consistencia));
    
    keep id_cliente status_contrato valor_premio valor_cobertura 
         data_contratacao data_cancelamento erro_consistencia tem_erro_consistencia;
run;

/* ============================================================================
   SECTION 4: RELATÓRIOS DE VALIDAÇÃO
   ============================================================================ */

/* 4.1: Relatório consolidado de erros de validação */
proc sql;
    create table relatorio_erros_consolidado as
    select 
       as percentual_dataset
    from projeto.clientes_seguros
    where length(cpf) ne 11
    
    union all
    
    select 
        'IDADE' as tipo_erro,
        'Idade fora do intervalo válido' as descricao_erro,
        count(*) as quantidade_registros,
        round(100 * count(*) / (select count(*) from projeto.clientes_seguros), 2)
        from projeto.clientes_seguros
    where idade < 18 or idade > 120
    
    union all
    
    select 
        'PREMIO' as tipo_erro,
        'Prêmio com valor negativo ou zero' as descricao_erro,
        count(*) as quantidade_registros,
        round(100 * count(*) / (select count(*) from projeto.clientes_seguros), 2)
    from projeto.clientes_seguros
    where valor_premio <= 0
    
    union all
    
    select 
        'CONSISTENCIA' as tipo_erro,
        'Cobertura menor que prêmio' as descricao_erro,
        count(*) as quantidade_registros,
        round(100 * count(*) / (select count(*) from projeto.clientes_seguros), 2)
    from projeto.clientes_seguros
    where valor_cobertura < valor_premio
    
    order by quantidade_registros desc;
quit;

/* 4.2: Scorecard de qualidade de dados */
proc sql;
    create table scorecard_qualidade as
    select 
        'Integridade' as dimensao,
        'Sem nulos obrigatórios' as critério,
        round(100 - (100 * sum(case when id_cliente is null then 1 else 0 end) / 
               count(*)), 2) as score_pct,
        case 
            when round(100 - (100 * sum(case when id_cliente is null then 1 else 0 end) / 
                   count(*)), 2) >= 95 then 'EXCELENTE'
            when round(100 - (100 * sum(case when id_cliente is null then 1 else 0 end) / 
                   count(*)), 2) >= 90 then 'BOM'
            else 'PRECISA_MELHORAR'
        end as status
    from projeto.clientes_seguros
    
    union all
    
    select 
        'Completude' as dimensao,
        'Campos obrigatórios preenchidos' as critério,
        round(100 - (100 * sum(case when nome_cliente is null or trim(nome_cliente)='' then 1 else 0 end) / 
               count(*)), 2) as score_pct,
        case 
            when round(100 - (100 * sum(case when nome_cliente is null or trim(nome_cliente)='' then 1 else 0 end) / 
                   count(*)), 2) >= 98 then 'EXCELENTE'
            when round(100 - (100 * sum(case when nome_cliente is null or trim(nome_cliente)='' then 1 else 0 end) / 
                   count(*)), 2) >= 95 then 'BOM'
            else 'PRECISA_MELHORAR'
        end as status
    from projeto.clientes_seguros
    
    union all
    
    select 
        'Validade' as dimensao,
        'Valores nos intervalos esperados' as critério,
        round(100 - (100 * sum(case when idade < 18 or idade > 120 then 1 else 0 end) / 
               count(*)), 2) as score_pct,
        case 
            when round(100 - (100 * sum(case when idade < 18 or idade > 120 then 1 else 0 end) / 
                   count(*)), 2) >= 99 then 'EXCELENTE'
            when round(100 - (100 * sum(case when idade < 18 or idade > 120 then 1 else 0 end) / 
                   count(*)), 2) >= 95 then 'BOM'
            else 'PRECISA_MELHORAR'
        end as status
    from projeto.clientes_seguros
    
    union all
    
    select 
        'Consistência' as dimensao,
        'Relacionamentos válidos' as critério,
        round(100 - (100 * sum(case when valor_cobertura < valor_premio then 1 else 0 end) / 
               count(*)), 2) as score_pct,
        case 
            when round(100 - (100 * sum(case when valor_cobertura < valor_premio then 1 else 0 end) / 
                   count(*)), 2) >= 99 then 'EXCELENTE'
            when round(100 - (100 * sum(case when valor_cobertura < valor_premio then 1 else 0 end) / 
                   count(*)), 2) >= 95 then 'BOM'
            else 'PRECISA_MELHORAR'
        end as status
    from projeto.clientes_seguros;
quit;

/* 4.3: Exporta relatórios para arquivo */
ods csvall file='C:\Output\relatorio_erros.csv';
proc print data=relatorio_erros_consolidado;
    title 'Relatório Consolidado de Erros de Validação';
run;
ods csvall close;

ods csvall file='C:\Output\scorecard_qualidade.csv';
proc print data=scorecard_qualidade;
    title 'Scorecard de Qualidade de Dados';
run;
ods csvall close;

/* ============================================================================
   SECTION 5: UTILITÁRIOS DE VALIDAÇÃO
   ============================================================================ */

/* 5.1: Macro para gerar relatório comparativo */
%macro relatorio_comparativo(dataset1=, dataset2=, chave=, output=);
    
    proc sql;
        create table &output as
        select 
            coalesce(d1.&chave, d2.&chave) as &chave,
            case when d1.&chave is not null then 'Em Dataset1' else 'Apenas Dataset2' end as localizacao,
   group by &chave, localizacao;
    quit;
    
%mend relatorio_comparativo;

/* 5.2: Macro para exportação com validação */
%macro exportar_com_validacao(dataset=, arquivo=, validacoes=);
    
    /* Aplica validações */
    %aplicar_regras_validacao(dataset=&dataset, regras_ds=&validacoes, output=dados_validados);
    
    /* Exporta apenas registros válidos */
    proc export data=dados_validados(where=(validacao_ok=1))
                outfile="&arquivo"
                dbms=xlsx
                replace;
    run;
    
    /* Gera relatório de exclusões */
    proc print data=dados_validados(where=(validacao_ok=0));
        title 'Registros Excluídos por Validação';
    run;
    
%mend exportar_com_validacao;

title;

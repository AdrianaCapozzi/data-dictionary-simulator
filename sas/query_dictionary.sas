/* SAS program to query data dictionary */
proc sql;
    select 
        nome_tabela,
        nome_coluna,
        tipo_dado,
        descricao_coluna,
        chave_primaria,
        aceita_nulos
    from projeto.data_dictionary
    where nome_tabela = 'clientes_seguros'
    order by nome_coluna;
quit;

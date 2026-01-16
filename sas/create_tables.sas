/* SAS program to create data dictionary tables */
/* Biblioteca de trabalho */
libname projeto work;

/* Tabela principal */
data projeto.clientes_seguros;
    length 
        id_cliente 8
        nome_cliente $100
        cpf $11
        data_nascimento 8
        tipo_seguro $50
        valor_premio 8
        data_contratacao 8
        status_contrato $20
        corretor_responsavel $100
        canal_venda $50;

    format data_nascimento data_contratacao date9.;
    stop;
run;

/* Data Dictionary */
data projeto.data_dictionary;
    length
        nome_tabela $50
        nome_coluna $50
        tipo_dado $50
        descricao_coluna $255
        chave_primaria $3
        aceita_nulos $3;
    stop;
run;

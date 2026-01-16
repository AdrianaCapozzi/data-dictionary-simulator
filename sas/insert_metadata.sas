/* SAS program to insert metadata */
data projeto.data_dictionary;
    input 
        nome_tabela $
        nome_coluna $
        tipo_dado $
        descricao_coluna $
        chave_primaria $
        aceita_nulos $;

datalines;
clientes_seguros id_cliente INT Identificador_unico_do_cliente Sim Nao
clientes_seguros nome_cliente VARCHAR(100) Nome_completo_do_cliente Nao Nao
clientes_seguros cpf CHAR(11) CPF_do_cliente Nao Nao
clientes_seguros data_nascimento DATE Data_de_nascimento Nao Sim
clientes_seguros tipo_seguro VARCHAR(50) Tipo_de_seguro_contratado Nao Sim
clientes_seguros valor_premio DECIMAL(10,2) Valor_do_premio Nao Sim
clientes_seguros data_contratacao DATE Data_de_contratacao Nao Sim
clientes_seguros status_contrato VARCHAR(20) Status_do_contrato Nao Sim
clientes_seguros corretor_responsavel VARCHAR(100) Nome_do_corretor Nao Sim
clientes_seguros canal_venda VARCHAR(50) Canal_de_venda Nao Sim
;
run;

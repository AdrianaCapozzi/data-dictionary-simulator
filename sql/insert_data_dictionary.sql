-- SQL script to insert data dictionary information
-- ===============================
-- Tabela de Data Dictionary
-- ===============================

CREATE TABLE data_dictionary (
    nome_tabela VARCHAR(50),
    nome_coluna VARCHAR(50),
    tipo_dado VARCHAR(50),
    descricao_coluna VARCHAR(255),
    chave_primaria VARCHAR(3),
    aceita_nulos VARCHAR(3)
);

INSERT INTO data_dictionary VALUES
('clientes_seguros','id_cliente','INT','Identificador único do cliente','Sim','Não'),
('clientes_seguros','nome_cliente','VARCHAR(100)','Nome completo do cliente','Não','Não'),
('clientes_seguros','cpf','CHAR(11)','CPF sem formatação','Não','Não'),
('clientes_seguros','data_nascimento','DATE','Data de nascimento','Não','Sim'),
('clientes_seguros','tipo_seguro','VARCHAR(50)','Tipo de seguro','Não','Sim'),
('clientes_seguros','valor_premio','DECIMAL(10,2)','Valor mensal do prêmio','Não','Sim'),
('clientes_seguros','data_contratacao','DATE','Data de contratação','Não','Sim'),
('clientes_seguros','status_contrato','VARCHAR(20)','Status do contrato','Não','Sim'),
('clientes_seguros','corretor_responsavel','VARCHAR(100)','Corretor responsável','Não','Sim'),
('clientes_seguros','canal_venda','VARCHAR(50)','Canal de venda','Não','Sim');

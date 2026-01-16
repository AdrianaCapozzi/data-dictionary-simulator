-- SQL script to create data dictionary tables
-- ===============================
-- Tabela principal de negócios
-- ===============================

CREATE TABLE clientes_seguros (
    id_cliente INT PRIMARY KEY,
    nome_cliente VARCHAR(100) NOT NULL,
    cpf CHAR(11) NOT NULL,
    sexo CHAR(1),
    data_nascimento DATE,
    idade INT,
    tipo_seguro VARCHAR(50),
    valor_premio DECIMAL(10,2),
    valor_cobertura DECIMAL(12,2),
    data_contratacao DATE,
    data_cancelamento DATE,
    status_contrato VARCHAR(20),
    corretor_responsavel VARCHAR(100),
    canal_venda VARCHAR(50),
    score_risco DECIMAL(5,2),
    flag_inadimplente CHAR(1),
    data_atualizacao TIMESTAMP
);

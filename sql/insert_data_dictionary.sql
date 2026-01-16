-- SQL script to insert data dictionary information
-- ===============================
-- Tabela de Data Dictionary
-- ===============================

CREATE TABLE data_dictionary (
    nome_tabela VARCHAR(50),
    nome_coluna VARCHAR(50),
    tipo_dado VARCHAR(50),
    descricao_coluna VARCHAR(255),
    dominio_valores VARCHAR(100),
    regra_negocio VARCHAR(255),
    exemplo_valor VARCHAR(50),
    sensibilidade_lgpd VARCHAR(20),
    chave_primaria VARCHAR(3),
    aceita_nulos VARCHAR(3)
);

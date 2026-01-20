-- ============================================================================
-- DADOS DE EXEMPLO PARA TESTES - DATA DICTIONARY SIMULATOR
-- ============================================================================
-- Este arquivo contém instruções INSERT para popular as tabelas com dados
-- de teste realistas, permitindo validar todas as consultas estatísticas.
-- ============================================================================

-- ============================================================================
-- INSERÇÃO DE DADOS - TABELA: clientes_seguros
-- ============================================================================

-- Bloco 1: Seguros Auto - Clientes de Baixo Risco
-- JUSTIFICATIVA: Seguro auto é produto de alto volume com diversificação
INSERT INTO clientes_seguros VALUES
(1, 'Carlos Silva', '12345678901', 'M', '1990-05-15', 34, 'Auto', 250.00, 50000.00, '2024-01-10', NULL, 'ATIVO', 'João Santos', 'Direto', 28.5, 'N', '2024-01-10'),
(2, 'Maria Oliveira', '23456789012', 'F', '1985-08-22', 39, 'Auto', 280.00, 52000.00, '2024-02-15', NULL, 'ATIVO', 'João Santos', 'Direto', 32.1, 'N', '2024-02-15'),
(3, 'José Pereira', '34567890123', 'M', '1978-03-10', 46, 'Auto', 320.00, 60000.00, '2024-01-20', NULL, 'ATIVO', 'Maria Costa', 'Corretor', 35.7, 'N', '2024-01-20'),
(4, 'Ana Mendes', '45678901234', 'F', '1992-11-28', 32, 'Auto', 245.00, 48000.00, '2024-03-05', NULL, 'ATIVO', 'Maria Costa', 'Corretor', 25.3, 'N', '2024-03-05'),
(5, 'Pedro Gomes', '56789012345', 'M', '1988-07-14', 36, 'Auto', 290.00, 55000.00, '2024-02-20', NULL, 'ATIVO', 'João Santos', 'Direto', 29.8, 'N', '2024-02-20');

-- Bloco 2: Seguros Residencial - Clientes com Risco Médio
-- JUSTIFICATIVA: Seguro residencial apresenta risco mais estável mas maior exposição
INSERT INTO clientes_seguros VALUES
(6, 'Laura Ferreira', '67890123456', 'F', '1980-09-05', 44, 'Residencial', 150.00, 300000.00, '2024-01-15', NULL, 'ATIVO', 'Carlos Rocha', 'Intermediário', 42.1, 'N', '2024-01-15'),
(7, 'Roberto Alves', '78901234567', 'M', '1975-02-18', 49, 'Residencial', 180.00, 350000.00, '2024-02-10', NULL, 'ATIVO', 'Carlos Rocha', 'Intermediário', 45.6, 'N', '2024-02-10'),
(8, 'Patricia Lima', '89012345678', 'F', '1982-06-30', 42, 'Residencial', 165.00, 320000.00, '2024-03-08', NULL, 'ATIVO', 'Ana Paula', 'Corretor', 40.2, 'N', '2024-03-08'),
(9, 'Fernando Costa', '90123456789', 'M', '1987-04-12', 37, 'Residencial', 155.00, 310000.00, '2024-01-25', NULL, 'ATIVO', 'Ana Paula', 'Corretor', 38.9, 'N', '2024-01-25'),
(10, 'Juliana Santos', '01234567890', 'F', '1993-10-20', 31, 'Residencial', 145.00, 290000.00, '2024-02-28', NULL, 'ATIVO', 'Carlos Rocha', 'Intermediário', 35.4, 'N', '2024-02-28');

-- Bloco 3: Seguros Saúde - Clientes com Risco Variável
-- JUSTIFICATIVA: Saúde apresenta forte correlação com idade e gênero
INSERT INTO clientes_seguros VALUES
(11, 'Ricardo Barbosa', '11223344556', 'M', '1960-01-10', 64, 'Saúde', 450.00, 100000.00, '2024-01-05', NULL, 'ATIVO', 'Pedro Teixeira', 'Direto', 68.5, 'S', '2024-01-05'),
(12, 'Beatriz Morais', '22334455667', 'F', '1955-12-25', 69, 'Saúde', 520.00, 120000.00, '2024-02-01', NULL, 'ATIVO', 'Pedro Teixeira', 'Direto', 72.3, 'S', '2024-02-01'),
(13, 'Gustavo Ribeiro', '33445566778', 'M', '1970-08-15', 54, 'Saúde', 380.00, 85000.00, '2024-01-12', NULL, 'ATIVO', 'Lúcia Mendes', 'Corretor', 55.2, 'N', '2024-01-12'),
(14, 'Márcia Dias', '44556677889', 'F', '1965-03-22', 59, 'Saúde', 420.00, 95000.00, '2024-03-10', NULL, 'ATIVO', 'Lúcia Mendes', 'Corretor', 62.8, 'N', '2024-03-10'),
(15, 'Wagner Oliveira', '55667788990', 'M', '1952-06-08', 72, 'Saúde', 580.00, 140000.00, '2024-02-05', NULL, 'ATIVO', 'Pedro Teixeira', 'Direto', 78.1, 'S', '2024-02-05');

-- Bloco 4: Seguros Auto - Clientes de Alto Risco (Inadimplentes)
-- JUSTIFICATIVA: Clientes com histórico de inadimplência apresentam scoring elevado
INSERT INTO clientes_seguros VALUES
(16, 'Marcelo Souza', '66778899001', 'M', '1996-09-14', 28, 'Auto', 420.00, 65000.00, '2024-01-08', NULL, 'ATIVO', 'João Santos', 'Direto', 71.2, 'S', '2024-01-08'),
(17, 'Camila Rocha', '77889900112', 'F', '1998-05-30', 26, 'Auto', 450.00, 70000.00, '2024-02-12', NULL, 'ATIVO', 'Maria Costa', 'Corretor', 75.8, 'S', '2024-02-12'),
(18, 'Bruno Santos', '88990011223', 'M', '1995-11-03', 29, 'Auto', 380.00, 58000.00, '2024-01-18', NULL, 'ATIVO', 'João Santos', 'Direto', 68.4, 'S', '2024-01-18'),
(19, 'Fernanda Silva', '99001122334', 'F', '1994-07-19', 30, 'Auto', 410.00, 62000.00, '2024-03-01', NULL, 'ATIVO', 'Maria Costa', 'Corretor', 72.9, 'S', '2024-03-01'),
(20, 'Eduardo Martins', '00112233445', 'M', '1999-02-08', 25, 'Auto', 460.00, 72000.00, '2024-02-22', NULL, 'ATIVO', 'João Santos', 'Direto', 79.5, 'S', '2024-02-22');

-- Bloco 5: Seguros Residencial Premium - Alto Valor
-- JUSTIFICATIVA: Residencial em áreas premium com exposição alta
INSERT INTO clientes_seguros VALUES
(21, 'Alejandro González', '11122233344', 'M', '1970-04-25', 54, 'Residencial', 320.00, 800000.00, '2024-01-03', NULL, 'ATIVO', 'Ana Paula', 'Intermediário', 48.2, 'N', '2024-01-03'),
(22, 'Isabela Mendes', '22233344455', 'F', '1978-10-12', 46, 'Residencial', 350.00, 850000.00, '2024-02-07', NULL, 'ATIVO', 'Carlos Rocha', 'Intermediário', 51.7, 'N', '2024-02-07'),
(23, 'Thiago Ferreira', '33344455566', 'M', '1985-01-30', 39, 'Residencial', 300.00, 750000.00, '2024-01-22', NULL, 'ATIVO', 'Ana Paula', 'Corretor', 44.3, 'N', '2024-01-22'),
(24, 'Vanessa Costa', '44455566677', 'F', '1988-08-14', 36, 'Residencial', 310.00, 780000.00, '2024-02-28', NULL, 'ATIVO', 'Carlos Rocha', 'Intermediário', 45.9, 'N', '2024-02-28'),
(25, 'Rodrigo Silva', '55566677788', 'M', '1983-12-02', 41, 'Residencial', 330.00, 820000.00, '2024-03-05', NULL, 'ATIVO', 'Ana Paula', 'Corretor', 49.5, 'N', '2024-03-05');

-- Bloco 6: Contratos Cancelados - Histórico de Churn
-- JUSTIFICATIVA: Análise de cancelamentos mostra padrões de retenção
INSERT INTO clientes_seguros VALUES
(26, 'Augusto Ribeiro', '66677788899', 'M', '1975-05-18', 49, 'Auto', 270.00, 51000.00, '2023-06-10', '2024-01-15', 'CANCELADO', 'João Santos', 'Direto', 52.1, 'N', '2024-01-15'),
(27, 'Cristina Lima', '77788899001', 'F', '1980-09-06', 44, 'Saúde', 390.00, 88000.00, '2023-08-20', '2024-02-10', 'CANCELADO', 'Pedro Teixeira', 'Direto', 58.6, 'N', '2024-02-10'),
(28, 'Leandro Gomes', '88899900112', 'M', '1992-03-14', 32, 'Residencial', 160.00, 320000.00, '2023-09-05', '2024-01-30', 'CANCELADO', 'Carlos Rocha', 'Intermediário', 39.2, 'N', '2024-01-30'),
(29, 'Sophie Almeida', '99900011223', 'F', '1990-11-27', 34, 'Auto', 300.00, 55000.00, '2023-07-12', '2024-02-20', 'CANCELADO', 'Maria Costa', 'Corretor', 61.4, 'S', '2024-02-20'),
(30, 'Mateus Barbosa', '00011122334', 'M', '1987-02-09', 37, 'Saúde', 430.00, 98000.00, '2023-10-01', '2024-03-10', 'CANCELADO', 'Lúcia Mendes', 'Corretor', 65.7, 'N', '2024-03-10');

-- Bloco 7: Clientes Recentes - Coorte Q1 2024
-- JUSTIFICATIVA: Acompanhamento de cohort de novos clientes
INSERT INTO clientes_seguros VALUES
(31, 'Simone Santos', '11233344556', 'F', '1986-04-20', 38, 'Auto', 265.00, 52000.00, '2024-03-15', NULL, 'ATIVO', 'João Santos', 'Direto', 31.2, 'N', '2024-03-15'),
(32, 'Henrique Oliveira', '22344455667', 'M', '1991-07-08', 33, 'Residencial', 170.00, 330000.00, '2024-03-18', NULL, 'ATIVO', 'Carlos Rocha', 'Intermediário', 37.8, 'N', '2024-03-18'),
(33, 'Dorothea Moura', '33455566778', 'F', '1956-01-15', 68, 'Saúde', 590.00, 145000.00, '2024-03-20', NULL, 'ATIVO', 'Pedro Teixeira', 'Direto', 74.5, 'S', '2024-03-20'),
(34, 'Víctor Costa', '44566677889', 'M', '1984-06-11', 40, 'Auto', 310.00, 58000.00, '2024-03-22', NULL, 'ATIVO', 'Maria Costa', 'Corretor', 33.5, 'N', '2024-03-22'),
(35, 'Natália Ferreira', '55677788990', 'F', '1989-09-19', 35, 'Residencial', 175.00, 340000.00, '2024-03-25', NULL, 'ATIVO', 'Ana Paula', 'Corretor', 36.9, 'N', '2024-03-25');

-- ============================================================================
-- INSERÇÃO DE DADOS - TABELA: data_dictionary
-- ============================================================================
-- Esta tabela documenta todos os metadados das colunas existentes

INSERT INTO data_dictionary VALUES
('clientes_seguros', 'id_cliente', 'INT', 'Identificador único do cliente', '1 a 999999', 'Deve ser único', '1001', 'Não Sensível', 'SIM', 'NÃO'),
('clientes_seguros', 'nome_cliente', 'VARCHAR(100)', 'Nome completo do cliente segurado', 'Qualquer string', 'Obrigatório, máx 100 caracteres', 'João Silva Santos', 'Sensível', 'NÃO', 'NÃO'),
('clientes_seguros', 'cpf', 'CHAR(11)', 'Cadastro de Pessoa Física (sem formatação)', '11 dígitos', 'Obrigatório, deve ser validado com módulo 11', '12345678901', 'Altamente Sensível', 'NÃO', 'NÃO'),
('clientes_seguros', 'sexo', 'CHAR(1)', 'Gênero biológico do cliente', 'M ou F', 'Obrigatório, apenas M ou F', 'M', 'Não Sensível', 'NÃO', 'SIM'),
('clientes_seguros', 'data_nascimento', 'DATE', 'Data de nascimento no formato ISO', 'YYYY-MM-DD', 'Obrigatório, deve ser < data_atual', '1990-05-15', 'Sensível', 'NÃO', 'NÃO'),
('clientes_seguros', 'idade', 'INT', 'Idade em anos completos do cliente', '18 a 120', 'Calculada automaticamente a partir data_nascimento', '34', 'Não Sensível', 'NÃO', 'SIM'),
('clientes_seguros', 'tipo_seguro', 'VARCHAR(50)', 'Categoria de produto de seguro contratado', 'Auto, Residencial, Saúde, Vida', 'Obrigatório, deve estar na tabela de produtos', 'Auto', 'Não Sensível', 'NÃO', 'NÃO'),
('clientes_seguros', 'valor_premio', 'DECIMAL(10,2)', 'Valor mensal/anual de prêmio em reais', '0.01 a 9999999.99', 'Obrigatório, maior que zero, baseado em scoring', '250.00', 'Não Sensível', 'NÃO', 'NÃO'),
('clientes_seguros', 'valor_cobertura', 'DECIMAL(12,2)', 'Valor máximo de cobertura/indenização em reais', '100.00 a 99999999.99', 'Obrigatório, maior que prêmio, válida produto', '50000.00', 'Não Sensível', 'NÃO', 'NÃO'),
('clientes_seguros', 'data_contratacao', 'DATE', 'Data de início da vigência do contrato', 'YYYY-MM-DD', 'Obrigatório, não pode ser no futuro', '2024-01-10', 'Não Sensível', 'NÃO', 'NÃO'),
('clientes_seguros', 'data_cancelamento', 'DATE', 'Data de término do contrato por cancelamento', 'YYYY-MM-DD', 'Opcional, nulo se contrato ativo, >= data_contratacao', '2024-02-15', 'Não Sensível', 'NÃO', 'SIM'),
('clientes_seguros', 'status_contrato', 'VARCHAR(20)', 'Situação atual do contrato', 'ATIVO, CANCELADO, SUSPENSO', 'Obrigatório, deve estar em domínio válido', 'ATIVO', 'Não Sensível', 'NÃO', 'NÃO'),
('clientes_seguros', 'corretor_responsavel', 'VARCHAR(100)', 'Nome do intermediário/corretor de seguros', 'Qualquer string, máx 100 caracteres', 'Obrigatório, rastreabilidade de vendas', 'João Santos', 'Não Sensível', 'NÃO', 'NÃO'),
('clientes_seguros', 'canal_venda', 'VARCHAR(50)', 'Meio pelo qual o cliente foi captado', 'Direto, Corretor, Intermediário, Online', 'Obrigatório, impacta comissão e análise', 'Direto', 'Não Sensível', 'NÃO', 'NÃO'),
('clientes_seguros', 'score_risco', 'DECIMAL(5,2)', 'Pontuação de risco do cliente (0-100)', '0.00 a 100.00', 'Calculado por modelo de scoring, maior=mais risco', '28.5', 'Não Sensível', 'NÃO', 'NÃO'),
('clientes_seguros', 'flag_inadimplente', 'CHAR(1)', 'Indicador de cliente com pagamentos em atraso', 'S ou N', 'Obrigatório, baseado em histórico financeiro', 'N', 'Não Sensível', 'NÃO', 'NÃO'),
('clientes_seguros', 'data_atualizacao', 'TIMESTAMP', 'Data e hora da última atualização do registro', 'YYYY-MM-DD HH:MM:SS', 'Obrigatório, atualizado a cada mudança', '2024-01-10 10:30:45', 'Não Sensível', 'NÃO', 'NÃO'),
('data_dictionary', 'nome_tabela', 'VARCHAR(50)', 'Nome da tabela no banco de dados', 'Qualquer nome válido SQL', 'Obrigatório, deve existir no schema', 'clientes_seguros', 'Não Sensível', 'NÃO', 'NÃO'),
('data_dictionary', 'nome_coluna', 'VARCHAR(50)', 'Nome da coluna/campo na tabela', 'Qualquer nome válido SQL', 'Obrigatório, deve existir na tabela', 'id_cliente', 'Não Sensível', 'NÃO', 'NÃO'),
('data_dictionary', 'tipo_dado', 'VARCHAR(50)', 'Tipo de dado SQL da coluna', 'INT, VARCHAR, DECIMAL, DATE, CHAR, TIMESTAMP', 'Obrigatório, deve ser válido', 'INT', 'Não Sensível', 'NÃO', 'NÃO'),
('data_dictionary', 'descricao_coluna', 'VARCHAR(255)', 'Descrição em linguagem natural do campo', 'Texto livre explicativo', 'Obrigatório, máx 255 caracteres', 'Identificador único do cliente', 'Não Sensível', 'NÃO', 'NÃO'),
('data_dictionary', 'dominio_valores', 'VARCHAR(100)', 'Valores possíveis ou intervalo aceito', 'Texto descritivo do domínio', 'Recomendado, facilita validação', '1 a 999999', 'Não Sensível', 'NÃO', 'SIM'),
('data_dictionary', 'regra_negocio', 'VARCHAR(255)', 'Regra de negócio ou validação aplicável', 'Descrição da regra', 'Recomendado, documenta constraints', 'Deve ser único', 'Não Sensível', 'NÃO', 'SIM'),
('data_dictionary', 'exemplo_valor', 'VARCHAR(50)', 'Exemplo de valor real válido', 'Valor exemplo conforme tipo', 'Recomendado, facilita compreensão', '1001', 'Não Sensível', 'NÃO', 'SIM'),
('data_dictionary', 'sensibilidade_lgpd', 'VARCHAR(20)', 'Classificação de sensibilidade conforme LGPD', 'Não Sensível, Sensível, Altamente Sensível', 'Obrigatório, compliance com LGPD/GDPR', 'Não Sensível', 'Não Sensível', 'NÃO', 'NÃO'),
('data_dictionary', 'chave_primaria', 'VARCHAR(3)', 'Indica se é chave primária da tabela', 'SIM ou NÃO', 'Obrigatório, apenas uma por tabela', 'SIM', 'Não Sensível', 'NÃO', 'NÃO'),
('data_dictionary', 'aceita_nulos', 'VARCHAR(3)', 'Indica se o campo pode conter valores NULL', 'SIM ou NÃO', 'Obrigatório, constraints NOT NULL se NÃO', 'NÃO', 'Não Sensível', 'NÃO', 'NÃO');

-- ============================================================================
-- FIM DAS INSERÇÕES - Dados prontos para testes de análise estatística
-- ============================================================================

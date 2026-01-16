# =========================================
# Data Dictionary Simulator
# =========================================

data_dictionary = [
    {
        "tabela": "clientes_seguros",
        "coluna": "id_cliente",
        "tipo": "INT",
        "descricao": "Identificador único do cliente",
        "dominio": "Numérico sequencial",
        "regra_negocio": "Gerado pelo sistema",
        "exemplo": "1",
        "sensibilidade_lgpd": "Baixa",
        "chave_primaria": True,
        "aceita_nulos": False
    },
    {
        "tabela": "clientes_seguros",
        "coluna": "nome_cliente",
        "tipo": "VARCHAR(100)",
        "descricao": "Nome completo do cliente",
        "dominio": "Texto livre",
        "regra_negocio": "Obrigatório",
        "exemplo": "Maria Silva",
        "sensibilidade_lgpd": "Alta",
        "chave_primaria": False,
        "aceita_nulos": False
    },
    {
        "tabela": "clientes_seguros",
        "coluna": "cpf",
        "tipo": "CHAR(11)",
        "descricao": "CPF do cliente",
        "dominio": "Somente números",
        "regra_negocio": "Obrigatório e único",
        "exemplo": "12345678901",
        "sensibilidade_lgpd": "Alta",
        "chave_primaria": False,
        "aceita_nulos": False
    },
    {
        "tabela": "clientes_seguros",
        "coluna": "valor_premio",
        "tipo": "DECIMAL(10,2)",
        "descricao": "Valor mensal do prêmio",
        "dominio": "Maior que zero",
        "regra_negocio": "Valor definido em contrato",
        "exemplo": "250.75",
        "sensibilidade_lgpd": "Média",
        "chave_primaria": False,
        "aceita_nulos": True
    },
    {
        "tabela": "clientes_seguros",
        "coluna": "score_risco",
        "tipo": "DECIMAL(5,2)",
        "descricao": "Score atuarial de risco",
        "dominio": "0 a 100",
        "regra_negocio": "Calculado por modelo atuarial",
        "exemplo": "72.50",
        "sensibilidade_lgpd": "Média",
        "chave_primaria": False,
        "aceita_nulos": True
    }
]


def exibir_data_dictionary(dicionario):
    print("DATA DICTIONARY\n")
    for item in dicionario:
        print(
            f"Tabela: {item['tabela']} | "
            f"Coluna: {item['coluna']} | "
            f"Tipo: {item['tipo']} | "
            f"PK: {item['chave_primaria']} | "
            f"Nulos: {item['aceita_nulos']} | "
            f"LGPD: {item['sensibilidade_lgpd']}"
        )


if __name__ == "__main__":
    exibir_data_dictionary(data_dictionary)

# Python script for data dictionary simulator
# =========================================
# Data Dictionary Simulator
# =========================================

data_dictionary = [
    {
        "tabela": "clientes_seguros",
        "coluna": "id_cliente",
        "tipo": "INT",
        "descricao": "Identificador único do cliente",
        "chave_primaria": True,
        "aceita_nulos": False
    },
    {
        "tabela": "clientes_seguros",
        "coluna": "nome_cliente",
        "tipo": "VARCHAR(100)",
        "descricao": "Nome completo do cliente",
        "chave_primaria": False,
        "aceita_nulos": False
    },
    {
        "tabela": "clientes_seguros",
        "coluna": "cpf",
        "tipo": "CHAR(11)",
        "descricao": "CPF do cliente",
        "chave_primaria": False,
        "aceita_nulos": False
    },
    {
        "tabela": "clientes_seguros",
        "coluna": "valor_premio",
        "tipo": "DECIMAL(10,2)",
        "descricao": "Valor mensal do prêmio",
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
            f"Nulos: {item['aceita_nulos']}"
        )

if __name__ == "__main__":
    exibir_data_dictionary(data_dictionary)

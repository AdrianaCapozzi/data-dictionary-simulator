# =========================================
# Data Dictionary Validator
# =========================================
# Script para validar integridade de dados contra o dicionário
# Implementa regras de negócio e verificações de qualidade

import json
from datetime import datetime
from typing import List, Dict, Tuple, Any

class DataValidator:
    """Valida dados contra regras definidas no dicionário de dados."""
    
    def __init__(self, data_dictionary: List[Dict[str, Any]]):
        """
        Inicializa o validador com um dicionário de dados.
        
        Args:
            data_dictionary: Lista com definições de colunas
        """
        self.data_dictionary = data_dictionary
        self.validation_errors = []
        self.validation_warnings = []
        
    def validate_data_type(self, column_name: str, value: Any) -> Tuple[bool, str]:
        """
        Valida se o tipo de dado corresponde à definição.
        
        Args:
            column_name: Nome da coluna
            value: Valor a validar
            
        Returns:
            Tupla (bool, mensagem_erro)
        """
        col_def = self._find_column_definition(column_name)
        if not col_def:
            return False, f"Coluna '{column_name}' não encontrada no dicionário"
        
        tipo = col_def.get('tipo', '').upper()
        
        try:
            if 'INT' in tipo and not isinstance(value, int):
                return False, f"Esperado INT, recebido {type(value).__name__}"
            elif 'VARCHAR' in tipo and not isinstance(value, str):
                return False, f"Esperado VARCHAR, recebido {type(value).__name__}"
            elif 'DECIMAL' in tipo or 'FLOAT' in tipo:
                if not isinstance(value, (int, float)):
                    return False, f"Esperado número, recebido {type(value).__name__}"
            elif 'DATE' in tipo:
                if not self._is_valid_date(value):
                    return False, f"Data inválida: {value}"
            return True, ""
        except Exception as e:
            return False, str(e)
    
    def validate_nullability(self, column_name: str, value: Any) -> Tuple[bool, str]:
        """
        Valida se nulos são aceitos para a coluna.
        
        Args:
            column_name: Nome da coluna
            value: Valor a validar
            
        Returns:
            Tupla (bool, mensagem_erro)
        """
        col_def = self._find_column_definition(column_name)
        if not col_def:
            return False, f"Coluna '{column_name}' não encontrada"
        
        if value is None and not col_def.get('aceita_nulos', True):
            return False, f"Coluna '{column_name}' não aceita valores nulos"
        
        return True, ""
    
    def validate_primary_key(self, column_name: str, value: Any) -> Tuple[bool, str]:
        """
        Valida se a chave primária está preenchida.
        
        Args:
            column_name: Nome da coluna
            value: Valor a validar
            
        Returns:
            Tupla (bool, mensagem_erro)
        """
        col_def = self._find_column_definition(column_name)
        if not col_def:
            return False, f"Coluna '{column_name}' não encontrada"
        
        if col_def.get('chave_primaria', False) and value is None:
            return False, f"Chave primária '{column_name}' não pode ser nula"
        
        return True, ""
    
    def validate_row(self, table_name: str, row_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Valida uma linha completa de dados.
        
        Args:
            table_name: Nome da tabela
            row_data: Dicionário com dados da linha
            
        Returns:
            Dicionário com resultados da validação
        """
        self.validation_errors.clear()
        self.validation_warnings.clear()
        
        for column_name, value in row_data.items():
            col_def = self._find_column_definition(column_name)
            if not col_def or col_def.get('tabela') != table_name:
                self.validation_warnings.append(f"Coluna '{column_name}' não pertence à tabela '{table_name}'")
                continue
            
            # Validações sequenciais
            is_valid, msg = self.validate_primary_key(column_name, value)
            if not is_valid:
                self.validation_errors.append(msg)
                continue
            
            is_valid, msg = self.validate_nullability(column_name, value)
            if not is_valid:
                self.validation_errors.append(msg)
                continue
            
            is_valid, msg = self.validate_data_type(column_name, value)
            if not is_valid:
                self.validation_errors.append(msg)
                continue
        
        return {
            'valid': len(self.validation_errors) == 0,
            'errors': self.validation_errors,
            'warnings': self.validation_warnings,
            'timestamp': datetime.now().isoformat()
        }
    
    def generate_validation_report(self, data_rows: List[Dict[str, Any]], 
                                  table_name: str) -> Dict[str, Any]:
        """
        Gera relatório de validação para múltiplas linhas.
        
        Args:
            data_rows: Lista de linhas a validar
            table_name: Nome da tabela
            
        Returns:
            Dicionário com estatísticas de validação
        """
        total_rows = len(data_rows)
        valid_rows = 0
        invalid_rows = 0
        all_errors = []
        
        for idx, row in enumerate(data_rows, 1):
            result = self.validate_row(table_name, row)
            if result['valid']:
                valid_rows += 1
            else:
                invalid_rows += 1
                for error in result['errors']:
                    all_errors.append({
                        'row_number': idx,
                        'error': error
                    })
        
        return {
            'table': table_name,
            'total_rows': total_rows,
            'valid_rows': valid_rows,
            'invalid_rows': invalid_rows,
            'success_rate': f"{(valid_rows / total_rows * 100):.2f}%" if total_rows > 0 else "0%",
            'errors': all_errors,
            'generated_at': datetime.now().isoformat()
        }
    
    def _find_column_definition(self, column_name: str) -> Dict[str, Any]:
        """Encontra definição da coluna no dicionário."""
        for col_def in self.data_dictionary:
            if col_def.get('coluna') == column_name:
                return col_def
        return None
    
    @staticmethod
    def _is_valid_date(date_value: str) -> bool:
        """Valida formato de data ISO."""
        try:
            datetime.fromisoformat(date_value)
            return True
        except (ValueError, TypeError):
            return False


class SensitivityClassifier:
    """Classifica e monitora dados sensíveis por LGPD."""
    
    @staticmethod
    def classify_sensitivity(data_dictionary: List[Dict[str, Any]]) -> Dict[str, List[str]]:
        """
        Classifica colunas por nível de sensibilidade LGPD.
        
        Args:
            data_dictionary: Dicionário de dados
            
        Returns:
            Dicionário agrupado por nível de sensibilidade
        """
        classified = {'Alta': [], 'Média': [], 'Baixa': []}
        
        for col in data_dictionary:
            sensitivity = col.get('sensibilidade_lgpd', 'Baixa')
            col_name = col.get('coluna', 'desconhecido')
            
            if sensitivity in classified:
                classified[sensitivity].append(col_name)
        
        return classified
    
    @staticmethod
    def generate_compliance_report(data_dictionary: List[Dict[str, Any]]) -> Dict[str, Any]:
        """Gera relatório de conformidade LGPD."""
        sensitive_cols = [
            col for col in data_dictionary 
            if col.get('sensibilidade_lgpd') == 'Alta'
        ]
        
        return {
            'total_columns': len(data_dictionary),
            'sensitive_columns': len(sensitive_cols),
            'sensitive_column_names': [col.get('coluna') for col in sensitive_cols],
            'requires_encryption': len(sensitive_cols) > 0,
            'compliance_status': 'REQUER ATENÇÃO' if len(sensitive_cols) > 0 else 'OK'
        }


if __name__ == '__main__':
    # Exemplo de uso
    from dictionary_simulator import data_dictionary
    
    validator = DataValidator(data_dictionary)
    classifier = SensitivityClassifier()
    
    # Teste de validação
    test_row = {
        'id_cliente': 1,
        'nome_cliente': 'João Silva',
        'cpf': '12345678901',
        'valor_premio': 150.50,
        'tipo_seguro': 'AUTOMOVEL'
    }
    
    result = validator.validate_row('clientes_seguros', test_row)
    print("Resultado da validação:", json.dumps(result, indent=2, ensure_ascii=False))
    
    # Relatório de sensibilidade
    sensitivity = classifier.classify_sensitivity(data_dictionary)
    print("\nClassificação por Sensibilidade:", json.dumps(sensitivity, indent=2, ensure_ascii=False))
    
    # Relatório LGPD
    compliance = classifier.generate_compliance_report(data_dictionary)
    print("\nRelatório de Conformidade LGPD:", json.dumps(compliance, indent=2, ensure_ascii=False))

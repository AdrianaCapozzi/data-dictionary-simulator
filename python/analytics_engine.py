# =========================================
# Analytics Engine - Data Dictionary
# =========================================
# Engine de análise para gerar estatísticas e insights
# sobre o dicionário de dados e qualidade

from typing import List, Dict, Any, Optional
from collections import Counter, defaultdict
from datetime import datetime
import statistics

class DictionaryAnalytics:
    """Analisa padrões e características do dicionário de dados."""
    
    def __init__(self, data_dictionary: List[Dict[str, Any]]):
        """Inicializa o engine de análise."""
        self.data_dictionary = data_dictionary
        self.tables = self._extract_tables()
    
    def _extract_tables(self) -> Dict[str, List[Dict[str, Any]]]:
        """Extrai colunas agrupadas por tabela."""
        tables = defaultdict(list)
        for col in self.data_dictionary:
            table_name = col.get('tabela', 'unknown')
            tables[table_name].append(col)
        return dict(tables)
    
    def get_table_statistics(self) -> Dict[str, Any]:
        """
        Retorna estatísticas gerais do dicionário.
        
        Returns:
            Dicionário com estatísticas
        """
        total_tables = len(self.tables)
        total_columns = len(self.data_dictionary)
        
        columns_per_table = [len(cols) for cols in self.tables.values()]
        
        pk_count = sum(1 for col in self.data_dictionary if col.get('chave_primaria'))
        nullable_count = sum(1 for col in self.data_dictionary if col.get('aceita_nulos'))
        
        return {
            'total_tables': total_tables,
            'total_columns': total_columns,
            'avg_columns_per_table': round(total_columns / total_tables, 2) if total_tables > 0 else 0,
            'min_columns_per_table': min(columns_per_table) if columns_per_table else 0,
            'max_columns_per_table': max(columns_per_table) if columns_per_table else 0,
            'primary_keys': pk_count,
            'nullable_columns': nullable_count,
            'non_nullable_columns': total_columns - nullable_count,
            'timestamp': datetime.now().isoformat()
        }
    
    def analyze_data_types(self) -> Dict[str, int]:
        """
        Analisa distribuição de tipos de dados.
        
        Returns:
            Contagem de cada tipo de dado
        """
        type_counter = Counter()
        
        for col in self.data_dictionary:
            col_type = col.get('tipo', 'UNKNOWN').upper()
            # Normaliza tipos (ex: VARCHAR(100) -> VARCHAR)
            base_type = col_type.split('(')[0]
            type_counter[base_type] += 1
        
        return dict(sorted(type_counter.items(), key=lambda x: x[1], reverse=True))
    
    def analyze_sensitivity_distribution(self) -> Dict[str, Any]:
        """
        Analisa distribuição de sensibilidade LGPD.
        
        Returns:
            Estatísticas de sensibilidade
        """
        sensitivity_counter = Counter()
        
        for col in self.data_dictionary:
            sensitivity = col.get('sensibilidade_lgpd', 'Não classificado')
            sensitivity_counter[sensitivity] += 1
        
        total = len(self.data_dictionary)
        
        return {
            'distribution': dict(sensitivity_counter),
            'percentages': {
                sens: round((count / total * 100), 2)
                for sens, count in sensitivity_counter.items()
            },
            'high_sensitivity_count': sensitivity_counter['Alta'],
            'requires_protection': sensitivity_counter['Alta'] + sensitivity_counter['Média']
        }
    
    def analyze_business_rules(self) -> Dict[str, Any]:
        """
        Analisa regras de negócio documentadas.
        
        Returns:
            Análise de regras por categoria
        """
        rules_by_type = defaultdict(list)
        
        for col in self.data_dictionary:
            rule = col.get('regra_negocio', 'Nenhuma')
            table = col.get('tabela', 'unknown')
            col_name = col.get('coluna', 'unknown')
            
            if 'Obrigatório' in rule:
                rules_by_type['obrigatorias'].append(f"{table}.{col_name}")
            elif 'Único' in rule:
                rules_by_type['unicas'].append(f"{table}.{col_name}")
            elif 'Sequencial' in rule or 'Gerado' in rule:
                rules_by_type['auto_generated'].append(f"{table}.{col_name}")
        
        return {
            'obrigatorias': len(rules_by_type['obrigatorias']),
            'unicas': len(rules_by_type['unicas']),
            'auto_generated': len(rules_by_type['auto_generated']),
            'details': {
                'obrigatorias': rules_by_type['obrigatorias'],
                'unicas': rules_by_type['unicas'],
                'auto_generated': rules_by_type['auto_generated']
            }
        }
    
    def get_table_detail(self, table_name: str) -> Dict[str, Any]:
        """
        Retorna detalhes completos de uma tabela específica.
        
        Args:
            table_name: Nome da tabela
            
        Returns:
            Dicionário com detalhes da tabela
        """
        table_cols = self.tables.get(table_name, [])
        
        if not table_cols:
            return {'error': f'Tabela {table_name} não encontrada'}
        
        return {
            'table_name': table_name,
            'column_count': len(table_cols),
            'primary_keys': [col['coluna'] for col in table_cols if col.get('chave_primaria')],
            'nullable_columns': [col['coluna'] for col in table_cols if col.get('aceita_nulos')],
            'high_sensitivity_cols': [
                col['coluna'] for col in table_cols 
                if col.get('sensibilidade_lgpd') == 'Alta'
            ],
            'data_types': dict(Counter(col.get('tipo', 'UNKNOWN').split('(')[0] for col in table_cols)),
            'columns': table_cols
        }
    
    def compare_tables(self) -> Dict[str, Any]:
        """
        Compara características entre tabelas.
        
        Returns:
            Análise comparativa das tabelas
        """
        comparison = {}
        
        for table_name, cols in self.tables.items():
            pk_cols = [col['coluna'] for col in cols if col.get('chave_primaria')]
            high_sens = [col['coluna'] for col in cols if col.get('sensibilidade_lgpd') == 'Alta']
            
            comparison[table_name] = {
                'columns': len(cols),
                'primary_keys': len(pk_cols),
                'high_sensitivity_columns': len(high_sens),
                'nullable_percentage': round(sum(1 for col in cols if col.get('aceita_nulos')) / len(cols) * 100, 2)
            }
        
        return comparison
    
    def generate_full_report(self) -> Dict[str, Any]:
        """
        Gera relatório completo de análise.
        
        Returns:
            Relatório consolidado
        """
        return {
            'report_type': 'DATA_DICTIONARY_ANALYSIS',
            'generated_at': datetime.now().isoformat(),
            'general_statistics': self.get_table_statistics(),
            'data_types_distribution': self.analyze_data_types(),
            'sensitivity_analysis': self.analyze_sensitivity_distribution(),
            'business_rules_analysis': self.analyze_business_rules(),
            'table_comparison': self.compare_tables()
        }


class QualityMetrics:
    """Calcula métricas de qualidade do dicionário."""
    
    @staticmethod
    def calculate_documentation_completeness(col: Dict[str, Any]) -> float:
        """
        Calcula percentual de documentação de uma coluna.
        
        Args:
            col: Definição de coluna
            
        Returns:
            Percentual de completude (0-100)
        """
        required_fields = ['coluna', 'tipo', 'descricao', 'dominio', 'regra_negocio']
        filled = sum(1 for field in required_fields if col.get(field) and col.get(field).strip())
        return round((filled / len(required_fields)) * 100, 2)
    
    @staticmethod
    def analyze_documentation_quality(data_dictionary: List[Dict[str, Any]]) -> Dict[str, Any]:
        """
        Analisa qualidade de documentação do dicionário.
        
        Args:
            data_dictionary: Lista de definições de colunas
            
        Returns:
            Métricas de qualidade
        """
        completeness_scores = [
            QualityMetrics.calculate_documentation_completeness(col)
            for col in data_dictionary
        ]
        
        poorly_documented = [
            col['coluna'] for col in data_dictionary
            if QualityMetrics.calculate_documentation_completeness(col) < 80
        ]
        
        return {
            'average_completeness': round(statistics.mean(completeness_scores), 2),
            'min_completeness': round(min(completeness_scores), 2),
            'max_completeness': round(max(completeness_scores), 2),
            'std_deviation': round(statistics.stdev(completeness_scores), 2) if len(completeness_scores) > 1 else 0,
            'columns_needing_improvement': poorly_documented,
            'quality_score': 'EXCELENTE' if statistics.mean(completeness_scores) >= 90 else 'BOA' if statistics.mean(completeness_scores) >= 80 else 'REQUER_MELHORIA'
        }


if __name__ == '__main__':
    import json
    from dictionary_simulator import data_dictionary
    
    analytics = DictionaryAnalytics(data_dictionary)
    quality = QualityMetrics()
    
    # Gera relatório completo
    report = analytics.generate_full_report()
    print("=== RELATÓRIO DE ANÁLISE ===")
    print(json.dumps(report, indent=2, ensure_ascii=False))
    
    # Análise de qualidade
    quality_report = quality.analyze_documentation_quality(data_dictionary)
    print("\n=== ANÁLISE DE QUALIDADE ===")
    print(json.dumps(quality_report, indent=2, ensure_ascii=False))

# =========================================
# Data Dictionary Report Generator
# =========================================
# Gerador de relatórios e documentação a partir do dicionário

import json
import csv
from typing import List, Dict, Any
from datetime import datetime
from collections import defaultdict
import os

class ReportGenerator:
    """Gera relatórios em múltiplos formatos a partir do dicionário de dados."""
    
    def __init__(self, data_dictionary: List[Dict[str, Any]], 
                 output_dir: str = './reports'):
        """Inicializa o gerador de relatórios."""
        self.data_dictionary = data_dictionary
        self.output_dir = output_dir
        self.tables = self._group_by_table()
        self._ensure_output_dir()
    
    def _group_by_table(self) -> Dict[str, List[Dict[str, Any]]]:
        """Agrupa colunas por tabela."""
        grouped = defaultdict(list)
        for col in self.data_dictionary:
            table = col.get('tabela', 'unknown')
            grouped[table].append(col)
        return dict(grouped)
    
    def _ensure_output_dir(self):
        """Cria diretório de saída se não existir."""
        if not os.path.exists(self.output_dir):
            os.makedirs(self.output_dir)
    
    def generate_csv_report(self, filename: str = 'data_dictionary.csv') -> str:
        """
        Gera relatório em formato CSV.
        
        Args:
            filename: Nome do arquivo
            
        Returns:
            Caminho do arquivo gerado
        """
        filepath = os.path.join(self.output_dir, filename)
        
        with open(filepath, 'w', newline='', encoding='utf-8') as f:
            writer = csv.DictWriter(f, fieldnames=self._get_fieldnames())
            writer.writeheader()
            writer.writerows(self.data_dictionary)
        
        return filepath
    
    def generate_html_report(self, filename: str = 'data_dictionary.html') -> str:
        """
        Gera relatório em formato HTML.
        
        Args:
            filename: Nome do arquivo
            
        Returns:
            Caminho do arquivo gerado
        """
        filepath = os.path.join(self.output_dir, filename)
        
        html_content = f"""
        <!DOCTYPE html>
        <html lang="pt-br">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Dicionário de Dados</title>
            <style>
                body {{ font-family: Arial, sans-serif; margin: 20px; background-color: #f5f5f5; }}
                .container {{ max-width: 1200px; margin: 0 auto; background-color: white; padding: 20px; }}
                h1, h2 {{ color: #333; }}
                table {{ 
                    width: 100%; 
                    border-collapse: collapse; 
                    margin: 20px 0;
                    box-shadow: 0 2px 4px rgba(0,0,0,0.1);
                }}
                th {{ 
                    background-color: #2c3e50; 
                    color: white; 
                    padding: 12px; 
                    text-align: left;
                    font-weight: bold;
                }}
                td {{ 
                    padding: 10px; 
                    border-bottom: 1px solid #ddd;
                }}
                tr:hover {{ background-color: #f9f9f9; }}
                .sensibilidade-alta {{ background-color: #ffebee; }}
                .sensibilidade-media {{ background-color: #fff3e0; }}
                .sensibilidade-baixa {{ background-color: #f1f8e9; }}
                .pk {{ font-weight: bold; color: #d32f2f; }}
                .nullable {{ color: #1976d2; }}
                .summary {{ 
                    background-color: #ecf0f1; 
                    padding: 15px; 
                    border-left: 4px solid #3498db;
                    margin: 20px 0;
                }}
                .table-section {{ margin: 30px 0; page-break-inside: avoid; }}
                .footer {{ 
                    margin-top: 40px; 
                    padding-top: 20px; 
                    border-top: 1px solid #ddd; 
                    font-size: 12px; 
                    color: #666;
                }}
            </style>
        </head>
        <body>
            <div class="container">
                <h1>📚 Dicionário de Dados</h1>
                <p><strong>Data de Geração:</strong> {datetime.now().strftime('%d/%m/%Y %H:%M:%S')}</p>
                
                <div class="summary">
                    <h3>📊 Resumo</h3>
                    <p><strong>Total de Tabelas:</strong> {len(self.tables)}</p>
                    <p><strong>Total de Colunas:</strong> {len(self.data_dictionary)}</p>
                    <p><strong>Colunas com Sensibilidade Alta:</strong> {sum(1 for col in self.data_dictionary if col.get('sensibilidade_lgpd') == 'Alta')}</p>
                    <p><strong>Chaves Primárias:</strong> {sum(1 for col in self.data_dictionary if col.get('chave_primaria'))}</p>
                </div>
                
                {self._generate_html_table_sections()}
                
                <div class="footer">
                    <p>Este documento foi gerado automaticamente e deve ser mantido atualizado.</p>
                </div>
            </div>
        </body>
        </html>
        """
        
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(html_content)
        
        return filepath
    
    def _generate_html_table_sections(self) -> str:
        """Gera seções de tabelas em HTML."""
        sections = []
        
        for table_name, columns in sorted(self.tables.items()):
            section_html = f'<div class="table-section"><h2>Tabela: {table_name}</h2>'
            section_html += '<table>'
            section_html += '''
                <thead>
                    <tr>
                        <th>Coluna</th>
                        <th>Tipo</th>
                        <th>Descrição</th>
                        <th>PK</th>
                        <th>Nulo</th>
                        <th>Sensibilidade</th>
                        <th>Regra de Negócio</th>
                    </tr>
                </thead>
                <tbody>
            '''
            
            for col in columns:
                sensibilidade = col.get('sensibilidade_lgpd', 'Baixa')
                sensibilidade_class = f'sensibilidade-{sensibilidade.lower()}'
                pk_icon = '🔑' if col.get('chave_primaria') else ''
                nullable = '✓' if col.get('aceita_nulos') else '✗'
                
                section_html += f'''
                    <tr class="{sensibilidade_class}">
                        <td><strong>{col.get('coluna', 'N/A')}</strong> {pk_icon}</td>
                        <td>{col.get('tipo', 'N/A')}</td>
                        <td>{col.get('descricao', 'N/A')}</td>
                        <td>{('Sim' if col.get('chave_primaria') else 'Não')}</td>
                        <td>{nullable}</td>
                        <td>{sensibilidade}</td>
                        <td>{col.get('regra_negocio', 'Nenhuma')}</td>
                    </tr>
                '''
            
            section_html += '</tbody></table></div>'
            sections.append(section_html)
        
        return ''.join(sections)
    
    def generate_json_report(self, filename: str = 'data_dictionary.json') -> str:
        """
        Gera relatório em formato JSON.
        
        Args:
            filename: Nome do arquivo
            
        Returns:
            Caminho do arquivo gerado
        """
        filepath = os.path.join(self.output_dir, filename)
        
        report = {
            'generated_at': datetime.now().isoformat(),
            'summary': {
                'total_tables': len(self.tables),
                'total_columns': len(self.data_dictionary),
                'high_sensitivity_columns': sum(
                    1 for col in self.data_dictionary 
                    if col.get('sensibilidade_lgpd') == 'Alta'
                ),
                'primary_keys': sum(
                    1 for col in self.data_dictionary 
                    if col.get('chave_primaria')
                )
            },
            'tables': {
                table: {
                    'column_count': len(columns),
                    'columns': columns
                }
                for table, columns in self.tables.items()
            }
        }
        
        with open(filepath, 'w', encoding='utf-8') as f:
            json.dump(report, f, indent=2, ensure_ascii=False)
        
        return filepath
    
    def generate_markdown_report(self, filename: str = 'DATA_DICTIONARY.md') -> str:
        """
        Gera relatório em formato Markdown.
        
        Args:
            filename: Nome do arquivo
            
        Returns:
            Caminho do arquivo gerado
        """
        filepath = os.path.join(self.output_dir, filename)
        
        md_content = f"""# 📚 Dicionário de Dados

**Data de Geração:** {datetime.now().strftime('%d/%m/%Y %H:%M:%S')}

## 📊 Resumo Executivo

- **Total de Tabelas:** {len(self.tables)}
- **Total de Colunas:** {len(self.data_dictionary)}
- **Colunas com Sensibilidade Alta:** {sum(1 for col in self.data_dictionary if col.get('sensibilidade_lgpd') == 'Alta')}
- **Chaves Primárias:** {sum(1 for col in self.data_dictionary if col.get('chave_primaria'))}

## 📋 Tabelas

"""
        
        for table_name, columns in sorted(self.tables.items()):
            md_content += f"\n### {table_name}\n\n"
            md_content += "| Coluna | Tipo | PK | Nulo | Sensibilidade | Descrição | Regra |\n"
            md_content += "|--------|------|----|----|---|---|---|\n"
            
            for col in columns:
                pk = "🔑" if col.get('chave_primaria') else ""
                nullable = "✓" if col.get('aceita_nulos') else "✗"
                sensibilidade = col.get('sensibilidade_lgpd', 'Baixa')
                
                md_content += (
                    f"| {col.get('coluna')} | {col.get('tipo')} | {pk} | {nullable} | "
                    f"{sensibilidade} | {col.get('descricao')} | {col.get('regra_negocio')} |\n"
                )
        
        md_content += f"\n---\n\n_Gerado automaticamente em {datetime.now().isoformat()}_\n"
        
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(md_content)
        
        return filepath
    
    def generate_sql_ddl(self, filename: str = 'ddl_tables.sql') -> str:
        """
        Gera comandos SQL CREATE TABLE.
        
        Args:
            filename: Nome do arquivo
            
        Returns:
            Caminho do arquivo gerado
        """
        filepath = os.path.join(self.output_dir, filename)
        sql_content = ""
        
        for table_name, columns in self.tables.items():
            sql_content += f"\n-- Tabela: {table_name}\n"
            sql_content += f"CREATE TABLE {table_name} (\n"
            
            column_defs = []
            pk_columns = [col['coluna'] for col in columns if col.get('chave_primaria')]
            
            for col in columns:
                col_def = f"    {col.get('coluna')} {col.get('tipo')}"
                
                if not col.get('aceita_nulos'):
                    col_def += " NOT NULL"
                
                if col.get('chave_primaria'):
                    col_def += " PRIMARY KEY"
                
                col_def += f" -- {col.get('descricao', 'N/A')}"
                column_defs.append(col_def)
            
            sql_content += ",\n".join(column_defs)
            sql_content += "\n);\n\n"
        
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(sql_content)
        
        return filepath
    
    def generate_all_reports(self) -> Dict[str, str]:
        """
        Gera todos os relatórios disponíveis.
        
        Returns:
            Dicionário com caminhos dos arquivos gerados
        """
        reports = {
            'csv': self.generate_csv_report(),
            'html': self.generate_html_report(),
            'json': self.generate_json_report(),
            'markdown': self.generate_markdown_report(),
            'sql': self.generate_sql_ddl()
        }
        
        return reports
    
    @staticmethod
    def _get_fieldnames() -> List[str]:
        """Retorna nomes dos campos para CSV."""
        return [
            'tabela', 'coluna', 'tipo', 'descricao', 'dominio',
            'regra_negocio', 'exemplo', 'sensibilidade_lgpd',
            'chave_primaria', 'aceita_nulos'
        ]


class DocumentationBuilder:
    """Constrói documentação técnica a partir do dicionário."""
    
    def __init__(self, data_dictionary: List[Dict[str, Any]]):
        self.data_dictionary = data_dictionary
    
    def build_entity_relationship_diagram(self) -> Dict[str, Any]:
        """
        Constrói descrição do diagrama entidade-relacionamento.
        
        Returns:
            Dicionário com estrutura do ERD
        """
        entities = {}
        
        for col in self.data_dictionary:
            table = col.get('tabela', 'unknown')
            if table not in entities:
                entities[table] = {
                    'attributes': [],
                    'primary_keys': [],
                    'foreign_keys': []
                }
            
            attribute = {
                'name': col.get('coluna'),
                'type': col.get('tipo'),
                'nullable': col.get('aceita_nulos')
            }
            entities[table]['attributes'].append(attribute)
            
            if col.get('chave_primaria'):
                entities[table]['primary_keys'].append(col.get('coluna'))
        
        return entities
    
    def build_data_lineage(self) -> Dict[str, Any]:
        """
        Constrói informações sobre linhagem de dados.
        
        Returns:
            Dicionário com informações de linhagem
        """
        return {
            'sources': self._identify_data_sources(),
            'transformations': self._identify_transformations(),
            'destinations': self._identify_destinations()
        }
    
    def _identify_data_sources(self) -> List[str]:
        """Identifica fontes de dados."""
        tables = set()
        for col in self.data_dictionary:
            tables.add(col.get('tabela', 'unknown'))
        return list(tables)
    
    def _identify_transformations(self) -> List[str]:
        """Identifica transformações aplicadas."""
        transformations = []
        for col in self.data_dictionary:
            rule = col.get('regra_negocio', '')
            if 'Gerado' in rule or 'Calculado' in rule:
                transformations.append(f"{col.get('coluna')} - {rule}")
        return transformations
    
    def _identify_destinations(self) -> List[str]:
        """Identifica destinos dos dados."""
        # Placeholder para lógica customizada
        return ['Data Warehouse', 'Analytics Platform']


if __name__ == '__main__':
    from dictionary_simulator import data_dictionary
    
    # Gera todos os relatórios
    generator = ReportGenerator(data_dictionary, output_dir='./data_dictionary_reports')
    reports = generator.generate_all_reports()
    
    print("✅ Relatórios gerados com sucesso:")
    for report_type, filepath in reports.items():
        print(f"  - {report_type.upper()}: {filepath}")
    
    # Constrói documentação
    doc_builder = DocumentationBuilder(data_dictionary)
    erd = doc_builder.build_entity_relationship_diagram()
    lineage = doc_builder.build_data_lineage()
    
    print("\n✅ Documentação construída:")
    print(f"  - Entidades: {len(erd)}")
    print(f"  - Fontes de Dados: {len(lineage['sources'])}")

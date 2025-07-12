import ast
import json
import os
import sys
from datetime import datetime


class OdooModuleAnalyzer(ast.NodeVisitor):
    def __init__(self):
        self.models = []
        self.fields = []
        self.methods = []
        self.controllers = []
        self.current_class = None
        self.current_file = None

    def visit_ClassDef(self, node):
        self.current_class = node.name

        # Check if it's an Odoo model
        bases = [base.id if hasattr(base, 'id') else str(base) for base in node.bases]
        if any('Model' in base for base in bases):
            model_info = {
                'name': node.name,
                'file': self.current_file,
                'docstring': ast.get_docstring(node),
                'bases': bases,
                'fields': [],
                'methods': [],
                'line_number': node.lineno,
            }
            self.models.append(model_info)

        # Check if it's a controller
        if any('Controller' in base for base in bases):
            controller_info = {
                'name': node.name,
                'file': self.current_file,
                'docstring': ast.get_docstring(node),
                'routes': [],
                'methods': [],
                'line_number': node.lineno,
            }
            self.controllers.append(controller_info)

        self.generic_visit(node)
        self.current_class = None

    def visit_Assign(self, node):
        # Detect field assignments in models
        if self.current_class and len(node.targets) == 1:
            target = node.targets[0]
            if hasattr(target, 'id'):
                field_name = target.id
                field_type = self._extract_field_type(node.value)
                if field_type:
                    field_info = {
                        'name': field_name,
                        'type': field_type,
                        'class': self.current_class,
                        'file': self.current_file,
                        'line_number': node.lineno,
                    }
                    self.fields.append(field_info)

        self.generic_visit(node)

    def visit_FunctionDef(self, node):
        if self.current_class:
            method_info = {
                'name': node.name,
                'class': self.current_class,
                'file': self.current_file,
                'docstring': ast.get_docstring(node),
                'args': [arg.arg for arg in node.args.args],
                'decorators': [dec.id if hasattr(dec, 'id') else str(dec) for dec in node.decorator_list],
                'line_number': node.lineno,
                'is_api_method': any('api.' in str(dec) for dec in node.decorator_list),
                'is_route': any('route' in str(dec) for dec in node.decorator_list),
            }
            self.methods.append(method_info)

        self.generic_visit(node)

    def _extract_field_type(self, node):
        """Extract Odoo field type from assignment."""
        if hasattr(node, 'func') and hasattr(node.func, 'attr'):
            if hasattr(node.func, 'value') and hasattr(node.func.value, 'id'):
                if node.func.value.id == 'fields':
                    return f"fields.{node.func.attr}"
        elif hasattr(node, 'attr'):
            return node.attr
        return None


def analyze_python_file(file_path):
    """Analyze a Python file for Odoo structures."""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()

        tree = ast.parse(content)
        analyzer = OdooModuleAnalyzer()
        analyzer.current_file = file_path
        analyzer.visit(tree)

        return {
            'models': analyzer.models,
            'fields': analyzer.fields,
            'methods': analyzer.methods,
            'controllers': analyzer.controllers,
        }
    except Exception as e:
        print(f"Error analyzing {file_path}: {e}")
        return {'models': [], 'fields': [], 'methods': [], 'controllers': []}


def analyze_xml_file(file_path):
    """Analyze XML files for views and data."""
    try:
        import xml.etree.ElementTree as ET

        tree = ET.parse(file_path)
        root = tree.getroot()

        views = []
        actions = []
        menus = []

        for record in root.findall('.//record'):
            model = record.get('model', '')
            record_id = record.get('id', '')

            if 'view' in model:
                view_type = None
                for field in record.findall('.//field[@name="arch"]'):
                    arch = field.find('*')
                    if arch is not None:
                        view_type = arch.tag
                        break

                views.append({'id': record_id, 'model': model, 'type': view_type, 'file': file_path})
            elif 'action' in model:
                actions.append({'id': record_id, 'model': model, 'file': file_path})
            elif 'menu' in model:
                menus.append({'id': record_id, 'model': model, 'file': file_path})

        return {'views': views, 'actions': actions, 'menus': menus}
    except Exception as e:
        print(f"Error analyzing XML {file_path}: {e}")
        return {'views': [], 'actions': [], 'menus': []}


def analyze_manifest(manifest_path):
    """Analyze module manifest file."""
    try:
        with open(manifest_path, 'r', encoding='utf-8') as f:
            content = f.read()

        # Safely evaluate the manifest
        manifest_dict = ast.literal_eval(content)
        return manifest_dict
    except Exception as e:
        print(f"Error analyzing manifest {manifest_path}: {e}")
        return {}


def analyze_module(module_path):
    """Analyze complete Odoo module."""
    module_name = os.path.basename(module_path)

    analysis = {
        'module_name': module_name,
        'module_path': module_path,
        'analysis_timestamp': datetime.now().isoformat(),
        'manifest': {},
        'models': [],
        'fields': [],
        'methods': [],
        'controllers': [],
        'views': [],
        'actions': [],
        'menus': [],
        'tests': [],
        'files': {'python': [], 'xml': [], 'csv': [], 'yaml': []},
    }

    # Analyze manifest
    manifest_path = os.path.join(module_path, '__manifest__.py')
    if os.path.exists(manifest_path):
        analysis['manifest'] = analyze_manifest(manifest_path)

    # Walk through module files
    for root, dirs, files in os.walk(module_path):
        for file in files:
            file_path = os.path.join(root, file)
            rel_path = os.path.relpath(file_path, module_path)

            if file.endswith('.py'):
                analysis['files']['python'].append(rel_path)

                if file != '__manifest__.py':
                    py_analysis = analyze_python_file(file_path)
                    analysis['models'].extend(py_analysis['models'])
                    analysis['fields'].extend(py_analysis['fields'])
                    analysis['methods'].extend(py_analysis['methods'])
                    analysis['controllers'].extend(py_analysis['controllers'])

                # Check if it's a test file
                if 'test' in file.lower():
                    analysis['tests'].append(rel_path)

            elif file.endswith('.xml'):
                analysis['files']['xml'].append(rel_path)
                xml_analysis = analyze_xml_file(file_path)
                analysis['views'].extend(xml_analysis['views'])
                analysis['actions'].extend(xml_analysis['actions'])
                analysis['menus'].extend(xml_analysis['menus'])

            elif file.endswith('.csv'):
                analysis['files']['csv'].append(rel_path)

            elif file.endswith(('.yml', '.yaml')):
                analysis['files']['yaml'].append(rel_path)

    return analysis


def main():
    if len(sys.argv) < 2:
        print("Usage: python analyze_module.py <module_path> [output_file]")
        sys.exit(1)

    module_path = sys.argv[1]
    output_file = sys.argv[2] if len(sys.argv) > 2 else 'module_analysis.json'

    analysis = analyze_module(module_path)

    with open(output_file, 'w') as f:
        json.dump(analysis, f, indent=2)

    print(f"Module analysis completed: {output_file}")
    print(f"Models: {len(analysis['models'])}")
    print(f"Fields: {len(analysis['fields'])}")
    print(f"Methods: {len(analysis['methods'])}")
    print(f"Controllers: {len(analysis['controllers'])}")
    print(f"Views: {len(analysis['views'])}")


if __name__ == '__main__':
    main()

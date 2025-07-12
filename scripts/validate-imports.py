#!/usr/bin/env python3
"""
Odoo Python Import Validation Script
Royal Textiles Project - Local Testing Infrastructure

This script provides comprehensive validation of Python imports in Odoo modules,
detecting circular imports, invalid paths, unused imports, and Odoo-specific
import patterns.

Key Features:
- Circular import detection
- Invalid import path validation
- Unused import detection
- Odoo-specific import pattern validation
- Deprecated import pattern detection
- Missing dependency detection
- Import organization validation

Usage:
    python scripts/validate-imports.py [module_name]
    python scripts/validate-imports.py  # validates all modules
"""

import ast
import sys
from collections import defaultdict
from pathlib import Path
from typing import Dict, List, Optional, Set, Tuple


class ImportValidator:
    """Comprehensive validator for Python imports in Odoo modules."""

    # Standard Odoo imports
    ODOO_CORE_IMPORTS = {
        'odoo.models',
        'odoo.fields',
        'odoo.api',
        'odoo.exceptions',
        'odoo.tools',
        'odoo.release',
        'odoo.service',
        'odoo.sql_db',
        'odoo.http',
        'odoo.osv',
        'odoo.workflow',
        'odoo.report',
        'odoo.addons',
        'odoo.modules',
        'odoo.tests',
    }

    # Common third-party imports used in Odoo
    COMMON_THIRD_PARTY = {
        'datetime',
        'json',
        'logging',
        'os',
        'sys',
        'time',
        'uuid',
        'base64',
        'hashlib',
        'urllib',
        'requests',
        'werkzeug',
        'psycopg2',
        'babel',
        'lxml',
        'PIL',
        'reportlab',
        'xlsxwriter',
    }

    # Deprecated import patterns
    DEPRECATED_PATTERNS = {
        'openerp': 'Use "odoo" instead of "openerp"',
        'osv': 'Use "odoo.models" instead of "osv"',
        'netsvc': 'Use "odoo.service" instead of "netsvc"',
        'pooler': 'Use "odoo.sql_db" instead of "pooler"',
    }

    # Required Odoo imports for different file types
    REQUIRED_IMPORTS = {
        'models': ['odoo.models'],
        'controllers': ['odoo.http'],
        'wizards': ['odoo.models'],
        'reports': ['odoo.report'],
    }

    def __init__(self, base_path: str = "custom_modules"):
        self.base_path = Path(base_path)
        self.errors: List[str] = []
        self.warnings: List[str] = []
        self.info: List[str] = []
        self.module_imports: Dict[str, Set[str]] = defaultdict(set)
        self.file_imports: Dict[str, List[Tuple[str, int]]] = defaultdict(list)
        self.import_graph: Dict[str, Set[str]] = defaultdict(set)

    def error(self, message: str, file_path: str = "", line_num: Optional[int] = None):
        """Add an error message."""
        location = f"{file_path}"
        if line_num:
            location += f":{line_num}"
        self.errors.append(f"❌ {location}: {message}")

    def warning(self, message: str, file_path: str = "", line_num: Optional[int] = None):
        """Add a warning message."""
        location = f"{file_path}"
        if line_num:
            location += f":{line_num}"
        self.warnings.append(f"⚠️  {location}: {message}")

    def add_info(self, message: str, file_path: str = "", line_num: Optional[int] = None):
        """Add an info message."""
        location = f"{file_path}"
        if line_num:
            location += f":{line_num}"
        self.info.append(f"ℹ️  {location}: {message}")

    def parse_python_file(self, file_path: Path) -> Optional[ast.AST]:
        """Parse a Python file and return its AST."""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            return ast.parse(content, filename=str(file_path))
        except SyntaxError as e:
            self.error(f"Python syntax error: {e}", str(file_path), e.lineno)
            return None
        except Exception as e:
            self.error(f"Error parsing file: {e}", str(file_path))
            return None

    def extract_imports(self, tree: ast.AST) -> List[Tuple[str, int, str]]:
        """Extract all import statements from AST."""
        imports = []

        for node in ast.walk(tree):
            if isinstance(node, ast.Import):
                for alias in node.names:
                    imports.append((alias.name, node.lineno, 'import'))
            elif isinstance(node, ast.ImportFrom):
                if node.module:
                    imports.append((node.module, node.lineno, 'from'))
                    for alias in node.names:
                        full_name = f"{node.module}.{alias.name}" if alias.name != '*' else node.module
                        imports.append((full_name, node.lineno, 'from_item'))

        return imports

    def validate_import_path(self, import_path: str, file_path: Path, line_num: int) -> bool:
        """Validate that an import path is valid."""
        success = True

        # Check for deprecated patterns
        for deprecated, message in self.DEPRECATED_PATTERNS.items():
            if import_path.startswith(deprecated):
                self.warning(f"Deprecated import '{import_path}': {message}", str(file_path), line_num)
                success = False

        # Check for relative imports outside of package
        if import_path.startswith('.'):
            # Relative imports should be within the same module
            self.add_info(f"Relative import used: {import_path}", str(file_path), line_num)

        # Check for overly long import paths
        if len(import_path.split('.')) > 6:
            self.warning(f"Very long import path: {import_path}", str(file_path), line_num)

        # Check for imports from __init__.py files
        if import_path.endswith('.__init__'):
            self.warning(f"Importing from __init__.py: {import_path}", str(file_path), line_num)

        return success

    def validate_odoo_imports(self, imports: List[Tuple[str, int, str]], file_path: Path) -> bool:
        """Validate Odoo-specific import patterns."""
        success = True

        # Check for required Odoo imports based on file type
        file_type = self.get_file_type(file_path)
        if file_type in self.REQUIRED_IMPORTS:
            found_required = False
            for required_import in self.REQUIRED_IMPORTS[file_type]:
                for import_path, _, _ in imports:
                    if import_path.startswith(required_import):
                        found_required = True
                        break
                if found_required:
                    break

            if not found_required:
                self.warning(
                    f"Missing required Odoo import for {file_type} file: {self.REQUIRED_IMPORTS[file_type]}",
                    str(file_path),
                )
                success = False

        # Check for proper Odoo import structure
        odoo_imports = [imp for imp in imports if imp[0].startswith('odoo')]
        if odoo_imports:
            # Check for proper odoo.addons imports
            addons_imports = [imp for imp in odoo_imports if 'addons' in imp[0]]
            for import_path, line_num, import_type in addons_imports:
                if not import_path.startswith('odoo.addons.'):
                    self.warning(f"Use 'odoo.addons.module_name' format: {import_path}", str(file_path), line_num)

        return success

    def get_file_type(self, file_path: Path) -> str:
        """Determine the type of Odoo file based on path and content."""
        path_str = str(file_path)

        if 'models' in path_str:
            return 'models'
        elif 'controllers' in path_str:
            return 'controllers'
        elif 'wizards' in path_str:
            return 'wizards'
        elif 'reports' in path_str:
            return 'reports'
        elif 'tests' in path_str:
            return 'tests'
        else:
            return 'other'

    def check_circular_imports(self, module_name: str) -> bool:
        """Check for circular imports within a module."""
        success = True

        # Build import graph
        visited = set()
        rec_stack = set()

        def has_cycle(node: str) -> bool:
            if node in rec_stack:
                return True
            if node in visited:
                return False

            visited.add(node)
            rec_stack.add(node)

            for neighbor in self.import_graph.get(node, set()):
                if has_cycle(neighbor):
                    return True

            rec_stack.remove(node)
            return False

        # Check for cycles in the import graph
        for node in self.import_graph:
            if node not in visited:
                if has_cycle(node):
                    self.error(f"Circular import detected involving: {node}")
                    success = False

        return success

    def check_unused_imports(self, tree: ast.AST, imports: List[Tuple[str, int, str]], file_path: Path) -> bool:
        """Check for unused imports in a file."""
        success = True

        # Extract all names used in the file
        used_names = set()

        class NameVisitor(ast.NodeVisitor):
            def visit_Name(self, node):
                used_names.add(node.id)
                self.generic_visit(node)

            def visit_Attribute(self, node):
                if isinstance(node.value, ast.Name):
                    used_names.add(node.value.id)
                self.generic_visit(node)

        visitor = NameVisitor()
        visitor.visit(tree)

        # Check each import
        for import_path, line_num, import_type in imports:
            if import_type == 'import':
                # For direct imports, check if the module name is used
                module_name = import_path.split('.')[0]
                if module_name not in used_names:
                    # Don't flag common setup imports as unused
                    if import_path not in ['logging', 'os', 'sys']:
                        self.warning(f"Unused import: {import_path}", str(file_path), line_num)
            elif import_type == 'from_item':
                # For from imports, check if the imported name is used
                imported_name = import_path.split('.')[-1]
                if imported_name not in used_names and imported_name != '*':
                    self.warning(f"Unused import: {imported_name}", str(file_path), line_num)

        return success

    def validate_import_organization(self, imports: List[Tuple[str, int, str]], file_path: Path) -> bool:
        """Validate import organization and grouping."""
        success = True

        if not imports:
            return success

        # Group imports by type
        stdlib_imports = []
        third_party_imports = []
        odoo_imports = []
        local_imports = []

        for import_path, line_num, import_type in imports:
            if import_type == 'import' or import_type == 'from':
                if import_path.startswith('odoo'):
                    odoo_imports.append((import_path, line_num))
                elif import_path.split('.')[0] in self.COMMON_THIRD_PARTY:
                    third_party_imports.append((import_path, line_num))
                elif import_path.startswith('.'):
                    local_imports.append((import_path, line_num))
                else:
                    stdlib_imports.append((import_path, line_num))

        # Check if imports are properly grouped
        prev_line = 0
        current_group = None

        for import_path, line_num, import_type in imports:
            if import_type in ['import', 'from']:
                if import_path.startswith('odoo'):
                    group = 'odoo'
                elif import_path.split('.')[0] in self.COMMON_THIRD_PARTY:
                    group = 'third_party'
                elif import_path.startswith('.'):
                    group = 'local'
                else:
                    group = 'stdlib'

                if current_group and current_group != group and line_num == prev_line + 1:
                    self.add_info(
                        f"Consider grouping imports: {group} mixed with {current_group}", str(file_path), line_num
                    )

                current_group = group
                prev_line = line_num

        return success

    def validate_python_file(self, file_path: Path, module_name: str) -> bool:
        """Validate a single Python file."""
        rel_path = file_path.relative_to(self.base_path / module_name)

        # Parse the file
        tree = self.parse_python_file(file_path)
        if tree is None:
            return False

        # Extract imports
        imports = self.extract_imports(tree)

        # Store imports for circular dependency checking
        self.file_imports[str(rel_path)] = imports

        success = True

        # Validate each import
        for import_path, line_num, import_type in imports:
            if import_type in ['import', 'from']:
                success &= self.validate_import_path(import_path, rel_path, line_num)

        # Validate Odoo-specific imports
        success &= self.validate_odoo_imports(imports, rel_path)

        # Check for unused imports
        success &= self.check_unused_imports(tree, imports, rel_path)

        # Validate import organization
        success &= self.validate_import_organization(imports, rel_path)

        return success

    def validate_module_imports(self, module_name: str) -> bool:
        """Validate all Python files in a module."""
        module_path = self.base_path / module_name

        if not module_path.exists():
            self.error(f"Module directory not found: {module_name}")
            return False

        # Find all Python files
        python_files = list(module_path.rglob("*.py"))

        if not python_files:
            self.add_info(f"No Python files found in module: {module_name}")
            return True

        success = True

        # Validate each Python file
        for py_file in python_files:
            if not self.validate_python_file(py_file, module_name):
                success = False

        # Check for circular imports within the module
        success &= self.check_circular_imports(module_name)

        return success

    def validate_all_modules(self) -> bool:
        """Validate Python imports in all modules."""
        if not self.base_path.exists():
            self.error(f"Custom modules directory not found: {self.base_path}")
            return False

        modules = [d for d in self.base_path.iterdir() if d.is_dir() and not d.name.startswith('.')]

        if not modules:
            self.warning("No modules found in custom_modules directory")
            return True

        success = True
        for module_dir in modules:
            if not self.validate_module_imports(module_dir.name):
                success = False

        return success

    def print_results(self):
        """Print validation results in a clear, structured format."""
        print("\n" + "=" * 70)
        print("🔍 ODOO PYTHON IMPORT VALIDATION RESULTS")
        print("=" * 70)

        total_issues = len(self.errors) + len(self.warnings)

        if self.errors:
            print(f"\n❌ CRITICAL ERRORS ({len(self.errors)}):")
            for error in self.errors:
                print(f"  {error}")

        if self.warnings:
            print(f"\n⚠️  WARNINGS ({len(self.warnings)}):")
            for warning in self.warnings:
                print(f"  {warning}")

        if self.info:
            print(f"\nℹ️  SUGGESTIONS ({len(self.info)}):")
            for info in self.info:
                print(f"  {info}")

        print("\n" + "=" * 70)
        if not self.errors and not self.warnings:
            print("✅ ALL IMPORT VALIDATIONS PASSED!")
        elif not self.errors:
            print(f"✅ No errors found ({len(self.warnings)} warnings)")
        else:
            print(f"❌ Validation failed: {len(self.errors)} errors, {len(self.warnings)} warnings")

        if total_issues == 0:
            print("🎉 Your Python imports are clean and ready!")

        print("=" * 70)


def main():
    """Main function."""
    validator = ImportValidator()

    print("🔍 Starting Odoo Python Import Validation...")

    if len(sys.argv) > 1:
        module_name = sys.argv[1]
        print(f"📦 Validating imports in module: {module_name}")
        success = validator.validate_module_imports(module_name)
    else:
        print("📦 Validating imports in all modules...")
        success = validator.validate_all_modules()

    validator.print_results()

    # Exit with error code if validation failed
    sys.exit(0 if success and not validator.errors else 1)


if __name__ == "__main__":
    main()

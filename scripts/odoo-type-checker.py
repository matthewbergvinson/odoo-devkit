#!/usr/bin/env python3
"""
Custom Odoo Type Checker

This script performs additional type checking specifically for Odoo field
definitions and relationships to catch type mismatches that can cause
deployment failures.

Usage:
    python scripts/odoo-type-checker.py [module_name]
"""

import ast
import re
import sys
from pathlib import Path
from typing import List, Optional

# Common Odoo field types and their expected Python types
ODOO_FIELD_TYPES = {
    'Char': 'str',
    'Text': 'str',
    'Html': 'str',
    'Integer': 'int',
    'Float': 'float',
    'Monetary': 'float',
    'Boolean': 'bool',
    'Date': 'datetime.date',
    'Datetime': 'datetime.datetime',
    'Binary': 'bytes',
    'Selection': 'str',  # Usually string value
    'Many2one': 'recordset',  # Points to another record
    'One2many': 'recordset',  # Collection of records
    'Many2many': 'recordset',  # Collection of records
}

# Common field type mismatches that cause deployment errors
COMMON_MISMATCHES = [
    ('Text', 'Char', 'contact_address'),  # The error we encountered
    ('Char', 'Text', 'name'),
    ('Integer', 'Float', 'sequence'),
    ('Float', 'Integer', 'amount'),
]


class OdooTypeChecker:
    """Checks for Odoo-specific type mismatches and field definition issues."""

    def __init__(self):
        self.errors = []
        self.warnings = []
        self.field_definitions = {}  # module -> model -> field -> type

    def error(self, message: str, file_path: str, line_no: Optional[int] = None):
        """Record a type checking error."""
        location = f"{file_path}:{line_no}" if line_no else file_path
        self.errors.append(f"❌ {location}: {message}")

    def warning(self, message: str, file_path: str, line_no: Optional[int] = None):
        """Record a type checking warning."""
        location = f"{file_path}:{line_no}" if line_no else file_path
        self.warnings.append(f"⚠️  {location}: {message}")

    def check_field_definition(
        self, field_name: str, field_type: str, field_args: List[str], file_path: str, line_no: int
    ) -> None:
        """Check a single field definition for type consistency."""

        # Check for related field type mismatches
        if 'related=' in ' '.join(field_args):
            related_match = re.search(r"related=['\"]([^'\"]+)['\"]", ' '.join(field_args))
            if related_match:
                related_path = related_match.group(1)
                self.check_related_field_type(field_name, field_type, related_path, file_path, line_no)

        # Check for compute field without store parameter
        compute_check = 'compute=' in ' '.join(field_args) and 'store=' not in ' '.join(field_args)
        if compute_check:
            searchable_types = ['Integer', 'Float', 'Monetary', 'Date', 'Datetime']
            if field_type in searchable_types:
                self.warning(
                    f"Computed {field_type} field '{field_name}' without " f"store=True may not be searchable",
                    file_path,
                    line_no,
                )

        # Check for Many2one without comodel_name
        if field_type == 'Many2one':
            has_comodel = any(
                'comodel_name=' in arg or arg.startswith("'") or arg.startswith('"') for arg in field_args
            )
            if not has_comodel:
                self.error(f"Many2one field '{field_name}' missing comodel_name parameter", file_path, line_no)

        # Check for Selection field without selection options
        if field_type == 'Selection':
            if not any('selection=' in arg for arg in field_args):
                self.error(f"Selection field '{field_name}' missing selection parameter", file_path, line_no)

    def check_related_field_type(
        self, field_name: str, field_type: str, related_path: str, file_path: str, line_no: int
    ) -> None:
        """Check if a related field type matches its source field type."""

        # Extract the final field name from the related path
        path_parts = related_path.split('.')
        if len(path_parts) < 2:
            return

        target_field = path_parts[-1]

        # Check against known problematic patterns
        for source_type, target_type, known_field in COMMON_MISMATCHES:
            if field_type == source_type and target_field == known_field:
                self.error(
                    f"Field type mismatch: '{field_name}' is {field_type} but "
                    f"related to '{target_field}' which is typically {target_type}. "
                    f"This will cause deployment errors.",
                    file_path,
                    line_no,
                )

        # Specific check for contact_address (the error we encountered)
        if target_field == 'contact_address' and field_type != 'Char':
            self.error(
                f"Field '{field_name}' type mismatch: contact_address is a Char field, "
                f"but {field_name} is defined as {field_type}. Change to fields.Char()",
                file_path,
                line_no,
            )

    def parse_model_file(self, file_path: Path) -> None:
        """Parse a Python model file for field definitions."""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()

            # Parse the AST
            tree = ast.parse(content)

            # Look for field definitions
            for node in ast.walk(tree):
                if isinstance(node, ast.Assign):
                    for target in node.targets:
                        if isinstance(target, ast.Name):
                            field_name = target.id

                            # Check if this is a field assignment
                            if isinstance(node.value, ast.Call):
                                if hasattr(node.value.func, 'attr'):
                                    field_type = node.value.func.attr
                                    if field_type in ODOO_FIELD_TYPES:
                                        # Extract field arguments
                                        args = []
                                        for arg in node.value.args:
                                            if isinstance(arg, ast.Constant):
                                                args.append(str(arg.value))

                                        for keyword in node.value.keywords:
                                            args.append(f"{keyword.arg}={ast.unparse(keyword.value)}")

                                        self.check_field_definition(
                                            field_name, field_type, args, str(file_path), node.lineno
                                        )

        except Exception as e:
            self.error(f"Error parsing file: {e}", str(file_path))

    def check_module(self, module_path: Path) -> None:
        """Check all model files in a module."""
        models_dir = module_path / 'models'

        if not models_dir.exists():
            return

        for model_file in models_dir.glob('*.py'):
            if model_file.name != '__init__.py':
                self.parse_model_file(model_file)

    def run_checks(self, target_path: Optional[str] = None) -> bool:
        """Run type checks on specified path or all modules."""
        custom_modules_dir = Path('custom_modules')

        if not custom_modules_dir.exists():
            self.error("custom_modules directory not found", str(custom_modules_dir))
            return False

        if target_path:
            module_path = custom_modules_dir / target_path
            if not module_path.exists():
                self.error(f"Module {target_path} not found", str(module_path))
                return False
            self.check_module(module_path)
        else:
            # Check all modules
            for module_dir in custom_modules_dir.iterdir():
                if module_dir.is_dir() and not module_dir.name.startswith('.'):
                    self.check_module(module_dir)

        return len(self.errors) == 0

    def print_results(self) -> None:
        """Print the results of type checking."""
        print("\n" + "=" * 60)
        print("🔍 ODOO TYPE CHECKING RESULTS")
        print("=" * 60)

        if self.errors:
            print(f"\n❌ ERRORS ({len(self.errors)}):")
            for error in self.errors:
                print(f"  {error}")

        if self.warnings:
            print(f"\n⚠️  WARNINGS ({len(self.warnings)}):")
            for warning in self.warnings:
                print(f"  {warning}")

        if not self.errors and not self.warnings:
            print("\n✅ No Odoo type issues found!")

        print("=" * 60)

        summary = f"Summary: {len(self.errors)} errors, {len(self.warnings)} warnings"
        if self.errors:
            summary += " ❌ MUST FIX BEFORE DEPLOYMENT"
        else:
            summary += " ✅ Ready for deployment"
        print(summary)


def main():
    """Main function."""
    checker = OdooTypeChecker()

    target_module = sys.argv[1] if len(sys.argv) > 1 else None

    print("🔍 Running Odoo-specific type checking...")
    if target_module:
        print(f"📁 Checking module: {target_module}")
    else:
        print("📁 Checking all modules")

    success = checker.run_checks(target_module)
    checker.print_results()

    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()

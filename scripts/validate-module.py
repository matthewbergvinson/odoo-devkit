#!/usr/bin/env python3
"""
Odoo Module Validation Script for RTP Denver

This script validates Odoo module structure, syntax, and common patterns
to catch errors before deployment. It would have caught the field type
mismatch error we encountered earlier.

Usage:
    python scripts/validate-module.py [module_name]
    python scripts/validate-module.py  # validates all modules
"""

import ast
import csv
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path
from typing import Any, Dict, List, Set

# Field type compatibility matrix for relationship validation
FIELD_TYPE_COMPATIBILITY = {
    'Char': ['Char', 'Text', 'Selection'],
    'Text': ['Text', 'Html'],
    'Integer': ['Integer', 'Float'],
    'Float': ['Float', 'Integer'],
    'Boolean': ['Boolean'],
    'Date': ['Date', 'Datetime'],
    'Datetime': ['Datetime', 'Date'],
    'Binary': ['Binary'],
    'Selection': ['Selection', 'Char'],
    'Many2one': ['Many2one'],
    'One2many': ['One2many'],
    'Many2many': ['Many2many'],
    'Html': ['Html', 'Text'],
    'Monetary': ['Monetary', 'Float', 'Integer'],
    'Reference': ['Reference'],
}

# Common Odoo model names and their typical field names
COMMON_MODEL_FIELDS = {
    'res.partner': {
        'name': 'Char',
        'email': 'Char',
        'phone': 'Char',
        'mobile': 'Char',
        'street': 'Char',
        'street2': 'Char',
        'city': 'Char',
        'zip': 'Char',
        'state_id': 'Many2one',
        'country_id': 'Many2one',
        'contact_address': 'Char',  # This would have caught our error!
        'is_company': 'Boolean',
        'supplier_rank': 'Integer',
        'customer_rank': 'Integer',
    },
    'sale.order': {
        'name': 'Char',
        'partner_id': 'Many2one',
        'date_order': 'Datetime',
        'state': 'Selection',
        'amount_total': 'Monetary',
        'currency_id': 'Many2one',
        'order_line': 'One2many',
    },
    'purchase.order': {
        'name': 'Char',
        'partner_id': 'Many2one',
        'date_order': 'Datetime',
        'state': 'Selection',
        'amount_total': 'Monetary',
        'currency_id': 'Many2one',
        'order_line': 'One2many',
    },
    'stock.picking': {
        'name': 'Char',
        'partner_id': 'Many2one',
        'location_id': 'Many2one',
        'location_dest_id': 'Many2one',
        'state': 'Selection',
        'move_lines': 'One2many',
    },
    'project.project': {
        'name': 'Char',
        'partner_id': 'Many2one',
        'user_id': 'Many2one',
        'date_start': 'Date',
        'date': 'Date',
        'task_ids': 'One2many',
    },
    'calendar.event': {
        'name': 'Char',
        'start': 'Datetime',
        'stop': 'Datetime',
        'user_id': 'Many2one',
        'partner_ids': 'Many2many',
        'location': 'Char',
        'description': 'Text',
    },
}


class ModuleValidator:
    """Validates Odoo module structure and content."""

    def __init__(self, base_path: str = "custom_modules"):
        self.base_path = Path(base_path)
        self.errors: List[str] = []
        self.warnings: List[str] = []

    def error(self, message: str, module: str = "", file: str = ""):
        """Add an error message."""
        location = f"{module}/{file}" if module and file else module or file
        self.errors.append(f"ERROR: {location}: {message}")

    def warning(self, message: str, module: str = "", file: str = ""):
        """Add a warning message."""
        location = f"{module}/{file}" if module and file else module or file
        self.warnings.append(f"WARNING: {location}: {message}")

    def validate_all_modules(self) -> bool:
        """Validate all modules in the custom_modules directory."""
        if not self.base_path.exists():
            self.error(f"Custom modules directory not found: {self.base_path}")
            return False

        modules = [d for d in self.base_path.iterdir() if d.is_dir() and not d.name.startswith('.')]

        if not modules:
            self.warning("No modules found in custom_modules directory")
            return True

        success = True
        for module_dir in modules:
            if not self.validate_module(module_dir.name):
                success = False

        return success

    def validate_module(self, module_name: str) -> bool:
        """Validate a specific module."""
        module_path = self.base_path / module_name

        if not module_path.exists():
            self.error(f"Module directory not found: {module_name}")
            return False

        print(f"Validating module: {module_name}")

        success = True
        success &= self.validate_manifest(module_name)
        success &= self.validate_python_files(module_name)
        success &= self.validate_xml_files(module_name)
        success &= self.validate_csv_files(module_name)
        success &= self.validate_module_structure(module_name)

        # NEW: Task 2.6 - Anti-pattern detection
        success &= self.validate_anti_patterns(module_name)

        return success

    def validate_manifest(self, module_name: str) -> bool:
        """Validate __manifest__.py file."""
        manifest_path = self.base_path / module_name / "__manifest__.py"

        if not manifest_path.exists():
            self.error("Missing __manifest__.py file", module_name)
            return False

        try:
            with open(manifest_path, 'r') as f:
                content = f.read()

            # Parse as Python AST to validate syntax
            try:
                ast.parse(content)
            except SyntaxError as e:
                self.error(f"Syntax error in __manifest__.py: {e}", module_name)
                return False

            # Execute the manifest file to get the dictionary
            manifest_globals: dict = {}
            try:
                exec(content, manifest_globals)
                if '__manifest__' in manifest_globals:
                    manifest = manifest_globals['__manifest__']
                else:
                    # Try to evaluate the content directly as a dictionary
                    manifest = eval(content)
                    if not isinstance(manifest, dict):
                        raise ValueError("Manifest is not a dictionary")
            except Exception as e:
                self.error(f"Could not parse __manifest__.py as dictionary: {e}", module_name, "__manifest__.py")
                return False

            # Check required fields
            required_fields = ['name', 'version', 'depends', 'data']
            for field in required_fields:
                if field not in manifest:
                    self.error(f"Missing required field '{field}' in manifest", module_name)

            # Check version format
            if 'version' in manifest:
                version = manifest['version']
                pattern = r'^\d+\.\d+\.\d+\.\d+$'
                if not re.match(pattern, version):
                    self.warning(f"Version format should be X.Y.Z.W, got: {version}", module_name)

            # Check dependencies
            if 'depends' in manifest:
                if not isinstance(manifest['depends'], list):
                    self.error("'depends' should be a list", module_name)
                elif 'base' not in manifest['depends']:
                    self.warning("'base' module not in dependencies", module_name)

        except Exception as e:
            self.error(f"Error reading __manifest__.py: {e}", module_name)
            return False

        return True

    def validate_python_files(self, module_name: str) -> bool:
        """Validate Python files for syntax and Odoo patterns."""
        module_path = self.base_path / module_name
        success = True

        for py_file in module_path.rglob("*.py"):
            rel_path = py_file.relative_to(module_path)

            try:
                with open(py_file, 'r') as f:
                    content = f.read()

                # Check syntax
                try:
                    ast.parse(content)
                except SyntaxError as e:
                    self.error(f"Syntax error: {e}", module_name, str(rel_path))
                    success = False
                    continue

                # Validate model files
                if 'models/' in str(rel_path) and rel_path.name != '__init__.py':
                    success &= self.validate_model_file(module_name, str(rel_path), content)

            except Exception as e:
                self.error(f"Error reading {rel_path}: {e}", module_name)
                success = False

        return success

    def validate_model_file(self, module_name: str, file_path: str, content: str) -> bool:
        """Validate Odoo model file for common patterns and errors."""
        success = True
        lines = content.split('\n')

        # Check for proper imports
        has_odoo_import = any('from odoo import' in line for line in lines)
        if not has_odoo_import:
            self.warning("No 'from odoo import' found", module_name, file_path)

        # Parse AST for detailed analysis
        try:
            tree = ast.parse(content)

            for node in ast.walk(tree):
                if isinstance(node, ast.ClassDef):
                    success &= self.validate_model_class(module_name, file_path, node, content)

        except Exception as e:
            self.error(f"Error parsing model file: {e}", module_name, file_path)
            success = False

        return success

    def validate_model_class(self, module_name: str, file_path: str, class_node: ast.ClassDef, content: str) -> bool:
        """Validate Odoo model class definition."""
        success = True

        # Check if it's a models.Model subclass
        is_model = False
        for base in class_node.bases:
            if isinstance(base, ast.Attribute) and hasattr(base, 'attr'):
                if base.attr == 'Model' or base.attr == 'TransientModel':
                    is_model = True
                    break

        if not is_model:
            return True  # Not an Odoo model, skip validation

        # Extract model attributes
        model_attrs = self._extract_model_attributes(class_node, content)

        # Check for _name or _inherit attribute (both are valid for Odoo models)
        has_name_or_inherit = '_name' in model_attrs or '_inherit' in model_attrs
        if not has_name_or_inherit:
            self.error(f"Model class {class_node.name} missing _name or _inherit attribute", module_name, file_path)
            success = False

        # Validate model inheritance patterns
        success &= self.validate_model_inheritance(module_name, file_path, class_node.name, model_attrs)

        # Validate field definitions - Enhanced for Task 2.5
        success &= self.validate_model_fields(module_name, file_path, class_node, content)

        # NEW: Comprehensive relationship validation for Task 2.5
        success &= self.validate_model_relationships(module_name, file_path, class_node, content, model_attrs)

        return success

    def _extract_model_attributes(self, class_node: ast.ClassDef, content: str) -> Dict[str, str]:
        """Extract model attributes like _name, _inherit, _description."""
        attributes = {}

        for node in class_node.body:
            if isinstance(node, ast.Assign):
                for target in node.targets:
                    if isinstance(target, ast.Name) and target.id.startswith('_'):
                        # Extract the value
                        if isinstance(node.value, ast.Constant):
                            attributes[target.id] = node.value.value
                        elif isinstance(node.value, ast.Str):  # Python < 3.8
                            attributes[target.id] = node.value.s

        return attributes

    def validate_model_inheritance(
        self, module_name: str, file_path: str, class_name: str, model_attrs: Dict[str, str]
    ) -> bool:
        """Validate model inheritance patterns - Critical for preventing
        deployment errors."""
        success = True

        has_name = '_name' in model_attrs
        has_inherit = '_inherit' in model_attrs

        if has_name and has_inherit:
            # Both _name and _inherit means creating a new model that
            # inherits from another. This is valid but should be carefully
            # reviewed
            inherit_model = model_attrs['_inherit']
            self.warning(
                f"Model {class_name} has both _name and _inherit. "
                f"This creates a new model inheriting from {inherit_model}. "
                f"Make sure this is intentional.",
                module_name,
                file_path,
            )

        elif has_inherit and not has_name:
            # Pure inheritance - extending existing model
            inherit_model = model_attrs['_inherit']

            # Validate inherit model name format
            pattern = r'^[a-z][a-z0-9]*(\.[a-z][a-z0-9]*)*$'
            if not re.match(pattern, inherit_model):
                self.error(
                    f"Invalid _inherit model name format: {inherit_model}. "
                    f"Should be lowercase with dots (e.g., 'sale.order')",
                    module_name,
                    file_path,
                )
                success = False

        elif has_name and not has_inherit:
            # New model creation
            model_name = model_attrs['_name']

            # Validate model name format
            pattern = r'^[a-z][a-z0-9]*(\.[a-z][a-z0-9]*)+$'
            if not re.match(pattern, model_name):
                self.error(
                    f"Invalid _name model format: {model_name}. "
                    f"Should be lowercase with dots (e.g., 'my.model.name')",
                    module_name,
                    file_path,
                )
                success = False

            # Check for potential overwriting of existing models
            if model_name in COMMON_MODEL_FIELDS:
                self.error(
                    f"Model {class_name} trying to overwrite existing "
                    f"Odoo model {model_name}. "
                    f"Use _inherit instead of _name to extend models!",
                    module_name,
                    file_path,
                )
                success = False

        return success

    def validate_model_relationships(
        self, module_name: str, file_path: str, class_node: ast.ClassDef, content: str, model_attrs: Dict[str, str]
    ) -> bool:
        """Comprehensive relationship validation for Task 2.5."""
        success = True

        # Extract all field definitions in this model
        model_fields = self._extract_model_fields(content)

        # Validate each relational field
        for field_name, field_info in model_fields.items():
            if field_info['type'] in ['Many2one', 'One2many', 'Many2many']:
                success &= self._validate_relational_field(module_name, file_path, field_name, field_info, model_attrs)

            if field_info.get('related'):
                success &= self._validate_related_field(module_name, file_path, field_name, field_info, model_attrs)

            if field_info.get('compute'):
                success &= self._validate_computed_field(module_name, file_path, field_name, field_info, model_attrs)

        # Check for circular dependencies
        success &= self._validate_dependency_cycles(module_name, file_path, model_fields, model_attrs)

        return success

    def _extract_model_fields(self, content: str) -> Dict[str, Dict[str, Any]]:
        """Extract field definitions from model content."""
        fields = {}
        lines = content.split('\n')

        for i, line in enumerate(lines):
            # Match field definitions: field_name = fields.Type(...)
            pattern = r'(\w+)\s*=\s*fields\.(\w+)\s*\(([^)]*)\)'
            field_match = re.search(pattern, line)
            if field_match:
                field_name = field_match.group(1)
                field_type = field_match.group(2)
                field_params = field_match.group(3)

                # Extract parameters
                field_info = {'type': field_type, 'line': i + 1, 'definition': line.strip()}

                # Extract common parameters
                if 'string=' in field_params:
                    string_match = re.search(r'string=[\'"]([^\'"]*)[\'"]', field_params)
                    if string_match:
                        field_info['string'] = string_match.group(1)

                if 'related=' in field_params:
                    related_match = re.search(r'related=[\'"]([^\'"]*)[\'"]', field_params)
                    if related_match:
                        field_info['related'] = related_match.group(1)

                if 'comodel_name=' in field_params:
                    comodel_match = re.search(r'comodel_name=[\'"]([^\'"]*)[\'"]', field_params)
                    if comodel_match:
                        field_info['comodel_name'] = comodel_match.group(1)

                if 'compute=' in field_params:
                    compute_match = re.search(r'compute=[\'"]([^\'"]*)[\'"]', field_params)
                    if compute_match:
                        field_info['compute'] = compute_match.group(1)

                if 'inverse_name=' in field_params:
                    inverse_match = re.search(r'inverse_name=[\'"]([^\'"]*)[\'"]', field_params)
                    if inverse_match:
                        field_info['inverse_name'] = inverse_match.group(1)

                # For One2many, extract the second positional parameter
                # (inverse field)
                if field_type == 'One2many':
                    pattern = r'fields\.One2many\s*\(\s*' r'[\'"]([^\'"]*)[\'"],\s*[\'"]([^\'"]*)[\'"]'
                    o2m_match = re.search(pattern, line)
                    if o2m_match:
                        field_info['comodel_name'] = o2m_match.group(1)
                        field_info['inverse_name'] = o2m_match.group(2)

                fields[field_name] = field_info

        return fields

    def _validate_relational_field(
        self, module_name: str, file_path: str, field_name: str, field_info: Dict[str, Any], model_attrs: Dict[str, str]
    ) -> bool:
        """Validate relational field definitions."""
        success = True
        field_type = field_info['type']
        line_num = field_info['line']

        if field_type == 'Many2one':
            # Many2one should have comodel_name
            if 'comodel_name' not in field_info:
                # Extract from first parameter if not explicitly set
                pattern = r'fields\.Many2one\s*\(\s*[\'"]([^\'"]*)[\'"]'
                comodel_match = re.search(pattern, field_info['definition'])
                if not comodel_match:
                    self.error(
                        f"Many2one field '{field_name}' missing comodel_name "
                        f"parameter. Line {line_num}: {field_info['definition']}",
                        module_name,
                        file_path,
                    )
                    success = False
                else:
                    comodel = comodel_match.group(1)
                    # Validate comodel name format
                    pattern = r'^[a-z][a-z0-9]*(\.[a-z][a-z0-9]*)*$'
                    if not re.match(pattern, comodel):
                        self.error(
                            f"Invalid comodel name format: {comodel}. " f"Line {line_num}: {field_info['definition']}",
                            module_name,
                            file_path,
                        )
                        success = False

        elif field_type == 'One2many':
            # One2many requires comodel and inverse_name
            missing_params = 'comodel_name' not in field_info or 'inverse_name' not in field_info
            if missing_params:
                self.error(
                    f"One2many field '{field_name}' missing required "
                    f"parameters (comodel, inverse_name). "
                    f"Line {line_num}: {field_info['definition']}",
                    module_name,
                    file_path,
                )
                success = False
            else:
                # Validate inverse field naming convention
                inverse_name = field_info['inverse_name']
                if not inverse_name.endswith('_id') and not inverse_name.endswith('_ids'):
                    self.warning(
                        f"One2many inverse field '{inverse_name}' should "
                        f"typically end with '_id'. "
                        f"Line {line_num}: {field_info['definition']}",
                        module_name,
                        file_path,
                    )

        elif field_type == 'Many2many':
            # Many2many should have comodel_name
            if 'comodel_name' not in field_info:
                pattern = r'fields\.Many2many\s*\(\s*[\'"]([^\'"]*)[\'"]'
                comodel_match = re.search(pattern, field_info['definition'])
                if not comodel_match:
                    self.error(
                        f"Many2many field '{field_name}' missing "
                        f"comodel_name parameter. "
                        f"Line {line_num}: {field_info['definition']}",
                        module_name,
                        file_path,
                    )
                    success = False

        return success

    def _validate_related_field(
        self, module_name: str, file_path: str, field_name: str, field_info: Dict[str, Any], model_attrs: Dict[str, str]
    ) -> bool:
        """Validate related field type compatibility - This would have
        caught our error!"""
        success = True
        related_path = field_info['related']
        field_type = field_info['type']
        line_num = field_info['line']

        # Split related path to analyze each step
        path_parts = related_path.split('.')

        if len(path_parts) < 2:
            self.error(
                f"Related field '{field_name}' has invalid path "
                f"'{related_path}'. Should be 'field.subfield' format. "
                f"Line {line_num}",
                module_name,
                file_path,
            )
            return False

        # Check if we know the target field type
        target_field = path_parts[-1]

        # Check against known model fields
        for model_name, model_fields in COMMON_MODEL_FIELDS.items():
            if target_field in model_fields:
                expected_type = model_fields[target_field]

                # Check type compatibility
                compatible_types = FIELD_TYPE_COMPATIBILITY.get(expected_type, [expected_type])
                if field_type not in compatible_types:
                    self.error(
                        f"Field type mismatch: {field_type} field "
                        f"'{field_name}' cannot be related to '{target_field}' "
                        f"(typically {expected_type}). "
                        f"Line {line_num}: {field_info['definition']}",
                        module_name,
                        file_path,
                    )
                    success = False
                    break

        # Specific checks for common field mismatches
        if field_type == 'Text':
            text_incompatible = ['email', 'phone', 'mobile', 'zip', 'name', 'contact_address']
            if any(field in target_field.lower() for field in text_incompatible):
                self.error(
                    f"Text field '{field_name}' related to '{target_field}' "
                    f"is likely a type mismatch. These fields are typically "
                    f"Char fields. Line {line_num}",
                    module_name,
                    file_path,
                )
                success = False

        elif field_type == 'Char':
            char_incompatible = ['description', 'note', 'comment']
            if any(field in target_field.lower() for field in char_incompatible):
                self.warning(
                    f"Char field '{field_name}' related to '{target_field}' "
                    f"might be better as Text. Line {line_num}",
                    module_name,
                    file_path,
                )

        return success

    def _validate_computed_field(
        self, module_name: str, file_path: str, field_name: str, field_info: Dict[str, Any], model_attrs: Dict[str, str]
    ) -> bool:
        """Validate computed field definitions."""
        success = True
        compute_method = field_info['compute']
        line_num = field_info['line']

        # Check compute method naming convention
        if not compute_method.startswith('_compute_'):
            self.warning(
                f"Compute method '{compute_method}' should start with " f"'_compute_'. Line {line_num}",
                module_name,
                file_path,
            )

        # Check for store parameter on computed fields
        definition = field_info['definition']
        if 'store=' not in definition and 'search=' not in definition:
            self.warning(
                f"Computed field '{field_name}' without store parameter "
                f"may not be searchable. Consider adding store=True if "
                f"field should be searchable. Line {line_num}",
                module_name,
                file_path,
            )

        return success

    def _validate_dependency_cycles(
        self, module_name: str, file_path: str, model_fields: Dict[str, Dict[str, Any]], model_attrs: Dict[str, str]
    ) -> bool:
        """Check for circular dependencies in field relationships."""
        success = True

        # Build dependency graph for related fields
        dependencies = {}

        for field_name, field_info in model_fields.items():
            if field_info.get('related'):
                related_path = field_info['related']
                first_field = related_path.split('.')[0]

                if first_field != field_name:  # Avoid self-reference
                    if field_name not in dependencies:
                        dependencies[field_name] = set()
                    dependencies[field_name].add(first_field)

        # Simple cycle detection
        for start_field in dependencies:
            visited = set()
            if self._has_cycle(start_field, dependencies, visited):
                self.warning(
                    f"Potential circular dependency detected starting from "
                    f"field '{start_field}'. Please review related field "
                    f"relationships.",
                    module_name,
                    file_path,
                )

        return success

    def _has_cycle(
        self, field: str, dependencies: Dict[str, Set[str]], visited: Set[str], path: Set[str] = None
    ) -> bool:
        """Detect cycles in field dependencies using DFS."""
        if path is None:
            path = set()

        if field in path:
            return True

        if field in visited:
            return False

        visited.add(field)
        path.add(field)

        for dep_field in dependencies.get(field, []):
            if self._has_cycle(dep_field, dependencies, visited, path):
                return True

        path.remove(field)
        return False

    def validate_model_fields(self, module_name: str, file_path: str, class_node: ast.ClassDef, content: str) -> bool:
        """Validate model field definitions - catches field type mismatches."""
        success = True
        lines = content.split('\n')

        # Find field definitions
        for i, line in enumerate(lines):
            # Look for field definitions with 'related=' parameter
            if 'fields.' in line and 'related=' in line:
                # Extract field type and related field
                field_match = re.search(r'fields\.(\w+)\s*\(.*related=[\'"]([^\'"]+)[\'"]', line)
                if field_match:
                    field_type = field_match.group(1)
                    related_field = field_match.group(2)

                    # This is the specific check that would have caught our error
                    if field_type == 'Text' and 'contact_address' in related_field:
                        self.error(
                            f"Field type mismatch: Text field cannot be related to contact_address "
                            f"(which is typically a Char field). Line {i+1}: {line.strip()}",
                            module_name,
                            file_path,
                        )
                        success = False

                    # General validation for common mismatches
                    if field_type == 'Text' and any(addr in related_field for addr in ['address', 'email', 'phone']):
                        self.warning(
                            f"Potential field type mismatch: Text field related to {related_field} "
                            f"(usually Char fields). Line {i+1}: {line.strip()}",
                            module_name,
                            file_path,
                        )

            # Check for compute fields without store parameter when they should have it
            if 'compute=' in line and 'store=' not in line and 'search=' not in line:
                self.warning(
                    f"Computed field without store parameter may not be searchable. " f"Line {i+1}: {line.strip()}",
                    module_name,
                    file_path,
                )

        return success

    def validate_xml_files(self, module_name: str) -> bool:
        """Validate XML files for syntax and structure."""
        module_path = self.base_path / module_name
        success = True

        for xml_file in module_path.rglob("*.xml"):
            rel_path = xml_file.relative_to(module_path)

            try:
                tree = ET.parse(xml_file)
                root = tree.getroot()

                # Validate Odoo XML structure
                if root.tag != 'odoo':
                    self.warning(f"Root element should be 'odoo', got '{root.tag}'", module_name, str(rel_path))

                # Check for common XML errors
                for elem in root.iter():
                    # Check for missing 'id' attributes on records
                    if elem.tag == 'record' and 'id' not in elem.attrib:
                        self.error("Record element missing 'id' attribute", module_name, str(rel_path))
                        success = False

                    # Check for invalid model references
                    if 'model' in elem.attrib:
                        model = elem.attrib['model']
                        if not re.match(r'^[a-z][a-z0-9]*(\.[a-z][a-z0-9]*)*$', model):
                            self.warning(f"Invalid model name format: {model}", module_name, str(rel_path))

            except ET.ParseError as e:
                self.error(f"XML parse error: {e}", module_name, str(rel_path))
                success = False
            except Exception as e:
                self.error(f"Error reading XML file: {e}", module_name, str(rel_path))
                success = False

        return success

    def validate_csv_files(self, module_name: str) -> bool:
        """Validate CSV files (typically security files)."""
        module_path = self.base_path / module_name
        success = True

        for csv_file in module_path.rglob("*.csv"):
            rel_path = csv_file.relative_to(module_path)

            try:
                with open(csv_file, 'r') as f:
                    reader = csv.reader(f)
                    rows = list(reader)

                if not rows:
                    self.warning("Empty CSV file", module_name, str(rel_path))
                    continue

                header = rows[0]

                # Validate access rights CSV structure
                if 'ir.model.access.csv' in str(rel_path):
                    expected_columns = [
                        'id',
                        'name',
                        'model_id:id',
                        'group_id:id',
                        'perm_read',
                        'perm_write',
                        'perm_create',
                        'perm_unlink',
                    ]
                    missing_columns = [col for col in expected_columns if col not in header]
                    if missing_columns:
                        self.error(
                            f"Missing columns in access rights CSV: {', '.join(missing_columns)}. Found columns: {', '.join(header)}",
                            module_name,
                            str(rel_path),
                        )
                        success = False

                    # Check data rows
                    for i, row in enumerate(rows[1:], 2):
                        if len(row) != len(header):
                            self.error(
                                f"Row {i} has {len(row)} columns, expected {len(header)}", module_name, str(rel_path)
                            )
                            success = False

            except Exception as e:
                self.error(f"Error reading CSV file: {e}", module_name, str(rel_path))
                success = False

        return success

    def validate_module_structure(self, module_name: str) -> bool:
        """Validate module directory structure."""
        module_path = self.base_path / module_name
        success = True

        # Check for required __init__.py files
        required_inits = [
            module_path / "__init__.py",
        ]

        if (module_path / "models").exists():
            required_inits.append(module_path / "models" / "__init__.py")

        if (module_path / "controllers").exists():
            required_inits.append(module_path / "controllers" / "__init__.py")

        for init_file in required_inits:
            if not init_file.exists():
                self.error(f"Missing {init_file.relative_to(module_path)}", module_name)
                success = False

        return success

    def validate_anti_patterns(self, module_name: str) -> bool:
        """Task 2.6: Comprehensive anti-pattern detection for Python and Odoo."""
        print(f"  Checking for anti-patterns in {module_name}...")

        success = True
        module_path = self.base_path / module_name

        # Check all Python files for anti-patterns
        python_files = list(module_path.rglob("*.py"))

        for py_file in python_files:
            rel_path = py_file.relative_to(module_path)

            try:
                with open(py_file, 'r', encoding='utf-8') as f:
                    content = f.read()

                success &= self._check_python_anti_patterns(module_name, str(rel_path), content)

                # Parse AST for more complex checks
                try:
                    tree = ast.parse(content)
                    success &= self._check_ast_anti_patterns(module_name, str(rel_path), tree, content)
                except SyntaxError:
                    # Syntax errors already caught in validate_python_files
                    pass

            except Exception as e:
                self.error(f"Error reading file for anti-pattern check: {e}", module_name, str(rel_path))
                success = False

        # Check module-level anti-patterns
        success &= self._check_module_level_anti_patterns(module_name)

        return success

    def _check_python_anti_patterns(self, module_name: str, file_path: str, content: str) -> bool:
        """Check for common Python anti-patterns."""
        success = True
        lines = content.split('\n')

        for i, line in enumerate(lines, 1):
            line_stripped = line.strip()

            # Anti-pattern: Bare except clause
            if re.search(r'\bexcept\s*:', line):
                self.error(
                    f"Bare except clause detected. Use specific exceptions. " f"Line {i}: {line_stripped}",
                    module_name,
                    file_path,
                )
                success = False

            # Anti-pattern: Print statements (should use logging)
            if re.search(r'\bprint\s*\(', line) and 'test' not in file_path.lower():
                self.warning(
                    f"Print statement detected. Use logging instead. " f"Line {i}: {line_stripped}",
                    module_name,
                    file_path,
                )

            # Anti-pattern: Hardcoded file paths
            path_patterns = [r'[\'"][A-Za-z]:[/\\]', r'[\'"]/[a-z]']
            if any(re.search(pattern, line) for pattern in path_patterns):
                # Skip if it's in a comment or docstring
                if not line_stripped.startswith('#') and '"""' not in line:
                    self.warning(
                        f"Hardcoded file path detected. Use os.path or pathlib. " f"Line {i}: {line_stripped}",
                        module_name,
                        file_path,
                    )

            # Anti-pattern: SQL injection vulnerability
            sql_pattern = r'execute\s*\(\s*[\'"][^\'"]*(%).*[\'"]'
            if re.search(sql_pattern, line):
                self.error(
                    f"Potential SQL injection vulnerability. "
                    f"Use parameterized queries. "
                    f"Line {i}: {line_stripped}",
                    module_name,
                    file_path,
                )
                success = False

            # Anti-pattern: Using exec() or eval()
            if re.search(r'\b(exec|eval)\s*\(', line):
                func_name = re.search(r'\b(exec|eval)', line).group(1)
                self.error(
                    f"Use of {func_name}() detected. " f"Security risk! Line {i}: {line_stripped}",
                    module_name,
                    file_path,
                )
                success = False

            # Anti-pattern: Hardcoded credentials or secrets
            secret_patterns = [
                r'password\s*=\s*[\'"][^\'"]+[\'"]',
                r'secret\s*=\s*[\'"][^\'"]+[\'"]',
                r'api_key\s*=\s*[\'"][^\'"]+[\'"]',
                r'token\s*=\s*[\'"][^\'"]+[\'"]',
            ]
            for pattern in secret_patterns:
                if re.search(pattern, line, re.IGNORECASE):
                    self.error(
                        f"Hardcoded credential detected. " f"Use environment variables. " f"Line {i}: [REDACTED]",
                        module_name,
                        file_path,
                    )
                    success = False

            # Anti-pattern: Debugging code left in production
            debug_patterns = [
                r'\bbreakpoint\s*\(',
                r'\bpdb\.set_trace\s*\(',
                r'\bipdb\.set_trace\s*\(',
                r'import\s+pdb',
                r'import\s+ipdb',
            ]
            for pattern in debug_patterns:
                if re.search(pattern, line):
                    self.error(
                        f"Debugging code detected. Remove before production. " f"Line {i}: {line_stripped}",
                        module_name,
                        file_path,
                    )
                    success = False

        return success

    def _check_ast_anti_patterns(self, module_name: str, file_path: str, tree: ast.AST, content: str) -> bool:
        """Check for AST-level anti-patterns."""
        success = True
        lines = content.split('\n')

        for node in ast.walk(tree):
            # Anti-pattern: Not using 'with' to open files
            if isinstance(node, ast.Call) and isinstance(node.func, ast.Name):
                if node.func.id == 'open':
                    # Check if this 'open' is inside a 'with' statement
                    if not self._is_inside_with_statement(node, tree):
                        line_num = getattr(node, 'lineno', 0)
                        if line_num > 0:
                            self.warning(
                                f"File opened without 'with' statement. "
                                f"Use 'with open()' for proper resource "
                                f"management. Line {line_num}: "
                                f"{lines[line_num-1].strip()}",
                                module_name,
                                file_path,
                            )

            # Anti-pattern: Mutable default arguments
            if isinstance(node, ast.FunctionDef):
                for default in node.args.defaults:
                    if isinstance(default, (ast.List, ast.Dict, ast.Set)):
                        line_num = getattr(default, 'lineno', 0)
                        if line_num > 0:
                            self.error(
                                f"Mutable default argument in function "
                                f"'{node.name}'. Use None and initialize "
                                f"in function body. Line {line_num}",
                                module_name,
                                file_path,
                            )
                            success = False

            # Anti-pattern: Using string exceptions (deprecated)
            if isinstance(node, ast.Raise) and isinstance(node.exc, ast.Str):
                line_num = getattr(node, 'lineno', 0)
                if line_num > 0:
                    self.error(
                        f"String exception detected. Use exception classes. "
                        f"Line {line_num}: {lines[line_num-1].strip()}",
                        module_name,
                        file_path,
                    )
                    success = False

        return success

    def _is_inside_with_statement(self, target_node: ast.AST, tree: ast.AST) -> bool:
        """Check if a node is inside a 'with' statement."""
        for node in ast.walk(tree):
            if isinstance(node, ast.With):
                for child in ast.walk(node):
                    if child is target_node:
                        return True
        return False

    def _check_module_level_anti_patterns(self, module_name: str) -> bool:
        """Check for module-level anti-patterns."""
        success = True
        module_path = self.base_path / module_name

        # Enhanced __init__.py check
        required_dirs = ['models', 'controllers', 'wizards', 'reports']
        for dir_name in required_dirs:
            dir_path = module_path / dir_name
            if dir_path.exists() and dir_path.is_dir():
                init_file = dir_path / "__init__.py"
                if not init_file.exists():
                    self.error(
                        f"Missing __init__.py in {dir_name}/ directory. " f"Required for Python package structure.",
                        module_name,
                    )
                    success = False

        # Check for circular imports
        success &= self._check_circular_imports(module_name)

        # Check for missing dependencies in manifest
        success &= self._check_missing_dependencies(module_name)

        # Check for deprecated Odoo patterns
        success &= self._check_deprecated_odoo_patterns(module_name)

        return success

    def _check_circular_imports(self, module_name: str) -> bool:
        """Detect potential circular import issues."""
        success = True
        module_path = self.base_path / module_name
        import_graph = {}

        # Build import graph
        for py_file in module_path.rglob("*.py"):
            rel_path = str(py_file.relative_to(module_path))
            module_id = rel_path.replace('/', '.').replace('.py', '')

            try:
                with open(py_file, 'r', encoding='utf-8') as f:
                    content = f.read()

                tree = ast.parse(content)
                imports = []

                for node in ast.walk(tree):
                    if isinstance(node, ast.Import):
                        for alias in node.names:
                            if alias.name.startswith(module_name):
                                imports.append(alias.name)
                    elif isinstance(node, ast.ImportFrom):
                        if node.module and node.module.startswith(module_name):
                            imports.append(node.module)

                import_graph[module_id] = imports

            except Exception:
                # Skip files with syntax errors
                continue

        # Simple circular import detection
        for module_id, imports in import_graph.items():
            for imported in imports:
                if imported in import_graph:
                    if module_id in import_graph[imported]:
                        self.warning(f"Potential circular import between " f"{module_id} and {imported}", module_name)

        return success

    def _check_missing_dependencies(self, module_name: str) -> bool:
        """Check for missing module dependencies."""
        success = True
        module_path = self.base_path / module_name
        manifest_path = module_path / "__manifest__.py"

        if not manifest_path.exists():
            return success  # Already checked in validate_manifest

        try:
            with open(manifest_path, 'r') as f:
                manifest_content = f.read()

            # Extract dependencies from manifest
            manifest_globals = {}
            exec(manifest_content, manifest_globals)

            if '__manifest__' in manifest_globals:
                manifest = manifest_globals['__manifest__']
            else:
                manifest = eval(manifest_content)

            declared_deps = set(manifest.get('depends', []))

            # Find imports in Python files
            used_modules = set()
            for py_file in module_path.rglob("*.py"):
                try:
                    with open(py_file, 'r', encoding='utf-8') as f:
                        content = f.read()

                    # Look for common Odoo module imports
                    odoo_imports = re.findall(r'from\s+odoo\.addons\.(\w+)', content)
                    used_modules.update(odoo_imports)

                except Exception:
                    continue

            # Check for missing dependencies
            missing_deps = used_modules - declared_deps - {module_name}
            for missing in missing_deps:
                self.warning(f"Module '{missing}' imported but not declared " f"in dependencies", module_name)

        except Exception as e:
            self.warning(f"Could not check dependencies: {e}", module_name)

        return success

    def _check_deprecated_odoo_patterns(self, module_name: str) -> bool:
        """Check for deprecated Odoo development patterns."""
        success = True
        module_path = self.base_path / module_name

        for py_file in module_path.rglob("*.py"):
            rel_path = py_file.relative_to(module_path)

            try:
                with open(py_file, 'r', encoding='utf-8') as f:
                    content = f.read()

                lines = content.split('\n')

                for i, line in enumerate(lines, 1):
                    # Deprecated: Using osv module
                    osv_patterns = ['from openerp.osv import', 'import openerp.osv']
                    if any(pattern in line for pattern in osv_patterns):
                        self.warning(
                            f"Deprecated osv import detected. " f"Use odoo.models instead. Line {i}",
                            module_name,
                            str(rel_path),
                        )

                    # Deprecated: Using old API decorators
                    if '@api.one' in line or '@api.multi' in line:
                        self.warning(
                            f"Deprecated API decorator detected. " f"Use @api.model or remove. Line {i}",
                            module_name,
                            str(rel_path),
                        )

                    # Anti-pattern: Direct SQL without proper escaping
                    sql_check = '_cr.execute' in line and '%' in line and 'format' not in line
                    if sql_check:
                        self.warning(
                            f"Direct SQL with string formatting. " f"Use cr.execute with params. Line {i}",
                            module_name,
                            str(rel_path),
                        )

                    # Anti-pattern: Using sudo() without proper consideration
                    sudo_check = '.sudo()' in line and 'test' not in str(rel_path).lower()
                    if sudo_check:
                        self.warning(
                            f"sudo() usage detected. Ensure security " f"implications are considered. Line {i}",
                            module_name,
                            str(rel_path),
                        )

            except Exception:
                continue

        return success

    def print_results(self):
        """Print validation results."""
        print("\n" + "=" * 60)
        print("ODOO MODULE VALIDATION RESULTS")
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
            print("\n✅ All validations passed!")
        elif not self.errors:
            print(f"\n✅ No errors found ({len(self.warnings)} warnings)")
        else:
            print(f"\n❌ Validation failed: {len(self.errors)} errors, {len(self.warnings)} warnings")

        print("=" * 60)


def main():
    """Main function."""
    validator = ModuleValidator()

    if len(sys.argv) > 1:
        module_name = sys.argv[1]
        success = validator.validate_module(module_name)
    else:
        success = validator.validate_all_modules()

    validator.print_results()

    # Exit with error code if validation failed
    sys.exit(0 if success and not validator.errors else 1)


if __name__ == "__main__":
    main()

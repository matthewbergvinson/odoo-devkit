#!/usr/bin/env python3
"""
Odoo XML Validation Script
Royal Textiles Project - Local Testing Infrastructure

This script provides comprehensive validation of XML files in Odoo modules,
including views, security files, and data files. It checks for XML syntax
errors and validates Odoo-specific structure requirements.

Key Features:
- XML syntax validation
- Odoo root element validation (<odoo>)
- Record structure validation
- Field and attribute validation
- Security file structure validation
- View structure validation for forms, trees, kanban, etc.
- Menu and action validation
- Data file structure validation

Usage:
    python scripts/validate-xml.py [module_name]
    python scripts/validate-xml.py  # validates all modules
"""

import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path
from typing import List, Optional, Tuple


class XMLValidator:
    """Comprehensive validator for Odoo XML files."""

    # Valid Odoo view types
    VALID_VIEW_TYPES = {
        'form',
        'tree',
        'kanban',
        'calendar',
        'pivot',
        'graph',
        'gantt',
        'dashboard',
        'search',
        'activity',
        'qweb',
        'map',
        'cohort',
    }

    # Valid field widget types (common ones)
    VALID_WIDGETS = {
        'char',
        'text',
        'html',
        'email',
        'url',
        'phone',
        'image',
        'binary',
        'selection',
        'radio',
        'many2one',
        'many2many',
        'one2many',
        'date',
        'datetime',
        'float',
        'monetary',
        'integer',
        'boolean',
        'progressbar',
        'handle',
        'priority',
        'toggle_button',
        'badge',
        'statusbar',
        'percentage',
        'float_time',
        'color',
        'signature',
    }

    # Valid record models for security and data
    SECURITY_MODELS = {'ir.model.access', 'ir.rule', 'res.groups', 'ir.module.category'}

    # Valid action types
    ACTION_MODELS = {
        'ir.actions.act_window',
        'ir.actions.act_url',
        'ir.actions.server',
        'ir.actions.report',
        'ir.actions.client',
        'ir.ui.menu',
    }

    def __init__(self, base_path: str = "custom_modules"):
        self.base_path = Path(base_path)
        self.errors: List[str] = []
        self.warnings: List[str] = []
        self.info: List[str] = []

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

    def get_line_number(self, element: ET.Element, xml_content: str) -> Optional[int]:
        """Get line number for an XML element (best effort)."""
        try:
            # This is a simplified approach - XML parsing doesn't preserve line numbers easily
            # We'll search for the element's tag in the content
            if hasattr(element, 'tag') and element.tag:
                # Look for the opening tag
                pattern = f"<{element.tag}"
                lines = xml_content.split('\n')
                for i, line in enumerate(lines, 1):
                    if pattern in line:
                        return i
            return None
        except (AttributeError, ValueError):
            return None

    def validate_xml_syntax(self, file_path: Path) -> Tuple[bool, Optional[ET.Element]]:
        """Validate XML syntax and return parsed tree."""
        try:
            tree = ET.parse(file_path)
            root = tree.getroot()
            return True, root
        except ET.ParseError as e:
            self.error(f"XML syntax error: {e}", str(file_path))
            return False, None
        except UnicodeDecodeError:
            self.error("File encoding not supported. Use UTF-8.", str(file_path))
            return False, None
        except Exception as e:
            self.error(f"XML parsing error: {e}", str(file_path))
            return False, None

    def validate_odoo_root_structure(self, root: ET.Element, file_path: Path) -> bool:
        """Validate that XML has proper Odoo root structure."""
        success = True

        # Check root element
        if root.tag != 'odoo':
            # Legacy format check
            if root.tag == 'openerp':
                self.warning("Using legacy '<openerp>' root element. Consider updating to '<odoo>'", str(file_path))
            else:
                self.error(f"Root element should be '<odoo>', found '<{root.tag}>'", str(file_path))
                success = False

        # Check for direct child elements - should typically be 'data' elements
        valid_root_children = {'data'}
        for child in root:
            if child.tag not in valid_root_children:
                if child.tag in {'record', 'menuitem', 'template'}:
                    self.warning(
                        f"Found '{child.tag}' directly under root. Consider wrapping in '<data>' element",
                        str(file_path),
                    )
                else:
                    self.warning(f"Unexpected root child element: '{child.tag}'", str(file_path))

        return success

    def validate_record_structure(self, record: ET.Element, file_path: Path) -> bool:
        """Validate structure of <record> elements."""
        success = True

        # Check required attributes
        if 'id' not in record.attrib:
            self.error("Record missing required 'id' attribute", str(file_path))
            success = False

        if 'model' not in record.attrib:
            self.error("Record missing required 'model' attribute", str(file_path))
            success = False
        else:
            model = record.attrib['model']
            # Validate model name format
            if not re.match(r'^[a-z][a-z0-9]*(\.[a-z][a-z0-9]*)*$', model):
                self.warning(f"Model name '{model}' doesn't follow naming convention", str(file_path))

        # Validate field elements
        for field in record.findall('field'):
            self.validate_field_element(field, file_path)

        return success

    def validate_field_element(self, field: ET.Element, file_path: Path) -> bool:
        """Validate <field> elements within records."""
        success = True

        # Check required 'name' attribute
        if 'name' not in field.attrib:
            self.error("Field element missing required 'name' attribute", str(file_path))
            success = False

        field_name = field.attrib.get('name', '')

        # Check for common field validation issues
        if 'eval' in field.attrib and 'ref' in field.attrib:
            self.warning(f"Field '{field_name}' has both 'eval' and 'ref' attributes", str(file_path))

        # Validate reference fields
        if 'ref' in field.attrib:
            ref_value = field.attrib['ref']
            if not ref_value:
                self.error(f"Field '{field_name}' has empty 'ref' attribute", str(file_path))
                success = False

        # Check for deprecated attributes
        deprecated_attrs = {'colspan', 'position'}
        for attr in deprecated_attrs:
            if attr in field.attrib and 'view' not in str(file_path).lower():
                self.warning(f"Field '{field_name}' uses potentially deprecated attribute '{attr}'", str(file_path))

        return success

    def validate_view_structure(self, record: ET.Element, file_path: Path) -> bool:
        """Validate view-specific record structure."""
        success = True

        if record.attrib.get('model') != 'ir.ui.view':
            return success

        # Find view type and architecture
        view_type = None
        arch_field = None

        for field in record.findall('field'):
            field_name = field.attrib.get('name')
            if field_name == 'type':
                view_type = field.text
            elif field_name == 'arch':
                arch_field = field

        # Validate view type
        if view_type and view_type not in self.VALID_VIEW_TYPES:
            self.warning(f"Unknown view type: '{view_type}'", str(file_path))

        # Validate view architecture
        if arch_field is not None:
            success &= self.validate_view_architecture(arch_field, view_type, file_path)

        return success

    def validate_view_architecture(self, arch_field: ET.Element, view_type: Optional[str], file_path: Path) -> bool:
        """Validate view architecture structure."""
        success = True

        # Check for proper view root elements
        valid_view_roots = {
            'form': {'form'},
            'tree': {'tree', 'list'},
            'kanban': {'kanban'},
            'search': {'search'},
            'calendar': {'calendar'},
            'pivot': {'pivot'},
            'graph': {'graph'},
            'gantt': {'gantt'},
        }

        if view_type and view_type in valid_view_roots:
            found_valid_root = False
            for child in arch_field:
                if child.tag in valid_view_roots[view_type]:
                    found_valid_root = True
                    break

            if not found_valid_root:
                expected_roots = ', '.join(valid_view_roots[view_type])
                self.warning(f"View type '{view_type}' should have root element: {expected_roots}", str(file_path))

        # Validate field widgets in views
        for field_elem in arch_field.iter('field'):
            if 'widget' in field_elem.attrib:
                widget = field_elem.attrib['widget']
                if widget not in self.VALID_WIDGETS:
                    self.add_info(f"Unknown widget type: '{widget}'", str(file_path))

        return success

    def validate_security_file(self, root: ET.Element, file_path: Path) -> bool:
        """Validate security-specific XML structure."""
        success = True

        for record in root.iter('record'):
            model = record.attrib.get('model')

            if model in self.SECURITY_MODELS:
                success &= self.validate_security_record(record, model, file_path)

        return success

    def validate_security_record(self, record: ET.Element, model: str, file_path: Path) -> bool:
        """Validate specific security record types."""
        success = True

        if model == 'ir.model.access':
            # Check required fields for access rights
            required_fields = {'name', 'model_id', 'perm_read', 'perm_write', 'perm_create', 'perm_unlink'}
            declared_fields = {field.attrib.get('name') for field in record.findall('field')}

            missing_fields = required_fields - declared_fields
            if missing_fields:
                self.warning(
                    f"Access rights record missing recommended fields: {', '.join(missing_fields)}", str(file_path)
                )

        elif model == 'ir.rule':
            # Check rule structure
            name_field = record.find("field[@name='name']")
            if name_field is None:
                self.error("Security rule missing 'name' field", str(file_path))
                success = False

        return success

    def validate_menu_and_actions(self, root: ET.Element, file_path: Path) -> bool:
        """Validate menu items and actions."""
        success = True

        # Validate menuitem elements
        for menuitem in root.iter('menuitem'):
            if 'id' not in menuitem.attrib:
                self.error("Menu item missing 'id' attribute", str(file_path))
                success = False

            if 'name' not in menuitem.attrib:
                self.error("Menu item missing 'name' attribute", str(file_path))
                success = False

        # Validate action records
        for record in root.iter('record'):
            model = record.attrib.get('model')
            if model in self.ACTION_MODELS:
                success &= self.validate_action_record(record, model, file_path)

        return success

    def validate_action_record(self, record: ET.Element, model: str, file_path: Path) -> bool:
        """Validate action record structure."""
        success = True

        if model == 'ir.actions.act_window':
            # Check for required fields
            required_fields = {'name', 'res_model', 'view_mode'}
            declared_fields = {field.attrib.get('name') for field in record.findall('field')}

            missing_fields = required_fields - declared_fields
            if missing_fields:
                self.warning(f"Window action missing recommended fields: {', '.join(missing_fields)}", str(file_path))

        elif model == 'ir.ui.menu':
            # Validate menu structure
            action_field = record.find("field[@name='action']")
            if action_field is not None and 'ref' in action_field.attrib:
                # This is good - menu references an action
                pass
            else:
                parent_field = record.find("field[@name='parent_id']")
                if parent_field is None:
                    self.add_info("Menu item without action or parent - may be a root menu", str(file_path))

        return success

    def validate_xml_file(self, file_path: Path, module_name: str) -> bool:
        """Validate a single XML file."""
        rel_path = file_path.relative_to(self.base_path / module_name)

        # Step 1: Validate XML syntax
        syntax_valid, root = self.validate_xml_syntax(file_path)
        if not syntax_valid or root is None:
            return False

        success = True

        # Step 2: Validate Odoo root structure
        success &= self.validate_odoo_root_structure(root, rel_path)

        # Step 3: Validate record structures
        for record in root.iter('record'):
            success &= self.validate_record_structure(record, rel_path)

        # Step 4: Validate view-specific structures
        for record in root.iter('record'):
            if record.attrib.get('model') == 'ir.ui.view':
                success &= self.validate_view_structure(record, rel_path)

        # Step 5: Validate security files
        if 'security' in str(rel_path):
            success &= self.validate_security_file(root, rel_path)

        # Step 6: Validate menus and actions
        success &= self.validate_menu_and_actions(root, rel_path)

        return success

    def validate_module_xml(self, module_name: str) -> bool:
        """Validate all XML files in a module."""
        module_path = self.base_path / module_name

        if not module_path.exists():
            self.error(f"Module directory not found: {module_name}")
            return False

        # Find all XML files
        xml_files = list(module_path.rglob("*.xml"))

        if not xml_files:
            self.add_info(f"No XML files found in module: {module_name}")
            return True

        success = True
        for xml_file in xml_files:
            if not self.validate_xml_file(xml_file, module_name):
                success = False

        return success

    def validate_all_modules(self) -> bool:
        """Validate XML files in all modules."""
        if not self.base_path.exists():
            self.error(f"Custom modules directory not found: {self.base_path}")
            return False

        modules = [d for d in self.base_path.iterdir() if d.is_dir() and not d.name.startswith('.')]

        if not modules:
            self.warning("No modules found in custom_modules directory")
            return True

        success = True
        for module_dir in modules:
            if not self.validate_module_xml(module_dir.name):
                success = False

        return success

    def print_results(self):
        """Print validation results in a clear, structured format."""
        print("\n" + "=" * 70)
        print("🔍 ODOO XML VALIDATION RESULTS")
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
            print("✅ ALL XML VALIDATIONS PASSED!")
        elif not self.errors:
            print(f"✅ No errors found ({len(self.warnings)} warnings)")
        else:
            print(f"❌ Validation failed: {len(self.errors)} errors, {len(self.warnings)} warnings")

        if total_issues == 0:
            print("🎉 Your XML files are ready for deployment!")

        print("=" * 70)


def main():
    """Main function."""
    validator = XMLValidator()

    print("🔍 Starting Odoo XML Validation...")

    if len(sys.argv) > 1:
        module_name = sys.argv[1]
        print(f"📦 Validating XML files in module: {module_name}")
        success = validator.validate_module_xml(module_name)
    else:
        print("📦 Validating XML files in all modules...")
        success = validator.validate_all_modules()

    validator.print_results()

    # Exit with error code if validation failed
    sys.exit(0 if success and not validator.errors else 1)


if __name__ == "__main__":
    main()

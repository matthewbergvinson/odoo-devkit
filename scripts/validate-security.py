#!/usr/bin/env python3
"""
Odoo Security File Validation Script
Royal Textiles Project - Local Testing Infrastructure

This script provides comprehensive validation of security files in Odoo modules,
including CSV access rights files, XML security rules, group definitions,
and security structure validation.

Key Features:
- CSV format and structure validation
- Access rights column validation
- Security rule XML validation
- Group definition validation
- Permission value validation
- Reference integrity checking
- Security file organization validation

Usage:
    python scripts/validate-security.py [module_name]
    python scripts/validate-security.py  # validates all modules
"""

import csv
import sys
import xml.etree.ElementTree as ET
from pathlib import Path
from typing import Dict, List, Optional, Set


class SecurityValidator:
    """Comprehensive validator for Odoo security files."""

    # Required columns for ir.model.access.csv
    REQUIRED_ACCESS_COLUMNS = {
        'id',
        'name',
        'model_id:id',
        'group_id:id',
        'perm_read',
        'perm_write',
        'perm_create',
        'perm_unlink',
    }

    # Optional columns for ir.model.access.csv
    OPTIONAL_ACCESS_COLUMNS = {'active', 'comment'}

    # Valid boolean values for permission columns
    VALID_PERMISSION_VALUES = {'1', '0', 'True', 'False', 'true', 'false'}

    # Valid security models in XML
    SECURITY_MODELS = {
        'ir.model.access',
        'ir.rule',
        'res.groups',
        'ir.module.category',
        'ir.actions.act_window',
        'ir.ui.menu',
    }

    # Required fields for different security record types
    REQUIRED_FIELDS = {
        'ir.model.access': {'name', 'model_id', 'perm_read', 'perm_write', 'perm_create', 'perm_unlink'},
        'ir.rule': {'name', 'model_id'},
        'res.groups': {'name', 'category_id'},
        'ir.module.category': {'name'},
    }

    def __init__(self, base_path: str = "custom_modules"):
        self.base_path = Path(base_path)
        self.errors: List[str] = []
        self.warnings: List[str] = []
        self.info: List[str] = []
        self.module_models: Dict[str, Set[str]] = {}
        self.module_groups: Dict[str, Set[str]] = {}

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

    def validate_csv_structure(self, file_path: Path) -> bool:
        """Validate CSV file structure and format."""
        success = True

        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                # Check if file is empty
                content = f.read().strip()
                if not content:
                    self.warning("Empty CSV file", str(file_path))
                    return False

                # Reset file pointer for CSV reader
                f.seek(0)

                # Detect CSV dialect
                sample = f.read(1024)
                f.seek(0)

                try:
                    dialect = csv.Sniffer().sniff(sample)
                except csv.Error:
                    # Use default dialect if detection fails
                    dialect = csv.excel

                # Read CSV with detected dialect
                reader = csv.DictReader(f, dialect=dialect)

                # Validate column structure
                if not reader.fieldnames:
                    self.error("CSV file has no headers", str(file_path))
                    return False

                fieldnames = set(reader.fieldnames)

                # Check for required columns
                missing_required = self.REQUIRED_ACCESS_COLUMNS - fieldnames
                if missing_required:
                    self.error(f"Missing required columns: {', '.join(missing_required)}", str(file_path))
                    success = False

                # Check for unknown columns
                valid_columns = self.REQUIRED_ACCESS_COLUMNS | self.OPTIONAL_ACCESS_COLUMNS
                unknown_columns = fieldnames - valid_columns
                if unknown_columns:
                    self.warning(f"Unknown columns: {', '.join(unknown_columns)}", str(file_path))

                # Validate row content
                row_num = 1
                for row in reader:
                    row_num += 1
                    success &= self.validate_csv_row(row, file_path, row_num)

                # Check if file has any data rows
                if row_num == 1:
                    self.warning("CSV file has headers but no data", str(file_path))

        except UnicodeDecodeError:
            self.error("File encoding not supported. Use UTF-8.", str(file_path))
            success = False
        except Exception as e:
            self.error(f"Error reading CSV file: {e}", str(file_path))
            success = False

        return success

    def validate_csv_row(self, row: Dict[str, str], file_path: Path, row_num: int) -> bool:
        """Validate a single CSV row."""
        success = True

        # Check for empty required fields
        for field in self.REQUIRED_ACCESS_COLUMNS:
            if field in row and not row[field].strip():
                self.error(f"Empty required field '{field}'", str(file_path), row_num)
                success = False

        # Validate permission values
        permission_fields = {'perm_read', 'perm_write', 'perm_create', 'perm_unlink'}
        for field in permission_fields:
            if field in row and row[field].strip():
                value = row[field].strip()
                if value not in self.VALID_PERMISSION_VALUES:
                    self.error(
                        f"Invalid permission value '{value}' for {field}. Use: {', '.join(self.VALID_PERMISSION_VALUES)}",
                        str(file_path),
                        row_num,
                    )
                    success = False

        # Validate ID format
        if 'id' in row and row['id'].strip():
            id_value = row['id'].strip()
            if not id_value.replace('_', '').replace('.', '').isalnum():
                self.warning(f"ID '{id_value}' contains unusual characters", str(file_path), row_num)

        # Validate model reference format
        if 'model_id:id' in row and row['model_id:id'].strip():
            model_ref = row['model_id:id'].strip()
            if not model_ref.startswith('model_'):
                self.warning(f"Model reference '{model_ref}' should start with 'model_'", str(file_path), row_num)

        # Validate group reference format
        if 'group_id:id' in row and row['group_id:id'].strip():
            group_ref = row['group_id:id'].strip()
            # Group references can be external (module.group_name) or internal
            if '.' not in group_ref and not group_ref.startswith('group_'):
                self.add_info(
                    f"Group reference '{group_ref}' - consider using 'group_' prefix or module.group format",
                    str(file_path),
                    row_num,
                )

        return success

    def validate_xml_security(self, file_path: Path) -> bool:
        """Validate XML security files."""
        success = True

        try:
            tree = ET.parse(file_path)
            root = tree.getroot()
        except ET.ParseError as e:
            self.error(f"XML parsing error: {e}", str(file_path))
            return False
        except Exception as e:
            self.error(f"Error reading XML file: {e}", str(file_path))
            return False

        # Check root element
        if root.tag not in ['odoo', 'openerp']:
            self.error(f"Invalid root element '{root.tag}'. Expected 'odoo' or 'openerp'", str(file_path))
            success = False

        # Validate security records
        for record in root.iter('record'):
            model = record.attrib.get('model')
            if model in self.SECURITY_MODELS:
                success &= self.validate_security_record(record, file_path)

        # Validate menu items (they can have security implications)
        for menuitem in root.iter('menuitem'):
            success &= self.validate_menuitem_security(menuitem, file_path)

        return success

    def validate_security_record(self, record: ET.Element, file_path: Path) -> bool:
        """Validate a security record in XML."""
        success = True

        model = record.attrib.get('model')
        record_id = record.attrib.get('id', 'unknown')

        # Check required attributes
        if not record.attrib.get('id'):
            self.error("Security record missing 'id' attribute", str(file_path))
            success = False

        if not model:
            self.error("Security record missing 'model' attribute", str(file_path))
            success = False
            return success

        # Get field values
        field_values = {}
        for field in record.findall('field'):
            field_name = field.attrib.get('name')
            if field_name:
                field_values[field_name] = field.text or field.attrib.get('ref', '')

        # Check required fields for specific models
        if model in self.REQUIRED_FIELDS:
            missing_fields = self.REQUIRED_FIELDS[model] - set(field_values.keys())
            if missing_fields:
                self.error(f"Record '{record_id}' missing required fields: {', '.join(missing_fields)}", str(file_path))
                success = False

        # Model-specific validation
        if model == 'ir.model.access':
            success &= self.validate_access_record(record, field_values, file_path)
        elif model == 'ir.rule':
            success &= self.validate_rule_record(record, field_values, file_path)
        elif model == 'res.groups':
            success &= self.validate_group_record(record, field_values, file_path)

        return success

    def validate_access_record(self, record: ET.Element, fields: Dict[str, str], file_path: Path) -> bool:
        """Validate ir.model.access record."""
        success = True

        # Validate permission fields
        permission_fields = {'perm_read', 'perm_write', 'perm_create', 'perm_unlink'}
        for perm_field in permission_fields:
            if perm_field in fields:
                value = fields[perm_field].strip()
                if value and value not in self.VALID_PERMISSION_VALUES:
                    self.error(f"Invalid permission value '{value}' for {perm_field}", str(file_path))
                    success = False

        # Check model reference
        if 'model_id' in fields:
            model_ref = fields['model_id']
            if model_ref and not model_ref.startswith('model_'):
                self.warning(f"Model reference '{model_ref}' should reference a model record", str(file_path))

        return success

    def validate_rule_record(self, record: ET.Element, fields: Dict[str, str], file_path: Path) -> bool:
        """Validate ir.rule record."""
        success = True

        # Check for domain_force field
        if 'domain_force' not in fields:
            self.warning("Security rule without 'domain_force' field", str(file_path))
        elif fields.get('domain_force'):
            domain = fields['domain_force']
            # Basic domain syntax validation
            if not (domain.startswith('[') and domain.endswith(']')):
                self.warning(f"Domain '{domain}' should be a list format", str(file_path))

        # Check rule type fields
        rule_types = {'perm_read', 'perm_write', 'perm_create', 'perm_unlink'}
        has_rule_type = any(field in fields for field in rule_types)
        if not has_rule_type:
            self.add_info("Security rule without specific permission types (applies to all)", str(file_path))

        return success

    def validate_group_record(self, record: ET.Element, fields: Dict[str, str], file_path: Path) -> bool:
        """Validate res.groups record."""
        success = True

        # Check category reference
        if 'category_id' in fields:
            category_ref = fields['category_id']
            if category_ref and not (category_ref.startswith('module_category_') or '.' in category_ref):
                self.add_info(
                    f"Category reference '{category_ref}' - ensure it references a valid category", str(file_path)
                )

        # Check for implied_ids field (group inheritance)
        if 'implied_ids' in fields:
            self.add_info("Group uses inheritance (implied_ids)", str(file_path))

        return success

    def validate_menuitem_security(self, menuitem: ET.Element, file_path: Path) -> bool:
        """Validate menuitem security attributes."""
        success = True

        # Check for groups attribute
        if 'groups' in menuitem.attrib:
            groups = menuitem.attrib['groups']
            # Groups should be comma-separated external IDs
            if groups and not all(g.strip() for g in groups.split(',')):
                self.warning("Empty group reference in menuitem", str(file_path))
        else:
            self.add_info("Menu item without explicit groups (visible to all users)", str(file_path))

        return success

    def validate_security_file_organization(self, module_path: Path, module_name: str) -> bool:
        """Validate security file organization and naming."""
        success = True

        security_dir = module_path / 'security'

        if not security_dir.exists():
            self.add_info(f"No security directory found in module: {module_name}")
            return True

        # Check for common security files
        access_csv = security_dir / 'ir.model.access.csv'
        if not access_csv.exists():
            self.add_info("No ir.model.access.csv file found", str(security_dir))

        # Check for XML security files
        xml_files = list(security_dir.glob('*.xml'))
        if not xml_files:
            self.add_info("No XML security files found", str(security_dir))

        # Validate file naming conventions
        for file_path in security_dir.iterdir():
            if file_path.is_file():
                filename = file_path.name
                if filename.endswith('.csv') and filename != 'ir.model.access.csv':
                    self.warning(f"Unusual CSV filename: {filename}", str(file_path))
                elif filename.endswith('.xml') and not filename.endswith('_security.xml'):
                    self.add_info(f"Consider using '_security.xml' suffix: {filename}", str(file_path))

        return success

    def validate_module_security(self, module_name: str) -> bool:
        """Validate all security files in a module."""
        module_path = self.base_path / module_name

        if not module_path.exists():
            self.error(f"Module directory not found: {module_name}")
            return False

        success = True

        # Validate file organization
        success &= self.validate_security_file_organization(module_path, module_name)

        security_dir = module_path / 'security'
        if not security_dir.exists():
            return success

        # Validate CSV files
        csv_files = list(security_dir.glob('*.csv'))
        for csv_file in csv_files:
            if not self.validate_csv_structure(csv_file):
                success = False

        # Validate XML files
        xml_files = list(security_dir.glob('*.xml'))
        for xml_file in xml_files:
            if not self.validate_xml_security(xml_file):
                success = False

        return success

    def validate_all_modules(self) -> bool:
        """Validate security files in all modules."""
        if not self.base_path.exists():
            self.error(f"Custom modules directory not found: {self.base_path}")
            return False

        modules = [d for d in self.base_path.iterdir() if d.is_dir() and not d.name.startswith('.')]

        if not modules:
            self.warning("No modules found in custom_modules directory")
            return True

        success = True
        for module_dir in modules:
            if not self.validate_module_security(module_dir.name):
                success = False

        return success

    def print_results(self):
        """Print validation results in a clear, structured format."""
        print("\n" + "=" * 70)
        print("🔍 ODOO SECURITY FILE VALIDATION RESULTS")
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
            print("✅ ALL SECURITY VALIDATIONS PASSED!")
        elif not self.errors:
            print(f"✅ No errors found ({len(self.warnings)} warnings)")
        else:
            print(f"❌ Validation failed: {len(self.errors)} errors, {len(self.warnings)} warnings")

        if total_issues == 0:
            print("🎉 Your security files are properly configured!")

        print("=" * 70)


def main():
    """Main function."""
    validator = SecurityValidator()

    print("🔍 Starting Odoo Security File Validation...")

    if len(sys.argv) > 1:
        module_name = sys.argv[1]
        print(f"📦 Validating security files in module: {module_name}")
        success = validator.validate_module_security(module_name)
    else:
        print("📦 Validating security files in all modules...")
        success = validator.validate_all_modules()

    validator.print_results()

    # Exit with error code if validation failed
    sys.exit(0 if success and not validator.errors else 1)


if __name__ == "__main__":
    main()

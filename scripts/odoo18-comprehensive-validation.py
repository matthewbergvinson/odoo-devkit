#!/usr/bin/env python3
"""
Comprehensive Odoo 18 Validation Script

This script performs thorough validation against official Odoo 18 standards
based on the official documentation at https://www.odoo.com/documentation/18.0/

Validates:
- Module manifest structure and required fields
- XML file structure and Odoo-specific syntax
- Model definitions and constraints
- Demo data integrity
- Security access rules
- View definitions
- Data file loading order
"""

import argparse
import ast
import json
import re
import sys
import xml.etree.ElementTree as ET
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Set, Tuple, Any


class Odoo18Validator:
    """Comprehensive Odoo 18 module validator"""
    
    def __init__(self, module_path: str):
        self.module_path = Path(module_path)
        self.module_name = self.module_path.name
        self.errors = []
        self.warnings = []
        self.info = []
        
        # Odoo 18 Standards
        self.required_manifest_fields = ['name', 'version', 'depends']
        self.recommended_manifest_fields = [
            'author', 'category', 'description', 'license', 
            'installable', 'auto_install'
        ]
        self.standard_odoo_models = {
            'res.partner', 'res.users', 'res.company', 'res.currency',
            'project.project', 'project.task', 'mail.thread', 'mail.activity.mixin',
            'account.move', 'sale.order', 'purchase.order', 'stock.picking',
            'hr.employee', 'calendar.event', 'ir.sequence', 'ir.cron',
            'ir.model.access', 'ir.ui.view', 'ir.ui.menu', 'ir.actions.act_window'
        }
        
    def validate(self) -> bool:
        """Run comprehensive Odoo 18 validation"""
        print(f"🔍 Comprehensive Odoo 18 Validation")
        print(f"📁 Module: {self.module_name}")
        print(f"📍 Path: {self.module_path}")
        print("=" * 60)
        
        # Core validations
        self._validate_module_structure()
        self._validate_manifest_file()
        self._validate_python_files()
        self._validate_xml_files()
        self._validate_demo_data()
        self._validate_security_files()
        self._validate_data_loading_order()
        
        # Report results
        self._report_results()
        
        return len(self.errors) == 0
    
    def _validate_module_structure(self):
        """Validate Odoo 18 module structure requirements"""
        print("📋 Validating module structure...")
        
        # Required files
        required_files = ['__init__.py', '__manifest__.py']
        for file_name in required_files:
            file_path = self.module_path / file_name
            if not file_path.exists():
                self.errors.append(f"Missing required file: {file_name}")
            else:
                self.info.append(f"✓ Found required file: {file_name}")
        
        # Expected directories
        expected_dirs = ['models', 'views', 'data', 'demo', 'security', 'static']
        existing_dirs = []
        for dir_name in expected_dirs:
            dir_path = self.module_path / dir_name
            if dir_path.exists() and dir_path.is_dir():
                existing_dirs.append(dir_name)
                
        self.info.append(f"✓ Found directories: {', '.join(existing_dirs)}")
        
        # Check for common issues
        if not (self.module_path / 'models').exists():
            self.warnings.append("No models directory found - is this a UI-only module?")
        if not (self.module_path / 'security').exists():
            self.warnings.append("No security directory found - access controls may be missing")
            
    def _validate_manifest_file(self):
        """Validate manifest file against Odoo 18 standards"""
        print("📄 Validating manifest file...")
        
        manifest_path = self.module_path / '__manifest__.py'
        if not manifest_path.exists():
            self.errors.append("__manifest__.py file not found")
            return
            
        try:
            content = manifest_path.read_text()
            manifest = ast.literal_eval(content.strip())
            
            if not isinstance(manifest, dict):
                self.errors.append("Manifest must be a dictionary")
                return
                
            # Check required fields
            for field in self.required_manifest_fields:
                if field not in manifest:
                    self.errors.append(f"Missing required manifest field: '{field}'")
                else:
                    self.info.append(f"✓ Required field '{field}': {manifest[field]}")
            
            # Check recommended fields
            for field in self.recommended_manifest_fields:
                if field not in manifest:
                    self.warnings.append(f"Missing recommended manifest field: '{field}'")
                else:
                    self.info.append(f"✓ Recommended field '{field}': {manifest[field]}")
            
            # Validate version format
            if 'version' in manifest:
                version = manifest['version']
                if not re.match(r'^\d+\.\d+\.\d+\.\d+\.\d+$', version):
                    self.warnings.append(f"Version format should be X.Y.Z.A.B, got: {version}")
                elif not version.startswith('18.0'):
                    self.warnings.append(f"Version should start with '18.0' for Odoo 18, got: {version}")
            
            # Validate dependencies
            if 'depends' in manifest:
                depends = manifest['depends']
                if not isinstance(depends, list):
                    self.errors.append("'depends' field must be a list")
                elif 'base' not in depends:
                    self.warnings.append("'base' module not in dependencies - this is unusual")
            
            # Check data and demo files existence
            for file_type in ['data', 'demo']:
                if file_type in manifest:
                    files = manifest[file_type]
                    if isinstance(files, list):
                        for file_path in files:
                            full_path = self.module_path / file_path
                            if not full_path.exists():
                                self.errors.append(f"File listed in manifest '{file_type}' not found: {file_path}")
                            else:
                                self.info.append(f"✓ {file_type.title()} file exists: {file_path}")
            
            # Validate license
            if 'license' in manifest:
                valid_licenses = ['LGPL-3', 'AGPL-3', 'OPL-1', 'MIT', 'BSD-3-Clause']
                license_val = manifest['license']
                if license_val not in valid_licenses:
                    self.warnings.append(f"License '{license_val}' not in standard list: {valid_licenses}")
            
            # Check installable flag
            if manifest.get('installable') is False:
                self.warnings.append("Module marked as not installable")
                
        except (SyntaxError, ValueError) as e:
            self.errors.append(f"Invalid Python syntax in manifest: {e}")
        except Exception as e:
            self.errors.append(f"Error reading manifest: {e}")
    
    def _validate_python_files(self):
        """Validate Python model files"""
        print("🐍 Validating Python files...")
        
        models_path = self.module_path / 'models'
        if not models_path.exists():
            return
            
        python_files = list(models_path.glob('*.py'))
        if not python_files:
            self.warnings.append("No Python model files found in models directory")
            return
            
        for py_file in python_files:
            self._validate_python_file(py_file)
    
    def _validate_python_file(self, file_path: Path):
        """Validate individual Python file"""
        try:
            content = file_path.read_text()
            
            # Check for Odoo imports
            if 'from odoo import' not in content and 'import odoo' not in content:
                if file_path.name != '__init__.py':
                    self.warnings.append(f"No Odoo imports found in {file_path.name}")
            
            # Check for proper model structure
            if re.search(r'class\s+\w+\s*\([^)]*models\.Model\)', content):
                self.info.append(f"✓ Model class found in {file_path.name}")
                
                # Check for _name attribute
                if '_name = ' not in content:
                    self.warnings.append(f"Model in {file_path.name} missing _name attribute")
                
                # Check for _description attribute
                if '_description = ' not in content:
                    self.warnings.append(f"Model in {file_path.name} missing _description attribute")
            
            # Check for security vulnerabilities
            dangerous_patterns = [
                (r'eval\s*\(', "Use of eval() is dangerous"),
                (r'exec\s*\(', "Use of exec() is dangerous"), 
                (r'__import__\s*\(', "Use of __import__() can be dangerous"),
                (r'getattr\s*\([^,]+,\s*[^,\)]+\)', "Dynamic getattr() without safe defaults"),
            ]
            
            for pattern, message in dangerous_patterns:
                if re.search(pattern, content):
                    self.warnings.append(f"Security concern in {file_path.name}: {message}")
            
            # Check for Odoo 18 best practices
            if 'fields.Date.today()' in content:
                self.warnings.append(f"Use of fields.Date.today() in {file_path.name} - consider context-aware dates")
            
            if 'TODO' in content or 'FIXME' in content:
                self.warnings.append(f"TODO/FIXME comments in {file_path.name} - complete before production")
            
        except Exception as e:
            self.errors.append(f"Error validating Python file {file_path.name}: {e}")
    
    def _validate_xml_files(self):
        """Validate XML files structure and syntax"""
        print("📄 Validating XML files...")
        
        xml_files = list(self.module_path.glob('**/*.xml'))
        if not xml_files:
            self.warnings.append("No XML files found")
            return
            
        for xml_file in xml_files:
            self._validate_xml_file(xml_file)
    
    def _validate_xml_file(self, file_path: Path):
        """Validate individual XML file"""
        try:
            tree = ET.parse(file_path)
            root = tree.getroot()
            
            # Check root element
            if root.tag != 'odoo':
                self.errors.append(f"XML file {file_path.name} should have <odoo> as root element, got <{root.tag}>")
            
            # Check for data wrapper
            data_elements = root.findall('data')
            if not data_elements:
                self.warnings.append(f"XML file {file_path.name} missing <data> wrapper element")
            
            # Validate records
            for record in root.findall('.//record'):
                self._validate_xml_record(record, file_path)
            
            # Validate menuitem elements
            for menuitem in root.findall('.//menuitem'):
                self._validate_menuitem(menuitem, file_path)
            
            # Check for proper encoding declaration
            with open(file_path, 'r', encoding='utf-8') as f:
                first_line = f.readline()
                if 'encoding="utf-8"' not in first_line:
                    self.warnings.append(f"XML file {file_path.name} missing UTF-8 encoding declaration")
            
            self.info.append(f"✓ XML syntax valid: {file_path.name}")
            
        except ET.ParseError as e:
            self.errors.append(f"XML parsing error in {file_path.name}: {e}")
        except Exception as e:
            self.errors.append(f"Error validating XML file {file_path.name}: {e}")
    
    def _validate_xml_record(self, record: ET.Element, file_path: Path):
        """Validate XML record element"""
        # Check required attributes
        if not record.get('id'):
            self.errors.append(f"Record in {file_path.name} missing 'id' attribute")
        if not record.get('model'):
            self.errors.append(f"Record in {file_path.name} missing 'model' attribute")
        
        # Check for proper field elements
        for field in record.findall('field'):
            field_name = field.get('name')
            if not field_name:
                self.errors.append(f"Field in {file_path.name} missing 'name' attribute")
            
            # Check for potentially problematic eval expressions
            if field.get('eval'):
                eval_expr = field.get('eval')
                if any(dangerous in eval_expr for dangerous in ['__', 'eval', 'exec', 'import']):
                    self.warnings.append(
                        f"Potentially dangerous eval expression in {file_path.name}: {eval_expr}"
                    )
    
    def _validate_menuitem(self, menuitem: ET.Element, file_path: Path):
        """Validate menuitem element"""
        if not menuitem.get('id'):
            self.errors.append(f"Menuitem in {file_path.name} missing 'id' attribute")
        if not menuitem.get('name'):
            self.errors.append(f"Menuitem in {file_path.name} missing 'name' attribute")
    
    def _validate_demo_data(self):
        """Validate demo data files"""
        print("🎯 Validating demo data...")
        
        demo_path = self.module_path / 'demo'
        if not demo_path.exists():
            self.info.append("No demo directory found")
            return
            
        demo_files = list(demo_path.glob('*.xml'))
        if not demo_files:
            self.warnings.append("Demo directory exists but contains no XML files")
            return
            
        for demo_file in demo_files:
            self._validate_demo_file(demo_file)
    
    def _validate_demo_file(self, file_path: Path):
        """Validate demo data file"""
        try:
            tree = ET.parse(file_path)
            root = tree.getroot()
            
            records_count = len(root.findall('.//record'))
            self.info.append(f"✓ Demo file {file_path.name}: {records_count} records")
            
            # Check for proper demo data practices
            for record in root.findall('.//record'):
                record_id = record.get('id')
                if record_id and not any(record_id.startswith(prefix) for prefix in ['demo_', 'sample_']):
                    self.warnings.append(
                        f"Demo record ID '{record_id}' should start with 'demo_' or 'sample_'"
                    )
                
                # Check for hardcoded dates in the past
                for field in record.findall('field'):
                    field_text = field.text or ''
                    if re.match(r'\d{4}-\d{2}-\d{2}', field_text):
                        try:
                            date_val = datetime.strptime(field_text, '%Y-%m-%d')
                            if date_val.year < 2024:
                                self.warnings.append(
                                    f"Old date in demo data {file_path.name}: {field_text}"
                                )
                        except ValueError:
                            pass
                            
        except ET.ParseError as e:
            self.errors.append(f"Demo data XML parsing error in {file_path.name}: {e}")
    
    def _validate_security_files(self):
        """Validate security access rules"""
        print("🔐 Validating security files...")
        
        security_path = self.module_path / 'security'
        if not security_path.exists():
            self.warnings.append("No security directory found")
            return
            
        # Check for access rules file
        access_file = security_path / 'ir.model.access.csv'
        if access_file.exists():
            self._validate_access_rules(access_file)
        else:
            self.warnings.append("No ir.model.access.csv file found")
        
        # Check for security XML files
        security_xml_files = list(security_path.glob('*.xml'))
        if security_xml_files:
            self.info.append(f"✓ Security XML files found: {len(security_xml_files)}")
        else:
            self.info.append("No security XML files found")
    
    def _validate_access_rules(self, file_path: Path):
        """Validate access rules CSV file"""
        try:
            content = file_path.read_text()
            lines = content.strip().split('\n')
            
            if not lines:
                self.errors.append("Access rules file is empty")
                return
                
            # Check header
            header = lines[0]
            expected_header = 'id,name,model_id:id,group_id:id,perm_read,perm_write,perm_create,perm_unlink'
            if header != expected_header:
                self.errors.append(f"Invalid access rules header. Expected: {expected_header}")
            
            # Validate each rule
            for i, line in enumerate(lines[1:], 2):
                if line.strip():
                    parts = line.split(',')
                    if len(parts) != 8:
                        self.errors.append(f"Invalid access rule on line {i}: wrong number of columns")
                    else:
                        # Check permissions are 0 or 1
                        for j, perm in enumerate(parts[4:8], 4):
                            if perm not in ['0', '1']:
                                self.errors.append(f"Invalid permission value on line {i}, column {j+1}: {perm}")
                                
            self.info.append(f"✓ Access rules validated: {len(lines)-1} rules")
            
        except Exception as e:
            self.errors.append(f"Error validating access rules: {e}")
    
    def _validate_data_loading_order(self):
        """Validate data file loading order"""
        print("📊 Validating data loading order...")
        
        manifest_path = self.module_path / '__manifest__.py'
        try:
            content = manifest_path.read_text()
            manifest = ast.literal_eval(content.strip())
            
            if 'data' in manifest:
                data_files = manifest['data']
                
                # Check recommended loading order
                file_types = {
                    'security': [],
                    'data': [],
                    'views': [],
                    'demo': []
                }
                
                for file_path in data_files:
                    if 'security/' in file_path:
                        file_types['security'].append(file_path)
                    elif 'data/' in file_path:
                        file_types['data'].append(file_path)
                    elif 'views/' in file_path:
                        file_types['views'].append(file_path)
                    elif 'demo/' in file_path:
                        file_types['demo'].append(file_path)
                
                # Security files should be loaded first
                if file_types['security'] and file_types['views']:
                    first_security_idx = data_files.index(file_types['security'][0])
                    first_view_idx = data_files.index(file_types['views'][0])
                    if first_security_idx > first_view_idx:
                        self.warnings.append("Security files should be loaded before view files")
                
                self.info.append(f"✓ Data loading order checked: {len(data_files)} files")
                
        except Exception as e:
            self.warnings.append(f"Could not validate data loading order: {e}")
    
    def _report_results(self):
        """Report validation results"""
        print("\n" + "="*60)
        print("📊 COMPREHENSIVE ODOO 18 VALIDATION RESULTS")
        print("="*60)
        
        if self.errors:
            print(f"❌ {len(self.errors)} ERRORS:")
            for i, error in enumerate(self.errors, 1):
                print(f"   {i}. {error}")
        
        if self.warnings:
            print(f"\n⚠️  {len(self.warnings)} WARNINGS:")
            for i, warning in enumerate(self.warnings, 1):
                print(f"   {i}. {warning}")
        
        if self.info:
            print(f"\n✅ {len(self.info)} CHECKS PASSED:")
            for info in self.info[:10]:  # Show first 10
                print(f"   • {info}")
            if len(self.info) > 10:
                print(f"   ... and {len(self.info) - 10} more checks")
        
        print(f"\n📈 SUMMARY:")
        print(f"   • Module: {self.module_name}")
        print(f"   • Errors: {len(self.errors)}")
        print(f"   • Warnings: {len(self.warnings)}")
        print(f"   • Checks passed: {len(self.info)}")
        
        if len(self.errors) == 0:
            print(f"\n🎉 MODULE VALIDATION PASSED!")
            if len(self.warnings) > 0:
                print(f"   Review {len(self.warnings)} warnings for optimization")
        else:
            print(f"\n💥 MODULE VALIDATION FAILED!")
            print(f"   Fix {len(self.errors)} errors before deployment")


def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(
        description="Comprehensive Odoo 18 module validation"
    )
    parser.add_argument(
        "module_path",
        help="Path to the Odoo module directory"
    )
    
    args = parser.parse_args()
    
    validator = Odoo18Validator(args.module_path)
    success = validator.validate()
    
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
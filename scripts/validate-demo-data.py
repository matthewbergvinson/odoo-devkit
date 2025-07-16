#!/usr/bin/env python3
"""
Demo Data Validation Script for Odoo 18

This script validates demo data files against model definitions to prevent
common issues like field type mismatches, invalid selection values, and
constraint violations.

Based on lessons learned from Royal Textiles Construction Management module.
"""

import argparse
import ast
import re
import sys
import xml.etree.ElementTree as ET
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Set, Tuple


class DemoDataValidator:
    """Validate demo data against model definitions"""
    
    def __init__(self, module_path: str):
        self.module_path = Path(module_path)
        self.models_path = self.module_path / "models"
        self.demo_path = self.module_path / "demo"
        self.errors = []
        self.warnings = []
        
        # Field type mappings
        self.selection_fields = {}
        self.date_fields = set()
        self.many2one_fields = {}
        self.constrains_fields = {}
        
    def validate(self) -> bool:
        """Run full validation suite"""
        print(f"🔍 Validating demo data for module: {self.module_path.name}")
        
        # Step 1: Parse model definitions
        if not self._parse_models():
            return False
            
        # Step 2: Validate demo data files
        if not self._validate_demo_files():
            return False
            
        # Step 3: Check business logic constraints
        if not self._validate_constraints():
            return False
            
        # Step 4: Report results
        self._report_results()
        
        return len(self.errors) == 0
    
    def _parse_models(self) -> bool:
        """Parse model files to extract field definitions"""
        print("📋 Parsing model definitions...")
        
        if not self.models_path.exists():
            self.errors.append(f"Models directory not found: {self.models_path}")
            return False
            
        model_files = list(self.models_path.glob("*.py"))
        if not model_files:
            self.warnings.append("No model files found")
            return True
            
        for model_file in model_files:
            self._parse_model_file(model_file)
            
        print(f"   ✅ Found {len(self.selection_fields)} selection fields")
        print(f"   ✅ Found {len(self.date_fields)} date fields")
        print(f"   ✅ Found {len(self.many2one_fields)} many2one fields")
        print(f"   ✅ Found {len(self.constrains_fields)} constraint fields")
        
        return True
    
    def _parse_model_file(self, model_file: Path):
        """Parse a single model file for field definitions"""
        try:
            content = model_file.read_text()
            
            # Find selection fields
            selection_pattern = r'(\w+)\s*=\s*fields\.Selection\(\s*\[(.*?)\]'
            for match in re.finditer(selection_pattern, content, re.DOTALL):
                field_name = match.group(1)
                options_str = match.group(2)
                
                # Parse selection options
                options = []
                option_pattern = r'\(\s*["\']([^"\']+)["\']'
                for option_match in re.finditer(option_pattern, options_str):
                    options.append(option_match.group(1))
                    
                self.selection_fields[field_name] = options
            
            # Find date fields
            date_pattern = r'(\w+)\s*=\s*fields\.(Date|Datetime)\('
            for match in re.finditer(date_pattern, content):
                self.date_fields.add(match.group(1))
                
            # Find many2one fields
            many2one_pattern = r'(\w+)\s*=\s*fields\.Many2one\(\s*["\']([^"\']+)["\']'
            for match in re.finditer(many2one_pattern, content):
                field_name = match.group(1)
                target_model = match.group(2)
                self.many2one_fields[field_name] = target_model
                
            # Find constraint decorators
            constraint_pattern = r'@api\.constrains\(["\']([^"\']+)["\'].*?\)'
            for match in re.finditer(constraint_pattern, content):
                fields = match.group(1).split('", "')
                for field in fields:
                    field = field.strip('"\'')
                    if field not in self.constrains_fields:
                        self.constrains_fields[field] = []
                    self.constrains_fields[field].append(model_file.name)
                    
        except Exception as e:
            self.warnings.append(f"Error parsing {model_file}: {e}")
    
    def _validate_demo_files(self) -> bool:
        """Validate all demo data files"""
        print("🎯 Validating demo data files...")
        
        if not self.demo_path.exists():
            self.warnings.append(f"Demo directory not found: {self.demo_path}")
            return True
            
        demo_files = list(self.demo_path.glob("*.xml"))
        if not demo_files:
            self.warnings.append("No demo data files found")
            return True
            
        for demo_file in demo_files:
            self._validate_demo_file(demo_file)
            
        return True
    
    def _validate_demo_file(self, demo_file: Path):
        """Validate a single demo data file"""
        try:
            tree = ET.parse(demo_file)
            root = tree.getroot()
            
            for record in root.findall(".//record"):
                self._validate_record(record, demo_file)
                
        except ET.ParseError as e:
            self.errors.append(f"XML parsing error in {demo_file}: {e}")
        except Exception as e:
            self.errors.append(f"Error validating {demo_file}: {e}")
    
    def _validate_record(self, record: ET.Element, demo_file: Path):
        """Validate a single record element"""
        record_id = record.get("id", "unknown")
        
        for field in record.findall("field"):
            field_name = field.get("name")
            field_value = field.text or ""
            
            # Skip if field not found in our definitions
            if not field_name:
                continue
                
            # Validate selection fields
            if field_name in self.selection_fields:
                self._validate_selection_field(
                    field_name, field_value, record_id, demo_file
                )
                
            # Validate date fields
            if field_name in self.date_fields:
                self._validate_date_field(
                    field_name, field_value, record_id, demo_file
                )
                
            # Check for eval expressions (discouraged)
            if field.get("eval"):
                self.warnings.append(
                    f"Eval expression in {demo_file}:{record_id}.{field_name} "
                    f"- consider using fixed values for stability"
                )
    
    def _validate_selection_field(self, field_name: str, field_value: str, 
                                 record_id: str, demo_file: Path):
        """Validate selection field values"""
        valid_options = self.selection_fields[field_name]
        
        # Check if field_value is a reference (starts with ref=)
        if field_value and not field_value.startswith("ref="):
            if field_value not in valid_options:
                self.errors.append(
                    f"Invalid selection value in {demo_file}:{record_id}.{field_name}: "
                    f"'{field_value}' not in {valid_options}"
                )
        elif field_value.startswith("ref="):
            self.errors.append(
                f"Selection field using record reference in {demo_file}:{record_id}.{field_name}: "
                f"'{field_value}' - should use selection value from {valid_options}"
            )
    
    def _validate_date_field(self, field_name: str, field_value: str, 
                            record_id: str, demo_file: Path):
        """Validate date field values"""
        if not field_value:
            return
            
        # Check date format
        date_formats = [
            "%Y-%m-%d",
            "%Y-%m-%d %H:%M:%S",
            "%Y-%m-%d %H:%M:%S.%f"
        ]
        
        valid_format = False
        parsed_date = None
        
        for fmt in date_formats:
            try:
                parsed_date = datetime.strptime(field_value, fmt)
                valid_format = True
                break
            except ValueError:
                continue
                
        if not valid_format:
            self.errors.append(
                f"Invalid date format in {demo_file}:{record_id}.{field_name}: "
                f"'{field_value}' - use YYYY-MM-DD or YYYY-MM-DD HH:MM:SS"
            )
            return
            
        # Check for dates that might be too far in the past
        if parsed_date and parsed_date.year < 2024:
            self.warnings.append(
                f"Old date in {demo_file}:{record_id}.{field_name}: "
                f"'{field_value}' - consider using more recent dates"
            )
    
    def _validate_constraints(self) -> bool:
        """Validate business logic constraints"""
        print("⚖️  Validating business logic constraints...")
        
        # This would require parsing the actual constraint logic
        # For now, we'll just report fields that have constraints
        if self.constrains_fields:
            print(f"   ⚠️  Found {len(self.constrains_fields)} fields with constraints:")
            for field, models in self.constrains_fields.items():
                print(f"      - {field} (in {', '.join(models)})")
                
        return True
    
    def _report_results(self):
        """Report validation results"""
        print("\n" + "="*50)
        print("📊 VALIDATION RESULTS")
        print("="*50)
        
        if self.errors:
            print(f"❌ {len(self.errors)} ERRORS found:")
            for error in self.errors:
                print(f"   • {error}")
        else:
            print("✅ No errors found!")
            
        if self.warnings:
            print(f"\n⚠️  {len(self.warnings)} WARNINGS:")
            for warning in self.warnings:
                print(f"   • {warning}")
        else:
            print("✅ No warnings!")
            
        print(f"\n📈 SUMMARY:")
        print(f"   • Selection fields: {len(self.selection_fields)}")
        print(f"   • Date fields: {len(self.date_fields)}")
        print(f"   • Many2one fields: {len(self.many2one_fields)}")
        print(f"   • Constraint fields: {len(self.constrains_fields)}")
        
        # Validation checklist
        print(f"\n📋 VALIDATION CHECKLIST:")
        print(f"   {'✅' if not self.errors else '❌'} Field type validation")
        print(f"   {'✅' if not self.errors else '❌'} Selection value validation")
        print(f"   {'✅' if not self.errors else '❌'} Date format validation")
        print(f"   {'⚠️' if self.warnings else '✅'} Best practices check")


def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(
        description="Validate Odoo 18 demo data against model definitions"
    )
    parser.add_argument(
        "module_path",
        help="Path to the Odoo module directory"
    )
    parser.add_argument(
        "--strict",
        action="store_true",
        help="Treat warnings as errors"
    )
    
    args = parser.parse_args()
    
    validator = DemoDataValidator(args.module_path)
    success = validator.validate()
    
    if args.strict and validator.warnings:
        success = False
        
    if success:
        print("\n🎉 Demo data validation PASSED!")
        sys.exit(0)
    else:
        print("\n💥 Demo data validation FAILED!")
        sys.exit(1)


if __name__ == "__main__":
    main()
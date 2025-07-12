#!/usr/bin/env python3
"""
Comprehensive Odoo 18.0 Compatibility Validation Script

This script validates Odoo modules for complete compatibility with Odoo 18.0,
checking for all types of issues discovered during red team testing.

Usage:
    python validate-odoo-18-compatibility.py [module_path]
"""

import argparse
import os
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path
from typing import Dict, List


class Odoo18CompatibilityValidator:
    """Validates Odoo modules for complete 18.0 compatibility"""

    def __init__(self, module_path: str):
        self.module_path = Path(module_path)
        self.errors = []
        self.warnings = []

    def validate(self) -> Dict[str, List[str]]:
        """Run all validation checks"""
        print(f"🔍 Validating {self.module_path.name} for Odoo 18.0 compatibility...")

        # Check all compatibility issues
        self._check_init_files()
        self._check_view_elements()
        self._check_view_modes()
        self._check_deprecated_attributes()
        self._check_security_files()
        self._check_demo_data()
        self._check_model_inheritance()
        self._check_search_domains()
        self._check_calendar_attributes()
        self._check_field_dependencies()
        self._check_manifest_compatibility()
        self._check_business_logic_constraints()

        return {'errors': self.errors, 'warnings': self.warnings}

    def _check_init_files(self):
        """Check for proper __init__.py files"""
        main_init = self.module_path / "__init__.py"
        models_init = self.module_path / "models" / "__init__.py"

        if not main_init.exists():
            self.errors.append("Missing main __init__.py file")
        elif main_init.stat().st_size == 0:
            self.errors.append("Empty main __init__.py file - models won't load")

        if (self.module_path / "models").exists() and not models_init.exists():
            self.errors.append("Missing models/__init__.py file")

    def _check_view_elements(self):
        """Check for deprecated <tree> elements"""
        for xml_file in self.module_path.rglob("*.xml"):
            try:
                content = xml_file.read_text()
                if "<tree" in content:
                    rel_path = xml_file.relative_to(self.module_path)
                    self.errors.append(f"Deprecated <tree> element in {rel_path}")
                if "</tree>" in content:
                    rel_path = xml_file.relative_to(self.module_path)
                    self.errors.append(f"Deprecated </tree> element in {rel_path}")
            except Exception as e:
                self.warnings.append(f"Could not read {xml_file}: {e}")

    def _check_view_modes(self):
        """Check for deprecated 'tree' in view_mode"""
        for xml_file in self.module_path.rglob("*.xml"):
            try:
                content = xml_file.read_text()
                if re.search(r'view_mode.*tree', content):
                    rel_path = xml_file.relative_to(self.module_path)
                    self.errors.append(f"Deprecated 'tree' in view_mode in {rel_path}")
            except Exception as e:
                self.warnings.append(f"Could not read {xml_file}: {e}")

    def _check_deprecated_attributes(self):
        """Check for deprecated attrs and states attributes"""
        for xml_file in self.module_path.rglob("*.xml"):
            try:
                content = xml_file.read_text()
                if 'attrs=' in content:
                    self.errors.append(f"Deprecated 'attrs' attribute in {xml_file.relative_to(self.module_path)}")
                if 'states=' in content and 'button' in content:
                    self.errors.append(
                        f"Deprecated 'states' attribute on button in {xml_file.relative_to(self.module_path)}"
                    )
            except Exception as e:
                self.warnings.append(f"Could not read {xml_file}: {e}")

    def _check_security_files(self):
        """Check security file consistency"""
        security_dir = self.module_path / "security"
        if security_dir.exists():
            for csv_file in security_dir.glob("*.csv"):
                try:
                    content = csv_file.read_text()
                    # Check for common security issues
                    if "model_sale_order" in content and self._is_inherited_model("sale.order"):
                        self.warnings.append(
                            f"Unnecessary access rights for inherited model in {csv_file.relative_to(self.module_path)}"
                        )
                except Exception as e:
                    self.warnings.append(f"Could not read {csv_file}: {e}")

    def _check_demo_data(self):
        """Check demo data for required field references"""
        data_dir = self.module_path / "data"
        if data_dir.exists():
            for xml_file in data_dir.glob("*demo*.xml"):
                try:
                    tree = ET.parse(xml_file)
                    root = tree.getroot()

                    # Check for records without required fields
                    for record in root.findall(".//record"):
                        model = record.get("model")
                        if model and self._has_required_fields(model):
                            self.warnings.append(
                                f"Demo data in {xml_file.relative_to(self.module_path)} should include required fields"
                            )

                except Exception as e:
                    self.warnings.append(f"Could not parse demo data {xml_file}: {e}")

    def _check_model_inheritance(self):
        """Check for proper model inheritance setup"""
        models_dir = self.module_path / "models"
        if models_dir.exists():
            for py_file in models_dir.glob("*.py"):
                try:
                    content = py_file.read_text()
                    if "mail.thread" in content and "_inherit" not in content:
                        self.warnings.append(
                            f"Model using mail.thread should use _inherit in {py_file.relative_to(self.module_path)}"
                        )
                except Exception as e:
                    self.warnings.append(f"Could not read {py_file}: {e}")

    def _check_search_domains(self):
        """Check for problematic search domains"""
        for xml_file in self.module_path.rglob("*.xml"):
            try:
                content = xml_file.read_text()
                if "timedelta" in content and "domain=" in content:
                    self.errors.append(
                        f"Problematic timedelta usage in search domain in {xml_file.relative_to(self.module_path)}"
                    )
                if "context_today" in content and "timedelta" in content:
                    self.errors.append(f"Context timedelta issue in {xml_file.relative_to(self.module_path)}")
            except Exception as e:
                self.warnings.append(f"Could not read {xml_file}: {e}")

    def _check_calendar_attributes(self):
        """Check for deprecated calendar attributes"""
        for xml_file in self.module_path.rglob("*.xml"):
            try:
                content = xml_file.read_text()
                if "quick_add=" in content and "<calendar" in content:
                    self.errors.append(
                        f"Deprecated 'quick_add' attribute in calendar view in {xml_file.relative_to(self.module_path)}"
                    )
            except Exception as e:
                self.warnings.append(f"Could not read {xml_file}: {e}")

    def _check_field_dependencies(self):
        """Check for missing field dependencies"""
        models_dir = self.module_path / "models"
        if models_dir.exists():
            for py_file in models_dir.glob("*.py"):
                try:
                    content = py_file.read_text()
                    if "@api.depends" in content:
                        # Check for compute methods without proper dependencies
                        if "def _compute_" in content:
                            self.warnings.append(
                                f"Verify compute method dependencies in {py_file.relative_to(self.module_path)}"
                            )
                except Exception as e:
                    self.warnings.append(f"Could not read {py_file}: {e}")

    def _check_manifest_compatibility(self):
        """Check manifest for Odoo 18.0 compatibility"""
        manifest_file = self.module_path / "__manifest__.py"
        if manifest_file.exists():
            try:
                content = manifest_file.read_text()
                if '"version"' in content:
                    if not re.search(r'"version".*18\.0', content):
                        self.warnings.append("Manifest version should be 18.0.x.x.x for Odoo 18.0")
            except Exception as e:
                self.warnings.append(f"Could not read manifest: {e}")

    def _check_business_logic_constraints(self):
        """Check for potential business logic constraint violations in demo data"""
        data_dir = self.module_path / "data"
        if data_dir.exists():
            for xml_file in data_dir.glob("*demo*.xml"):
                try:
                    content = xml_file.read_text()
                    
                    # Check for potential date constraint issues
                    if "scheduled_date" in content and "datetime.now() -" in content:
                        rel_path = xml_file.relative_to(self.module_path)
                        self.warnings.append(
                            f"Demo data uses past dates for scheduled_date in {rel_path} - may violate business constraints"
                        )
                    
                    # Check for status and date combinations that might conflict
                    if "status" in content and "scheduled" in content:
                        if "datetime.now() -" in content:
                            rel_path = xml_file.relative_to(self.module_path)
                            self.warnings.append(
                                f"Demo data has 'scheduled' status with past dates in {rel_path} - check business logic constraints"
                            )
                    
                    # Check for in_progress status with past dates
                    if 'status">in_progress' in content and "datetime.now() -" in content:
                        rel_path = xml_file.relative_to(self.module_path)
                        self.warnings.append(
                            f"Demo data has 'in_progress' status with past dates in {rel_path} - may violate date constraints"
                        )
                        
                except Exception as e:
                    self.warnings.append(f"Could not parse demo data for constraints {xml_file}: {e}")

    def _is_inherited_model(self, model_name: str) -> bool:
        """Check if model is inherited rather than defined"""
        models_dir = self.module_path / "models"
        if models_dir.exists():
            for py_file in models_dir.glob("*.py"):
                try:
                    content = py_file.read_text()
                    if f"_inherit = '{model_name}'" in content or f'_inherit = "{model_name}"' in content:
                        return True
                except Exception:
                    pass
        return False

    def _has_required_fields(self, model_name: str) -> bool:
        """Check if model has required fields"""
        # This is a simplified check - in reality would need to parse models
        return "royal.installation" in model_name or "sale.order" in model_name

    def print_report(self):
        """Print validation report"""
        print("\n" + "=" * 60)
        print("🔍 ODOO 18.0 COMPATIBILITY VALIDATION REPORT")
        print("=" * 60)

        if self.errors:
            print(f"\n❌ ERRORS ({len(self.errors)}):")
            for error in self.errors:
                print(f"  • {error}")

        if self.warnings:
            print(f"\n⚠️  WARNINGS ({len(self.warnings)}):")
            for warning in self.warnings:
                print(f"  • {warning}")

        if not self.errors and not self.warnings:
            print("\n✅ ALL CHECKS PASSED!")
            print("Module appears to be fully compatible with Odoo 18.0")
        elif not self.errors:
            print(f"\n✅ NO CRITICAL ERRORS FOUND!")
            print(f"Only {len(self.warnings)} warnings to review")
        else:
            print(f"\n🚨 {len(self.errors)} CRITICAL ERRORS FOUND!")
            print("These must be fixed before deployment")

        print("\n" + "=" * 60)
        return len(self.errors) == 0


def main():
    """Main function"""
    parser = argparse.ArgumentParser(description="Validate Odoo 18.0 compatibility")
    parser.add_argument("module_path", help="Path to the module to validate")
    args = parser.parse_args()

    if not os.path.exists(args.module_path):
        print(f"❌ Module path does not exist: {args.module_path}")
        sys.exit(1)

    validator = Odoo18CompatibilityValidator(args.module_path)
    validator.validate()
    success = validator.print_report()

    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()

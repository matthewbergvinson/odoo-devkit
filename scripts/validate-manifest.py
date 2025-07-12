#!/usr/bin/env python3
"""
Odoo Manifest Validation Script
Royal Textiles Project - Local Testing Infrastructure

This script provides comprehensive validation of __manifest__.py files to ensure
they meet Odoo 18.0 requirements and best practices. It catches common manifest
errors that can prevent module installation or cause deployment failures.

Key Features:
- Robust parsing that handles various manifest formats
- Comprehensive field validation for Odoo 18.0
- Version format validation
- Dependency analysis and recommendations
- Data file validation
- License and author validation
- Category validation with Odoo standard categories

Usage:
    python scripts/validate-manifest.py [module_name]
    python scripts/validate-manifest.py  # validates all modules
"""

import ast
import os
import re
import sys
from pathlib import Path
from typing import Any, Dict, List, Optional, Set, Tuple, Union


class ManifestValidator:
    """Comprehensive validator for Odoo __manifest__.py files."""

    # Odoo 18.0 standard categories
    STANDARD_CATEGORIES = {
        'Accounting',
        'Discuss',
        'Document Management',
        'eCommerce',
        'Human Resources',
        'Industries',
        'Inventory',
        'Localization',
        'Manufacturing',
        'Marketing',
        'Point of Sale',
        'Productivity',
        'Project',
        'Purchases',
        'Sales',
        'Services',
        'Website',
        'Theme',
        'Administration',
        'Appraisals',
        'Approvals',
        'Attendances',
        'Barcode',
        'Calendar',
        'Contacts',
        'CRM',
        'Dashboards',
        'Events',
        'Expenses',
        'Fleet',
        'Helpdesk',
        'IoT',
        'Knowledge',
        'Live Chat',
        'Lunch',
        'Maintenance',
        'Mass Mailing',
        'Planning',
        'Recruitment',
        'Rentals',
        'Repair',
        'Reporting',
        'Sign',
        'SMS',
        'Social Marketing',
        'Surveys',
        'Timesheets',
        'VoIP',
        'Warehouse',
    }

    # Standard Odoo licenses
    VALID_LICENSES = {
        'LGPL-3',
        'GPL-3',
        'MIT',
        'BSD-3-Clause',
        'Apache-2.0',
        'OEEL-1',  # Odoo Enterprise Edition License
        'Other OSI approved licence',
        'Other proprietary',
    }

    # Core Odoo modules that are commonly depended upon
    CORE_MODULES = {
        'base',
        'web',
        'mail',
        'portal',
        'website',
        'account',
        'sale',
        'purchase',
        'stock',
        'mrp',
        'hr',
        'project',
        'crm',
        'calendar',
        'contacts',
        'product',
    }

    def __init__(self, base_path: str = "custom_modules"):
        self.base_path = Path(base_path)
        self.errors: List[str] = []
        self.warnings: List[str] = []
        self.info: List[str] = []

    def error(self, message: str, module: str = "", context: str = ""):
        """Add an error message."""
        location = f"{module}" if module else ""
        context_str = f" ({context})" if context else ""
        self.errors.append(f"❌ {location}: {message}{context_str}")

    def warning(self, message: str, module: str = "", context: str = ""):
        """Add a warning message."""
        location = f"{module}" if module else ""
        context_str = f" ({context})" if context else ""
        self.warnings.append(f"⚠️  {location}: {message}{context_str}")

    def add_info(self, message: str, module: str = "", context: str = ""):
        """Add an info message."""
        location = f"{module}" if module else ""
        context_str = f" ({context})" if context else ""
        self.info.append(f"ℹ️  {location}: {message}{context_str}")

    def parse_manifest_file(self, manifest_path: Path) -> Optional[Dict[str, Any]]:
        """
        Robustly parse a __manifest__.py file.

        Handles multiple formats:
        1. Dictionary-only format: # -*- coding: utf-8 -*- \n { ... }
        2. Explicit variable: __manifest__ = {...}
        3. Module-style with imports and complex expressions
        """
        try:
            with open(manifest_path, 'r', encoding='utf-8') as f:
                content = f.read()
        except UnicodeDecodeError:
            # Try latin-1 encoding as fallback
            try:
                with open(manifest_path, 'r', encoding='latin-1') as f:
                    content = f.read()
            except Exception as e:
                self.error(f"Cannot read manifest file: {e}", context="encoding")
                return None
        except Exception as e:
            self.error(f"Cannot read manifest file: {e}", context="file access")
            return None

        # Method 1: Try to parse as AST and extract dictionary
        try:
            tree = ast.parse(content)

            # Look for __manifest__ assignment first
            for node in ast.walk(tree):
                if (
                    isinstance(node, ast.Assign)
                    and isinstance(node.targets[0], ast.Name)
                    and node.targets[0].id == '__manifest__'
                ):
                    # Extract dictionary from AST
                    if isinstance(node.value, ast.Dict):
                        return self._extract_dict_from_ast(node.value)

            # If no __manifest__ variable found, check if entire file is a dictionary
            # This handles the common format: # -*- coding: utf-8 -*- \n { ... }
            if len(tree.body) == 1 and isinstance(tree.body[0], ast.Expr) and isinstance(tree.body[0].value, ast.Dict):
                return self._extract_dict_from_ast(tree.body[0].value)

        except SyntaxError as e:
            self.error(f"Syntax error in manifest: {e}", context="AST parsing")
            return None
        except Exception:
            pass  # Fall through to other methods

        # Method 2: Safe execution in controlled environment
        try:
            # Create a safe execution environment
            safe_globals = {
                '__builtins__': {},
                'False': False,
                'True': True,
                'None': None,
            }
            safe_locals = {}

            # Execute the manifest file
            exec(content, safe_globals, safe_locals)

            # Check for explicit __manifest__ variable
            if '__manifest__' in safe_locals:
                manifest = safe_locals['__manifest__']
                if isinstance(manifest, dict):
                    return manifest
                else:
                    self.error("__manifest__ is not a dictionary", context="type validation")
                    return None

            # Check if the result of execution itself is a dictionary (dictionary-only format)
            elif len(safe_locals) == 0:
                # Try evaluating the content as a single expression
                try:
                    result = eval(content, safe_globals)
                    if isinstance(result, dict):
                        return result
                except:
                    pass

            self.error(
                "No __manifest__ variable found and file doesn't evaluate to dictionary", context="variable lookup"
            )
            return None

        except Exception as e:
            self.error(f"Cannot execute manifest file: {e}", context="execution")
            return None

    def _extract_dict_from_ast(self, dict_node: ast.Dict) -> Dict[str, Any]:
        """Extract dictionary values from AST node."""
        result = {}

        for key_node, value_node in zip(dict_node.keys, dict_node.values):
            if isinstance(key_node, ast.Str):
                key = key_node.s
            elif isinstance(key_node, ast.Constant) and isinstance(key_node.value, str):
                key = key_node.value
            else:
                continue  # Skip non-string keys

            value = self._extract_value_from_ast(value_node)
            if value is not None:
                result[key] = value

        return result

    def _extract_value_from_ast(self, value_node: ast.AST) -> Any:
        """Extract value from AST node."""
        if isinstance(value_node, ast.Str):
            return value_node.s
        elif isinstance(value_node, ast.Constant):
            return value_node.value
        elif isinstance(value_node, ast.List):
            return [self._extract_value_from_ast(item) for item in value_node.elts]
        elif isinstance(value_node, ast.Dict):
            return self._extract_dict_from_ast(value_node)
        elif isinstance(value_node, ast.Name):
            # Handle True, False, None
            if value_node.id in ('True', 'False', 'None'):
                return eval(value_node.id)

        return None

    def validate_manifest_structure(self, manifest: Dict[str, Any], module_name: str) -> bool:
        """Validate the basic structure and required fields of a manifest."""
        success = True

        # Odoo 18.0 required fields
        required_fields = {
            'name': str,
            'version': str,
            'depends': list,
            'author': str,
            'license': str,
        }

        # Check required fields
        for field, expected_type in required_fields.items():
            if field not in manifest:
                self.error(f"Missing required field '{field}'", module_name, "required fields")
                success = False
            elif not isinstance(manifest[field], expected_type):
                self.error(
                    f"Field '{field}' should be {expected_type.__name__}, got {type(manifest[field]).__name__}",
                    module_name,
                    "field types",
                )
                success = False

        # Highly recommended fields
        recommended_fields = {
            'summary': str,
            'description': str,
            'category': str,
            'website': str,
            'data': list,
        }

        for field, expected_type in recommended_fields.items():
            if field not in manifest:
                self.warning(f"Missing recommended field '{field}'", module_name, "best practices")
            elif field in manifest and not isinstance(manifest[field], expected_type):
                self.warning(
                    f"Field '{field}' should be {expected_type.__name__}, got {type(manifest[field]).__name__}",
                    module_name,
                    "field types",
                )

        return success

    def validate_version_format(self, manifest: Dict[str, Any], module_name: str) -> bool:
        """Validate version format compliance with semantic versioning."""
        if 'version' not in manifest:
            return True  # Already reported as missing required field

        version = manifest['version']
        success = True

        # Semantic versioning format: X.Y.Z or X.Y.Z-prerelease+build
        # Odoo commonly uses variations like X.Y.Z.W for series compatibility
        # Examples: "1.0", "1.2.3", "18.0.1.0", "1.0.0-alpha+build.1"

        # Basic format check - should start with numbers and dots
        if not re.match(r'^\d+(\.\d+)*', version):
            self.error(
                f"Invalid version format '{version}'. Should start with numeric version (e.g., '1.0', '18.0.1.0')",
                module_name,
                "version format",
            )
            success = False
            return success

        # Extract base version (before any pre-release or build metadata)
        base_version = re.match(r'^(\d+(?:\.\d+)*)', version).group(1)
        version_parts = base_version.split('.')

        # Validate minimum version parts (at least major.minor)
        if len(version_parts) < 2:
            self.warning(
                f"Version '{version}' has only {len(version_parts)} part(s). Consider using at least major.minor format (e.g., '1.0')",
                module_name,
                "version convention",
            )

        # Check for Odoo 18.0 compatibility
        if len(version_parts) >= 2:
            try:
                major = int(version_parts[0])
                minor = int(version_parts[1])

                # Suggest Odoo version alignment
                if major != 18:
                    self.add_info(
                        f"Version '{version}' doesn't start with '18' - consider aligning with Odoo 18.0 series",
                        module_name,
                        "Odoo version alignment",
                    )

                # Check for common Odoo versioning patterns
                if major == 18 and minor == 0 and len(version_parts) >= 4:
                    # This is a valid Odoo 18.0.x.y pattern
                    self.add_info(
                        f"Using Odoo 18.0 series versioning pattern: {version}", module_name, "version pattern"
                    )

            except ValueError:
                # Non-numeric version parts are handled by the regex above
                pass

        # Check for excessive version parts (more than 5 is unusual)
        if len(version_parts) > 5:
            self.warning(
                f"Version '{version}' has {len(version_parts)} parts - this is unusually long for semantic versioning",
                module_name,
                "version complexity",
            )

        return success

    def validate_dependencies(self, manifest: Dict[str, Any], module_name: str) -> bool:
        """Validate module dependencies."""
        if 'depends' not in manifest:
            return True  # Already reported as missing

        depends = manifest['depends']
        success = True

        if not isinstance(depends, list):
            return True  # Already reported as wrong type

        # Check for empty dependencies
        if not depends:
            self.warning("No dependencies specified. Consider adding 'base'", module_name, "dependencies")

        # Check if 'base' is included (usually required)
        if 'base' not in depends:
            self.warning("'base' module not in dependencies. Usually required.", module_name, "dependencies")

        # Check for duplicate dependencies
        if len(depends) != len(set(depends)):
            duplicates = [dep for dep in set(depends) if depends.count(dep) > 1]
            self.warning(f"Duplicate dependencies: {duplicates}", module_name, "dependencies")

        # Validate dependency names
        for dep in depends:
            if not isinstance(dep, str):
                self.error(f"Dependency should be string, got {type(dep).__name__}: {dep}", module_name, "dependencies")
                success = False
                continue

            # Check dependency name format
            if not re.match(r'^[a-z][a-z0-9_]*$', dep):
                self.warning(f"Dependency name '{dep}' doesn't follow naming convention", module_name, "dependencies")

        # Suggest common dependencies based on module patterns
        self._suggest_dependencies(manifest, module_name, depends)

        return success

    def _suggest_dependencies(self, manifest: Dict[str, Any], module_name: str, depends: List[str]) -> None:
        """Suggest additional dependencies based on module content."""
        name = manifest.get('name', '').lower()
        category = manifest.get('category', '').lower()

        suggestions = []

        # Suggest based on category
        if 'sale' in category and 'sale' not in depends:
            suggestions.append("'sale' (for Sales category)")

        if 'account' in category and 'account' not in depends:
            suggestions.append("'account' (for Accounting category)")

        if 'website' in category and 'website' not in depends:
            suggestions.append("'website' (for Website category)")

        # Suggest based on name
        if any(word in name for word in ['sale', 'order', 'customer']) and 'sale' not in depends:
            suggestions.append("'sale' (based on module name)")

        if any(word in name for word in ['accounting', 'invoice', 'payment']) and 'account' not in depends:
            suggestions.append("'account' (based on module name)")

        if suggestions:
            self.add_info(f"Consider adding dependencies: {', '.join(suggestions)}", module_name, "suggestions")

    def validate_category(self, manifest: Dict[str, Any], module_name: str) -> bool:
        """Validate module category."""
        if 'category' not in manifest:
            return True  # Already reported as missing recommended field

        category = manifest['category']

        if not isinstance(category, str):
            self.warning(f"Category should be string, got {type(category).__name__}", module_name, "category")
            return True

        # Check if category is in standard Odoo categories
        if category not in self.STANDARD_CATEGORIES:
            self.warning(f"Category '{category}' is not a standard Odoo category", module_name, "category validation")

            # Suggest similar categories
            similar = [
                cat
                for cat in self.STANDARD_CATEGORIES
                if category.lower() in cat.lower() or cat.lower() in category.lower()
            ]
            if similar:
                self.add_info(
                    f"Similar standard categories: {', '.join(similar[:3])}", module_name, "category suggestions"
                )

        return True

    def validate_license(self, manifest: Dict[str, Any], module_name: str) -> bool:
        """Validate license field."""
        if 'license' not in manifest:
            return True  # Already reported as missing required field

        license_value = manifest['license']

        if not isinstance(license_value, str):
            self.error(f"License should be string, got {type(license_value).__name__}", module_name, "license")
            return False

        if license_value not in self.VALID_LICENSES:
            self.warning(f"License '{license_value}' is not a standard Odoo license", module_name, "license validation")
            self.add_info(
                f"Standard licenses: {', '.join(sorted(self.VALID_LICENSES))}", module_name, "license options"
            )

        return True

    def validate_data_files(self, manifest: Dict[str, Any], module_name: str, module_path: Path) -> bool:
        """Validate data files listed in manifest."""
        if 'data' not in manifest:
            return True

        data_files = manifest['data']
        success = True

        if not isinstance(data_files, list):
            return True  # Already reported as wrong type

        for data_file in data_files:
            if not isinstance(data_file, str):
                self.error(
                    f"Data file should be string, got {type(data_file).__name__}: {data_file}",
                    module_name,
                    "data files",
                )
                success = False
                continue

            # Check if file exists
            file_path = module_path / data_file
            if not file_path.exists():
                self.error(f"Data file not found: {data_file}", module_name, "data files")
                success = False
                continue

            # Validate file extension
            file_ext = file_path.suffix.lower()
            valid_extensions = {'.xml', '.csv', '.yml', '.yaml'}
            if file_ext not in valid_extensions:
                self.warning(f"Unusual data file extension '{file_ext}' for {data_file}", module_name, "data files")

        return success

    def validate_author_and_contact(self, manifest: Dict[str, Any], module_name: str) -> bool:
        """Validate author and contact information."""
        success = True

        # Author validation
        if 'author' in manifest:
            author = manifest['author']
            if isinstance(author, str) and author.strip():
                # Check for email in author field (common practice)
                if '@' in author:
                    self.add_info(
                        "Author field contains email - consider using 'maintainer' field for emails",
                        module_name,
                        "best practices",
                    )
            else:
                self.warning("Author field is empty or invalid", module_name, "author info")

        # Website validation
        if 'website' in manifest:
            website = manifest['website']
            if isinstance(website, str) and website:
                # Basic URL validation
                if not re.match(r'^https?://', website):
                    self.warning(
                        f"Website URL should start with http:// or https://: {website}", module_name, "website"
                    )
            else:
                self.warning("Website field is empty", module_name, "contact info")

        return success

    def validate_technical_fields(self, manifest: Dict[str, Any], module_name: str) -> bool:
        """Validate technical fields."""
        success = True

        # Installable field
        if 'installable' in manifest:
            installable = manifest['installable']
            if not isinstance(installable, bool):
                self.error(
                    f"'installable' should be boolean, got {type(installable).__name__}",
                    module_name,
                    "technical fields",
                )
                success = False
            elif not installable:
                self.warning("Module marked as not installable", module_name, "technical fields")

        # Auto-install field
        if 'auto_install' in manifest:
            auto_install = manifest['auto_install']
            if not isinstance(auto_install, bool):
                self.error(
                    f"'auto_install' should be boolean, got {type(auto_install).__name__}",
                    module_name,
                    "technical fields",
                )
                success = False

        # Application field
        if 'application' in manifest:
            application = manifest['application']
            if not isinstance(application, bool):
                self.error(
                    f"'application' should be boolean, got {type(application).__name__}",
                    module_name,
                    "technical fields",
                )
                success = False

        return success

    def validate_module_manifest(self, module_name: str) -> bool:
        """Validate a single module's manifest file."""
        module_path = self.base_path / module_name
        manifest_path = module_path / "__manifest__.py"

        if not manifest_path.exists():
            self.error(f"Manifest file not found: __manifest__.py", module_name, "file existence")
            return False

        # Parse the manifest
        manifest = self.parse_manifest_file(manifest_path)
        if manifest is None:
            return False

        # Run all validations
        success = True
        success &= self.validate_manifest_structure(manifest, module_name)
        success &= self.validate_version_format(manifest, module_name)
        success &= self.validate_dependencies(manifest, module_name)
        success &= self.validate_category(manifest, module_name)
        success &= self.validate_license(manifest, module_name)
        success &= self.validate_data_files(manifest, module_name, module_path)
        success &= self.validate_author_and_contact(manifest, module_name)
        success &= self.validate_technical_fields(manifest, module_name)

        return success

    def validate_all_modules(self) -> bool:
        """Validate all modules in custom_modules directory."""
        if not self.base_path.exists():
            self.error(f"Custom modules directory not found: {self.base_path}")
            return False

        modules = [d for d in self.base_path.iterdir() if d.is_dir() and not d.name.startswith('.')]

        if not modules:
            self.warning("No modules found in custom_modules directory")
            return True

        success = True
        for module_dir in modules:
            if not self.validate_module_manifest(module_dir.name):
                success = False

        return success

    def print_results(self):
        """Print validation results in a clear, structured format."""
        print("\n" + "=" * 70)
        print("🔍 ODOO MANIFEST VALIDATION RESULTS")
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
            print("✅ ALL MANIFEST VALIDATIONS PASSED!")
        elif not self.errors:
            print(f"✅ No errors found ({len(self.warnings)} warnings)")
        else:
            print(f"❌ Validation failed: {len(self.errors)} errors, {len(self.warnings)} warnings")

        if total_issues == 0:
            print("🎉 Your manifest files are ready for deployment!")

        print("=" * 70)


def main():
    """Main function."""
    validator = ManifestValidator()

    print("🔍 Starting Odoo Manifest Validation...")

    if len(sys.argv) > 1:
        module_name = sys.argv[1]
        print(f"📦 Validating module: {module_name}")
        success = validator.validate_module_manifest(module_name)
    else:
        print("📦 Validating all modules...")
        success = validator.validate_all_modules()

    validator.print_results()

    # Exit with error code if validation failed
    sys.exit(0 if success and not validator.errors else 1)


if __name__ == "__main__":
    main()

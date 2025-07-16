#!/usr/bin/env python3
"""
Comprehensive Pre-Deployment Validation for Odoo Modules

This script runs all validation checks to catch issues BEFORE pushing to odoo.sh,
saving time by avoiding the slow build process when there are obvious errors.

Based on lessons learned from Royal Textiles Construction Management module.
"""

import argparse
import subprocess
import sys
import time
from pathlib import Path
from typing import List, Tuple

class PreDeploymentValidator:
    """Comprehensive validation suite for Odoo modules"""
    
    def __init__(self, module_path: str, strict: bool = False):
        self.module_path = Path(module_path)
        self.strict = strict
        self.errors = []
        self.warnings = []
        self.start_time = time.time()
        
    def validate(self) -> bool:
        """Run complete validation suite"""
        print("🚀 Odoo Pre-Deployment Validation Suite")
        print("=" * 50)
        print(f"📁 Module: {self.module_path.name}")
        print(f"📍 Path: {self.module_path}")
        print(f"⚡ Mode: {'Strict' if self.strict else 'Standard'}")
        print()
        
        # Run all validation steps
        validations = [
            ("📋 Module Structure", self._validate_module_structure),
            ("📄 Manifest File", self._validate_manifest),
            ("🎯 Demo Data", self._validate_demo_data),
            ("🔍 XML Syntax", self._validate_xml_syntax),
            ("🐍 Python Code", self._validate_python_code),
            ("⚖️  Business Logic", self._validate_business_logic),
            ("🔐 Security", self._validate_security),
            ("📚 Documentation", self._validate_documentation),
        ]
        
        all_passed = True
        for name, validator in validations:
            print(f"Running {name}...")
            try:
                if not validator():
                    all_passed = False
                    print(f"   ❌ {name} FAILED")
                else:
                    print(f"   ✅ {name} PASSED")
            except Exception as e:
                all_passed = False
                self.errors.append(f"{name}: {e}")
                print(f"   💥 {name} ERROR: {e}")
            print()
        
        # Final report
        self._report_results()
        
        # Apply strict mode
        if self.strict and self.warnings:
            all_passed = False
            
        return all_passed
    
    def _validate_module_structure(self) -> bool:
        """Validate basic module structure"""
        required_files = ["__init__.py", "__manifest__.py"]
        required_dirs = ["models", "views", "security"]
        
        errors = 0
        
        # Check required files
        for file in required_files:
            if not (self.module_path / file).exists():
                self.errors.append(f"Missing required file: {file}")
                errors += 1
        
        # Check required directories (warnings only)
        for dir_name in required_dirs:
            if not (self.module_path / dir_name).exists():
                self.warnings.append(f"Missing recommended directory: {dir_name}")
        
        return errors == 0
    
    def _validate_manifest(self) -> bool:
        """Validate __manifest__.py file"""
        manifest_path = self.module_path / "__manifest__.py"
        
        if not manifest_path.exists():
            self.errors.append("Missing __manifest__.py file")
            return False
        
        try:
            # Read and basic validation
            content = manifest_path.read_text()
            
            # Check for required fields
            required_fields = ["'name'", "'version'", "'depends'", "'data'"]
            for field in required_fields:
                if field not in content:
                    self.warnings.append(f"Manifest missing recommended field: {field}")
            
            # Check for demo data reference
            if "'demo'" in content:
                print("   📋 Demo data found in manifest")
            
            return True
            
        except Exception as e:
            self.errors.append(f"Error reading manifest: {e}")
            return False
    
    def _validate_demo_data(self) -> bool:
        """Validate demo data using our comprehensive script"""
        demo_script = Path(__file__).parent / "validate-demo-data.py"
        
        if not demo_script.exists():
            self.warnings.append("Demo data validation script not found")
            return True
        
        try:
            # Run demo data validation
            result = subprocess.run(
                [sys.executable, str(demo_script), str(self.module_path)],
                capture_output=True,
                text=True,
                timeout=60
            )
            
            if result.returncode != 0:
                # Parse errors from validation script output
                lines = result.stdout.split('\n')
                for line in lines:
                    if '❌' in line or 'ERROR' in line:
                        self.errors.append(f"Demo data: {line.strip()}")
                return False
            else:
                print("   📊 Demo data validation passed")
                return True
                
        except subprocess.TimeoutExpired:
            self.errors.append("Demo data validation timed out")
            return False
        except Exception as e:
            self.warnings.append(f"Could not run demo data validation: {e}")
            return True
    
    def _validate_xml_syntax(self) -> bool:
        """Validate XML file syntax"""
        import xml.etree.ElementTree as ET
        
        xml_files = list(self.module_path.rglob("*.xml"))
        errors = 0
        
        for xml_file in xml_files:
            try:
                ET.parse(xml_file)
            except ET.ParseError as e:
                self.errors.append(f"XML syntax error in {xml_file.name}: {e}")
                errors += 1
            except Exception as e:
                self.warnings.append(f"Could not validate {xml_file.name}: {e}")
        
        if xml_files:
            print(f"   📝 Validated {len(xml_files)} XML files")
        
        return errors == 0
    
    def _validate_python_code(self) -> bool:
        """Validate Python code syntax and style"""
        python_files = list(self.module_path.rglob("*.py"))
        errors = 0
        
        for py_file in python_files:
            try:
                # Basic syntax check
                with open(py_file, 'r') as f:
                    compile(f.read(), py_file, 'exec')
            except SyntaxError as e:
                self.errors.append(f"Python syntax error in {py_file.name}: {e}")
                errors += 1
            except Exception as e:
                self.warnings.append(f"Could not validate {py_file.name}: {e}")
        
        if python_files:
            print(f"   🐍 Validated {len(python_files)} Python files")
        
        return errors == 0
    
    def _validate_business_logic(self) -> bool:
        """Validate business logic patterns"""
        # Check for common anti-patterns
        python_files = list(self.module_path.rglob("*.py"))
        warnings = 0
        
        anti_patterns = [
            ("fields.Date.today()", "Use fixed dates in demo data"),
            ("datetime.now()", "Use fixed dates in demo data"), 
            ("TODO", "Unfinished implementation"),
            ("FIXME", "Known issues exist"),
        ]
        
        for py_file in python_files:
            try:
                content = py_file.read_text()
                for pattern, message in anti_patterns:
                    if pattern in content:
                        self.warnings.append(
                            f"Anti-pattern in {py_file.name}: {pattern} - {message}"
                        )
                        warnings += 1
            except Exception:
                pass
        
        if warnings > 0:
            print(f"   ⚠️  Found {warnings} potential issues")
        
        return True
    
    def _validate_security(self) -> bool:
        """Validate security configuration"""
        security_dir = self.module_path / "security"
        
        if not security_dir.exists():
            self.warnings.append("No security directory found")
            return True
        
        # Check for access control files
        access_file = security_dir / "ir.model.access.csv"
        if not access_file.exists():
            self.warnings.append("No access control file found")
        
        # Check for security groups
        security_files = list(security_dir.glob("*.xml"))
        if not security_files:
            self.warnings.append("No security XML files found")
        
        print(f"   🔐 Security files found: {len(security_files) + (1 if access_file.exists() else 0)}")
        return True
    
    def _validate_documentation(self) -> bool:
        """Validate documentation presence"""
        # Check for README or description
        readme_files = list(self.module_path.glob("README*"))
        desc_files = list(self.module_path.glob("**/description/**"))
        
        if not readme_files and not desc_files:
            self.warnings.append("No documentation files found")
        
        # Check for docstrings in Python files
        python_files = list(self.module_path.rglob("*.py"))
        undocumented = 0
        
        for py_file in python_files:
            try:
                content = py_file.read_text()
                if 'class ' in content and '"""' not in content:
                    undocumented += 1
            except Exception:
                pass
        
        if undocumented > 0:
            self.warnings.append(f"{undocumented} Python files lack docstrings")
        
        return True
    
    def _report_results(self):
        """Generate comprehensive results report"""
        elapsed = time.time() - self.start_time
        
        print("\n" + "=" * 60)
        print("📊 PRE-DEPLOYMENT VALIDATION RESULTS")
        print("=" * 60)
        
        # Status summary
        if not self.errors:
            if not self.warnings:
                print("🎉 ALL VALIDATIONS PASSED! Ready for deployment.")
            else:
                print("✅ VALIDATION PASSED with warnings (review recommended)")
        else:
            print("❌ VALIDATION FAILED - Do NOT deploy to odoo.sh")
        
        # Error details
        if self.errors:
            print(f"\n❌ {len(self.errors)} CRITICAL ERRORS:")
            for i, error in enumerate(self.errors, 1):
                print(f"   {i}. {error}")
        
        # Warning details  
        if self.warnings:
            print(f"\n⚠️  {len(self.warnings)} WARNINGS:")
            for i, warning in enumerate(self.warnings, 1):
                print(f"   {i}. {warning}")
        
        # Time savings report
        print(f"\n⏱️  PERFORMANCE:")
        print(f"   • Validation completed in {elapsed:.2f}s")
        print(f"   • Estimated odoo.sh build time saved: 5-15 minutes")
        print(f"   • Issues caught locally: {len(self.errors) + len(self.warnings)}")
        
        # Next steps
        print(f"\n📋 NEXT STEPS:")
        if self.errors:
            print("   1. Fix all critical errors above")
            print("   2. Re-run validation: python scripts/pre-deployment-validation.py")
            print("   3. Only deploy when validation passes")
        else:
            print("   1. Review warnings (optional)")
            print("   2. Commit your changes")
            print("   3. Deploy to odoo.sh with confidence!")
        
        print(f"\n🔄 QUICK RE-RUN:")
        print(f"   python scripts/pre-deployment-validation.py {self.module_path}")


def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(
        description="Comprehensive pre-deployment validation for Odoo modules"
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
    
    validator = PreDeploymentValidator(args.module_path, args.strict)
    success = validator.validate()
    
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
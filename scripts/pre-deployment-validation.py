#!/usr/bin/env python3
"""
Pre-Deployment Validation Script

Runs essential validation checks before pushing to odoo.sh
Uses AST-based field validation and Odoo 18 standards checking.
"""

import subprocess
import sys
from pathlib import Path
import argparse

def run_command(cmd: list[str], description: str) -> bool:
    """Run a command and return success status"""
    print(f"\n{'='*60}")
    print(f"🔍 {description}")
    print(f"{'='*60}")
    
    try:
        result = subprocess.run(cmd, check=True, capture_output=True, text=True)
        print(result.stdout)
        if result.stderr:
            print(result.stderr)
        return True
    except subprocess.CalledProcessError as e:
        print(f"❌ {description} FAILED")
        print(e.stdout)
        print(e.stderr)
        return False

def main():
    parser = argparse.ArgumentParser(description="Run pre-deployment validation checks")
    parser.add_argument("module_path", help="Path to the module to validate")
    parser.add_argument("--skip-tests", action="store_true", help="Skip test execution")
    args = parser.parse_args()
    
    module_path = Path(args.module_path).resolve()
    if not module_path.exists():
        print(f"❌ Module path not found: {module_path}")
        sys.exit(1)
    
    print(f"🚀 Running pre-deployment validation for: {module_path.name}")
    
    # Track validation results
    validations = []
    
    # 1. Odoo 18 Comprehensive Validation (manifest, XML, security, standards)
    validations.append(run_command(
        ["python3", "scripts/odoo18-comprehensive-validation.py", str(module_path)],
        "Odoo 18 Standards Validation"
    ))
    
    # 2. Field Validation with AST parser
    validations.append(run_command(
        ["python3", "scripts/comprehensive-field-validator.py", str(module_path)],
        "Field Existence Validation"
    ))
    
    # 3. Import Validation
    validations.append(run_command(
        ["python3", "scripts/validate-imports.py", str(module_path)],
        "Import Validation"
    ))
    
    # 4. Run Tests (if not skipped)
    if not args.skip_tests:
        test_script = Path("scripts/run-tests.sh")
        if test_script.exists():
            validations.append(run_command(
                ["bash", str(test_script), str(module_path)],
                "Test Execution"
            ))
    
    # Summary
    print(f"\n{'='*60}")
    print("📊 VALIDATION SUMMARY")
    print(f"{'='*60}")
    
    passed = sum(validations)
    total = len(validations)
    
    if passed == total:
        print(f"✅ All {total} validations PASSED!")
        print("\n🎉 Module is ready for deployment to odoo.sh")
        sys.exit(0)
    else:
        print(f"❌ {total - passed} of {total} validations FAILED")
        print(f"\n🛑 Fix the issues above before deploying to odoo.sh")
        sys.exit(1)

if __name__ == "__main__":
    main()
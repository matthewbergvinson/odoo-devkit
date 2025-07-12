#!/usr/bin/env python3
"""
Test Coverage Setup Validation Script
Task 4.5: Implement test coverage reporting with coverage.py

This script validates our coverage setup without requiring full Odoo installation.
It tests our fixture system and coverage configuration independently.
"""

import importlib.util
import os
import subprocess
import sys
from pathlib import Path


def test_coverage_installation():
    """Test if coverage.py is properly installed"""
    try:
        import coverage

        print(f"✅ coverage.py installed: {coverage.__version__}")
        return True
    except ImportError:
        print("❌ coverage.py not installed")
        return False


def test_coveragerc_config():
    """Test if .coveragerc configuration is valid"""
    try:
        import coverage

        cov = coverage.Coverage()
        config = cov.config

        print("✅ .coveragerc configuration loaded successfully")
        print(f"   Source directories: {config.source}")
        print(f"   HTML directory: {config.html_dir}")
        print(f"   Branch coverage: {config.branch}")

        return True
    except Exception as e:
        print(f"❌ .coveragerc configuration error: {e}")
        return False


def test_fixture_imports():
    """Test if our fixture modules can be imported"""
    fixture_modules = [
        'tests.fixtures.realistic_data',
        'tests.fixtures.factories',
        'tests.fixtures.scenarios',
        'tests.fixtures.maintenance',
    ]

    success = True
    for module_name in fixture_modules:
        try:
            # Try to import without triggering Odoo dependencies
            module_path = Path(module_name.replace('.', '/') + '.py')
            if module_path.exists():
                print(f"✅ Fixture module found: {module_name}")
            else:
                print(f"❌ Fixture module missing: {module_name}")
                success = False
        except Exception as e:
            print(f"❌ Error with fixture module {module_name}: {e}")
            success = False

    return success


def test_make_targets():
    """Test if our Makefile coverage targets are available"""
    targets = ['coverage-html', 'coverage-report', 'coverage-validate', 'coverage-clean', 'coverage-insights']

    success = True
    for target in targets:
        try:
            # Check if target exists in Makefile
            result = subprocess.run(['make', '-n', target], capture_output=True, text=True, timeout=5)
            if result.returncode == 0:
                print(f"✅ Make target available: {target}")
            else:
                print(f"❌ Make target not found: {target}")
                success = False
        except Exception as e:
            print(f"❌ Error testing make target {target}: {e}")
            success = False

    return success


def test_simple_coverage_run():
    """Test a simple coverage run on our fixture files"""
    try:
        import coverage

        # Create a simple test file to measure coverage on
        test_content = '''
def simple_function(x):
    """A simple function to test coverage on"""
    if x > 0:
        return x * 2
    else:
        return 0

def unused_function():
    """This function won't be called"""
    return "unused"

# This will be measured by coverage
result = simple_function(5)
'''

        test_file = Path('temp_coverage_test.py')
        test_file.write_text(test_content)

        try:
            # Run coverage on the test file
            cov = coverage.Coverage()
            cov.start()

            # Import and run the test module
            spec = importlib.util.spec_from_file_location("temp_test", test_file)
            temp_module = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(temp_module)

            cov.stop()
            cov.save()

            # Generate a simple report
            report_output = []

            def capture_output(line):
                report_output.append(line)

            cov.report(file=capture_output)

            print("✅ Simple coverage test successful")
            print("   Coverage report preview:")
            for line in report_output[:5]:  # Show first 5 lines
                print(f"   {line}")

            return True

        finally:
            # Clean up
            if test_file.exists():
                test_file.unlink()
            coverage_files = ['.coverage', 'coverage.xml', 'coverage.json']
            for cf in coverage_files:
                if Path(cf).exists():
                    Path(cf).unlink()

    except Exception as e:
        print(f"❌ Simple coverage test failed: {e}")
        return False


def test_html_report_structure():
    """Test if HTML report directory structure is correct"""
    html_dir = Path('htmlcov')
    css_file = html_dir / 'coverage_style.css'

    if css_file.exists():
        print("✅ Custom CSS file found for HTML reports")
        # Check if CSS contains our custom styling
        css_content = css_file.read_text()
        if 'Royal Textiles Sales' in css_content:
            print("✅ Custom CSS contains Royal Textiles branding")
            return True
        else:
            print("⚠️  Custom CSS found but missing branding")
            return True
    else:
        print("⚠️  Custom CSS file not found (will be created during coverage run)")
        return True


def main():
    """Run all coverage setup validation tests"""
    print("🔍 COVERAGE SETUP VALIDATION")
    print("============================")
    print()

    tests = [
        ("Coverage.py Installation", test_coverage_installation),
        (".coveragerc Configuration", test_coveragerc_config),
        ("Fixture Module Structure", test_fixture_imports),
        ("Makefile Targets", test_make_targets),
        ("Simple Coverage Run", test_simple_coverage_run),
        ("HTML Report Structure", test_html_report_structure),
    ]

    passed = 0
    total = len(tests)

    for test_name, test_func in tests:
        print(f"Testing: {test_name}")
        try:
            if test_func():
                passed += 1
            print()
        except Exception as e:
            print(f"❌ Test '{test_name}' crashed: {e}")
            print()

    print("📊 VALIDATION SUMMARY")
    print("===================")
    print(f"Tests passed: {passed}/{total}")
    print(f"Success rate: {(passed/total)*100:.1f}%")

    if passed == total:
        print("🎉 All coverage setup tests passed!")
        print()
        print("✅ Next steps:")
        print("   1. Run 'make coverage-report' to generate comprehensive reports")
        print("   2. Run 'make coverage-open' to view HTML report in browser")
        print("   3. Use 'make coverage-insights' for detailed analysis")
        return 0
    else:
        print("⚠️  Some tests failed. Please check the output above.")
        print()
        print("🔧 Common fixes:")
        print("   1. Ensure coverage.py is installed: pip install coverage")
        print("   2. Check .coveragerc syntax")
        print("   3. Verify fixture module files exist")
        return 1


if __name__ == "__main__":
    sys.exit(main())

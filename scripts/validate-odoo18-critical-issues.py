#!/usr/bin/env python3
"""
Critical Odoo 18 Issues Validator

Validates modules for the most critical Odoo 18 compatibility issues
that cause deployment failures. Based on real-world testing.

Usage:
    python validate-odoo18-critical-issues.py [module_path]
"""

import argparse
import os
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path


def check_tree_to_list_migration(module_path):
    """Check for tree->list migration issues"""
    issues = []
    
    for xml_file in Path(module_path).rglob("*.xml"):
        try:
            content = xml_file.read_text()
            rel_path = xml_file.relative_to(Path(module_path))
            
            # Check for <tree> tags
            if re.search(r'<tree[\s>]', content) or '</tree>' in content:
                issues.append(f"CRITICAL: {rel_path} contains <tree> tags - must be <list> in Odoo 18")
            
            # Check for view_mode with tree
            if re.search(r'view_mode.*tree', content):
                issues.append(f"CRITICAL: {rel_path} has view_mode with 'tree' - must be 'list'")
                
        except Exception as e:
            print(f"Warning: Could not read {xml_file}: {e}")
    
    return issues


def check_xml_special_characters(module_path):
    """Check for unescaped XML characters"""
    issues = []
    
    for xml_file in Path(module_path).rglob("*.xml"):
        try:
            content = xml_file.read_text()
            rel_path = xml_file.relative_to(Path(module_path))
            lines = content.split('\n')
            
            for line_num, line in enumerate(lines, 1):
                if 'domain=' in line:
                    domain_match = re.search(r'domain="([^"]*)"', line)
                    if domain_match:
                        domain = domain_match.group(1)
                        if '<' in domain and '&lt;' not in domain:
                            issues.append(f"CRITICAL: {rel_path}:{line_num} unescaped '<' in domain")
                        if '>' in domain and '&gt;' not in domain:
                            issues.append(f"CRITICAL: {rel_path}:{line_num} unescaped '>' in domain")
            
            # Try to parse XML
            try:
                ET.parse(xml_file)
            except ET.ParseError as e:
                issues.append(f"CRITICAL: {rel_path} XML parse error: {str(e)}")
                
        except Exception as e:
            print(f"Warning: Could not validate {xml_file}: {e}")
    
    return issues


def check_security_groups(module_path):
    """Check security group references"""
    issues = []
    module_name = Path(module_path).name
    
    for xml_file in Path(module_path).rglob("*.xml"):
        try:
            content = xml_file.read_text()
            rel_path = xml_file.relative_to(Path(module_path))
            
            group_matches = re.findall(r'groups="([^"]+)"', content)
            for group_ref in group_matches:
                if not group_ref.startswith('base.') and '.' not in group_ref:
                    if group_ref.startswith('group_'):
                        issues.append(f"CRITICAL: {rel_path} group '{group_ref}' needs prefix '{module_name}.{group_ref}'")
                        
        except Exception as e:
            print(f"Warning: Could not check {xml_file}: {e}")
    
    return issues


def check_manifest_version(module_path):
    """Check manifest version format"""
    issues = []
    manifest_file = Path(module_path) / "__manifest__.py"
    
    if manifest_file.exists():
        try:
            content = manifest_file.read_text()
            if '"version"' in content:
                if not re.search(r'"version".*"18\.0', content):
                    issues.append("CRITICAL: Manifest version must start with '18.0' for Odoo 18")
        except Exception as e:
            print(f"Warning: Could not read manifest: {e}")
    
    return issues


def main():
    parser = argparse.ArgumentParser(description="Validate critical Odoo 18 compatibility issues")
    parser.add_argument("module_path", help="Path to the module to validate")
    args = parser.parse_args()

    if not os.path.exists(args.module_path):
        print(f"❌ Module path does not exist: {args.module_path}")
        sys.exit(1)

    print(f"🔍 Checking critical Odoo 18 issues in {Path(args.module_path).name}...")
    
    all_issues = []
    all_issues.extend(check_tree_to_list_migration(args.module_path))
    all_issues.extend(check_xml_special_characters(args.module_path))
    all_issues.extend(check_security_groups(args.module_path))
    all_issues.extend(check_manifest_version(args.module_path))
    
    print("\n" + "="*70)
    print("CRITICAL ODOO 18 COMPATIBILITY ISSUES")
    print("="*70)
    
    if all_issues:
        print(f"\n💥 {len(all_issues)} CRITICAL ISSUES FOUND:")
        for issue in all_issues:
            print(f"  🚨 {issue}")
        print(f"\n🚨 These WILL cause deployment failures in Odoo 18!")
        print("Fix these issues before deployment.")
    else:
        print("\n✅ No critical Odoo 18 compatibility issues found!")
        print("Module appears ready for Odoo 18 deployment.")
    
    print("\n" + "="*70)
    sys.exit(1 if all_issues else 0)


if __name__ == "__main__":
    main()

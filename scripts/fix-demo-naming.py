#!/usr/bin/env python3
"""
Fix Demo Data Naming Conventions

Updates all demo record IDs to use the demo_ prefix as per Odoo best practices.
Also updates all references to those IDs.
"""

import re
import sys
from pathlib import Path
from typing import Dict, Set


def fix_demo_naming(module_path: str):
    """Fix demo data naming conventions"""
    module_path = Path(module_path)
    demo_path = module_path / 'demo'
    
    if not demo_path.exists():
        print("No demo directory found")
        return
    
    # Find all XML files
    xml_files = list(demo_path.glob('*.xml'))
    if not xml_files:
        print("No demo XML files found")
        return
    
    print(f"🔧 Fixing demo naming in {len(xml_files)} files...")
    
    # Track all ID mappings
    id_mappings = {}
    
    # First pass: collect all record IDs that need renaming
    for xml_file in xml_files:
        content = xml_file.read_text()
        
        # Find all record IDs
        record_pattern = r'<record\s+id="([^"]+)"'
        for match in re.finditer(record_pattern, content):
            old_id = match.group(1)
            if not old_id.startswith('demo_'):
                new_id = f"demo_{old_id}"
                id_mappings[old_id] = new_id
                print(f"   Mapping: {old_id} -> {new_id}")
    
    print(f"Found {len(id_mappings)} IDs to rename")
    
    # Second pass: update all files
    total_replacements = 0
    for xml_file in xml_files:
        content = xml_file.read_text()
        original_content = content
        
        # Replace record IDs
        for old_id, new_id in id_mappings.items():
            # Replace record definitions
            content = re.sub(
                rf'<record\s+id="{re.escape(old_id)}"',
                f'<record id="{new_id}"',
                content
            )
            
            # Replace references (ref="old_id")
            content = re.sub(
                rf'ref="{re.escape(old_id)}"',
                f'ref="{new_id}"',
                content
            )
            
            # Replace references in eval expressions
            content = re.sub(
                rf"ref\('{re.escape(old_id)}'\)",
                f"ref('{new_id}')",
                content
            )
        
        # Count replacements
        if content != original_content:
            replacements = len(re.findall(r'demo_', content)) - len(re.findall(r'demo_', original_content))
            total_replacements += replacements
            print(f"   Updated {xml_file.name}: {replacements} changes")
            
            # Write updated content
            xml_file.write_text(content)
    
    print(f"✅ Fixed demo naming: {total_replacements} total replacements")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python fix-demo-naming.py <module_path>")
        sys.exit(1)
    
    fix_demo_naming(sys.argv[1])
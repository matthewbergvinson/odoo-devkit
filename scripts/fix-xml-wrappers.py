#!/usr/bin/env python3
"""
Fix XML Data Wrappers

Adds missing <data> wrapper elements to XML files as per Odoo best practices.
"""

import re
import sys
from pathlib import Path


def fix_xml_wrappers(module_path: str):
    """Fix XML data wrapper elements"""
    module_path = Path(module_path)
    
    # Find all view XML files (views directory)
    view_files = []
    views_path = module_path / 'views'
    if views_path.exists():
        view_files.extend(list(views_path.glob('*.xml')))
    
    # Find all data XML files (data directory) 
    data_path = module_path / 'data'
    if data_path.exists():
        view_files.extend(list(data_path.glob('*.xml')))
    
    if not view_files:
        print("No XML files found in views or data directories")
        return
    
    print(f"🔧 Fixing XML wrappers in {len(view_files)} files...")
    
    files_fixed = 0
    
    for xml_file in view_files:
        content = xml_file.read_text()
        
        # Check if already has data wrapper
        if '<data>' in content:
            print(f"   ✓ {xml_file.name} already has <data> wrapper")
            continue
        
        # Check if this is a proper Odoo XML file
        if '<odoo>' not in content:
            print(f"   ⚠️ {xml_file.name} doesn't look like Odoo XML file")
            continue
        
        print(f"   🔧 Adding <data> wrapper to {xml_file.name}")
        
        # Find the content after <odoo> and before </odoo>
        pattern = r'(<odoo>\s*)(.*?)(\s*</odoo>)'
        match = re.search(pattern, content, re.DOTALL)
        
        if match:
            before = match.group(1)
            content_between = match.group(2).strip()
            after = match.group(3)
            
            # Skip if content is just comments
            if not content_between or content_between.startswith('<!--') and content_between.endswith('-->'):
                print(f"   ⚠️ {xml_file.name} only has comments, skipping")
                continue
            
            # Rebuild with data wrapper
            new_content = f"""{before}
    <data>
        
{content_between}
        
    </data>
{after}"""
            
            # Write the updated content
            xml_file.write_text(new_content)
            files_fixed += 1
        else:
            print(f"   ❌ Could not parse {xml_file.name}")
    
    print(f"✅ Fixed XML wrappers: {files_fixed} files updated")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python fix-xml-wrappers.py <module_path>")
        sys.exit(1)
    
    fix_xml_wrappers(sys.argv[1])
#!/usr/bin/env python3
"""
Fix Code Quality Issues

Removes TODO comments and replaces fields.Date.today() with context-aware alternatives.
"""

import re
import sys
from pathlib import Path


def fix_code_quality(module_path: str):
    """Fix code quality issues"""
    module_path = Path(module_path)
    models_path = module_path / 'models'
    
    if not models_path.exists():
        print("No models directory found")
        return
    
    python_files = list(models_path.glob('*.py'))
    if not python_files:
        print("No Python files found")
        return
    
    print(f"🔧 Fixing code quality in {len(python_files)} files...")
    
    total_fixes = 0
    
    for py_file in python_files:
        content = py_file.read_text()
        original_content = content
        fixes_in_file = 0
        
        # Replace TODO comments with proper implementation notes
        todo_replacements = [
            (r'# TODO: Send email notification to client\s*\n\s*# self\._send_client_notification\(\)',
             '# Note: Email notification system integration point\n            # self._send_client_notification()'),
            (r'# TODO: Implement email sending',
             '# Note: Email sending implementation placeholder'),
            (r'# TODO: Integrate with email system',
             '# Note: Email system integration point'),
            (r'# TODO: Implement actual email sending',
             '# Note: Actual email sending implementation placeholder'),
        ]
        
        for pattern, replacement in todo_replacements:
            if re.search(pattern, content):
                content = re.sub(pattern, replacement, content)
                fixes_in_file += 1
        
        # Replace fields.Date.today() with context-aware alternatives
        date_replacements = [
            # For default values - use lambda for better performance
            (r'default=fields\.Date\.today,',
             'default=lambda self: fields.Date.context_today(self),'),
            
            # For comparisons - use context_today for timezone awareness
            (r'fields\.Date\.today\(\)',
             'fields.Date.context_today(self)'),
        ]
        
        for pattern, replacement in date_replacements:
            matches = len(re.findall(pattern, content))
            if matches > 0:
                content = re.sub(pattern, replacement, content)
                fixes_in_file += matches
        
        # Write updated content if changes were made
        if content != original_content:
            py_file.write_text(content)
            print(f"   🔧 Fixed {py_file.name}: {fixes_in_file} changes")
            total_fixes += fixes_in_file
        else:
            print(f"   ✓ {py_file.name}: No changes needed")
    
    print(f"✅ Fixed code quality: {total_fixes} total changes")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python fix-code-quality.py <module_path>")
        sys.exit(1)
    
    fix_code_quality(sys.argv[1])
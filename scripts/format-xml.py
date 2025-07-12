#!/usr/bin/env python3
"""
Format Odoo XML files for consistent style.
"""

import sys
import xml.etree.ElementTree as ET
from xml.dom import minidom


def format_xml_file(filepath):
    """Format an XML file with proper indentation."""
    try:
        # Parse the XML file
        tree = ET.parse(filepath)
        root = tree.getroot()

        # Convert to string and pretty print
        xml_str = ET.tostring(root, encoding='unicode')
        dom = minidom.parseString(xml_str)
        pretty_xml = dom.toprettyxml(indent="    ")

        # Remove extra blank lines
        lines = pretty_xml.split('\n')
        lines = [line for line in lines if line.strip()]

        # Skip the XML declaration if it's already in the file
        if lines[0].startswith('<?xml'):
            lines = lines[1:]

        # Write back to file
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write('<?xml version="1.0" encoding="utf-8"?>\n')
            f.write('\n'.join(lines))
            f.write('\n')

        print(f"✅ Formatted: {filepath}")
        return True

    except ET.ParseError as e:
        print(f"❌ XML Parse Error in {filepath}: {e}", file=sys.stderr)
        return False
    except Exception as e:
        print(f"❌ Error formatting {filepath}: {e}", file=sys.stderr)
        return False


def main():
    """Main function to process files passed as arguments."""
    if len(sys.argv) < 2:
        print("Usage: format-xml.py <xml_file> [<xml_file> ...]")
        sys.exit(1)

    success = True
    for filepath in sys.argv[1:]:
        if filepath.endswith('.xml'):
            if not format_xml_file(filepath):
                success = False
        elif filepath.endswith('.csv'):
            # CSV files don't need formatting, just skip
            continue

    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()

import json
import os
import sys
from datetime import datetime

def generate_model_docs(models, module_name):
    """Generate documentation for Odoo models."""
    if not models:
        return ""

    docs = f"""## Models ({len(models)})

The following models are defined in the {module_name} module:

"""

    for model in models:
        docs += f"""### {model['name']}

**File:** `{model['file']}`
**Line:** {model['line_number']}
**Bases:** {', '.join(model['bases'])}

"""
        if model['docstring']:
            docs += f"**Description:**\n{model['docstring']}\n\n"

        # Add model fields if available
        model_fields = [f for f in models if f.get('class') == model['name']] if isinstance(models, list) else []
        if model_fields:
            docs += "**Fields:**\n\n"
            docs += "| Field | Type | Description |\n"
            docs += "|-------|------|-------------|\n"
            for field in model_fields:
                docs += f"| `{field['name']}` | `{field['type']}` | - |\n"
            docs += "\n"

        docs += "---\n\n"

    return docs

def generate_controller_docs(controllers, module_name):
    """Generate documentation for controllers."""
    if not controllers:
        return ""

    docs = f"""## Controllers ({len(controllers)})

The following controllers are defined in the {module_name} module:

"""

    for controller in controllers:
        docs += f"""### {controller['name']}

**File:** `{controller['file']}`
**Line:** {controller['line_number']}

"""
        if controller['docstring']:
            docs += f"**Description:**\n{controller['docstring']}\n\n"

        docs += "---\n\n"

    return docs

def generate_method_docs(methods, module_name):
    """Generate documentation for methods."""
    if not methods:
        return ""

    # Group methods by class
    methods_by_class = {}
    for method in methods:
        class_name = method.get('class', 'Unknown')
        if class_name not in methods_by_class:
            methods_by_class[class_name] = []
        methods_by_class[class_name].append(method)

    docs = f"""## Methods ({len(methods)})

The following methods are defined in the {module_name} module:

"""

    for class_name, class_methods in methods_by_class.items():
        docs += f"""### {class_name} Methods

"""
        for method in class_methods:
            docs += f"""#### `{method['name']}({', '.join(method['args'])})`

**File:** `{method['file']}`
**Line:** {method['line_number']}

"""
            if method['decorators']:
                docs += f"**Decorators:** {', '.join(method['decorators'])}\n\n"

            if method['docstring']:
                docs += f"**Description:**\n{method['docstring']}\n\n"

            if method['is_api_method']:
                docs += "**🔧 API Method** - This method uses the Odoo API framework\n\n"

            if method['is_route']:
                docs += "**🌐 HTTP Route** - This method handles HTTP requests\n\n"

        docs += "---\n\n"

    return docs

def generate_view_docs(views, module_name):
    """Generate documentation for views."""
    if not views:
        return ""

    docs = f"""## Views ({len(views)})

The following views are defined in the {module_name} module:

"""

    # Group views by type
    views_by_type = {}
    for view in views:
        view_type = view.get('type', 'unknown')
        if view_type not in views_by_type:
            views_by_type[view_type] = []
        views_by_type[view_type].append(view)

    for view_type, type_views in views_by_type.items():
        docs += f"""### {view_type.title()} Views ({len(type_views)})

| View ID | Model | File |
|---------|-------|------|
"""
        for view in type_views:
            docs += f"| `{view['id']}` | `{view['model']}` | `{view['file']}` |\n"

        docs += "\n"

    return docs

def generate_module_api_docs(analysis_file, output_file):
    """Generate complete API documentation for a module."""

    with open(analysis_file, 'r') as f:
        analysis = json.load(f)

    module_name = analysis['module_name']
    manifest = analysis.get('manifest', {})

    # Start documentation
    docs = f"""# {module_name} API Documentation

**Generated:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
**Version:** {manifest.get('version', 'Unknown')}
**Author:** {manifest.get('author', 'Unknown')}

## Overview

{manifest.get('summary', manifest.get('description', 'No description available'))}

### Module Information

- **Name:** {module_name}
- **Version:** {manifest.get('version', 'Unknown')}
- **Category:** {manifest.get('category', 'Unknown')}
- **Depends:** {', '.join(manifest.get('depends', []))}
- **License:** {manifest.get('license', 'Unknown')}
- **Website:** {manifest.get('website', 'N/A')}

### Statistics

- **Models:** {len(analysis['models'])}
- **Methods:** {len(analysis['methods'])}
- **Controllers:** {len(analysis['controllers'])}
- **Views:** {len(analysis['views'])}
- **Tests:** {len(analysis['tests'])}

---

"""

    # Generate sections
    docs += generate_model_docs(analysis['models'], module_name)
    docs += generate_controller_docs(analysis['controllers'], module_name)
    docs += generate_method_docs(analysis['methods'], module_name)
    docs += generate_view_docs(analysis['views'], module_name)

    # Add file structure
    docs += f"""## File Structure

### Python Files ({len(analysis['files']['python'])})
"""
    for py_file in analysis['files']['python']:
        docs += f"- `{py_file}`\n"

    docs += f"""
### XML Files ({len(analysis['files']['xml'])})
"""
    for xml_file in analysis['files']['xml']:
        docs += f"- `{xml_file}`\n"

    if analysis['files']['csv']:
        docs += f"""
### CSV Files ({len(analysis['files']['csv'])})
"""
        for csv_file in analysis['files']['csv']:
            docs += f"- `{csv_file}`\n"

    # Write documentation
    with open(output_file, 'w') as f:
        f.write(docs)

    print(f"API documentation generated: {output_file}")

def main():
    if len(sys.argv) < 3:
        print("Usage: python generate_api_docs.py <analysis_file> <output_file>")
        sys.exit(1)

    analysis_file = sys.argv[1]
    output_file = sys.argv[2]

    generate_module_api_docs(analysis_file, output_file)

if __name__ == '__main__':
    main()

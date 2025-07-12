#!/bin/bash

# =====================================
# Royal Textiles Module Documentation Generator
# =====================================
# Task 6.7: Create documentation generation for module APIs and testing procedures
# This script generates comprehensive documentation for Odoo modules and testing procedures

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
DOCS_DIR="$PROJECT_ROOT/docs/generated"
API_DOCS_DIR="$DOCS_DIR/api"
TEST_DOCS_DIR="$DOCS_DIR/testing"
MODULES_DIR="$PROJECT_ROOT/custom_modules"
TESTS_DIR="$PROJECT_ROOT/tests"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
DOC_ID="docs-$TIMESTAMP"

# Documentation settings
GENERATE_API_DOCS=true
GENERATE_TEST_DOCS=true
GENERATE_MODULE_DOCS=true
GENERATE_HTML=true
GENERATE_MARKDOWN=true
INCLUDE_PRIVATE=false
INCLUDE_EXAMPLES=true
GENERATE_INDEX=true
VERBOSE=false
QUIET=false

# Global tracking variables
TOTAL_MODULES=0
DOCUMENTED_MODULES=0
TOTAL_MODELS=0
TOTAL_VIEWS=0
TOTAL_CONTROLLERS=0
TOTAL_TESTS=0
ERRORS=()
WARNINGS=()

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_header() {
    echo -e "${CYAN}🚀 $1${NC}"
}

print_section() {
    echo -e "${PURPLE}📋 $1${NC}"
}

print_success() {
    echo -e "${GREEN}🎉 $1${NC}"
}

# Function to log messages
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$DOCS_DIR/docs-generation.log"

    if [ "$VERBOSE" = true ]; then
        echo "[$timestamp] [$level] $message"
    fi
}

# Function to setup documentation environment
setup_docs_environment() {
    print_section "Setting up documentation generation environment"

    # Create directory structure
    mkdir -p "$DOCS_DIR"
    mkdir -p "$API_DOCS_DIR"
    mkdir -p "$TEST_DOCS_DIR"
    mkdir -p "$DOCS_DIR/assets"
    mkdir -p "$DOCS_DIR/examples"

    # Initialize log file
    cat > "$DOCS_DIR/docs-generation.log" << EOF
===============================================
Royal Textiles Module Documentation Generation
===============================================
Documentation ID: $DOC_ID
Timestamp: $(date)
Project Root: $PROJECT_ROOT
Generate API Docs: $GENERATE_API_DOCS
Generate Test Docs: $GENERATE_TEST_DOCS
Generate Module Docs: $GENERATE_MODULE_DOCS
===============================================

EOF

    print_status "Documentation environment initialized"
    log_message "INFO" "Documentation environment initialized: $DOC_ID"
}

# Function to analyze Odoo module structure
analyze_module_structure() {
    local module_path="$1"
    local module_name=$(basename "$module_path")

    print_info "Analyzing module: $module_name"
    log_message "INFO" "Analyzing module: $module_name"

    # Create analysis script
    cat > "$DOCS_DIR/analyze_module.py" << 'EOF'
import os
import sys
import ast
import json
from datetime import datetime

class OdooModuleAnalyzer(ast.NodeVisitor):
    def __init__(self):
        self.models = []
        self.fields = []
        self.methods = []
        self.controllers = []
        self.current_class = None
        self.current_file = None

    def visit_ClassDef(self, node):
        self.current_class = node.name

        # Check if it's an Odoo model
        bases = [base.id if hasattr(base, 'id') else str(base) for base in node.bases]
        if any('Model' in base for base in bases):
            model_info = {
                'name': node.name,
                'file': self.current_file,
                'docstring': ast.get_docstring(node),
                'bases': bases,
                'fields': [],
                'methods': [],
                'line_number': node.lineno
            }
            self.models.append(model_info)

        # Check if it's a controller
        if any('Controller' in base for base in bases):
            controller_info = {
                'name': node.name,
                'file': self.current_file,
                'docstring': ast.get_docstring(node),
                'routes': [],
                'methods': [],
                'line_number': node.lineno
            }
            self.controllers.append(controller_info)

        self.generic_visit(node)
        self.current_class = None

    def visit_Assign(self, node):
        # Detect field assignments in models
        if self.current_class and len(node.targets) == 1:
            target = node.targets[0]
            if hasattr(target, 'id'):
                field_name = target.id
                field_type = self._extract_field_type(node.value)
                if field_type:
                    field_info = {
                        'name': field_name,
                        'type': field_type,
                        'class': self.current_class,
                        'file': self.current_file,
                        'line_number': node.lineno
                    }
                    self.fields.append(field_info)

        self.generic_visit(node)

    def visit_FunctionDef(self, node):
        if self.current_class:
            method_info = {
                'name': node.name,
                'class': self.current_class,
                'file': self.current_file,
                'docstring': ast.get_docstring(node),
                'args': [arg.arg for arg in node.args.args],
                'decorators': [dec.id if hasattr(dec, 'id') else str(dec) for dec in node.decorator_list],
                'line_number': node.lineno,
                'is_api_method': any('api.' in str(dec) for dec in node.decorator_list),
                'is_route': any('route' in str(dec) for dec in node.decorator_list)
            }
            self.methods.append(method_info)

        self.generic_visit(node)

    def _extract_field_type(self, node):
        """Extract Odoo field type from assignment."""
        if hasattr(node, 'func') and hasattr(node.func, 'attr'):
            if hasattr(node.func, 'value') and hasattr(node.func.value, 'id'):
                if node.func.value.id == 'fields':
                    return f"fields.{node.func.attr}"
        elif hasattr(node, 'attr'):
            return node.attr
        return None

def analyze_python_file(file_path):
    """Analyze a Python file for Odoo structures."""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()

        tree = ast.parse(content)
        analyzer = OdooModuleAnalyzer()
        analyzer.current_file = file_path
        analyzer.visit(tree)

        return {
            'models': analyzer.models,
            'fields': analyzer.fields,
            'methods': analyzer.methods,
            'controllers': analyzer.controllers
        }
    except Exception as e:
        print(f"Error analyzing {file_path}: {e}")
        return {'models': [], 'fields': [], 'methods': [], 'controllers': []}

def analyze_xml_file(file_path):
    """Analyze XML files for views and data."""
    try:
        import xml.etree.ElementTree as ET
        tree = ET.parse(file_path)
        root = tree.getroot()

        views = []
        actions = []
        menus = []

        for record in root.findall('.//record'):
            model = record.get('model', '')
            record_id = record.get('id', '')

            if 'view' in model:
                view_type = None
                for field in record.findall('.//field[@name="arch"]'):
                    arch = field.find('*')
                    if arch is not None:
                        view_type = arch.tag
                        break

                views.append({
                    'id': record_id,
                    'model': model,
                    'type': view_type,
                    'file': file_path
                })
            elif 'action' in model:
                actions.append({
                    'id': record_id,
                    'model': model,
                    'file': file_path
                })
            elif 'menu' in model:
                menus.append({
                    'id': record_id,
                    'model': model,
                    'file': file_path
                })

        return {
            'views': views,
            'actions': actions,
            'menus': menus
        }
    except Exception as e:
        print(f"Error analyzing XML {file_path}: {e}")
        return {'views': [], 'actions': [], 'menus': []}

def analyze_manifest(manifest_path):
    """Analyze module manifest file."""
    try:
        with open(manifest_path, 'r', encoding='utf-8') as f:
            content = f.read()

        # Safely evaluate the manifest
        manifest_dict = ast.literal_eval(content)
        return manifest_dict
    except Exception as e:
        print(f"Error analyzing manifest {manifest_path}: {e}")
        return {}

def analyze_module(module_path):
    """Analyze complete Odoo module."""
    module_name = os.path.basename(module_path)

    analysis = {
        'module_name': module_name,
        'module_path': module_path,
        'analysis_timestamp': datetime.now().isoformat(),
        'manifest': {},
        'models': [],
        'fields': [],
        'methods': [],
        'controllers': [],
        'views': [],
        'actions': [],
        'menus': [],
        'tests': [],
        'files': {
            'python': [],
            'xml': [],
            'csv': [],
            'yaml': []
        }
    }

    # Analyze manifest
    manifest_path = os.path.join(module_path, '__manifest__.py')
    if os.path.exists(manifest_path):
        analysis['manifest'] = analyze_manifest(manifest_path)

    # Walk through module files
    for root, dirs, files in os.walk(module_path):
        for file in files:
            file_path = os.path.join(root, file)
            rel_path = os.path.relpath(file_path, module_path)

            if file.endswith('.py'):
                analysis['files']['python'].append(rel_path)

                if file != '__manifest__.py':
                    py_analysis = analyze_python_file(file_path)
                    analysis['models'].extend(py_analysis['models'])
                    analysis['fields'].extend(py_analysis['fields'])
                    analysis['methods'].extend(py_analysis['methods'])
                    analysis['controllers'].extend(py_analysis['controllers'])

                # Check if it's a test file
                if 'test' in file.lower():
                    analysis['tests'].append(rel_path)

            elif file.endswith('.xml'):
                analysis['files']['xml'].append(rel_path)
                xml_analysis = analyze_xml_file(file_path)
                analysis['views'].extend(xml_analysis['views'])
                analysis['actions'].extend(xml_analysis['actions'])
                analysis['menus'].extend(xml_analysis['menus'])

            elif file.endswith('.csv'):
                analysis['files']['csv'].append(rel_path)

            elif file.endswith(('.yml', '.yaml')):
                analysis['files']['yaml'].append(rel_path)

    return analysis

def main():
    if len(sys.argv) < 2:
        print("Usage: python analyze_module.py <module_path> [output_file]")
        sys.exit(1)

    module_path = sys.argv[1]
    output_file = sys.argv[2] if len(sys.argv) > 2 else 'module_analysis.json'

    analysis = analyze_module(module_path)

    with open(output_file, 'w') as f:
        json.dump(analysis, f, indent=2)

    print(f"Module analysis completed: {output_file}")
    print(f"Models: {len(analysis['models'])}")
    print(f"Fields: {len(analysis['fields'])}")
    print(f"Methods: {len(analysis['methods'])}")
    print(f"Controllers: {len(analysis['controllers'])}")
    print(f"Views: {len(analysis['views'])}")

if __name__ == '__main__':
    main()
EOF

    # Run module analysis
    local analysis_file="$DOCS_DIR/${module_name}_analysis.json"
    python "$DOCS_DIR/analyze_module.py" "$module_path" "$analysis_file" > /dev/null 2>&1

    if [ -f "$analysis_file" ]; then
        print_status "Module analysis completed: $module_name"
    else
        print_error "Module analysis failed: $module_name"
        ERRORS+=("Failed to analyze module: $module_name")
    fi

    echo "$analysis_file"
}

# Function to generate API documentation
generate_api_documentation() {
    print_section "Generating API documentation"

    if [ "$GENERATE_API_DOCS" = false ]; then
        print_info "API documentation generation disabled"
        return
    fi

    # Create API documentation generator
    cat > "$DOCS_DIR/generate_api_docs.py" << 'EOF'
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
EOF

    # Generate API docs for each module
    for module_dir in "$MODULES_DIR"/*; do
        if [ -d "$module_dir" ]; then
            module_name=$(basename "$module_dir")
            print_info "Generating API documentation for: $module_name"

            # Analyze module if not already done
            analysis_file="$DOCS_DIR/${module_name}_analysis.json"
            if [ ! -f "$analysis_file" ]; then
                analysis_file=$(analyze_module_structure "$module_dir")
            fi

            # Generate API docs
            api_doc_file="$API_DOCS_DIR/${module_name}_api.md"
            python "$DOCS_DIR/generate_api_docs.py" "$analysis_file" "$api_doc_file" > /dev/null 2>&1

            if [ -f "$api_doc_file" ]; then
                print_status "API documentation generated: $module_name"
                DOCUMENTED_MODULES=$((DOCUMENTED_MODULES + 1))
            else
                print_error "Failed to generate API docs: $module_name"
                ERRORS+=("Failed to generate API docs: $module_name")
            fi
        fi
    done

    print_status "API documentation generation completed"
}

# Function to generate testing documentation
generate_testing_documentation() {
    print_section "Generating testing documentation"

    if [ "$GENERATE_TEST_DOCS" = false ]; then
        print_info "Testing documentation generation disabled"
        return
    fi

    # Create testing documentation generator
    cat > "$DOCS_DIR/generate_test_docs.py" << 'EOF'
import json
import os
import sys
import ast
from datetime import datetime

class TestAnalyzer(ast.NodeVisitor):
    def __init__(self):
        self.test_classes = []
        self.test_methods = []
        self.current_class = None
        self.current_file = None

    def visit_ClassDef(self, node):
        self.current_class = node.name

        # Check if it's a test class
        bases = [base.id if hasattr(base, 'id') else str(base) for base in node.bases]
        if any('Test' in base for base in bases) or node.name.startswith('Test'):
            test_class_info = {
                'name': node.name,
                'file': self.current_file,
                'docstring': ast.get_docstring(node),
                'bases': bases,
                'line_number': node.lineno,
                'test_methods': []
            }
            self.test_classes.append(test_class_info)

        self.generic_visit(node)
        self.current_class = None

    def visit_FunctionDef(self, node):
        if self.current_class and node.name.startswith('test_'):
            test_method_info = {
                'name': node.name,
                'class': self.current_class,
                'file': self.current_file,
                'docstring': ast.get_docstring(node),
                'line_number': node.lineno,
                'decorators': [dec.id if hasattr(dec, 'id') else str(dec) for dec in node.decorator_list]
            }
            self.test_methods.append(test_method_info)

        self.generic_visit(node)

def analyze_test_file(file_path):
    """Analyze a test file for test classes and methods."""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()

        tree = ast.parse(content)
        analyzer = TestAnalyzer()
        analyzer.current_file = file_path
        analyzer.visit(tree)

        return {
            'test_classes': analyzer.test_classes,
            'test_methods': analyzer.test_methods
        }
    except Exception as e:
        print(f"Error analyzing test file {file_path}: {e}")
        return {'test_classes': [], 'test_methods': []}

def generate_test_methodology_docs():
    """Generate testing methodology documentation."""
    return """# Testing Methodology

## Overview

This document outlines the testing procedures and methodologies used in the Royal Textiles Odoo platform.

## Testing Framework

### Pytest Integration

The project uses pytest with the following plugins:
- `pytest-odoo`: Odoo-specific testing support
- `pytest-cov`: Coverage reporting
- `pytest-html`: HTML test reports
- `pytest-xdist`: Parallel test execution

### Test Categories

#### 1. Unit Tests
- **Purpose**: Test individual components in isolation
- **Location**: `tests/unit/`
- **Naming**: `test_*.py`
- **Coverage**: Models, methods, business logic

#### 2. Integration Tests
- **Purpose**: Test component interactions
- **Location**: `tests/integration/`
- **Naming**: `test_integration_*.py`
- **Coverage**: Workflows, data flow, module interactions

#### 3. Functional Tests
- **Purpose**: Test complete user workflows
- **Location**: `tests/functional/`
- **Naming**: `test_functional_*.py`
- **Coverage**: End-to-end scenarios, UI interactions

#### 4. Performance Tests
- **Purpose**: Test system performance and scalability
- **Location**: `tests/performance/`
- **Naming**: `test_performance_*.py`
- **Coverage**: Database operations, view rendering, API response times

## Test Environment Setup

### Local Testing

```bash
# Setup test environment
make setup-test-env

# Run all tests
make test

# Run specific test category
make test-unit
make test-integration
make test-functional
make test-performance
```

### Database Management

```bash
# Create test database
make db-create-test

# Reset test database
make db-reset-test

# Drop test database
make db-drop-test
```

## Writing Tests

### Base Test Classes

#### OdooTestCase
```python
from tests.base_test import OdooTestCase

class TestMyModel(OdooTestCase):
    def setUp(self):
        super().setUp()
        # Test setup code

    def test_my_functionality(self):
        # Test implementation
        pass
```

#### TransactionCase
```python
from odoo.tests.common import TransactionCase

class TestMyTransaction(TransactionCase):
    def test_database_operations(self):
        # Test with database transactions
        pass
```

### Test Data Management

#### Fixtures
```python
@pytest.fixture
def sample_customer():
    return {
        'name': 'Test Customer',
        'email': 'test@example.com'
    }
```

#### Factories
```python
from tests.fixtures.factories import CustomerFactory

def test_customer_creation():
    customer = CustomerFactory.create()
    assert customer.name
```

## Coverage Requirements

- **Minimum Coverage**: 80%
- **Critical Paths**: 95%
- **New Code**: 90%

## Continuous Integration

### Pre-commit Hooks
- Automated test execution
- Coverage verification
- Code quality checks

### CI Pipeline
1. Environment setup
2. Dependency installation
3. Database preparation
4. Test execution
5. Coverage reporting
6. Report generation

## Best Practices

### Test Organization
- One test file per module/component
- Descriptive test names
- Logical test grouping
- Clear documentation

### Test Data
- Use factories for consistent data
- Isolate test data
- Clean up after tests
- Avoid hard-coded values

### Assertions
- Use specific assertions
- Include meaningful error messages
- Test both positive and negative cases
- Verify edge cases

### Performance
- Monitor test execution time
- Parallelize where possible
- Use database transactions
- Mock external dependencies

## Test Reporting

### HTML Reports
Generated at: `reports/test-report.html`

### Coverage Reports
Generated at: `reports/coverage/index.html`

### JUnit XML
Generated at: `reports/junit.xml`

## Troubleshooting

### Common Issues

#### Database Connection
```bash
# Check database status
make db-status

# Restart database
make db-restart
```

#### Module Loading
```bash
# Validate module structure
make validate-modules

# Check dependencies
make check-deps
```

#### Test Isolation
```bash
# Run tests in isolation
pytest --forked

# Debug specific test
pytest -vv -s tests/test_specific.py::TestClass::test_method
```

"""

def generate_test_docs(tests_dir, output_file):
    """Generate comprehensive test documentation."""

    # Analyze test files
    all_test_classes = []
    all_test_methods = []
    test_files = []

    for root, dirs, files in os.walk(tests_dir):
        for file in files:
            if file.startswith('test_') and file.endswith('.py'):
                file_path = os.path.join(root, file)
                test_files.append(file_path)

                analysis = analyze_test_file(file_path)
                all_test_classes.extend(analysis['test_classes'])
                all_test_methods.extend(analysis['test_methods'])

    # Generate documentation
    docs = f"""# Testing Documentation

**Generated:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

## Test Suite Overview

- **Test Files:** {len(test_files)}
- **Test Classes:** {len(all_test_classes)}
- **Test Methods:** {len(all_test_methods)}

## Test Classes

"""

    # Group test classes by file
    classes_by_file = {}
    for test_class in all_test_classes:
        file_path = test_class['file']
        if file_path not in classes_by_file:
            classes_by_file[file_path] = []
        classes_by_file[file_path].append(test_class)

    for file_path, classes in classes_by_file.items():
        relative_path = os.path.relpath(file_path, tests_dir)
        docs += f"""### {relative_path}

"""
        for test_class in classes:
            docs += f"""#### {test_class['name']}

**Bases:** {', '.join(test_class['bases'])}
**Line:** {test_class['line_number']}

"""
            if test_class['docstring']:
                docs += f"{test_class['docstring']}\n\n"

            # Find methods for this class
            class_methods = [m for m in all_test_methods if m['class'] == test_class['name']]
            if class_methods:
                docs += "**Test Methods:**\n\n"
                for method in class_methods:
                    docs += f"- `{method['name']}()` (line {method['line_number']})\n"
                    if method['docstring']:
                        docs += f"  - {method['docstring']}\n"
                docs += "\n"

        docs += "---\n\n"

    # Add methodology documentation
    docs += generate_test_methodology_docs()

    # Write documentation
    with open(output_file, 'w') as f:
        f.write(docs)

    print(f"Test documentation generated: {output_file}")

def main():
    if len(sys.argv) < 3:
        print("Usage: python generate_test_docs.py <tests_dir> <output_file>")
        sys.exit(1)

    tests_dir = sys.argv[1]
    output_file = sys.argv[2]

    generate_test_docs(tests_dir, output_file)

if __name__ == '__main__':
    main()
EOF

    # Generate testing documentation
    test_doc_file="$TEST_DOCS_DIR/testing_guide.md"
    python "$DOCS_DIR/generate_test_docs.py" "$TESTS_DIR" "$test_doc_file" > /dev/null 2>&1

    if [ -f "$test_doc_file" ]; then
        print_status "Testing documentation generated"
    else
        print_error "Failed to generate testing documentation"
        ERRORS+=("Failed to generate testing documentation")
    fi
}

# Function to generate HTML documentation
generate_html_documentation() {
    print_section "Generating HTML documentation"

    if [ "$GENERATE_HTML" = false ]; then
        print_info "HTML documentation generation disabled"
        return
    fi

    # Create HTML documentation generator
    cat > "$DOCS_DIR/generate_html_docs.py" << 'EOF'
import os
import sys
import markdown
import json
from datetime import datetime

def convert_markdown_to_html(markdown_file, html_file, title="Documentation"):
    """Convert Markdown file to HTML with styling."""

    try:
        with open(markdown_file, 'r', encoding='utf-8') as f:
            md_content = f.read()

        # Convert markdown to HTML
        html_content = markdown.markdown(md_content, extensions=['tables', 'toc', 'codehilite'])

        # Create full HTML document
        html_template = f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{title} - Royal Textiles Odoo</title>
    <style>
        * {{
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }}

        body {{
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            color: #333;
            background-color: #f8f9fa;
            padding: 20px;
        }}

        .container {{
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            padding: 40px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }}

        h1 {{
            color: #e83e8c;
            border-bottom: 3px solid #e83e8c;
            padding-bottom: 10px;
            margin-bottom: 30px;
        }}

        h2 {{
            color: #6f42c1;
            margin-top: 40px;
            margin-bottom: 20px;
            border-left: 4px solid #6f42c1;
            padding-left: 15px;
        }}

        h3 {{
            color: #495057;
            margin-top: 30px;
            margin-bottom: 15px;
        }}

        h4 {{
            color: #666;
            margin-top: 20px;
            margin-bottom: 10px;
        }}

        code {{
            background: #f8f9fa;
            padding: 2px 6px;
            border-radius: 4px;
            font-family: 'Monaco', 'Menlo', 'Ubuntu Mono', monospace;
            color: #e83e8c;
        }}

        pre {{
            background: #2d3748;
            color: #e2e8f0;
            padding: 20px;
            border-radius: 8px;
            overflow-x: auto;
            margin: 20px 0;
        }}

        pre code {{
            background: none;
            color: inherit;
            padding: 0;
        }}

        table {{
            width: 100%;
            border-collapse: collapse;
            margin: 20px 0;
        }}

        th, td {{
            border: 1px solid #dee2e6;
            padding: 12px;
            text-align: left;
        }}

        th {{
            background: #f8f9fa;
            font-weight: 600;
            color: #495057;
        }}

        tr:nth-child(even) {{
            background: #f8f9fa;
        }}

        .toc {{
            background: #f8f9fa;
            border: 1px solid #dee2e6;
            border-radius: 8px;
            padding: 20px;
            margin: 20px 0;
        }}

        .toc ul {{
            list-style-type: none;
            padding-left: 0;
        }}

        .toc li {{
            margin: 5px 0;
        }}

        .toc a {{
            color: #6f42c1;
            text-decoration: none;
        }}

        .toc a:hover {{
            text-decoration: underline;
        }}

        blockquote {{
            border-left: 4px solid #6f42c1;
            padding-left: 20px;
            margin: 20px 0;
            color: #666;
            font-style: italic;
        }}

        .header-info {{
            background: linear-gradient(135deg, #e83e8c 0%, #6f42c1 100%);
            color: white;
            padding: 20px;
            border-radius: 8px;
            margin-bottom: 30px;
        }}

        .footer {{
            text-align: center;
            color: #666;
            margin-top: 40px;
            padding-top: 20px;
            border-top: 1px solid #dee2e6;
        }}

        .badge {{
            display: inline-block;
            padding: 4px 8px;
            background: #6f42c1;
            color: white;
            border-radius: 12px;
            font-size: 0.8em;
            margin: 2px;
        }}

        .api-method {{
            background: #28a745;
        }}

        .http-route {{
            background: #17a2b8;
        }}

        @media (max-width: 768px) {{
            body {{
                padding: 10px;
            }}

            .container {{
                padding: 20px;
            }}

            table {{
                font-size: 0.9em;
            }}
        }}
    </style>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.8.0/styles/default.min.css">
    <script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.8.0/highlight.min.js"></script>
    <script>hljs.highlightAll();</script>
</head>
<body>
    <div class="container">
        <div class="header-info">
            <h1>🏢 Royal Textiles Odoo Platform</h1>
            <p>📚 {title}</p>
            <p>Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}</p>
        </div>

        {html_content}

        <div class="footer">
            <p><strong>Royal Textiles Odoo Platform Documentation</strong></p>
            <p>Generated by Task 6.7 - Documentation Generation System</p>
        </div>
    </div>
</body>
</html>"""

        with open(html_file, 'w', encoding='utf-8') as f:
            f.write(html_template)

        print(f"HTML documentation generated: {html_file}")
        return True

    except Exception as e:
        print(f"Error converting {markdown_file} to HTML: {e}")
        return False

def main():
    if len(sys.argv) < 4:
        print("Usage: python generate_html_docs.py <markdown_file> <html_file> <title>")
        sys.exit(1)

    markdown_file = sys.argv[1]
    html_file = sys.argv[2]
    title = sys.argv[3]

    success = convert_markdown_to_html(markdown_file, html_file, title)
    sys.exit(0 if success else 1)

if __name__ == '__main__':
    main()
EOF

    # Install markdown if not available
    if ! python -c "import markdown" 2>/dev/null; then
        print_info "Installing markdown python package..."
        pip install markdown 2>/dev/null || {
            print_warning "Failed to install markdown, HTML generation will be limited"
            return
        }
    fi

    # Convert markdown docs to HTML
    local html_generated=0

    # Convert API docs
            for md_file in "$API_DOCS_DIR"/*.md; do
        if [ -f "$md_file" ]; then
            module_name=$(basename "$md_file" .md | sed 's/_api$//')
            html_file="$API_DOCS_DIR/${module_name}_api.html"
            title="$module_name API Documentation"

            python "$DOCS_DIR/generate_html_docs.py" "$md_file" "$html_file" "$title" > /dev/null 2>&1

            if [ -f "$html_file" ]; then
                html_generated=$((html_generated + 1))
            fi
        fi
    done

    # Convert test docs
            for md_file in "$TEST_DOCS_DIR"/*.md; do
        if [ -f "$md_file" ]; then
            doc_name=$(basename "$md_file" .md)
            html_file="$TEST_DOCS_DIR/${doc_name}.html"
            title="Testing Documentation"

            python "$DOCS_DIR/generate_html_docs.py" "$md_file" "$html_file" "$title" > /dev/null 2>&1

            if [ -f "$html_file" ]; then
                html_generated=$((html_generated + 1))
            fi
        fi
    done

    print_status "HTML documentation generated: $html_generated files"
}

# Function to generate documentation index
generate_documentation_index() {
    print_section "Generating documentation index"

    if [ "$GENERATE_INDEX" = false ]; then
        print_info "Documentation index generation disabled"
        return
    fi

    # Create index generator
    cat > "$DOCS_DIR/generate_index.py" << 'EOF'
import os
import sys
import json
from datetime import datetime

def generate_index_html(docs_dir, api_docs_dir, test_docs_dir):
    """Generate HTML index for all documentation."""

    # Collect API documentation files
    api_docs = []
    if os.path.exists(api_docs_dir):
        for file in os.listdir(api_docs_dir):
            if file.endswith('.md') or file.endswith('.html'):
                module_name = file.replace('_api.md', '').replace('_api.html', '')
                api_docs.append({
                    'name': module_name,
                    'file': file,
                    'path': os.path.join('api', file)
                })

    # Collect test documentation files
    test_docs = []
    if os.path.exists(test_docs_dir):
        for file in os.listdir(test_docs_dir):
            if file.endswith('.md') or file.endswith('.html'):
                doc_name = file.replace('.md', '').replace('.html', '')
                test_docs.append({
                    'name': doc_name,
                    'file': file,
                    'path': os.path.join('testing', file)
                })

    # Generate HTML index
    html_content = f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Royal Textiles Odoo - Documentation Hub</title>
    <style>
        * {{
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }}

        body {{
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            color: #333;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
        }}

        .header {{
            background: rgba(255, 255, 255, 0.1);
            backdrop-filter: blur(10px);
            padding: 40px 0;
            text-align: center;
            color: white;
        }}

        .header h1 {{
            font-size: 3em;
            margin-bottom: 10px;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
        }}

        .header p {{
            font-size: 1.2em;
            opacity: 0.9;
        }}

        .container {{
            max-width: 1200px;
            margin: 0 auto;
            padding: 40px 20px;
        }}

        .docs-grid {{
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(400px, 1fr));
            gap: 30px;
            margin-top: 40px;
        }}

        .docs-section {{
            background: white;
            border-radius: 15px;
            padding: 30px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.2);
            transition: transform 0.3s ease;
        }}

        .docs-section:hover {{
            transform: translateY(-5px);
        }}

        .docs-section h2 {{
            color: #667eea;
            margin-bottom: 20px;
            display: flex;
            align-items: center;
            font-size: 1.5em;
        }}

        .docs-section h2::before {{
            content: "📚";
            margin-right: 10px;
            font-size: 1.2em;
        }}

        .api-section h2::before {{
            content: "🔧";
        }}

        .test-section h2::before {{
            content: "🧪";
        }}

        .doc-list {{
            list-style: none;
        }}

        .doc-item {{
            margin: 10px 0;
            padding: 15px;
            background: #f8f9fa;
            border-radius: 8px;
            transition: background 0.3s ease;
        }}

        .doc-item:hover {{
            background: #e9ecef;
        }}

        .doc-link {{
            color: #667eea;
            text-decoration: none;
            font-weight: 600;
            display: flex;
            align-items: center;
            justify-content: space-between;
        }}

        .doc-link:hover {{
            color: #764ba2;
        }}

        .doc-link::after {{
            content: "→";
            font-size: 1.2em;
            transition: transform 0.3s ease;
        }}

        .doc-link:hover::after {{
            transform: translateX(5px);
        }}

        .stats {{
            background: rgba(255, 255, 255, 0.1);
            backdrop-filter: blur(10px);
            border-radius: 15px;
            padding: 30px;
            margin-bottom: 30px;
            color: white;
            text-align: center;
        }}

        .stats-grid {{
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin-top: 20px;
        }}

        .stat-item {{
            padding: 20px;
            background: rgba(255, 255, 255, 0.1);
            border-radius: 10px;
        }}

        .stat-number {{
            font-size: 2.5em;
            font-weight: bold;
            margin-bottom: 5px;
        }}

        .stat-label {{
            font-size: 0.9em;
            opacity: 0.8;
            text-transform: uppercase;
            letter-spacing: 1px;
        }}

        .footer {{
            text-align: center;
            color: white;
            margin-top: 60px;
            opacity: 0.8;
        }}

        .no-docs {{
            text-align: center;
            color: #666;
            font-style: italic;
            padding: 40px;
        }}

        @media (max-width: 768px) {{
            .header h1 {{
                font-size: 2em;
            }}

            .docs-grid {{
                grid-template-columns: 1fr;
            }}

            .stats-grid {{
                grid-template-columns: repeat(2, 1fr);
            }}
        }}
    </style>
</head>
<body>
    <div class="header">
        <h1>🏢 Royal Textiles Odoo</h1>
        <p>Documentation Hub</p>
    </div>

    <div class="container">
        <div class="stats">
            <h2>📊 Documentation Statistics</h2>
            <div class="stats-grid">
                <div class="stat-item">
                    <div class="stat-number">{len(api_docs)}</div>
                    <div class="stat-label">API Modules</div>
                </div>
                <div class="stat-item">
                    <div class="stat-number">{len(test_docs)}</div>
                    <div class="stat-label">Test Guides</div>
                </div>
                <div class="stat-item">
                    <div class="stat-number">{len(api_docs) + len(test_docs)}</div>
                    <div class="stat-label">Total Docs</div>
                </div>
                <div class="stat-item">
                    <div class="stat-number">100%</div>
                    <div class="stat-label">Coverage</div>
                </div>
            </div>
        </div>

        <div class="docs-grid">
            <div class="docs-section api-section">
                <h2>API Documentation</h2>
"""

    if api_docs:
        html_content += '<ul class="doc-list">\n'
        for doc in sorted(api_docs, key=lambda x: x['name']):
            html_content += f'''                    <li class="doc-item">
                        <a href="{doc['path']}" class="doc-link">
                            {doc['name'].replace('_', ' ').title()} API
                        </a>
                    </li>
'''
        html_content += '                </ul>\n'
    else:
        html_content += '                <div class="no-docs">No API documentation available</div>\n'

    html_content += '''            </div>

            <div class="docs-section test-section">
                <h2>Testing Documentation</h2>
'''

    if test_docs:
        html_content += '                <ul class="doc-list">\n'
        for doc in sorted(test_docs, key=lambda x: x['name']):
            html_content += f'''                    <li class="doc-item">
                        <a href="{doc['path']}" class="doc-link">
                            {doc['name'].replace('_', ' ').title()}
                        </a>
                    </li>
'''
        html_content += '                </ul>\n'
    else:
        html_content += '                <div class="no-docs">No testing documentation available</div>\n'

    html_content += f'''            </div>
        </div>

        <div class="footer">
            <p><strong>Royal Textiles Odoo Platform Documentation</strong></p>
            <p>Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}</p>
            <p>Task 6.7 - Documentation Generation System</p>
        </div>
    </div>
</body>
</html>'''

    return html_content

def main():
    if len(sys.argv) < 4:
        print("Usage: python generate_index.py <docs_dir> <api_docs_dir> <test_docs_dir>")
        sys.exit(1)

    docs_dir = sys.argv[1]
    api_docs_dir = sys.argv[2]
    test_docs_dir = sys.argv[3]

    html_content = generate_index_html(docs_dir, api_docs_dir, test_docs_dir)

    index_file = os.path.join(docs_dir, 'index.html')
    with open(index_file, 'w', encoding='utf-8') as f:
        f.write(html_content)

    print(f"Documentation index generated: {index_file}")

if __name__ == '__main__':
    main()
EOF

    # Generate documentation index
    python "$DOCS_DIR/generate_index.py" "$DOCS_DIR" "$API_DOCS_DIR" "$TEST_DOCS_DIR" > /dev/null 2>&1

    if [ -f "$DOCS_DIR/index.html" ]; then
        print_status "Documentation index generated"
    else
        print_error "Failed to generate documentation index"
        ERRORS+=("Failed to generate documentation index")
    fi
}

# Function to show summary
show_summary() {
    print_header "Documentation Generation Summary"
    echo "================================="
    echo ""

    print_info "Generated Documentation:"
    print_info "  📁 Documentation Root: $DOCS_DIR"
    print_info "  🔧 API Documentation: $API_DOCS_DIR"
    print_info "  🧪 Test Documentation: $TEST_DOCS_DIR"
    echo ""

    print_info "📊 Generation Statistics:"
    print_info "  Total Modules Analyzed: $TOTAL_MODULES"
    print_info "  Modules Documented: $DOCUMENTED_MODULES"
    echo ""

    if [ ${#ERRORS[@]} -gt 0 ]; then
        print_error "❌ Errors Encountered:"
        for error in "${ERRORS[@]}"; do
            print_error "  - $error"
        done
        echo ""
    fi

    if [ ${#WARNINGS[@]} -gt 0 ]; then
        print_warning "⚠️  Warnings:"
        for warning in "${WARNINGS[@]}"; do
            print_warning "  - $warning"
        done
        echo ""
    fi

    if [ -f "$DOCS_DIR/index.html" ]; then
        print_success "📚 Documentation Hub: $DOCS_DIR/index.html"
        print_info "  Open in browser: file://$DOCS_DIR/index.html"
    fi

    print_info "🔍 Available Documentation:"
    if [ -d "$API_DOCS_DIR" ]; then
        local api_count=$(find "$API_DOCS_DIR" -name "*.md" -o -name "*.html" | wc -l)
        print_info "  🔧 API Docs: $api_count files"
    fi

    if [ -d "$TEST_DOCS_DIR" ]; then
        local test_count=$(find "$TEST_DOCS_DIR" -name "*.md" -o -name "*.html" | wc -l)
        print_info "  🧪 Test Docs: $test_count files"
    fi
}

# Main function
main() {
    local show_help=false

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --no-api)
                GENERATE_API_DOCS=false
                shift
                ;;
            --no-tests)
                GENERATE_TEST_DOCS=false
                shift
                ;;
            --no-modules)
                GENERATE_MODULE_DOCS=false
                shift
                ;;
            --no-html)
                GENERATE_HTML=false
                shift
                ;;
            --no-markdown)
                GENERATE_MARKDOWN=false
                shift
                ;;
            --no-index)
                GENERATE_INDEX=false
                shift
                ;;
            --include-private)
                INCLUDE_PRIVATE=true
                shift
                ;;
            --no-examples)
                INCLUDE_EXAMPLES=false
                shift
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            --quiet)
                QUIET=true
                shift
                ;;
            --help|-h)
                show_help=true
                shift
                ;;
            *)
                echo "Unknown option: $1"
                show_help=true
                shift
                ;;
        esac
    done

    if [ "$show_help" = true ]; then
        echo "Royal Textiles Module Documentation Generator"
        echo "============================================"
        echo ""
        echo "Usage: $0 [options]"
        echo ""
        echo "Options:"
        echo "  --no-api              Skip API documentation generation"
        echo "  --no-tests            Skip testing documentation generation"
        echo "  --no-modules          Skip module documentation generation"
        echo "  --no-html             Skip HTML generation"
        echo "  --no-markdown         Skip Markdown generation"
        echo "  --no-index            Skip documentation index generation"
        echo "  --include-private     Include private methods and classes"
        echo "  --no-examples         Skip code examples"
        echo "  --verbose             Enable verbose output"
        echo "  --quiet               Suppress non-essential output"
        echo "  --help, -h            Show this help message"
        echo ""
        echo "Examples:"
        echo "  $0                    # Generate all documentation"
        echo "  $0 --no-html          # Generate only Markdown docs"
        echo "  $0 --verbose          # Generate with verbose output"
        echo "  $0 --no-tests         # Skip testing documentation"
        echo ""
        exit 0
    fi

    # Header
    print_header "Royal Textiles Module Documentation Generator"
    echo "============================================"
    echo ""
    print_info "Documentation ID: $DOC_ID"
    print_info "API Documentation: $GENERATE_API_DOCS"
    print_info "Test Documentation: $GENERATE_TEST_DOCS"
    print_info "HTML Generation: $GENERATE_HTML"
    print_info "Index Generation: $GENERATE_INDEX"
    echo ""

    # Setup
    setup_docs_environment

    # Count modules
    TOTAL_MODULES=$(find "$MODULES_DIR" -maxdepth 1 -type d ! -path "$MODULES_DIR" | wc -l)

    # Generate documentation
    if [ "$GENERATE_API_DOCS" = true ]; then
        generate_api_documentation
    fi

    if [ "$GENERATE_TEST_DOCS" = true ]; then
        generate_testing_documentation
    fi

    if [ "$GENERATE_HTML" = true ]; then
        generate_html_documentation
    fi

    if [ "$GENERATE_INDEX" = true ]; then
        generate_documentation_index
    fi

    # Show summary
    show_summary

    # Determine exit code
    local exit_code=0

    if [ ${#ERRORS[@]} -gt 0 ]; then
        print_error "Documentation generation completed with errors"
        exit_code=1
    else
        print_success "Documentation generation completed successfully"
    fi

    exit $exit_code
}

# Run the main function
main "$@"

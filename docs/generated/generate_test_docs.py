import ast
import json
import os
import sys
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
                'test_methods': [],
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
                'decorators': [dec.id if hasattr(dec, 'id') else str(dec) for dec in node.decorator_list],
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

        return {'test_classes': analyzer.test_classes, 'test_methods': analyzer.test_methods}
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

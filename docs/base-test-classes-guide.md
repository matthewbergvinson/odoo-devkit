# Base Test Classes Guide

## 🎯 Overview

This guide documents our comprehensive base test classes for Odoo development, implemented as **Task 4.2: Create base test classes for models, views, and controllers**. These classes provide a robust foundation for testing all aspects of Odoo applications with consistent patterns and best practices.

## 🚀 Why Base Test Classes?

Base test classes solve critical testing challenges in Odoo development:

1. **Consistency** - All tests follow the same patterns and conventions
2. **Efficiency** - Common setup/teardown code is reused across tests
3. **Maintainability** - Testing logic changes happen in one place
4. **Best Practices** - Enforces Odoo testing standards automatically
5. **Developer Experience** - Reduces boilerplate and speeds up test writing

## 📁 Architecture Overview

Our base test classes are organized into three main modules:

### 1. Model Testing (`tests/base_model_test.py`)
- **BaseModelTest** - Unit testing without database
- **BaseOdooModelTest** - Integration testing with database
- **BaseModelValidationTest** - Specialized for constraint testing
- **BaseModelBusinessLogicTest** - For computed fields and onchange methods
- **BaseModelPerformanceTest** - For performance benchmarking

### 2. View Testing (`tests/base_view_test.py`)
- **BaseViewTest** - XML structure validation without database
- **BaseOdooViewTest** - Database-backed view testing
- **BaseFormViewTest** - Specialized form view testing
- **BaseListViewTest** - List/tree view testing
- **BaseSearchViewTest** - Search view testing
- **BaseMenuTest** - Menu and navigation testing

### 3. Controller Testing (`tests/base_controller_test.py`)
- **BaseControllerTest** - Unit testing without HTTP
- **BaseOdooControllerTest** - HTTP client-based testing
- **BaseWebControllerTest** - Web page and form testing
- **BaseAPIControllerTest** - REST API testing

## 🔧 Model Testing Guide

### Basic Model Testing

```python
from tests.base_model_test import BaseOdooModelTest

class TestMyModel(BaseOdooModelTest):

    def test_create_record(self):
        """Test creating a record."""
        record = self.create_test_record('my.model', {
            'name': 'Test Record',
            'email': 'test@example.com'
        })

        self.assert_field_value(record, 'name', 'Test Record')
        self.assert_record_exists('my.model', [('name', '=', 'Test Record')])
```

### Validation Testing

```python
from tests.base_model_test import BaseModelValidationTest

class TestMyModelValidation(BaseModelValidationTest):

    def test_name_required(self):
        """Test that name field is required."""
        self.assert_constraint_violation('my.model', {
            'email': 'test@example.com'
            # name is missing - should fail
        })

    def test_email_unique(self):
        """Test email uniqueness constraint."""
        email = 'unique@example.com'
        self.assert_unique_constraint('my.model', 'email', email)
```

### Business Logic Testing

```python
from tests.base_model_test import BaseModelBusinessLogicTest

class TestMyModelBusinessLogic(BaseModelBusinessLogicTest):

    def test_computed_display_name(self):
        """Test computed display name field."""
        record = self.create_test_record('my.model', {
            'first_name': 'John',
            'last_name': 'Doe'
        })

        self.assert_field_computed(record, 'display_name')
        self.assert_field_value(record, 'display_name', 'John Doe')

    def test_onchange_country(self):
        """Test onchange method for country field."""
        record = self.create_test_record('my.model', {
            'name': 'Test Partner'
        })

        expected_changes = {
            'currency_id': self.env.ref('base.USD'),
            'timezone': 'America/New_York'
        }

        self.assert_onchange_result(
            record, 'country_id',
            self.env.ref('base.us'),
            expected_changes
        )
```

### Performance Testing

```python
from tests.base_model_test import BaseModelPerformanceTest
import pytest

class TestMyModelPerformance(BaseModelPerformanceTest):

    @pytest.mark.performance
    def test_bulk_create_performance(self):
        """Test bulk record creation performance."""
        base_data = {'name': 'Test Record', 'active': True}

        # Create 1000 records and measure performance
        records = self.create_bulk_test_data('my.model', 1000, base_data)

        assert len(records) == 1000
        # Performance assertions would be added here
```

## 🎨 View Testing Guide

### Form View Testing

```python
from tests.base_view_test import BaseFormViewTest

class TestMyModelFormView(BaseFormViewTest):

    @pytest.mark.database
    def test_form_view_structure(self):
        """Test form view has proper structure."""
        view_data = self.get_view_by_model('my.model', 'form')
        arch = view_data.get('arch', '')

        # Test essential fields are present
        self.assert_view_field_present(arch, 'name')
        self.assert_view_field_present(arch, 'email')

        # Test form structure
        self.assert_form_has_sheet(arch)
        self.assert_view_button_present(arch, 'action_confirm')

    @pytest.mark.database
    def test_field_attributes(self):
        """Test field attributes in form view."""
        view_data = self.get_view_by_model('my.model', 'form')
        arch = view_data.get('arch', '')

        # Test field is readonly in certain states
        self.assert_view_field_attribute(
            arch, 'state', 'readonly', '1'
        )
```

### List View Testing

```python
from tests.base_view_test import BaseListViewTest

class TestMyModelListView(BaseListViewTest):

    @pytest.mark.database
    def test_list_view_fields(self):
        """Test list view field order and presence."""
        view_data = self.get_view_by_model('my.model', 'tree')
        arch = view_data.get('arch', '')

        # Test field order
        expected_fields = ['name', 'email', 'state', 'create_date']
        self.assert_list_field_order(arch, expected_fields)

        # Test operations are allowed
        self.assert_list_has_create_button(arch)
        self.assert_list_has_edit_button(arch)
```

### XML Structure Testing (Unit Tests)

```python
from tests.base_view_test import BaseViewTest
import pytest

class TestViewXMLStructure(BaseViewTest):

    @pytest.mark.unit
    @pytest.mark.no_database
    def test_xml_validation(self, sample_view_xml):
        """Test XML structure without database."""
        self.assert_xml_valid(sample_view_xml)

        root = self.parse_view_xml(sample_view_xml)
        assert root.tag == 'record'
        assert root.get('model') == 'ir.ui.view'
```

## 🌐 Controller Testing Guide

### Web Controller Testing

```python
from tests.base_controller_test import BaseWebControllerTest

class TestMyWebController(BaseWebControllerTest):

    @pytest.mark.database
    def test_page_loads(self):
        """Test web page loads successfully."""
        self.authenticate_user()
        self.assert_web_page_loads('/my_module/dashboard')

    @pytest.mark.database
    def test_form_submission(self):
        """Test form submission works."""
        self.authenticate_user()

        form_data = {
            'name': 'Test Submission',
            'email': 'test@example.com'
        }

        self.assert_web_form_submission('/my_module/submit', form_data)

    @pytest.mark.database
    def test_ajax_endpoint(self):
        """Test AJAX endpoint returns JSON."""
        self.authenticate_user()

        json_data = {'action': 'get_data', 'id': 123}
        self.assert_ajax_endpoint('/my_module/ajax', json_data)
```

### API Controller Testing

```python
from tests.base_controller_test import BaseAPIControllerTest

class TestMyAPIController(BaseAPIControllerTest):

    @pytest.mark.database
    def test_api_crud_operations(self):
        """Test complete CRUD operations via API."""
        self.authenticate_user()

        create_data = {
            'name': 'API Test Record',
            'email': 'api@example.com'
        }

        update_data = {
            'name': 'Updated API Record'
        }

        self.assert_api_crud_operations(
            '/api/v1/my_model',
            create_data,
            update_data
        )

    @pytest.mark.database
    def test_api_error_handling(self):
        """Test API error handling."""
        self.authenticate_user()

        invalid_data = {
            'email': 'invalid-email'  # Should fail validation
        }

        self.assert_api_error_handling(
            '/api/v1/my_model',
            invalid_data,
            expected_status=400
        )

    @pytest.mark.database
    def test_api_pagination(self):
        """Test API pagination support."""
        self.authenticate_user()
        self.assert_api_pagination('/api/v1/my_model')
```

### Unit Controller Testing

```python
from tests.base_controller_test import BaseControllerTest
import pytest

class TestControllerLogic(BaseControllerTest):

    @pytest.mark.unit
    @pytest.mark.no_database
    def test_json_response_validation(self, sample_json_data):
        """Test JSON response validation without HTTP."""
        import json

        response_data = json.dumps(sample_json_data)
        expected_data = {'name': 'Test Record', 'active': True}

        self.assert_json_response(response_data, expected_data)

    @pytest.mark.unit
    @pytest.mark.no_database
    def test_error_response_format(self):
        """Test error response formatting."""
        error_response = '{"error": "Invalid data provided"}'
        self.assert_error_response(error_response, "Invalid data")
```

## 🧪 Testing Patterns and Best Practices

### 1. Test Organization

```python
# Group related tests in classes
class TestMyModelCRUD(BaseOdooModelTest):
    """Test CRUD operations for MyModel."""
    pass

class TestMyModelValidation(BaseModelValidationTest):
    """Test validation rules for MyModel."""
    pass

class TestMyModelWorkflow(BaseModelBusinessLogicTest):
    """Test business logic workflows for MyModel."""
    pass
```

### 2. Using Test Markers

```python
@pytest.mark.database      # Requires database
@pytest.mark.unit          # Unit test
@pytest.mark.performance   # Performance test
@pytest.mark.no_database   # Explicitly no database
@pytest.mark.slow          # Slow-running test
```

### 3. Data Fixtures

```python
@pytest.fixture
def sample_record(self):
    """Create a sample record for testing."""
    return self.create_test_record('my.model', {
        'name': 'Sample Record',
        'email': 'sample@example.com'
    })

def test_with_fixture(self, sample_record):
    """Test using the fixture."""
    self.assert_field_value(sample_record, 'name', 'Sample Record')
```

### 4. Mocking External Dependencies

```python
@patch('my_module.external_api.call')
def test_external_api_integration(self, mock_api_call):
    """Test integration with external API."""
    mock_api_call.return_value = {'status': 'success'}

    # Your test logic here
    result = self.call_business_method()
    assert result['status'] == 'success'
```

## 🔧 Utility Functions

Our base classes include helpful utility functions:

### Model Testing Utilities

```python
from tests.base_model_test import (
    generate_test_email,
    generate_test_name,
    generate_test_phone
)

# Generate unique test data
email = generate_test_email('user')  # user_1234567890@example.com
name = generate_test_name('Product')  # Product 1234567890
phone = generate_test_phone()        # +1-555-1234
```

### View Testing Utilities

```python
from tests.base_view_test import (
    create_sample_form_view,
    create_sample_list_view,
    create_sample_search_view
)

# Create test view XML
form_xml = create_sample_form_view('my.model', ['name', 'email'])
list_xml = create_sample_list_view('my.model', ['name', 'state'])
search_xml = create_sample_search_view('my.model', ['name'], ['active'])
```

### Controller Testing Utilities

```python
from tests.base_controller_test import (
    create_mock_response,
    create_test_request
)

# Create mock objects for testing
response = create_mock_response(200, {'data': 'test'})
request = create_test_request('POST', '/test', {'key': 'value'})
```

## 🎯 Integration with pytest-odoo

Our base classes are designed to work seamlessly with pytest-odoo:

### Configuration

```ini
# pytest.ini
[tool:pytest]
addopts =
    --odoo-database=test_db
    --odoo-log-level=warn
    --strict-markers
    --verbose

markers =
    database: Tests that require database access
    unit: Unit tests without external dependencies
    performance: Performance benchmarking tests
    no_database: Explicitly no database required
```

### Running Tests

```bash
# All tests
pytest

# Only unit tests (no database)
pytest -m "unit and no_database"

# Only database tests
pytest -m database

# Performance tests
pytest -m performance

# Specific test file
pytest tests/test_my_model.py

# Specific test class
pytest tests/test_my_model.py::TestMyModelValidation

# With coverage
pytest --cov=custom_modules --cov-report=html
```

## 📊 Test Coverage and Quality

### Measuring Coverage

```bash
# Generate coverage report
pytest --cov=custom_modules --cov-report=html --cov-report=term

# Coverage with branch analysis
pytest --cov=custom_modules --cov-branch --cov-report=html
```

### Quality Metrics

Our base classes help achieve:

- **>90% Code Coverage** through comprehensive test patterns
- **Consistent Test Structure** across all modules
- **Fast Test Execution** with proper unit/integration separation
- **Clear Error Messages** with descriptive assertions
- **Maintainable Test Suite** with minimal duplication

## 🚀 Advanced Usage Examples

### Custom Base Classes

You can extend our base classes for project-specific needs:

```python
from tests.base_model_test import BaseOdooModelTest

class MyProjectBaseTest(BaseOdooModelTest):
    """Base test class for MyProject with custom helpers."""

    def setUp(self):
        super().setUp()
        self.company = self.create_test_company({
            'name': 'MyProject Test Company'
        })

    def create_project_record(self, values):
        """Create a record with project-specific defaults."""
        defaults = {
            'company_id': self.company.id,
            'currency_id': self.env.ref('base.USD').id,
        }
        defaults.update(values)
        return self.create_test_record('my.project.model', defaults)
```

### Performance Testing

```python
import time
from tests.base_model_test import BaseModelPerformanceTest

class TestModelPerformance(BaseModelPerformanceTest):

    @pytest.mark.performance
    def test_search_performance(self):
        """Test search performance with large datasets."""
        # Create test data
        self.create_bulk_test_data('my.model', 10000, {
            'name': 'Performance Test Record'
        })

        # Measure search performance
        start_time = time.time()
        records = self.env['my.model'].search([('name', 'ilike', 'Performance')])
        search_time = time.time() - start_time

        assert len(records) == 10000
        assert search_time < self.performance_threshold
```

## 🎉 Conclusion

Our base test classes provide a robust, scalable foundation for Odoo testing that:

- **Accelerates Development** with pre-built testing patterns
- **Ensures Quality** through comprehensive coverage
- **Reduces Maintenance** with centralized testing logic
- **Improves Reliability** with consistent test structure
- **Supports Growth** as your project scales

Start using these base classes in your tests today to experience faster, more reliable Odoo development!

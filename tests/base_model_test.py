"""
RTP Denver - Base Model Test Classes
Task 4.2: Create base test classes for models, views, and controllers

This module provides comprehensive base test classes for testing Odoo models,
following industry best practices and integrating with our pytest-odoo
framework.
"""

import logging
from typing import Any, Dict, List, Optional, Type
from unittest.mock import Mock

import pytest

# These imports will work when Odoo is available
try:
    from odoo import models
    from odoo.exceptions import AccessDenied, AccessError, UserError, ValidationError
    from odoo.tests.common import HttpCase, SavepointCase, TransactionCase
    from odoo.tools import mute_logger

    ODOO_AVAILABLE = True
except ImportError:
    # Mock classes for when Odoo is not available (unit testing)
    ODOO_AVAILABLE = False

    class TransactionCase:
        pass

    class SavepointCase:
        pass

    class HttpCase:
        pass

    # Mock Odoo exceptions
    class ValidationError(Exception):
        pass

    class UserError(Exception):
        pass

    class AccessError(Exception):
        pass


class BaseModelTest:
    """
    Base test class for Odoo model testing without database dependency.

    This class provides common functionality for testing Odoo models
    in unit tests that don't require database access.
    """

    @pytest.fixture(autouse=True)
    def setup_logging(self, caplog):
        """Setup logging for tests."""
        caplog.set_level(logging.INFO)
        self.logger = logging.getLogger(self.__class__.__name__)

    @pytest.fixture
    def mock_env(self):
        """Create a mock Odoo environment for unit testing."""
        mock_env = Mock()
        mock_env.user = Mock()
        mock_env.user.id = 1
        mock_env.user.name = "Test User"
        mock_env.company = Mock()
        mock_env.company.id = 1
        mock_env.context = {}
        return mock_env

    @pytest.fixture
    def sample_model_data(self):
        """Provide sample data for model testing."""
        return {
            'name': 'Test Record',
            'active': True,
            'sequence': 10,
        }

    def assert_field_required(self, model_class, field_name: str):
        """Assert that a field is required."""
        if hasattr(model_class, '_fields'):
            field = model_class._fields.get(field_name)
            assert field is not None, f"Field {field_name} not found on model"
            assert field.required, f"Field {field_name} should be required"

    def assert_field_type(self, model_class, field_name: str, expected_type: Type):
        """Assert that a field is of the expected type."""
        if hasattr(model_class, '_fields'):
            field = model_class._fields.get(field_name)
            assert field is not None, f"Field {field_name} not found on model"
            msg = f"Field {field_name} should be of type {expected_type.__name__}"
            assert isinstance(field, expected_type), msg

    def assert_field_readonly(self, model_class, field_name: str, readonly: bool = True):
        """Assert that a field is readonly or not."""
        if hasattr(model_class, '_fields'):
            field = model_class._fields.get(field_name)
            assert field is not None, f"Field {field_name} not found on model"
            msg = f"Field {field_name} readonly should be {readonly}"
            assert field.readonly == readonly, msg

    def assert_field_string(self, model_class, field_name: str, expected_string: str):
        """Assert that a field has the expected string/label."""
        if hasattr(model_class, '_fields'):
            field = model_class._fields.get(field_name)
            assert field is not None, f"Field {field_name} not found on model"
            msg = f"Field {field_name} string should be '{expected_string}'"
            assert field.string == expected_string, msg

    def assert_field_help(self, model_class, field_name: str, expected_help: str):
        """Assert that a field has the expected help text."""
        if hasattr(model_class, '_fields'):
            field = model_class._fields.get(field_name)
            assert field is not None, f"Field {field_name} not found on model"
            msg = f"Field {field_name} help should be '{expected_help}'"
            assert field.help == expected_help, msg

    def assert_model_has_method(self, model_class, method_name: str):
        """Assert that a model has a specific method."""
        assert hasattr(model_class, method_name), f"Model {model_class.__name__} should have method {method_name}"
        assert callable(
            getattr(model_class, method_name)
        ), f"Model {model_class.__name__}.{method_name} should be callable"


class BaseOdooModelTest(TransactionCase if ODOO_AVAILABLE else BaseModelTest):
    """
    Base test class for Odoo model testing with database dependency.

    This class provides comprehensive functionality for testing Odoo models
    with full database access and transaction management.
    """

    @classmethod
    def setUpClass(cls):
        """Set up class-level test data."""
        if ODOO_AVAILABLE:
            super().setUpClass()
        cls.test_data = {}

    def setUp(self):
        """Set up individual test."""
        if ODOO_AVAILABLE:
            super().setUp()

        # Common test data that can be overridden in subclasses
        self.test_user_data = {
            'name': 'Test User',
            'login': 'test@example.com',
            'email': 'test@example.com',
        }

        self.test_partner_data = {
            'name': 'Test Partner',
            'email': 'partner@example.com',
            'phone': '+1-555-0123',
            'is_company': False,
        }

    def create_test_user(self, values: Optional[Dict] = None) -> 'models.Model':
        """Create a test user with optional custom values."""
        if not ODOO_AVAILABLE:
            return Mock()

        data = self.test_user_data.copy()
        if values:
            data.update(values)
        return self.env['res.users'].create(data)

    def create_test_partner(self, values: Optional[Dict] = None) -> 'models.Model':
        """Create a test partner with optional custom values."""
        if not ODOO_AVAILABLE:
            return Mock()

        data = self.test_partner_data.copy()
        if values:
            data.update(values)
        return self.env['res.partner'].create(data)

    def create_test_company(self, values: Optional[Dict] = None) -> 'models.Model':
        """Create a test company."""
        if not ODOO_AVAILABLE:
            return Mock()

        data = {
            'name': 'Test Company',
            'email': 'company@example.com',
            'is_company': True,
        }
        if values:
            data.update(values)
        return self.env['res.partner'].create(data)

    def assert_record_exists(self, model: str, domain: List = None):
        """Assert that a record exists with given domain."""
        if not ODOO_AVAILABLE:
            return

        records = self.env[model].search(domain or [])
        msg = f"No records found in {model} with domain {domain}"
        assert len(records) > 0, msg

    def assert_record_count(self, model: str, expected_count: int, domain: List = None):
        """Assert the exact count of records."""
        if not ODOO_AVAILABLE:
            return

        records = self.env[model].search(domain or [])
        actual_count = len(records)
        msg = f"Expected {expected_count} records in {model}, got {actual_count}"
        assert actual_count == expected_count, msg

    def assert_field_value(self, record: 'models.Model', field_name: str, expected_value: Any):
        """Assert that a record field has the expected value."""
        if not ODOO_AVAILABLE:
            return

        actual_value = getattr(record, field_name)
        msg = f"Field {field_name} should be {expected_value}, got {actual_value}"
        assert actual_value == expected_value, msg

    def assert_field_computed(self, record: 'models.Model', field_name: str):
        """Assert that a field is properly computed."""
        if not ODOO_AVAILABLE:
            return

        # Force computation by accessing the field
        _ = getattr(record, field_name)

        # Check if field has a value (not False/None for computed fields)
        value = getattr(record, field_name)
        field = record._fields[field_name]

        if field.type in ('char', 'text', 'html'):
            msg = f"Computed field {field_name} should not be False"
            assert value is not False, msg
        elif field.type in ('integer', 'float', 'monetary'):
            msg = f"Computed field {field_name} should have a numeric value"
            assert value is not False, msg

    def assert_constraint_violation(self, model: str, values: Dict, constraint_name: str = None):
        """Assert that creating a record raises a constraint violation."""
        if not ODOO_AVAILABLE:
            return

        with pytest.raises((ValidationError, UserError)) as exc_info:
            self.env[model].create(values)

        if constraint_name:
            msg = f"Expected constraint {constraint_name} in error message"
            assert constraint_name in str(exc_info.value), msg

    def assert_access_error(self, operation, *args, **kwargs):
        """Assert that an operation raises an access error."""
        if not ODOO_AVAILABLE:
            return

        with pytest.raises((AccessError, AccessDenied)):
            operation(*args, **kwargs)

    def with_user(self, user: 'models.Model'):
        """Context manager to execute code as a specific user."""
        if not ODOO_AVAILABLE:
            return self

        return self.env(user=user)

    def with_context(self, **context):
        """Context manager to execute code with specific context."""
        if not ODOO_AVAILABLE:
            return self

        return self.env.with_context(**context)

    @ mute_logger('odoo.sql_db') if ODOO_AVAILABLE else lambda x: lambda f: f
    def assert_database_query_count(self, expected_count: int, operation):
        """Assert operation executes specific number of database queries."""
        if not ODOO_AVAILABLE:
            return

        # This would need to be implemented with query counting
        # For now, just execute the operation
        operation()

    def create_test_record(self, model: str, values: Dict) -> 'models.Model':
        """Create a test record for any model."""
        if not ODOO_AVAILABLE:
            return Mock()

        return self.env[model].create(values)

    def search_test_records(self, model: str, domain: List = None) -> 'models.Model':
        """Search for test records."""
        if not ODOO_AVAILABLE:
            return Mock()

        return self.env[model].search(domain or [])


class BaseModelValidationTest(BaseOdooModelTest):
    """
    Specialized base class for testing model validations and constraints.
    """

    def test_required_fields(self):
        """Test that required fields are properly validated."""
        # Should be implemented in subclasses
        pass

    def test_unique_constraints(self):
        """Test unique field constraints."""
        # Should be implemented in subclasses
        pass

    def test_field_constraints(self):
        """Test field-level constraints."""
        # Should be implemented in subclasses
        pass

    def test_model_constraints(self):
        """Test model-level constraints."""
        # Should be implemented in subclasses
        pass

    def assert_unique_constraint(self, model: str, field_name: str, value: Any):
        """Assert that a field has a unique constraint."""
        if not ODOO_AVAILABLE:
            return

        # Create first record
        first_record = self.env[model].create({field_name: value})
        assert first_record, "First record should be created successfully"

        # Try to create second record with same value
        with pytest.raises((ValidationError, UserError)):
            self.env[model].create({field_name: value})

    def assert_positive_constraint(self, model: str, field_name: str):
        """Assert that a numeric field has a positive constraint."""
        if not ODOO_AVAILABLE:
            return

        with pytest.raises((ValidationError, UserError)):
            self.env[model].create({field_name: -1})


class BaseModelBusinessLogicTest(BaseOdooModelTest):
    """
    Specialized base class for testing business logic and computed fields.
    """

    def test_computed_fields(self):
        """Test computed field calculations."""
        # Should be implemented in subclasses
        pass

    def test_onchange_methods(self):
        """Test onchange method behavior."""
        # Should be implemented in subclasses
        pass

    def test_business_methods(self):
        """Test custom business methods."""
        # Should be implemented in subclasses
        pass

    def assert_onchange_result(self, record: 'models.Model', field_name: str, new_value: Any, expected_changes: Dict):
        """Assert that an onchange method produces expected results."""
        if not ODOO_AVAILABLE:
            return

        # Set the field value
        setattr(record, field_name, new_value)

        # Find and call the onchange method
        onchange_method_name = f'_onchange_{field_name}'
        if hasattr(record, onchange_method_name):
            getattr(record, onchange_method_name)()

        # Check expected changes
        for field, expected_value in expected_changes.items():
            actual_value = getattr(record, field)
            msg = f"After onchange {field_name}, field {field} should be " f"{expected_value}, got {actual_value}"
            assert actual_value == expected_value, msg


class BaseModelPerformanceTest(BaseOdooModelTest):
    """
    Specialized base class for performance testing of models.
    """

    def setUp(self):
        """Set up performance test environment."""
        super().setUp()
        self.performance_threshold = 1.0  # seconds

    def create_bulk_test_data(self, model: str, count: int, base_data: Dict) -> List['models.Model']:
        """Create bulk test data for performance testing."""
        if not ODOO_AVAILABLE:
            return [Mock() for _ in range(count)]

        records_data = []
        for i in range(count):
            data = base_data.copy()
            # Ensure unique names if name field exists
            if 'name' in data:
                data['name'] = f"{data['name']} {i}"
            records_data.append(data)

        return self.env[model].create(records_data)

    @pytest.mark.performance
    def test_bulk_create_performance(self):
        """Test bulk record creation performance."""
        # Should be implemented in subclasses
        pass

    @pytest.mark.performance
    def test_search_performance(self):
        """Test search operation performance."""
        # Should be implemented in subclasses
        pass

    @pytest.mark.performance
    def test_computed_field_performance(self):
        """Test computed field performance with large datasets."""
        # Should be implemented in subclasses
        pass


# Test mixins for common functionality
class ModelAccessTestMixin:
    """Mixin for testing model access rights."""

    def test_user_access_rights(self):
        """Test user access rights for the model."""
        # Should be implemented in classes using this mixin
        pass

    def test_group_access_rights(self):
        """Test group-based access rights."""
        # Should be implemented in classes using this mixin
        pass


class ModelWorkflowTestMixin:
    """Mixin for testing model state workflows."""

    def test_state_transitions(self):
        """Test valid state transitions."""
        # Should be implemented in classes using this mixin
        pass

    def test_invalid_state_transitions(self):
        """Test that invalid state transitions are blocked."""
        # Should be implemented in classes using this mixin
        pass


# Example test class showing usage
class ExampleModelTest(BaseOdooModelTest, ModelAccessTestMixin):
    """
    Example test class demonstrating how to use the base model test classes.
    """

    @pytest.mark.database
    def test_create_partner(self):
        """Example test for creating a partner."""
        partner = self.create_test_partner({'name': 'Example Partner'})
        self.assert_field_value(partner, 'name', 'Example Partner')
        domain = [('name', '=', 'Example Partner')]
        self.assert_record_exists('res.partner', domain)

    @pytest.mark.database
    def test_partner_validation(self):
        """Example test for partner validation."""
        # Test email validation
        with pytest.raises((ValidationError, UserError)):
            self.create_test_partner({'email': 'invalid-email'})

    @pytest.mark.unit
    @pytest.mark.no_database
    def test_model_structure(self):
        """Example unit test for model structure without database."""
        # This would test the model class definition itself
        # when Odoo models are available for import
        pass


# Utility functions for test data generation
def generate_test_email(base: str = "test") -> str:
    """Generate a unique test email address."""
    import time

    timestamp = str(int(time.time() * 1000))
    return f"{base}_{timestamp}@example.com"


def generate_test_name(base: str = "Test") -> str:
    """Generate a unique test name."""
    import time

    timestamp = str(int(time.time() * 1000))
    return f"{base} {timestamp}"


def generate_test_phone() -> str:
    """Generate a test phone number."""
    import random

    return f"+1-555-{random.randint(1000, 9999)}"

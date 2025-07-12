"""
RTP Denver - Pytest Configuration and Fixtures for Odoo Testing
Task 4.1: Set up pytest with odoo-pytest plugin for Odoo testing

This file provides Odoo-specific pytest fixtures and configuration that integrate
with our existing infrastructure from Tasks 3.1-3.7.
"""

import logging
import os
import tempfile
from pathlib import Path
from unittest.mock import patch

import pytest

# Configure logging for tests
logging.getLogger('odoo').setLevel(logging.WARNING)
logging.getLogger('werkzeug').setLevel(logging.ERROR)

# Test database configuration
TEST_DB_TEMPLATE = "test_pytest_{}"
ODOO_CONFIG_FILE = os.path.join(os.path.dirname(__file__), "local-odoo", "configs", "odoo-testing.conf")


@pytest.fixture(scope="session", autouse=True)
def setup_test_environment():
    """
    Session-wide setup for Odoo testing environment.
    Ensures proper configuration and environment setup.
    """
    # Set environment variables for testing
    os.environ.setdefault('ODOO_RC', ODOO_CONFIG_FILE)
    os.environ.setdefault('RUNNING_TESTS', '1')

    # Ensure test directories exist
    test_dirs = ['reports', 'tests/fixtures', 'tests/data', 'tests/temp']

    for test_dir in test_dirs:
        Path(test_dir).mkdir(parents=True, exist_ok=True)

    yield

    # Cleanup after all tests
    import shutil

    temp_dir = Path('tests/temp')
    if temp_dir.exists():
        shutil.rmtree(temp_dir)


@pytest.fixture(scope="session")
def odoo_env():
    """
    Session-wide Odoo environment fixture.
    Provides access to Odoo registry and environment for tests.
    """
    try:
        import odoo
        from odoo import SUPERUSER_ID, api
        from odoo.tests.common import HOST, PORT, get_db_name

        # Initialize Odoo if not already done
        if not hasattr(odoo, 'registry'):
            odoo.tools.config.parse_config(['--config', ODOO_CONFIG_FILE, '--test-enable', '--stop-after-init'])

        db_name = get_db_name()
        registry = odoo.registry(db_name)

        with registry.cursor() as cr:
            env = api.Environment(cr, SUPERUSER_ID, {})
            yield env

    except ImportError:
        pytest.skip("Odoo not available for testing")


@pytest.fixture
def odoo_registry(odoo_env):
    """
    Odoo registry fixture for low-level registry access.
    """
    return odoo_env.registry


@pytest.fixture
def odoo_cr(odoo_env):
    """
    Database cursor fixture for direct SQL operations.
    """
    return odoo_env.cr


@pytest.fixture
def temp_dir():
    """
    Temporary directory fixture for test file operations.
    """
    with tempfile.TemporaryDirectory(dir='tests/temp') as tmpdir:
        yield Path(tmpdir)


@pytest.fixture
def sample_data():
    """
    Sample data fixture for consistent test data across tests.
    """
    return {
        'customer_data': {
            'name': 'Test Customer',
            'email': 'test@example.com',
            'phone': '+1-555-0123',
            'street': '123 Test St',
            'city': 'Test City',
            'state_id': False,
            'zip': '12345',
            'country_id': False,
        },
        'sale_order_data': {
            'partner_id': False,  # Will be set by test
            'name': 'Test Sale Order',
            'state': 'draft',
        },
        'product_data': {
            'name': 'Test Blind',
            'type': 'product',
            'list_price': 100.0,
            'standard_price': 50.0,
        },
    }


@pytest.fixture
def mock_external_api():
    """
    Mock external API calls for testing without dependencies.
    """
    with patch('requests.get') as mock_get, patch('requests.post') as mock_post:
        # Configure default responses
        mock_get.return_value.status_code = 200
        mock_get.return_value.json.return_value = {'status': 'success'}

        mock_post.return_value.status_code = 201
        mock_post.return_value.json.return_value = {'id': 123, 'status': 'created'}

        yield {'get': mock_get, 'post': mock_post}


@pytest.fixture
def rtp_customers_module(odoo_env):
    """
    Fixture for RTP Customers module testing.
    """
    try:
        return odoo_env['rtp.customer']
    except KeyError:
        pytest.skip("RTP Customers module not installed")


@pytest.fixture
def royal_textiles_module(odoo_env):
    """
    Fixture for Royal Textiles Sales module testing.
    """
    try:
        # Check if Royal Textiles module models are available
        sale_order = odoo_env['sale.order']
        installation = odoo_env.get('royal_textiles.installation')

        return {'sale_order': sale_order, 'installation': installation}
    except KeyError:
        pytest.skip("Royal Textiles Sales module not installed")


@pytest.fixture(autouse=True)
def setup_test_logging(caplog):
    """
    Configure logging for individual tests.
    """
    caplog.set_level(logging.INFO)

    # Suppress noisy Odoo logs during testing
    logging.getLogger('odoo.sql_db').setLevel(logging.WARNING)
    logging.getLogger('odoo.modules.loading').setLevel(logging.WARNING)


# Custom pytest markers for better test organization
def pytest_configure(config):
    """
    Custom pytest configuration and marker registration.
    """
    # Register custom markers
    markers = [
        "unit: Unit tests - test individual components in isolation",
        "integration: Integration tests - test component interactions",
        "functional: Functional tests - test complete user workflows",
        "performance: Performance tests - test system performance and load",
        "slow: Slow tests - tests that take more than 5 seconds",
        "fast: Fast tests - tests that complete in under 1 second",
        "database: Tests that require database access",
        "no_database: Tests that don't require database access",
        "webtest: Tests that use Odoo's WebTest framework",
        "security: Security-related tests",
        "models: Model-specific tests",
        "views: View-related tests",
        "controllers: Controller tests",
        "workflows: Business workflow tests",
        "rtp_customers: RTP Customers module tests",
        "royal_textiles_sales: Royal Textiles Sales module tests",
    ]

    for marker in markers:
        config.addinivalue_line("markers", marker)


def pytest_collection_modifyitems(config, items):
    """
    Modify test collection to add automatic markers and organize tests.
    """
    for item in items:
        # Add module-specific markers based on file path
        if "rtp_customers" in str(item.fspath):
            item.add_marker(pytest.mark.rtp_customers)
        elif "royal_textiles" in str(item.fspath):
            item.add_marker(pytest.mark.royal_textiles_sales)

        # Add database marker to tests that use Odoo environment
        if hasattr(item, 'fixturenames') and 'odoo_env' in item.fixturenames:
            item.add_marker(pytest.mark.database)

        # Add performance marker to tests with benchmark fixtures
        if hasattr(item, 'fixturenames') and any('benchmark' in f for f in item.fixturenames):
            item.add_marker(pytest.mark.performance)


def pytest_runtest_setup(item):
    """
    Setup for individual test runs.
    """
    # Skip database tests if no database available
    if item.get_closest_marker("database"):
        if not os.path.exists(ODOO_CONFIG_FILE):
            pytest.skip("Database configuration not available")


# Custom assertion helpers for Odoo testing
class OdooAssertions:
    """Custom assertion helpers for Odoo testing."""

    @staticmethod
    def assert_model_exists(env, model_name):
        """Assert that a model exists in the Odoo registry."""
        assert model_name in env.registry, f"Model {model_name} not found in registry"

    @staticmethod
    def assert_field_exists(env, model_name, field_name):
        """Assert that a field exists on a model."""
        model = env[model_name]
        assert hasattr(model, field_name), f"Field {field_name} not found on model {model_name}"

    @staticmethod
    def assert_record_count(recordset, expected_count):
        """Assert the number of records in a recordset."""
        actual_count = len(recordset)
        assert actual_count == expected_count, f"Expected {expected_count} records, got {actual_count}"


# Make assertions available in tests
@pytest.fixture
def odoo_assertions():
    """Fixture providing Odoo-specific assertion helpers."""
    return OdooAssertions()

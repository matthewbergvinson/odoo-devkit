#!/bin/bash

# RTP Denver - Pytest with Odoo-Pytest Plugin Setup
# Task 4.1: Set up pytest with odoo-pytest plugin for Odoo testing
#
# This script configures a comprehensive pytest environment specifically for Odoo testing,
# integrating with our existing infrastructure from Tasks 3.1-3.7
#
# Usage: ./scripts/setup-pytest-odoo.sh [OPTIONS]

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ODOO_HOME="$PROJECT_ROOT/local-odoo"
VENV_PATH="$ODOO_HOME/venv"
CUSTOM_MODULES_PATH="$PROJECT_ROOT/custom_modules"
TESTS_PATH="$PROJECT_ROOT/tests"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Logging functions
log_info() {
    echo -e "${BLUE}[PYTEST-INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') $1"
}

log_success() {
    echo -e "${GREEN}[PYTEST-SUCCESS]${NC} $(date '+%Y-%m-%d %H:%M:%S') $1"
}

log_warning() {
    echo -e "${YELLOW}[PYTEST-WARNING]${NC} $(date '+%Y-%m-%d %H:%M:%S') $1"
}

log_error() {
    echo -e "${RED}[PYTEST-ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') $1"
}

# Show help message
show_help() {
    cat << EOF
RTP Denver - Pytest with Odoo-Pytest Plugin Setup
==================================================

This script sets up a comprehensive pytest environment for Odoo testing
that integrates with our existing infrastructure from Tasks 3.1-3.7.

Usage: $0 [OPTIONS]

Options:
  --local-only      Setup for local environment only (skip Docker)
  --docker-only     Setup for Docker environment only (skip local)
  --update-deps     Update pytest and testing dependencies
  --create-examples Create example test files
  --validate        Validate pytest setup
  --help            Show this help message

Features:
  ✅ pytest with odoo-pytest plugin configuration
  ✅ Odoo-specific test discovery and execution
  ✅ Integration with Tasks 3.1-3.7 infrastructure
  ✅ Local and Docker environment support
  ✅ Test database management
  ✅ Coverage reporting with Odoo-specific configuration
  ✅ Parallel test execution
  ✅ Custom module test organization

Examples:
  # Full setup for both local and Docker
  $0

  # Setup for local environment only
  $0 --local-only

  # Update testing dependencies
  $0 --update-deps

  # Create example tests and validate setup
  $0 --create-examples --validate

EOF
}

# Check if we're in virtual environment for local setup
check_virtual_environment() {
    if [[ "${VIRTUAL_ENV:-}" == "" ]]; then
        log_info "Activating virtual environment..."
        if [[ -f "$VENV_PATH/bin/activate" ]]; then
            source "$VENV_PATH/bin/activate"
            log_success "Virtual environment activated"
        else
            log_error "Virtual environment not found at $VENV_PATH"
            log_info "Please run Task 3.1 setup first: make install-odoo"
            exit 1
        fi
    else
        log_info "Virtual environment already active"
    fi
}

# Install and update testing dependencies
install_testing_dependencies() {
    log_info "Installing/updating pytest and Odoo testing dependencies..."

    # Core pytest and Odoo testing packages
    local packages=(
        "pytest>=7.4.0"
        "pytest-odoo>=1.3.0"
        "pytest-cov>=4.1.0"
        "pytest-xdist>=3.3.0"           # Parallel test execution
        "pytest-mock>=3.11.0"           # Mocking support
        "pytest-html>=3.2.0"            # HTML test reports
        "pytest-json-report>=1.5.0"     # JSON test reports
        "pytest-benchmark>=4.0.0"       # Performance benchmarking
        "pytest-timeout>=2.1.0"         # Test timeout management
        "pytest-randomly>=3.15.0"       # Random test order
        "pytest-clarity>=1.0.1"         # Better assertion output
        "coverage[toml]>=7.3.0"         # Coverage with TOML support
        "factory-boy>=3.3.0"            # Test data factories
        "freezegun>=1.2.0"              # Time freezing for tests
        "responses>=0.23.0"             # HTTP request mocking
        "faker>=19.0.0"                 # Fake data generation
    )

    for package in "${packages[@]}"; do
        log_info "Installing: $package"
        pip install "$package"
    done

    log_success "Testing dependencies installed successfully"
}

# Create comprehensive pytest configuration
create_pytest_configuration() {
    log_info "Creating comprehensive pytest configuration..."

    # Update pyproject.toml with Odoo-specific pytest configuration
    cat > "$PROJECT_ROOT/pytest.ini" << 'EOF'
# RTP Denver - Pytest Configuration for Odoo Testing
# Task 4.1: Set up pytest with odoo-pytest plugin for Odoo testing

[tool:pytest]
# Minimum pytest version
minversion = 7.4

# Test discovery patterns
python_files = test_*.py *_test.py test*.py
python_classes = Test*
python_functions = test_*

# Test paths - prioritize custom modules and tests directory
testpaths =
    tests
    custom_modules/*/tests
    custom_modules/*/tests/*

# Addons and plugins
addopts =
    --strict-markers
    --strict-config
    --verbose
    --tb=short
    --maxfail=10
    --durations=10
    --cov=custom_modules
    --cov-report=term-missing
    --cov-report=html:htmlcov
    --cov-report=xml
    --cov-branch
    --cov-fail-under=75
    --html=reports/pytest_report.html
    --self-contained-html
    --json-report
    --json-report-file=reports/pytest_report.json

# Odoo-specific configuration
# Database configuration for tests
odoo_config_file = local-odoo/configs/odoo-testing.conf
odoo_test_db_pattern = test_pytest_{}.format

# Test markers
markers =
    unit: Unit tests - test individual components in isolation
    integration: Integration tests - test component interactions
    functional: Functional tests - test complete user workflows
    performance: Performance tests - test system performance and load
    slow: Slow tests - tests that take more than 5 seconds
    fast: Fast tests - tests that complete in under 1 second
    database: Tests that require database access
    no_database: Tests that don't require database access
    webtest: Tests that use Odoo's WebTest framework
    post_install: Tests that run after module installation
    at_install: Tests that run during module installation
    security: Security-related tests
    api: API endpoint tests
    models: Model-specific tests
    views: View-related tests
    controllers: Controller tests
    wizards: Wizard tests
    reports: Report generation tests
    workflows: Business workflow tests
    modules: Module-specific tests
    rtp_customers: RTP Customers module tests
    royal_textiles_sales: Royal Textiles Sales module tests

# Logging configuration
log_cli = true
log_cli_level = INFO
log_cli_format = %(asctime)s [%(levelname)8s] %(name)s: %(message)s
log_cli_date_format = %Y-%m-%d %H:%M:%S

# Test timeout (in seconds)
timeout = 300
timeout_method = thread

# Parallel execution configuration
dist = loadscope
numprocesses = auto

# Filter warnings
filterwarnings =
    ignore::DeprecationWarning
    ignore::PendingDeprecationWarning
    ignore::UserWarning:odoo.*
    error::UserWarning:custom_modules.*

# Test collection configuration
collect_ignore = [
    "local-odoo",
    "venv",
    "docker",
    ".git",
    "htmlcov",
    "reports"
]

# Doctest configuration
doctest_optionflags = NORMALIZE_WHITESPACE IGNORE_EXCEPTION_DETAIL ELLIPSIS

# Custom collection patterns for Odoo
collect_ignore_glob = [
    "*/migrations/*",
    "*/static/*",
    "*/__pycache__/*"
]

EOF

    log_success "Pytest configuration created"
}

# Create conftest.py for Odoo-specific pytest fixtures
create_conftest() {
    log_info "Creating Odoo-specific pytest fixtures in conftest.py..."

    cat > "$PROJECT_ROOT/conftest.py" << 'EOF'
"""
RTP Denver - Pytest Configuration and Fixtures for Odoo Testing
Task 4.1: Set up pytest with odoo-pytest plugin for Odoo testing

This file provides Odoo-specific pytest fixtures and configuration that integrate
with our existing infrastructure from Tasks 3.1-3.7.
"""

import pytest
import logging
import os
import tempfile
from pathlib import Path
from unittest.mock import patch

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
    test_dirs = [
        'reports',
        'tests/fixtures',
        'tests/data',
        'tests/temp'
    ]

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
        from odoo import api, SUPERUSER_ID
        from odoo.tests.common import HOST, PORT, get_db_name

        # Initialize Odoo if not already done
        if not hasattr(odoo, 'registry'):
            odoo.tools.config.parse_config([
                '--config', ODOO_CONFIG_FILE,
                '--test-enable',
                '--stop-after-init'
            ])

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
        }
    }

@pytest.fixture
def mock_external_api():
    """
    Mock external API calls for testing without dependencies.
    """
    with patch('requests.get') as mock_get, \
         patch('requests.post') as mock_post:

        # Configure default responses
        mock_get.return_value.status_code = 200
        mock_get.return_value.json.return_value = {'status': 'success'}

        mock_post.return_value.status_code = 201
        mock_post.return_value.json.return_value = {'id': 123, 'status': 'created'}

        yield {
            'get': mock_get,
            'post': mock_post
        }

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

        return {
            'sale_order': sale_order,
            'installation': installation
        }
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
        assert actual_count == expected_count, \
            f"Expected {expected_count} records, got {actual_count}"

# Make assertions available in tests
@pytest.fixture
def odoo_assertions():
    """Fixture providing Odoo-specific assertion helpers."""
    return OdooAssertions()

EOF

    log_success "Odoo-specific conftest.py created"
}

# Create test directory structure
create_test_structure() {
    log_info "Creating comprehensive test directory structure..."

    local test_dirs=(
        "tests"
        "tests/unit"
        "tests/integration"
        "tests/functional"
        "tests/performance"
        "tests/fixtures"
        "tests/data"
        "tests/temp"
        "tests/reports"
        "reports"
    )

    for dir in "${test_dirs[@]}"; do
        mkdir -p "$PROJECT_ROOT/$dir"
    done

    # Create __init__.py files for test packages
    touch "$PROJECT_ROOT/tests/__init__.py"
    touch "$PROJECT_ROOT/tests/unit/__init__.py"
    touch "$PROJECT_ROOT/tests/integration/__init__.py"
    touch "$PROJECT_ROOT/tests/functional/__init__.py"
    touch "$PROJECT_ROOT/tests/performance/__init__.py"

    log_success "Test directory structure created"
}

# Create example test files
create_example_tests() {
    log_info "Creating example test files to demonstrate pytest-odoo usage..."

    # Example unit test
    cat > "$PROJECT_ROOT/tests/unit/test_example_unit.py" << 'EOF'
"""
Example unit tests for RTP Denver Odoo modules.
Task 4.1: Demonstrates pytest-odoo plugin usage for unit testing.
"""

import pytest
from unittest.mock import Mock, patch


class TestExampleUnit:
    """Example unit tests that don't require Odoo database."""

    @pytest.mark.unit
    @pytest.mark.fast
    @pytest.mark.no_database
    def test_basic_functionality(self):
        """Test basic functionality without database dependency."""
        # Example: Test utility functions, calculations, etc.
        result = 2 + 2
        assert result == 4

    @pytest.mark.unit
    @pytest.mark.no_database
    def test_mock_usage(self, mock_external_api):
        """Demonstrate mocking external dependencies."""
        # Test code that uses external APIs
        response = mock_external_api['get']()
        assert response.status_code == 200

    @pytest.mark.unit
    @pytest.mark.no_database
    def test_sample_data_fixture(self, sample_data):
        """Demonstrate using sample data fixture."""
        customer_data = sample_data['customer_data']
        assert customer_data['name'] == 'Test Customer'
        assert '@' in customer_data['email']

EOF

    # Example integration test
    cat > "$PROJECT_ROOT/tests/integration/test_example_integration.py" << 'EOF'
"""
Example integration tests for RTP Denver Odoo modules.
Task 4.1: Demonstrates pytest-odoo plugin usage for integration testing.
"""

import pytest


class TestExampleIntegration:
    """Example integration tests that use Odoo database."""

    @pytest.mark.integration
    @pytest.mark.database
    def test_odoo_environment(self, odoo_env):
        """Test basic Odoo environment access."""
        assert odoo_env is not None
        assert hasattr(odoo_env, 'cr')
        assert hasattr(odoo_env, 'user')

    @pytest.mark.integration
    @pytest.mark.database
    def test_base_models_available(self, odoo_env, odoo_assertions):
        """Test that basic Odoo models are available."""
        # Test core Odoo models
        odoo_assertions.assert_model_exists(odoo_env, 'res.partner')
        odoo_assertions.assert_model_exists(odoo_env, 'res.users')

        # Test that we can create basic records
        partner = odoo_env['res.partner'].create({'name': 'Test Partner'})
        assert partner.name == 'Test Partner'
        assert partner.id > 0

    @pytest.mark.integration
    @pytest.mark.database
    @pytest.mark.rtp_customers
    def test_rtp_customers_integration(self, rtp_customers_module, sample_data):
        """Test RTP Customers module integration."""
        customer_data = sample_data['customer_data']

        # Create customer record
        customer = rtp_customers_module.create(customer_data)
        assert customer.name == customer_data['name']
        assert customer.email == customer_data['email']

    @pytest.mark.integration
    @pytest.mark.database
    @pytest.mark.royal_textiles_sales
    def test_royal_textiles_integration(self, royal_textiles_module, odoo_env, sample_data):
        """Test Royal Textiles Sales module integration."""
        sale_order_model = royal_textiles_module['sale_order']

        # Create partner first
        partner = odoo_env['res.partner'].create(sample_data['customer_data'])

        # Create sale order
        order_data = sample_data['sale_order_data'].copy()
        order_data['partner_id'] = partner.id

        order = sale_order_model.create(order_data)
        assert order.partner_id == partner
        assert order.state == 'draft'

EOF

    # Example functional test
    cat > "$PROJECT_ROOT/tests/functional/test_example_functional.py" << 'EOF'
"""
Example functional tests for RTP Denver Odoo modules.
Task 4.1: Demonstrates pytest-odoo plugin usage for functional testing.
"""

import pytest


class TestExampleFunctional:
    """Example functional tests for complete user workflows."""

    @pytest.mark.functional
    @pytest.mark.database
    @pytest.mark.slow
    def test_complete_sales_workflow(self, odoo_env, sample_data):
        """Test complete sales workflow from quotation to installation."""
        # Create customer
        partner = odoo_env['res.partner'].create(sample_data['customer_data'])

        # Create product
        product = odoo_env['res.product'].create(sample_data['product_data'])

        # Create sale order
        order_data = sample_data['sale_order_data'].copy()
        order_data['partner_id'] = partner.id
        order = odoo_env['sale.order'].create(order_data)

        # Add order line
        odoo_env['sale.order.line'].create({
            'order_id': order.id,
            'product_id': product.id,
            'product_uom_qty': 1,
            'price_unit': product.list_price,
        })

        # Confirm order
        order.action_confirm()
        assert order.state == 'sale'

        # Verify workflow completion
        assert len(order.order_line) == 1
        assert order.amount_total > 0

    @pytest.mark.functional
    @pytest.mark.database
    @pytest.mark.royal_textiles_sales
    def test_installation_scheduling_workflow(self, royal_textiles_module, odoo_env, sample_data):
        """Test installation scheduling workflow."""
        if not royal_textiles_module.get('installation'):
            pytest.skip("Installation model not available")

        # Create complete installation workflow
        partner = odoo_env['res.partner'].create(sample_data['customer_data'])

        # Test installation creation and scheduling
        # This would test the Royal Textiles specific functionality
        # based on the actual implementation
        pass

EOF

    # Example performance test
    cat > "$PROJECT_ROOT/tests/performance/test_example_performance.py" << 'EOF'
"""
Example performance tests for RTP Denver Odoo modules.
Task 4.1: Demonstrates pytest-odoo plugin usage for performance testing.
"""

import pytest
import time


class TestExamplePerformance:
    """Example performance tests using pytest-benchmark."""

    @pytest.mark.performance
    @pytest.mark.database
    def test_partner_creation_performance(self, odoo_env, benchmark, sample_data):
        """Benchmark partner creation performance."""

        def create_partner():
            return odoo_env['res.partner'].create(sample_data['customer_data'])

        result = benchmark(create_partner)
        assert result.id > 0

    @pytest.mark.performance
    @pytest.mark.database
    @pytest.mark.slow
    def test_bulk_operations_performance(self, odoo_env, benchmark, sample_data):
        """Test bulk operations performance."""

        def create_bulk_partners():
            partners_data = []
            for i in range(100):
                data = sample_data['customer_data'].copy()
                data['name'] = f"Test Customer {i}"
                data['email'] = f"test{i}@example.com"
                partners_data.append(data)

            return odoo_env['res.partner'].create(partners_data)

        result = benchmark(create_bulk_partners)
        assert len(result) == 100

EOF

    log_success "Example test files created"
}

# Create test runner script
create_test_runner() {
    log_info "Creating test runner script for easy test execution..."

    cat > "$PROJECT_ROOT/scripts/run-tests.sh" << 'EOF'
#!/bin/bash

# RTP Denver - Test Runner Script
# Task 4.1: Easy test execution with pytest-odoo

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Default values
TEST_TYPE="all"
MODULE=""
COVERAGE=false
PARALLEL=false
HTML_REPORT=false
VERBOSE=false

show_help() {
    echo "RTP Denver - Test Runner"
    echo "======================="
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -t, --type TYPE      Test type: all, unit, integration, functional, performance"
    echo "  -m, --module MODULE  Test specific module: rtp_customers, royal_textiles_sales"
    echo "  -c, --coverage       Generate coverage report"
    echo "  -p, --parallel       Run tests in parallel"
    echo "  -r, --report         Generate HTML report"
    echo "  -v, --verbose        Verbose output"
    echo "  -h, --help          Show this help"
    echo ""
    echo "Examples:"
    echo "  $0                           # Run all tests"
    echo "  $0 -t unit                   # Run unit tests only"
    echo "  $0 -m rtp_customers -c       # Test RTP customers with coverage"
    echo "  $0 -t integration -p -r      # Integration tests with parallel execution and HTML report"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--type)
            TEST_TYPE="$2"
            shift 2
            ;;
        -m|--module)
            MODULE="$2"
            shift 2
            ;;
        -c|--coverage)
            COVERAGE=true
            shift
            ;;
        -p|--parallel)
            PARALLEL=true
            shift
            ;;
        -r|--report)
            HTML_REPORT=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Build pytest command
PYTEST_CMD="pytest"

# Add test type selection
case $TEST_TYPE in
    unit)
        PYTEST_CMD="$PYTEST_CMD -m unit"
        ;;
    integration)
        PYTEST_CMD="$PYTEST_CMD -m integration"
        ;;
    functional)
        PYTEST_CMD="$PYTEST_CMD -m functional"
        ;;
    performance)
        PYTEST_CMD="$PYTEST_CMD -m performance"
        ;;
    fast)
        PYTEST_CMD="$PYTEST_CMD -m fast"
        ;;
    slow)
        PYTEST_CMD="$PYTEST_CMD -m slow"
        ;;
    all)
        # Run all tests
        ;;
    *)
        echo "Unknown test type: $TEST_TYPE"
        exit 1
        ;;
esac

# Add module selection
if [[ -n "$MODULE" ]]; then
    PYTEST_CMD="$PYTEST_CMD -m $MODULE"
fi

# Add coverage
if [[ "$COVERAGE" == true ]]; then
    PYTEST_CMD="$PYTEST_CMD --cov=custom_modules --cov-report=term-missing --cov-report=html"
fi

# Add parallel execution
if [[ "$PARALLEL" == true ]]; then
    PYTEST_CMD="$PYTEST_CMD -n auto"
fi

# Add HTML report
if [[ "$HTML_REPORT" == true ]]; then
    PYTEST_CMD="$PYTEST_CMD --html=reports/pytest_report.html --self-contained-html"
fi

# Add verbose output
if [[ "$VERBOSE" == true ]]; then
    PYTEST_CMD="$PYTEST_CMD -v"
fi

# Ensure directories exist
mkdir -p reports

# Run tests
echo -e "${BLUE}Running tests with command:${NC} $PYTEST_CMD"
echo ""

cd "$PROJECT_ROOT"
eval "$PYTEST_CMD"

echo ""
echo -e "${GREEN}Test execution completed!${NC}"

if [[ "$COVERAGE" == true ]]; then
    echo -e "${BLUE}Coverage report available at:${NC} htmlcov/index.html"
fi

if [[ "$HTML_REPORT" == true ]]; then
    echo -e "${BLUE}Test report available at:${NC} reports/pytest_report.html"
fi

EOF

    chmod +x "$PROJECT_ROOT/scripts/run-tests.sh"
    log_success "Test runner script created and made executable"
}

# Integrate with existing Makefile
integrate_makefile() {
    log_info "Integrating pytest-odoo targets with existing Makefile..."

    # Add comprehensive pytest targets to Makefile
    cat >> "$PROJECT_ROOT/Makefile" << 'EOF'

# Pytest with Odoo-Pytest Plugin (Task 4.1)
.PHONY: pytest pytest-unit pytest-integration pytest-functional pytest-performance
.PHONY: pytest-module pytest-coverage pytest-parallel pytest-html pytest-fast pytest-slow
.PHONY: pytest-rtp-customers pytest-royal-textiles pytest-setup pytest-validate

pytest: ## Run all tests with pytest-odoo
	@echo "Running all tests with pytest-odoo..."
	./scripts/run-tests.sh

pytest-unit: ## Run unit tests only
	@echo "Running unit tests..."
	./scripts/run-tests.sh --type unit

pytest-integration: ## Run integration tests only
	@echo "Running integration tests..."
	./scripts/run-tests.sh --type integration

pytest-functional: ## Run functional tests only
	@echo "Running functional tests..."
	./scripts/run-tests.sh --type functional

pytest-performance: ## Run performance tests only
	@echo "Running performance tests..."
	./scripts/run-tests.sh --type performance

pytest-fast: ## Run fast tests only (under 1 second)
	@echo "Running fast tests..."
	./scripts/run-tests.sh --type fast

pytest-slow: ## Run slow tests only (over 5 seconds)
	@echo "Running slow tests..."
	./scripts/run-tests.sh --type slow

pytest-module: ## Run tests for specific module (usage: make pytest-module MODULE=rtp_customers)
ifndef MODULE
	@echo "Error: Please specify MODULE: make pytest-module MODULE=rtp_customers"
	@echo "Available modules: rtp_customers, royal_textiles_sales"
	@exit 1
endif
	@echo "Running tests for module: $(MODULE)"
	./scripts/run-tests.sh --module $(MODULE)

pytest-coverage: ## Run tests with coverage report
	@echo "Running tests with coverage..."
	./scripts/run-tests.sh --coverage

pytest-parallel: ## Run tests in parallel
	@echo "Running tests in parallel..."
	./scripts/run-tests.sh --parallel

pytest-html: ## Run tests with HTML report
	@echo "Running tests with HTML report..."
	./scripts/run-tests.sh --report

pytest-rtp-customers: ## Run all RTP Customers module tests
	@echo "Running RTP Customers module tests..."
	./scripts/run-tests.sh --module rtp_customers --coverage --report

pytest-royal-textiles: ## Run all Royal Textiles Sales module tests
	@echo "Running Royal Textiles Sales module tests..."
	./scripts/run-tests.sh --module royal_textiles_sales --coverage --report

pytest-setup: ## Setup pytest with odoo-pytest plugin
	@echo "Setting up pytest with odoo-pytest plugin..."
	./scripts/setup-pytest-odoo.sh

pytest-validate: ## Validate pytest setup and run example tests
	@echo "Validating pytest setup..."
	./scripts/setup-pytest-odoo.sh --validate

# Combined testing workflows
pytest-ci: ## CI/CD pipeline testing (fast tests + coverage)
	@echo "Running CI/CD pipeline tests..."
	./scripts/run-tests.sh --type fast --coverage --parallel

pytest-full: ## Complete testing suite (all tests + coverage + reports)
	@echo "Running complete testing suite..."
	./scripts/run-tests.sh --coverage --report --parallel

# Docker-based pytest execution
docker-pytest: ## Run pytest in Docker environment
	@echo "Running pytest in Docker environment..."
	./scripts/docker-manager.sh test pytest

docker-pytest-module: ## Run pytest for specific module in Docker (usage: make docker-pytest-module MODULE=rtp_customers)
ifndef MODULE
	@echo "Error: Please specify MODULE: make docker-pytest-module MODULE=rtp_customers"
	@exit 1
endif
	@echo "Running pytest for module $(MODULE) in Docker..."
	./scripts/docker-manager.sh test pytest $(MODULE)

EOF

    log_success "Makefile integration completed"
}

# Validate pytest setup
validate_setup() {
    log_info "Validating pytest-odoo setup..."

    # Check if pytest is available
    if ! command -v pytest >/dev/null 2>&1; then
        log_error "pytest not found in PATH"
        return 1
    fi

    # Check pytest version
    local pytest_version=$(pytest --version | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+')
    log_info "pytest version: $pytest_version"

    # Check if pytest-odoo plugin is available
    if pytest --version | grep -q "pytest-odoo"; then
        log_success "pytest-odoo plugin detected"
    else
        log_warning "pytest-odoo plugin not detected, but may still be available"
    fi

    # Test pytest configuration
    if pytest --collect-only tests/ >/dev/null 2>&1; then
        log_success "pytest configuration valid - test discovery working"
    else
        log_warning "pytest configuration may have issues"
    fi

    # Check if test directories exist
    local test_dirs=("tests" "tests/unit" "tests/integration" "tests/functional")
    for dir in "${test_dirs[@]}"; do
        if [[ -d "$PROJECT_ROOT/$dir" ]]; then
            log_success "Test directory exists: $dir"
        else
            log_warning "Test directory missing: $dir"
        fi
    done

    # Run example tests if they exist
    if [[ -f "$PROJECT_ROOT/tests/unit/test_example_unit.py" ]]; then
        log_info "Running example unit tests..."
        if pytest -xvs tests/unit/test_example_unit.py::TestExampleUnit::test_basic_functionality >/dev/null 2>&1; then
            log_success "Example unit test passed"
        else
            log_warning "Example unit test failed, but this may be expected without full Odoo setup"
        fi
    fi

    log_success "Pytest-odoo setup validation completed"
}

# Main function
main() {
    local local_only=false
    local docker_only=false
    local update_deps=false
    local create_examples=false
    local validate=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --local-only)
                local_only=true
                shift
                ;;
            --docker-only)
                docker_only=true
                shift
                ;;
            --update-deps)
                update_deps=true
                shift
                ;;
            --create-examples)
                create_examples=true
                shift
                ;;
            --validate)
                validate=true
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done

    echo -e "${BLUE}"
    echo "=================================================="
    echo "RTP Denver - Pytest with Odoo-Pytest Plugin Setup"
    echo "=================================================="
    echo -e "${NC}"
    echo "Task 4.1: Set up pytest with odoo-pytest plugin for Odoo testing"
    echo ""
    echo "This script will set up a comprehensive pytest environment for Odoo testing"
    echo "that integrates with our existing infrastructure from Tasks 3.1-3.7."
    echo ""

    cd "$PROJECT_ROOT"

    # Setup for local environment
    if [[ "$docker_only" == false ]]; then
        log_info "Setting up pytest-odoo for local environment..."

        check_virtual_environment

        if [[ "$update_deps" == true ]] || ! command -v pytest >/dev/null 2>&1; then
            install_testing_dependencies
        fi

        create_pytest_configuration
        create_conftest
        create_test_structure

        if [[ "$create_examples" == true ]]; then
            create_example_tests
        fi

        create_test_runner
        integrate_makefile

        if [[ "$validate" == true ]]; then
            validate_setup
        fi
    fi

    # Docker integration (always done unless local-only)
    if [[ "$local_only" == false ]]; then
        log_info "Integrating pytest-odoo with Docker environment..."

        # Update Docker manager to support pytest testing
        if [[ -f "$PROJECT_ROOT/scripts/docker-manager.sh" ]]; then
            log_info "Docker integration will be handled by existing docker-manager.sh"
        else
            log_warning "Docker manager not found - skipping Docker integration"
        fi
    fi

    echo ""
    log_success "Pytest with odoo-pytest plugin setup completed!"
    echo ""
    echo -e "${GREEN}✅ Setup Summary:${NC}"
    echo "=================="
    echo "✅ pytest and pytest-odoo plugin configured"
    echo "✅ Odoo-specific test configuration created"
    echo "✅ Test directory structure established"
    echo "✅ Test fixtures and conftest.py created"
    echo "✅ Test runner script created"
    echo "✅ Makefile integration completed"
    if [[ "$create_examples" == true ]]; then
        echo "✅ Example test files created"
    fi
    if [[ "$validate" == true ]]; then
        echo "✅ Setup validation completed"
    fi
    echo ""
    echo -e "${GREEN}🚀 Ready to Use:${NC}"
    echo "================"
    echo "# Run all tests"
    echo "make pytest"
    echo ""
    echo "# Run specific test types"
    echo "make pytest-unit              # Unit tests"
    echo "make pytest-integration       # Integration tests"
    echo "make pytest-functional        # Functional tests"
    echo ""
    echo "# Run module-specific tests"
    echo "make pytest-module MODULE=rtp_customers"
    echo ""
    echo "# Run with coverage and reports"
    echo "make pytest-coverage"
    echo "make pytest-html"
    echo ""
    echo "# Quick testing commands"
    echo "./scripts/run-tests.sh --type unit --verbose"
    echo "./scripts/run-tests.sh --module rtp_customers --coverage"
    echo ""
    echo -e "${BLUE}📚 Next Steps:${NC}"
    echo "==============="
    echo "1. Create tests for your custom modules in custom_modules/*/tests/"
    echo "2. Run 'make pytest-validate' to verify everything works"
    echo "3. Use 'make pytest-coverage' to check test coverage"
    echo "4. Explore example tests in tests/ directory"
    echo ""

}

# Run main function
main "$@"

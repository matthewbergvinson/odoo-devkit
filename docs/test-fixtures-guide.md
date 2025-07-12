# Royal Textiles Sales - Test Fixtures and Factories Guide

## Task 4.4: Test Data Fixtures and Factories for Consistent Test Scenarios

This guide covers the comprehensive test fixture system created for the Royal Textiles Sales module. The system provides realistic, consistent test data for all testing scenarios.

## 📚 Table of Contents

1. [System Overview](#system-overview)
2. [Quick Start](#quick-start)
3. [Factory Classes](#factory-classes)
4. [Scenario Fixtures](#scenario-fixtures)
5. [Realistic Data](#realistic-data)
6. [Maintenance Tools](#maintenance-tools)
7. [Best Practices](#best-practices)
8. [Usage Examples](#usage-examples)
9. [Performance Considerations](#performance-considerations)

## 🎯 System Overview

Our fixture system follows modern best practices for test data management:

- **Factory Pattern**: Generate data programmatically instead of static files
- **Realistic Data**: Business-domain-specific data that matches real-world scenarios
- **Scenario-based**: Pre-built fixtures for common testing situations
- **Maintainable**: Tools for keeping fixtures current with codebase changes
- **Performance-aware**: Optimized for both speed and memory usage

### Architecture

```
tests/fixtures/
├── __init__.py          # Package exports and imports
├── realistic_data.py    # Business-specific realistic data
├── factories.py         # Factory classes for data generation
├── scenarios.py         # Pre-built scenario fixtures
└── maintenance.py       # Validation and cleanup utilities
```

## 🚀 Quick Start

### Basic Factory Usage

```python
from tests.fixtures import CustomerFactory, ProductFactory, SaleOrderFactory

# Create a single customer
customer_factory = CustomerFactory(env)
customer = customer_factory.create('residential')

# Create multiple products
product_factory = ProductFactory(env)
products = product_factory.create_batch(5, 'blinds')

# Create a complete order
order_factory = SaleOrderFactory(env)
order = order_factory.create_confirmed_order('typical')
```

### Pre-built Scenarios

```python
from tests.fixtures import create_simple_scenario, create_complex_scenario

# Simple residential order
simple_data = create_simple_scenario(env)
customer = simple_data['customer']
order = simple_data['sale_order']
installation = simple_data['installation']

# Complex commercial scenario
complex_data = create_complex_scenario(env)
# Contains multiple installations, integrations, etc.
```

### Test Data Manager

```python
from tests.fixtures import TestDataManager

# Central manager for all factories
manager = TestDataManager(env)

# Create complete business scenario
scenario = manager.create_complete_scenario('typical')

# Bulk data for performance testing
bulk_data = manager.create_performance_test_data(order_count=100)

# Clean up everything
manager.cleanup_all()
```

## 🏭 Factory Classes

### CustomerFactory

Creates realistic customer records with proper address and contact information.

```python
customer_factory = CustomerFactory(env)

# Basic usage
customer = customer_factory.create('residential')

# Specific customer types
residential = customer_factory.create_residential()
commercial = customer_factory.create_commercial()
hospitality = customer_factory.create_hospitality()

# Batch creation
customers = customer_factory.create_batch(10, 'commercial')

# With overrides
vip_customer = customer_factory.create('residential',
                                     name='VIP Customer',
                                     email='vip@example.com')
```

**Customer Types:**
- `residential`: Home customers (Johnson Family, Martinez Home, etc.)
- `commercial`: Business customers (Denver Medical Center, Tech Innovation Hub)
- `hospitality`: Hotels and resorts (Grand Mountain Resort, Aspen Luxury Lodge)

### ProductFactory

Creates product records matching our window treatments catalog.

```python
product_factory = ProductFactory(env)

# Product types
blind = product_factory.create_blind()
shade = product_factory.create_shade()
motorized = product_factory.create_motorized()
service = product_factory.create_service()

# Complete catalog
catalog = product_factory.create_product_catalog()
# Returns: {'blind': product, 'shade': product, 'motorized': product, 'service': product}

# Custom product
custom_blind = product_factory.create('blinds',
                                    name='Custom Blind Design',
                                    list_price=299.99)
```

**Product Categories:**
- `blinds`: Faux wood, aluminum, venetian, vertical blinds
- `shades`: Cellular, roller, roman, bamboo shades
- `motorized`: Smart WiFi, battery, hardwired motorized products
- `services`: Installation, consultation, upgrade services

### SaleOrderFactory

Creates sale orders with realistic order lines and product combinations.

```python
order_factory = SaleOrderFactory(env)

# Scenario-based orders
simple_order = order_factory.create_simple_order()      # 3 blinds + 1 service
typical_order = order_factory.create_typical_order()    # Mixed products
complex_order = order_factory.create_complex_order()    # 8+ products with motorized

# Confirmed orders ready for workflow
confirmed = order_factory.create_confirmed_order('typical')

# Custom scenario
order = order_factory.create('commercial',
                            customer=existing_customer,
                            products=existing_catalog)
```

**Order Scenarios:**
- `simple`: 2-4 products, residential customer, 2.5 hours estimated
- `typical`: 3-8 mixed products, 4.0 hours estimated
- `complex`: 8+ products with motorized, commercial customer, 8.5+ hours
- `commercial`: Large commercial installation, 15+ products
- `bulk`: Property management bulk order, 25+ products

### InstallationFactory

Creates installation records with proper workflow relationships.

```python
installation_factory = InstallationFactory(env)

# Installation types
residential = installation_factory.create_residential()      # 2 hours
commercial = installation_factory.create_commercial()        # 6 hours
complex = installation_factory.create_complex()              # 10+ hours with special requirements

# Workflow states
in_progress = installation_factory.create_in_progress()
completed = installation_factory.create_completed()

# Custom installation
custom = installation_factory.create('complex_motorized',
                                    sale_order=existing_order,
                                    estimated_hours=12.0)
```

**Installation Scenarios:**
- `quick_residential`: 2 hours, simple setup
- `standard_commercial`: 6 hours, weekend/after-hours scheduling
- `complex_motorized`: 10+ hours, electrical work, WiFi configuration
- `bulk_property`: 16+ hours, multi-unit coordination

## 📋 Scenario Fixtures

Pre-built scenarios combine multiple factories for complete testing situations.

### SimpleOrderScenario

**Use Case**: Basic functionality testing, form validation, simple workflows

```python
from tests.fixtures import SimpleOrderScenario

scenario = SimpleOrderScenario(env)
data = scenario.create()

# Contains:
# - 1 residential customer
# - 4 products (catalog)
# - 1 simple order (3 blinds + 1 service)
# - 1 residential installation
# - Metadata about scenario complexity and use cases
```

### ComplexOrderScenario

**Use Case**: Advanced business logic, module integration, performance testing

```python
from tests.fixtures import ComplexOrderScenario

scenario = ComplexOrderScenario(env)
data = scenario.create()

# Contains:
# - 1 commercial customer
# - 4 products (catalog)
# - 1 complex order (8 blinds + 4 shades + 2 motorized + 2 services)
# - 2 installations (primary + additional)
# - Integration points (sales, project, calendar modules)
```

### BulkTestingScenario

**Use Case**: Performance testing, bulk operations, stress testing

```python
from tests.fixtures import BulkTestingScenario

scenario = BulkTestingScenario(env)
data = scenario.create(customer_count=20, order_count=50)

# Contains:
# - 20 customers (mixed types)
# - 1 shared product catalog
# - 50 orders (varying complexity)
# - 25 installations
# - Performance metrics and targets
```

### ErrorTestingScenario

**Use Case**: Validation testing, error handling, edge cases

```python
from tests.fixtures import ErrorTestingScenario

scenario = ErrorTestingScenario(env)
data = scenario.create()

# Contains:
# - Valid base data for comparison
# - Edge case customers (very long names, minimal data)
# - Invalid orders (empty order lines)
# - Invalid installations (negative hours, past dates)
# - Error scenarios documentation
```

### PerformanceTestingScenario

**Use Case**: Performance benchmarking, scalability analysis

```python
from tests.fixtures import PerformanceTestingScenario

scenario = PerformanceTestingScenario(env)
data = scenario.create(scale_factor=2)  # 2x baseline data volume

# Contains:
# - Scaled data volumes
# - Completed installations for realistic status distribution
# - Performance targets and benchmark operations
# - Memory usage monitoring points
```

### WorkflowTestingScenario

**Use Case**: End-to-end testing, status transitions, integration points

```python
from tests.fixtures import WorkflowTestingScenario

scenario = WorkflowTestingScenario(env)
data = scenario.create()

# Contains:
# - Orders at different workflow stages (draft, confirmed)
# - Installations at different statuses (scheduled, in-progress, completed)
# - Workflow step tracking
# - Integration touchpoints
```

## 📊 Realistic Data

Our fixtures use business-domain-specific realistic data instead of generic test data.

### Customer Data

**Residential Customers:**
- Johnson Family Residence, Martinez Home Design, Wilson Family Trust
- Colorado addresses (Denver, Boulder, Colorado Springs, Fort Collins)
- Realistic phone numbers and email patterns

**Commercial Customers:**
- Denver Medical Center, Tech Innovation Hub, Cherry Creek Shopping District
- Business addresses and corporate email patterns

**Hospitality Customers:**
- Grand Mountain Resort, Aspen Luxury Lodge, Vail Conference Center
- Tourism-focused locations

### Product Catalog

**Realistic Products with Proper Pricing:**
- Premium 2" Faux Wood Blinds - White ($185.00 list, $92.50 cost)
- Smart Motorized Roller Shades - WiFi Enabled ($485.00 list)
- Professional Installation Service ($125.00)

**Installation Time Multipliers:**
- Blinds: 1.0-1.4x base time (depending on complexity)
- Shades: 0.7-1.1x base time (faster installation)
- Motorized: 2.0-2.5x base time (complex setup)
- Services: 0.5-1.5x base time (varies by service)

### Geographic Data

All addresses use real Colorado locations:
- Denver (80202), Colorado Springs (80903), Boulder (80301)
- Fort Collins (80521), Aurora (80012), Lakewood (80226)
- Proper state and country references

## 🔧 Maintenance Tools

### FixtureValidator

Validates that all fixtures create valid data and maintain consistency.

```python
from tests.fixtures.maintenance import FixtureValidator

validator = FixtureValidator(env)
results = validator.validate_all()

print(f"Summary: {results['summary']}")
# Output: "All 6 scenarios passed validation ✓"

# Detailed results
for scenario_name, result in results['scenarios'].items():
    print(f"{scenario_name}: {result['status']}")
    print(f"  Records created: {result['records_created']}")
    print(f"  Creation time: {result['creation_time']:.2f}s")
```

### TestDataCleanup

Manages cleanup of test data and orphaned records.

```python
from tests.fixtures.maintenance import TestDataCleanup

cleanup = TestDataCleanup(env)

# Dry run to see what would be deleted
results = cleanup.cleanup_all_test_data(dry_run=True)
print(f"Would delete {results['total_deleted']} records")

# Actually delete test data
results = cleanup.cleanup_all_test_data(dry_run=False)

# Clean up old test data
cleanup.cleanup_old_test_data(days_old=7)
```

### FixtureUpdater

Checks compatibility with schema changes and updates.

```python
from tests.fixtures.maintenance import FixtureUpdater

updater = FixtureUpdater(env)
compatibility = updater.check_schema_compatibility()

if not compatibility['compatible']:
    print("Schema issues found:")
    for issue in compatibility['issues']:
        print(f"  - {issue}")

    print("Recommendations:")
    for rec in compatibility['recommendations']:
        print(f"  - {rec}")
```

### FixtureMetrics

Collects performance metrics for optimization.

```python
from tests.fixtures.maintenance import FixtureMetrics

metrics = FixtureMetrics(env)
performance = metrics.collect_performance_metrics()

print(f"Average creation time: {performance['summary']['average_create_time']:.2f}s")
print(f"Records per second: {performance['summary']['average_records_per_second']:.1f}")
```

## 📋 Best Practices

### 1. Use Appropriate Scenarios

```python
# ✅ Good: Use simple scenario for basic tests
def test_order_creation():
    data = create_simple_scenario(env)
    order = data['sale_order']
    # Test basic order functionality

# ✅ Good: Use complex scenario for integration tests
def test_multi_module_integration():
    data = create_complex_scenario(env)
    # Test sales + project + calendar integration

# ❌ Avoid: Using complex data for simple tests
def test_order_name_field():
    data = create_complex_scenario(env)  # Overkill for field test
    # Just test the name field
```

### 2. Clean Up After Tests

```python
# ✅ Good: Clean up in test teardown
def setUp(self):
    self.data_manager = TestDataManager(self.env)

def tearDown(self):
    self.data_manager.cleanup_all()

# ✅ Good: Use context managers for cleanup
class TestRoyalTextiles(BaseOdooModelTest):
    def test_with_automatic_cleanup(self):
        with TestDataManager(self.env) as manager:
            data = manager.create_complete_scenario('typical')
            # Test logic here
        # Automatic cleanup when exiting context
```

### 3. Customize vs Create New

```python
# ✅ Good: Customize existing scenarios
def test_specific_customer_type():
    data = create_simple_scenario(env,
                                customer_type='commercial',
                                estimated_hours=10.0)

# ✅ Good: Use factory methods for specific needs
def test_edge_case_product():
    factory = ProductFactory(env)
    product = factory.create('blinds',
                           name='Edge Case Product',
                           list_price=0.01)  # Very low price

# ❌ Avoid: Creating completely custom data when factories exist
def test_manual_data_creation():
    # Don't manually create customer records when factory exists
    customer = env['res.partner'].create({
        'name': 'Test Customer',  # Not realistic
        'email': 'test@test.com'  # Not realistic
    })
```

### 4. Performance Considerations

```python
# ✅ Good: Reuse data within test class
class TestOrderWorkflow(BaseOdooModelTest):
    @classmethod
    def setUpClass(cls):
        super().setUpClass()
        cls.manager = TestDataManager(cls.env)
        cls.scenario_data = cls.manager.create_complete_scenario('typical')

    def test_order_confirmation(self):
        order = self.scenario_data['sale_order']
        # Use shared data

    def test_installation_scheduling(self):
        installation = self.scenario_data['installation']
        # Use shared data

# ❌ Avoid: Creating new data for every test method
class TestOrderWorkflow(BaseOdooModelTest):
    def test_order_confirmation(self):
        data = create_complex_scenario(env)  # Expensive
        # Test logic

    def test_installation_scheduling(self):
        data = create_complex_scenario(env)  # Expensive again
        # Test logic
```

## 💡 Usage Examples

### Testing Business Logic

```python
class TestRoyalTextilesSalesBusinessLogic(BaseOdooModelTest):
    def setUp(self):
        super().setUp()
        self.manager = TestDataManager(self.env)

    def test_installation_time_calculation(self):
        """Test that installation time is calculated correctly."""
        # Create order with known products
        data = create_simple_scenario(self.env)
        order = data['sale_order']

        # Calculate expected time based on products
        expected_hours = 0
        for line in order.order_line:
            product = line.product_id
            if 'Blind' in product.name:
                expected_hours += line.product_uom_qty * 1.2  # Blind multiplier
            elif 'Shade' in product.name:
                expected_hours += line.product_uom_qty * 0.8  # Shade multiplier

        # Test the calculation
        actual_hours = order.calculate_installation_time()
        self.assertEqual(actual_hours, expected_hours)

    def tearDown(self):
        self.manager.cleanup_all()
        super().tearDown()
```

### Testing Error Conditions

```python
class TestValidationRules(BaseOdooModelTest):
    def test_empty_order_validation(self):
        """Test that orders without lines are rejected."""
        error_data = create_error_scenario(self.env)
        empty_order = error_data['error_orders'][0]

        with self.assertRaises(ValidationError):
            empty_order.action_schedule_installation()

    def test_negative_hours_validation(self):
        """Test that negative estimated hours are rejected."""
        error_data = create_error_scenario(self.env)

        for installation in error_data['error_installations']:
            if installation.estimated_hours < 0:
                with self.assertRaises(ValidationError):
                    installation.write({'status': 'scheduled'})
```

### Performance Testing

```python
class TestPerformance(BaseOdooModelTest):
    def test_bulk_order_creation_performance(self):
        """Test that bulk order creation meets performance targets."""
        start_time = time.time()

        # Create bulk data
        performance_data = create_performance_scenario(self.env, scale_factor=2)

        creation_time = time.time() - start_time
        order_count = len(performance_data['orders'])

        # Assert performance targets
        self.assertLess(creation_time, 60.0, "Bulk creation took too long")
        self.assertGreater(order_count / creation_time, 1.0, "Creation rate too slow")

        # Test search performance
        start_time = time.time()
        results = self.env['sale.order'].search([('state', '=', 'sale')])
        search_time = time.time() - start_time

        self.assertLess(search_time, 1.0, "Search took too long")
```

## 📈 Performance Considerations

### Memory Usage

Our fixtures are designed to be memory-efficient:

- **Lazy Loading**: Products and references are created only when needed
- **Shared References**: Common data (countries, states) are reused
- **Cleanup Tracking**: All created records are tracked for proper cleanup

### Creation Speed

Typical performance benchmarks:

- **Simple Scenario**: ~1-2 seconds, 6-8 records
- **Complex Scenario**: ~3-5 seconds, 15-20 records
- **Bulk Scenario**: ~30-60 seconds, 100+ records

### Optimization Tips

1. **Reuse Scenarios**: Create once per test class, not per test method
2. **Batch Operations**: Use `create_batch()` for multiple similar records
3. **Selective Cleanup**: Clean up only what you need
4. **Monitor Memory**: Use `FixtureMetrics` to track performance

## 🔍 Troubleshooting

### Common Issues

**Import Errors**
```python
# ❌ This fails
from tests.fixtures import NonExistentFactory

# ✅ Check available imports
from tests.fixtures import (
    CustomerFactory, ProductFactory, SaleOrderFactory,
    InstallationFactory, TestDataManager
)
```

**Schema Compatibility**
```python
# Check for schema issues
from tests.fixtures.maintenance import FixtureUpdater

updater = FixtureUpdater(env)
compatibility = updater.check_schema_compatibility()

if not compatibility['compatible']:
    # Handle schema issues
    for issue in compatibility['issues']:
        print(f"Schema issue: {issue}")
```

**Performance Issues**
```python
# Measure performance
from tests.fixtures.maintenance import FixtureMetrics

metrics = FixtureMetrics(env)
performance = metrics.collect_performance_metrics()

# Check for slow scenarios
for name, data in performance['scenarios'].items():
    if data.get('create_time', 0) > 5.0:
        print(f"Slow scenario: {name} took {data['create_time']:.2f}s")
```

### Validation Failures

```python
# Validate all fixtures
from tests.fixtures.maintenance import FixtureValidator

validator = FixtureValidator(env)
results = validator.validate_all()

if results['failed_scenarios'] > 0:
    for scenario_name, result in results['scenarios'].items():
        if result['status'] == 'failed':
            print(f"Failed scenario: {scenario_name}")
            for error in result.get('errors', []):
                print(f"  Error: {error}")
```

## 📚 Additional Resources

- **Base Test Classes**: See `tests/base_model_test.py` for inheritance patterns
- **Royal Textiles Models**: See `custom_modules/royal_textiles_sales/models/`
- **Test Examples**: See `tests/test_royal_textiles_*.py` for usage examples
- **Maintenance Scripts**: Use fixture maintenance tools for ongoing health

---

This comprehensive fixture system provides the foundation for reliable, maintainable testing of the Royal Textiles Sales module. The realistic data, factory patterns, and scenario-based approach ensure that tests are both meaningful and efficient.

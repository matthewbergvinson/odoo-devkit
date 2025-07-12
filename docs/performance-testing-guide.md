# Performance Testing Guide for Royal Textiles Sales Module

## Overview

Performance testing validates that the Royal Textiles Sales module performs efficiently under expected loads and meets response time requirements. This guide covers database operations, view rendering, memory management, and system resource optimization.

## Why Performance Testing Matters

In a production environment, Royal Textiles will accumulate thousands of customers, sales orders, and installations. Without performance testing, we might discover too late that:

- Customer lists take 30+ seconds to load with 10,000+ customers
- Sales order creation becomes slow due to inefficient relationship queries
- Installation reports timeout with large datasets
- The system becomes unusable during busy periods
- Memory leaks cause server crashes during high usage

## Performance Testing Categories

### 1. Database Performance Testing

**Purpose**: Validate database operation efficiency and query optimization.

**Test Coverage**:
- **CRUD Operations**: Single record create, read, update, delete performance
- **Bulk Operations**: Batch processing of 100+ records
- **Search Performance**: Simple, complex, and filtered searches
- **Relationship Queries**: Efficient loading without N+1 query problems
- **Reporting Queries**: Complex aggregations and business intelligence queries

**Performance Thresholds**:
```python
# Single operations
SINGLE_CREATE_MAX = 0.1s    # Customer creation
SINGLE_READ_MAX = 0.05s     # Customer lookup
SINGLE_UPDATE_MAX = 0.1s    # Customer modification
SINGLE_DELETE_MAX = 0.05s   # Customer removal

# Bulk operations
BULK_CREATE_100_MAX = 2.0s   # 100 customer creation
BULK_UPDATE_100_MAX = 1.5s   # 100 customer update
BULK_DELETE_100_MAX = 1.0s   # 100 customer deletion

# Search operations
SIMPLE_SEARCH_MAX = 0.2s     # Basic customer search
COMPLEX_SEARCH_MAX = 1.0s    # Multi-condition search
FILTERED_SEARCH_MAX = 0.5s   # In-memory filtering
```

**Key Test Scenarios**:
```python
def test_single_customer_crud_performance(self):
    """Test individual customer CRUD operations"""

    # CREATE performance
    with self.measure_performance('customer_create') as metrics:
        customer = self.env['res.partner'].create({
            'name': 'Performance Test Customer',
            'email': 'perf@test.com',
            'customer_rank': 1,
        })

    self.assert_performance_threshold(
        metrics, self.thresholds.SINGLE_CREATE_MAX, 'customer_create'
    )
```

### 2. View Performance Testing

**Purpose**: Validate view rendering performance and user interface responsiveness.

**Test Coverage**:
- **Form Views**: Customer, sales order, and installation form rendering
- **List Views**: Large dataset pagination and field loading
- **Kanban Views**: Card-based view performance with relationships
- **Search Views**: Filter and sorting performance
- **Dashboard Views**: Multi-widget data loading
- **Pivot Views**: Complex aggregation and reporting views

**Performance Thresholds**:
```python
# View rendering thresholds
FORM_VIEW_RENDER_MAX = 0.3s      # Form view rendering
LIST_VIEW_RENDER_MAX = 0.5s      # List view (80 records)
KANBAN_VIEW_RENDER_MAX = 0.4s    # Kanban view rendering
```

**Key Test Scenarios**:
```python
def test_customer_list_view_performance(self):
    """Test customer list view rendering performance"""

    with self.measure_performance('customer_list_view_80') as metrics:
        customers = self.env['res.partner'].search([
            ('customer_rank', '>', 0)
        ], limit=80)

        # Simulate list view field loading
        list_data = customers.read([
            'name', 'email', 'phone', 'city', 'country_id'
        ])

    self.assert_performance_threshold(
        metrics, self.thresholds.LIST_VIEW_RENDER_MAX, 'customer_list_view_80'
    )
```

### 3. Memory Performance Testing

**Purpose**: Validate memory efficiency and prevent memory leaks.

**Test Coverage**:
- **Memory Usage Monitoring**: Track memory growth during operations
- **Memory Leak Detection**: Identify unreleased resources
- **Garbage Collection**: Validate GC efficiency
- **Cache Management**: Odoo cache memory optimization
- **Concurrent Access**: Memory usage under simulated load

**Performance Thresholds**:
```python
# Memory thresholds
MEMORY_GROWTH_MAX = 50.0   # 50MB max growth per operation
TOTAL_MEMORY_MAX = 500.0   # 500MB total memory usage
```

**Key Test Scenarios**:
```python
def test_memory_leak_detection(self):
    """Test for memory leaks during repetitive operations"""

    baseline_memory = self.process.memory_info().rss / 1024 / 1024
    memory_snapshots = []

    # Perform repetitive operations and monitor memory growth
    for iteration in range(10):
        # Create and delete customers repeatedly
        customers = self.env['res.partner'].create([{...}])
        customers.unlink()
        gc.collect()

        current_memory = self.process.memory_info().rss / 1024 / 1024
        memory_snapshots.append(current_memory - baseline_memory)

    # Validate no consistent memory growth (leak detection)
    self.assertLess(avg_recent - avg_early, 20.0, "Memory leak detected")
```

## Test Execution Strategies

### 1. Basic Performance Testing

Run all performance tests:
```bash
make test-performance
```

Run specific test categories:
```bash
make test-database-performance    # Database operations
make test-view-performance        # View rendering
make test-memory-performance      # Memory usage
```

### 2. CI/CD Integration

Optimized for continuous integration:
```bash
make test-performance-ci          # Fast, essential tests
make test-performance-smoke       # Quick validation
```

### 3. Comprehensive Analysis

Full performance analysis workflow:
```bash
make test-performance-full        # Complete workflow with reports
make test-performance-benchmark   # Detailed benchmarking
make test-performance-monitor     # System resource monitoring
```

### 4. Load Testing

Simulate concurrent user load:
```bash
make test-performance-load        # Concurrent operations
make test-performance-parallel    # Parallel test execution
```

## Performance Test Infrastructure

### Base Performance Test Class

All performance tests inherit from `BasePerformanceTest`:

```python
from tests.performance.base_performance_test import BasePerformanceTest

@tagged('performance', 'database')
class TestDatabasePerformance(BasePerformanceTest):

    def test_customer_performance(self):
        with self.measure_performance('customer_create') as metrics:
            # Perform operation
            customer = self.env['res.partner'].create({...})

        # Assert performance thresholds
        self.assert_performance_threshold(
            metrics, 0.1, 'customer_create'
        )
        self.assert_memory_threshold(
            metrics, 10.0, 'customer_create'
        )
```

### Performance Measurement Tools

**Execution Time Measurement**:
```python
with self.measure_performance('operation_name') as metrics:
    # Perform operation
    result = expensive_operation()

# Access metrics
execution_time = metrics.execution_time
memory_growth = metrics.memory_usage['growth_mb']
database_queries = metrics.database_queries
```

**Function Benchmarking**:
```python
def test_function_benchmark(self):
    def operation_to_benchmark():
        return self.env['res.partner'].search([('customer_rank', '>', 0)])

    stats = self.benchmark_function(operation_to_benchmark, iterations=10)

    self.assertLess(stats['mean'], 0.1, "Average execution too slow")
    self.assertLess(stats['std_dev'], 0.05, "Performance too variable")
```

**Concurrent Load Simulation**:
```python
def test_concurrent_operations(self):
    operations = [
        lambda: self.create_customer(),
        lambda: self.search_customers(),
        lambda: self.update_customer(),
    ]

    results = self.simulate_user_load(operations, concurrent_users=5)

    self.assertLess(results['mean_response_time'], 0.5)
    self.assertLess(results['max_response_time'], 2.0)
```

## Performance Optimization Strategies

### 1. Database Optimization

**Efficient Bulk Operations**:
```python
# GOOD: Bulk create
customers = self.env['res.partner'].create([
    {'name': f'Customer {i}', 'customer_rank': 1}
    for i in range(100)
])

# BAD: Individual creates
for i in range(100):
    self.env['res.partner'].create({
        'name': f'Customer {i}',
        'customer_rank': 1
    })
```

**Avoid N+1 Queries**:
```python
# GOOD: Efficient relationship loading
customers = self.env['res.partner'].search([('customer_rank', '>', 0)])
orders = customers.mapped('sale_order_ids')  # Single query

# BAD: N+1 query pattern
customers = self.env['res.partner'].search([('customer_rank', '>', 0)])
for customer in customers:
    orders = customer.sale_order_ids  # Query per customer
```

**Optimized Search Operations**:
```python
# GOOD: Database-level filtering
customers = self.env['res.partner'].search([
    ('customer_rank', '>', 0),
    ('city', '=', 'Denver'),
    ('create_date', '>=', date_threshold)
])

# BAD: In-memory filtering
all_customers = self.env['res.partner'].search([('customer_rank', '>', 0)])
denver_customers = all_customers.filtered(lambda c: c.city == 'Denver')
```

### 2. Memory Optimization

**Efficient Data Processing**:
```python
# GOOD: Process in chunks
chunk_size = 100
for i in range(0, len(large_dataset), chunk_size):
    chunk = large_dataset[i:i + chunk_size]
    process_chunk(chunk)

# BAD: Load everything into memory
all_data = large_dataset.read(['all', 'fields'])
process_all_data(all_data)
```

**Proper Cache Management**:
```python
# Clear cache when needed
self.env.invalidate_all()

# Force garbage collection after intensive operations
import gc
gc.collect()
```

### 3. View Optimization

**Efficient Field Loading**:
```python
# GOOD: Load only required fields
customer_data = customers.read(['name', 'email', 'phone'])

# BAD: Load all fields
customer_data = customers.read()
```

**Pagination for Large Datasets**:
```python
# GOOD: Use pagination
customers = self.env['res.partner'].search([
    ('customer_rank', '>', 0)
], limit=80, offset=page * 80)

# BAD: Load everything
all_customers = self.env['res.partner'].search([('customer_rank', '>', 0)])
```

## Performance Monitoring and Analysis

### 1. Continuous Monitoring

Set up automated performance monitoring:

```python
# Add to CI/CD pipeline
- name: Performance Tests
  run: |
    make test-performance-ci
    make test-performance-benchmark
```

### 2. Performance Regression Detection

Track performance over time:

```bash
# Generate performance baseline
make test-performance-full > performance_baseline.txt

# Compare against baseline in CI
make test-performance-ci | diff performance_baseline.txt -
```

### 3. Resource Monitoring

Monitor system resources during testing:

```bash
# Monitor resources during tests
make test-performance-monitor

# Profile with detailed analysis
make test-performance-profile
```

## Best Practices

### 1. Test Design

- **Test realistic scenarios**: Use real-world data volumes and patterns
- **Isolate performance factors**: Test individual components separately
- **Use consistent test data**: Ensure reproducible results
- **Set realistic thresholds**: Based on actual usage requirements

### 2. Performance Thresholds

- **User experience focused**: Thresholds based on user perception
- **Environment specific**: Different thresholds for dev/staging/production
- **Gradual degradation**: Warning thresholds before failure thresholds
- **Business context**: Critical operations have stricter thresholds

### 3. Test Maintenance

- **Regular baseline updates**: Update thresholds as system evolves
- **Performance regression alerts**: Automated notifications for slowdowns
- **Optimization tracking**: Document performance improvements
- **Load testing schedules**: Regular testing under realistic loads

## Troubleshooting Performance Issues

### 1. Database Performance

**Slow Queries**:
- Enable PostgreSQL query logging
- Use `EXPLAIN ANALYZE` for query optimization
- Check for missing database indexes
- Optimize relationship queries

**High Memory Usage**:
- Check for inefficient ORM usage
- Look for large result sets loaded into memory
- Verify proper cache management
- Monitor garbage collection patterns

### 2. View Performance

**Slow Rendering**:
- Reduce fields loaded in views
- Optimize computed field calculations
- Use pagination for large datasets
- Minimize relationship traversals

**Memory Leaks**:
- Check for unreleased JavaScript objects
- Verify proper view cleanup
- Monitor browser memory usage
- Use browser profiling tools

### 3. System Resources

**High CPU Usage**:
- Profile Python code for bottlenecks
- Optimize complex calculations
- Use database aggregations instead of Python loops
- Consider caching for expensive operations

**Memory Leaks**:
- Use memory profiling tools
- Check for circular references
- Verify proper resource cleanup
- Monitor long-running processes

## Conclusion

Performance testing ensures Royal Textiles Sales module remains responsive and efficient as data grows and usage increases. Regular performance testing catches issues early, prevents user experience degradation, and guides optimization efforts.

**Key Benefits**:
- **Proactive issue detection**: Find performance problems before users do
- **Optimization guidance**: Data-driven performance improvement decisions
- **Capacity planning**: Understand system limits and scaling requirements
- **Quality assurance**: Maintain consistent user experience under load

**Next Steps**:
1. Set up automated performance testing in CI/CD pipeline
2. Establish performance monitoring in production
3. Create performance optimization roadmap based on test results
4. Train team on performance testing best practices

For more information, see the performance test implementation in `tests/performance/` directory.

"""
Database Performance Tests for Royal Textiles Sales Module

Tests database operation performance including:
- CRUD operations (Create, Read, Update, Delete)
- Bulk operations performance
- Search and filtering performance
- Relationship query optimization
- N+1 query detection
- Complex reporting queries
"""

import random
from datetime import datetime, timedelta

from odoo.tests.common import tagged

from .base_performance_test import BasePerformanceTest


@tagged('performance', 'database')
class TestDatabasePerformance(BasePerformanceTest):
    """Test database operation performance for Royal Textiles module"""

    @classmethod
    def setUpClass(cls):
        """Set up test data for performance testing"""
        super().setUpClass()

        # Create test companies for variety
        cls.test_companies = cls.env['res.company'].create([{'name': f'Test Company {i}'} for i in range(5)])

        # Create test users
        cls.test_users = cls.env['res.users'].create(
            [
                {
                    'name': f'Test User {i}',
                    'login': f'testuser{i}@example.com',
                    'company_ids': [(6, 0, cls.test_companies.ids)],
                }
                for i in range(3)
            ]
        )

    def test_single_customer_crud_performance(self):
        """Test performance of individual customer CRUD operations"""

        # Test CREATE performance
        with self.measure_performance('customer_create') as metrics:
            customer = self.env['res.partner'].create(
                {
                    'name': 'Performance Test Customer',
                    'email': 'perf@test.com',
                    'phone': '555-0123',
                    'street': '123 Test Street',
                    'city': 'Denver',
                    'state_id': self.env.ref('base.state_us_6').id,  # Colorado
                    'zip': '80202',
                    'country_id': self.env.ref('base.us').id,
                    'is_company': False,
                    'customer_rank': 1,
                }
            )

        # Assert CREATE performance
        self.assert_performance_threshold(metrics, self.thresholds.SINGLE_CREATE_MAX, 'customer_create')
        self.assert_query_threshold(metrics, self.thresholds.SINGLE_OPERATION_QUERIES_MAX, 'customer_create')

        # Test READ performance
        with self.measure_performance('customer_read') as metrics:
            customer_data = customer.read(['name', 'email', 'phone', 'street', 'city'])

        self.assert_performance_threshold(metrics, self.thresholds.SINGLE_READ_MAX, 'customer_read')

        # Test UPDATE performance
        with self.measure_performance('customer_update') as metrics:
            customer.write({'phone': '555-9999', 'street': '456 Updated Street'})

        self.assert_performance_threshold(metrics, self.thresholds.SINGLE_UPDATE_MAX, 'customer_update')

        # Test DELETE performance
        with self.measure_performance('customer_delete') as metrics:
            customer.unlink()

        self.assert_performance_threshold(metrics, self.thresholds.SINGLE_DELETE_MAX, 'customer_delete')

    def test_bulk_customer_operations(self):
        """Test performance of bulk customer operations"""

        # Test bulk CREATE
        def create_customer_data(index):
            return {
                'name': f'Bulk Customer {index}',
                'email': f'bulk{index}@test.com',
                'phone': f'555-{index:04d}',
                'street': f'{index} Bulk Street',
                'city': 'Denver',
                'state_id': self.env.ref('base.state_us_6').id,
                'zip': f'{80000 + index % 1000:05d}',
                'country_id': self.env.ref('base.us').id,
                'is_company': False,
                'customer_rank': 1,
            }

        with self.measure_performance('bulk_customer_create_100') as metrics:
            customer_data = [create_customer_data(i) for i in range(100)]
            customers = self.env['res.partner'].create(customer_data)

        self.assert_performance_threshold(metrics, self.thresholds.BULK_CREATE_100_MAX, 'bulk_customer_create_100')
        self.assert_query_threshold(metrics, self.thresholds.BULK_OPERATION_QUERIES_MAX, 'bulk_customer_create_100')

        # Test bulk UPDATE
        with self.measure_performance('bulk_customer_update_100') as metrics:
            customers.write({'customer_rank': 2})

        self.assert_performance_threshold(metrics, self.thresholds.BULK_UPDATE_100_MAX, 'bulk_customer_update_100')

        # Test bulk DELETE
        with self.measure_performance('bulk_customer_delete_100') as metrics:
            customers.unlink()

        self.assert_performance_threshold(metrics, self.thresholds.BULK_DELETE_100_MAX, 'bulk_customer_delete_100')

    def test_sales_order_performance(self):
        """Test performance of sales order operations"""

        # Create test customer
        customer = self.env['res.partner'].create(
            {
                'name': 'Sales Performance Customer',
                'email': 'sales@test.com',
                'customer_rank': 1,
            }
        )

        # Create test product
        product = self.env['product.product'].create(
            {
                'name': 'Performance Test Product',
                'type': 'product',
                'list_price': 100.0,
            }
        )

        # Test sales order creation with lines
        with self.measure_performance('sales_order_create_with_lines') as metrics:
            order = self.env['sale.order'].create(
                {
                    'partner_id': customer.id,
                    'order_line': [
                        (
                            0,
                            0,
                            {
                                'product_id': product.id,
                                'product_uom_qty': random.randint(1, 10),
                                'price_unit': 100.0,
                            },
                        )
                        for _ in range(5)
                    ],
                }
            )

        self.assert_performance_threshold(metrics, 0.5, 'sales_order_create_with_lines')

        # Test order confirmation
        with self.measure_performance('sales_order_confirm') as metrics:
            order.action_confirm()

        self.assert_performance_threshold(metrics, 0.3, 'sales_order_confirm')

    def test_installation_performance(self):
        """Test performance of installation record operations"""

        # Create test customer and sales order
        customer = self.env['res.partner'].create(
            {
                'name': 'Installation Performance Customer',
                'customer_rank': 1,
            }
        )

        order = self.env['sale.order'].create(
            {
                'partner_id': customer.id,
            }
        )

        # Test installation creation
        with self.measure_performance('installation_create') as metrics:
            installation = self.env['royal_textiles.installation'].create(
                {
                    'customer_id': customer.id,
                    'sale_order_id': order.id,
                    'scheduled_date': datetime.now() + timedelta(days=7),
                    'installation_type': 'residential',
                    'estimated_duration': 4.0,
                    'special_instructions': 'Performance test installation',
                }
            )

        self.assert_performance_threshold(metrics, self.thresholds.SINGLE_CREATE_MAX, 'installation_create')

        # Test installation update with complex data
        with self.measure_performance('installation_update_complex') as metrics:
            installation.write(
                {
                    'status': 'in_progress',
                    'actual_start_date': datetime.now(),
                    'team_notes': 'Started performance test installation process',
                    'quality_check_passed': True,
                }
            )

        self.assert_performance_threshold(metrics, self.thresholds.SINGLE_UPDATE_MAX, 'installation_update_complex')

    def test_search_performance(self):
        """Test performance of search operations"""

        # Create test data for searching
        customers = self.env['res.partner'].create(
            [
                {
                    'name': f'Search Customer {i}',
                    'email': f'search{i}@test.com',
                    'city': random.choice(['Denver', 'Boulder', 'Colorado Springs']),
                    'customer_rank': 1,
                }
                for i in range(200)
            ]
        )

        # Test simple search
        with self.measure_performance('customer_simple_search') as metrics:
            found = self.env['res.partner'].search([('customer_rank', '>', 0)])

        self.assert_performance_threshold(metrics, self.thresholds.SIMPLE_SEARCH_MAX, 'customer_simple_search')

        # Test complex search with multiple conditions
        with self.measure_performance('customer_complex_search') as metrics:
            found = self.env['res.partner'].search(
                [
                    ('customer_rank', '>', 0),
                    ('city', 'in', ['Denver', 'Boulder']),
                    ('email', 'ilike', 'search%'),
                    ('create_date', '>=', datetime.now() - timedelta(hours=1)),
                ]
            )

        self.assert_performance_threshold(metrics, self.thresholds.COMPLEX_SEARCH_MAX, 'customer_complex_search')

        # Test filtered search (in-memory filtering)
        with self.measure_performance('customer_filtered_search') as metrics:
            all_customers = self.env['res.partner'].search([('customer_rank', '>', 0)])
            denver_customers = all_customers.filtered(lambda c: c.city == 'Denver')

        self.assert_performance_threshold(metrics, self.thresholds.FILTERED_SEARCH_MAX, 'customer_filtered_search')

    def test_relationship_query_performance(self):
        """Test performance of relationship queries and N+1 detection"""

        # Create test customers with orders
        customers = []
        for i in range(50):
            customer = self.env['res.partner'].create(
                {
                    'name': f'Relationship Customer {i}',
                    'customer_rank': 1,
                }
            )
            customers.append(customer)

            # Create multiple orders per customer
            for j in range(3):
                self.env['sale.order'].create(
                    {
                        'partner_id': customer.id,
                        'name': f'Order {i}-{j}',
                    }
                )

        # Test efficient relationship loading
        with self.measure_performance('relationship_efficient_load') as metrics:
            # Use proper ORM methods to avoid N+1 queries
            customers_with_orders = self.env['res.partner'].search([('customer_rank', '>', 0)])
            # Prefetch related data efficiently
            customers_with_orders.mapped('sale_order_ids')

        self.assert_performance_threshold(metrics, 1.0, 'relationship_efficient_load')

        # Ensure we're not hitting N+1 query problems
        self.assert_query_threshold(metrics, 20, 'relationship_efficient_load')

    def test_reporting_query_performance(self):
        """Test performance of complex reporting queries"""

        # Create comprehensive test data
        customers = self.env['res.partner'].create(
            [
                {
                    'name': f'Report Customer {i}',
                    'customer_rank': 1,
                    'city': random.choice(['Denver', 'Boulder', 'Fort Collins']),
                }
                for i in range(100)
            ]
        )

        orders = []
        for customer in customers[:50]:  # Some customers have orders
            for j in range(random.randint(1, 3)):
                order = self.env['sale.order'].create(
                    {
                        'partner_id': customer.id,
                        'amount_total': random.randint(1000, 10000),
                        'date_order': datetime.now() - timedelta(days=random.randint(1, 365)),
                    }
                )
                orders.append(order)

        # Test customer summary report query
        with self.measure_performance('customer_summary_report') as metrics:
            # Simulate complex reporting query
            summary = self.env['res.partner'].read_group(
                domain=[('customer_rank', '>', 0)],
                fields=['city', 'sale_order_ids:count', 'id:count'],
                groupby=['city'],
            )

        self.assert_performance_threshold(metrics, 0.5, 'customer_summary_report')

        # Test sales performance report
        with self.measure_performance('sales_performance_report') as metrics:
            # Complex aggregation query
            sales_data = self.env['sale.order'].read_group(
                domain=[('partner_id', 'in', customers.ids)],
                fields=['amount_total:sum', 'partner_id', 'date_order'],
                groupby=['partner_id', 'date_order:month'],
            )

        self.assert_performance_threshold(metrics, 1.0, 'sales_performance_report')

    def test_concurrent_operations_simulation(self):
        """Simulate concurrent user operations"""

        def create_customer_operation():
            """Simulate a user creating a customer"""
            return self.env['res.partner'].create(
                {
                    'name': f'Concurrent Customer {random.randint(1000, 9999)}',
                    'customer_rank': 1,
                }
            )

        def search_customer_operation():
            """Simulate a user searching for customers"""
            return self.env['res.partner'].search([('customer_rank', '>', 0)], limit=10)

        def update_customer_operation():
            """Simulate a user updating customer data"""
            customers = self.env['res.partner'].search([('customer_rank', '>', 0)], limit=1)
            if customers:
                customers[0].write({'phone': f'555-{random.randint(1000, 9999)}'})

        operations = [
            create_customer_operation,
            search_customer_operation,
            update_customer_operation,
        ]

        # Simulate concurrent load
        load_results = self.simulate_user_load(operations, concurrent_users=5)

        # Assert reasonable response times under simulated load
        self.assertLess(
            load_results['mean_response_time'],
            0.5,
            f"Mean response time under load: {load_results['mean_response_time']:.3f}s",
        )

        self.assertLess(
            load_results['max_response_time'],
            2.0,
            f"Max response time under load: {load_results['max_response_time']:.3f}s",
        )

    def test_memory_usage_under_load(self):
        """Test memory usage during intensive operations"""

        initial_memory = self.process.memory_info().rss / 1024 / 1024

        # Perform memory-intensive operations
        with self.measure_performance('memory_intensive_operations') as metrics:
            # Create large dataset
            large_dataset = self.env['res.partner'].create(
                [
                    {
                        'name': f'Memory Test Customer {i}',
                        'email': f'memory{i}@test.com',
                        'customer_rank': 1,
                    }
                    for i in range(500)
                ]
            )

            # Perform operations on the dataset
            large_dataset.read(['name', 'email', 'create_date'])
            large_dataset.write({'customer_rank': 2})

            # Search operations
            for _ in range(10):
                self.env['res.partner'].search([('customer_rank', '=', 2)])

        # Assert memory growth is reasonable
        self.assert_memory_threshold(metrics, self.thresholds.MEMORY_GROWTH_MAX, 'memory_intensive_operations')

        final_memory = self.process.memory_info().rss / 1024 / 1024
        total_memory_used = final_memory - self.baseline_memory

        self.assertLess(
            total_memory_used,
            self.thresholds.TOTAL_MEMORY_MAX,
            f"Total memory usage {total_memory_used:.1f}MB exceeds threshold",
        )

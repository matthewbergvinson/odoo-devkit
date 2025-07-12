"""
Memory and Resource Performance Tests for Royal Textiles Sales Module

Tests memory usage and resource performance including:
- Memory usage monitoring and leak detection
- Garbage collection performance
- Resource cleanup validation
- Memory-intensive operation optimization
- System resource utilization under load
"""

import gc
import sys
import threading
import time
from datetime import datetime, timedelta

from odoo.tests.common import tagged

from .base_performance_test import BasePerformanceTest


@tagged('performance', 'memory')
class TestMemoryPerformance(BasePerformanceTest):
    """Test memory usage and resource performance for Royal Textiles module"""

    def setUp(self):
        """Set up memory performance testing"""
        super().setUp()

        # Force initial garbage collection for clean baseline
        gc.collect()
        self.initial_memory = self.process.memory_info().rss / 1024 / 1024
        self.initial_objects = len(gc.get_objects())

    def test_memory_usage_customer_operations(self):
        """Test memory usage during customer operations"""

        with self.measure_performance('customer_memory_usage') as metrics:
            # Create multiple customers and track memory
            customers = []
            for i in range(100):
                customer = self.env['res.partner'].create(
                    {
                        'name': f'Memory Test Customer {i}',
                        'email': f'memory{i}@test.com',
                        'customer_rank': 1,
                    }
                )
                customers.append(customer)

                # Force periodic garbage collection during creation
                if i % 25 == 0:
                    gc.collect()

            # Perform operations on created customers
            for customer in customers:
                customer.write({'phone': f'555-{customer.id:04d}'})

            # Read operations
            customers_data = (
                self.env['res.partner']
                .browse([c.id for c in customers])
                .read(['name', 'email', 'phone', 'customer_rank'])
            )

            # Cleanup
            for customer in customers:
                customer.unlink()

        # Assert memory usage is reasonable
        self.assert_memory_threshold(metrics, 30.0, 'customer_memory_usage')  # 30MB max growth

    def test_memory_leak_detection(self):
        """Test for memory leaks during repetitive operations"""

        baseline_memory = self.process.memory_info().rss / 1024 / 1024
        memory_snapshots = []

        # Perform repetitive operations and monitor memory growth
        for iteration in range(10):
            with self.measure_performance(f'memory_leak_iteration_{iteration}') as metrics:
                # Create and immediately delete customers
                customers = self.env['res.partner'].create(
                    [
                        {
                            'name': f'Leak Test Customer {i}',
                            'customer_rank': 1,
                        }
                        for i in range(50)
                    ]
                )

                # Perform some operations
                customers.write({'phone': '555-9999'})
                customers.read(['name', 'phone'])

                # Delete customers
                customers.unlink()

                # Force garbage collection
                gc.collect()

                # Record memory usage
                current_memory = self.process.memory_info().rss / 1024 / 1024
                memory_snapshots.append(current_memory - baseline_memory)

        # Check for consistent memory growth (potential leak)
        if len(memory_snapshots) >= 5:
            recent_growth = memory_snapshots[-3:]
            early_growth = memory_snapshots[:3]

            avg_recent = sum(recent_growth) / len(recent_growth)
            avg_early = sum(early_growth) / len(early_growth)

            memory_leak_threshold = 20.0  # 20MB growth between early and recent

            self.assertLess(
                avg_recent - avg_early,
                memory_leak_threshold,
                f"Potential memory leak detected: {avg_recent - avg_early:.1f}MB growth",
            )

    def test_garbage_collection_performance(self):
        """Test garbage collection performance and efficiency"""

        # Create objects that should be garbage collected
        test_objects = []

        with self.measure_performance('garbage_collection_test') as metrics:
            # Create many temporary objects
            for i in range(1000):
                customer_data = {
                    'name': f'GC Test Customer {i}',
                    'email': f'gc{i}@test.com',
                    'customer_rank': 1,
                }
                test_objects.append(customer_data)

            # Create actual database records
            customers = self.env['res.partner'].create(test_objects)

            # Clear references to allow garbage collection
            test_objects.clear()

            # Force garbage collection and measure time
            gc_start = time.perf_counter()
            collected = gc.collect()
            gc_time = time.perf_counter() - gc_start

            # Clean up database records
            customers.unlink()

            # Store custom metrics
            metrics.custom_metrics['gc_time'] = gc_time
            metrics.custom_metrics['objects_collected'] = collected

        # Assert garbage collection is efficient
        gc_time = metrics.custom_metrics.get('gc_time', 0)
        self.assertLess(
            gc_time, 0.1, f"Garbage collection took {gc_time:.3f}s, which is too slow"  # Should take less than 100ms
        )

    def test_large_dataset_memory_efficiency(self):
        """Test memory efficiency with large datasets"""

        with self.measure_performance('large_dataset_memory') as metrics:
            # Create large dataset efficiently
            customer_data = [
                {
                    'name': f'Large Dataset Customer {i}',
                    'email': f'large{i}@test.com',
                    'customer_rank': 1,
                }
                for i in range(1000)
            ]

            # Create all customers at once (more memory efficient)
            customers = self.env['res.partner'].create(customer_data)

            # Perform bulk operations
            customers.write({'supplier_rank': 1})

            # Test memory-efficient reading
            # Read in chunks to avoid loading everything into memory
            chunk_size = 100
            for i in range(0, len(customers), chunk_size):
                chunk = customers[i : i + chunk_size]
                chunk_data = chunk.read(['name', 'email'])

            # Clean up
            customers.unlink()

        # Assert memory growth is reasonable for large dataset
        self.assert_memory_threshold(metrics, 100.0, 'large_dataset_memory')  # 100MB max for 1000 records

    def test_relationship_memory_optimization(self):
        """Test memory usage with complex relationships"""

        with self.measure_performance('relationship_memory_optimization') as metrics:
            # Create customers with related orders
            customers = self.env['res.partner'].create(
                [
                    {
                        'name': f'Relationship Customer {i}',
                        'customer_rank': 1,
                    }
                    for i in range(50)
                ]
            )

            # Create products
            products = self.env['product.product'].create(
                [
                    {
                        'name': f'Relationship Product {i}',
                        'type': 'product',
                        'list_price': 100.0,
                    }
                    for i in range(10)
                ]
            )

            # Create orders with multiple lines (complex relationships)
            orders = []
            for customer in customers:
                order = self.env['sale.order'].create(
                    {
                        'partner_id': customer.id,
                        'order_line': [
                            (
                                0,
                                0,
                                {
                                    'product_id': products[i % len(products)].id,
                                    'product_uom_qty': 1,
                                    'price_unit': 100.0,
                                },
                            )
                            for i in range(5)
                        ],
                    }
                )
                orders.append(order)

            # Test efficient relationship loading (should not load everything)
            customers_with_orders = self.env['res.partner'].search([('id', 'in', customers.ids)])

            # Use mapped() for efficient access
            all_orders = customers_with_orders.mapped('sale_order_ids')
            all_order_lines = all_orders.mapped('order_line')

            # Clean up
            for order in orders:
                order.order_line.unlink()
                order.unlink()
            customers.unlink()
            products.unlink()

        # Assert reasonable memory usage for complex relationships
        self.assert_memory_threshold(metrics, 80.0, 'relationship_memory_optimization')

    def test_cache_memory_management(self):
        """Test Odoo cache memory management"""

        with self.measure_performance('cache_memory_management') as metrics:
            # Create test data
            customers = self.env['res.partner'].create(
                [
                    {
                        'name': f'Cache Test Customer {i}',
                        'customer_rank': 1,
                    }
                    for i in range(200)
                ]
            )

            # Access customers to populate cache
            for customer in customers:
                # Access various fields to populate cache
                name = customer.name
                email = customer.email
                rank = customer.customer_rank

            # Clear cache and measure memory impact
            self.env.invalidate_all()
            gc.collect()

            # Access customers again (should rebuild cache)
            for customer in customers:
                name = customer.name
                email = customer.email
                rank = customer.customer_rank

            # Test cache size by accessing more fields
            for customer in customers[:50]:  # Subset to control memory
                customer_data = customer.read(['name', 'email', 'phone', 'street', 'city', 'create_date', 'write_date'])

            # Clean up
            customers.unlink()

        # Assert cache memory usage is reasonable
        self.assert_memory_threshold(metrics, 60.0, 'cache_memory_management')

    def test_concurrent_memory_usage(self):
        """Test memory usage under simulated concurrent access"""

        def worker_operation():
            """Simulate concurrent user operations"""
            # Create some customers
            customers = self.env['res.partner'].create(
                [
                    {
                        'name': f'Concurrent Customer {i}',
                        'customer_rank': 1,
                    }
                    for i in range(10)
                ]
            )

            # Perform operations
            customers.write({'phone': '555-0000'})
            customers.read(['name', 'phone'])

            # Clean up
            customers.unlink()

        with self.measure_performance('concurrent_memory_usage') as metrics:
            # Simulate multiple concurrent operations
            for _ in range(5):  # Simulate 5 concurrent users
                worker_operation()

        # Assert memory usage under concurrent load
        self.assert_memory_threshold(metrics, 40.0, 'concurrent_memory_usage')

    def test_memory_optimization_techniques(self):
        """Test various memory optimization techniques"""

        # Test 1: Bulk operations vs individual operations
        with self.measure_performance('bulk_vs_individual_memory') as metrics:
            # Individual operations (less memory efficient)
            individual_customers = []
            for i in range(100):
                customer = self.env['res.partner'].create(
                    {
                        'name': f'Individual Customer {i}',
                        'customer_rank': 1,
                    }
                )
                individual_customers.append(customer)

            # Bulk operations (more memory efficient)
            bulk_data = [
                {
                    'name': f'Bulk Customer {i}',
                    'customer_rank': 1,
                }
                for i in range(100)
            ]
            bulk_customers = self.env['res.partner'].create(bulk_data)

            # Clean up
            self.env['res.partner'].browse([c.id for c in individual_customers]).unlink()
            bulk_customers.unlink()

        # Test 2: Lazy loading vs eager loading
        with self.measure_performance('lazy_vs_eager_loading') as metrics:
            # Create test data
            customers = self.env['res.partner'].create(
                [
                    {
                        'name': f'Loading Test Customer {i}',
                        'customer_rank': 1,
                    }
                    for i in range(50)
                ]
            )

            orders = []
            for customer in customers[:25]:
                order = self.env['sale.order'].create(
                    {
                        'partner_id': customer.id,
                    }
                )
                orders.append(order)

            # Lazy loading (load as needed)
            for customer in customers:
                if customer.sale_order_ids:
                    order_count = len(customer.sale_order_ids)

            # Eager loading (load all at once)
            customers_with_orders = customers.filtered('sale_order_ids')
            all_orders = customers_with_orders.mapped('sale_order_ids')

            # Clean up
            for order in orders:
                order.unlink()
            customers.unlink()

        # Assert optimization techniques keep memory usage reasonable
        self.assert_memory_threshold(metrics, 50.0, 'lazy_vs_eager_loading')

    def test_memory_profiling_integration(self):
        """Test integration with memory profiling tools"""

        with self.measure_performance('memory_profiling') as metrics:
            # Get detailed memory information
            import psutil

            process = psutil.Process()

            # Memory info before operations
            memory_before = process.memory_info()

            # Perform memory-intensive operations
            customers = self.env['res.partner'].create(
                [
                    {
                        'name': f'Profiling Customer {i}',
                        'email': f'profile{i}@test.com',
                        'customer_rank': 1,
                    }
                    for i in range(300)
                ]
            )

            # Memory info after operations
            memory_after = process.memory_info()

            # Calculate memory usage details
            memory_growth = (memory_after.rss - memory_before.rss) / 1024 / 1024
            virtual_memory_growth = (memory_after.vms - memory_before.vms) / 1024 / 1024

            # Store detailed metrics
            metrics.custom_metrics.update(
                {
                    'rss_growth_mb': memory_growth,
                    'virtual_memory_growth_mb': virtual_memory_growth,
                    'memory_percent': process.memory_percent(),
                }
            )

            # Clean up
            customers.unlink()

        # Assert memory profiling shows reasonable usage
        rss_growth = metrics.custom_metrics.get('rss_growth_mb', 0)
        self.assertLess(
            rss_growth,
            80.0,  # 80MB max for 300 customer records
            f"RSS memory growth {rss_growth:.1f}MB exceeds threshold",
        )

    def tearDown(self):
        """Clean up after memory performance tests"""
        super().tearDown()

        # Force garbage collection after each test
        gc.collect()

        # Check for significant memory growth
        final_memory = self.process.memory_info().rss / 1024 / 1024
        memory_growth = final_memory - self.initial_memory

        # Warn if memory growth is excessive
        if memory_growth > 100.0:  # 100MB threshold
            print(f"WARNING: Test caused {memory_growth:.1f}MB memory growth")

        # Check for object leak
        final_objects = len(gc.get_objects())
        object_growth = final_objects - self.initial_objects

        if object_growth > 1000:  # 1000 objects threshold
            print(f"WARNING: Test created {object_growth} unreleased objects")

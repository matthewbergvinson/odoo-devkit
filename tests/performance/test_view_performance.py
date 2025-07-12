"""
View Rendering Performance Tests for Royal Textiles Sales Module

Tests view rendering performance including:
- Form view rendering time
- List view rendering with large datasets
- Kanban view performance
- Search view performance
- Report generation performance
- Widget rendering performance
"""

import random
from datetime import datetime, timedelta
from unittest.mock import patch

from odoo.http import request
from odoo.tests.common import tagged

from .base_performance_test import BasePerformanceTest


@tagged('performance', 'views')
class TestViewPerformance(BasePerformanceTest):
    """Test view rendering performance for Royal Textiles module"""

    @classmethod
    def setUpClass(cls):
        """Set up test data for view performance testing"""
        super().setUpClass()

        # Create substantial test dataset for view rendering
        cls.test_customers = cls.env['res.partner'].create(
            [
                {
                    'name': f'View Test Customer {i}',
                    'email': f'view{i}@test.com',
                    'phone': f'555-{i:04d}',
                    'street': f'{i} View Test Street',
                    'city': random.choice(['Denver', 'Boulder', 'Fort Collins']),
                    'state_id': cls.env.ref('base.state_us_6').id,
                    'country_id': cls.env.ref('base.us').id,
                    'customer_rank': 1,
                }
                for i in range(100)
            ]
        )

        # Create test products
        cls.test_products = cls.env['product.product'].create(
            [
                {
                    'name': f'View Test Product {i}',
                    'type': 'product',
                    'list_price': random.randint(50, 500),
                }
                for i in range(20)
            ]
        )

        # Create test sales orders with multiple lines
        cls.test_orders = []
        for i, customer in enumerate(cls.test_customers[:50]):
            order = cls.env['sale.order'].create(
                {
                    'partner_id': customer.id,
                    'order_line': [
                        (
                            0,
                            0,
                            {
                                'product_id': random.choice(cls.test_products).id,
                                'product_uom_qty': random.randint(1, 5),
                                'price_unit': random.randint(100, 1000),
                            },
                        )
                        for _ in range(random.randint(1, 5))
                    ],
                }
            )
            cls.test_orders.append(order)

        # Create test installations
        cls.test_installations = []
        for order in cls.test_orders[:30]:
            installation = cls.env['royal_textiles.installation'].create(
                {
                    'customer_id': order.partner_id.id,
                    'sale_order_id': order.id,
                    'scheduled_date': datetime.now() + timedelta(days=random.randint(1, 30)),
                    'installation_type': random.choice(['residential', 'commercial']),
                    'estimated_duration': random.uniform(2.0, 8.0),
                    'special_instructions': f'Test installation {len(cls.test_installations)}',
                }
            )
            cls.test_installations.append(installation)

    def test_customer_form_view_performance(self):
        """Test customer form view rendering performance"""

        # Test rendering single customer form view
        customer = self.test_customers[0]

        with self.measure_performance('customer_form_view_render') as metrics:
            # Simulate form view rendering by reading all form fields
            form_data = customer.read(
                [
                    'name',
                    'email',
                    'phone',
                    'mobile',
                    'website',
                    'street',
                    'street2',
                    'city',
                    'state_id',
                    'zip',
                    'country_id',
                    'is_company',
                    'customer_rank',
                    'supplier_rank',
                    'category_id',
                    'comment',
                    'create_date',
                    'write_date',
                ]
            )

            # Simulate loading related fields (like in a form view)
            sale_orders = customer.sale_order_ids
            invoices = customer.invoice_ids

        self.assert_performance_threshold(metrics, self.thresholds.FORM_VIEW_RENDER_MAX, 'customer_form_view_render')

        # Test complex customer with many relationships
        complex_customer = self.test_customers[0]

        with self.measure_performance('complex_customer_form_render') as metrics:
            # Read customer with all relationships loaded
            form_data = complex_customer.read(['name', 'email', 'phone', 'sale_order_ids', 'invoice_ids'])
            # Force relationship loading
            orders = complex_customer.sale_order_ids.read(['name', 'amount_total'])

        self.assert_performance_threshold(metrics, 0.5, 'complex_customer_form_render')

    def test_customer_list_view_performance(self):
        """Test customer list view rendering performance"""

        # Test list view with default pagination (80 records)
        with self.measure_performance('customer_list_view_80') as metrics:
            customers = self.env['res.partner'].search([('customer_rank', '>', 0)], limit=80)

            # Simulate list view field loading
            list_data = customers.read(['name', 'email', 'phone', 'city', 'country_id', 'customer_rank'])

        self.assert_performance_threshold(metrics, self.thresholds.LIST_VIEW_RENDER_MAX, 'customer_list_view_80')

        # Test list view with heavy pagination (200 records)
        with self.measure_performance('customer_list_view_200') as metrics:
            customers = self.env['res.partner'].search([('customer_rank', '>', 0)], limit=200)

            list_data = customers.read(['name', 'email', 'phone', 'city', 'country_id', 'customer_rank'])

        self.assert_performance_threshold(metrics, 1.0, 'customer_list_view_200')

    def test_sales_order_form_view_performance(self):
        """Test sales order form view rendering performance"""

        # Test simple order form view
        order = self.test_orders[0]

        with self.measure_performance('sales_order_form_simple') as metrics:
            form_data = order.read(
                [
                    'name',
                    'partner_id',
                    'date_order',
                    'state',
                    'amount_total',
                    'order_line',
                    'currency_id',
                    'pricelist_id',
                ]
            )

            # Load order lines (critical for form view)
            order_lines = order.order_line.read(['product_id', 'product_uom_qty', 'price_unit', 'price_subtotal'])

        self.assert_performance_threshold(metrics, self.thresholds.FORM_VIEW_RENDER_MAX, 'sales_order_form_simple')

        # Test complex order with many lines
        complex_order = max(self.test_orders, key=lambda o: len(o.order_line))

        with self.measure_performance('sales_order_form_complex') as metrics:
            form_data = complex_order.read(
                [
                    'name',
                    'partner_id',
                    'date_order',
                    'state',
                    'amount_total',
                    'order_line',
                    'currency_id',
                    'pricelist_id',
                ]
            )

            order_lines = complex_order.order_line.read(
                ['product_id', 'product_uom_qty', 'price_unit', 'price_subtotal']
            )

        self.assert_performance_threshold(metrics, 0.5, 'sales_order_form_complex')

    def test_installation_kanban_view_performance(self):
        """Test installation kanban view rendering performance"""

        with self.measure_performance('installation_kanban_view') as metrics:
            installations = self.env['royal_textiles.installation'].search([])

            # Simulate kanban view data loading
            kanban_data = installations.read(
                [
                    'customer_id',
                    'scheduled_date',
                    'status',
                    'installation_type',
                    'estimated_duration',
                    'actual_start_date',
                    'quality_check_passed',
                ]
            )

            # Simulate loading related customer data for kanban cards
            customers = installations.mapped('customer_id')
            customer_data = customers.read(['name', 'city', 'phone'])

        self.assert_performance_threshold(metrics, self.thresholds.KANBAN_VIEW_RENDER_MAX, 'installation_kanban_view')

    def test_search_view_performance(self):
        """Test search view and filtering performance"""

        # Test basic search functionality
        with self.measure_performance('customer_search_basic') as metrics:
            results = self.env['res.partner'].search([('name', 'ilike', 'View Test Customer 1')])

        self.assert_performance_threshold(metrics, 0.1, 'customer_search_basic')

        # Test complex search with multiple filters
        with self.measure_performance('customer_search_complex') as metrics:
            results = self.env['res.partner'].search(
                [
                    ('customer_rank', '>', 0),
                    ('city', 'in', ['Denver', 'Boulder']),
                    ('email', 'ilike', 'view%'),
                    ('create_date', '>=', datetime.now() - timedelta(days=1)),
                ]
            )

        self.assert_performance_threshold(metrics, 0.2, 'customer_search_complex')

        # Test search with ordering and grouping
        with self.measure_performance('customer_search_ordered') as metrics:
            results = self.env['res.partner'].search([('customer_rank', '>', 0)], order='name, city', limit=50)

        self.assert_performance_threshold(metrics, 0.15, 'customer_search_ordered')

    def test_grouped_view_performance(self):
        """Test grouped view rendering performance"""

        # Test customer grouping by city
        with self.measure_performance('customer_grouped_by_city') as metrics:
            grouped_data = self.env['res.partner'].read_group(
                domain=[('customer_rank', '>', 0)], fields=['city', 'id:count'], groupby=['city']
            )

        self.assert_performance_threshold(metrics, 0.3, 'customer_grouped_by_city')

        # Test sales order grouping by state and partner
        with self.measure_performance('orders_grouped_by_state_partner') as metrics:
            grouped_data = self.env['sale.order'].read_group(
                domain=[('partner_id', 'in', self.test_customers.ids)],
                fields=['state', 'partner_id', 'amount_total:sum'],
                groupby=['state', 'partner_id'],
            )

        self.assert_performance_threshold(metrics, 0.4, 'orders_grouped_by_state_partner')

    def test_tree_view_with_computations(self):
        """Test tree view with computed fields performance"""

        with self.measure_performance('sales_orders_tree_computed') as metrics:
            orders = self.env['sale.order'].search([('partner_id', 'in', self.test_customers.ids)])

            # Simulate tree view with computed fields
            tree_data = orders.read(
                [
                    'name',
                    'partner_id',
                    'date_order',
                    'state',
                    'amount_total',
                    'amount_untaxed',
                    'amount_tax',
                    'order_line',  # This triggers computation of order totals
                ]
            )

        self.assert_performance_threshold(metrics, 0.6, 'sales_orders_tree_computed')

    def test_calendar_view_performance(self):
        """Test calendar view rendering performance"""

        with self.measure_performance('installation_calendar_view') as metrics:
            installations = self.env['royal_textiles.installation'].search([])

            # Simulate calendar view data preparation
            calendar_data = installations.read(
                ['scheduled_date', 'customer_id', 'installation_type', 'estimated_duration', 'status']
            )

            # Group by date for calendar display
            date_groups = {}
            for installation in calendar_data:
                date_key = installation['scheduled_date'].date() if installation['scheduled_date'] else None
                if date_key not in date_groups:
                    date_groups[date_key] = []
                date_groups[date_key].append(installation)

        self.assert_performance_threshold(metrics, 0.4, 'installation_calendar_view')

    def test_pivot_view_performance(self):
        """Test pivot view/reporting performance"""

        with self.measure_performance('sales_pivot_by_customer_month') as metrics:
            # Simulate pivot table generation
            pivot_data = self.env['sale.order'].read_group(
                domain=[('partner_id', 'in', self.test_customers.ids)],
                fields=['partner_id', 'amount_total:sum', 'date_order'],
                groupby=['partner_id', 'date_order:month'],
                lazy=False,
            )

        self.assert_performance_threshold(metrics, 0.8, 'sales_pivot_by_customer_month')

        # Test more complex pivot with installations
        with self.measure_performance('installation_pivot_analysis') as metrics:
            pivot_data = self.env['royal_textiles.installation'].read_group(
                domain=[],
                fields=['installation_type', 'status', 'estimated_duration:avg'],
                groupby=['installation_type', 'status'],
                lazy=False,
            )

        self.assert_performance_threshold(metrics, 0.5, 'installation_pivot_analysis')

    def test_dashboard_view_performance(self):
        """Test dashboard-style view performance with multiple widgets"""

        with self.measure_performance('dashboard_data_loading') as metrics:
            # Simulate dashboard data loading

            # Customer statistics
            customer_count = self.env['res.partner'].search_count([('customer_rank', '>', 0)])

            # Sales statistics
            sales_total = sum(
                self.env['sale.order'].search([('partner_id', 'in', self.test_customers.ids)]).mapped('amount_total')
            )

            # Installation statistics
            installation_stats = self.env['royal_textiles.installation'].read_group(
                domain=[], fields=['status', 'id:count'], groupby=['status']
            )

            # Recent activity
            recent_orders = self.env['sale.order'].search(
                [('partner_id', 'in', self.test_customers.ids)], limit=10, order='create_date desc'
            )

            recent_installations = self.env['royal_textiles.installation'].search(
                [], limit=10, order='create_date desc'
            )

        self.assert_performance_threshold(metrics, 1.0, 'dashboard_data_loading')

    def test_view_inheritance_performance(self):
        """Test performance impact of view inheritance"""

        # Test base view rendering
        with self.measure_performance('base_customer_view') as metrics:
            customer = self.test_customers[0]
            base_data = customer.read(['name', 'email', 'phone'])

        base_time = metrics.execution_time

        # Test extended view with additional fields
        with self.measure_performance('extended_customer_view') as metrics:
            customer = self.test_customers[0]
            extended_data = customer.read(
                [
                    'name',
                    'email',
                    'phone',  # Base fields
                    'customer_rank',
                    'supplier_rank',
                    'category_id',  # Extended fields
                    'sale_order_ids',
                    'invoice_ids',  # Relationship fields
                ]
            )

        # Ensure view inheritance doesn't cause excessive slowdown
        inheritance_overhead = metrics.execution_time - base_time
        self.assertLess(
            inheritance_overhead,
            0.1,  # Should add less than 100ms
            f"View inheritance overhead: {inheritance_overhead:.3f}s",
        )

    def test_field_widget_performance(self):
        """Test performance of different field widgets"""

        # Test many2one widget performance
        with self.measure_performance('many2one_widget_loading') as metrics:
            orders = self.test_orders[:20]
            # Simulate many2one field loading for partner_id
            partner_data = orders.mapped('partner_id').read(['name', 'email'])

        self.assert_performance_threshold(metrics, 0.2, 'many2one_widget_loading')

        # Test one2many widget performance
        with self.measure_performance('one2many_widget_loading') as metrics:
            customers = self.test_customers[:10]
            # Simulate one2many field loading for sale_order_ids
            for customer in customers:
                order_data = customer.sale_order_ids.read(['name', 'amount_total'])

        self.assert_performance_threshold(metrics, 0.3, 'one2many_widget_loading')

        # Test many2many widget performance
        with self.measure_performance('many2many_widget_loading') as metrics:
            customers = self.test_customers[:20]
            # Simulate many2many field loading for category_id
            category_data = customers.mapped('category_id').read(['name'])

        self.assert_performance_threshold(metrics, 0.15, 'many2many_widget_loading')

    def test_large_dataset_view_performance(self):
        """Test view performance with large datasets"""

        # Create additional test data for large dataset testing
        large_customers = self.env['res.partner'].create(
            [
                {
                    'name': f'Large Dataset Customer {i}',
                    'email': f'large{i}@test.com',
                    'customer_rank': 1,
                }
                for i in range(500)
            ]
        )

        # Test list view with large dataset
        with self.measure_performance('large_dataset_list_view') as metrics:
            customers = self.env['res.partner'].search(
                [('customer_rank', '>', 0)], limit=100
            )  # Typical pagination size

            list_data = customers.read(['name', 'email', 'city'])

        self.assert_performance_threshold(metrics, 0.8, 'large_dataset_list_view')

        # Test search performance with large dataset
        with self.measure_performance('large_dataset_search') as metrics:
            results = self.env['res.partner'].search(
                [('name', 'ilike', 'Large Dataset Customer'), ('customer_rank', '>', 0)], limit=50
            )

        self.assert_performance_threshold(metrics, 0.5, 'large_dataset_search')

    def test_concurrent_view_rendering(self):
        """Test view rendering under concurrent access simulation"""

        def render_customer_list():
            """Simulate user loading customer list view"""
            customers = self.env['res.partner'].search([('customer_rank', '>', 0)], limit=20)
            return customers.read(['name', 'email', 'city'])

        def render_order_form():
            """Simulate user loading order form view"""
            order = random.choice(self.test_orders)
            return order.read(['partner_id', 'amount_total', 'order_line'])

        def render_installation_kanban():
            """Simulate user loading installation kanban"""
            installations = self.env['royal_textiles.installation'].search([], limit=15)
            return installations.read(['customer_id', 'status', 'scheduled_date'])

        operations = [
            render_customer_list,
            render_order_form,
            render_installation_kanban,
        ]

        # Simulate concurrent view rendering
        load_results = self.simulate_user_load(operations, concurrent_users=3)

        # Assert reasonable response times under load
        self.assertLess(
            load_results['mean_response_time'],
            0.8,
            f"Mean view rendering time under load: {load_results['mean_response_time']:.3f}s",
        )

        self.assertLess(
            load_results['max_response_time'],
            2.0,
            f"Max view rendering time under load: {load_results['max_response_time']:.3f}s",
        )

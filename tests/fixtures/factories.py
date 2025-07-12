"""
Test Data Factories for Royal Textiles Sales Module
Task 4.4: Add test data fixtures and factories for consistent test scenarios

Factory classes for generating realistic, consistent test data using
the Factory Method pattern. Based on best practices from Django and
other frameworks for maintainable test data generation.

Usage:
    # Create a single customer
    customer = CustomerFactory.create()

    # Create multiple customers
    customers = CustomerFactory.create_batch(5)

    # Create with specific attributes
    commercial_customer = CustomerFactory.create(customer_type='commercial')

    # Create complete order scenario
    scenario = SimpleOrderScenario.create()
"""

import random
from datetime import datetime, timedelta
from typing import Any, Dict, List, Optional

from tests.base_model_test import BaseOdooModelTest

from .realistic_data import (
    INSTALLATION_SCENARIOS,
    get_realistic_customer_data,
    get_realistic_order_scenario,
    get_realistic_product_data,
)


class BaseFactory:
    """
    Base factory class providing common functionality for all factories.

    Implements the Factory Method pattern with Odoo-specific functionality.
    """

    def __init__(self, env):
        """Initialize factory with Odoo environment."""
        self.env = env
        self._created_records = []

    def cleanup(self):
        """Clean up all records created by this factory."""
        for record in reversed(self._created_records):
            if record.exists():
                record.unlink()
        self._created_records.clear()

    def _track_record(self, record):
        """Track a created record for cleanup."""
        self._created_records.append(record)
        return record

    def _get_or_create_reference(self, model_name: str, reference_name: str) -> Any:
        """Get or create common reference data."""
        if model_name == 'res.country' and reference_name == 'US':
            return self.env.ref('base.us')
        elif model_name == 'res.country.state' and reference_name == 'CO':
            return self.env.ref('base.state_us_6')  # Colorado
        elif model_name == 'product.category' and reference_name == 'window_treatments':
            # Get or create window treatments category
            category = self.env['product.category'].search([('name', '=', 'Window Treatments')], limit=1)
            if not category:
                category = self.env['product.category'].create(
                    {
                        'name': 'Window Treatments',
                    }
                )
                self._track_record(category)
            return category
        return None


class CustomerFactory(BaseFactory):
    """
    Factory for creating realistic customer/partner records.

    Supports different customer types: residential, commercial, hospitality
    """

    def create(self, customer_type: str = 'residential', **overrides) -> Any:
        """
        Create a realistic customer record.

        Args:
            customer_type: Type of customer ('residential', 'commercial', 'hospitality')
            **overrides: Fields to override in the generated data

        Returns:
            Created res.partner record
        """
        # Get realistic base data
        customer_data = get_realistic_customer_data(customer_type)

        # Set references
        customer_data['country_id'] = self._get_or_create_reference('res.country', 'US').id
        customer_data['state_id'] = self._get_or_create_reference('res.country.state', 'CO').id

        # Apply overrides
        customer_data.update(overrides)

        # Remove custom fields that aren't in res.partner
        customer_data.pop('customer_type', None)

        # Create and track record
        customer = self.env['res.partner'].create(customer_data)
        return self._track_record(customer)

    def create_batch(self, count: int, customer_type: str = 'residential', **overrides) -> List[Any]:
        """Create multiple customer records."""
        return [self.create(customer_type, **overrides) for _ in range(count)]

    def create_residential(self, **overrides) -> Any:
        """Create a residential customer."""
        return self.create('residential', **overrides)

    def create_commercial(self, **overrides) -> Any:
        """Create a commercial customer."""
        return self.create('commercial', **overrides)

    def create_hospitality(self, **overrides) -> Any:
        """Create a hospitality customer."""
        return self.create('hospitality', **overrides)


class ProductFactory(BaseFactory):
    """
    Factory for creating realistic product records.

    Supports different product types: blinds, shades, motorized, services
    """

    def create(self, product_type: str = None, **overrides) -> Any:
        """
        Create a realistic product record.

        Args:
            product_type: Type of product ('blinds', 'shades', 'motorized', 'services')
            **overrides: Fields to override in the generated data

        Returns:
            Created product.product record
        """
        # Get realistic base data
        product_data = get_realistic_product_data(product_type)

        # Set category reference
        if product_data['type'] != 'service':
            category = self._get_or_create_reference('product.category', 'window_treatments')
            if category:
                product_data['categ_id'] = category.id

        # Apply overrides
        product_data.update(overrides)

        # Remove custom fields that aren't in product.product
        product_data.pop('product_type', None)
        product_data.pop('install_time_multiplier', None)
        product_data.pop('weight_per_unit', None)

        # Create and track record
        product = self.env['product.product'].create(product_data)
        return self._track_record(product)

    def create_batch(self, count: int, product_type: str = None, **overrides) -> List[Any]:
        """Create multiple product records."""
        return [self.create(product_type, **overrides) for _ in range(count)]

    def create_blind(self, **overrides) -> Any:
        """Create a blind product."""
        return self.create('blinds', **overrides)

    def create_shade(self, **overrides) -> Any:
        """Create a shade product."""
        return self.create('shades', **overrides)

    def create_motorized(self, **overrides) -> Any:
        """Create a motorized product."""
        return self.create('motorized', **overrides)

    def create_service(self, **overrides) -> Any:
        """Create a service product."""
        return self.create('services', **overrides)

    def create_product_catalog(self) -> Dict[str, Any]:
        """Create a complete product catalog for testing."""
        return {
            'blind': self.create_blind(),
            'shade': self.create_shade(),
            'motorized': self.create_motorized(),
            'service': self.create_service(),
        }


class SaleOrderFactory(BaseFactory):
    """
    Factory for creating realistic sale order records with order lines.

    Supports different order scenarios and complexity levels.
    """

    def __init__(self, env):
        super().__init__(env)
        self.customer_factory = CustomerFactory(env)
        self.product_factory = ProductFactory(env)

    def create(
        self, scenario_type: str = 'typical', customer: Any = None, products: Dict[str, Any] = None, **overrides
    ) -> Any:
        """
        Create a realistic sale order with order lines.

        Args:
            scenario_type: Order scenario ('simple', 'typical', 'complex', etc.)
            customer: Existing customer record (creates one if None)
            products: Existing product catalog (creates one if None)
            **overrides: Fields to override in the generated data

        Returns:
            Created sale.order record with order lines
        """
        # Get scenario configuration
        scenario = get_realistic_order_scenario(scenario_type)

        # Create or use provided customer
        if not customer:
            customer = self.customer_factory.create(customer_type=scenario['customer_type'])

        # Create or use provided products
        if not products:
            products = self.product_factory.create_product_catalog()

        # Create sale order
        order_data = {
            'partner_id': customer.id,
            'date_order': datetime.now(),
        }
        order_data.update(overrides)

        order = self.env['sale.order'].create(order_data)
        self._track_record(order)

        # Create order lines based on scenario
        for product_spec in scenario['products']:
            product_type = product_spec['type']
            quantity = product_spec['quantity']

            if product_type == 'blinds':
                product = products['blind']
            elif product_type == 'shades':
                product = products['shade']
            elif product_type == 'motorized':
                product = products['motorized']
            elif product_type == 'services':
                product = products['service']
            else:
                continue

            # Create order line
            line_data = {
                'order_id': order.id,
                'product_id': product.id,
                'product_uom_qty': quantity,
                'price_unit': product.list_price,
            }

            line = self.env['sale.order.line'].create(line_data)
            self._track_record(line)

        return order

    def create_simple_order(self, **overrides) -> Any:
        """Create a simple residential order."""
        return self.create('simple', **overrides)

    def create_typical_order(self, **overrides) -> Any:
        """Create a typical mixed order."""
        return self.create('typical', **overrides)

    def create_complex_order(self, **overrides) -> Any:
        """Create a complex commercial order."""
        return self.create('complex', **overrides)

    def create_confirmed_order(self, scenario_type: str = 'typical', **overrides) -> Any:
        """Create a confirmed sale order ready for installation."""
        order = self.create(scenario_type, **overrides)
        order.write({'state': 'sale'})
        return order


class InstallationFactory(BaseFactory):
    """
    Factory for creating realistic installation records.

    Creates installations with proper relationships to sale orders and customers.
    """

    def __init__(self, env):
        super().__init__(env)
        self.customer_factory = CustomerFactory(env)
        self.order_factory = SaleOrderFactory(env)

    def create(
        self, scenario_type: str = 'quick_residential', sale_order: Any = None, customer: Any = None, **overrides
    ) -> Any:
        """
        Create a realistic installation record.

        Args:
            scenario_type: Installation scenario type
            sale_order: Existing sale order (creates one if None)
            customer: Existing customer (uses sale order customer if None)
            **overrides: Fields to override in the generated data

        Returns:
            Created royal.installation record
        """
        # Get scenario configuration
        scenario = INSTALLATION_SCENARIOS.get(scenario_type, INSTALLATION_SCENARIOS['quick_residential'])

        # Create or use provided sale order
        if not sale_order:
            order_scenario = 'simple' if 'residential' in scenario_type else 'commercial'
            sale_order = self.order_factory.create_confirmed_order(order_scenario)

        # Use sale order customer or provided customer
        if not customer:
            customer = sale_order.partner_id

        # Generate installation name
        installation_name = f"Installation for {sale_order.name}"

        # Create installation data
        installation_data = {
            'name': installation_name,
            'sale_order_id': sale_order.id,
            'customer_id': customer.id,
            'estimated_hours': scenario['estimated_hours'],
            'scheduled_date': datetime.now() + timedelta(days=7),
            'installation_notes': f"Scenario: {scenario['complexity']}",
        }

        # Add special requirements if any
        if scenario.get('special_requirements'):
            requirements = '\n'.join(scenario['special_requirements'])
            installation_data['special_instructions'] = requirements

        # Apply overrides
        installation_data.update(overrides)

        # Create and track record
        installation = self.env['royal.installation'].create(installation_data)
        return self._track_record(installation)

    def create_residential(self, **overrides) -> Any:
        """Create a residential installation."""
        return self.create('quick_residential', **overrides)

    def create_commercial(self, **overrides) -> Any:
        """Create a commercial installation."""
        return self.create('standard_commercial', **overrides)

    def create_complex(self, **overrides) -> Any:
        """Create a complex motorized installation."""
        return self.create('complex_motorized', **overrides)

    def create_in_progress(self, **overrides) -> Any:
        """Create an installation that's in progress."""
        installation = self.create(**overrides)
        installation.write({'status': 'scheduled'})
        installation.action_start_installation()
        return installation

    def create_completed(self, **overrides) -> Any:
        """Create a completed installation with realistic timing."""
        installation = self.create(**overrides)
        installation.write({'status': 'scheduled'})

        # Start installation
        installation.action_start_installation()

        # Complete installation with realistic duration
        actual_hours = installation.estimated_hours * random.uniform(0.8, 1.2)
        installation.write({'duration_actual': actual_hours})
        installation.action_complete_installation()

        return installation


class TestDataManager:
    """
    Central manager for creating and managing test data across all factories.

    Provides high-level methods for creating complete test scenarios
    and managing cleanup across multiple factories.
    """

    def __init__(self, env):
        self.env = env
        self.customer_factory = CustomerFactory(env)
        self.product_factory = ProductFactory(env)
        self.order_factory = SaleOrderFactory(env)
        self.installation_factory = InstallationFactory(env)
        self._all_factories = [
            self.customer_factory,
            self.product_factory,
            self.order_factory,
            self.installation_factory,
        ]

    def cleanup_all(self):
        """Clean up all records created by all factories."""
        for factory in self._all_factories:
            factory.cleanup()

    def create_complete_scenario(self, scenario_type: str = 'typical') -> Dict[str, Any]:
        """
        Create a complete business scenario with all related records.

        Args:
            scenario_type: Scenario complexity level

        Returns:
            Dictionary with all created records
        """
        # Determine customer type based on scenario
        if 'commercial' in scenario_type or 'complex' in scenario_type:
            customer_type = 'commercial'
        else:
            customer_type = 'residential'

        # Create customer
        customer = self.customer_factory.create(customer_type)

        # Create product catalog
        products = self.product_factory.create_product_catalog()

        # Create confirmed sale order
        sale_order = self.order_factory.create_confirmed_order(scenario_type, customer=customer, products=products)

        # Create installation
        installation_scenario = (
            'complex_motorized'
            if 'complex' in scenario_type
            else 'standard_commercial'
            if customer_type == 'commercial'
            else 'quick_residential'
        )

        installation = self.installation_factory.create(installation_scenario, sale_order=sale_order, customer=customer)

        return {
            'customer': customer,
            'products': products,
            'sale_order': sale_order,
            'installation': installation,
            'scenario_type': scenario_type,
        }

    def create_bulk_customers(self, count: int, customer_types: List[str] = None) -> List[Any]:
        """Create multiple customers for bulk testing."""
        if not customer_types:
            customer_types = ['residential', 'commercial', 'hospitality']

        customers = []
        for i in range(count):
            customer_type = customer_types[i % len(customer_types)]
            customer = self.customer_factory.create(customer_type)
            customers.append(customer)

        return customers

    def create_performance_test_data(self, order_count: int = 50) -> Dict[str, Any]:
        """
        Create data set for performance testing.

        Args:
            order_count: Number of orders to create

        Returns:
            Dictionary with performance test data
        """
        # Create customers
        customers = self.create_bulk_customers(order_count // 5)

        # Create shared product catalog
        products = self.product_factory.create_product_catalog()

        # Create orders and installations
        orders = []
        installations = []

        for i in range(order_count):
            customer = customers[i % len(customers)]

            # Vary scenario types
            scenario_types = ['simple', 'typical', 'complex']
            scenario_type = scenario_types[i % len(scenario_types)]

            # Create order
            order = self.order_factory.create_confirmed_order(scenario_type, customer=customer, products=products)
            orders.append(order)

            # Create installation for some orders
            if i % 2 == 0:  # Create installation for every other order
                installation = self.installation_factory.create(
                    'quick_residential', sale_order=order, customer=customer
                )
                installations.append(installation)

        return {
            'customers': customers,
            'products': products,
            'orders': orders,
            'installations': installations,
            'total_records': len(customers) + len(products) + len(orders) + len(installations),
        }

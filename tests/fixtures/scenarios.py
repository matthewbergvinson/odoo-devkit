"""
Pre-built Test Scenarios for Royal Textiles Sales Module
Task 4.4: Add test data fixtures and factories for consistent test scenarios

This module provides pre-built scenario fixtures that combine multiple
factories to create complete, realistic testing scenarios. These scenarios
cover common use cases and can be used as-is or customized for specific tests.

Based on best practices: "Have extensive fixtures for every use case" and
organize fixtures by feature and scenario complexity.

Usage:
    # Create a simple order scenario
    scenario = SimpleOrderScenario(env)
    data = scenario.create()

    # Create bulk testing scenario
    bulk_scenario = BulkTestingScenario(env)
    bulk_data = bulk_scenario.create(customer_count=100)
"""

from datetime import datetime, timedelta
from typing import Any, Dict, List

from .factories import CustomerFactory, InstallationFactory, ProductFactory, SaleOrderFactory, TestDataManager


class BaseScenario:
    """
    Base class for all test scenarios.

    Provides common functionality and standard interface for scenario creation.
    """

    def __init__(self, env):
        """Initialize scenario with Odoo environment."""
        self.env = env
        self.data_manager = TestDataManager(env)

    def cleanup(self):
        """Clean up all records created by this scenario."""
        self.data_manager.cleanup_all()

    def create(self, **kwargs) -> Dict[str, Any]:
        """
        Create the scenario data.

        To be implemented by subclasses.
        """
        raise NotImplementedError("Subclasses must implement create method")


class SimpleOrderScenario(BaseScenario):
    """
    Simple Order Scenario: Single residential customer with basic order.

    Use case: Testing basic order creation, simple installation workflows,
    form validation with minimal data complexity.

    Creates:
    - 1 residential customer
    - 1 product catalog (4 products)
    - 1 simple sale order (3 blinds + 1 service)
    - 1 residential installation
    """

    def create(self, **overrides) -> Dict[str, Any]:
        """Create simple order scenario."""
        # Create base scenario
        scenario_data = self.data_manager.create_complete_scenario('simple')

        # Add scenario-specific metadata
        scenario_data.update(
            {
                'scenario_name': 'Simple Order',
                'complexity': 'low',
                'estimated_test_duration': '30 seconds',
                'use_cases': [
                    'Basic order creation',
                    'Simple installation workflow',
                    'Form validation testing',
                    'Status transitions',
                ],
                'record_counts': {
                    'customers': 1,
                    'products': 4,
                    'orders': 1,
                    'order_lines': 2,
                    'installations': 1,
                },
            }
        )

        # Apply any overrides
        scenario_data.update(overrides)

        return scenario_data


class ComplexOrderScenario(BaseScenario):
    """
    Complex Order Scenario: Commercial customer with advanced products.

    Use case: Testing complex business logic, advanced workflows,
    integration between multiple modules, performance with larger datasets.

    Creates:
    - 1 commercial customer
    - 1 product catalog (4 products)
    - 1 complex sale order (8 blinds + 4 shades + 2 motorized + 2 services)
    - 1 complex motorized installation
    - Work order project integration
    - Calendar event integration
    """

    def create(self, **overrides) -> Dict[str, Any]:
        """Create complex order scenario."""
        # Create base scenario
        scenario_data = self.data_manager.create_complete_scenario('complex')

        # Additional complexity: Create multiple installations
        order = scenario_data['sale_order']
        customer = scenario_data['customer']

        # Create a second installation for the same order
        additional_installation = self.data_manager.installation_factory.create(
            'standard_commercial', sale_order=order, customer=customer
        )

        # Add scenario-specific metadata
        scenario_data.update(
            {
                'scenario_name': 'Complex Order',
                'complexity': 'high',
                'estimated_test_duration': '2 minutes',
                'additional_installation': additional_installation,
                'use_cases': [
                    'Complex business logic testing',
                    'Multi-module integration',
                    'Advanced workflow validation',
                    'Performance testing',
                    'Error handling with complex data',
                ],
                'record_counts': {
                    'customers': 1,
                    'products': 4,
                    'orders': 1,
                    'order_lines': 4,
                    'installations': 2,
                },
                'integration_points': [
                    'Sales module (order extensions)',
                    'Project module (work orders)',
                    'Calendar module (scheduling)',
                    'Product module (calculations)',
                ],
            }
        )

        # Apply any overrides
        scenario_data.update(overrides)

        return scenario_data


class BulkTestingScenario(BaseScenario):
    """
    Bulk Testing Scenario: Multiple customers and orders for performance testing.

    Use case: Performance testing, bulk operations, stress testing,
    testing with realistic data volumes.

    Creates:
    - Multiple customers (default: 20)
    - 1 shared product catalog
    - Multiple orders (default: 50)
    - Multiple installations (default: 25)
    """

    def create(self, customer_count: int = 20, order_count: int = 50, **overrides) -> Dict[str, Any]:
        """Create bulk testing scenario."""
        # Create performance test data
        performance_data = self.data_manager.create_performance_test_data(order_count)

        # Add scenario-specific metadata
        scenario_data = {
            'scenario_name': 'Bulk Testing',
            'complexity': 'very_high',
            'estimated_test_duration': '5 minutes',
            'customers': performance_data['customers'],
            'products': performance_data['products'],
            'orders': performance_data['orders'],
            'installations': performance_data['installations'],
            'use_cases': [
                'Performance testing',
                'Bulk operations',
                'Stress testing',
                'Large dataset validation',
                'Memory usage testing',
            ],
            'record_counts': {
                'customers': len(performance_data['customers']),
                'products': len(performance_data['products']),
                'orders': len(performance_data['orders']),
                'order_lines': len(performance_data['orders']) * 3,  # Average
                'installations': len(performance_data['installations']),
                'total_records': performance_data['total_records'],
            },
            'performance_metrics': {
                'target_creation_time': '< 30 seconds',
                'target_query_time': '< 1 second per 100 records',
                'memory_usage': 'Monitor for leaks',
            },
        }

        # Apply any overrides
        scenario_data.update(overrides)

        return scenario_data


class ErrorTestingScenario(BaseScenario):
    """
    Error Testing Scenario: Data designed to trigger validation errors and edge cases.

    Use case: Testing error handling, validation rules, constraint checking,
    edge case behavior, exception handling.

    Creates:
    - Various invalid data combinations
    - Boundary condition testing data
    - Constraint violation scenarios
    """

    def create(self, **overrides) -> Dict[str, Any]:
        """Create error testing scenario."""
        # Create base valid data first
        base_scenario = self.data_manager.create_complete_scenario('typical')

        # Create various error-inducing data
        customer_factory = self.data_manager.customer_factory
        order_factory = self.data_manager.order_factory
        installation_factory = self.data_manager.installation_factory

        # Create customers with edge case data
        edge_case_customers = []

        # Customer with very long name (testing field limits)
        long_name_customer = customer_factory.create(
            name="A" * 200 + " Very Long Company Name That Exceeds Normal Limits",
            email="test.very.long.email.address@example.com",
        )
        edge_case_customers.append(long_name_customer)

        # Customer with minimal data
        minimal_customer = customer_factory.create(name="Test", email="t@e.co")
        edge_case_customers.append(minimal_customer)

        # Create orders for testing business logic errors
        error_orders = []

        # Order with no lines (should fail business validation)
        empty_order = self.env['sale.order'].create(
            {
                'partner_id': base_scenario['customer'].id,
                'date_order': datetime.now(),
            }
        )
        self.data_manager.order_factory._track_record(empty_order)
        error_orders.append(empty_order)

        # Create installations with invalid data
        error_installations = []

        # Installation with past scheduled date
        past_installation = installation_factory.create(
            scheduled_date=datetime.now() - timedelta(days=30), estimated_hours=-5.0  # Negative hours
        )
        error_installations.append(past_installation)

        # Installation with extremely long duration
        long_installation = installation_factory.create(
            estimated_hours=1000.0, installation_notes="A" * 5000  # Unrealistic duration  # Very long notes
        )
        error_installations.append(long_installation)

        scenario_data = {
            'scenario_name': 'Error Testing',
            'complexity': 'high',
            'estimated_test_duration': '1 minute',
            'base_scenario': base_scenario,
            'edge_case_customers': edge_case_customers,
            'error_orders': error_orders,
            'error_installations': error_installations,
            'use_cases': [
                'Validation rule testing',
                'Error handling validation',
                'Constraint checking',
                'Edge case behavior',
                'Exception handling',
                'Boundary condition testing',
            ],
            'error_scenarios': [
                'Empty order validation',
                'Invalid date ranges',
                'Field length limits',
                'Negative value validation',
                'Missing required fields',
                'Invalid status transitions',
            ],
            'record_counts': {
                'valid_customers': 1,
                'edge_case_customers': len(edge_case_customers),
                'error_orders': len(error_orders),
                'error_installations': len(error_installations),
            },
        }

        # Apply any overrides
        scenario_data.update(overrides)

        return scenario_data


class PerformanceTestingScenario(BaseScenario):
    """
    Performance Testing Scenario: Optimized for measuring system performance.

    Use case: Performance benchmarking, optimization testing,
    scalability analysis, bottleneck identification.

    Creates:
    - Large but controlled datasets
    - Varied complexity levels
    - Benchmark data structures
    """

    def create(self, scale_factor: int = 1, **overrides) -> Dict[str, Any]:
        """
        Create performance testing scenario.

        Args:
            scale_factor: Multiplier for data volumes (1 = baseline, 2 = double, etc.)
        """
        # Base counts scaled by factor
        base_customers = 25 * scale_factor
        base_orders = 100 * scale_factor

        # Create the bulk data
        performance_data = self.data_manager.create_performance_test_data(base_orders)

        # Create additional complexity data
        completed_installations = []
        for i in range(min(10 * scale_factor, len(performance_data['installations']))):
            installation = performance_data['installations'][i]
            # Complete some installations for realistic status distribution
            installation.write({'status': 'scheduled'})
            installation.action_start_installation()
            installation.action_complete_installation()
            completed_installations.append(installation)

        scenario_data = {
            'scenario_name': 'Performance Testing',
            'complexity': 'very_high',
            'scale_factor': scale_factor,
            'estimated_test_duration': f'{2 * scale_factor} minutes',
            'customers': performance_data['customers'],
            'products': performance_data['products'],
            'orders': performance_data['orders'],
            'installations': performance_data['installations'],
            'completed_installations': completed_installations,
            'use_cases': [
                'Performance benchmarking',
                'Scalability testing',
                'Bottleneck identification',
                'Memory usage analysis',
                'Query optimization testing',
            ],
            'record_counts': {
                'customers': len(performance_data['customers']),
                'products': len(performance_data['products']),
                'orders': len(performance_data['orders']),
                'installations': len(performance_data['installations']),
                'completed_installations': len(completed_installations),
                'total_records': performance_data['total_records'],
            },
            'performance_targets': {
                'order_creation': f'< {5 * scale_factor} seconds',
                'installation_workflow': f'< {2 * scale_factor} seconds',
                'bulk_operations': f'< {10 * scale_factor} seconds',
                'search_performance': '< 500ms per query',
                'memory_usage': f'< {100 * scale_factor}MB',
            },
            'benchmark_operations': [
                'Create 10 orders with full workflow',
                'Search and filter large datasets',
                'Status transition bulk operations',
                'Report generation with large data',
                'Calendar integration performance',
            ],
        }

        # Apply any overrides
        scenario_data.update(overrides)

        return scenario_data


class WorkflowTestingScenario(BaseScenario):
    """
    Workflow Testing Scenario: Complete end-to-end workflow validation.

    Use case: Integration testing, workflow validation,
    end-to-end process testing, business process validation.

    Creates:
    - Complete workflow from order to completion
    - Multiple status transitions
    - Integration touchpoints
    """

    def create(self, **overrides) -> Dict[str, Any]:
        """Create workflow testing scenario."""
        # Create base scenario
        base_scenario = self.data_manager.create_complete_scenario('typical')

        order = base_scenario['sale_order']
        installation = base_scenario['installation']

        # Execute partial workflow to create intermediate states
        workflow_steps = []

        # Step 1: Confirm order
        if order.state == 'draft':
            order.action_confirm()
            workflow_steps.append({'step': 'Order Confirmed', 'timestamp': datetime.now(), 'status': 'completed'})

        # Step 2: Schedule installation
        installation.write({'status': 'scheduled'})
        workflow_steps.append({'step': 'Installation Scheduled', 'timestamp': datetime.now(), 'status': 'completed'})

        # Create additional orders at different workflow stages
        draft_order = self.data_manager.order_factory.create(
            'simple', customer=base_scenario['customer'], products=base_scenario['products']
        )

        confirmed_order = self.data_manager.order_factory.create_confirmed_order(
            'typical', customer=base_scenario['customer'], products=base_scenario['products']
        )

        # Create installations at different stages
        in_progress_installation = self.data_manager.installation_factory.create_in_progress()
        completed_installation = self.data_manager.installation_factory.create_completed()

        scenario_data = {
            'scenario_name': 'Workflow Testing',
            'complexity': 'high',
            'estimated_test_duration': '3 minutes',
            'primary_order': order,
            'primary_installation': installation,
            'draft_order': draft_order,
            'confirmed_order': confirmed_order,
            'in_progress_installation': in_progress_installation,
            'completed_installation': completed_installation,
            'workflow_steps': workflow_steps,
            'use_cases': [
                'End-to-end workflow testing',
                'Status transition validation',
                'Integration point testing',
                'Business process validation',
                'Cross-module functionality',
            ],
            'workflow_stages': [
                'Draft order creation',
                'Order confirmation',
                'Installation scheduling',
                'Installation execution',
                'Installation completion',
                'Work order generation',
                'Calendar integration',
            ],
            'record_counts': {
                'customers': 1,
                'products': 4,
                'orders': 3,
                'installations': 4,
                'workflow_states': len(workflow_steps),
            },
        }

        # Apply any overrides
        scenario_data.update(overrides)

        return scenario_data


# Convenience functions for quick scenario access


def create_simple_scenario(env, **kwargs):
    """Quick access to simple order scenario."""
    scenario = SimpleOrderScenario(env)
    return scenario.create(**kwargs)


def create_complex_scenario(env, **kwargs):
    """Quick access to complex order scenario."""
    scenario = ComplexOrderScenario(env)
    return scenario.create(**kwargs)


def create_bulk_scenario(env, **kwargs):
    """Quick access to bulk testing scenario."""
    scenario = BulkTestingScenario(env)
    return scenario.create(**kwargs)


def create_error_scenario(env, **kwargs):
    """Quick access to error testing scenario."""
    scenario = ErrorTestingScenario(env)
    return scenario.create(**kwargs)


def create_performance_scenario(env, **kwargs):
    """Quick access to performance testing scenario."""
    scenario = PerformanceTestingScenario(env)
    return scenario.create(**kwargs)


def create_workflow_scenario(env, **kwargs):
    """Quick access to workflow testing scenario."""
    scenario = WorkflowTestingScenario(env)
    return scenario.create(**kwargs)

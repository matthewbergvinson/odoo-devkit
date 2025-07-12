"""
Maintenance Utilities for Royal Textiles Sales Test Fixtures
Task 4.4: Add test data fixtures and factories for consistent test scenarios

This module provides utilities for maintaining fixtures, keeping them
up-to-date with codebase changes, and managing test data lifecycle.

Based on best practices: "Keep your Fixtures Up-to-date" and provide
tools for fixture maintenance and validation.

Usage:
    # Validate all fixtures
    validator = FixtureValidator(env)
    validator.validate_all()

    # Clean up test data
    cleanup = TestDataCleanup(env)
    cleanup.cleanup_all_test_data()

    # Update fixtures with schema changes
    updater = FixtureUpdater(env)
    updater.update_for_schema_changes()
"""

import logging
from datetime import datetime, timedelta
from typing import Any, Dict, List, Set, Tuple

from .factories import TestDataManager
from .scenarios import (
    BulkTestingScenario,
    ComplexOrderScenario,
    ErrorTestingScenario,
    PerformanceTestingScenario,
    SimpleOrderScenario,
    WorkflowTestingScenario,
)

_logger = logging.getLogger(__name__)


class FixtureValidator:
    """
    Validates fixture data integrity and consistency.

    Ensures that all fixtures create valid data and maintain
    consistency with current schema and business rules.
    """

    def __init__(self, env):
        """Initialize validator with Odoo environment."""
        self.env = env
        self.errors = []
        self.warnings = []

    def validate_all(self) -> Dict[str, Any]:
        """
        Validate all fixture scenarios and return comprehensive report.

        Returns:
            Dictionary with validation results
        """
        _logger.info("Starting comprehensive fixture validation...")

        self.errors.clear()
        self.warnings.clear()

        validation_results = {
            'timestamp': datetime.now(),
            'total_scenarios': 0,
            'passed_scenarios': 0,
            'failed_scenarios': 0,
            'scenarios': {},
            'errors': [],
            'warnings': [],
            'summary': '',
        }

        # Define scenarios to test
        scenario_classes = [
            ('Simple Order', SimpleOrderScenario),
            ('Complex Order', ComplexOrderScenario),
            ('Bulk Testing', BulkTestingScenario),
            ('Error Testing', ErrorTestingScenario),
            ('Performance Testing', PerformanceTestingScenario),
            ('Workflow Testing', WorkflowTestingScenario),
        ]

        # Validate each scenario
        for scenario_name, scenario_class in scenario_classes:
            validation_results['total_scenarios'] += 1

            try:
                _logger.info(f"Validating {scenario_name} scenario...")
                result = self._validate_scenario(scenario_name, scenario_class)
                validation_results['scenarios'][scenario_name] = result

                if result['status'] == 'passed':
                    validation_results['passed_scenarios'] += 1
                else:
                    validation_results['failed_scenarios'] += 1

            except Exception as e:
                _logger.error(f"Error validating {scenario_name}: {str(e)}")
                validation_results['failed_scenarios'] += 1
                validation_results['scenarios'][scenario_name] = {
                    'status': 'failed',
                    'error': str(e),
                    'records_created': 0,
                }
                self.errors.append(f"{scenario_name}: {str(e)}")

        # Compile final results
        validation_results['errors'] = self.errors
        validation_results['warnings'] = self.warnings
        validation_results['summary'] = self._generate_summary(validation_results)

        _logger.info(f"Fixture validation completed: {validation_results['summary']}")
        return validation_results

    def _validate_scenario(self, scenario_name: str, scenario_class) -> Dict[str, Any]:
        """Validate a single scenario."""
        scenario = scenario_class(self.env)

        try:
            # Create scenario data
            start_time = datetime.now()
            scenario_data = scenario.create()
            creation_time = (datetime.now() - start_time).total_seconds()

            # Validate created data
            validation_result = self._validate_scenario_data(scenario_data)

            # Clean up
            scenario.cleanup()

            return {
                'status': 'passed' if validation_result['valid'] else 'failed',
                'creation_time': creation_time,
                'records_created': validation_result['record_count'],
                'validation_checks': validation_result['checks'],
                'errors': validation_result['errors'],
                'warnings': validation_result['warnings'],
            }

        except Exception as e:
            # Ensure cleanup even on error
            try:
                scenario.cleanup()
            except:
                pass
            raise e

    def _validate_scenario_data(self, scenario_data: Dict[str, Any]) -> Dict[str, Any]:
        """Validate the data created by a scenario."""
        checks = []
        errors = []
        warnings = []
        record_count = 0

        # Check for required scenario metadata
        required_keys = ['scenario_name', 'complexity', 'use_cases']
        for key in required_keys:
            if key in scenario_data:
                checks.append(f"✓ {key} present")
            else:
                errors.append(f"Missing required key: {key}")

        # Validate customer data
        if 'customer' in scenario_data:
            customer = scenario_data['customer']
            if customer and customer.exists():
                checks.append("✓ Customer record valid")
                record_count += 1

                # Check required customer fields
                if not customer.name:
                    errors.append("Customer missing name")
                if not customer.email:
                    warnings.append("Customer missing email")
            else:
                errors.append("Customer record invalid or doesn't exist")

        # Validate product data
        if 'products' in scenario_data:
            products = scenario_data['products']
            if isinstance(products, dict):
                for product_type, product in products.items():
                    if product and product.exists():
                        checks.append(f"✓ {product_type} product valid")
                        record_count += 1
                    else:
                        errors.append(f"{product_type} product invalid")

        # Validate sale order data
        if 'sale_order' in scenario_data:
            order = scenario_data['sale_order']
            if order and order.exists():
                checks.append("✓ Sale order valid")
                record_count += 1

                # Check order lines
                if order.order_line:
                    checks.append(f"✓ Order has {len(order.order_line)} lines")
                    record_count += len(order.order_line)
                else:
                    warnings.append("Sale order has no order lines")

                # Check order state
                if order.state in ['draft', 'sale']:
                    checks.append(f"✓ Order state valid: {order.state}")
                else:
                    warnings.append(f"Unusual order state: {order.state}")
            else:
                errors.append("Sale order invalid or doesn't exist")

        # Validate installation data
        if 'installation' in scenario_data:
            installation = scenario_data['installation']
            if installation and installation.exists():
                checks.append("✓ Installation record valid")
                record_count += 1

                # Check installation fields
                if installation.estimated_hours > 0:
                    checks.append("✓ Installation has positive estimated hours")
                else:
                    errors.append("Installation has invalid estimated hours")

                if installation.scheduled_date:
                    checks.append("✓ Installation has scheduled date")
                else:
                    warnings.append("Installation missing scheduled date")
            else:
                errors.append("Installation record invalid or doesn't exist")

        # Validate bulk data scenarios
        for bulk_key in ['customers', 'orders', 'installations']:
            if bulk_key in scenario_data:
                bulk_data = scenario_data[bulk_key]
                if isinstance(bulk_data, list):
                    valid_records = sum(1 for record in bulk_data if record.exists())
                    checks.append(f"✓ {valid_records}/{len(bulk_data)} {bulk_key} valid")
                    record_count += valid_records

                    if valid_records < len(bulk_data):
                        errors.append(f"Some {bulk_key} records are invalid")

        return {
            'valid': len(errors) == 0,
            'record_count': record_count,
            'checks': checks,
            'errors': errors,
            'warnings': warnings,
        }

    def _generate_summary(self, results: Dict[str, Any]) -> str:
        """Generate human-readable validation summary."""
        total = results['total_scenarios']
        passed = results['passed_scenarios']
        failed = results['failed_scenarios']

        if failed == 0:
            return f"All {total} scenarios passed validation ✓"
        else:
            return f"{passed}/{total} scenarios passed, {failed} failed ✗"


class TestDataCleanup:
    """
    Manages cleanup of test data and orphaned records.

    Provides safe cleanup operations to maintain test database hygiene.
    """

    def __init__(self, env):
        """Initialize cleanup utility with Odoo environment."""
        self.env = env

    def cleanup_all_test_data(self, dry_run: bool = True) -> Dict[str, Any]:
        """
        Clean up all test data created by fixtures.

        Args:
            dry_run: If True, only report what would be deleted

        Returns:
            Dictionary with cleanup results
        """
        _logger.info(f"Starting test data cleanup (dry_run={dry_run})...")

        cleanup_results = {
            'timestamp': datetime.now(),
            'dry_run': dry_run,
            'deleted_records': {},
            'total_deleted': 0,
            'errors': [],
        }

        # Define test data patterns to clean up
        cleanup_targets = [
            ('royal.installation', self._find_test_installations),
            ('sale.order', self._find_test_orders),
            ('res.partner', self._find_test_customers),
            ('product.product', self._find_test_products),
            ('product.category', self._find_test_categories),
        ]

        # Process each cleanup target
        for model_name, finder_method in cleanup_targets:
            try:
                records_to_delete = finder_method()
                count = len(records_to_delete)

                if count > 0:
                    _logger.info(f"Found {count} {model_name} records to clean up")

                    if not dry_run:
                        # Actually delete the records
                        try:
                            records_to_delete.unlink()
                            cleanup_results['deleted_records'][model_name] = count
                            cleanup_results['total_deleted'] += count
                        except Exception as e:
                            error_msg = f"Error deleting {model_name}: {str(e)}"
                            _logger.error(error_msg)
                            cleanup_results['errors'].append(error_msg)
                    else:
                        # Dry run - just record what would be deleted
                        cleanup_results['deleted_records'][model_name] = count
                        cleanup_results['total_deleted'] += count

            except Exception as e:
                error_msg = f"Error finding {model_name} records: {str(e)}"
                _logger.error(error_msg)
                cleanup_results['errors'].append(error_msg)

        summary = (
            f"Test data cleanup completed. "
            f"{'Would delete' if dry_run else 'Deleted'} "
            f"{cleanup_results['total_deleted']} records"
        )

        _logger.info(summary)
        cleanup_results['summary'] = summary

        return cleanup_results

    def _find_test_installations(self):
        """Find test installation records."""
        # Look for installations with test-like names or recent creation
        domain = [
            '|',
            ('name', 'ilike', 'Installation for'),
            ('name', 'ilike', 'Test'),
            ('create_date', '>=', datetime.now().date() - timedelta(days=1)),
        ]
        return self.env['royal.installation'].search(domain)

    def _find_test_orders(self):
        """Find test sale order records."""
        # Look for orders created recently or with test patterns
        domain = [
            '|',
            ('create_date', '>=', datetime.now().date() - timedelta(days=1)),
            ('partner_id.name', 'ilike', 'Test'),
        ]
        return self.env['sale.order'].search(domain)

    def _find_test_customers(self):
        """Find test customer records."""
        # Look for customers with test-like names
        test_patterns = [
            'Johnson Family',
            'Martinez Home',
            'Thompson &',
            'Denver Medical',
            'Riverside Office',
            'Grand Mountain',
            'Test',
            'Example',
        ]

        domain = []
        for pattern in test_patterns:
            if domain:
                domain.append('|')
            domain.extend([('name', 'ilike', pattern)])

        if domain:
            return self.env['res.partner'].search(domain)
        else:
            return self.env['res.partner']

    def _find_test_products(self):
        """Find test product records."""
        # Look for products with test-like names
        test_patterns = [
            'Premium 2" Faux Wood',
            'Aluminum Mini Blinds',
            'Cellular Honeycomb',
            'Smart Motorized',
            'Professional Installation',
            'Test Product',
        ]

        domain = []
        for pattern in test_patterns:
            if domain:
                domain.append('|')
            domain.extend([('name', 'ilike', pattern)])

        if domain:
            return self.env['product.product'].search(domain)
        else:
            return self.env['product.product']

    def _find_test_categories(self):
        """Find test product categories."""
        domain = [('name', '=', 'Window Treatments')]
        return self.env['product.category'].search(domain)

    def cleanup_old_test_data(self, days_old: int = 7) -> Dict[str, Any]:
        """Clean up test data older than specified days."""
        cutoff_date = datetime.now() - timedelta(days=days_old)

        _logger.info(f"Cleaning up test data older than {days_old} days...")

        # Find old test records
        old_installations = self.env['royal.installation'].search(
            [('create_date', '<', cutoff_date), ('name', 'ilike', 'Test')]
        )

        old_orders = self.env['sale.order'].search(
            [('create_date', '<', cutoff_date), ('partner_id.name', 'ilike', 'Test')]
        )

        cleanup_count = 0

        # Delete old records
        if old_installations:
            old_installations.unlink()
            cleanup_count += len(old_installations)

        if old_orders:
            old_orders.unlink()
            cleanup_count += len(old_orders)

        return {
            'timestamp': datetime.now(),
            'cutoff_date': cutoff_date,
            'deleted_count': cleanup_count,
        }


class FixtureUpdater:
    """
    Updates fixtures when schema or business rules change.

    Helps maintain fixture compatibility with evolving codebase.
    """

    def __init__(self, env):
        """Initialize updater with Odoo environment."""
        self.env = env

    def check_schema_compatibility(self) -> Dict[str, Any]:
        """
        Check if current fixtures are compatible with schema.

        Returns:
            Dictionary with compatibility check results
        """
        _logger.info("Checking fixture schema compatibility...")

        compatibility_results = {
            'timestamp': datetime.now(),
            'compatible': True,
            'issues': [],
            'recommendations': [],
        }

        # Check Royal Textiles module models
        models_to_check = [
            'royal.installation',
            'sale.order',
            'res.partner',
            'product.product',
        ]

        for model_name in models_to_check:
            try:
                model = self.env[model_name]

                # Check if model exists and is accessible
                if not model:
                    compatibility_results['compatible'] = False
                    compatibility_results['issues'].append(f"Model {model_name} not found")
                    continue

                # Check required fields based on our fixtures
                required_checks = self._get_required_field_checks(model_name)

                for field_name, field_type in required_checks.items():
                    if field_name not in model._fields:
                        compatibility_results['compatible'] = False
                        compatibility_results['issues'].append(f"Missing field {model_name}.{field_name}")
                    else:
                        # Check field type compatibility
                        actual_field = model._fields[field_name]
                        if not self._check_field_type_compatibility(actual_field, field_type):
                            compatibility_results['issues'].append(f"Field type mismatch: {model_name}.{field_name}")

            except Exception as e:
                compatibility_results['compatible'] = False
                compatibility_results['issues'].append(f"Error checking {model_name}: {str(e)}")

        # Generate recommendations
        if compatibility_results['issues']:
            compatibility_results['recommendations'] = [
                "Update fixture data to match current schema",
                "Check for missing custom modules",
                "Verify field name changes in recent updates",
                "Consider updating fixture factory methods",
            ]

        return compatibility_results

    def _get_required_field_checks(self, model_name: str) -> Dict[str, str]:
        """Get required field checks for a model."""
        field_checks = {
            'royal.installation': {
                'name': 'char',
                'sale_order_id': 'many2one',
                'customer_id': 'many2one',
                'estimated_hours': 'float',
                'scheduled_date': 'datetime',
                'status': 'selection',
            },
            'sale.order': {
                'partner_id': 'many2one',
                'date_order': 'datetime',
                'state': 'selection',
                'installation_status': 'selection',  # Custom field
            },
            'res.partner': {
                'name': 'char',
                'email': 'char',
                'phone': 'char',
            },
            'product.product': {
                'name': 'char',
                'type': 'selection',
                'list_price': 'float',
            },
        }

        return field_checks.get(model_name, {})

    def _check_field_type_compatibility(self, actual_field, expected_type: str) -> bool:
        """Check if field type is compatible."""
        field_type_map = {
            'char': ['Char'],
            'text': ['Text'],
            'float': ['Float'],
            'integer': ['Integer'],
            'boolean': ['Boolean'],
            'date': ['Date'],
            'datetime': ['Datetime'],
            'selection': ['Selection'],
            'many2one': ['Many2one'],
            'one2many': ['One2many'],
            'many2many': ['Many2many'],
        }

        expected_types = field_type_map.get(expected_type, [])
        actual_type = type(actual_field).__name__

        return actual_type in expected_types


class FixtureMetrics:
    """
    Collects and reports metrics on fixture usage and performance.

    Helps optimize fixture performance and identify issues.
    """

    def __init__(self, env):
        """Initialize metrics collector."""
        self.env = env
        self.metrics = {}

    def collect_performance_metrics(self) -> Dict[str, Any]:
        """
        Collect performance metrics for all fixture scenarios.

        Returns:
            Dictionary with performance data
        """
        _logger.info("Collecting fixture performance metrics...")

        metrics = {
            'timestamp': datetime.now(),
            'scenarios': {},
            'summary': {},
        }

        # Test each scenario for performance
        scenario_classes = [
            ('Simple', SimpleOrderScenario),
            ('Complex', ComplexOrderScenario),
            ('Bulk', BulkTestingScenario),
        ]

        for name, scenario_class in scenario_classes:
            try:
                start_time = datetime.now()
                scenario = scenario_class(self.env)

                # Create scenario
                create_start = datetime.now()
                scenario_data = scenario.create()
                create_time = (datetime.now() - create_start).total_seconds()

                # Count records
                record_count = self._count_scenario_records(scenario_data)

                # Cleanup
                cleanup_start = datetime.now()
                scenario.cleanup()
                cleanup_time = (datetime.now() - cleanup_start).total_seconds()

                total_time = (datetime.now() - start_time).total_seconds()

                metrics['scenarios'][name] = {
                    'total_time': total_time,
                    'create_time': create_time,
                    'cleanup_time': cleanup_time,
                    'record_count': record_count,
                    'records_per_second': record_count / create_time if create_time > 0 else 0,
                }

            except Exception as e:
                _logger.error(f"Error measuring {name} scenario: {str(e)}")
                metrics['scenarios'][name] = {
                    'error': str(e),
                }

        # Calculate summary statistics
        valid_scenarios = [s for s in metrics['scenarios'].values() if 'error' not in s]
        if valid_scenarios:
            metrics['summary'] = {
                'average_create_time': sum(s['create_time'] for s in valid_scenarios) / len(valid_scenarios),
                'average_cleanup_time': sum(s['cleanup_time'] for s in valid_scenarios) / len(valid_scenarios),
                'total_record_count': sum(s['record_count'] for s in valid_scenarios),
                'average_records_per_second': sum(s['records_per_second'] for s in valid_scenarios)
                / len(valid_scenarios),
            }

        return metrics

    def _count_scenario_records(self, scenario_data: Dict[str, Any]) -> int:
        """Count total records created in a scenario."""
        count = 0

        # Count individual records
        for key in ['customer', 'installation', 'sale_order']:
            if key in scenario_data and scenario_data[key]:
                count += 1

        # Count product catalog
        if 'products' in scenario_data and isinstance(scenario_data['products'], dict):
            count += len(scenario_data['products'])

        # Count bulk records
        for key in ['customers', 'orders', 'installations']:
            if key in scenario_data and isinstance(scenario_data[key], list):
                count += len(scenario_data[key])

        return count

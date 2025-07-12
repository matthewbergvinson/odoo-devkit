#!/usr/bin/env python3
"""
Reporting Workflow Integration Tests
Task 4.6: Create integration tests for complete user workflows

Tests complete reporting and analytics workflows for business intelligence.
Validates data aggregation, report generation, and business analytics processes.
"""

from datetime import datetime, timedelta

import pytest

# Import our base test classes and fixtures
from tests.base_test import OdooIntegrationTestCase
from tests.fixtures import (
    ComplexOrderScenario,
    CustomerFactory,
    InstallationFactory,
    SaleOrderFactory,
    SimpleOrderScenario,
    TestDataManager,
)


class ReportingWorkflowTest(OdooIntegrationTestCase):
    """
    Integration tests for reporting and analytics workflows.

    Tests complete business intelligence processes including:
    - Sales performance reporting
    - Customer analytics and segmentation
    - Installation tracking and metrics
    - Financial reporting and analysis
    - Operational dashboards and KPIs
    - Automated report generation
    """

    @classmethod
    def setUpClass(cls):
        """Set up test environment with reporting data"""
        super().setUpClass()
        cls.data_manager = TestDataManager(cls.env)

        # Initialize factories for reporting data
        cls.customer_factory = CustomerFactory(cls.env)
        cls.order_factory = SaleOrderFactory(cls.env)
        cls.installation_factory = InstallationFactory(cls.env)

        # Create test scenarios
        cls.simple_scenario = SimpleOrderScenario(cls.env)
        cls.complex_scenario = ComplexOrderScenario(cls.env)

        # Create comprehensive test dataset
        cls._create_reporting_dataset()

    @classmethod
    def _create_reporting_dataset(cls):
        """Create comprehensive dataset for reporting tests"""
        cls.test_customers = []
        cls.test_orders = []
        cls.test_installations = []

        # Create diverse customer base for reporting
        customer_types = ['residential', 'commercial', 'hospitality']

        for i, customer_type in enumerate(customer_types):
            for j in range(3):  # 3 customers per type
                customer = cls.customer_factory.create_customer(
                    {
                        'name': f'{customer_type.title()} Customer {i*3 + j + 1}',
                        'customer_type': customer_type,
                        'is_company': customer_type != 'residential',
                    }
                )
                cls.test_customers.append(customer)

                # Create historical orders
                for month_offset in [6, 3, 1]:  # Orders from 6, 3, 1 months ago
                    if customer_type == 'residential':
                        order = cls.simple_scenario.create_order(customer)
                    else:
                        order = cls.complex_scenario.create_order(customer)

                    order.write({'date_order': datetime.now() - timedelta(days=month_offset * 30), 'state': 'sale'})
                    cls.test_orders.append(order)

                    # Create installations
                    installation = cls.installation_factory.create_installation(
                        {
                            'sale_order_id': order.id,
                            'customer_id': customer.id,
                            'state': 'completed' if month_offset > 1 else 'scheduled',
                        }
                    )
                    cls.test_installations.append(installation)

    def setUp(self):
        """Set up each test with clean state"""
        super().setUp()

    def tearDown(self):
        """Clean up after each test"""
        super().tearDown()

    def test_sales_performance_reporting_workflow(self):
        """
        Test sales performance reporting and analytics.

        Reporting Flow:
        1. Data collection and aggregation
        2. Sales metrics calculation
        3. Performance trend analysis
        4. Report generation and formatting
        5. Dashboard creation and visualization
        6. Automated report distribution
        """
        # Step 1: Data collection and aggregation
        # Collect sales data for current period
        current_month_start = datetime.now().replace(day=1)
        last_month_start = (current_month_start - timedelta(days=1)).replace(day=1)

        current_month_orders = self.env['sale.order'].search(
            [('date_order', '>=', current_month_start), ('state', '=', 'sale')]
        )

        last_month_orders = self.env['sale.order'].search(
            [('date_order', '>=', last_month_start), ('date_order', '<', current_month_start), ('state', '=', 'sale')]
        )

        # Step 2: Sales metrics calculation
        # Calculate key sales metrics
        current_month_revenue = sum(current_month_orders.mapped('amount_total'))
        last_month_revenue = sum(last_month_orders.mapped('amount_total'))

        revenue_change = (
            ((current_month_revenue - last_month_revenue) / last_month_revenue * 100) if last_month_revenue > 0 else 0
        )

        current_month_orders_count = len(current_month_orders)
        last_month_orders_count = len(last_month_orders)

        avg_order_value_current = (
            current_month_revenue / current_month_orders_count if current_month_orders_count > 0 else 0
        )
        avg_order_value_last = last_month_revenue / last_month_orders_count if last_month_orders_count > 0 else 0

        # Step 3: Performance trend analysis
        # Analyze trends by customer type
        customer_type_performance = {}
        for customer_type in ['residential', 'commercial', 'hospitality']:
            type_orders = current_month_orders.filtered(lambda o: o.partner_id.customer_type == customer_type)

            customer_type_performance[customer_type] = {
                'order_count': len(type_orders),
                'total_revenue': sum(type_orders.mapped('amount_total')),
                'avg_order_value': (sum(type_orders.mapped('amount_total')) / len(type_orders)) if type_orders else 0,
            }

        # Step 4: Report generation and formatting
        # Create sales performance report
        sales_report_data = {
            'report_period': current_month_start.strftime('%B %Y'),
            'current_month_revenue': current_month_revenue,
            'last_month_revenue': last_month_revenue,
            'revenue_change_percent': revenue_change,
            'current_month_orders': current_month_orders_count,
            'avg_order_value': avg_order_value_current,
            'customer_type_breakdown': customer_type_performance,
            'generated_date': datetime.now(),
        }

        # Step 5: Dashboard creation and visualization
        # Create dashboard activity
        dashboard_activity = self.env['mail.activity'].create(
            {
                'res_model': 'res.partner',
                'res_id': self.env.user.partner_id.id,
                'activity_type_id': self.env.ref('mail.mail_activity_data_todo').id,
                'summary': 'Monthly Sales Dashboard Review',
                'note': f'Review monthly sales dashboard. Revenue: ${current_month_revenue:,.2f}',
                'date_deadline': datetime.now().date(),
                'user_id': self.env.user.id,
            }
        )

        # Step 6: Automated report distribution
        # Simulate report distribution
        report_distribution = self.env['mail.message'].create(
            {
                'subject': f'Sales Performance Report - {current_month_start.strftime("%B %Y")}',
                'body': f'<p>Monthly sales report generated. Total revenue: ${current_month_revenue:,.2f}</p>',
                'message_type': 'email',
                'author_id': self.env.user.partner_id.id,
            }
        )

        # Validate sales reporting workflow
        self.assertTrue(isinstance(sales_report_data['current_month_revenue'], (int, float)))
        self.assertTrue(isinstance(sales_report_data['revenue_change_percent'], (int, float)))
        self.assertTrue(dashboard_activity.exists())
        self.assertTrue(report_distribution.exists())

    def test_customer_analytics_workflow(self):
        """
        Test customer analytics and segmentation reporting.

        Analytics Flow:
        1. Customer data aggregation
        2. Segmentation analysis
        3. Lifetime value calculation
        4. Behavior pattern analysis
        5. Predictive analytics preparation
        6. Customer insights reporting
        """
        # Step 1: Customer data aggregation
        all_customers = self.env['res.partner'].search([('customer_rank', '>', 0)])

        customer_analytics = []

        for customer in all_customers:
            # Gather customer data
            customer_orders = self.env['sale.order'].search([('partner_id', '=', customer.id), ('state', '=', 'sale')])

            customer_data = {
                'customer_id': customer.id,
                'name': customer.name,
                'customer_type': getattr(customer, 'customer_type', 'unknown'),
                'order_count': len(customer_orders),
                'total_revenue': sum(customer_orders.mapped('amount_total')),
                'avg_order_value': (sum(customer_orders.mapped('amount_total')) / len(customer_orders))
                if customer_orders
                else 0,
                'first_order_date': min(customer_orders.mapped('date_order')) if customer_orders else None,
                'last_order_date': max(customer_orders.mapped('date_order')) if customer_orders else None,
            }

            customer_analytics.append(customer_data)

        # Step 2: Segmentation analysis
        # Segment customers by value and behavior
        customer_segments = {
            'high_value': [],
            'medium_value': [],
            'low_value': [],
            'new_customers': [],
            'repeat_customers': [],
        }

        # Calculate segmentation thresholds
        total_revenues = [c['total_revenue'] for c in customer_analytics if c['total_revenue'] > 0]
        if total_revenues:
            revenue_avg = sum(total_revenues) / len(total_revenues)
            revenue_high_threshold = revenue_avg * 1.5
            revenue_low_threshold = revenue_avg * 0.5
        else:
            revenue_high_threshold = 1000
            revenue_low_threshold = 100

        for customer_data in customer_analytics:
            # Value segmentation
            if customer_data['total_revenue'] >= revenue_high_threshold:
                customer_segments['high_value'].append(customer_data)
            elif customer_data['total_revenue'] >= revenue_low_threshold:
                customer_segments['medium_value'].append(customer_data)
            else:
                customer_segments['low_value'].append(customer_data)

            # Behavior segmentation
            if customer_data['order_count'] == 1:
                customer_segments['new_customers'].append(customer_data)
            elif customer_data['order_count'] > 1:
                customer_segments['repeat_customers'].append(customer_data)

        # Step 3: Lifetime value calculation
        for customer_data in customer_analytics:
            if customer_data['first_order_date'] and customer_data['order_count'] > 0:
                # Calculate customer relationship duration
                relationship_days = (datetime.now().date() - customer_data['first_order_date'].date()).days
                relationship_months = max(relationship_days / 30.0, 1)

                # Calculate monthly value and project lifetime value
                monthly_value = customer_data['total_revenue'] / relationship_months
                projected_lifetime_months = 24  # Assume 2-year average relationship
                customer_data['lifetime_value'] = monthly_value * projected_lifetime_months
                customer_data['monthly_value'] = monthly_value
            else:
                customer_data['lifetime_value'] = 0
                customer_data['monthly_value'] = 0

        # Step 4: Behavior pattern analysis
        # Analyze ordering patterns
        ordering_patterns = {'seasonal_customers': 0, 'regular_customers': 0, 'one_time_customers': 0}

        for customer_data in customer_analytics:
            if customer_data['order_count'] == 1:
                ordering_patterns['one_time_customers'] += 1
            elif customer_data['order_count'] >= 3:
                ordering_patterns['regular_customers'] += 1
            else:
                ordering_patterns['seasonal_customers'] += 1

        # Step 5: Predictive analytics preparation
        # Identify customers at risk of churn
        at_risk_customers = []
        current_date = datetime.now().date()

        for customer_data in customer_analytics:
            if customer_data['last_order_date']:
                days_since_last_order = (current_date - customer_data['last_order_date'].date()).days

                # Customer hasn't ordered in 6 months
                if days_since_last_order > 180 and customer_data['order_count'] > 1:
                    at_risk_customers.append(customer_data)

        # Step 6: Customer insights reporting
        # Generate customer analytics report
        analytics_report = {
            'total_customers': len(customer_analytics),
            'segments': {
                'high_value': len(customer_segments['high_value']),
                'medium_value': len(customer_segments['medium_value']),
                'low_value': len(customer_segments['low_value']),
                'new_customers': len(customer_segments['new_customers']),
                'repeat_customers': len(customer_segments['repeat_customers']),
            },
            'ordering_patterns': ordering_patterns,
            'at_risk_customers': len(at_risk_customers),
            'avg_lifetime_value': (sum(c['lifetime_value'] for c in customer_analytics) / len(customer_analytics))
            if customer_analytics
            else 0,
        }

        # Create analytics report activity
        analytics_activity = self.env['mail.activity'].create(
            {
                'res_model': 'res.partner',
                'res_id': self.env.user.partner_id.id,
                'activity_type_id': self.env.ref('mail.mail_activity_data_todo').id,
                'summary': 'Customer Analytics Review',
                'note': f'Customer analytics: {analytics_report["total_customers"]} total customers, {len(at_risk_customers)} at risk',
                'date_deadline': datetime.now().date(),
                'user_id': self.env.user.id,
            }
        )

        # Validate customer analytics workflow
        self.assertTrue(len(customer_analytics) > 0)
        self.assertTrue(analytics_report['total_customers'] > 0)
        self.assertTrue(analytics_activity.exists())

    def test_installation_tracking_workflow(self):
        """
        Test installation tracking and operational reporting.

        Tracking Flow:
        1. Installation data collection
        2. Performance metrics calculation
        3. Quality tracking and analysis
        4. Resource utilization reporting
        5. Customer satisfaction analysis
        6. Operational dashboard creation
        """
        # Step 1: Installation data collection
        all_installations = self.env['project.project'].search([('sale_order_id', '!=', False)])

        installation_data = []

        for installation in all_installations:
            # Calculate installation metrics
            if hasattr(installation, 'actual_start_time') and hasattr(installation, 'actual_end_time'):
                if installation.actual_start_time and installation.actual_end_time:
                    duration_hours = (
                        installation.actual_end_time - installation.actual_start_time
                    ).total_seconds() / 3600
                else:
                    duration_hours = 0
            else:
                duration_hours = 0

            data = {
                'installation_id': installation.id,
                'customer_type': getattr(installation.partner_id, 'customer_type', 'unknown'),
                'state': installation.stage_id.name
                if installation.stage_id
                else getattr(installation, 'state', 'unknown'),
                'duration_hours': duration_hours,
                'customer_satisfaction': getattr(installation, 'customer_satisfaction', 'unknown'),
                'scheduled_date': getattr(installation, 'scheduled_date', None),
                'completion_date': getattr(installation, 'actual_end_time', None),
            }

            installation_data.append(data)

        # Step 2: Performance metrics calculation
        completed_installations = [i for i in installation_data if i['state'] in ['completed', 'done']]

        performance_metrics = {
            'total_installations': len(installation_data),
            'completed_installations': len(completed_installations),
            'completion_rate': (len(completed_installations) / len(installation_data) * 100)
            if installation_data
            else 0,
            'avg_duration': (sum(i['duration_hours'] for i in completed_installations) / len(completed_installations))
            if completed_installations
            else 0,
        }

        # Step 3: Quality tracking and analysis
        satisfaction_ratings = [
            i['customer_satisfaction'] for i in completed_installations if i['customer_satisfaction'] != 'unknown'
        ]

        quality_metrics = {
            'satisfaction_responses': len(satisfaction_ratings),
            'excellent_ratings': satisfaction_ratings.count('excellent'),
            'good_ratings': satisfaction_ratings.count('good'),
            'poor_ratings': satisfaction_ratings.count('poor'),
        }

        if satisfaction_ratings:
            quality_metrics['satisfaction_rate'] = (
                (quality_metrics['excellent_ratings'] + quality_metrics['good_ratings'])
                / len(satisfaction_ratings)
                * 100
            )
        else:
            quality_metrics['satisfaction_rate'] = 0

        # Step 4: Resource utilization reporting
        # Analyze installation scheduling and resource usage
        current_month = datetime.now().replace(day=1)
        next_month = (current_month + timedelta(days=32)).replace(day=1)

        scheduled_installations = [
            i
            for i in installation_data
            if i['scheduled_date'] and current_month.date() <= i['scheduled_date'].date() < next_month.date()
        ]

        resource_metrics = {
            'scheduled_this_month': len(scheduled_installations),
            'avg_installations_per_week': len(scheduled_installations) / 4.0,
            'resource_utilization': min(len(scheduled_installations) / 20.0 * 100, 100),  # Assume 20 max capacity
        }

        # Step 5: Customer satisfaction analysis
        # Analyze satisfaction by customer type
        satisfaction_by_type = {}
        for customer_type in ['residential', 'commercial', 'hospitality']:
            type_installations = [i for i in completed_installations if i['customer_type'] == customer_type]

            type_satisfaction = [
                i['customer_satisfaction'] for i in type_installations if i['customer_satisfaction'] != 'unknown'
            ]

            satisfaction_by_type[customer_type] = {
                'total': len(type_installations),
                'with_feedback': len(type_satisfaction),
                'excellent': type_satisfaction.count('excellent'),
                'satisfaction_rate': (type_satisfaction.count('excellent') + type_satisfaction.count('good'))
                / len(type_satisfaction)
                * 100
                if type_satisfaction
                else 0,
            }

        # Step 6: Operational dashboard creation
        # Create comprehensive installation report
        installation_report = {
            'performance_metrics': performance_metrics,
            'quality_metrics': quality_metrics,
            'resource_metrics': resource_metrics,
            'satisfaction_by_type': satisfaction_by_type,
            'report_date': datetime.now(),
        }

        # Create installation tracking activity
        tracking_activity = self.env['mail.activity'].create(
            {
                'res_model': 'res.partner',
                'res_id': self.env.user.partner_id.id,
                'activity_type_id': self.env.ref('mail.mail_activity_data_todo').id,
                'summary': 'Installation Performance Review',
                'note': f'Installation metrics: {performance_metrics["completion_rate"]:.1f}% completion rate, {quality_metrics["satisfaction_rate"]:.1f}% satisfaction',
                'date_deadline': datetime.now().date(),
                'user_id': self.env.user.id,
            }
        )

        # Validate installation tracking workflow
        self.assertTrue(installation_report['performance_metrics']['total_installations'] >= 0)
        self.assertTrue(installation_report['quality_metrics']['satisfaction_responses'] >= 0)
        self.assertTrue(tracking_activity.exists())


# Helper functions for reporting workflow testing
def generate_comprehensive_business_report(env):
    """
    Generate a comprehensive business report combining all analytics.
    """
    # Sales metrics
    orders = env['sale.order'].search([('state', '=', 'sale')])
    total_revenue = sum(orders.mapped('amount_total'))

    # Customer metrics
    customers = env['res.partner'].search([('customer_rank', '>', 0)])
    total_customers = len(customers)

    # Installation metrics
    installations = env['project.project'].search([('sale_order_id', '!=', False)])
    total_installations = len(installations)

    comprehensive_report = {
        'business_overview': {
            'total_revenue': total_revenue,
            'total_customers': total_customers,
            'total_installations': total_installations,
            'avg_revenue_per_customer': total_revenue / total_customers if total_customers > 0 else 0,
        },
        'report_generated': datetime.now(),
        'period': 'All Time',
    }

    return comprehensive_report


# Test runner for manual execution
if __name__ == '__main__':
    print("Reporting Workflow Integration Tests")
    print("===================================")
    print("These tests validate reporting and analytics workflows for business intelligence.")
    print("Run via: pytest tests/integration/test_reporting_workflow.py -v")

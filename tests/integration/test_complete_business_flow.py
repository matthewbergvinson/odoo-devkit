#!/usr/bin/env python3
"""
Complete Business Flow Integration Tests
Task 4.6: Create integration tests for complete user workflows

Tests complete end-to-end business scenarios combining all workflows:
customer lifecycle, sales orders, installations, and follow-up processes.
"""

from datetime import datetime, timedelta

import pytest

# Import our base test classes and fixtures
from tests.base_test import OdooIntegrationTestCase
from tests.fixtures import (
    ComplexOrderScenario,
    CustomerFactory,
    InstallationFactory,
    ProductFactory,
    SaleOrderFactory,
    SimpleOrderScenario,
    TestDataManager,
)


class CompleteBusinesFlowTest(OdooIntegrationTestCase):
    """
    End-to-end integration tests for complete Royal Textiles business flows.

    Tests complete customer journeys including:
    - Initial customer contact through installation completion
    - Multi-order customer relationships
    - Complex commercial projects
    - Customer service and follow-up processes
    - Business analytics and reporting workflows
    """

    @classmethod
    def setUpClass(cls):
        """Set up test environment for complete business flows"""
        super().setUpClass()
        cls.data_manager = TestDataManager(cls.env)

        # Initialize all factories needed for complete testing
        cls.customer_factory = CustomerFactory(cls.env)
        cls.product_factory = ProductFactory(cls.env)
        cls.order_factory = SaleOrderFactory(cls.env)
        cls.installation_factory = InstallationFactory(cls.env)

        # Set up order scenarios
        cls.simple_scenario = SimpleOrderScenario(cls.env)
        cls.complex_scenario = ComplexOrderScenario(cls.env)

    def setUp(self):
        """Set up each test with clean state"""
        super().setUp()

    def tearDown(self):
        """Clean up after each test"""
        # Clean up all factories
        for factory in [self.customer_factory, self.product_factory, self.order_factory, self.installation_factory]:
            factory.cleanup()
        super().tearDown()

    def test_residential_customer_complete_journey(self):
        """
        Test complete residential customer journey from initial contact to completion.

        Business Flow:
        1. Initial customer inquiry and onboarding
        2. Consultation and quote generation
        3. Order confirmation and processing
        4. Installation scheduling and execution
        5. Customer satisfaction and follow-up
        6. Relationship maintenance and future opportunities
        """
        # Step 1: Initial customer inquiry and onboarding
        residential_customer = self.customer_factory.create_customer(
            {
                'name': 'Henderson Family Residence',
                'customer_type': 'residential',
                'phone': '(303) 555-2468',
                'email': 'sarah.henderson@email.com',
                'street': '2145 Maple Grove Lane',
                'city': 'Denver',
                'zip': '80206',
                'inquiry_source': 'google_search',
                'initial_interest': 'bedroom window treatments',
            }
        )

        # Customer onboarding process
        residential_customer._assign_customer_number()
        residential_customer._assign_sales_representative()

        # Initial contact activity
        initial_contact = self.env['mail.activity'].create(
            {
                'res_model': 'res.partner',
                'res_id': residential_customer.id,
                'activity_type_id': self.env.ref('mail.mail_activity_data_call').id,
                'summary': 'Initial consultation call',
                'note': 'Discuss bedroom window treatment needs and schedule in-home consultation',
                'date_deadline': datetime.now().date() + timedelta(days=1),
                'user_id': self.env.user.id,
            }
        )

        # Complete initial contact
        initial_contact.action_done()

        # Step 2: Consultation and quote generation
        consultation_activity = self.env['mail.activity'].create(
            {
                'res_model': 'res.partner',
                'res_id': residential_customer.id,
                'activity_type_id': self.env.ref('mail.mail_activity_data_meeting').id,
                'summary': 'In-home consultation',
                'note': 'Measure windows and discuss options for master bedroom and guest room',
                'date_deadline': datetime.now().date() + timedelta(days=3),
                'user_id': self.env.user.id,
            }
        )

        # Complete consultation
        consultation_activity.action_done()

        # Generate quote from consultation
        quote = self.simple_scenario.create_order(residential_customer)
        quote.write(
            {
                'note': 'Quote based on in-home consultation. Includes cellular shades for master bedroom and faux wood blinds for guest room.',
                'validity_date': datetime.now().date() + timedelta(days=30),
            }
        )

        # Add consultation notes
        consultation_notes = self.env['mail.message'].create(
            {
                'res_id': residential_customer.id,
                'model': 'res.partner',
                'message_type': 'comment',
                'body': '<p>In-home consultation completed. Customer interested in light-filtering cellular shades for privacy and faux wood blinds for guest room. Budget range: $800-1200.</p>',
                'author_id': self.env.user.partner_id.id,
            }
        )

        # Step 3: Order confirmation and processing
        # Send quote to customer
        quote.action_quotation_send()

        # Customer approves after 1 week
        quote_followup = self.env['mail.activity'].create(
            {
                'res_model': 'sale.order',
                'res_id': quote.id,
                'activity_type_id': self.env.ref('mail.mail_activity_data_call').id,
                'summary': 'Quote follow-up call',
                'note': 'Follow up on quote, answer questions, and get decision',
                'date_deadline': datetime.now().date() + timedelta(days=7),
                'user_id': self.env.user.id,
            }
        )

        quote_followup.action_done()

        # Customer confirms order
        quote.action_confirm()

        # Validate order processing
        self.assertEqual(quote.state, 'sale')
        self.assertTrue(quote.confirmation_date)

        # Step 4: Installation scheduling and execution
        # Create installation project
        installation = self.installation_factory.create_installation(
            {
                'sale_order_id': quote.id,
                'customer_id': residential_customer.id,
                'installation_type': 'residential_standard',
            }
        )

        # Schedule installation
        installation_date = datetime.now() + timedelta(days=10)
        installation.write({'scheduled_date': installation_date, 'state': 'scheduled'})

        # Installation scheduling communication
        install_scheduling = self.env['mail.activity'].create(
            {
                'res_model': 'project.project',
                'res_id': installation.id,
                'activity_type_id': self.env.ref('mail.mail_activity_data_call').id,
                'summary': 'Installation appointment scheduling',
                'note': f'Confirm installation appointment for {installation_date.strftime("%Y-%m-%d")}',
                'date_deadline': installation_date.date() - timedelta(days=2),
                'user_id': self.env.user.id,
            }
        )

        install_scheduling.action_done()

        # Execute installation
        installation.write({'state': 'in_progress', 'actual_start_time': installation_date})

        # Complete installation phases
        installation_tasks = [
            'Install cellular shades - Master bedroom',
            'Install faux wood blinds - Guest room',
            'Customer walkthrough and training',
        ]

        for task_name in installation_tasks:
            task = self.env['project.task'].create(
                {
                    'name': task_name,
                    'project_id': installation.id,
                    'date_deadline': installation_date.date(),
                    'user_id': self.env.user.id,
                }
            )

            # Complete task
            task.write({'date_end': installation_date, 'description': f'{task_name} - Completed successfully'})

        # Complete installation
        installation.write(
            {
                'state': 'completed',
                'actual_end_time': installation_date + timedelta(hours=2),
                'customer_satisfaction': 'excellent',
            }
        )

        # Step 5: Customer satisfaction and follow-up
        satisfaction_survey = self.env['mail.activity'].create(
            {
                'res_model': 'res.partner',
                'res_id': residential_customer.id,
                'activity_type_id': self.env.ref('mail.mail_activity_data_call').id,
                'summary': 'Customer satisfaction follow-up',
                'note': 'Follow up on installation satisfaction and gather feedback',
                'date_deadline': installation_date.date() + timedelta(days=3),
                'user_id': self.env.user.id,
            }
        )

        satisfaction_survey.action_done()

        # Record customer feedback
        customer_feedback = self.env['mail.message'].create(
            {
                'res_id': residential_customer.id,
                'model': 'res.partner',
                'message_type': 'comment',
                'body': '<p>Customer satisfaction survey completed. Customer extremely happy with installation quality and professionalism. Mentioned they may need window treatments for living room in the future.</p>',
                'author_id': self.env.user.partner_id.id,
            }
        )

        # Step 6: Relationship maintenance and future opportunities
        # Schedule future follow-up
        future_opportunity = self.env['mail.activity'].create(
            {
                'res_model': 'res.partner',
                'res_id': residential_customer.id,
                'activity_type_id': self.env.ref('mail.mail_activity_data_call').id,
                'summary': 'Future opportunity follow-up',
                'note': 'Customer mentioned interest in living room window treatments. Follow up in 6 months.',
                'date_deadline': datetime.now().date() + timedelta(days=180),
                'user_id': self.env.user.id,
            }
        )

        # Validate complete journey
        journey_validations = [
            residential_customer.exists(),
            residential_customer.customer_number is not None,
            quote.state == 'sale',
            installation.state == 'completed',
            installation.customer_satisfaction == 'excellent',
            future_opportunity.exists(),
        ]

        self.assertTrue(all(journey_validations), "Complete residential customer journey should be successful")

    def test_commercial_customer_complex_project(self):
        """
        Test complex commercial customer project with multiple phases.

        Business Flow:
        1. Commercial prospect qualification
        2. Site survey and complex quote generation
        3. Multi-phase order processing
        4. Coordinated installation project
        5. Project management and quality control
        6. Contract completion and relationship expansion
        """
        # Step 1: Commercial prospect qualification
        commercial_customer = self.customer_factory.create_customer(
            {
                'name': 'Denver Corporate Center',
                'customer_type': 'commercial',
                'is_company': True,
                'phone': '(303) 555-8900',
                'email': 'facilities@denvercc.com',
                'street': '1500 Lawrence Street',
                'street2': 'Suite 2000',
                'city': 'Denver',
                'zip': '80202',
                'company_size': 'large',
                'project_scope': 'full_building',
            }
        )

        # Qualification process
        qualification = self.env['mail.activity'].create(
            {
                'res_model': 'res.partner',
                'res_id': commercial_customer.id,
                'activity_type_id': self.env.ref('mail.mail_activity_data_meeting').id,
                'summary': 'Commercial project qualification meeting',
                'note': 'Qualify project scope, budget, and timeline for office building window treatments',
                'date_deadline': datetime.now().date() + timedelta(days=2),
                'user_id': self.env.user.id,
            }
        )

        qualification.action_done()

        # Update customer with qualification details
        commercial_customer.write(
            {'project_budget': 150000.00, 'project_timeline': '6_months', 'decision_makers': 'Facilities Manager, CFO'}
        )

        # Step 2: Site survey and complex quote generation
        site_survey = self.env['mail.activity'].create(
            {
                'res_model': 'res.partner',
                'res_id': commercial_customer.id,
                'activity_type_id': self.env.ref('mail.mail_activity_data_meeting').id,
                'summary': 'Comprehensive site survey',
                'note': 'Complete site survey of all floors. Document window specifications and requirements.',
                'date_deadline': datetime.now().date() + timedelta(days=5),
                'user_id': self.env.user.id,
            }
        )

        site_survey.action_done()

        # Generate complex multi-phase quote
        phase1_quote = self.complex_scenario.create_order(commercial_customer)
        phase1_quote.write(
            {
                'name': f'{phase1_quote.name} - Phase 1 (Floors 1-5)',
                'note': 'Phase 1: Executive floors and conference rooms. Motorized blackout shades and premium blinds.',
                'validity_date': datetime.now().date() + timedelta(days=45),
            }
        )

        phase2_quote = self.complex_scenario.create_order(commercial_customer)
        phase2_quote.write(
            {
                'name': f'{phase2_quote.name} - Phase 2 (Floors 6-10)',
                'note': 'Phase 2: General office areas. Standard office blinds and shades.',
                'validity_date': datetime.now().date() + timedelta(days=45),
            }
        )

        # Step 3: Multi-phase order processing
        # Customer approves both phases
        contract_negotiation = self.env['mail.activity'].create(
            {
                'res_model': 'res.partner',
                'res_id': commercial_customer.id,
                'activity_type_id': self.env.ref('mail.mail_activity_data_meeting').id,
                'summary': 'Contract negotiation and approval',
                'note': 'Present comprehensive proposal and negotiate contract terms',
                'date_deadline': datetime.now().date() + timedelta(days=14),
                'user_id': self.env.user.id,
            }
        )

        contract_negotiation.action_done()

        # Confirm both phases
        phase1_quote.action_confirm()
        phase2_quote.action_confirm()

        # Validate multi-phase processing
        self.assertEqual(phase1_quote.state, 'sale')
        self.assertEqual(phase2_quote.state, 'sale')

        # Step 4: Coordinated installation project
        # Create installation projects for each phase
        phase1_installation = self.installation_factory.create_installation(
            {
                'sale_order_id': phase1_quote.id,
                'customer_id': commercial_customer.id,
                'installation_type': 'commercial_premium',
                'project_phase': 'Phase 1',
            }
        )

        phase2_installation = self.installation_factory.create_installation(
            {
                'sale_order_id': phase2_quote.id,
                'customer_id': commercial_customer.id,
                'installation_type': 'commercial_standard',
                'project_phase': 'Phase 2',
            }
        )

        # Schedule coordinated installations
        phase1_start = datetime.now() + timedelta(days=21)
        phase2_start = phase1_start + timedelta(days=28)  # Start after Phase 1 completion

        phase1_installation.write({'scheduled_date': phase1_start, 'state': 'scheduled'})

        phase2_installation.write({'scheduled_date': phase2_start, 'state': 'scheduled'})

        # Step 5: Project management and quality control
        # Execute Phase 1
        phase1_installation.write({'state': 'in_progress', 'actual_start_time': phase1_start})

        # Phase 1 daily progress tracking
        for day in range(5):  # 5-day installation
            progress_task = self.env['project.task'].create(
                {
                    'name': f'Phase 1 Day {day + 1} Progress',
                    'project_id': phase1_installation.id,
                    'description': f'Day {day + 1} installation progress for floors {day + 1}',
                    'date_deadline': (phase1_start + timedelta(days=day)).date(),
                    'user_id': self.env.user.id,
                }
            )

            # Complete daily progress
            progress_task.write(
                {
                    'date_end': phase1_start + timedelta(days=day),
                    'description': f'Day {day + 1} completed successfully. Floor {day + 1} installation finished.',
                }
            )

        # Complete Phase 1
        phase1_installation.write(
            {
                'state': 'completed',
                'actual_end_time': phase1_start + timedelta(days=5),
                'customer_satisfaction': 'excellent',
            }
        )

        # Execute Phase 2
        phase2_installation.write({'state': 'in_progress', 'actual_start_time': phase2_start})

        # Phase 2 execution (abbreviated for test)
        phase2_completion_task = self.env['project.task'].create(
            {
                'name': 'Phase 2 Completion',
                'project_id': phase2_installation.id,
                'description': 'Complete Phase 2 installation for floors 6-10',
                'date_deadline': (phase2_start + timedelta(days=7)).date(),
                'user_id': self.env.user.id,
            }
        )

        phase2_completion_task.write(
            {
                'date_end': phase2_start + timedelta(days=7),
                'description': 'Phase 2 completed successfully. All floors 6-10 finished.',
            }
        )

        # Complete Phase 2
        phase2_installation.write(
            {
                'state': 'completed',
                'actual_end_time': phase2_start + timedelta(days=7),
                'customer_satisfaction': 'excellent',
            }
        )

        # Step 6: Contract completion and relationship expansion
        # Project completion review
        project_completion = self.env['mail.activity'].create(
            {
                'res_model': 'res.partner',
                'res_id': commercial_customer.id,
                'activity_type_id': self.env.ref('mail.mail_activity_data_meeting').id,
                'summary': 'Project completion review',
                'note': 'Final project review with customer. Document lessons learned and discuss future opportunities.',
                'date_deadline': (phase2_start + timedelta(days=10)).date(),
                'user_id': self.env.user.id,
            }
        )

        project_completion.action_done()

        # Update customer relationship status
        commercial_customer.write(
            {
                'customer_status': 'vip',
                'project_completion_date': phase2_start + timedelta(days=7),
                'relationship_value': 'high',
            }
        )

        # Future opportunity identification
        expansion_opportunity = self.env['mail.activity'].create(
            {
                'res_model': 'res.partner',
                'res_id': commercial_customer.id,
                'activity_type_id': self.env.ref('mail.mail_activity_data_call').id,
                'summary': 'Expansion opportunity follow-up',
                'note': 'Customer mentioned plans for additional building. Follow up on potential new project.',
                'date_deadline': datetime.now().date() + timedelta(days=90),
                'user_id': self.env.user.id,
            }
        )

        # Validate complex commercial project
        project_validations = [
            commercial_customer.exists(),
            commercial_customer.customer_status == 'vip',
            phase1_quote.state == 'sale',
            phase2_quote.state == 'sale',
            phase1_installation.state == 'completed',
            phase2_installation.state == 'completed',
            expansion_opportunity.exists(),
        ]

        self.assertTrue(all(project_validations), "Complex commercial project should be completed successfully")

    def test_multi_order_customer_relationship(self):
        """
        Test customer relationship management across multiple orders over time.

        Business Flow:
        1. Initial order and relationship establishment
        2. Customer satisfaction and referral generation
        3. Repeat business and relationship deepening
        4. Customer loyalty program participation
        5. Long-term relationship maintenance
        6. Customer lifetime value optimization
        """
        # Step 1: Initial order and relationship establishment
        loyal_customer = self.customer_factory.create_customer(
            {
                'name': 'Rodriguez Family Home',
                'customer_type': 'residential',
                'phone': '(303) 555-7777',
                'email': 'carlos.rodriguez@email.com',
            }
        )

        # First order - kitchen window treatments
        first_order = self.simple_scenario.create_order(loyal_customer)
        first_order.write(
            {
                'note': 'Initial order: Kitchen window treatments',
                'date_order': datetime.now() - timedelta(days=365),  # One year ago
            }
        )
        first_order.action_confirm()

        # Complete first installation
        first_installation = self.installation_factory.create_installation(
            {
                'sale_order_id': first_order.id,
                'customer_id': loyal_customer.id,
                'state': 'completed',
                'customer_satisfaction': 'excellent',
            }
        )

        # Step 2: Customer satisfaction and referral generation
        # Customer provides referral
        referral_activity = self.env['mail.activity'].create(
            {
                'res_model': 'res.partner',
                'res_id': loyal_customer.id,
                'activity_type_id': self.env.ref('mail.mail_activity_data_call').id,
                'summary': 'Customer referral follow-up',
                'note': 'Customer referred neighbors. Follow up and thank customer.',
                'date_deadline': (datetime.now() - timedelta(days=330)).date(),
                'user_id': self.env.user.id,
            }
        )

        referral_activity.action_done()

        # Create referred customer
        referred_customer = self.customer_factory.create_customer(
            {
                'name': 'Thompson Family (Referred by Rodriguez)',
                'customer_type': 'residential',
                'referral_source': loyal_customer.id,
                'referred_by': loyal_customer.name,
            }
        )

        # Step 3: Repeat business and relationship deepening
        # Second order - living room (6 months later)
        second_order = self.simple_scenario.create_order(loyal_customer)
        second_order.write(
            {
                'note': 'Second order: Living room window treatments',
                'date_order': datetime.now() - timedelta(days=180),
                'discount_reason': 'loyal_customer',
            }
        )

        # Apply loyal customer discount
        for line in second_order.order_line:
            line.discount = 5.0  # 5% loyal customer discount

        second_order.action_confirm()

        # Complete second installation
        second_installation = self.installation_factory.create_installation(
            {
                'sale_order_id': second_order.id,
                'customer_id': loyal_customer.id,
                'state': 'completed',
                'customer_satisfaction': 'excellent',
            }
        )

        # Step 4: Customer loyalty program participation
        # Enroll in loyalty program
        loyal_customer.write(
            {'loyalty_program': True, 'loyalty_points': 250, 'customer_status': 'loyal'}  # Points from two orders
        )

        # Third order - bedroom (current)
        third_order = self.simple_scenario.create_order(loyal_customer)
        third_order.write(
            {'note': 'Third order: Master bedroom motorized shades', 'loyalty_points_used': 100}  # Use loyalty points
        )

        # Apply loyalty point discount
        loyalty_discount_line = self.env['sale.order.line'].create(
            {
                'order_id': third_order.id,
                'name': 'Loyalty Points Discount (100 points)',
                'price_unit': -25.00,  # $25 discount for 100 points
                'product_uom_qty': 1,
            }
        )

        third_order.action_confirm()

        # Step 5: Long-term relationship maintenance
        # Customer maintenance schedule
        maintenance_schedule = self.env['mail.activity'].create(
            {
                'res_model': 'res.partner',
                'res_id': loyal_customer.id,
                'activity_type_id': self.env.ref('mail.mail_activity_data_call').id,
                'summary': 'Annual relationship review',
                'note': 'Annual check-in with loyal customer. Review satisfaction and identify new opportunities.',
                'date_deadline': datetime.now().date() + timedelta(days=30),
                'user_id': self.env.user.id,
            }
        )

        # Step 6: Customer lifetime value optimization
        # Calculate customer lifetime value
        all_orders = self.env['sale.order'].search([('partner_id', '=', loyal_customer.id)])

        total_order_value = sum(all_orders.mapped('amount_total'))
        order_count = len(all_orders)
        avg_order_value = total_order_value / order_count if order_count > 0 else 0

        # Update customer with value metrics
        loyal_customer.write(
            {
                'lifetime_value': total_order_value,
                'order_count': order_count,
                'average_order_value': avg_order_value,
                'relationship_duration': 365,  # Days since first order
            }
        )

        # Validate multi-order relationship
        relationship_validations = [
            loyal_customer.exists(),
            len(all_orders) >= 3,
            loyal_customer.loyalty_program is True,
            loyal_customer.customer_status == 'loyal',
            referred_customer.exists(),
            total_order_value > 0,
            maintenance_schedule.exists(),
        ]

        self.assertTrue(all(relationship_validations), "Multi-order customer relationship should be well-managed")


# Helper functions for complete business flow testing
def create_comprehensive_business_scenario(env, scenario_type='mixed'):
    """
    Create a comprehensive business scenario with multiple customers,
    orders, and installations representing a realistic business environment.
    """
    data_manager = TestDataManager(env)

    # Create diverse customer base
    customers = []
    orders = []
    installations = []

    customer_types = ['residential', 'commercial', 'hospitality']

    for i, customer_type in enumerate(customer_types):
        # Create customer
        customer = CustomerFactory(env).create_customer(
            {
                'name': f'{customer_type.title()} Customer {i+1}',
                'customer_type': customer_type,
                'is_company': customer_type != 'residential',
            }
        )
        customers.append(customer)

        # Create order
        if customer_type == 'residential':
            scenario = SimpleOrderScenario(env)
        else:
            scenario = ComplexOrderScenario(env)

        order = scenario.create_order(customer)
        order.action_confirm()
        orders.append(order)

        # Create installation
        installation = InstallationFactory(env).create_installation(
            {'sale_order_id': order.id, 'customer_id': customer.id, 'installation_type': f'{customer_type}_standard'}
        )
        installations.append(installation)

    return {
        'customers': customers,
        'orders': orders,
        'installations': installations,
        'summary': {
            'total_customers': len(customers),
            'total_orders': len(orders),
            'total_installations': len(installations),
            'total_revenue': sum(order.amount_total for order in orders),
        },
    }


# Test runner for manual execution
if __name__ == '__main__':
    print("Complete Business Flow Integration Tests")
    print("=======================================")
    print("These tests validate end-to-end business scenarios combining all workflows.")
    print("Run via: pytest tests/integration/test_complete_business_flow.py -v")

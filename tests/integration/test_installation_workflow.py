#!/usr/bin/env python3
"""
Installation Workflow Integration Tests
Task 4.6: Create integration tests for complete user workflows

Tests the complete installation process from scheduling through completion.
Validates the entire service delivery workflow for Royal Textiles.
"""

from datetime import datetime, timedelta

import pytest

# Import our base test classes and fixtures
from tests.base_test import OdooIntegrationTestCase
from tests.fixtures import CustomerFactory, InstallationFactory, SaleOrderFactory, SimpleOrderScenario, TestDataManager


class InstallationWorkflowTest(OdooIntegrationTestCase):
    """
    Integration tests for complete installation workflows.

    Tests complete business processes including:
    - Installation scheduling and coordination
    - Resource allocation and team assignment
    - On-site installation execution
    - Quality control and customer acceptance
    - Follow-up and service completion
    - Documentation and invoicing
    """

    @classmethod
    def setUpClass(cls):
        """Set up test environment with installation data"""
        super().setUpClass()
        cls.data_manager = TestDataManager(cls.env)

        # Create factories for installation testing
        cls.customer_factory = CustomerFactory(cls.env)
        cls.installation_factory = InstallationFactory(cls.env)
        cls.order_factory = SaleOrderFactory(cls.env)
        cls.order_scenario = SimpleOrderScenario(cls.env)

    def setUp(self):
        """Set up each test with clean state"""
        super().setUp()

        # Create test customer and order for installation
        self.test_customer = self.customer_factory.create_customer(
            {
                'name': 'Installation Test Customer',
                'customer_type': 'residential',
                'street': '123 Installation Ave',
                'city': 'Denver',
                'zip': '80202',
            }
        )

        # Create completed sale order for installation
        self.test_order = self.order_scenario.create_order(self.test_customer)
        self.test_order.action_confirm()

    def tearDown(self):
        """Clean up after each test"""
        self.customer_factory.cleanup()
        self.installation_factory.cleanup()
        self.order_factory.cleanup()
        super().tearDown()

    def test_complete_installation_scheduling_workflow(self):
        """
        Test the complete installation scheduling process.

        Workflow Steps:
        1. Installation request creation from sale order
        2. Site survey and measurement confirmation
        3. Installation scheduling and team assignment
        4. Customer communication and confirmation
        5. Resource allocation and preparation
        6. Pre-installation checklist completion
        """
        # Step 1: Create installation request from sale order
        installation = self.installation_factory.create_installation(
            {
                'sale_order_id': self.test_order.id,
                'customer_id': self.test_customer.id,
                'installation_type': 'residential_standard',
            }
        )

        # Validate installation creation
        self.assertTrue(installation.exists())
        self.assertEqual(installation.sale_order_id, self.test_order)
        self.assertEqual(installation.customer_id, self.test_customer)
        self.assertEqual(installation.state, 'draft')

        # Step 2: Site survey and measurement confirmation
        site_survey = self.env['mail.activity'].create(
            {
                'res_model': 'project.project',
                'res_id': installation.id,
                'activity_type_id': self.env.ref('mail.mail_activity_data_meeting').id,
                'summary': 'Site survey and measurements',
                'note': 'Confirm final measurements and installation requirements',
                'date_deadline': datetime.now().date() + timedelta(days=2),
                'user_id': self.env.user.id,
            }
        )

        # Complete site survey
        site_survey.action_done()

        # Update installation with survey results
        installation.write(
            {
                'measurements_confirmed': True,
                'site_notes': 'Standard installation, no obstacles detected',
                'estimated_duration': 4.0,  # 4 hours
            }
        )

        # Step 3: Installation scheduling and team assignment
        # Find available installation team
        installation_team = self.env['hr.employee'].search([('job_id.name', 'ilike', 'installer')], limit=1)

        if not installation_team:
            # Create installation team for testing
            installation_team = self.env['hr.employee'].create(
                {
                    'name': 'Test Installation Team Lead',
                    'job_id': self.env['hr.job'].create({'name': 'Installation Technician'}).id,
                }
            )

        # Schedule installation
        installation_date = datetime.now() + timedelta(days=5)
        installation.write(
            {'scheduled_date': installation_date, 'team_lead_id': installation_team.id, 'state': 'scheduled'}
        )

        # Validate scheduling
        self.assertEqual(installation.state, 'scheduled')
        self.assertTrue(installation.scheduled_date)
        self.assertTrue(installation.team_lead_id)

        # Step 4: Customer communication and confirmation
        confirmation_activity = self.env['mail.activity'].create(
            {
                'res_model': 'project.project',
                'res_id': installation.id,
                'activity_type_id': self.env.ref('mail.mail_activity_data_call').id,
                'summary': 'Installation appointment confirmation',
                'note': f'Confirm installation appointment for {installation_date.strftime("%Y-%m-%d")}',
                'date_deadline': installation_date.date() - timedelta(days=1),
                'user_id': self.env.user.id,
            }
        )

        # Customer confirms appointment
        confirmation_activity.action_done()

        # Step 5: Resource allocation and preparation
        # Create installation tasks
        preparation_task = self.env['project.task'].create(
            {
                'name': 'Installation Preparation',
                'project_id': installation.id,
                'description': 'Prepare materials and tools for installation',
                'date_deadline': installation_date.date() - timedelta(days=1),
                'user_id': installation_team.user_id.id if installation_team.user_id else self.env.user.id,
            }
        )

        material_prep_task = self.env['project.task'].create(
            {
                'name': 'Material Preparation',
                'project_id': installation.id,
                'description': 'Load vehicle with window treatments and installation hardware',
                'date_deadline': installation_date.date(),
                'user_id': installation_team.user_id.id if installation_team.user_id else self.env.user.id,
            }
        )

        # Step 6: Pre-installation checklist completion
        checklist_items = [
            'Materials loaded and verified',
            'Tools and equipment checked',
            'Customer contact information confirmed',
            'Site access arrangements confirmed',
            'Installation instructions reviewed',
        ]

        for item in checklist_items:
            checklist_task = self.env['project.task'].create(
                {
                    'name': f'Checklist: {item}',
                    'project_id': installation.id,
                    'description': item,
                    'date_deadline': installation_date.date(),
                    'user_id': installation_team.user_id.id if installation_team.user_id else self.env.user.id,
                }
            )

            # Mark as completed
            checklist_task.stage_id = self.env['project.task.type'].search([('name', 'ilike', 'done')], limit=1)

        # Validate preparation completion
        completed_tasks = self.env['project.task'].search(
            [('project_id', '=', installation.id), ('stage_id.name', 'ilike', 'done')]
        )

        self.assertTrue(len(completed_tasks) >= len(checklist_items))

    def test_installation_execution_workflow(self):
        """
        Test the on-site installation execution process.

        Workflow Steps:
        1. Installation team arrival and setup
        2. Customer walkthrough and final confirmation
        3. Installation execution and progress tracking
        4. Quality control during installation
        5. Customer inspection and acceptance
        6. Documentation and cleanup
        """
        # Step 1: Create installation ready for execution
        execution_installation = self.installation_factory.create_installation(
            {
                'sale_order_id': self.test_order.id,
                'customer_id': self.test_customer.id,
                'state': 'scheduled',
                'scheduled_date': datetime.now(),
                'installation_type': 'residential_standard',
            }
        )

        # Team arrives and starts installation
        execution_installation.write(
            {
                'state': 'in_progress',
                'actual_start_time': datetime.now(),
                'on_site_notes': 'Team arrived on time, customer present',
            }
        )

        # Validate installation start
        self.assertEqual(execution_installation.state, 'in_progress')
        self.assertTrue(execution_installation.actual_start_time)

        # Step 2: Customer walkthrough and final confirmation
        walkthrough_task = self.env['project.task'].create(
            {
                'name': 'Customer Walkthrough',
                'project_id': execution_installation.id,
                'description': 'Review installation plan with customer',
                'date_deadline': datetime.now().date(),
                'priority': '1',  # High priority
            }
        )

        # Complete walkthrough
        walkthrough_task.write(
            {'description': 'Walkthrough completed. Customer approved installation plan.', 'date_end': datetime.now()}
        )

        # Step 3: Installation execution and progress tracking
        installation_phases = [
            {'name': 'Window 1 - Living Room East', 'duration': 45, 'status': 'completed'},  # minutes
            {'name': 'Window 2 - Living Room West', 'duration': 45, 'status': 'completed'},
            {'name': 'Window 3 - Master Bedroom', 'duration': 30, 'status': 'in_progress'},
        ]

        completed_phases = 0
        for phase in installation_phases:
            phase_task = self.env['project.task'].create(
                {
                    'name': f'Install: {phase["name"]}',
                    'project_id': execution_installation.id,
                    'description': f'Installation phase: {phase["name"]}',
                    'planned_hours': phase['duration'] / 60.0,
                    'date_deadline': datetime.now().date(),
                }
            )

            if phase['status'] == 'completed':
                phase_task.write({'effective_hours': phase['duration'] / 60.0, 'date_end': datetime.now()})
                completed_phases += 1

        # Update installation progress
        total_phases = len(installation_phases)
        progress_percentage = (completed_phases / total_phases) * 100

        execution_installation.write(
            {
                'progress_percentage': progress_percentage,
                'current_phase': f'{completed_phases}/{total_phases} windows completed',
            }
        )

        # Step 4: Quality control during installation
        qc_checkpoints = [
            'Mounting hardware properly secured',
            'Window treatments operate smoothly',
            'All safety requirements met',
            'Installation area clean and organized',
        ]

        for checkpoint in qc_checkpoints:
            qc_task = self.env['project.task'].create(
                {
                    'name': f'QC: {checkpoint}',
                    'project_id': execution_installation.id,
                    'description': f'Quality control checkpoint: {checkpoint}',
                    'priority': '1',
                    'date_deadline': datetime.now().date(),
                }
            )

            # Mark QC as passed
            qc_task.write({'description': f'{checkpoint} - PASSED', 'date_end': datetime.now()})

        # Step 5: Customer inspection and acceptance
        customer_inspection = self.env['project.task'].create(
            {
                'name': 'Customer Final Inspection',
                'project_id': execution_installation.id,
                'description': 'Customer reviews completed installation',
                'priority': '1',
                'date_deadline': datetime.now().date(),
            }
        )

        # Customer approves installation
        customer_inspection.write(
            {'description': 'Customer inspection completed. Installation approved.', 'date_end': datetime.now()}
        )

        # Step 6: Documentation and cleanup
        # Complete installation
        execution_installation.write(
            {
                'state': 'completed',
                'actual_end_time': datetime.now(),
                'customer_satisfaction': 'excellent',
                'final_notes': 'Installation completed successfully. Customer very satisfied.',
            }
        )

        # Create completion documentation
        completion_doc = self.env['ir.attachment'].create(
            {
                'name': f'Installation Completion - {execution_installation.name}',
                'res_model': 'project.project',
                'res_id': execution_installation.id,
                'type': 'binary',
                'datas': b'Installation completion documentation',  # Simplified for test
            }
        )

        # Validate installation completion
        self.assertEqual(execution_installation.state, 'completed')
        self.assertTrue(execution_installation.actual_end_time)
        self.assertTrue(completion_doc.exists())

    def test_installation_quality_control_workflow(self):
        """
        Test quality control processes throughout installation.

        Workflow Steps:
        1. Pre-installation quality checks
        2. In-progress quality monitoring
        3. Post-installation inspection
        4. Customer satisfaction verification
        5. Quality documentation and reporting
        6. Follow-up quality assurance
        """
        # Step 1: Create installation for quality testing
        qc_installation = self.installation_factory.create_installation(
            {
                'sale_order_id': self.test_order.id,
                'customer_id': self.test_customer.id,
                'installation_type': 'residential_premium',  # Higher quality standards
            }
        )

        # Pre-installation quality checks
        pre_qc_checks = [
            'Materials match order specifications',
            'Hardware components complete',
            'Installation tools calibrated',
            'Team qualifications verified',
        ]

        for check in pre_qc_checks:
            qc_task = self.env['project.task'].create(
                {
                    'name': f'Pre-QC: {check}',
                    'project_id': qc_installation.id,
                    'description': check,
                    'tag_ids': [(6, 0, [self.env.ref('project.project_tag_01').id])],  # Quality tag
                    'date_deadline': datetime.now().date(),
                }
            )

            # Pass pre-installation check
            qc_task.write({'description': f'{check} - VERIFIED', 'date_end': datetime.now()})

        # Step 2: Start installation with quality monitoring
        qc_installation.write(
            {
                'state': 'in_progress',
                'quality_standard': 'premium',
                'qc_frequency': 'per_window',  # Quality check per window
            }
        )

        # In-progress quality monitoring
        windows_to_install = 3
        for window_num in range(1, windows_to_install + 1):
            # Installation phase
            install_task = self.env['project.task'].create(
                {
                    'name': f'Install Window {window_num}',
                    'project_id': qc_installation.id,
                    'description': f'Complete installation of window {window_num}',
                    'date_deadline': datetime.now().date(),
                }
            )

            # Quality check for each window
            window_qc = self.env['project.task'].create(
                {
                    'name': f'QC Window {window_num}',
                    'project_id': qc_installation.id,
                    'description': f'Quality control check for window {window_num}',
                    'tag_ids': [(6, 0, [self.env.ref('project.project_tag_01').id])],
                    'date_deadline': datetime.now().date(),
                }
            )

            # Complete installation and QC
            install_task.date_end = datetime.now()
            window_qc.write({'description': f'Window {window_num} - Quality approved', 'date_end': datetime.now()})

        # Step 3: Post-installation inspection
        final_inspection_items = [
            'All windows operate correctly',
            'Mounting hardware secure',
            'No damage to customer property',
            'Installation area clean',
            'Customer trained on operation',
        ]

        for item in final_inspection_items:
            inspection_task = self.env['project.task'].create(
                {
                    'name': f'Final Inspection: {item}',
                    'project_id': qc_installation.id,
                    'description': item,
                    'priority': '1',
                    'date_deadline': datetime.now().date(),
                }
            )

            # Pass final inspection
            inspection_task.write({'description': f'{item} - PASSED', 'date_end': datetime.now()})

        # Step 4: Customer satisfaction verification
        satisfaction_survey = self.env['mail.activity'].create(
            {
                'res_model': 'project.project',
                'res_id': qc_installation.id,
                'activity_type_id': self.env.ref('mail.mail_activity_data_call').id,
                'summary': 'Customer satisfaction survey',
                'note': 'Conduct customer satisfaction survey for quality verification',
                'date_deadline': datetime.now().date(),
                'user_id': self.env.user.id,
            }
        )

        # Complete satisfaction survey
        satisfaction_survey.action_done()

        qc_installation.write(
            {
                'customer_satisfaction': 'excellent',
                'quality_score': 95.0,
                'customer_feedback': 'Outstanding work, very professional installation',
            }
        )

        # Step 5: Quality documentation and reporting
        qc_installation.write(
            {
                'state': 'completed',
                'qc_certification': 'passed',
                'quality_notes': 'Installation meets all premium quality standards',
            }
        )

        # Generate quality report
        quality_report = self.env['ir.attachment'].create(
            {
                'name': f'Quality Report - {qc_installation.name}',
                'res_model': 'project.project',
                'res_id': qc_installation.id,
                'description': 'Quality control documentation and certification',
                'type': 'binary',
                'datas': b'Quality control report and certification',
            }
        )

        # Step 6: Follow-up quality assurance
        followup_activity = self.env['mail.activity'].create(
            {
                'res_model': 'project.project',
                'res_id': qc_installation.id,
                'activity_type_id': self.env.ref('mail.mail_activity_data_call').id,
                'summary': '30-day quality follow-up',
                'note': 'Follow up on installation quality and customer satisfaction',
                'date_deadline': datetime.now().date() + timedelta(days=30),
                'user_id': self.env.user.id,
            }
        )

        # Validate quality workflow completion
        self.assertEqual(qc_installation.state, 'completed')
        self.assertEqual(qc_installation.qc_certification, 'passed')
        self.assertTrue(qc_installation.quality_score >= 90.0)
        self.assertTrue(quality_report.exists())
        self.assertTrue(followup_activity.exists())

    def test_installation_workflow_error_handling(self):
        """
        Test error handling and recovery in installation workflows.

        Tests:
        1. Installation delays and rescheduling
        2. Equipment failures during installation
        3. Customer unavailability
        4. Weather-related postponements
        5. Quality failures and rework
        """
        # Test 1: Installation delays and rescheduling
        delayed_installation = self.installation_factory.create_installation(
            {
                'sale_order_id': self.test_order.id,
                'customer_id': self.test_customer.id,
                'state': 'scheduled',
                'scheduled_date': datetime.now() + timedelta(days=1),
            }
        )

        # Simulate delay notification
        delay_reason = 'Material delivery delayed due to supplier issue'
        delayed_installation.write(
            {'state': 'delayed', 'delay_reason': delay_reason, 'rescheduled_date': datetime.now() + timedelta(days=3)}
        )

        # Create rescheduling communication
        reschedule_activity = self.env['mail.activity'].create(
            {
                'res_model': 'project.project',
                'res_id': delayed_installation.id,
                'activity_type_id': self.env.ref('mail.mail_activity_data_call').id,
                'summary': 'Reschedule installation appointment',
                'note': f'Contact customer to reschedule due to: {delay_reason}',
                'date_deadline': datetime.now().date(),
                'user_id': self.env.user.id,
            }
        )

        # Validate delay handling
        self.assertEqual(delayed_installation.state, 'delayed')
        self.assertTrue(delayed_installation.rescheduled_date)
        self.assertTrue(reschedule_activity.exists())

        # Test 2: Equipment failures during installation
        equipment_failure_installation = self.installation_factory.create_installation(
            {'sale_order_id': self.test_order.id, 'customer_id': self.test_customer.id, 'state': 'in_progress'}
        )

        # Simulate equipment failure
        failure_task = self.env['project.task'].create(
            {
                'name': 'Equipment Failure - Drill Malfunction',
                'project_id': equipment_failure_installation.id,
                'description': 'Primary drill failed during installation',
                'priority': '3',  # Urgent
                'date_deadline': datetime.now().date(),
            }
        )

        # Handle equipment failure
        equipment_failure_installation.write(
            {'state': 'on_hold', 'hold_reason': 'Equipment failure - replacement needed'}
        )

        # Resolve equipment issue
        failure_task.write(
            {'description': 'Equipment failure resolved - backup drill used', 'date_end': datetime.now()}
        )

        equipment_failure_installation.write({'state': 'in_progress', 'hold_reason': False})

        # Test 3: Customer unavailability
        unavailable_customer_installation = self.installation_factory.create_installation(
            {'sale_order_id': self.test_order.id, 'customer_id': self.test_customer.id, 'state': 'scheduled'}
        )

        # Customer not home for appointment
        unavailable_customer_installation.write(
            {'state': 'customer_unavailable', 'unavailability_notes': 'Customer not home at scheduled time'}
        )

        # Reschedule with customer
        customer_contact_activity = self.env['mail.activity'].create(
            {
                'res_model': 'project.project',
                'res_id': unavailable_customer_installation.id,
                'activity_type_id': self.env.ref('mail.mail_activity_data_call').id,
                'summary': 'Contact customer for rescheduling',
                'note': 'Customer unavailable for scheduled appointment',
                'date_deadline': datetime.now().date(),
                'user_id': self.env.user.id,
            }
        )

        # Test 4: Quality failures and rework
        quality_failure_installation = self.installation_factory.create_installation(
            {'sale_order_id': self.test_order.id, 'customer_id': self.test_customer.id, 'state': 'in_progress'}
        )

        # Quality check fails
        quality_failure_task = self.env['project.task'].create(
            {
                'name': 'Quality Failure - Window Alignment',
                'project_id': quality_failure_installation.id,
                'description': 'Window blind alignment does not meet quality standards',
                'priority': '2',  # High priority
                'date_deadline': datetime.now().date(),
            }
        )

        # Initiate rework
        rework_task = self.env['project.task'].create(
            {
                'name': 'Rework - Realign Window Blinds',
                'project_id': quality_failure_installation.id,
                'description': 'Correct window blind alignment to meet quality standards',
                'date_deadline': datetime.now().date(),
            }
        )

        # Complete rework
        quality_failure_task.date_end = datetime.now()
        rework_task.write(
            {'description': 'Rework completed - window alignment now meets standards', 'date_end': datetime.now()}
        )

        # Validate error handling
        error_handling_tests = [
            delayed_installation.exists(),
            equipment_failure_installation.state == 'in_progress',
            unavailable_customer_installation.state == 'customer_unavailable',
            rework_task.date_end is not None,
        ]

        self.assertTrue(all(error_handling_tests), "All error handling scenarios should be resolved")


# Helper functions for installation testing
def create_realistic_installation_scenario(env, complexity='standard'):
    """
    Create a realistic installation scenario with complete workflow.
    """
    data_manager = TestDataManager(env)
    customer_factory = CustomerFactory(env)
    installation_factory = InstallationFactory(env)

    # Create customer and order
    customer = customer_factory.create_customer(
        {
            'name': f'Installation Customer - {complexity.title()}',
            'customer_type': 'residential' if complexity == 'standard' else 'commercial',
        }
    )

    order_scenario = SimpleOrderScenario(env)
    order = order_scenario.create_order(customer)
    order.action_confirm()

    # Create installation with appropriate complexity
    installation = installation_factory.create_installation(
        {
            'sale_order_id': order.id,
            'customer_id': customer.id,
            'installation_type': f'{"residential" if complexity == "standard" else "commercial"}_{complexity}',
        }
    )

    return {'customer': customer, 'order': order, 'installation': installation}


# Test runner for manual execution
if __name__ == '__main__':
    print("Installation Workflow Integration Tests")
    print("======================================")
    print("These tests validate complete installation workflows from scheduling to completion.")
    print("Run via: pytest tests/integration/test_installation_workflow.py -v")

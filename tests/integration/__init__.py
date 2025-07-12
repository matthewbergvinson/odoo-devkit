"""
Royal Textiles Sales - Integration Test Package
Task 4.6: Create integration tests for complete user workflows

This package contains end-to-end integration tests that validate complete
business workflows rather than individual components.

Integration tests ensure that:
- Complete user journeys work from start to finish
- Multiple modules interact correctly
- Business rules are enforced across the entire process
- Data flows properly between different components
"""

from .test_complete_business_flow import CompleteBusinesFlowTest

# Import key workflow test classes for easy access
from .test_customer_lifecycle import CustomerLifecycleWorkflowTest
from .test_installation_workflow import InstallationWorkflowTest
from .test_reporting_workflow import ReportingWorkflowTest
from .test_sales_order_workflow import SalesOrderWorkflowTest

__all__ = [
    'CustomerLifecycleWorkflowTest',
    'SalesOrderWorkflowTest',
    'InstallationWorkflowTest',
    'ReportingWorkflowTest',
    'CompleteBusinesFlowTest',
]

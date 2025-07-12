"""
Example unit tests for RTP Denver Odoo modules.
Task 4.1: Demonstrates pytest-odoo plugin usage for unit testing.
"""

from unittest.mock import Mock, patch

import pytest


class TestExampleUnit:
    """Example unit tests that don't require Odoo database."""

    @pytest.mark.unit
    @pytest.mark.fast
    @pytest.mark.no_database
    def test_basic_functionality(self):
        """Test basic functionality without database dependency."""
        # Example: Test utility functions, calculations, etc.
        result = 2 + 2
        assert result == 4

    @pytest.mark.unit
    @pytest.mark.no_database
    def test_mock_usage(self, mock_external_api):
        """Demonstrate mocking external dependencies."""
        # Test code that uses external APIs
        response = mock_external_api['get']()
        assert response.status_code == 200

    @pytest.mark.unit
    @pytest.mark.no_database
    def test_sample_data_fixture(self, sample_data):
        """Demonstrate using sample data fixture."""
        customer_data = sample_data['customer_data']
        assert customer_data['name'] == 'Test Customer'
        assert '@' in customer_data['email']

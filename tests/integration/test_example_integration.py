"""
Example integration tests for RTP Denver Odoo modules.
Task 4.1: Demonstrates pytest-odoo plugin usage for integration testing.
"""

import pytest


class TestExampleIntegration:
    """Example integration tests that use Odoo database."""

    @pytest.mark.integration
    @pytest.mark.database
    def test_odoo_environment(self, odoo_env):
        """Test basic Odoo environment access."""
        assert odoo_env is not None
        assert hasattr(odoo_env, 'cr')
        assert hasattr(odoo_env, 'user')

    @pytest.mark.integration
    @pytest.mark.database
    def test_base_models_available(self, odoo_env, odoo_assertions):
        """Test that basic Odoo models are available."""
        # Test core Odoo models
        odoo_assertions.assert_model_exists(odoo_env, 'res.partner')
        odoo_assertions.assert_model_exists(odoo_env, 'res.users')

        # Test that we can create basic records
        partner = odoo_env['res.partner'].create({'name': 'Test Partner'})
        assert partner.name == 'Test Partner'
        assert partner.id > 0

    @pytest.mark.integration
    @pytest.mark.database
    @pytest.mark.rtp_customers
    def test_rtp_customers_integration(self, rtp_customers_module, sample_data):
        """Test RTP Customers module integration."""
        customer_data = sample_data['customer_data']

        # Create customer record
        customer = rtp_customers_module.create(customer_data)
        assert customer.name == customer_data['name']
        assert customer.email == customer_data['email']

    @pytest.mark.integration
    @pytest.mark.database
    @pytest.mark.royal_textiles_sales
    def test_royal_textiles_integration(self, royal_textiles_module, odoo_env, sample_data):
        """Test Royal Textiles Sales module integration."""
        sale_order_model = royal_textiles_module['sale_order']

        # Create partner first
        partner = odoo_env['res.partner'].create(sample_data['customer_data'])

        # Create sale order
        order_data = sample_data['sale_order_data'].copy()
        order_data['partner_id'] = partner.id

        order = sale_order_model.create(order_data)
        assert order.partner_id == partner
        assert order.state == 'draft'

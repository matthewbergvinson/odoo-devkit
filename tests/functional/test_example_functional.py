"""
Example functional tests for RTP Denver Odoo modules.
Task 4.1: Demonstrates pytest-odoo plugin usage for functional testing.
"""

import pytest


class TestExampleFunctional:
    """Example functional tests for complete user workflows."""

    @pytest.mark.functional
    @pytest.mark.database
    @pytest.mark.slow
    def test_complete_sales_workflow(self, odoo_env, sample_data):
        """Test complete sales workflow from quotation to installation."""
        # Create customer
        partner = odoo_env['res.partner'].create(sample_data['customer_data'])

        # Create product
        product = odoo_env['res.product'].create(sample_data['product_data'])

        # Create sale order
        order_data = sample_data['sale_order_data'].copy()
        order_data['partner_id'] = partner.id
        order = odoo_env['sale.order'].create(order_data)

        # Add order line
        odoo_env['sale.order.line'].create(
            {
                'order_id': order.id,
                'product_id': product.id,
                'product_uom_qty': 1,
                'price_unit': product.list_price,
            }
        )

        # Confirm order
        order.action_confirm()
        assert order.state == 'sale'

        # Verify workflow completion
        assert len(order.order_line) == 1
        assert order.amount_total > 0

    @pytest.mark.functional
    @pytest.mark.database
    @pytest.mark.royal_textiles_sales
    def test_installation_scheduling_workflow(self, royal_textiles_module, odoo_env, sample_data):
        """Test installation scheduling workflow."""
        if not royal_textiles_module.get('installation'):
            pytest.skip("Installation model not available")

        # Create complete installation workflow
        partner = odoo_env['res.partner'].create(sample_data['customer_data'])

        # Test installation creation and scheduling
        # This would test the Royal Textiles specific functionality
        # based on the actual implementation
        pass

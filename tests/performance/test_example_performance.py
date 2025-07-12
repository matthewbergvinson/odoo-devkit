"""
Example performance tests for RTP Denver Odoo modules.
Task 4.1: Demonstrates pytest-odoo plugin usage for performance testing.
"""

import time

import pytest


class TestExamplePerformance:
    """Example performance tests using pytest-benchmark."""

    @pytest.mark.performance
    @pytest.mark.database
    def test_partner_creation_performance(self, odoo_env, benchmark, sample_data):
        """Benchmark partner creation performance."""

        def create_partner():
            return odoo_env['res.partner'].create(sample_data['customer_data'])

        result = benchmark(create_partner)
        assert result.id > 0

    @pytest.mark.performance
    @pytest.mark.database
    @pytest.mark.slow
    def test_bulk_operations_performance(self, odoo_env, benchmark, sample_data):
        """Test bulk operations performance."""

        def create_bulk_partners():
            partners_data = []
            for i in range(100):
                data = sample_data['customer_data'].copy()
                data['name'] = f"Test Customer {i}"
                data['email'] = f"test{i}@example.com"
                partners_data.append(data)

            return odoo_env['res.partner'].create(partners_data)

        result = benchmark(create_bulk_partners)
        assert len(result) == 100

"""
Test Data Fixtures and Factories for Royal Textiles Sales Module
Task 4.4: Add test data fixtures and factories for consistent test scenarios

This package provides comprehensive test data factories and fixtures
for the Royal Textiles Sales module and related testing scenarios.

Organization:
- factories.py: Core data factories using factory patterns
- scenarios.py: Pre-built scenario fixtures for common use cases
- realistic_data.py: Realistic business data (addresses, names, etc.)
- maintenance.py: Utilities for keeping fixtures up-to-date
"""

# Export main factory classes for easy importing
from .factories import CustomerFactory, InstallationFactory, ProductFactory, SaleOrderFactory, TestDataManager

# Export realistic data utilities
from .realistic_data import (
    ADDRESSES,
    CUSTOMER_NAMES,
    PRODUCT_CATALOG,
    get_realistic_customer_data,
    get_realistic_product_data,
)

# Export scenario fixtures
from .scenarios import (
    BulkTestingScenario,
    ComplexOrderScenario,
    ErrorTestingScenario,
    PerformanceTestingScenario,
    SimpleOrderScenario,
)

__all__ = [
    # Factories
    'CustomerFactory',
    'ProductFactory',
    'SaleOrderFactory',
    'InstallationFactory',
    'TestDataManager',
    # Scenarios
    'SimpleOrderScenario',
    'ComplexOrderScenario',
    'BulkTestingScenario',
    'ErrorTestingScenario',
    'PerformanceTestingScenario',
    # Realistic Data
    'CUSTOMER_NAMES',
    'PRODUCT_CATALOG',
    'ADDRESSES',
    'get_realistic_customer_data',
    'get_realistic_product_data',
]

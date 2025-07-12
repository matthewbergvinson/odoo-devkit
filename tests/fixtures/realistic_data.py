"""
Realistic Business Data for Royal Textiles Sales Test Fixtures
Task 4.4: Add test data fixtures and factories for consistent test scenarios

This module provides realistic, business-domain-specific data for creating
test fixtures that closely match real-world Royal Textiles scenarios.

Based on best practices: Use realistic data instead of "fake" data to make
tests more meaningful and catch real-world edge cases.
"""

import random
from typing import Any, Dict, List

# === CUSTOMER DATA ===

CUSTOMER_NAMES = {
    'residential': [
        'Johnson Family Residence',
        'Martinez Home Design',
        'Thompson & Associates',
        'Wilson Family Trust',
        'Anderson Property Management',
        'Brown Family Estate',
        'Davis Residential Services',
        'Miller Home Improvement',
        'Garcia Property Solutions',
        'Rodriguez Family Holdings',
        'Lee Residential Design',
        'Taylor Home Services',
        'Moore Property Group',
        'Clark Family Investments',
        'Lewis Home Management',
    ],
    'commercial': [
        'Denver Medical Center',
        'Riverside Office Complex',
        'Mountain View Corporate Plaza',
        'Cherry Creek Shopping District',
        'Downtown Business Center',
        'Tech Innovation Hub',
        'Colorado Springs Medical',
        'Boulder Research Campus',
        'Highlands Ranch Corporate',
        'Aurora Business Park',
        'Westminster Office Tower',
        'Lakewood Professional Center',
        'Thornton Industrial Complex',
        'Arvada Corporate Campus',
        'Centennial Business District',
    ],
    'hospitality': [
        'Grand Mountain Resort',
        'Denver Downtown Hotel',
        'Colorado Springs Inn',
        'Aspen Luxury Lodge',
        'Vail Conference Center',
        'Boulder Boutique Hotel',
        'Steamboat Springs Resort',
        'Breckenridge Mountain Lodge',
        'Keystone Conference Hotel',
        'Winter Park Resort',
        'Copper Mountain Inn',
        'Telluride Luxury Resort',
        'Crested Butte Lodge',
        'Durango Historic Hotel',
        'Fort Collins Business Hotel',
    ],
}

ADDRESSES = [
    {'street': '1234 Maple Street', 'city': 'Denver', 'state': 'Colorado', 'zip': '80202', 'country': 'United States'},
    {
        'street': '5678 Oak Avenue',
        'city': 'Colorado Springs',
        'state': 'Colorado',
        'zip': '80903',
        'country': 'United States',
    },
    {'street': '9012 Pine Road', 'city': 'Boulder', 'state': 'Colorado', 'zip': '80301', 'country': 'United States'},
    {
        'street': '3456 Cedar Lane',
        'city': 'Fort Collins',
        'state': 'Colorado',
        'zip': '80521',
        'country': 'United States',
    },
    {'street': '7890 Elm Drive', 'city': 'Aurora', 'state': 'Colorado', 'zip': '80012', 'country': 'United States'},
    {
        'street': '2468 Birch Circle',
        'city': 'Lakewood',
        'state': 'Colorado',
        'zip': '80226',
        'country': 'United States',
    },
    {
        'street': '1357 Aspen Way',
        'city': 'Westminster',
        'state': 'Colorado',
        'zip': '80031',
        'country': 'United States',
    },
    {
        'street': '8642 Spruce Court',
        'city': 'Thornton',
        'state': 'Colorado',
        'zip': '80229',
        'country': 'United States',
    },
    {'street': '9753 Willow Street', 'city': 'Arvada', 'state': 'Colorado', 'zip': '80002', 'country': 'United States'},
    {
        'street': '4681 Cherry Plaza',
        'city': 'Centennial',
        'state': 'Colorado',
        'zip': '80112',
        'country': 'United States',
    },
]

# === PRODUCT CATALOG ===

PRODUCT_CATALOG = {
    'blinds': [
        {
            'name': 'Premium 2" Faux Wood Blinds - White',
            'description': 'Classic white faux wood blinds with 2-inch slats, perfect for any room',
            'list_price': 185.00,
            'standard_price': 92.50,
            'install_time_multiplier': 1.2,
            'weight_per_unit': 3.5,
            'category': 'Window Treatments',
        },
        {
            'name': 'Aluminum Mini Blinds - Silver',
            'description': 'Durable aluminum mini blinds with adjustable slats',
            'list_price': 95.00,
            'standard_price': 47.50,
            'install_time_multiplier': 1.0,
            'weight_per_unit': 2.8,
            'category': 'Window Treatments',
        },
        {
            'name': 'Premium Venetian Blinds - Natural Wood',
            'description': 'Genuine wood venetian blinds with rich natural finish',
            'list_price': 245.00,
            'standard_price': 122.50,
            'install_time_multiplier': 1.3,
            'weight_per_unit': 4.2,
            'category': 'Window Treatments',
        },
        {
            'name': 'Vertical Blinds - Fabric',
            'description': 'Elegant fabric vertical blinds for large windows and sliding doors',
            'list_price': 165.00,
            'standard_price': 82.50,
            'install_time_multiplier': 1.4,
            'weight_per_unit': 3.0,
            'category': 'Window Treatments',
        },
    ],
    'shades': [
        {
            'name': 'Cellular Honeycomb Shades - Beige',
            'description': 'Energy-efficient cellular shades with honeycomb design',
            'list_price': 155.00,
            'standard_price': 77.50,
            'install_time_multiplier': 0.8,
            'weight_per_unit': 2.0,
            'category': 'Window Treatments',
        },
        {
            'name': 'Roller Shades - Blackout',
            'description': 'Room-darkening roller shades for bedrooms and media rooms',
            'list_price': 125.00,
            'standard_price': 62.50,
            'install_time_multiplier': 0.7,
            'weight_per_unit': 1.8,
            'category': 'Window Treatments',
        },
        {
            'name': 'Roman Shades - Designer Fabric',
            'description': 'Elegant roman shades with premium designer fabric',
            'list_price': 285.00,
            'standard_price': 142.50,
            'install_time_multiplier': 1.1,
            'weight_per_unit': 2.5,
            'category': 'Window Treatments',
        },
        {
            'name': 'Bamboo Natural Shades',
            'description': 'Eco-friendly bamboo shades with natural texture',
            'list_price': 195.00,
            'standard_price': 97.50,
            'install_time_multiplier': 0.9,
            'weight_per_unit': 2.2,
            'category': 'Window Treatments',
        },
    ],
    'motorized': [
        {
            'name': 'Smart Motorized Roller Shades - WiFi Enabled',
            'description': 'Smart home compatible motorized shades with app control',
            'list_price': 485.00,
            'standard_price': 242.50,
            'install_time_multiplier': 2.2,
            'weight_per_unit': 5.5,
            'category': 'Smart Home',
        },
        {
            'name': 'Motorized Cellular Shades - Battery Powered',
            'description': 'Battery-operated motorized cellular shades with remote control',
            'list_price': 395.00,
            'standard_price': 197.50,
            'install_time_multiplier': 2.0,
            'weight_per_unit': 4.8,
            'category': 'Smart Home',
        },
        {
            'name': 'Motorized Wood Blinds - Hardwired',
            'description': 'Premium hardwired motorized wood blinds for commercial use',
            'list_price': 595.00,
            'standard_price': 297.50,
            'install_time_multiplier': 2.5,
            'weight_per_unit': 6.2,
            'category': 'Smart Home',
        },
    ],
    'services': [
        {
            'name': 'Professional Installation Service',
            'description': 'Expert installation by certified technicians',
            'list_price': 125.00,
            'standard_price': 62.50,
            'install_time_multiplier': 1.0,
            'weight_per_unit': 0.0,
            'category': 'Services',
        },
        {
            'name': 'Measurement and Consultation',
            'description': 'Professional measurement and design consultation',
            'list_price': 75.00,
            'standard_price': 37.50,
            'install_time_multiplier': 0.5,
            'weight_per_unit': 0.0,
            'category': 'Services',
        },
        {
            'name': 'Motorization Upgrade Service',
            'description': 'Upgrade existing blinds/shades to motorized operation',
            'list_price': 185.00,
            'standard_price': 92.50,
            'install_time_multiplier': 1.5,
            'weight_per_unit': 0.0,
            'category': 'Services',
        },
    ],
}

# === PHONE NUMBERS AND EMAILS ===

PHONE_NUMBERS = [
    '+1-303-555-0101',  # Denver area
    '+1-303-555-0102',
    '+1-303-555-0103',
    '+1-719-555-0201',  # Colorado Springs area
    '+1-719-555-0202',
    '+1-970-555-0301',  # Fort Collins/Boulder area
    '+1-970-555-0302',
    '+1-720-555-0401',  # Metro Denver
    '+1-720-555-0402',
    '+1-720-555-0403',
]

EMAIL_DOMAINS = [
    'gmail.com',
    'yahoo.com',
    'outlook.com',
    'icloud.com',
    'comcast.net',
    'centurylink.net',
    'example.com',
    'test.com',
]

# === HELPER FUNCTIONS ===


def get_realistic_customer_data(customer_type: str = 'residential') -> Dict[str, Any]:
    """
    Generate realistic customer data for the specified type.

    Args:
        customer_type: 'residential', 'commercial', or 'hospitality'

    Returns:
        Dictionary with realistic customer data
    """
    if customer_type not in CUSTOMER_NAMES:
        customer_type = 'residential'

    name = random.choice(CUSTOMER_NAMES[customer_type])
    address = random.choice(ADDRESSES)

    # Generate email from name
    email_name = name.lower().replace(' ', '.').replace('&', 'and')
    email_name = ''.join(c for c in email_name if c.isalnum() or c in '.-')
    email_domain = random.choice(EMAIL_DOMAINS)

    return {
        'name': name,
        'email': f"{email_name}@{email_domain}",
        'phone': random.choice(PHONE_NUMBERS),
        'street': address['street'],
        'city': address['city'],
        'state_id': None,  # Will be set by factory
        'zip': address['zip'],
        'country_id': None,  # Will be set by factory
        'is_company': customer_type != 'residential',
        'customer_type': customer_type,
    }


def get_realistic_product_data(product_type: str = None) -> Dict[str, Any]:
    """
    Generate realistic product data for the specified type.

    Args:
        product_type: 'blinds', 'shades', 'motorized', 'services', or None for random

    Returns:
        Dictionary with realistic product data
    """
    if product_type is None:
        product_type = random.choice(list(PRODUCT_CATALOG.keys()))

    if product_type not in PRODUCT_CATALOG:
        product_type = 'blinds'

    product_data = random.choice(PRODUCT_CATALOG[product_type])

    return {
        'name': product_data['name'],
        'description': product_data['description'],
        'type': 'service' if product_type == 'services' else 'product',
        'list_price': product_data['list_price'],
        'standard_price': product_data['standard_price'],
        'product_type': product_type,
        'install_time_multiplier': product_data['install_time_multiplier'],
        'weight_per_unit': product_data['weight_per_unit'],
        'categ_id': None,  # Will be set by factory
    }


def get_realistic_order_scenario(scenario_type: str = 'typical') -> Dict[str, Any]:
    """
    Generate realistic order scenarios with appropriate product mixes.

    Args:
        scenario_type: 'simple', 'typical', 'complex', 'commercial', 'bulk'

    Returns:
        Dictionary with scenario configuration
    """
    scenarios = {
        'simple': {
            'description': 'Simple residential order',
            'customer_type': 'residential',
            'products': [{'type': 'blinds', 'quantity': 3}, {'type': 'services', 'quantity': 1}],
            'expected_hours': 2.5,
            'complexity': 'low',
        },
        'typical': {
            'description': 'Typical mixed residential order',
            'customer_type': 'residential',
            'products': [
                {'type': 'blinds', 'quantity': 5},
                {'type': 'shades', 'quantity': 3},
                {'type': 'services', 'quantity': 1},
            ],
            'expected_hours': 4.0,
            'complexity': 'medium',
        },
        'complex': {
            'description': 'Complex order with motorized products',
            'customer_type': 'commercial',
            'products': [
                {'type': 'blinds', 'quantity': 8},
                {'type': 'shades', 'quantity': 4},
                {'type': 'motorized', 'quantity': 2},
                {'type': 'services', 'quantity': 2},
            ],
            'expected_hours': 8.5,
            'complexity': 'high',
        },
        'commercial': {
            'description': 'Large commercial installation',
            'customer_type': 'commercial',
            'products': [
                {'type': 'blinds', 'quantity': 15},
                {'type': 'shades', 'quantity': 10},
                {'type': 'motorized', 'quantity': 5},
                {'type': 'services', 'quantity': 3},
            ],
            'expected_hours': 16.0,
            'complexity': 'very_high',
        },
        'bulk': {
            'description': 'Bulk order for property management',
            'customer_type': 'commercial',
            'products': [
                {'type': 'blinds', 'quantity': 25},
                {'type': 'shades', 'quantity': 15},
                {'type': 'services', 'quantity': 4},
            ],
            'expected_hours': 20.0,
            'complexity': 'very_high',
        },
    }

    return scenarios.get(scenario_type, scenarios['typical'])


# === INSTALLATION SCENARIOS ===

INSTALLATION_SCENARIOS = {
    'quick_residential': {
        'estimated_hours': 2.0,
        'complexity': 'Simple residential installation',
        'special_requirements': [],
        'customer_type': 'residential',
    },
    'standard_commercial': {
        'estimated_hours': 6.0,
        'complexity': 'Standard commercial installation',
        'special_requirements': ['Weekend scheduling', 'After hours access'],
        'customer_type': 'commercial',
    },
    'complex_motorized': {
        'estimated_hours': 10.0,
        'complexity': 'Complex motorized installation with programming',
        'special_requirements': ['Electrical work', 'WiFi configuration', 'Training'],
        'customer_type': 'commercial',
    },
    'bulk_property': {
        'estimated_hours': 16.0,
        'complexity': 'Multi-unit property installation',
        'special_requirements': ['Property manager coordination', 'Tenant scheduling'],
        'customer_type': 'commercial',
    },
}

# === SEASONAL AND TRENDING DATA ===

SEASONAL_TRENDS = {
    'spring': {'popular_products': ['shades', 'blinds'], 'discount_percentage': 10, 'average_order_size': 5.5},
    'summer': {'popular_products': ['motorized', 'shades'], 'discount_percentage': 15, 'average_order_size': 6.2},
    'fall': {'popular_products': ['blinds', 'services'], 'discount_percentage': 5, 'average_order_size': 4.8},
    'winter': {'popular_products': ['blinds', 'services'], 'discount_percentage': 20, 'average_order_size': 4.2},
}

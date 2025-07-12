# -*- coding: utf-8 -*-
{
    # Module Information
    'name': 'Royal Textiles Sales Enhancement',
    'version': '18.0.1.0.1',
    'category': 'Sales',
    'summary': 'Custom sales order enhancements for Royal Textiles installation company',
    # Description
    'description': """
Royal Textiles Sales Enhancement
===============================

This module adds custom business logic to sales orders specifically designed
for Royal Textiles, a commercial blinds and shades installation company.

Key Features:
* Schedule Installation button on sales orders
* Generate Work Order with installation tasks
* Calculate Materials needed for each order
* Automatic creation of installation appointments
* Integration with project management workflows
* Custom business logic for blind/shade installations

Business Logic:
* When sales order is confirmed → Enable installation scheduling
* Schedule Installation → Creates calendar event and installation record
* Generate Work Order → Creates project with installation tasks
* Calculate Materials → Estimates materials based on order lines

Target Users:
* Sales team members
* Installation coordinators
* Project managers
* Operations team
    """,
    # Author and Contact
    'author': 'RTP Denver Development Team',
    'website': 'https://github.com/matthewbergvinson/rtp-denver',
    'license': 'LGPL-3',
    # Dependencies
    'depends': [
        'base',
        'web',
        'sale',  # Sales module for extending sales orders
        'project',  # Project module for work orders
        'calendar',  # Calendar for installation appointments
    ],
    # Data Files
    'data': [
        # Security
        'security/ir.model.access.csv',
        # Views - Sales Order Enhancement
        'views/sale_order_views.xml',
        'views/installation_views.xml',
        # Menu items
        'views/installation_menu.xml',
        # Demo data
        'data/installation_demo.xml',
    ],
    # Demo Data
    'demo': [
        'data/installation_demo.xml',
    ],
    # Module Behavior
    'installable': True,
    'application': True,
    'auto_install': False,
    # Version Compatibility
    'odoo_version': '18.0',
    # Development Status
    'development_status': 'Beta',
    'maintainers': ['m@vigilanteconsulting.com'],
}

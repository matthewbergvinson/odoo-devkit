{
    'name': 'Example Module',
    'version': '1.0.0',
    'category': 'Tools',
    'summary': 'Example module for demonstrating the Odoo local testing framework',
    'description': '''
        This is an example module that demonstrates:
        - Proper module structure
        - Model creation with fields and methods
        - Views and forms
        - Controllers and routes
        - Security configuration
        - Unit and integration testing
        - Documentation generation
    ''',
    'author': 'Your Name',
    'website': 'https://github.com/matthewbergvinson/odoo-local-testing',
    'depends': ['base', 'web'],
    'data': [
        'security/ir.model.access.csv',
        'views/example_views.xml',
        'data/example_data.xml',
    ],
    'demo': [],
    'installable': True,
    'auto_install': False,
    'application': True,
    'sequence': 1,
    'license': 'LGPL-3',
} 
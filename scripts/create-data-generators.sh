#!/bin/bash

# RTP Denver - Data Generator Creation Script
# Creates all Python data generation scripts for sample data system

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_SCRIPTS_PATH="$SCRIPT_DIR/data-generators"

mkdir -p "$DATA_SCRIPTS_PATH"

# Create base generator
cat > "$DATA_SCRIPTS_PATH/base_generator.py" << 'EOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Base Data Generator for RTP Denver Sample Data System

This module provides the base class and common functionality for all data generators.
Uses Odoo's ORM to create realistic sample data for testing scenarios.

Author: RTP Denver Development Team
License: Private
"""

import argparse
import logging
import random
import sys
from datetime import date, datetime, timedelta
from pathlib import Path

# Add the project root to the Python path for imports
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

DESCRIPTION = "Base data generator with common functionality"

class BaseDataGenerator:
    """
    Base class for all data generators

    Provides common functionality for connecting to Odoo, logging,
    batch processing, and data validation.
    """

    def __init__(self, database, config_file, scenario='development'):
        self.database = database
        self.config_file = config_file
        self.scenario = scenario
        self.odoo = None
        self.env = None

        # Setup logging
        self.setup_logging()

        # Connect to Odoo
        self.connect_odoo()

    def setup_logging(self):
        """Setup logging configuration"""
        log_format = '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        logging.basicConfig(
            level=logging.INFO,
            format=log_format,
            handlers=[
                logging.StreamHandler(),
                logging.FileHandler(f'/tmp/data_generator_{self.__class__.__name__.lower()}.log')
            ]
        )
        self.logger = logging.getLogger(self.__class__.__name__)

    def connect_odoo(self):
        """Connect to Odoo using the provided configuration"""
        try:
            import odoo
            from odoo import SUPERUSER_ID
            from odoo.api import Environment

            # Initialize Odoo
            odoo.tools.config.parse_config([
                '--config', self.config_file,
                '--database', self.database,
                '--stop-after-init'
            ])

            # Get registry and environment
            registry = odoo.registry(self.database)
            with registry.cursor() as cr:
                self.env = Environment(cr, SUPERUSER_ID, {})
                self.logger.info(f"Connected to Odoo database: {self.database}")

        except Exception as e:
            self.logger.error(f"Failed to connect to Odoo: {e}")
            raise

    def generate_realistic_date(self, start_days_ago=365, end_days_ago=0):
        """Generate a realistic date within the specified range"""
        start_date = date.today() - timedelta(days=start_days_ago)
        end_date = date.today() - timedelta(days=end_days_ago)

        # Random date between start and end
        time_between = end_date - start_date
        days_between = time_between.days
        random_days = random.randrange(days_between + 1)

        return start_date + timedelta(days=random_days)

    def generate_realistic_datetime(self, start_days_ago=30, end_days_ago=0):
        """Generate a realistic datetime within the specified range"""
        base_date = self.generate_realistic_date(start_days_ago, end_days_ago)

        # Add random time during business hours (8 AM - 6 PM)
        hour = random.randint(8, 17)
        minute = random.choice([0, 15, 30, 45])

        return datetime.combine(base_date, datetime.min.time()) + timedelta(hours=hour, minutes=minute)

    def generate_phone_number(self):
        """Generate a realistic phone number"""
        area_codes = ['555', '303', '720', '970']
        area_code = random.choice(area_codes)
        exchange = random.randint(200, 999)
        number = random.randint(1000, 9999)

        return f"({area_code}) {exchange}-{number}"

    def generate_email(self, first_name, last_name, domain_list=None):
        """Generate a realistic email address"""
        if domain_list is None:
            domain_list = [
                'gmail.com', 'yahoo.com', 'outlook.com', 'company.com',
                'business.org', 'enterprise.net', 'rtpdenver.com'
            ]

        domain = random.choice(domain_list)

        # Different email patterns
        patterns = [
            f"{first_name.lower()}.{last_name.lower()}@{domain}",
            f"{first_name.lower()}{last_name.lower()}@{domain}",
            f"{first_name[0].lower()}{last_name.lower()}@{domain}",
            f"{first_name.lower()}_{last_name.lower()}@{domain}",
        ]

        return random.choice(patterns)

    def generate_website(self, company_name):
        """Generate a realistic website URL"""
        # Clean company name for URL
        clean_name = ''.join(c for c in company_name.lower() if c.isalnum())

        tlds = ['.com', '.org', '.net', '.biz']
        tld = random.choice(tlds)

        return f"www.{clean_name}{tld}"

    def create_batch(self, model_name, data_list, batch_size=100):
        """Create records in batches for better performance"""
        self.logger.info(f"Creating {len(data_list)} {model_name} records in batches of {batch_size}")

        model = self.env[model_name]
        created_records = []

        for i in range(0, len(data_list), batch_size):
            batch = data_list[i:i + batch_size]
            try:
                batch_records = model.create(batch)
                created_records.extend(batch_records)
                self.logger.info(f"Created batch {i//batch_size + 1}: {len(batch)} records")

                # Commit after each batch
                self.env.cr.commit()

            except Exception as e:
                self.logger.error(f"Failed to create batch {i//batch_size + 1}: {e}")
                self.env.cr.rollback()
                raise

        self.logger.info(f"Successfully created {len(created_records)} {model_name} records")
        return created_records

    def validate_data(self, model_name, expected_count):
        """Validate that the expected number of records were created"""
        model = self.env[model_name]
        actual_count = model.search_count([])

        if actual_count >= expected_count:
            self.logger.info(f"Validation passed: {actual_count} {model_name} records found (expected: {expected_count})")
            return True
        else:
            self.logger.error(f"Validation failed: {actual_count} {model_name} records found (expected: {expected_count})")
            return False

    def cleanup_data(self, model_name):
        """Clean up all data for a specific model"""
        model = self.env[model_name]
        records = model.search([])
        count = len(records)

        if count > 0:
            records.unlink()
            self.env.cr.commit()
            self.logger.info(f"Cleaned up {count} {model_name} records")

        return count


def setup_argument_parser():
    """Setup command line argument parser"""
    parser = argparse.ArgumentParser(description='RTP Denver Base Data Generator')
    parser.add_argument('--database', required=True, help='Target database name')
    parser.add_argument('--config', required=True, help='Odoo configuration file path')
    parser.add_argument('--count', type=int, default=100, help='Number of records to generate')
    parser.add_argument('--scenario', default='development', help='Data generation scenario')
    parser.add_argument('--batch-size', type=int, default=100, help='Batch size for record creation')
    parser.add_argument('--log-file', help='Log file path')
    parser.add_argument('--clean', action='store_true', help='Clean existing data before generation')
    parser.add_argument('--validate', action='store_true', help='Validate data after generation')

    return parser


if __name__ == '__main__':
    parser = setup_argument_parser()
    args = parser.parse_args()

    # Example usage of base generator
    generator = BaseDataGenerator(args.database, args.config, args.scenario)
    generator.logger.info("Base data generator initialized successfully")

    print("Base data generator is ready for use by other generators")
EOF

# Create customer generator
cat > "$DATA_SCRIPTS_PATH/customer_generator.py" << 'EOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Customer Data Generator for RTP Denver Sample Data System

Generates realistic customer data for the RTP Customers module.
Creates customers with realistic names, contact information, and business relationships.

Author: RTP Denver Development Team
License: Private
"""

import random
from base_generator import BaseDataGenerator, setup_argument_parser

DESCRIPTION = "Generates realistic customer data for RTP Customers module"

class CustomerDataGenerator(BaseDataGenerator):
    """
    Customer data generator for RTP Customers module

    Creates realistic customer records with:
    - Realistic names and company names
    - Valid contact information
    - Appropriate priority and status distributions
    - Realistic signup and contact dates
    """

    def __init__(self, database, config_file, scenario='development'):
        super().__init__(database, config_file, scenario)

        # Data pools for realistic generation
        self.first_names = [
            'James', 'Mary', 'John', 'Patricia', 'Robert', 'Jennifer', 'Michael', 'Linda',
            'William', 'Elizabeth', 'David', 'Barbara', 'Richard', 'Susan', 'Joseph', 'Jessica',
            'Thomas', 'Sarah', 'Charles', 'Karen', 'Christopher', 'Nancy', 'Daniel', 'Lisa',
            'Matthew', 'Betty', 'Anthony', 'Helen', 'Mark', 'Sandra', 'Donald', 'Donna',
            'Steven', 'Carol', 'Paul', 'Ruth', 'Andrew', 'Sharon', 'Joshua', 'Michelle'
        ]

        self.last_names = [
            'Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller', 'Davis',
            'Rodriguez', 'Martinez', 'Hernandez', 'Lopez', 'Gonzalez', 'Wilson', 'Anderson', 'Thomas',
            'Taylor', 'Moore', 'Jackson', 'Martin', 'Lee', 'Perez', 'Thompson', 'White',
            'Harris', 'Sanchez', 'Clark', 'Ramirez', 'Lewis', 'Robinson', 'Walker', 'Young'
        ]

        self.company_types = [
            'LLC', 'Inc', 'Corp', 'Co', 'Company', 'Enterprises', 'Group', 'Solutions',
            'Services', 'Consulting', 'Partners', 'Associates', 'Industries', 'Systems'
        ]

        self.business_words = [
            'Advanced', 'Global', 'Premier', 'Elite', 'Professional', 'Strategic', 'Dynamic',
            'Innovative', 'Creative', 'Reliable', 'Quality', 'Superior', 'Excellence', 'Prime',
            'Metro', 'Capital', 'Summit', 'Alliance', 'Vertex', 'Pinnacle', 'Core', 'Matrix'
        ]

        self.industries = [
            'Technology', 'Healthcare', 'Finance', 'Manufacturing', 'Retail', 'Construction',
            'Education', 'Transportation', 'Real Estate', 'Hospitality', 'Legal', 'Marketing'
        ]

    def generate_customer_name(self):
        """Generate a realistic customer name (individual or company)"""
        if random.choice([True, False]):  # 50% individual, 50% company
            first_name = random.choice(self.first_names)
            last_name = random.choice(self.last_names)
            return f"{first_name} {last_name}", first_name, last_name
        else:
            # Company name
            business_word = random.choice(self.business_words)
            industry = random.choice(self.industries)
            company_type = random.choice(self.company_types)

            patterns = [
                f"{business_word} {industry} {company_type}",
                f"{business_word} {company_type}",
                f"{industry} {business_word} {company_type}",
                f"{random.choice(self.last_names)} {industry} {company_type}"
            ]

            company_name = random.choice(patterns)
            return company_name, business_word, industry

    def get_priority_distribution(self):
        """Get realistic priority distribution based on scenario"""
        if self.scenario == 'testing':
            # Equal distribution for testing
            return {'0': 25, '1': 25, '2': 25, '3': 25}  # Low, Medium, High, VIP
        elif self.scenario == 'performance':
            # More low priority for performance testing
            return {'0': 50, '1': 30, '2': 15, '3': 5}
        else:
            # Realistic distribution for development/demo
            return {'0': 30, '1': 40, '2': 25, '3': 5}

    def get_status_distribution(self):
        """Get realistic status distribution based on scenario"""
        if self.scenario == 'testing':
            # Equal distribution for testing
            return {'prospect': 25, 'active': 25, 'inactive': 25, 'blocked': 25}
        else:
            # Realistic distribution
            return {'prospect': 20, 'active': 60, 'inactive': 15, 'blocked': 5}

    def generate_customers(self, count, batch_size=100):
        """Generate the specified number of customer records"""
        self.logger.info(f"Generating {count} customers for scenario: {self.scenario}")

        # Get available users for assignment
        users = self.env['res.users'].search([])
        if not users:
            self.logger.error("No users found for customer assignment")
            return []

        # Get distribution weights
        priority_dist = self.get_priority_distribution()
        status_dist = self.get_status_distribution()

        customers_data = []

        for i in range(count):
            # Generate customer name and details
            customer_name, first_part, second_part = self.generate_customer_name()

            # Generate contact information
            email = self.generate_email(first_part, second_part)
            phone = self.generate_phone_number()
            website = self.generate_website(customer_name) if random.random() > 0.3 else False

            # Assign priority and status based on distribution
            priority = random.choices(
                list(priority_dist.keys()),
                weights=list(priority_dist.values())
            )[0]

            status = random.choices(
                list(status_dist.keys()),
                weights=list(status_dist.values())
            )[0]

            # Generate dates
            signup_date = self.generate_realistic_date(365, 0)

            # Last contact date based on status
            if status == 'active':
                # Active customers contacted recently
                last_contact_date = self.generate_realistic_date(30, 0)
            elif status == 'prospect':
                # Prospects may not have been contacted yet
                last_contact_date = self.generate_realistic_date(7, 0) if random.random() > 0.3 else False
            elif status == 'inactive':
                # Inactive customers not contacted for a while
                last_contact_date = self.generate_realistic_date(180, 90)
            else:  # blocked
                # Blocked customers have old contact dates
                last_contact_date = self.generate_realistic_date(365, 180)

            # Assign to random user
            user_id = random.choice(users).id

            # Generate description/notes
            descriptions = [
                f"Customer in {random.choice(self.industries)} industry",
                f"Referred by existing customer",
                f"Responded to marketing campaign",
                f"Trade show contact from recent event",
                f"Website inquiry for {random.choice(['products', 'services', 'consultation'])}",
                f"Existing relationship with {first_part}",
                ""  # Some customers have no description
            ]

            description = random.choice(descriptions)

            customer_data = {
                'name': customer_name,
                'description': description,
                'priority': priority,
                'status': status,
                'user_id': user_id,
                'email': email,
                'phone': phone,
                'website': website,
                'signup_date': signup_date,
                'last_contact_date': last_contact_date,
            }

            customers_data.append(customer_data)

            # Progress logging
            if (i + 1) % 100 == 0:
                self.logger.info(f"Prepared {i + 1}/{count} customer records")

        # Create customers in batches
        return self.create_batch('rtp.customer', customers_data, batch_size)

    def generate_sample_data(self, count, batch_size=100, clean_first=False):
        """Main method to generate customer sample data"""
        if clean_first:
            self.cleanup_data('rtp.customer')

        # Generate customers
        customers = self.generate_customers(count, batch_size)

        # Validate results
        if self.validate_data('rtp.customer', count):
            self.logger.info(f"Successfully generated {len(customers)} customer records")
            return True
        else:
            self.logger.error("Customer data validation failed")
            return False


def main():
    parser = setup_argument_parser()
    parser.description = 'Generate customer data for RTP Customers module'
    args = parser.parse_args()

    generator = CustomerDataGenerator(args.database, args.config, args.scenario)

    success = generator.generate_sample_data(
        count=args.count,
        batch_size=args.batch_size,
        clean_first=args.clean
    )

    if success:
        print(f"Successfully generated {args.count} customer records")
        exit(0)
    else:
        print("Customer data generation failed")
        exit(1)


if __name__ == '__main__':
    main()
EOF

# Create sales generator
cat > "$DATA_SCRIPTS_PATH/sales_generator.py" << 'EOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Sales Order Data Generator for RTP Denver Sample Data System

Generates realistic sales order data for Royal Textiles Sales module.
Creates sales orders with realistic products, quantities, and pricing.

Author: RTP Denver Development Team
License: Private
"""

import random
from base_generator import BaseDataGenerator, setup_argument_parser

DESCRIPTION = "Generates realistic sales order data for Royal Textiles module"

class SalesDataGenerator(BaseDataGenerator):
    """
    Sales order data generator for Royal Textiles Sales module

    Creates realistic sales orders with:
    - Appropriate products for blinds/shades business
    - Realistic quantities and pricing
    - Proper workflow states
    - Customer relationships
    """

    def __init__(self, database, config_file, scenario='development'):
        super().__init__(database, config_file, scenario)

        # Product definitions for blinds and shades business
        self.product_categories = {
            'vertical_blinds': {
                'names': [
                    'Commercial Vertical Blinds - White',
                    'Commercial Vertical Blinds - Beige',
                    'Commercial Vertical Blinds - Gray',
                    'Heavy Duty Vertical Blinds - Black',
                    'Premium Vertical Blinds - Custom Color'
                ],
                'price_range': (150, 300),
                'typical_qty': (2, 12)
            },
            'horizontal_blinds': {
                'names': [
                    'Aluminum Horizontal Blinds - 1 inch',
                    'Aluminum Horizontal Blinds - 2 inch',
                    'Wood Horizontal Blinds - Maple',
                    'Wood Horizontal Blinds - Oak',
                    'Faux Wood Horizontal Blinds'
                ],
                'price_range': (80, 200),
                'typical_qty': (1, 8)
            },
            'roller_shades': {
                'names': [
                    'Blackout Roller Shades',
                    'Light Filtering Roller Shades',
                    'Solar Screen Roller Shades',
                    'Custom Fabric Roller Shades',
                    'Dual Roller Shades System'
                ],
                'price_range': (120, 250),
                'typical_qty': (1, 6)
            },
            'motorized': {
                'names': [
                    'Motorized Vertical Blinds System',
                    'Motorized Roller Shades',
                    'Smart Home Integration Package',
                    'Remote Control Blinds',
                    'Automated Shade System'
                ],
                'price_range': (400, 800),
                'typical_qty': (1, 4)
            },
            'installation': {
                'names': [
                    'Professional Installation Service',
                    'Measurement and Consultation',
                    'Hardware Installation',
                    'Custom Mounting Solutions',
                    'Installation Project Management'
                ],
                'price_range': (50, 200),
                'typical_qty': (1, 3)
            }
        }

    def ensure_products_exist(self):
        """Ensure all required products exist in the system"""
        self.logger.info("Ensuring required products exist")

        product_model = self.env['product.product']
        category_model = self.env['product.category']

        # Create product category for blinds and shades
        category = category_model.search([('name', '=', 'Blinds & Shades')])
        if not category:
            category = category_model.create({
                'name': 'Blinds & Shades',
                'description': 'Commercial blinds, shades, and installation services'
            })

        created_products = []

        for category_key, category_data in self.product_categories.items():
            for product_name in category_data['names']:
                # Check if product already exists
                existing_product = product_model.search([('name', '=', product_name)])

                if not existing_product:
                    # Create the product
                    price_min, price_max = category_data['price_range']
                    list_price = random.uniform(price_min, price_max)

                    product_data = {
                        'name': product_name,
                        'type': 'product',
                        'categ_id': category.id,
                        'list_price': list_price,
                        'sale_ok': True,
                        'purchase_ok': True,
                        'description_sale': f"High-quality {product_name.lower()} for commercial installations",
                    }

                    product = product_model.create(product_data)
                    created_products.append(product)
                    self.logger.info(f"Created product: {product_name}")

        self.logger.info(f"Products ready: {len(created_products)} created")
        return created_products

    def get_random_products_for_order(self):
        """Get a realistic combination of products for a sales order"""
        product_model = self.env['product.product']

        # Get all available products
        all_products = []
        for category_data in self.product_categories.values():
            for product_name in category_data['names']:
                product = product_model.search([('name', '=', product_name)], limit=1)
                if product:
                    all_products.append(product)

        if not all_products:
            self.logger.error("No products found for sales orders")
            return []

        # Generate realistic order lines
        order_lines = []

        # 70% chance of having main product (blinds or shades)
        if random.random() < 0.7:
            main_categories = ['vertical_blinds', 'horizontal_blinds', 'roller_shades']
            category_key = random.choice(main_categories)
            category_data = self.product_categories[category_key]

            product_name = random.choice(category_data['names'])
            product = product_model.search([('name', '=', product_name)], limit=1)

            if product:
                qty_min, qty_max = category_data['typical_qty']
                quantity = random.randint(qty_min, qty_max)

                order_lines.append({
                    'product': product,
                    'quantity': quantity,
                    'price_unit': product.list_price
                })

        # 60% chance of having installation service
        if random.random() < 0.6:
            installation_products = [
                product for product in all_products
                if 'installation' in product.name.lower() or 'service' in product.name.lower()
            ]

            if installation_products:
                product = random.choice(installation_products)
                quantity = random.randint(1, 2)

                order_lines.append({
                    'product': product,
                    'quantity': quantity,
                    'price_unit': product.list_price
                })

        # 30% chance of having motorized upgrade
        if random.random() < 0.3:
            motorized_products = [
                product for product in all_products
                if 'motorized' in product.name.lower() or 'smart' in product.name.lower()
            ]

            if motorized_products:
                product = random.choice(motorized_products)
                quantity = random.randint(1, 2)

                order_lines.append({
                    'product': product,
                    'quantity': quantity,
                    'price_unit': product.list_price
                })

        # Ensure at least one product
        if not order_lines and all_products:
            product = random.choice(all_products)
            order_lines.append({
                'product': product,
                'quantity': random.randint(1, 5),
                'price_unit': product.list_price
            })

        return order_lines

    def generate_sales_orders(self, count, batch_size=50):
        """Generate the specified number of sales orders"""
        self.logger.info(f"Generating {count} sales orders for scenario: {self.scenario}")

        # Ensure products exist
        self.ensure_products_exist()

        # Get available customers (partners)
        customers = self.env['res.partner'].search([('is_company', '=', False)])
        if not customers:
            # Fallback to any partners
            customers = self.env['res.partner'].search([])

        if not customers:
            self.logger.error("No customers found for sales orders")
            return []

        # Get available users for salesperson assignment
        users = self.env['res.users'].search([])
        if not users:
            self.logger.error("No users found for salesperson assignment")
            return []

        sales_orders_data = []

        for i in range(count):
            # Select random customer and salesperson
            customer = random.choice(customers)
            salesperson = random.choice(users)

            # Generate order date
            order_date = self.generate_realistic_datetime(90, 0)

            # Determine order state based on scenario and date
            if self.scenario == 'testing':
                # Equal distribution for testing
                states = ['draft', 'sent', 'sale', 'done', 'cancel']
                state = random.choice(states)
            else:
                # Realistic distribution
                if order_date.date() < (datetime.now().date() - timedelta(days=30)):
                    # Older orders are more likely to be confirmed/done
                    state = random.choices(
                        ['sale', 'done', 'cancel'],
                        weights=[60, 30, 10]
                    )[0]
                else:
                    # Recent orders might still be in progress
                    state = random.choices(
                        ['draft', 'sent', 'sale', 'done'],
                        weights=[20, 20, 40, 20]
                    )[0]

            # Create basic sales order
            order_data = {
                'partner_id': customer.id,
                'user_id': salesperson.id,
                'date_order': order_date,
                'state': state,
                'company_id': 1,  # Default company
            }

            sales_orders_data.append(order_data)

            # Progress logging
            if (i + 1) % 50 == 0:
                self.logger.info(f"Prepared {i + 1}/{count} sales order records")

        # Create sales orders in batches
        return self.create_batch('sale.order', sales_orders_data, batch_size)

    def add_order_lines_to_orders(self, orders):
        """Add order lines to the created sales orders"""
        self.logger.info(f"Adding order lines to {len(orders)} sales orders")

        order_line_model = self.env['sale.order.line']

        for i, order in enumerate(orders):
            try:
                # Get products for this order
                order_lines_data = self.get_random_products_for_order()

                for line_data in order_lines_data:
                    line_vals = {
                        'order_id': order.id,
                        'product_id': line_data['product'].id,
                        'product_uom_qty': line_data['quantity'],
                        'price_unit': line_data['price_unit'],
                        'name': line_data['product'].name,
                    }

                    order_line_model.create(line_vals)

                # Update order amount
                order._compute_amount_all()

                if (i + 1) % 100 == 0:
                    self.logger.info(f"Added order lines to {i + 1}/{len(orders)} orders")
                    self.env.cr.commit()

            except Exception as e:
                self.logger.error(f"Failed to add order lines to order {order.id}: {e}")
                continue

        self.env.cr.commit()
        self.logger.info("Order lines creation completed")

    def generate_sample_data(self, count, batch_size=50, clean_first=False):
        """Main method to generate sales order sample data"""
        if clean_first:
            self.cleanup_data('sale.order.line')
            self.cleanup_data('sale.order')

        # Generate sales orders
        orders = self.generate_sales_orders(count, batch_size)

        # Add order lines
        self.add_order_lines_to_orders(orders)

        # Validate results
        if self.validate_data('sale.order', count):
            self.logger.info(f"Successfully generated {len(orders)} sales order records")
            return True
        else:
            self.logger.error("Sales order data validation failed")
            return False


def main():
    parser = setup_argument_parser()
    parser.description = 'Generate sales order data for Royal Textiles Sales module'
    args = parser.parse_args()

    generator = SalesDataGenerator(args.database, args.config, args.scenario)

    success = generator.generate_sample_data(
        count=args.count,
        batch_size=args.batch_size,
        clean_first=args.clean
    )

    if success:
        print(f"Successfully generated {args.count} sales order records")
        exit(0)
    else:
        print("Sales order data generation failed")
        exit(1)


if __name__ == '__main__':
    main()
EOF

# Create installation generator
cat > "$DATA_SCRIPTS_PATH/installation_generator.py" << 'EOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Installation Data Generator for RTP Denver Sample Data System

Generates realistic installation data for Royal Textiles Sales module.
Creates installation records with realistic scheduling and workflow states.

Author: RTP Denver Development Team
License: Private
"""

import random
from datetime import datetime, timedelta
from base_generator import BaseDataGenerator, setup_argument_parser

DESCRIPTION = "Generates realistic installation data for Royal Textiles module"

class InstallationDataGenerator(BaseDataGenerator):
    """
    Installation data generator for Royal Textiles Sales module

    Creates realistic installation records with:
    - Proper relationships to sales orders
    - Realistic scheduling dates
    - Appropriate status workflow
    - Installation notes and materials
    """

    def __init__(self, database, config_file, scenario='development'):
        super().__init__(database, config_file, scenario)

        # Installation-related data
        self.installation_types = [
            'Office Building Installation',
            'Retail Store Setup',
            'Restaurant Window Treatment',
            'Medical Office Installation',
            'School Classroom Installation',
            'Conference Room Setup',
            'Lobby Area Installation',
            'Warehouse Office Installation'
        ]

        self.special_instructions = [
            'Building requires security check-in at front desk',
            'Installation must be completed during business hours (8 AM - 6 PM)',
            'Contact building manager upon arrival',
            'Use freight elevator for equipment transport',
            'Parking available in visitor spaces',
            'Customer will provide ladder and basic tools',
            'Multiple rooms - coordinate with office manager',
            'After-hours installation approved - use side entrance',
            'Sensitive equipment in area - exercise caution',
            'Customer prefers minimal disruption to operations'
        ]

        self.material_templates = [
            "• {qty} x {product_type}\n• {brackets} x Mounting Brackets\n• {screws} x Screws\n• Installation hardware",
            "• {qty} x {product_type}\n• Custom mounting solutions\n• Hardware kit included\n• Touch-up materials",
            "• {qty} x {product_type}\n• Professional installation kit\n• Quality assurance tools\n• Cleanup materials"
        ]

    def get_available_sales_orders(self):
        """Get sales orders that can have installations"""
        # Get confirmed sales orders that don't already have installations
        orders = self.env['sale.order'].search([
            ('state', 'in', ['sale', 'done']),
        ])

        # Filter out orders that already have installations
        available_orders = []
        for order in orders:
            existing_installation = self.env['royal.installation'].search([
                ('sale_order_id', '=', order.id)
            ], limit=1)

            if not existing_installation:
                available_orders.append(order)

        return available_orders

    def generate_installation_materials(self, sale_order):
        """Generate realistic materials notes based on sales order"""
        materials_lines = []
        total_qty = 0

        for line in sale_order.order_line:
            product_name = line.product_id.name
            qty = int(line.product_uom_qty)
            total_qty += qty

            if 'blind' in product_name.lower():
                materials_lines.append(f"• {qty} x {product_name}")
                materials_lines.append(f"• {qty * 2} x Mounting Brackets (for blinds)")
                materials_lines.append(f"• {qty * 4} x Screws (standard)")
            elif 'shade' in product_name.lower():
                materials_lines.append(f"• {qty} x {product_name}")
                materials_lines.append(f"• {qty * 2} x Mounting Brackets (for shades)")
                materials_lines.append(f"• {qty * 2} x Screws (light duty)")
            elif 'motorized' in product_name.lower():
                materials_lines.append(f"• {qty} x {product_name}")
                materials_lines.append(f"• {qty * 3} x Heavy Duty Brackets")
                materials_lines.append(f"• {qty * 6} x Screws (heavy duty)")
                materials_lines.append(f"• Electrical wiring kit")
            elif 'installation' not in product_name.lower():
                materials_lines.append(f"• {qty} x {product_name}")

        # Add common materials
        materials_lines.extend([
            "• Drill and bits",
            "• Level and measuring tape",
            "• Safety equipment",
            "• Touch-up materials",
            "• Cleaning supplies"
        ])

        # Calculate estimated weight
        estimated_weight = total_qty * random.uniform(2.5, 4.0)

        materials_notes = "\n".join(materials_lines)
        materials_notes += f"\n\nEstimated Total Weight: {estimated_weight:.1f} lbs"

        return materials_notes, estimated_weight

    def generate_installations(self, count, batch_size=50):
        """Generate the specified number of installation records"""
        self.logger.info(f"Generating {count} installations for scenario: {self.scenario}")

        # Get available sales orders
        available_orders = self.get_available_sales_orders()

        if len(available_orders) < count:
            self.logger.warning(f"Only {len(available_orders)} sales orders available for {count} installations")
            count = min(count, len(available_orders))

        if count == 0:
            self.logger.error("No sales orders available for installation generation")
            return []

        # Get available users for installer assignment
        users = self.env['res.users'].search([])
        if not users:
            self.logger.error("No users found for installer assignment")
            return []

        installations_data = []
        used_orders = set()

        for i in range(count):
            # Select available sales order (avoid duplicates)
            available_orders_filtered = [o for o in available_orders if o.id not in used_orders]
            if not available_orders_filtered:
                self.logger.warning(f"Ran out of unique sales orders at installation {i}")
                break

            sale_order = random.choice(available_orders_filtered)
            used_orders.add(sale_order.id)

            # Get customer from sales order
            customer = sale_order.partner_id

            # Assign installer
            installer = random.choice(users)

            # Generate installation name
            installation_name = f"Installation - {customer.name}"
            if len(installation_name) > 50:
                installation_name = installation_name[:47] + "..."

            # Generate dates based on sales order
            order_date = sale_order.date_order

            # Scheduled date: 1-14 days after order
            days_ahead = random.randint(1, 14)
            scheduled_date = order_date + timedelta(days=days_ahead)

            # Adjust to business hours (9 AM - 5 PM)
            scheduled_date = scheduled_date.replace(
                hour=random.randint(9, 16),
                minute=random.choice([0, 30]),
                second=0,
                microsecond=0
            )

            # Determine status based on scheduled date and scenario
            now = datetime.now()

            if self.scenario == 'testing':
                # Equal distribution for testing
                status = random.choice(['draft', 'scheduled', 'in_progress', 'completed', 'cancelled'])
            else:
                # Realistic distribution based on date
                if scheduled_date < now - timedelta(days=7):
                    # Past installations are likely completed
                    status = random.choices(
                        ['completed', 'cancelled'],
                        weights=[90, 10]
                    )[0]
                elif scheduled_date < now:
                    # Recent past installations
                    status = random.choices(
                        ['in_progress', 'completed', 'cancelled'],
                        weights=[20, 70, 10]
                    )[0]
                else:
                    # Future installations
                    status = random.choices(
                        ['draft', 'scheduled'],
                        weights=[30, 70]
                    )[0]

            # Generate actual dates for completed/in-progress installations
            actual_start_date = None
            completion_date = None
            actual_hours = None

            if status in ['in_progress', 'completed']:
                # Actual start date is on or near scheduled date
                start_offset = random.randint(-1, 1)  # Can start up to 1 day early/late
                actual_start_date = scheduled_date + timedelta(days=start_offset)

                if status == 'completed':
                    # Completion date is same day or next day
                    completion_offset = random.randint(0, 1)
                    completion_date = actual_start_date + timedelta(days=completion_offset)

                    # Set actual hours
                    estimated_hours = random.uniform(2.0, 8.0)
                    actual_hours = estimated_hours * random.uniform(0.8, 1.3)  # ±30% of estimate

            # Generate estimated hours based on sales order
            estimated_hours = 2.0  # Minimum
            for line in sale_order.order_line:
                estimated_hours += line.product_uom_qty * 0.5  # 30 min per unit
                if 'motorized' in line.product_id.name.lower():
                    estimated_hours += line.product_uom_qty * 1.0  # Extra for motorized

            estimated_hours = min(estimated_hours, 12.0)  # Cap at 12 hours

            # Generate materials and notes
            materials_notes, estimated_weight = self.generate_installation_materials(sale_order)

            # Generate description
            description_templates = [
                f"Professional installation for {customer.name}. {random.choice(self.installation_types)}.",
                f"Installation project for {customer.name}. Multiple {random.choice(['conference rooms', 'offices', 'areas'])} included.",
                f"Custom installation for {customer.name}. {random.choice(['High-quality', 'Premium', 'Professional'])} window treatments.",
                f"Standard installation for {customer.name}. {random.choice(['Office', 'Commercial', 'Retail'])} environment."
            ]

            description = random.choice(description_templates)

            # Generate installation address (use customer address as base)
            if customer.street:
                installation_address = f"{customer.street}"
                if customer.street2:
                    installation_address += f"\n{customer.street2}"
                if customer.city and customer.state_id:
                    installation_address += f"\n{customer.city}, {customer.state_id.name}"
                if customer.zip:
                    installation_address += f" {customer.zip}"
            else:
                installation_address = f"Customer location: {customer.name}"

            installation_data = {
                'name': installation_name,
                'description': description,
                'sale_order_id': sale_order.id,
                'customer_id': customer.id,
                'installer_id': installer.id,
                'status': status,
                'scheduled_date': scheduled_date,
                'actual_start_date': actual_start_date,
                'completion_date': completion_date,
                'estimated_hours': estimated_hours,
                'actual_hours': actual_hours,
                'estimated_weight': estimated_weight,
                'materials_notes': materials_notes,
                'installation_address': installation_address,
                'special_instructions': random.choice(self.special_instructions) if random.random() > 0.3 else False,
            }

            installations_data.append(installation_data)

            # Progress logging
            if (i + 1) % 25 == 0:
                self.logger.info(f"Prepared {i + 1}/{count} installation records")

        # Create installations in batches
        return self.create_batch('royal.installation', installations_data, batch_size)

    def generate_sample_data(self, count, batch_size=50, clean_first=False):
        """Main method to generate installation sample data"""
        if clean_first:
            self.cleanup_data('royal.installation')

        # Generate installations
        installations = self.generate_installations(count, batch_size)

        # Validate results
        if self.validate_data('royal.installation', len(installations)):
            self.logger.info(f"Successfully generated {len(installations)} installation records")
            return True
        else:
            self.logger.error("Installation data validation failed")
            return False


def main():
    parser = setup_argument_parser()
    parser.description = 'Generate installation data for Royal Textiles Sales module'
    args = parser.parse_args()

    generator = InstallationDataGenerator(args.database, args.config, args.scenario)

    success = generator.generate_sample_data(
        count=args.count,
        batch_size=args.batch_size,
        clean_first=args.clean
    )

    if success:
        print(f"Successfully generated installation records")
        exit(0)
    else:
        print("Installation data generation failed")
        exit(1)


if __name__ == '__main__':
    main()
EOF

# Create user generator
cat > "$DATA_SCRIPTS_PATH/user_generator.py" << 'EOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
User Data Generator for RTP Denver Sample Data System

Generates demo users for testing scenarios.
Creates users with appropriate roles and permissions.

Author: RTP Denver Development Team
License: Private
"""

import random
from base_generator import BaseDataGenerator, setup_argument_parser

DESCRIPTION = "Generates demo users with appropriate roles for testing"

class UserDataGenerator(BaseDataGenerator):
    """
    User data generator

    Creates demo users with:
    - Realistic names and contact information
    - Appropriate access groups
    - Different roles (sales, manager, admin)
    """

    def __init__(self, database, config_file, scenario='development'):
        super().__init__(database, config_file, scenario)

        # User data pools
        self.first_names = [
            'Alice', 'Bob', 'Carol', 'David', 'Emma', 'Frank', 'Grace', 'Henry',
            'Isabel', 'Jack', 'Karen', 'Luis', 'Maria', 'Nathan', 'Olivia', 'Peter',
            'Quinn', 'Rachel', 'Samuel', 'Tina', 'Victor', 'Wendy', 'Xavier', 'Yvonne'
        ]

        self.last_names = [
            'Anderson', 'Brown', 'Clark', 'Davis', 'Evans', 'Foster', 'Green', 'Hall',
            'Jackson', 'King', 'Lewis', 'Miller', 'Nelson', 'Parker', 'Roberts', 'Smith',
            'Taylor', 'Williams', 'Young', 'Adams', 'Baker', 'Cooper', 'Fisher', 'Gray'
        ]

        self.job_titles = {
            'sales': [
                'Sales Representative', 'Account Manager', 'Sales Associate',
                'Business Development Rep', 'Territory Manager', 'Sales Specialist'
            ],
            'manager': [
                'Sales Manager', 'Operations Manager', 'Project Manager',
                'Installation Manager', 'Customer Success Manager', 'Regional Manager'
            ],
            'admin': [
                'System Administrator', 'Office Manager', 'Operations Coordinator',
                'Administrative Assistant', 'Data Entry Specialist'
            ]
        }

    def get_access_groups(self, role):
        """Get appropriate access groups for user role"""
        group_model = self.env['res.groups']

        # Base groups all users should have
        base_groups = [
            'base.group_user',  # Internal User
            'base.group_partner_manager',  # Contact Creation
        ]

        role_groups = {
            'sales': [
                'sales_team.group_sale_salesman',  # User: Own Documents Only
                'account.group_account_readonly',  # Billing: Read Access
            ],
            'manager': [
                'sales_team.group_sale_manager',  # Manager
                'account.group_account_user',  # Billing: User
                'project.group_project_manager',  # Project Manager
            ],
            'admin': [
                'base.group_system',  # Settings
                'sales_team.group_sale_manager',  # Sales Manager
                'account.group_account_manager',  # Billing Manager
            ]
        }

        all_groups = base_groups + role_groups.get(role, [])

        # Find existing groups
        groups = []
        for group_xml_id in all_groups:
            try:
                group = self.env.ref(group_xml_id)
                if group:
                    groups.append(group.id)
            except:
                self.logger.warning(f"Group not found: {group_xml_id}")
                continue

        return groups

    def generate_users(self, count, batch_size=20):
        """Generate the specified number of demo users"""
        self.logger.info(f"Generating {count} demo users for scenario: {self.scenario}")

        # Don't create too many users in testing scenario
        if self.scenario == 'testing' and count > 10:
            count = 10
            self.logger.info(f"Limited to {count} users for testing scenario")

        users_data = []

        # Role distribution
        role_distribution = {
            'sales': 60,    # 60% sales reps
            'manager': 30,  # 30% managers
            'admin': 10     # 10% admins
        }

        for i in range(count):
            # Select role based on distribution
            role = random.choices(
                list(role_distribution.keys()),
                weights=list(role_distribution.values())
            )[0]

            # Generate name
            first_name = random.choice(self.first_names)
            last_name = random.choice(self.last_names)
            name = f"{first_name} {last_name}"

            # Generate login (email)
            login = f"{first_name.lower()}.{last_name.lower()}@rtpdenver.com"

            # Make sure login is unique
            existing_user = self.env['res.users'].search([('login', '=', login)])
            if existing_user:
                login = f"{first_name.lower()}.{last_name.lower()}{i}@rtpdenver.com"

            # Generate other details
            job_title = random.choice(self.job_titles[role])

            # Get access groups
            groups = self.get_access_groups(role)

            user_data = {
                'name': name,
                'login': login,
                'email': login,
                'password': 'demo123',  # Simple password for demo
                'groups_id': [(6, 0, groups)] if groups else False,
                'function': job_title,
                'phone': self.generate_phone_number(),
                'active': True,
            }

            users_data.append(user_data)

            # Progress logging
            if (i + 1) % 10 == 0:
                self.logger.info(f"Prepared {i + 1}/{count} user records")

        # Create users in batches
        return self.create_batch('res.users', users_data, batch_size)

    def generate_sample_data(self, count, batch_size=20, clean_first=False):
        """Main method to generate user sample data"""
        if clean_first:
            # Don't clean admin user
            demo_users = self.env['res.users'].search([
                ('login', 'like', '%@rtpdenver.com'),
                ('login', '!=', 'admin')
            ])
            if demo_users:
                demo_users.unlink()
                self.env.cr.commit()
                self.logger.info(f"Cleaned {len(demo_users)} demo users")

        # Generate users
        users = self.generate_users(count, batch_size)

        # Validate results (count existing demo users)
        demo_user_count = self.env['res.users'].search_count([
            ('login', 'like', '%@rtpdenver.com'),
            ('login', '!=', 'admin')
        ])

        if demo_user_count >= count:
            self.logger.info(f"Successfully generated {len(users)} user records")
            return True
        else:
            self.logger.error("User data validation failed")
            return False


def main():
    parser = setup_argument_parser()
    parser.description = 'Generate demo users for testing'
    args = parser.parse_args()

    generator = UserDataGenerator(args.database, args.config, args.scenario)

    success = generator.generate_sample_data(
        count=args.count,
        batch_size=args.batch_size,
        clean_first=args.clean
    )

    if success:
        print(f"Successfully generated demo user records")
        exit(0)
    else:
        print("User data generation failed")
        exit(1)


if __name__ == '__main__':
    main()
EOF

# Create cleanup script
cat > "$DATA_SCRIPTS_PATH/data_cleanup.py" << 'EOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Data Cleanup Script for RTP Denver Sample Data System

Removes sample data from the database.
Provides selective cleanup options.

Author: RTP Denver Development Team
License: Private
"""

import argparse
import logging
from base_generator import BaseDataGenerator

DESCRIPTION = "Cleans up sample data from database"

class DataCleanup(BaseDataGenerator):
    """
    Data cleanup utility

    Removes sample data while preserving system data.
    """

    def __init__(self, database, config_file):
        super().__init__(database, config_file, 'cleanup')

        # Models to clean in dependency order (children first)
        self.cleanup_models = [
            'royal.installation',
            'sale.order.line',
            'sale.order',
            'rtp.customer',
            'product.product',  # Only demo products
            'res.users',  # Only demo users
        ]

    def cleanup_installations(self):
        """Clean up installation records"""
        installations = self.env['royal.installation'].search([])
        count = len(installations)

        if count > 0:
            installations.unlink()
            self.logger.info(f"Cleaned {count} installation records")

        return count

    def cleanup_sales_orders(self):
        """Clean up sales orders and their lines"""
        # Clean order lines first
        order_lines = self.env['sale.order.line'].search([])
        line_count = len(order_lines)

        if line_count > 0:
            order_lines.unlink()
            self.logger.info(f"Cleaned {line_count} sales order lines")

        # Clean sales orders
        orders = self.env['sale.order'].search([])
        order_count = len(orders)

        if order_count > 0:
            orders.unlink()
            self.logger.info(f"Cleaned {order_count} sales orders")

        return order_count + line_count

    def cleanup_customers(self):
        """Clean up RTP customer records"""
        customers = self.env['rtp.customer'].search([])
        count = len(customers)

        if count > 0:
            customers.unlink()
            self.logger.info(f"Cleaned {count} customer records")

        return count

    def cleanup_demo_products(self):
        """Clean up demo products (blinds and shades)"""
        # Find products in blinds & shades category
        category = self.env['product.category'].search([('name', '=', 'Blinds & Shades')])

        count = 0
        if category:
            products = self.env['product.product'].search([('categ_id', '=', category.id)])
            count = len(products)

            if count > 0:
                products.unlink()
                self.logger.info(f"Cleaned {count} demo products")

                # Clean up category if empty
                remaining_products = self.env['product.product'].search([('categ_id', '=', category.id)])
                if not remaining_products:
                    category.unlink()
                    self.logger.info("Cleaned demo product category")

        return count

    def cleanup_demo_users(self):
        """Clean up demo users (keep admin)"""
        demo_users = self.env['res.users'].search([
            ('login', 'like', '%@rtpdenver.com'),
            ('login', '!=', 'admin')
        ])

        count = len(demo_users)

        if count > 0:
            demo_users.unlink()
            self.logger.info(f"Cleaned {count} demo users")

        return count

    def cleanup_all(self, force=False):
        """Clean up all sample data"""
        if not force:
            print("This will remove ALL sample data from the database.")
            print("This includes:")
            print("  • All installation records")
            print("  • All sales orders and order lines")
            print("  • All RTP customer records")
            print("  • All demo products")
            print("  • All demo users (except admin)")
            print("")

            confirm = input("Are you sure you want to continue? (yes/no): ")
            if confirm.lower() not in ['yes', 'y']:
                print("Cleanup cancelled")
                return 0

        total_cleaned = 0

        # Clean in dependency order
        self.logger.info("Starting complete data cleanup...")

        total_cleaned += self.cleanup_installations()
        total_cleaned += self.cleanup_sales_orders()
        total_cleaned += self.cleanup_customers()
        total_cleaned += self.cleanup_demo_products()
        total_cleaned += self.cleanup_demo_users()

        # Commit all changes
        self.env.cr.commit()

        self.logger.info(f"Cleanup completed: {total_cleaned} records removed")
        return total_cleaned


def main():
    parser = argparse.ArgumentParser(description='Clean up sample data from database')
    parser.add_argument('--database', required=True, help='Target database name')
    parser.add_argument('--config', required=True, help='Odoo configuration file path')
    parser.add_argument('--log-file', help='Log file path')
    parser.add_argument('--force', action='store_true', help='Skip confirmation prompts')
    parser.add_argument('--model', help='Clean specific model only')

    args = parser.parse_args()

    cleanup = DataCleanup(args.database, args.config)

    if args.model:
        # Clean specific model
        method_name = f"cleanup_{args.model.replace('.', '_')}"
        if hasattr(cleanup, method_name):
            count = getattr(cleanup, method_name)()
            cleanup.env.cr.commit()
            print(f"Cleaned {count} {args.model} records")
        else:
            print(f"No cleanup method for model: {args.model}")
            exit(1)
    else:
        # Clean all data
        count = cleanup.cleanup_all(args.force)
        print(f"Cleanup completed: {count} total records removed")

    exit(0)


if __name__ == '__main__':
    main()
EOF

# Create validator script
cat > "$DATA_SCRIPTS_PATH/data_validator.py" << 'EOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Data Validator for RTP Denver Sample Data System

Validates sample data integrity and relationships.
Checks for data consistency and business rules.

Author: RTP Denver Development Team
License: Private
"""

import argparse
from base_generator import BaseDataGenerator

DESCRIPTION = "Validates sample data integrity and relationships"

class DataValidator(BaseDataGenerator):
    """
    Data validator for sample data

    Validates:
    - Record counts and relationships
    - Data integrity and constraints
    - Business rule compliance
    """

    def __init__(self, database, config_file):
        super().__init__(database, config_file, 'validation')
        self.validation_results = {}
        self.total_errors = 0
        self.total_warnings = 0

    def validate_customers(self):
        """Validate RTP customer data"""
        self.logger.info("Validating customer data...")

        customers = self.env['rtp.customer'].search([])
        errors = []
        warnings = []

        for customer in customers:
            # Check required fields
            if not customer.name:
                errors.append(f"Customer {customer.id}: Missing name")

            if not customer.user_id:
                errors.append(f"Customer {customer.id}: Missing assigned user")

            # Check email format
            if customer.email and '@' not in customer.email:
                errors.append(f"Customer {customer.id}: Invalid email format")

            # Check status workflow
            if customer.status == 'active' and not customer.last_contact_date:
                warnings.append(f"Customer {customer.id}: Active customer with no contact date")

            # Check priority logic
            if customer.priority == '3' and customer.status != 'active':
                warnings.append(f"Customer {customer.id}: VIP customer not active")

        self.validation_results['customers'] = {
            'count': len(customers),
            'errors': errors,
            'warnings': warnings
        }

        self.total_errors += len(errors)
        self.total_warnings += len(warnings)

        self.logger.info(f"Customer validation: {len(customers)} records, {len(errors)} errors, {len(warnings)} warnings")

    def validate_sales_orders(self):
        """Validate sales order data"""
        self.logger.info("Validating sales order data...")

        orders = self.env['sale.order'].search([])
        order_lines = self.env['sale.order.line'].search([])

        errors = []
        warnings = []

        for order in orders:
            # Check required fields
            if not order.partner_id:
                errors.append(f"Sales Order {order.name}: Missing customer")

            if not order.user_id:
                errors.append(f"Sales Order {order.name}: Missing salesperson")

            # Check order lines
            lines = order.order_line
            if not lines:
                warnings.append(f"Sales Order {order.name}: No order lines")

            # Check amounts
            if order.amount_total <= 0:
                errors.append(f"Sales Order {order.name}: Invalid total amount")

            # Check state consistency
            if order.state == 'done' and not lines:
                errors.append(f"Sales Order {order.name}: Completed order with no lines")

        # Check orphaned order lines
        for line in order_lines:
            if not line.order_id:
                errors.append(f"Order Line {line.id}: Missing parent order")

            if not line.product_id:
                errors.append(f"Order Line {line.id}: Missing product")

            if line.product_uom_qty <= 0:
                errors.append(f"Order Line {line.id}: Invalid quantity")

        self.validation_results['sales_orders'] = {
            'count': len(orders),
            'lines_count': len(order_lines),
            'errors': errors,
            'warnings': warnings
        }

        self.total_errors += len(errors)
        self.total_warnings += len(warnings)

        self.logger.info(f"Sales order validation: {len(orders)} orders, {len(order_lines)} lines, {len(errors)} errors, {len(warnings)} warnings")

    def validate_installations(self):
        """Validate installation data"""
        self.logger.info("Validating installation data...")

        installations = self.env['royal.installation'].search([])
        errors = []
        warnings = []

        for installation in installations:
            # Check required fields
            if not installation.name:
                errors.append(f"Installation {installation.id}: Missing name")

            if not installation.sale_order_id:
                errors.append(f"Installation {installation.id}: Missing sales order")

            if not installation.customer_id:
                errors.append(f"Installation {installation.id}: Missing customer")

            if not installation.installer_id:
                errors.append(f"Installation {installation.id}: Missing installer")

            # Check date consistency
            if installation.actual_start_date and installation.completion_date:
                if installation.actual_start_date > installation.completion_date:
                    errors.append(f"Installation {installation.id}: Start date after completion date")

            # Check status consistency
            if installation.status == 'completed' and not installation.completion_date:
                errors.append(f"Installation {installation.id}: Completed status without completion date")

            if installation.status == 'in_progress' and not installation.actual_start_date:
                warnings.append(f"Installation {installation.id}: In progress without start date")

            # Check customer consistency
            if installation.sale_order_id and installation.customer_id:
                if installation.sale_order_id.partner_id.id != installation.customer_id.id:
                    errors.append(f"Installation {installation.id}: Customer mismatch with sales order")

        self.validation_results['installations'] = {
            'count': len(installations),
            'errors': errors,
            'warnings': warnings
        }

        self.total_errors += len(errors)
        self.total_warnings += len(warnings)

        self.logger.info(f"Installation validation: {len(installations)} records, {len(errors)} errors, {len(warnings)} warnings")

    def validate_relationships(self):
        """Validate cross-model relationships"""
        self.logger.info("Validating cross-model relationships...")

        errors = []
        warnings = []

        # Check installations have corresponding sales orders
        installations = self.env['royal.installation'].search([])
        for installation in installations:
            if installation.sale_order_id:
                order = installation.sale_order_id
                if order.state not in ['sale', 'done']:
                    warnings.append(f"Installation {installation.id}: Related order not confirmed")

        # Check for sales orders without installations (might be normal)
        confirmed_orders = self.env['sale.order'].search([('state', 'in', ['sale', 'done'])])
        orders_with_installations = installations.mapped('sale_order_id')
        orders_without_installations = confirmed_orders - orders_with_installations

        if len(orders_without_installations) > len(confirmed_orders) * 0.7:  # More than 70% without installations
            warnings.append(f"Many confirmed orders ({len(orders_without_installations)}) without installations")

        self.validation_results['relationships'] = {
            'errors': errors,
            'warnings': warnings
        }

        self.total_errors += len(errors)
        self.total_warnings += len(warnings)

        self.logger.info(f"Relationship validation: {len(errors)} errors, {len(warnings)} warnings")

    def validate_all(self):
        """Run all validations"""
        self.logger.info("Starting comprehensive data validation...")

        self.validate_customers()
        self.validate_sales_orders()
        self.validate_installations()
        self.validate_relationships()

        # Generate summary
        self.generate_validation_report()

        return self.total_errors == 0

    def generate_validation_report(self):
        """Generate validation report"""
        self.logger.info("Generating validation report...")

        print("\n" + "="*60)
        print("DATA VALIDATION REPORT")
        print("="*60)

        for model, results in self.validation_results.items():
            print(f"\n{model.upper()}:")
            print(f"  Records: {results.get('count', 'N/A')}")

            if 'lines_count' in results:
                print(f"  Order Lines: {results['lines_count']}")

            if results['errors']:
                print(f"  Errors ({len(results['errors'])}):")
                for error in results['errors']:
                    print(f"    - {error}")

            if results['warnings']:
                print(f"  Warnings ({len(results['warnings'])}):")
                for warning in results['warnings']:
                    print(f"    - {warning}")

            if not results['errors'] and not results['warnings']:
                print("  ✅ All validations passed")

        print(f"\n{'='*60}")
        print(f"SUMMARY: {self.total_errors} errors, {self.total_warnings} warnings")

        if self.total_errors == 0:
            print("✅ VALIDATION PASSED")
        else:
            print("❌ VALIDATION FAILED")

        print("="*60)


def main():
    parser = argparse.ArgumentParser(description='Validate sample data integrity')
    parser.add_argument('--database', required=True, help='Target database name')
    parser.add_argument('--config', required=True, help='Odoo configuration file path')
    parser.add_argument('--log-file', help='Log file path')
    parser.add_argument('--model', help='Validate specific model only')

    args = parser.parse_args()

    validator = DataValidator(args.database, args.config)

    if args.model:
        # Validate specific model
        method_name = f"validate_{args.model.replace('.', '_')}"
        if hasattr(validator, method_name):
            getattr(validator, method_name)()
            validator.generate_validation_report()
        else:
            print(f"No validation method for model: {args.model}")
            exit(1)
    else:
        # Validate all data
        success = validator.validate_all()

    exit(0 if validator.total_errors == 0 else 1)


if __name__ == '__main__':
    main()
EOF

# Make all scripts executable
chmod +x "$DATA_SCRIPTS_PATH"/*.py

echo "All data generator scripts created successfully!"
echo "Location: $DATA_SCRIPTS_PATH"
echo ""
echo "Available generators:"
ls -la "$DATA_SCRIPTS_PATH"/*.py

# rtp_customers API Documentation

**Generated:** 2025-07-11 23:33:22
**Version:** 18.0.1.0.0
**Author:** RTP Denver Development Team

## Overview

Customer management system for RTP Denver project

### Module Information

- **Name:** rtp_customers
- **Version:** 18.0.1.0.0
- **Category:** Sales/CRM
- **Depends:** base, web, contacts
- **License:** LGPL-3
- **Website:** https://github.com/matthewbergvinson/rtp-denver

### Statistics

- **Models:** 0
- **Methods:** 15
- **Controllers:** 0
- **Views:** 0
- **Tests:** 0

---

## Methods (15)

The following methods are defined in the rtp_customers module:

### RTPCustomer Methods

#### `_compute_days_since_signup(self)`

**File:** `/Users/mbergvinson/cursor-projects/odoo/rtp-denver/custom_modules/rtp_customers/models/customer.py`
**Line:** 141

**Decorators:** <ast.Call object at 0x1011b6650>

**Description:**
Compute days since customer signup
Same pattern as todo _compute_days_until_due

#### `_compute_is_recent_customer(self)`

**File:** `/Users/mbergvinson/cursor-projects/odoo/rtp-denver/custom_modules/rtp_customers/models/customer.py`
**Line:** 155

**Decorators:** <ast.Call object at 0x1011b4e50>

**Description:**
Compute if customer is recent (within 30 days)
Same pattern as todo _compute_is_overdue

#### `_compute_contact_overdue(self)`

**File:** `/Users/mbergvinson/cursor-projects/odoo/rtp-denver/custom_modules/rtp_customers/models/customer.py`
**Line:** 165

**Decorators:** <ast.Call object at 0x1011ab3d0>

**Description:**
Compute if contact is overdue
Same pattern as todo overdue logic

#### `_onchange_priority(self)`

**File:** `/Users/mbergvinson/cursor-projects/odoo/rtp-denver/custom_modules/rtp_customers/models/customer.py`
**Line:** 179

**Decorators:** <ast.Call object at 0x1012b3110>

**Description:**
Update contact scheduling based on priority
Same pattern as todo _onchange_priority

#### `_onchange_status(self)`

**File:** `/Users/mbergvinson/cursor-projects/odoo/rtp-denver/custom_modules/rtp_customers/models/customer.py`
**Line:** 197

**Decorators:** <ast.Call object at 0x1012b1e90>

**Description:**
Handle status changes
Same pattern as todo _onchange_status

#### `action_activate_customer(self)`

**File:** `/Users/mbergvinson/cursor-projects/odoo/rtp-denver/custom_modules/rtp_customers/models/customer.py`
**Line:** 212

**Description:**
Activate customer account
Same pattern as todo action_start_task

#### `action_block_customer(self)`

**File:** `/Users/mbergvinson/cursor-projects/odoo/rtp-denver/custom_modules/rtp_customers/models/customer.py`
**Line:** 225

**Description:**
Block customer account
Same pattern as todo action_cancel_task

#### `action_update_contact(self)`

**File:** `/Users/mbergvinson/cursor-projects/odoo/rtp-denver/custom_modules/rtp_customers/models/customer.py`
**Line:** 237

**Description:**
Update last contact date
Same pattern as todo business actions

#### `_check_email_format(self)`

**File:** `/Users/mbergvinson/cursor-projects/odoo/rtp-denver/custom_modules/rtp_customers/models/customer.py`
**Line:** 249

**Decorators:** <ast.Call object at 0x1012c79d0>

**Description:**
Validate email format
Same pattern as todo _check_due_date

#### `_check_customer_name(self)`

**File:** `/Users/mbergvinson/cursor-projects/odoo/rtp-denver/custom_modules/rtp_customers/models/customer.py`
**Line:** 262

**Decorators:** <ast.Call object at 0x1012d0f50>

**Description:**
Validate customer name
Same pattern as todo _check_task_name

#### `_check_phone_format(self)`

**File:** `/Users/mbergvinson/cursor-projects/odoo/rtp-denver/custom_modules/rtp_customers/models/customer.py`
**Line:** 274

**Decorators:** <ast.Call object at 0x1012d2650>

**Description:**
Validate phone number format
New business validation example

#### `create(self, vals)`

**File:** `/Users/mbergvinson/cursor-projects/odoo/rtp-denver/custom_modules/rtp_customers/models/customer.py`
**Line:** 289

**Decorators:** <ast.Attribute object at 0x1012d8ad0>

**Description:**
Override create method for custom logic
Same pattern as todo create override

#### `write(self, vals)`

**File:** `/Users/mbergvinson/cursor-projects/odoo/rtp-denver/custom_modules/rtp_customers/models/customer.py`
**Line:** 306

**Description:**
Override write method for status change logic
Same pattern as todo write override

#### `unlink(self)`

**File:** `/Users/mbergvinson/cursor-projects/odoo/rtp-denver/custom_modules/rtp_customers/models/customer.py`
**Line:** 329

**Description:**
Override unlink method for deletion validation
Same pattern as todo unlink override

#### `name_get(self)`

**File:** `/Users/mbergvinson/cursor-projects/odoo/rtp-denver/custom_modules/rtp_customers/models/customer.py`
**Line:** 343

**Description:**
Override name display for better UX
Same pattern as todo name_get

---

## File Structure

### Python Files (4)
- `__init__.py`
- `__manifest__.py`
- `models/__init__.py`
- `models/customer.py`

### XML Files (0)

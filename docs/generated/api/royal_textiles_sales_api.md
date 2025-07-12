# royal_textiles_sales API Documentation

**Generated:** 2025-07-11 23:33:22
**Version:** 18.0.1.0.1
**Author:** RTP Denver Development Team

## Overview

Custom sales order enhancements for Royal Textiles installation company

### Module Information

- **Name:** royal_textiles_sales
- **Version:** 18.0.1.0.1
- **Category:** Sales
- **Depends:** base, web, sale, project, calendar
- **License:** LGPL-3
- **Website:** https://github.com/matthewbergvinson/rtp-denver

### Statistics

- **Models:** 0
- **Methods:** 16
- **Controllers:** 0
- **Views:** 8
- **Tests:** 0

---

## Methods (16)

The following methods are defined in the royal_textiles_sales module:

### SaleOrder Methods

#### `_compute_estimated_hours(self)`

**File:** `/Users/mbergvinson/cursor-projects/odoo/rtp-denver/custom_modules/royal_textiles_sales/models/sale_order.py`
**Line:** 69

**Decorators:** <ast.Call object at 0x102f6d950>

**Description:**
Compute estimated installation hours based on products ordered
Business logic specific to blinds and shades installation

#### `action_schedule_installation(self)`

**File:** `/Users/mbergvinson/cursor-projects/odoo/rtp-denver/custom_modules/royal_textiles_sales/models/sale_order.py`
**Line:** 105

**Description:**
Schedule Installation Button Action

Creates an installation record and opens a form to schedule the appointment.
Only available for confirmed sales orders.

#### `action_generate_work_order(self)`

**File:** `/Users/mbergvinson/cursor-projects/odoo/rtp-denver/custom_modules/royal_textiles_sales/models/sale_order.py`
**Line:** 185

**Description:**
Generate Work Order Button Action

Creates a project with tasks for the installation work.
Integrates with Odoo's project management module.

#### `action_calculate_materials(self)`

**File:** `/Users/mbergvinson/cursor-projects/odoo/rtp-denver/custom_modules/royal_textiles_sales/models/sale_order.py`
**Line:** 263

**Description:**
Calculate Materials Button Action

Analyzes the order lines and calculates additional materials needed
for the installation (screws, brackets, etc.)

---

### RoyalInstallation Methods

#### `_compute_duration(self)`

**File:** `/Users/mbergvinson/cursor-projects/odoo/rtp-denver/custom_modules/royal_textiles_sales/models/installation.py`
**Line:** 161

**Decorators:** <ast.Call object at 0x102f63cd0>

**Description:**
Compute actual duration of installation
Same pattern as Hello World Todo computed fields

#### `_compute_is_overdue(self)`

**File:** `/Users/mbergvinson/cursor-projects/odoo/rtp-denver/custom_modules/royal_textiles_sales/models/installation.py`
**Line:** 174

**Decorators:** <ast.Call object at 0x102f6c150>

**Description:**
Compute if installation is overdue
Same pattern as Hello World Todo overdue logic

#### `_compute_efficiency_rating(self)`

**File:** `/Users/mbergvinson/cursor-projects/odoo/rtp-denver/custom_modules/royal_textiles_sales/models/installation.py`
**Line:** 188

**Decorators:** <ast.Call object at 0x102fadcd0>

**Description:**
Compute efficiency rating based on actual vs estimated time
Same pattern as Hello World Todo computed fields

#### `action_start_installation(self)`

**File:** `/Users/mbergvinson/cursor-projects/odoo/rtp-denver/custom_modules/royal_textiles_sales/models/installation.py`
**Line:** 213

**Description:**
Start the installation process
Same pattern as Hello World Todo action_start_task

#### `action_complete_installation(self)`

**File:** `/Users/mbergvinson/cursor-projects/odoo/rtp-denver/custom_modules/royal_textiles_sales/models/installation.py`
**Line:** 238

**Description:**
Complete the installation
Same pattern as Hello World Todo action_complete_task

#### `action_cancel_installation(self)`

**File:** `/Users/mbergvinson/cursor-projects/odoo/rtp-denver/custom_modules/royal_textiles_sales/models/installation.py`
**Line:** 263

**Description:**
Cancel the installation
Same pattern as Hello World Todo action_cancel_task

#### `action_reschedule_installation(self)`

**File:** `/Users/mbergvinson/cursor-projects/odoo/rtp-denver/custom_modules/royal_textiles_sales/models/installation.py`
**Line:** 287

**Description:**
Reschedule the installation
Custom business action

#### `_check_scheduled_date(self)`

**File:** `/Users/mbergvinson/cursor-projects/odoo/rtp-denver/custom_modules/royal_textiles_sales/models/installation.py`
**Line:** 310

**Decorators:** <ast.Call object at 0x102f98550>

**Description:**
Validate scheduled date is not in the past
Same pattern as Hello World Todo validation

#### `_check_date_sequence(self)`

**File:** `/Users/mbergvinson/cursor-projects/odoo/rtp-denver/custom_modules/royal_textiles_sales/models/installation.py`
**Line:** 327

**Decorators:** <ast.Call object at 0x102fa31d0>

**Description:**
Validate date sequence is logical
Same pattern as Hello World Todo validation

#### `create(self, vals)`

**File:** `/Users/mbergvinson/cursor-projects/odoo/rtp-denver/custom_modules/royal_textiles_sales/models/installation.py`
**Line:** 340

**Decorators:** <ast.Attribute object at 0x102fa1190>

**Description:**
Override create method for custom logic
Same pattern as Hello World Todo create override

#### `write(self, vals)`

**File:** `/Users/mbergvinson/cursor-projects/odoo/rtp-denver/custom_modules/royal_textiles_sales/models/installation.py`
**Line:** 353

**Description:**
Override write method for status change logic
Same pattern as Hello World Todo write override

#### `name_get(self)`

**File:** `/Users/mbergvinson/cursor-projects/odoo/rtp-denver/custom_modules/royal_textiles_sales/models/installation.py`
**Line:** 382

**Description:**
Override name display for better UX
Same pattern as Hello World Todo name_get

---

## Views (8)

The following views are defined in the royal_textiles_sales module:

### Form Views (1)

| View ID | Model | File |
|---------|-------|------|
| `view_royal_installation_form` | `ir.ui.view` | `/Users/mbergvinson/cursor-projects/odoo/rtp-denver/custom_modules/royal_textiles_sales/views/installation_views.xml` |

### Tree Views (1)

| View ID | Model | File |
|---------|-------|------|
| `view_royal_installation_tree` | `ir.ui.view` | `/Users/mbergvinson/cursor-projects/odoo/rtp-denver/custom_modules/royal_textiles_sales/views/installation_views.xml` |

### Search Views (1)

| View ID | Model | File |
|---------|-------|------|
| `view_royal_installation_search` | `ir.ui.view` | `/Users/mbergvinson/cursor-projects/odoo/rtp-denver/custom_modules/royal_textiles_sales/views/installation_views.xml` |

### Calendar Views (1)

| View ID | Model | File |
|---------|-------|------|
| `view_royal_installation_calendar` | `ir.ui.view` | `/Users/mbergvinson/cursor-projects/odoo/rtp-denver/custom_modules/royal_textiles_sales/views/installation_views.xml` |

### Kanban Views (1)

| View ID | Model | File |
|---------|-------|------|
| `view_royal_installation_kanban` | `ir.ui.view` | `/Users/mbergvinson/cursor-projects/odoo/rtp-denver/custom_modules/royal_textiles_sales/views/installation_views.xml` |

### Xpath Views (3)

| View ID | Model | File |
|---------|-------|------|
| `view_order_form_royal_textiles` | `ir.ui.view` | `/Users/mbergvinson/cursor-projects/odoo/rtp-denver/custom_modules/royal_textiles_sales/views/sale_order_views.xml` |
| `view_order_tree_royal_textiles` | `ir.ui.view` | `/Users/mbergvinson/cursor-projects/odoo/rtp-denver/custom_modules/royal_textiles_sales/views/sale_order_views.xml` |
| `view_sales_order_filter_royal_textiles` | `ir.ui.view` | `/Users/mbergvinson/cursor-projects/odoo/rtp-denver/custom_modules/royal_textiles_sales/views/sale_order_views.xml` |

## File Structure

### Python Files (5)
- `__init__.py`
- `__manifest__.py`
- `models/sale_order.py`
- `models/installation.py`
- `models/__init__.py`

### XML Files (4)
- `data/installation_demo.xml`
- `views/installation_views.xml`
- `views/sale_order_views.xml`
- `views/installation_menu.xml`

### CSV Files (1)
- `security/ir.model.access.csv`

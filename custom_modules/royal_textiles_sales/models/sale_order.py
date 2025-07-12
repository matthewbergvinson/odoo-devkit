# -*- coding: utf-8 -*-
"""
Sales Order Extensions for Royal Textiles

This extends the sales order model to add custom business logic
for Royal Textiles' blinds and shades installation business.

Author: Matthew Bergvinson
Company: Royal Textiles
"""

import logging
from datetime import date, timedelta

from odoo import _, api, fields, models
from odoo.exceptions import UserError, ValidationError

_logger = logging.getLogger(__name__)


class SaleOrder(models.Model):
    """
    Extended Sales Order Model for Royal Textiles

    Adds custom buttons and business logic for installation scheduling,
    work order generation, and material calculation.
    """

    # Model Configuration - Use _inherit to extend existing model
    _inherit = "sale.order"  # Fix: Changed from _name to _inherit

    # === CUSTOM FIELDS FOR ROYAL TEXTILES ===

    installation_status = fields.Selection(
        [
            ("not_scheduled", "Not Scheduled"),
            ("scheduled", "Installation Scheduled"),
            ("in_progress", "Installation in Progress"),
            ("completed", "Installation Completed"),
            ("cancelled", "Installation Cancelled"),
        ],
        string="Installation Status",
        default="not_scheduled",
        tracking=True,
        help="Status of the installation process for this order",
    )

    installation_id = fields.Many2one(
        "royal.installation",
        string="Installation Record",
        help="Link to the installation appointment record",
    )

    estimated_installation_hours = fields.Float(
        string="Estimated Installation Hours",
        compute="_compute_estimated_hours",
        store=True,  # Added store=True to fix warning
        help="Estimated hours needed for installation based on order lines",
    )

    installation_notes = fields.Text(
        string="Installation Notes",
        help="Special notes and instructions for the installation team",
    )

    # Additional fields for view integration
    installation_scheduled = fields.Boolean(
        string="Installation Scheduled",
        compute="_compute_installation_scheduled",
        help="Whether installation has been scheduled for this order",
    )

    installation_date = fields.Datetime(
        string="Installation Date",
        related="installation_id.scheduled_date",
        help="Scheduled date for installation",
    )

    materials_calculated = fields.Boolean(
        string="Materials Calculated",
        default=False,
        help="Whether materials calculation has been performed",
    )

    work_order_id = fields.Many2one(
        "project.project",
        string="Work Order Project",
        help="Link to the work order project",
    )

    # === COMPUTED FIELDS ===

    @api.depends("installation_id")
    def _compute_installation_scheduled(self):
        """Compute whether installation has been scheduled"""
        for order in self:
            order.installation_scheduled = bool(order.installation_id)

    @api.depends("order_line.product_uom_qty", "order_line.product_id")
    def _compute_estimated_hours(self):
        """
        Compute estimated installation hours based on products ordered
        Business logic specific to blinds and shades installation
        """
        for order in self:
            total_hours = 0.0

            for line in order.order_line:
                # Base calculation: 30 minutes per unit for most products
                base_time = line.product_uom_qty * 0.5

                # Adjustment factors based on product type (in real scenario,
                # you'd have product categories or attributes)
                product_name = line.product_id.name.lower() if line.product_id.name else ""

                if "blind" in product_name:
                    # Blinds take longer to install
                    multiplier = 1.2
                elif "shade" in product_name:
                    # Shades are quicker
                    multiplier = 0.8
                elif "motorized" in product_name:
                    # Motorized products take much longer
                    multiplier = 2.0
                else:
                    # Default for other products/services
                    multiplier = 1.0

                total_hours += base_time * multiplier

            # Minimum 2 hours for any installation
            order.estimated_installation_hours = max(total_hours, 2.0)

    # === BUSINESS LOGIC METHODS ===

    def action_schedule_installation(self):
        """
        Schedule Installation Button Action

        Creates an installation record and opens a form to schedule the appointment.
        Only available for confirmed sales orders.
        """
        for order in self:
            # Validation: Order must be confirmed
            if order.state not in ["sale", "done"]:
                raise UserError(
                    _(
                        "Installation can only be scheduled for confirmed sales orders. "
                        "Please confirm this order first."
                    )
                )

            # Check if installation already exists
            if order.installation_id:
                # Open existing installation
                return {
                    "type": "ir.actions.act_window",
                    "name": "Installation Appointment",
                    "res_model": "royal.installation",
                    "res_id": order.installation_id.id,
                    "view_mode": "form",
                    "target": "new",
                }

            # Create new installation record
            installation_vals = {
                "name": f"Installation for {order.name}",
                "sale_order_id": order.id,
                "customer_id": order.partner_id.id,
                "estimated_hours": order.estimated_installation_hours,
                "installation_notes": order.installation_notes or "",
                "scheduled_date": fields.Datetime.now() + timedelta(days=7),  # Default 1 week out
                "status": "scheduled",
            }

            installation = self.env["royal.installation"].create(installation_vals)

            # Update sales order
            order.write(
                {
                    "installation_id": installation.id,
                    "installation_status": "scheduled",
                }
            )

            # Create calendar event for the installation
            calendar_vals = {
                "name": f"Installation: {order.partner_id.name} - {order.name}",
                "description": f"""
Installation Details:
- Customer: {order.partner_id.name}
- Sales Order: {order.name}
- Estimated Hours: {order.estimated_installation_hours}
- Products: {', '.join(order.order_line.mapped('product_id.name'))}
- Notes: {order.installation_notes or 'None'}
                """,
                "start": installation.scheduled_date,
                "stop": installation.scheduled_date + timedelta(hours=installation.estimated_hours),
                "user_id": self.env.user.id,
            }

            calendar_event = self.env["calendar.event"].create(calendar_vals)

            _logger.info(f"Installation scheduled for order {order.name}: {installation.name}")

            # Return action to open the installation form
            return {
                "type": "ir.actions.act_window",
                "name": "Installation Scheduled",
                "res_model": "royal.installation",
                "res_id": installation.id,
                "view_mode": "form",
                "target": "new",
            }

    def action_generate_work_order(self):
        """
        Generate Work Order Button Action

        Creates a project with tasks for the installation work.
        Integrates with Odoo's project management module.
        """
        for order in self:
            # Validation: Order must be confirmed
            if order.state not in ["sale", "done"]:
                raise UserError(_("Work orders can only be generated for confirmed sales orders."))

            # Create project for this installation
            project_vals = {
                "name": f"Installation Project - {order.name}",
                "partner_id": order.partner_id.id,
                "user_id": self.env.user.id,
                "description": f"""
Installation project for sales order {order.name}

Customer: {order.partner_id.name}
Estimated Hours: {order.estimated_installation_hours}
Installation Status: {order.installation_status}

Products to Install:
{chr(10).join([f"- {line.product_id.name} (Qty: {line.product_uom_qty})" for line in order.order_line])}
                """,
            }

            project = self.env["project.project"].create(project_vals)

            # Update sales order with work order reference
            order.work_order_id = project.id

            # Create tasks for different installation phases
            task_templates = [
                {
                    "name": "Site Survey and Preparation",
                    "description": "Survey installation site and prepare materials",
                    "planned_hours": 1.0,
                    "sequence": 1,
                },
                {
                    "name": "Install Products",
                    "description": f"Install {len(order.order_line)} products for {order.partner_id.name}",
                    "planned_hours": max(order.estimated_installation_hours - 1.0, 1.0),
                    "sequence": 2,
                },
                {
                    "name": "Quality Check and Customer Walkthrough",
                    "description": "Verify installation quality and walk through with customer",
                    "planned_hours": 0.5,
                    "sequence": 3,
                },
            ]

            for template in task_templates:
                task_vals = {
                    "name": template["name"],
                    "description": template["description"],
                    "project_id": project.id,
                    "user_ids": [(6, 0, [self.env.user.id])],
                    "planned_hours": template["planned_hours"],
                    "sequence": template["sequence"],
                    "partner_id": order.partner_id.id,
                }

                self.env["project.task"].create(task_vals)

            _logger.info(f"Work order project created for {order.name}: {project.name}")

            # Return action to open the project
            return {
                "type": "ir.actions.act_window",
                "name": "Installation Work Order",
                "res_model": "project.project",
                "res_id": project.id,
                "view_mode": "form",
                "target": "current",
            }

    def action_calculate_materials(self):
        """
        Calculate Materials Button Action

        Analyzes the order lines and calculates additional materials needed
        for the installation (screws, brackets, etc.)
        """
        for order in self:
            # Validation
            if not order.order_line:
                raise UserError(_("No products found to calculate materials for."))

            materials_calculation = []
            total_weight = 0.0

            for line in order.order_line:
                product_name = line.product_id.name.lower() if line.product_id.name else ""
                qty = line.product_uom_qty

                # Calculate materials based on product type
                if "blind" in product_name:
                    materials_calculation.append(f"• Blinds x{qty}: {qty * 2} brackets, {qty * 4} screws")
                    total_weight += qty * 3.5  # Average 3.5 lbs per blind
                elif "shade" in product_name:
                    materials_calculation.append(f"• Shades x{qty}: {qty * 2} brackets, {qty * 2} screws")
                    total_weight += qty * 2.0  # Average 2 lbs per shade
                elif "motorized" in product_name:
                    materials_calculation.append(
                        f"• Motorized x{qty}: {qty * 3} brackets, {qty * 6} screws, electrical"
                    )
                    total_weight += qty * 5.0  # Heavier for motorized
                else:
                    materials_calculation.append(f"• {line.product_id.name} x{qty}: Standard hardware")
                    total_weight += qty * 2.5  # Default weight

            # Create the materials summary
            materials_summary = f"""
MATERIALS CALCULATION FOR {order.name}
{'='*50}

Customer: {order.partner_id.name}
Order Date: {order.date_order.strftime('%Y-%m-%d')}
Estimated Installation: {order.estimated_installation_hours} hours

MATERIALS NEEDED:
{chr(10).join(materials_calculation)}

SUMMARY:
• Total Estimated Weight: {total_weight:.1f} lbs
• Installation Complexity: {'High' if order.estimated_installation_hours > 6 else 'Medium' if order.estimated_installation_hours > 3 else 'Low'}
• Recommended Team Size: {2 if order.estimated_installation_hours > 4 else 1} installer(s)

ADDITIONAL ITEMS TO BRING:
• Drill and bits
• Level
• Measuring tape
• Safety equipment
• Touch-up paint
• Cleaning supplies
            """

            # Update installation notes with materials calculation and mark as calculated
            order.write(
                {
                    "installation_notes": materials_summary,
                    "materials_calculated": True,
                }
            )

            # Update installation record if it exists
            if order.installation_id:
                order.installation_id.write(
                    {
                        "materials_notes": materials_summary,
                        "estimated_weight": total_weight,
                    }
                )

            _logger.info(f"Materials calculated for order {order.name}: {total_weight:.1f} lbs")

            # Show message to user
            return {
                "type": "ir.actions.client",
                "tag": "display_notification",
                "params": {
                    "title": "Materials Calculated",
                    "message": f"Materials calculation complete. Total weight: {total_weight:.1f} lbs. See installation notes for details.",
                    "type": "success",
                    "sticky": False,
                },
            }

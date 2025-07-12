# -*- coding: utf-8 -*-
"""
Installation Model for Royal Textiles

This model manages installation records for Royal Textiles' blinds and shades
installation business. Uses the same patterns as Hello World Todo model.

Author: Matthew Bergvinson
Company: Royal Textiles
"""

import logging
from datetime import date, timedelta

from odoo import _, api, fields, models
from odoo.exceptions import UserError, ValidationError

_logger = logging.getLogger(__name__)


class RoyalInstallation(models.Model):
    """
    Installation Record Model

    Tracks installation appointments and progress for Royal Textiles.
    Uses Hello World Todo patterns for consistency.
    """

    # Model Configuration (same pattern as todo.task)
    _name = "royal.installation"
    _description = "Royal Textiles Installation"
    _inherit = ["mail.thread", "mail.activity.mixin"]
    _order = "scheduled_date desc, create_date desc"
    _rec_name = "name"

    # === BASIC FIELDS === (Same pattern as Hello World Todo)

    name = fields.Char(
        string="Installation Name",
        required=True,
        help="Name of the installation appointment",
    )

    description = fields.Text(
        string="Installation Notes",
        help="Additional notes and instructions for the installation",
    )

    # === RELATIONSHIP FIELDS === (Same pattern as Hello World Todo)

    sale_order_id = fields.Many2one(
        "sale.order",
        string="Sales Order",
        required=True,
        help="Related sales order for this installation",
    )

    customer_id = fields.Many2one(
        "res.partner",
        string="Customer",
        required=True,
        help="Customer for this installation",
    )

    installer_id = fields.Many2one(
        "res.users",
        string="Installer",
        default=lambda self: self.env.user,
        help="User assigned to perform the installation",
    )

    # === STATUS AND WORKFLOW === (Same pattern as Hello World Todo status)

    status = fields.Selection(
        [
            ("draft", "Draft"),
            ("scheduled", "Scheduled"),
            ("in_progress", "In Progress"),
            ("completed", "Completed"),
            ("cancelled", "Cancelled"),
        ],
        string="Status",
        default="draft",
        required=True,
        tracking=True,
        help="Current status of the installation",
    )

    # === DATE FIELDS === (Same pattern as Hello World Todo dates)

    scheduled_date = fields.Datetime(
        string="Scheduled Date",
        required=True,
        help="Date and time when installation is scheduled",
    )

    actual_start_date = fields.Datetime(
        string="Actual Start Date",
        help="Date and time when installation actually started",
    )

    completion_date = fields.Datetime(string="Completion Date", help="Date and time when installation was completed")

    # === NUMERIC FIELDS === (Same pattern as Hello World Todo)

    estimated_hours = fields.Float(
        string="Estimated Hours",
        default=4.0,
        help="Estimated hours needed for installation",
    )

    actual_hours = fields.Float(string="Actual Hours", help="Actual hours spent on installation")

    estimated_weight = fields.Float(
        string="Estimated Weight (lbs)",
        help="Estimated weight of materials to be installed",
    )

    # === TEXT FIELDS === (Business specific)

    materials_notes = fields.Text(string="Materials List", help="List of materials needed for this installation")

    installation_address = fields.Text(string="Installation Address", help="Address where installation will take place")

    special_instructions = fields.Text(
        string="Special Instructions",
        help="Special instructions for the installation team",
    )

    # === COMPUTED FIELDS === (Same pattern as Hello World Todo)

    duration_actual = fields.Float(
        string="Duration (Hours)",
        compute="_compute_duration",
        store=True,
        help="Actual duration of installation in hours",
    )

    is_overdue = fields.Boolean(
        string="Overdue",
        compute="_compute_is_overdue",
        store=True,
        help="True if installation is past scheduled date",
    )

    efficiency_rating = fields.Selection(
        [
            ("excellent", "Excellent (≤ estimated time)"),
            ("good", "Good (≤ 110% of estimated)"),
            ("fair", "Fair (≤ 125% of estimated)"),
            ("poor", "Poor (> 125% of estimated)"),
        ],
        string="Efficiency Rating",
        compute="_compute_efficiency_rating",
        store=True,
        help="Efficiency rating based on actual vs estimated time",
    )

    # === COMPUTED FIELD METHODS === (Same pattern as Hello World Todo)

    @api.depends("actual_start_date", "completion_date")
    def _compute_duration(self):
        """
        Compute actual duration of installation
        Same pattern as Hello World Todo computed fields
        """
        for installation in self:
            if installation.actual_start_date and installation.completion_date:
                delta = installation.completion_date - installation.actual_start_date
                installation.duration_actual = delta.total_seconds() / 3600.0  # Convert to hours
            else:
                installation.duration_actual = 0.0

    @api.depends("scheduled_date", "status")
    def _compute_is_overdue(self):
        """
        Compute if installation is overdue
        Same pattern as Hello World Todo overdue logic
        """
        now = fields.Datetime.now()
        for installation in self:
            installation.is_overdue = (
                installation.scheduled_date
                and installation.scheduled_date < now
                and installation.status not in ["completed", "cancelled"]
            )

    @api.depends("estimated_hours", "duration_actual", "status")
    def _compute_efficiency_rating(self):
        """
        Compute efficiency rating based on actual vs estimated time
        Same pattern as Hello World Todo computed fields
        """
        for installation in self:
            if (
                installation.status == "completed"
                and installation.estimated_hours > 0
                and installation.duration_actual > 0
            ):
                ratio = installation.duration_actual / installation.estimated_hours
                if ratio <= 1.0:
                    installation.efficiency_rating = "excellent"
                elif ratio <= 1.1:
                    installation.efficiency_rating = "good"
                elif ratio <= 1.25:
                    installation.efficiency_rating = "fair"
                else:
                    installation.efficiency_rating = "poor"
            else:
                installation.efficiency_rating = False

    # === BUSINESS LOGIC METHODS === (Same pattern as Hello World Todo actions)

    def action_start_installation(self):
        """
        Start the installation process
        Same pattern as Hello World Todo action_start_task
        """
        for installation in self:
            if installation.status != "scheduled":
                raise UserError(_("Only scheduled installations can be started."))

            installation.write(
                {
                    "status": "in_progress",
                    "actual_start_date": fields.Datetime.now(),
                }
            )

            # Update related sales order
            installation.sale_order_id.write(
                {
                    "installation_status": "in_progress",
                }
            )

            _logger.info(f"Installation {installation.name} started by user {self.env.user.name}")

    def action_complete_installation(self):
        """
        Complete the installation
        Same pattern as Hello World Todo action_complete_task
        """
        for installation in self:
            if installation.status != "in_progress":
                raise UserError(_("Only in-progress installations can be completed."))

            installation.write(
                {
                    "status": "completed",
                    "completion_date": fields.Datetime.now(),
                }
            )

            # Update related sales order
            installation.sale_order_id.write(
                {
                    "installation_status": "completed",
                }
            )

            _logger.info(f"Installation {installation.name} completed by user {self.env.user.name}")

    def action_cancel_installation(self):
        """
        Cancel the installation
        Same pattern as Hello World Todo action_cancel_task
        """
        for installation in self:
            if installation.status == "completed":
                raise UserError(_("Cannot cancel completed installations."))

            installation.write(
                {
                    "status": "cancelled",
                }
            )

            # Update related sales order
            installation.sale_order_id.write(
                {
                    "installation_status": "cancelled",
                }
            )

            _logger.info(f"Installation {installation.name} cancelled by user {self.env.user.name}")

    def action_reschedule_installation(self):
        """
        Reschedule the installation
        Custom business action
        """
        for installation in self:
            if installation.status not in ["scheduled", "in_progress"]:
                raise UserError(_("Only scheduled or in-progress installations can be rescheduled."))

            # Reset to scheduled status
            installation.write(
                {
                    "status": "scheduled",
                    "actual_start_date": False,
                    "completion_date": False,
                }
            )

            _logger.info(f"Installation {installation.name} rescheduled by user {self.env.user.name}")

    # === VALIDATION CONSTRAINTS === (Same pattern as Hello World Todo)

    @api.constrains("scheduled_date")
    def _check_scheduled_date(self):
        """
        Validate scheduled date is not in the past
        Same pattern as Hello World Todo validation
        """
        for installation in self:
            if installation.scheduled_date and installation.scheduled_date < fields.Datetime.now():
                # Allow past dates only for completed installations
                if installation.status not in ["completed", "cancelled"]:
                    raise ValidationError(
                        _(
                            "Scheduled date cannot be in the past for active installations. "
                            "Please select a future date and time."
                        )
                    )

    @api.constrains("actual_start_date", "completion_date")
    def _check_date_sequence(self):
        """
        Validate date sequence is logical
        Same pattern as Hello World Todo validation
        """
        for installation in self:
            if installation.actual_start_date and installation.completion_date:
                if installation.actual_start_date > installation.completion_date:
                    raise ValidationError(_("Completion date cannot be before start date. " "Please check the dates."))

    # === ORM OVERRIDE METHODS === (Same pattern as Hello World Todo)

    @api.model
    def create(self, vals):
        """
        Override create method for custom logic
        Same pattern as Hello World Todo create override
        """
        # Auto-set installer if not specified
        if "installer_id" not in vals:
            vals["installer_id"] = self.env.user.id

        installation = super(RoyalInstallation, self).create(vals)
        _logger.info(f"New installation created: {installation.name} assigned to {installation.installer_id.name}")
        return installation

    def write(self, vals):
        """
        Override write method for status change logic
        Same pattern as Hello World Todo write override
        """
        # Auto-set actual hours when completing
        if vals.get("status") == "completed" and "actual_hours" not in vals:
            for installation in self:
                if installation.duration_actual > 0:
                    vals["actual_hours"] = installation.duration_actual

        # Log status changes
        for installation in self:
            old_status = installation.status

        result = super(RoyalInstallation, self).write(vals)

        # Log after update
        if "status" in vals:
            for installation in self:
                if old_status != installation.status:
                    _logger.info(
                        f"Installation {installation.name} status changed: {old_status} → {installation.status}"
                    )

        return result

    # === UTILITY METHODS === (Same pattern as Hello World Todo)

    def name_get(self):
        """
        Override name display for better UX
        Same pattern as Hello World Todo name_get
        """
        result = []
        for installation in self:
            # Show status and customer in name
            status_icon = (
                "✅" if installation.status == "completed" else "🔄" if installation.status == "in_progress" else "📅"
            )

            display_name = f"{status_icon} {installation.name}"
            if installation.customer_id:
                display_name += f" - {installation.customer_id.name}"
            if installation.scheduled_date:
                display_name += f" ({installation.scheduled_date.strftime('%m/%d %I:%M %p')})"

            result.append((installation.id, display_name))
        return result

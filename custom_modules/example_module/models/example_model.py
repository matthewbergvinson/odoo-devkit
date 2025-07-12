from odoo import models, fields, api
from odoo.exceptions import ValidationError


class ExampleModel(models.Model):
    """Example model to demonstrate the testing framework."""
    
    _name = 'example.model'
    _description = 'Example Model'
    _order = 'name'

    name = fields.Char(
        string='Name',
        required=True,
        help='The name of the example record'
    )
    
    description = fields.Text(
        string='Description',
        help='A detailed description of the example record'
    )
    
    value = fields.Float(
        string='Value',
        digits=(10, 2),
        help='A numeric value for calculations'
    )
    
    active = fields.Boolean(
        string='Active',
        default=True,
        help='Whether this record is active'
    )
    
    state = fields.Selection([
        ('draft', 'Draft'),
        ('confirmed', 'Confirmed'),
        ('done', 'Done'),
        ('cancelled', 'Cancelled')
    ], string='State', default='draft')
    
    partner_id = fields.Many2one(
        'res.partner',
        string='Partner',
        help='Related partner'
    )
    
    tag_ids = fields.Many2many(
        'example.tag',
        string='Tags',
        help='Tags for categorization'
    )
    
    line_ids = fields.One2many(
        'example.line',
        'example_id',
        string='Lines',
        help='Related lines'
    )
    
    total_value = fields.Float(
        string='Total Value',
        compute='_compute_total_value',
        store=True,
        help='Total value of all lines'
    )
    
    @api.depends('line_ids.value')
    def _compute_total_value(self):
        """Compute the total value of all lines."""
        for record in self:
            record.total_value = sum(line.value for line in record.line_ids)
    
    @api.constrains('value')
    def _check_value(self):
        """Validate that value is positive."""
        for record in self:
            if record.value < 0:
                raise ValidationError("Value must be positive")
    
    def action_confirm(self):
        """Confirm the record."""
        self.write({'state': 'confirmed'})
        return True
    
    def action_done(self):
        """Mark the record as done."""
        self.write({'state': 'done'})
        return True
    
    def action_cancel(self):
        """Cancel the record."""
        self.write({'state': 'cancelled'})
        return True
    
    def action_reset_to_draft(self):
        """Reset the record to draft."""
        self.write({'state': 'draft'})
        return True


class ExampleTag(models.Model):
    """Example tag model for categorization."""
    
    _name = 'example.tag'
    _description = 'Example Tag'
    _order = 'name'

    name = fields.Char(
        string='Name',
        required=True,
        help='The name of the tag'
    )
    
    color = fields.Integer(
        string='Color',
        default=0,
        help='Color index for the tag'
    )
    
    active = fields.Boolean(
        string='Active',
        default=True,
        help='Whether this tag is active'
    )


class ExampleLine(models.Model):
    """Example line model to demonstrate one2many relationships."""
    
    _name = 'example.line'
    _description = 'Example Line'
    _order = 'sequence, id'

    sequence = fields.Integer(
        string='Sequence',
        default=10,
        help='Sequence for ordering'
    )
    
    example_id = fields.Many2one(
        'example.model',
        string='Example',
        required=True,
        ondelete='cascade',
        help='Parent example record'
    )
    
    name = fields.Char(
        string='Name',
        required=True,
        help='The name of the line'
    )
    
    value = fields.Float(
        string='Value',
        digits=(10, 2),
        help='The value of the line'
    )
    
    notes = fields.Text(
        string='Notes',
        help='Additional notes for the line'
    ) 
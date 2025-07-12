from odoo import http
from odoo.http import request
import json


class ExampleController(http.Controller):
    """Example controller to demonstrate API endpoints."""

    @http.route('/api/example/list', type='json', auth='user', methods=['POST'])
    def list_examples(self, **kwargs):
        """List all example records."""
        domain = []
        if kwargs.get('name'):
            domain.append(('name', 'ilike', kwargs['name']))
        if kwargs.get('state'):
            domain.append(('state', '=', kwargs['state']))
        
        examples = request.env['example.model'].search(domain)
        return [{
            'id': example.id,
            'name': example.name,
            'description': example.description,
            'value': example.value,
            'state': example.state,
            'total_value': example.total_value,
        } for example in examples]

    @http.route('/api/example/<int:example_id>', type='json', auth='user', methods=['POST'])
    def get_example(self, example_id, **kwargs):
        """Get a specific example record."""
        example = request.env['example.model'].browse(example_id)
        if not example.exists():
            return {'error': 'Example not found'}
        
        return {
            'id': example.id,
            'name': example.name,
            'description': example.description,
            'value': example.value,
            'state': example.state,
            'total_value': example.total_value,
            'partner_id': example.partner_id.id if example.partner_id else None,
            'partner_name': example.partner_id.name if example.partner_id else None,
            'tag_ids': example.tag_ids.ids,
            'line_ids': [{
                'id': line.id,
                'name': line.name,
                'value': line.value,
                'notes': line.notes,
            } for line in example.line_ids]
        }

    @http.route('/api/example/create', type='json', auth='user', methods=['POST'])
    def create_example(self, **kwargs):
        """Create a new example record."""
        try:
            vals = {
                'name': kwargs.get('name'),
                'description': kwargs.get('description'),
                'value': kwargs.get('value', 0.0),
            }
            
            if kwargs.get('partner_id'):
                vals['partner_id'] = kwargs['partner_id']
            
            example = request.env['example.model'].create(vals)
            
            # Add lines if provided
            if kwargs.get('lines'):
                for line_vals in kwargs['lines']:
                    line_vals['example_id'] = example.id
                    request.env['example.line'].create(line_vals)
            
            return {
                'success': True,
                'id': example.id,
                'message': 'Example created successfully'
            }
        except Exception as e:
            return {
                'success': False,
                'error': str(e)
            }

    @http.route('/api/example/<int:example_id>/action', type='json', auth='user', methods=['POST'])
    def example_action(self, example_id, action, **kwargs):
        """Perform an action on an example record."""
        example = request.env['example.model'].browse(example_id)
        if not example.exists():
            return {'error': 'Example not found'}
        
        try:
            if action == 'confirm':
                example.action_confirm()
            elif action == 'done':
                example.action_done()
            elif action == 'cancel':
                example.action_cancel()
            elif action == 'reset':
                example.action_reset_to_draft()
            else:
                return {'error': 'Invalid action'}
            
            return {
                'success': True,
                'state': example.state,
                'message': f'Action {action} completed successfully'
            }
        except Exception as e:
            return {
                'success': False,
                'error': str(e)
            }

    @http.route('/api/example/stats', type='json', auth='user', methods=['POST'])
    def get_stats(self, **kwargs):
        """Get statistics about example records."""
        domain = []
        if kwargs.get('date_from'):
            domain.append(('create_date', '>=', kwargs['date_from']))
        if kwargs.get('date_to'):
            domain.append(('create_date', '<=', kwargs['date_to']))
        
        examples = request.env['example.model'].search(domain)
        
        stats = {
            'total_count': len(examples),
            'total_value': sum(examples.mapped('total_value')),
            'average_value': sum(examples.mapped('total_value')) / len(examples) if examples else 0,
            'state_counts': {},
        }
        
        for state in ['draft', 'confirmed', 'done', 'cancelled']:
            stats['state_counts'][state] = len(examples.filtered(lambda x: x.state == state))
        
        return stats 
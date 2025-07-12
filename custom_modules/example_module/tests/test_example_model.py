from odoo.exceptions import ValidationError
from odoo.tests.common import TransactionCase


class TestExampleModel(TransactionCase):
    """Test cases for the example model."""

    def setUp(self):
        """Set up test data."""
        super().setUp()
        self.example_model = self.env['example.model']
        self.tag_model = self.env['example.tag']
        self.line_model = self.env['example.line']

        # Create test tags
        self.tag_test = self.tag_model.create({'name': 'Test Tag', 'color': 1})

        # Create test partner
        self.partner = self.env['res.partner'].create({'name': 'Test Partner', 'email': 'test@example.com'})

    def test_create_example_record(self):
        """Test creating an example record."""
        example = self.example_model.create(
            {
                'name': 'Test Example',
                'description': 'Test description',
                'value': 100.0,
                'partner_id': self.partner.id,
                'tag_ids': [(6, 0, [self.tag_test.id])],
            }
        )

        self.assertEqual(example.name, 'Test Example')
        self.assertEqual(example.description, 'Test description')
        self.assertEqual(example.value, 100.0)
        self.assertEqual(example.state, 'draft')
        self.assertEqual(example.partner_id, self.partner)
        self.assertIn(self.tag_test, example.tag_ids)
        self.assertTrue(example.active)

    def test_state_transitions(self):
        """Test state transitions."""
        example = self.example_model.create({'name': 'Test Example', 'value': 100.0})

        # Test confirm action
        example.action_confirm()
        self.assertEqual(example.state, 'confirmed')

        # Test done action
        example.action_done()
        self.assertEqual(example.state, 'done')

        # Test reset to draft
        example.action_reset_to_draft()
        self.assertEqual(example.state, 'draft')

        # Test cancel action
        example.action_cancel()
        self.assertEqual(example.state, 'cancelled')

    def test_compute_total_value(self):
        """Test total value computation."""
        example = self.example_model.create({'name': 'Test Example', 'value': 100.0})

        # Initially no lines, total should be 0
        self.assertEqual(example.total_value, 0.0)

        # Add lines
        self.line_model.create({'example_id': example.id, 'name': 'Line 1', 'value': 50.0})

        self.line_model.create({'example_id': example.id, 'name': 'Line 2', 'value': 30.0})

        # Total should be computed
        self.assertEqual(example.total_value, 80.0)

    def test_value_constraint(self):
        """Test value constraint validation."""
        example = self.example_model.create({'name': 'Test Example', 'value': 100.0})

        # Test positive value is allowed
        example.write({'value': 50.0})
        self.assertEqual(example.value, 50.0)

        # Test negative value raises ValidationError
        with self.assertRaises(ValidationError):
            example.write({'value': -10.0})

    def test_search_and_filtering(self):
        """Test search and filtering functionality."""
        # Create test records
        example1 = self.example_model.create({'name': 'Example 1', 'value': 100.0, 'state': 'draft'})

        example2 = self.example_model.create({'name': 'Example 2', 'value': 200.0, 'state': 'confirmed'})

        # Test search by name
        results = self.example_model.search([('name', 'ilike', 'Example 1')])
        self.assertIn(example1, results)
        self.assertNotIn(example2, results)

        # Test search by state
        results = self.example_model.search([('state', '=', 'confirmed')])
        self.assertIn(example2, results)
        self.assertNotIn(example1, results)

        # Test search by value range
        results = self.example_model.search([('value', '>', 150.0)])
        self.assertIn(example2, results)
        self.assertNotIn(example1, results)

    def test_tag_relationship(self):
        """Test many2many relationship with tags."""
        example = self.example_model.create({'name': 'Test Example', 'value': 100.0})

        # Create additional tags
        tag1 = self.tag_model.create({'name': 'Tag 1', 'color': 1})
        tag2 = self.tag_model.create({'name': 'Tag 2', 'color': 2})

        # Add tags to example
        example.write({'tag_ids': [(6, 0, [tag1.id, tag2.id])]})

        self.assertEqual(len(example.tag_ids), 2)
        self.assertIn(tag1, example.tag_ids)
        self.assertIn(tag2, example.tag_ids)

    def test_line_relationship(self):
        """Test one2many relationship with lines."""
        example = self.example_model.create({'name': 'Test Example', 'value': 100.0})

        # Create lines
        line1 = self.line_model.create({'example_id': example.id, 'name': 'Line 1', 'value': 50.0, 'sequence': 10})

        line2 = self.line_model.create({'example_id': example.id, 'name': 'Line 2', 'value': 30.0, 'sequence': 20})

        self.assertEqual(len(example.line_ids), 2)
        self.assertIn(line1, example.line_ids)
        self.assertIn(line2, example.line_ids)

        # Test cascade delete
        example.unlink()
        self.assertFalse(line1.exists())
        self.assertFalse(line2.exists())

    def test_default_values(self):
        """Test default values are set correctly."""
        example = self.example_model.create({'name': 'Test Example'})

        self.assertEqual(example.state, 'draft')
        self.assertTrue(example.active)
        self.assertEqual(example.value, 0.0)
        self.assertEqual(example.total_value, 0.0)

    def test_required_fields(self):
        """Test required field validation."""
        # Test that name is required
        with self.assertRaises(Exception):
            self.example_model.create({'value': 100.0})

    def test_ordering(self):
        """Test record ordering."""
        example_z = self.example_model.create({'name': 'Z Example', 'value': 100.0})

        example_a = self.example_model.create({'name': 'A Example', 'value': 100.0})

        # Search should return records ordered by name
        results = self.example_model.search([('name', 'in', ['Z Example', 'A Example'])])
        self.assertEqual(results[0], example_a)
        self.assertEqual(results[1], example_z)

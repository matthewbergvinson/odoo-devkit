"""Unit tests for the example module."""

import unittest

from tests.base_model_test import BaseModelTest


class TestExampleModel(BaseModelTest):
    """Unit tests for example.model."""

    def setUp(self):
        """Set up test data."""
        super().setUp()
        self.Example = self.env['example.model']
        self.Tag = self.env['example.tag']
        self.Line = self.env['example.line']

    def test_example_model_creation(self):
        """Test creating an example model record."""
        # Create a basic example record
        example = self.Example.create(
            {'name': 'Test Example', 'description': 'A test example for unit testing', 'value': 100.0}
        )

        # Verify the record was created with correct values
        self.assertEqual(example.name, 'Test Example')
        self.assertEqual(example.description, 'A test example for unit testing')
        self.assertEqual(example.value, 100.0)
        self.assertEqual(example.state, 'draft')
        self.assertTrue(example.active)
        self.assertEqual(example.total_value, 0.0)

    def test_example_model_state_transitions(self):
        """Test state transitions work correctly."""
        example = self.Example.create({'name': 'State Test Example', 'value': 50.0})

        # Test draft -> confirmed
        self.assertEqual(example.state, 'draft')
        result = example.action_confirm()
        self.assertTrue(result)
        self.assertEqual(example.state, 'confirmed')

        # Test confirmed -> done
        result = example.action_done()
        self.assertTrue(result)
        self.assertEqual(example.state, 'done')

        # Test reset to draft
        result = example.action_reset_to_draft()
        self.assertTrue(result)
        self.assertEqual(example.state, 'draft')

        # Test draft -> cancelled
        result = example.action_cancel()
        self.assertTrue(result)
        self.assertEqual(example.state, 'cancelled')

    def test_example_model_computed_fields(self):
        """Test computed fields work correctly."""
        example = self.Example.create({'name': 'Computed Test Example', 'value': 75.0})

        # Initially no lines, so total_value should be 0
        self.assertEqual(example.total_value, 0.0)

        # Create some lines
        line1 = self.Line.create({'example_id': example.id, 'name': 'Line 1', 'value': 25.0})

        line2 = self.Line.create({'example_id': example.id, 'name': 'Line 2', 'value': 35.0})

        # Total value should be computed
        self.assertEqual(example.total_value, 60.0)

        # Update line value and verify recomputation
        line1.write({'value': 40.0})
        self.assertEqual(example.total_value, 75.0)

    def test_example_model_constraints(self):
        """Test model constraints work correctly."""
        example = self.Example.create({'name': 'Constraint Test Example', 'value': 100.0})

        # Test positive value is allowed
        example.write({'value': 50.0})
        self.assertEqual(example.value, 50.0)

        # Test zero value is allowed
        example.write({'value': 0.0})
        self.assertEqual(example.value, 0.0)

        # Test negative value should raise ValidationError
        with self.assertRaises(Exception):
            example.write({'value': -10.0})

    def test_example_model_relationships(self):
        """Test model relationships work correctly."""
        # Create tags
        tag1 = self.Tag.create({'name': 'Tag 1', 'color': 1})
        tag2 = self.Tag.create({'name': 'Tag 2', 'color': 2})

        # Create example with tags
        example = self.Example.create(
            {'name': 'Relationship Test Example', 'value': 100.0, 'tag_ids': [(6, 0, [tag1.id, tag2.id])]}
        )

        # Test many2many relationship
        self.assertEqual(len(example.tag_ids), 2)
        self.assertIn(tag1, example.tag_ids)
        self.assertIn(tag2, example.tag_ids)

        # Create lines
        line1 = self.Line.create({'example_id': example.id, 'name': 'Line 1', 'value': 30.0, 'sequence': 10})

        line2 = self.Line.create({'example_id': example.id, 'name': 'Line 2', 'value': 20.0, 'sequence': 20})

        # Test one2many relationship
        self.assertEqual(len(example.line_ids), 2)
        self.assertIn(line1, example.line_ids)
        self.assertIn(line2, example.line_ids)

        # Test ordering
        ordered_lines = example.line_ids.sorted('sequence')
        self.assertEqual(ordered_lines[0], line1)
        self.assertEqual(ordered_lines[1], line2)

    def test_example_model_search_filtering(self):
        """Test search and filtering capabilities."""
        # Create test records
        example1 = self.Example.create({'name': 'Example Alpha', 'value': 100.0, 'state': 'draft'})

        example2 = self.Example.create({'name': 'Example Beta', 'value': 200.0, 'state': 'confirmed'})

        example3 = self.Example.create({'name': 'Example Gamma', 'value': 150.0, 'state': 'done'})

        # Test name search
        results = self.Example.search([('name', 'ilike', 'Alpha')])
        self.assertEqual(len(results), 1)
        self.assertEqual(results[0], example1)

        # Test state filtering
        confirmed_results = self.Example.search([('state', '=', 'confirmed')])
        self.assertIn(example2, confirmed_results)
        self.assertNotIn(example1, confirmed_results)
        self.assertNotIn(example3, confirmed_results)

        # Test value range filtering
        high_value_results = self.Example.search([('value', '>', 175.0)])
        self.assertIn(example2, high_value_results)
        self.assertNotIn(example1, high_value_results)
        self.assertNotIn(example3, high_value_results)

        # Test ordering
        ordered_results = self.Example.search([('name', 'in', ['Example Alpha', 'Example Beta', 'Example Gamma'])])
        # Should be ordered by name (default _order)
        self.assertEqual(ordered_results[0], example1)  # Alpha
        self.assertEqual(ordered_results[1], example2)  # Beta
        self.assertEqual(ordered_results[2], example3)  # Gamma


class TestExampleTag(BaseModelTest):
    """Unit tests for example.tag."""

    def setUp(self):
        """Set up test data."""
        super().setUp()
        self.Tag = self.env['example.tag']

    def test_tag_creation(self):
        """Test creating a tag."""
        tag = self.Tag.create({'name': 'Test Tag', 'color': 5})

        self.assertEqual(tag.name, 'Test Tag')
        self.assertEqual(tag.color, 5)
        self.assertTrue(tag.active)

    def test_tag_defaults(self):
        """Test tag default values."""
        tag = self.Tag.create({'name': 'Default Tag'})

        self.assertEqual(tag.color, 0)
        self.assertTrue(tag.active)


class TestExampleLine(BaseModelTest):
    """Unit tests for example.line."""

    def setUp(self):
        """Set up test data."""
        super().setUp()
        self.Example = self.env['example.model']
        self.Line = self.env['example.line']

        # Create parent example
        self.example = self.Example.create({'name': 'Parent Example', 'value': 100.0})

    def test_line_creation(self):
        """Test creating a line."""
        line = self.Line.create({'example_id': self.example.id, 'name': 'Test Line', 'value': 50.0})

        self.assertEqual(line.name, 'Test Line')
        self.assertEqual(line.value, 50.0)
        self.assertEqual(line.example_id, self.example)
        self.assertEqual(line.sequence, 10)  # Default sequence

    def test_line_sequence_ordering(self):
        """Test line ordering by sequence."""
        line1 = self.Line.create({'example_id': self.example.id, 'name': 'Line 1', 'value': 25.0, 'sequence': 20})

        line2 = self.Line.create({'example_id': self.example.id, 'name': 'Line 2', 'value': 35.0, 'sequence': 10})

        # Search should return ordered by sequence
        lines = self.Line.search([('example_id', '=', self.example.id)])
        self.assertEqual(lines[0], line2)  # sequence 10
        self.assertEqual(lines[1], line1)  # sequence 20

    def test_line_cascade_delete(self):
        """Test cascade delete when parent is deleted."""
        line = self.Line.create({'example_id': self.example.id, 'name': 'Test Line', 'value': 25.0})

        line_id = line.id

        # Delete parent example
        self.example.unlink()

        # Line should be deleted too (cascade)
        self.assertFalse(self.Line.browse(line_id).exists())


if __name__ == '__main__':
    unittest.main()

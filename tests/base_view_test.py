"""
RTP Denver - Base View Test Classes
Task 4.2: Create base test classes for models, views, and controllers

This module provides comprehensive base test classes for testing Odoo views,
including XML validation, field presence checking, and UI interaction testing.
"""

import logging
import xml.etree.ElementTree as ET
from typing import Any, Dict, List, Optional
from unittest.mock import Mock, patch

import pytest
from lxml import etree

# These imports will work when Odoo is available
try:
    from odoo.exceptions import UserError, ValidationError
    from odoo.tests.common import HttpCase, TransactionCase
    from odoo.tools import mute_logger

    ODOO_AVAILABLE = True
except ImportError:
    # Mock classes for when Odoo is not available (unit testing)
    ODOO_AVAILABLE = False

    class TransactionCase:
        pass

    class HttpCase:
        pass

    class ValidationError(Exception):
        pass

    class UserError(Exception):
        pass


class BaseViewTest:
    """
    Base test class for Odoo view testing without database dependency.

    This class provides functionality for testing view XML structure,
    field definitions, and basic view validation.
    """

    @pytest.fixture(autouse=True)
    def setup_logging(self, caplog):
        """Setup logging for tests."""
        caplog.set_level(logging.INFO)
        self.logger = logging.getLogger(self.__class__.__name__)

    @pytest.fixture
    def sample_view_xml(self):
        """Provide sample view XML for testing."""
        return """
        <record id="test_view_form" model="ir.ui.view">
            <field name="name">Test Form View</field>
            <field name="model">test.model</field>
            <field name="arch" type="xml">
                <form string="Test Form">
                    <sheet>
                        <group>
                            <field name="name"/>
                            <field name="email"/>
                            <field name="phone"/>
                        </group>
                    </sheet>
                </form>
            </field>
        </record>
        """

    def parse_view_xml(self, xml_string: str) -> ET.Element:
        """Parse XML string and return root element."""
        try:
            return ET.fromstring(xml_string)
        except ET.ParseError as e:
            pytest.fail(f"Invalid XML structure: {e}")

    def parse_view_arch(self, arch_xml: str) -> ET.Element:
        """Parse view architecture XML."""
        try:
            return ET.fromstring(arch_xml)
        except ET.ParseError as e:
            pytest.fail(f"Invalid view architecture XML: {e}")

    def assert_xml_valid(self, xml_string: str):
        """Assert that XML string is valid."""
        try:
            ET.fromstring(xml_string)
        except ET.ParseError as e:
            pytest.fail(f"XML validation failed: {e}")

    def assert_view_field_present(self, arch_xml: str, field_name: str):
        """Assert that a field is present in the view architecture."""
        root = self.parse_view_arch(arch_xml)
        fields = root.findall(".//field[@name='{}']".format(field_name))
        assert len(fields) > 0, f"Field {field_name} not found in view"

    def assert_view_field_absent(self, arch_xml: str, field_name: str):
        """Assert that a field is NOT present in the view architecture."""
        root = self.parse_view_arch(arch_xml)
        fields = root.findall(".//field[@name='{}']".format(field_name))
        assert len(fields) == 0, f"Field {field_name} should not be in view"

    def assert_view_field_attribute(self, arch_xml: str, field_name: str, attribute: str, expected_value: str):
        """Assert that a field has a specific attribute value."""
        root = self.parse_view_arch(arch_xml)
        field = root.find(".//field[@name='{}']".format(field_name))
        assert field is not None, f"Field {field_name} not found in view"

        actual_value = field.get(attribute)
        assert actual_value == expected_value, (
            f"Field {field_name} attribute {attribute} should be " f"{expected_value}, got {actual_value}"
        )

    def assert_view_button_present(self, arch_xml: str, button_name: str):
        """Assert that a button is present in the view."""
        root = self.parse_view_arch(arch_xml)
        buttons = root.findall(".//button[@name='{}']".format(button_name))
        assert len(buttons) > 0, f"Button {button_name} not found in view"

    def assert_view_group_present(self, arch_xml: str, group_string: str = None):
        """Assert that a group element is present in the view."""
        root = self.parse_view_arch(arch_xml)
        if group_string:
            groups = root.findall(".//group[@string='{}']".format(group_string))
        else:
            groups = root.findall(".//group")
        assert len(groups) > 0, f"Group {group_string or ''} not found in view"

    def get_view_fields(self, arch_xml: str) -> List[str]:
        """Get list of all field names in the view."""
        root = self.parse_view_arch(arch_xml)
        fields = root.findall(".//field")
        return [field.get('name') for field in fields if field.get('name')]

    def get_view_buttons(self, arch_xml: str) -> List[str]:
        """Get list of all button names in the view."""
        root = self.parse_view_arch(arch_xml)
        buttons = root.findall(".//button")
        return [button.get('name') for button in buttons if button.get('name')]


class BaseOdooViewTest(TransactionCase if ODOO_AVAILABLE else BaseViewTest):
    """
    Base test class for Odoo view testing with database dependency.

    This class provides functionality for testing views with actual Odoo
    environment, including view rendering and field validation.
    """

    @classmethod
    def setUpClass(cls):
        """Set up class-level test data."""
        if ODOO_AVAILABLE:
            super().setUpClass()

    def setUp(self):
        """Set up individual test."""
        if ODOO_AVAILABLE:
            super().setUp()

    def get_view_by_id(self, view_id: str) -> 'models.Model':
        """Get a view record by its XML ID."""
        if not ODOO_AVAILABLE:
            return Mock()

        return self.env.ref(view_id)

    def get_view_by_model(self, model_name: str, view_type: str = 'form') -> 'models.Model':
        """Get the default view for a model."""
        if not ODOO_AVAILABLE:
            return Mock()

        return self.env[model_name].fields_view_get(view_type=view_type)

    def assert_view_exists(self, view_id: str):
        """Assert that a view exists in the database."""
        if not ODOO_AVAILABLE:
            return

        try:
            view = self.env.ref(view_id)
            assert view, f"View {view_id} not found"
        except ValueError:
            pytest.fail(f"View {view_id} does not exist")

    def assert_view_model(self, view_id: str, expected_model: str):
        """Assert that a view is for the expected model."""
        if not ODOO_AVAILABLE:
            return

        view = self.get_view_by_id(view_id)
        assert view.model == expected_model, f"View {view_id} model should be {expected_model}, got {view.model}"

    def assert_view_type(self, view_id: str, expected_type: str):
        """Assert that a view is of the expected type."""
        if not ODOO_AVAILABLE:
            return

        view = self.get_view_by_id(view_id)
        assert view.type == expected_type, f"View {view_id} type should be {expected_type}, got {view.type}"

    def assert_view_active(self, view_id: str):
        """Assert that a view is active."""
        if not ODOO_AVAILABLE:
            return

        view = self.get_view_by_id(view_id)
        assert view.active, f"View {view_id} should be active"

    def assert_field_in_view(self, model_name: str, field_name: str, view_type: str = 'form'):
        """Assert that a field appears in the default view of a model."""
        if not ODOO_AVAILABLE:
            return

        view_data = self.get_view_by_model(model_name, view_type)
        arch = view_data.get('arch', '')
        self.assert_view_field_present(arch, field_name)

    def assert_field_readonly_in_view(self, model_name: str, field_name: str, view_type: str = 'form'):
        """Assert that a field is readonly in the view."""
        if not ODOO_AVAILABLE:
            return

        view_data = self.get_view_by_model(model_name, view_type)
        arch = view_data.get('arch', '')
        self.assert_view_field_attribute(arch, field_name, 'readonly', '1')

    def assert_field_required_in_view(self, model_name: str, field_name: str, view_type: str = 'form'):
        """Assert that a field is required in the view."""
        if not ODOO_AVAILABLE:
            return

        view_data = self.get_view_by_model(model_name, view_type)
        arch = view_data.get('arch', '')
        self.assert_view_field_attribute(arch, field_name, 'required', '1')

    def assert_field_invisible_in_view(self, model_name: str, field_name: str, view_type: str = 'form'):
        """Assert that a field is invisible in the view."""
        if not ODOO_AVAILABLE:
            return

        view_data = self.get_view_by_model(model_name, view_type)
        arch = view_data.get('arch', '')
        self.assert_view_field_attribute(arch, field_name, 'invisible', '1')

    def create_test_view(self, model_name: str, view_type: str, arch: str, name: str = None) -> 'models.Model':
        """Create a test view for testing purposes."""
        if not ODOO_AVAILABLE:
            return Mock()

        values = {
            'name': name or f'Test {view_type.title()} View',
            'model': model_name,
            'type': view_type,
            'arch': arch,
        }
        return self.env['ir.ui.view'].create(values)

    def validate_view_rendering(self, view_id: str):
        """Validate that a view can be rendered without errors."""
        if not ODOO_AVAILABLE:
            return

        view = self.get_view_by_id(view_id)
        try:
            # Attempt to render the view
            model = self.env[view.model]
            model.fields_view_get(view_id=view.id, view_type=view.type)
        except Exception as e:
            pytest.fail(f"View {view_id} rendering failed: {e}")


class BaseFormViewTest(BaseOdooViewTest):
    """
    Specialized base class for testing form views.
    """

    def assert_form_has_sheet(self, arch_xml: str):
        """Assert that a form view has a sheet element."""
        root = self.parse_view_arch(arch_xml)
        sheets = root.findall(".//sheet")
        assert len(sheets) > 0, "Form view should have a sheet element"

    def assert_form_has_header(self, arch_xml: str):
        """Assert that a form view has a header element."""
        root = self.parse_view_arch(arch_xml)
        headers = root.findall(".//header")
        assert len(headers) > 0, "Form view should have a header element"

    def assert_form_has_statusbar(self, arch_xml: str, field_name: str):
        """Assert that a form view has a statusbar widget."""
        root = self.parse_view_arch(arch_xml)
        statusbars = root.findall(f".//field[@name='{field_name}'][@widget='statusbar']")
        assert len(statusbars) > 0, f"Form view should have statusbar for field {field_name}"


class BaseListViewTest(BaseOdooViewTest):
    """
    Specialized base class for testing list/tree views.
    """

    def assert_list_field_order(self, arch_xml: str, expected_fields: List[str]):
        """Assert that fields appear in the expected order in list view."""
        fields = self.get_view_fields(arch_xml)
        for i, expected_field in enumerate(expected_fields):
            assert i < len(fields), f"Field {expected_field} not found at position {i}"
            assert fields[i] == expected_field, f"Field at position {i} should be {expected_field}, got {fields[i]}"

    def assert_list_has_create_button(self, arch_xml: str):
        """Assert that list view allows record creation."""
        root = self.parse_view_arch(arch_xml)
        # Check if create attribute is not set to false
        create_attr = root.get('create')
        assert create_attr != 'false', "List view should allow creation"

    def assert_list_has_edit_button(self, arch_xml: str):
        """Assert that list view allows record editing."""
        root = self.parse_view_arch(arch_xml)
        # Check if edit attribute is not set to false
        edit_attr = root.get('edit')
        assert edit_attr != 'false', "List view should allow editing"

    def assert_list_has_delete_button(self, arch_xml: str):
        """Assert that list view allows record deletion."""
        root = self.parse_view_arch(arch_xml)
        # Check if delete attribute is not set to false
        delete_attr = root.get('delete')
        assert delete_attr != 'false', "List view should allow deletion"


class BaseSearchViewTest(BaseOdooViewTest):
    """
    Specialized base class for testing search views.
    """

    def assert_search_field_present(self, arch_xml: str, field_name: str):
        """Assert that a search field is present."""
        self.assert_view_field_present(arch_xml, field_name)

    def assert_search_filter_present(self, arch_xml: str, filter_name: str):
        """Assert that a search filter is present."""
        root = self.parse_view_arch(arch_xml)
        filters = root.findall(f".//filter[@name='{filter_name}']")
        assert len(filters) > 0, f"Search filter {filter_name} not found"

    def assert_search_group_by_present(self, arch_xml: str, field_name: str):
        """Assert that a group by option is present."""
        root = self.parse_view_arch(arch_xml)
        group_bys = root.findall(f".//filter[@context*='group_by:{field_name}']")
        assert len(group_bys) > 0, f"Group by {field_name} not found in search view"


class BaseMenuTest(BaseOdooViewTest):
    """
    Base class for testing menu items and navigation.
    """

    def assert_menu_exists(self, menu_id: str):
        """Assert that a menu item exists."""
        if not ODOO_AVAILABLE:
            return

        try:
            menu = self.env.ref(menu_id)
            assert menu, f"Menu {menu_id} not found"
        except ValueError:
            pytest.fail(f"Menu {menu_id} does not exist")

    def assert_menu_action(self, menu_id: str, expected_action: str):
        """Assert that a menu points to the expected action."""
        if not ODOO_AVAILABLE:
            return

        menu = self.env.ref(menu_id)
        assert menu.action, f"Menu {menu_id} should have an action"

        # Get the action name
        action_name = menu.action.xml_id or menu.action.name
        assert expected_action in action_name, f"Menu {menu_id} should point to action containing {expected_action}"

    def assert_menu_parent(self, menu_id: str, parent_menu_id: str):
        """Assert that a menu has the expected parent."""
        if not ODOO_AVAILABLE:
            return

        menu = self.env.ref(menu_id)
        parent = self.env.ref(parent_menu_id)
        assert menu.parent_id == parent, f"Menu {menu_id} should have parent {parent_menu_id}"


# Example test classes showing usage
class ExampleFormViewTest(BaseFormViewTest):
    """
    Example test class demonstrating form view testing.
    """

    @pytest.mark.database
    def test_partner_form_view(self):
        """Example test for partner form view."""
        if not ODOO_AVAILABLE:
            pytest.skip("Odoo not available")

        view_data = self.get_view_by_model('res.partner', 'form')
        arch = view_data.get('arch', '')

        # Test that essential fields are present
        self.assert_view_field_present(arch, 'name')
        self.assert_view_field_present(arch, 'email')
        self.assert_view_field_present(arch, 'phone')

        # Test that form has proper structure
        self.assert_form_has_sheet(arch)

    @pytest.mark.unit
    @pytest.mark.no_database
    def test_xml_structure(self, sample_view_xml):
        """Example unit test for XML structure."""
        self.assert_xml_valid(sample_view_xml)

        # Parse and test structure
        root = self.parse_view_xml(sample_view_xml)
        assert root.tag == 'record'
        assert root.get('model') == 'ir.ui.view'


class ExampleListViewTest(BaseListViewTest):
    """
    Example test class demonstrating list view testing.
    """

    @pytest.mark.database
    def test_partner_list_view(self):
        """Example test for partner list view."""
        if not ODOO_AVAILABLE:
            pytest.skip("Odoo not available")

        view_data = self.get_view_by_model('res.partner', 'tree')
        arch = view_data.get('arch', '')

        # Test that essential fields are present
        self.assert_view_field_present(arch, 'name')
        self.assert_view_field_present(arch, 'email')

        # Test that operations are allowed
        self.assert_list_has_create_button(arch)
        self.assert_list_has_edit_button(arch)


# View testing utilities
def create_sample_form_view(model_name: str, fields: List[str]) -> str:
    """Create a sample form view XML for testing."""
    field_elements = ''.join([f'<field name="{field}"/>' for field in fields])

    return f"""
    <form string="Test Form">
        <sheet>
            <group>
                {field_elements}
            </group>
        </sheet>
    </form>
    """


def create_sample_list_view(model_name: str, fields: List[str]) -> str:
    """Create a sample list view XML for testing."""
    field_elements = ''.join([f'<field name="{field}"/>' for field in fields])

    return f"""
    <tree string="Test List">
        {field_elements}
    </tree>
    """


def create_sample_search_view(model_name: str, search_fields: List[str], filter_fields: List[str] = None) -> str:
    """Create a sample search view XML for testing."""
    field_elements = ''.join([f'<field name="{field}"/>' for field in search_fields])

    filter_elements = ''
    if filter_fields:
        filter_elements = ''.join(
            [
                f'<filter name="filter_{field}" string="{field.title()}" ' f'domain="[(\'{field}\', \'!=\', False)]"/>'
                for field in filter_fields
            ]
        )

    return f"""
    <search string="Test Search">
        {field_elements}
        <group expand="0" string="Group By">
            {filter_elements}
        </group>
    </search>
    """

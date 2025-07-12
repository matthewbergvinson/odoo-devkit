# VS Code Snippets Guide for Royal Textiles Odoo Development

This guide explains how to use the comprehensive VS Code snippet system for efficient Royal Textiles Odoo development. These snippets provide ready-to-use templates for common Odoo patterns.

## 🚀 Quick Start

### Accessing Snippets
1. **In any file**: Start typing the snippet prefix
2. **IntelliSense**: Press `Ctrl+Space` to see available snippets
3. **Tab completion**: Press `Tab` to insert and navigate through placeholders
4. **Snippet browser**: `Ctrl+Shift+P` → "Insert Snippet"

### Using Snippets
- Type the **prefix** (e.g., `odoo-model`)
- Press `Tab` to insert the snippet
- Use `Tab` to move between placeholders
- Replace placeholders with your actual values
- Press `Esc` to exit snippet mode

## 📁 Snippet Categories

### 🐍 Python Snippets (`python.json`)

#### **Model Development**

**`odoo-model`** - Basic Odoo Model
```python
from odoo import api, fields, models

class ModelName(models.Model):
    _name = 'module.model.name'
    _description = 'Model Description'
    _order = 'name'

    name = fields.Char(string='Name', required=True)
    description = fields.Text(string='Description')
    active = fields.Boolean(string='Active', default=True)
```

**`odoo-model-inherit`** - Model Inheritance
```python
class ModelName(models.Model):
    _inherit = 'existing.model'
    _description = 'Extended Model Description'

    new_field = fields.Char(string='Field Label')
```

**`odoo-model-rtp`** - Royal Textiles Model Template
- Complete model with standard RTP fields
- Audit fields (create_date, create_uid, etc.)
- State management with tracking
- Business-specific field patterns

#### **Field Types & Relationships**

**`odoo-selection`** - Selection Field
```python
field_name = fields.Selection([
    ('value1', 'Label 1'),
    ('value2', 'Label 2'),
], string='Field Label', default='value1')
```

**`odoo-computed`** - Computed Field
```python
field_name = fields.Char(compute='_compute_field_name', store=True)

@api.depends('dependency_field')
def _compute_field_name(self):
    for record in self:
        record.field_name = computed_value
```

**`odoo-many2one`** - Many2one Relationship
```python
field_name_id = fields.Many2one(
    comodel_name='target.model',
    string='Field Label',
    required=True,
    ondelete='cascade'
)
```

**`odoo-one2many`** - One2many Relationship
```python
field_name_ids = fields.One2many(
    comodel_name='target.model',
    inverse_name='inverse_field_id',
    string='Field Label'
)
```

**`odoo-many2many`** - Many2many Relationship
```python
field_name_ids = fields.Many2many(
    comodel_name='target.model',
    relation='relation_table',
    column1='source_id',
    column2='target_id',
    string='Field Label'
)
```

#### **Business Logic Methods**

**`odoo-constraint`** - API Constraint
```python
@api.constrains('field_name')
def _check_field_name(self):
    for record in self:
        if condition:
            raise ValidationError(_('Error message'))
```

**`odoo-onchange`** - Onchange Method
```python
@api.onchange('field_name')
def _onchange_field_name(self):
    if self.field_name:
        # Logic when field changes
```

**`odoo-crud`** - CRUD Method Overrides
```python
@api.model
def create(self, vals):
    # Pre-creation logic
    record = super(ModelName, self).create(vals)
    # Post-creation logic
    return record
```

#### **Controllers & Web**

**`odoo-controller`** - HTTP Controller
```python
class ControllerName(http.Controller):

    @http.route('/route/path', type='http', auth='user')
    def method_name(self, **kwargs):
        # Controller logic
        return response
```

**`odoo-json-controller`** - JSON API Controller
```python
@http.route('/api/endpoint', type='json', auth='user', methods=['POST'])
def method_name(self, **kwargs):
    try:
        # Process request
        return {'success': True, 'data': result}
    except Exception as e:
        return {'success': False, 'error': str(e)}
```

**`odoo-website-controller`** - Website Controller
```python
@http.route('/web/page', type='http', auth='public', website=True)
def method_name(self, **kwargs):
    values = {'key': value}
    return request.render('module.template_name', values)
```

#### **Specialized Models**

**`odoo-wizard`** - Transient Model (Wizard)
```python
class WizardName(models.TransientModel):
    _name = 'module.wizard.name'
    _description = 'Wizard Description'

    def action_confirm(self):
        # Wizard logic
        return {'type': 'ir.actions.act_window_close'}
```

**`odoo-report`** - Report Model
```python
class ReportName(models.Model):
    _name = 'module.report.name'
    _auto = False

    def init(self):
        tools.drop_view_if_exists(self.env.cr, self._table)
        self.env.cr.execute("""CREATE VIEW...""")
```

#### **Utility Patterns**

**`odoo-business-method`** - Business Logic Method
```python
def method_name(self):
    """Method description

    Returns:
        Return type: Return description
    """
    self.ensure_one()
    # Business logic
    return result
```

**`odoo-state-transition`** - State Transition
```python
def action_state_name(self):
    """Transition to state_name state"""
    for record in self:
        if record.state != 'expected_state':
            raise UserError(_('Cannot transition'))
        record.state = 'new_state'
```

**`odoo-domain`** - Search Domain
```python
domain = [
    ('field_name', 'operator', value),
    ('field_name', 'operator', value),
]
records = self.env['model.name'].search(domain, limit=10)
```

**`odoo-env`** - Environment Usage
```python
# Access models, create, search, browse
model = self.env['model.name']
record = model.create({'field': value})
records = model.search([('field', '=', value)])
```

**`odoo-exception`** - Exception Handling
```python
try:
    # Code that might raise exceptions
except ValidationError as e:
    raise ValidationError(_('Custom message: %s') % str(e))
```

**`odoo-cron`** - Scheduled Job
```python
@api.model
def cron_job_name(self):
    """Cron job description"""
    try:
        # Cron job logic
        _logger.info('Cron job completed')
    except Exception as e:
        _logger.error('Cron job failed: %s', str(e))
```

**`odoo-rtp-install`** - Royal Textiles Integration
```python
# Royal Textiles specific fields for installations and sales
installation_id = fields.Many2one('rtp.installation')
sale_order_id = fields.Many2one('sale.order')
installation_state = fields.Selection([...])
```

### 🌐 XML Snippets (`xml.json`)

#### **View Development**

**`odoo-form-view`** - Complete Form View
- Full form structure with header, sheet, notebook
- Statusbar and workflow buttons
- Chatter integration
- Button box for smart buttons
- Responsive group layout

**`odoo-tree-view`** - Tree/List View
- Editable tree configuration
- Field decorations and badges
- State-based styling
- Invisible field handling

**`odoo-search-view`** - Search View
- Field filters with custom domains
- Predefined filter buttons
- Group by options
- Advanced search patterns

**`odoo-kanban-view`** - Kanban View
- Card-based layout
- State grouping
- Record templates
- Responsive design

**`odoo-pivot-view`** - Pivot Analysis View
```xml
<pivot string="Pivot Title">
    <field name="row_field" type="row"/>
    <field name="col_field" type="col"/>
    <field name="measure_field" type="measure"/>
</pivot>
```

**`odoo-graph-view`** - Chart View
```xml
<graph string="Graph Title" type="bar">
    <field name="x_field" type="row"/>
    <field name="y_field" type="measure"/>
</graph>
```

#### **Actions & Navigation**

**`odoo-action`** - Action Window
```xml
<record id="action_model_name" model="ir.actions.act_window">
    <field name="name">Action Name</field>
    <field name="res_model">module.model</field>
    <field name="view_mode">tree,form,kanban</field>
</record>
```

**`odoo-menu`** - Menu Structure
```xml
<!-- Main Menu -->
<menuitem id="menu_module_root" name="Main Menu"/>
<!-- Sub Menu -->
<menuitem id="menu_module_sub" parent="menu_module_root"/>
<!-- Action Menu -->
<menuitem id="menu_module_action" action="action_model_name"/>
```

#### **Security & Access Control**

**`odoo-security-access`** - Access Rights (CSV format)
```csv
id,name,model_id:id,group_id:id,perm_read,perm_write,perm_create,perm_unlink
access_model_user,Model User,model_module_model,base.group_user,1,0,0,0
```

**`odoo-security-rules`** - Record Rules
```xml
<record id="rule_model_user" model="ir.rule">
    <field name="name">Model: User Access</field>
    <field name="model_id" ref="model_module_model"/>
    <field name="domain_force">[('user_field', '=', user.id)]</field>
</record>
```

**`odoo-security-groups`** - Security Groups
```xml
<record id="group_group_name" model="res.groups">
    <field name="name">Group Display Name</field>
    <field name="category_id" ref="module.module_category"/>
</record>
```

#### **Data & Configuration**

**`odoo-data`** - Data Record
```xml
<record id="record_id" model="model.name">
    <field name="name">Record Name</field>
    <field name="many2one_field" ref="reference_id"/>
    <field name="boolean_field" eval="True"/>
</record>
```

**`odoo-demo`** - Demo Data
```xml
<odoo>
    <data noupdate="1">
        <record id="demo_record" model="module.model">
            <field name="name">Demo Record</field>
        </record>
    </data>
</odoo>
```

#### **Reports & Templates**

**`odoo-report-template`** - QWeb Report
```xml
<record id="report_name" model="ir.actions.report">
    <field name="name">Report Display Name</field>
    <field name="model">module.model</field>
    <field name="report_type">qweb-pdf</field>
</record>

<template id="report_template">
    <t t-call="web.html_container">
        <!-- Report content -->
    </t>
</template>
```

**`odoo-email-template`** - Email Template
```xml
<record id="email_template_name" model="mail.template">
    <field name="name">Email Template Name</field>
    <field name="subject">Email Subject - ${object.name}</field>
    <field name="body_html" type="html">
        <!-- Email content -->
    </field>
</record>
```

#### **Workflow & Automation**

**`odoo-workflow`** - Workflow Buttons
```xml
<header>
    <button name="action_confirm" type="object" string="Confirm"
            class="btn-primary" states="draft"/>
    <field name="state" widget="statusbar"/>
</header>
```

**`odoo-automated-action`** - Automated Action
```xml
<record id="automated_action_name" model="base.automation">
    <field name="name">Action Name</field>
    <field name="trigger">on_create</field>
    <field name="code"># Python code</field>
</record>
```

#### **Website & Frontend**

**`odoo-website-page`** - Website Page Template
```xml
<template id="template_name" name="Page Title" page="True">
    <t t-call="website.layout">
        <div id="wrap">
            <!-- Page content -->
        </div>
    </t>
</template>
```

#### **Royal Textiles Specialized**

**`odoo-rtp-form`** - Royal Textiles Form View
- Business-specific form layout
- Installation and sales integration
- State management for RTP workflows
- Smart buttons for related records
- Chatter integration

**`odoo-manifest`** - Module Manifest
```python
{
    'name': 'Module Name',
    'version': '18.0.1.0.0',
    'depends': ['base', 'sale'],
    'data': ['views/model_views.xml'],
    'installable': True,
}
```

### 🎨 JavaScript Snippets (`javascript.json`)

#### **OWL Components**

**`odoo-js-widget`** - OWL Component Widget
```javascript
export class WidgetName extends Component {
    static template = "module.WidgetName";

    setup() {
        super.setup();
    }
}
registry.category("fields").add("widget_name", WidgetName);
```

**`odoo-js-field`** - Custom Field Widget
```javascript
export class FieldWidget extends Component {
    static props = { ...standardFieldProps };

    get computedValue() {
        return this.props.record.data[this.props.name];
    }
}
```

#### **Actions & Services**

**`odoo-js-action`** - JavaScript Action
```javascript
export class ActionName extends Component {
    setup() {
        this.orm = this.env.services.orm;
    }

    async performAction() {
        const result = await this.orm.call("model", "method", [args]);
    }
}
```

**`odoo-js-service`** - Custom Service
```javascript
export const serviceName = {
    dependencies: ["orm", "notification"],

    start(env, { orm, notification }) {
        return {
            async methodName(params) {
                return await orm.call("model", "method", [params]);
            }
        };
    }
};
```

#### **Controllers & Views**

**`odoo-js-form-controller`** - Form Controller Patch
```javascript
patch(FormController.prototype, "module.FormController", {
    async customMethod() {
        return super.customMethod(...arguments);
    }
});
```

**`odoo-js-list-controller`** - List Controller Patch
```javascript
patch(ListController.prototype, "module.ListController", {
    async customAction() {
        const selectedRecords = await this.getSelectedResIds();
        // Custom list logic
    }
});
```

#### **UI Components**

**`odoo-js-dialog`** - Custom Dialog
```javascript
export class DialogName extends Component {
    static components = { Dialog };

    async confirm() {
        // Dialog confirmation logic
        this.props.close();
    }
}
```

**`odoo-qweb-template`** - QWeb Template
```xml
<t t-name="module.TemplateName" owl="1">
    <div class="widget_class">
        <button t-on-click="onClick">Button Text</button>
    </div>
</t>
```

#### **System Integration**

**`odoo-js-systray`** - Systray Item
```javascript
export class SystrayItem extends Component {
    async onClick() {
        await this.action.doAction({
            type: "ir.actions.act_window",
            res_model: "model.name"
        });
    }
}
```

**`odoo-js-tour`** - Web Tour
```javascript
registry.category("web_tour.tours").add("tour_name", {
    steps: () => [
        {
            trigger: '.selector',
            content: "Step description",
            run: "text Test",
        }
    ]
});
```

## 🎯 Usage Patterns

### **Model Development Workflow**
1. `odoo-model-rtp` - Start with Royal Textiles model template
2. `odoo-many2one` - Add relationship fields
3. `odoo-computed` - Add computed fields
4. `odoo-constraint` - Add validation
5. `odoo-business-method` - Add business logic

### **View Development Workflow**
1. `odoo-form-view` - Create comprehensive form
2. `odoo-tree-view` - Add list view
3. `odoo-search-view` - Add search and filters
4. `odoo-kanban-view` - Add kanban visualization
5. `odoo-action` - Create window action
6. `odoo-menu` - Add menu structure

### **Security Setup Workflow**
1. `odoo-security-groups` - Define security groups
2. `odoo-security-access` - Set access rights
3. `odoo-security-rules` - Add record rules

### **Royal Textiles Specific Workflow**
1. `odoo-model-rtp` - Use RTP model template
2. `odoo-rtp-install` - Add installation fields
3. `odoo-rtp-form` - Use RTP form template
4. Standard view, action, and menu snippets

## ⚙️ Configuration & Tips

### **Customizing Snippets**
- Edit files in `.vscode/snippets/`
- Add your own placeholders with `${1:default_value}`
- Use `${0}` for final cursor position
- Restart VS Code after changes

### **Best Practices**
1. **Consistent Naming**: Use clear, descriptive names
2. **Royal Textiles Standards**: Follow RTP naming conventions
3. **Documentation**: Include docstrings and comments
4. **Error Handling**: Use appropriate exception types
5. **Security**: Always consider access rights and validation

### **Performance Tips**
1. Use `store=True` judiciously on computed fields
2. Add database indexes for frequently searched fields
3. Use `api.depends` correctly for computed fields
4. Implement proper `_order` for consistent sorting

### **Debugging Snippets**
- Include `_logger` statements in business methods
- Add try/catch blocks with proper error handling
- Use `self.ensure_one()` for single-record methods
- Include validation in constraints and onchange methods

## 🔧 Maintenance

### **Adding New Snippets**
1. Edit appropriate JSON file in `.vscode/snippets/`
2. Follow existing naming conventions
3. Include proper placeholders and defaults
4. Test the snippet in actual development
5. Update this documentation

### **Royal Textiles Customizations**
- All RTP-specific snippets use `rtp.` prefix
- Include standard audit fields
- Use consistent state management
- Follow established field naming patterns

### **Integration with Tasks**
These snippets work seamlessly with our VS Code tasks:
- Use snippets to create code
- Run `🔍 Lint: Current File` to check quality
- Use `🧪 Test: Current Module` to test functionality
- Apply `🎨 Format: Current File` for consistency

## 📚 Additional Resources

- **Odoo Development Documentation**: https://www.odoo.com/documentation/18.0/developer.html
- **OWL Framework**: https://github.com/odoo/owl
- **QWeb Templates**: https://www.odoo.com/documentation/18.0/developer/reference/frontend/qweb.html
- **VS Code Snippets**: https://code.visualstudio.com/docs/editor/userdefinedsnippets

## 🎉 Conclusion

This comprehensive snippet system provides:
- **60+ specialized snippets** for all Odoo development patterns
- **Royal Textiles integration** with business-specific templates
- **Complete coverage** of models, views, controllers, and frontend
- **Consistent development patterns** across the team
- **Rapid development** with ready-to-use templates

Use these snippets to accelerate your Royal Textiles Odoo development while maintaining code quality and consistency!

For debugging workflows, see [docs/vscode-debugging-guide.md](./vscode-debugging-guide.md)
For task automation, see [docs/vscode-tasks-guide.md](./vscode-tasks-guide.md)

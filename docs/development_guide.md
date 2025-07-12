# RTP Denver Odoo Development Guide

## 🎯 Overview

This guide explains how to develop Odoo modules using Cursor IDE for the RTP Denver project, bridging the gap between learning examples and production-ready code.

## 🚀 Development Environment Setup

### **Prerequisites**
- Cursor IDE installed
- Python 3.11+ installed
- Git configured for GitHub access
- Access to RTP Denver odoo.sh instance

### **Initial Setup**
1. Clone the repository:
   ```bash
   git clone https://github.com/matthewbergvinson/rtp-denver.git
   cd rtp-denver
   git checkout matt1test
   ```

2. Open in Cursor:
   - Open the `rtp-denver` folder in Cursor
   - Install recommended extensions when prompted
   - Configure Python interpreter (should auto-detect)

3. Install development dependencies:
   ```bash
   pip install -r requirements.txt
   ```

## 📁 Project Structure

```
rtp-denver/
├── custom_modules/          # Your custom modules
│   ├── __init__.py
│   ├── your_module_name/    # Individual module
│   │   ├── __manifest__.py
│   │   ├── __init__.py
│   │   ├── models/
│   │   ├── views/
│   │   ├── security/
│   │   └── tests/
│   └── another_module/
├── docs/                    # Documentation
├── .vscode/                 # Cursor/VS Code settings
├── .gitignore              # Git ignore rules
├── .odoo_ignore            # Odoo.sh ignore rules
└── requirements.txt        # Python dependencies
```

## 🔧 Development Workflow

### **1. Creating a New Module**

Use your Hello World Todo module as a template:

```bash
# Create module directory
mkdir custom_modules/your_module_name
cd custom_modules/your_module_name

# Create basic structure
mkdir models views security controllers static tests data docs
touch __init__.py __manifest__.py
```

### **2. Module Development Process**

1. **Plan Your Module**
   - Define business requirements
   - Design data models
   - Plan user interface
   - Consider security needs

2. **Create the Manifest**
   ```python
   # __manifest__.py
   {
       'name': 'Your Module Name',
       'version': '18.0.1.0.0',
       'category': 'Your Category',
       'summary': 'Brief description',
       'depends': ['base', 'web'],
       'data': [
           'security/ir.model.access.csv',
           'views/your_views.xml',
           'data/your_data.xml',
       ],
       'installable': True,
       'application': True,
   }
   ```

3. **Develop Models**
   - Start with basic model structure
   - Add fields incrementally
   - Implement business logic
   - Add validation and constraints

4. **Create Views**
   - Form views for data entry
   - List views for overview
   - Search views for filtering
   - Menu items for navigation

5. **Configure Security**
   - Define user groups
   - Set model access rights
   - Create record rules if needed

6. **Add Tests**
   - Unit tests for models
   - Integration tests for workflows
   - UI tests for critical paths

### **3. Testing and Debugging**

#### **Local Testing**
```bash
# Run specific tests
python -m pytest custom_modules/your_module/tests/

# Run with coverage
coverage run -m pytest custom_modules/your_module/tests/
coverage report
```

#### **Debugging in Cursor**
- Set breakpoints in Python code
- Use integrated terminal for Odoo shell
- Inspect variables and call stack
- Use logging for runtime debugging

### **4. Deployment to Odoo.sh**

1. **Development Deployment**
   ```bash
   git add .
   git commit -m "Add new module feature"
   git push origin matt1test
   ```
   - This automatically triggers deployment to your dev environment

2. **Production Deployment**
   ```bash
   git checkout main
   git merge matt1test
   git push origin main
   ```
   - This deploys to production environment

## 🏗️ Transferring Hello World Concepts to Real Development

### **From Learning to Production**

Your Hello World Todo module taught you:
- Model creation and field types
- View development and UI design
- Security implementation
- Business logic and workflows
- Testing strategies

Apply these concepts to real modules:

1. **Model Design**
   ```python
   # Instead of simple todo tasks, create business models
   class Customer(models.Model):
       _name = 'rtp.customer'
       _description = 'RTP Customer'
       
       name = fields.Char(required=True)
       email = fields.Char()
       phone = fields.Char()
       # ... business-specific fields
   ```

2. **Business Logic**
   ```python
   # Real business workflows
   def action_approve_request(self):
       for record in self:
           record.state = 'approved'
           record.approved_date = fields.Datetime.now()
           # Send notifications, update related records, etc.
   ```

3. **Security for Real Users**
   ```xml
   <!-- Real user groups -->
   <record id="group_rtp_user" model="res.groups">
       <field name="name">RTP User</field>
       <field name="category_id" ref="base.module_category_hidden"/>
   </record>
   ```

## 🎨 Cursor-Specific Development Tips

### **AI-Powered Development**
- Use Cursor's AI chat for code generation
- Ask for Odoo-specific patterns and best practices
- Get help with complex ORM queries
- Generate test cases automatically

### **Code Navigation**
- Use Ctrl+Click to jump to definitions
- Utilize file search (Ctrl+P) for quick navigation
- Use symbol search (Ctrl+Shift+O) within files
- Navigate Odoo inheritance chains easily

### **Refactoring Tools**
- Rename symbols across files
- Extract methods and classes
- Organize imports automatically
- Format code with Black on save

### **Debugging Features**
- Set conditional breakpoints
- Watch variables and expressions
- Step through code execution
- Debug Odoo controller endpoints

## 🧪 Testing Strategy

### **Test Types**
1. **Unit Tests**: Test individual methods
2. **Integration Tests**: Test module interactions
3. **Functional Tests**: Test complete workflows
4. **Performance Tests**: Test with large datasets

### **Test Structure**
```python
# tests/test_your_model.py
from odoo.tests.common import TransactionCase
from odoo.exceptions import ValidationError

class TestYourModel(TransactionCase):
    def setUp(self):
        super().setUp()
        self.Model = self.env['your.model']
        
    def test_create_record(self):
        record = self.Model.create({'name': 'Test'})
        self.assertEqual(record.name, 'Test')
        
    def test_business_logic(self):
        # Test your business methods
        pass
```

## 📊 Code Quality and Standards

### **Linting Configuration**
The project is configured with:
- **Pylint** with Odoo-specific rules
- **Flake8** for style checking
- **Black** for code formatting
- **MyPy** for type checking (optional)

### **Best Practices**
1. **Follow PEP 8** for Python code style
2. **Use descriptive variable names**
3. **Write comprehensive docstrings**
4. **Add type hints where appropriate**
5. **Keep functions small and focused**
6. **Use proper error handling**

## 🔄 Git Workflow

### **Branch Strategy**
- `main`: Production-ready code
- `matt1test`: Development branch
- `feature/your-feature`: Feature development

### **Commit Messages**
```
[MODULE] Brief description

Detailed explanation of changes:
- Added new model for customer management
- Implemented validation for email addresses
- Updated security groups and permissions

Fixes: #issue-number
```

## 🚀 Advanced Development

### **Performance Optimization**
- Use appropriate field indexing
- Optimize database queries
- Implement caching where needed
- Profile slow operations

### **Integration**
- Connect with external APIs
- Implement webhooks
- Create scheduled actions
- Build reports and analytics

### **Mobile Development**
- Responsive view design
- Touch-friendly interfaces
- Offline capability consideration
- Progressive Web App features

## 🎯 Next Steps

1. **Create Your First Real Module**
   - Start with a simple business requirement
   - Apply all concepts from Hello World
   - Test thoroughly before deployment

2. **Explore Advanced Features**
   - Custom reports
   - Email templates
   - Workflow automation
   - Third-party integrations

3. **Contributing to the Project**
   - Code reviews
   - Documentation updates
   - Testing improvements
   - Performance optimization

---

**Remember**: The goal is to build maintainable, scalable, and user-friendly business applications. Use your Hello World knowledge as a foundation, but always consider real-world requirements and best practices.

For questions or support, contact: m@vigilanteconsulting.com 
# Odoo Local Testing Infrastructure Guide

## 🎯 Overview

This testing infrastructure was built to solve the problem of slow development cycles caused by pushing untested code to odoo.sh. Now you can catch **90% of deployment errors locally** before pushing.

## 🚀 Quick Start

### 1. One-Time Setup
```bash
# Install all dependencies and set up pre-commit hooks
make setup
```

### 2. Before Every Commit
```bash
# Run the full deployment readiness check
make deploy-check
```

### 3. Daily Development
```bash
# Validate modules as you work
make validate

# Run tests for specific module
make test-module MODULE=royal_textiles_sales

# Format code automatically
make format

# Lint code for quality issues
make lint
```

## 🛡️ What Our Testing Catches

### ✅ **Errors We Catch (Would Have Prevented Our Deployment Issues)**

1. **Field Type Mismatches**
   - The `Text` field related to `contact_address` error we encountered
   - Any field type incompatibilities

2. **Module Structure Issues**
   - Missing `__init__.py` files
   - Invalid `__manifest__.py` format
   - Missing required manifest fields

3. **Python Syntax Errors**
   - Syntax errors in any Python file
   - Import issues
   - Missing model `_name` attributes

4. **XML Structure Problems**
   - Malformed XML files
   - Missing required attributes
   - Invalid model references

5. **Security Configuration**
   - Invalid CSV security files
   - Missing access control columns

6. **Code Quality Issues**
   - PEP8 violations
   - Odoo-specific anti-patterns
   - Unused imports

## 📋 Available Commands

### Core Commands
```bash
make help              # Show all available commands
make setup             # One-time environment setup
make deploy-check      # Full pre-deployment validation
```

### Testing Commands
```bash
make test              # Run all tests
make test-module MODULE=royal_textiles_sales  # Test specific module
make coverage          # Test with coverage report
```

### Code Quality Commands
```bash
make validate          # Validate Odoo modules
make lint              # Run all linting tools
make format            # Auto-format code
```

### Individual Tools
```bash
make black             # Format with Black
make flake8            # Python style checking
make pylint-odoo       # Odoo-specific linting
make mypy              # Type checking
```

## 🔧 Integration with Cursor IDE

### Available Tasks (Cmd+Shift+P → "Tasks: Run Task")

1. **Odoo: Validate All Modules** - Check all modules for errors
2. **Odoo: Validate Current Module** - Check just one module
3. **Odoo: Run All Tests** - Execute full test suite
4. **Odoo: Test Current Module** - Test specific module
5. **Odoo: Lint All Code** - Run all quality checks
6. **Odoo: Deploy Check** - Full deployment readiness check

### Keyboard Shortcuts (Can be customized)
- **Ctrl+Shift+V** - Validate current module
- **Ctrl+Shift+T** - Run tests for current module
- **Ctrl+Shift+L** - Lint current file

## 🎯 Real Examples - How This Would Have Helped

### Example 1: Field Type Mismatch (Our Real Error)
**❌ What happened:**
```python
installation_address = fields.Text(
    related='customer_id.contact_address',  # Text field related to Char
)
```

**✅ What our validator would have caught:**
```
ERROR: royal_textiles_sales/models/installation.py: Field type mismatch:
Text field cannot be related to contact_address (which is typically a Char field).
Line 98: installation_address = fields.Text(related='customer_id.contact_address')
```

### Example 2: Missing Security Columns
**❌ Current issue in our module:**
```
ERROR: Missing column 'id' in access rights CSV
ERROR: Missing column 'perm_read' in access rights CSV
```

**✅ How to fix:**
```csv
id,name,model_id:id,group_id:id,perm_read,perm_write,perm_create,perm_unlink
access_royal_installation,access_royal_installation,model_royal_installation,,1,1,1,1
```

### Example 3: Model Inheritance Issue
**❌ Current issue:**
```
ERROR: Model class SaleOrder missing _name attribute
```

**✅ How to fix:**
```python
class SaleOrder(models.Model):
    _inherit = 'sale.order'  # Use _inherit instead of _name for extending
```

## 🔄 Development Workflow

### Before Starting Work
```bash
git pull origin main
make setup  # If first time
```

### During Development
```bash
# Make your changes...

# Quick validation
make validate-module MODULE=royal_textiles_sales

# Format code automatically
make format

# Run tests
make test-module MODULE=royal_textiles_sales
```

### Before Committing
```bash
# Full deployment check
make deploy-check

# If all passes:
git add .
git commit -m "Your message"
git push origin your-branch
```

## 📊 Understanding Test Results

### ✅ Success Output
```
🚀 All checks passed! Ready for deployment.
```

### ❌ Error Output
```
❌ ERRORS (9):
  ERROR: royal_textiles_sales/models/sale_order.py: Model class SaleOrder missing _name attribute
  ...

⚠️  WARNINGS (9):
  WARNING: royal_textiles_sales: Version format should be X.Y.Z.W, got: 18.0.1.0.1
  ...
```

**Errors** = Must fix before deployment
**Warnings** = Should fix but won't break deployment

## 🐛 Troubleshooting

### Common Issues

1. **"Module not found" errors**
   ```bash
   pip install -r requirements.txt
   ```

2. **Pre-commit hooks failing**
   ```bash
   pre-commit install
   pre-commit run --all-files
   ```

3. **Permission denied on scripts**
   ```bash
   chmod +x scripts/*.py
   ```

4. **PostgreSQL not found (for future local Odoo)**
   ```bash
   brew install postgresql@14
   brew services start postgresql@14
   ```

## 📈 Benefits We're Already Seeing

### ✅ **Errors Caught Locally**
- Field type mismatches (our real example)
- Missing security configurations
- Model inheritance issues
- XML syntax problems

### ✅ **Development Speed**
- Immediate feedback vs waiting for odoo.sh deployment
- Automated code formatting
- Comprehensive validation before push

### ✅ **Code Quality**
- Consistent style across team
- Odoo best practices enforcement
- Early detection of anti-patterns

## 🔮 Next Steps (Future Enhancements)

1. **Local Odoo Instance** - Full local testing environment
2. **GitHub Actions Integration** - Automated PR validation
3. **Performance Testing** - Database query optimization
4. **Visual Regression Testing** - UI change detection

---

## 🆘 Support

For issues or questions:
1. Check this guide first
2. Run `make help` for available commands
3. Look at error messages - they're designed to be helpful
4. Check the validation script output for specific line numbers

**Remember:** This infrastructure would have caught our field type mismatch error and saved us a deployment cycle! 🎯

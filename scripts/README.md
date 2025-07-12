# Development Scripts

This directory contains scripts to help with Odoo development and testing for the Royal Textiles project.

## 🚀 Setup Script

### `setup-dev-environment.sh`

**Primary purpose**: Complete development environment setup including **pre-commit hooks installation**.

**Usage**:
```bash
# From rtp-denver directory
./scripts/setup-dev-environment.sh
```

**What it does**:
1. ✅ Checks system dependencies (Python 3.11+, git, pip, make)
2. ✅ Creates Python virtual environment (`venv/`)
3. ✅ Installs development dependencies from `requirements.txt`
4. ✅ **Installs and configures pre-commit hooks** (Task 1.6)
5. ✅ Validates Royal Textiles module structure
6. ✅ Tests Make targets functionality
7. ✅ Creates development configuration (`.env`)
8. ✅ Provides helpful setup summary and next steps

**Key features**:
- 🎨 Colored output with clear logging
- 🛡️ Error handling and dependency checking
- 🔄 Idempotent (safe to run multiple times)
- 📋 Comprehensive validation and testing
- 🪝 **Automatic pre-commit hooks setup**

## 🔍 Validation Scripts

### `validate-module.py`

Comprehensive Odoo module validation that catches common errors before deployment.

**Usage**:
```bash
python scripts/validate-module.py <module_name>
# Example: python scripts/validate-module.py royal_textiles_sales
```

**What it catches**:
- Manifest file structure and required fields
- Model definition errors (would have caught our field type mismatch)
- Security file format validation
- XML syntax and structure validation
- Common anti-patterns and best practices

### `odoo-type-checker.py`

Custom type checker specifically for Odoo field relationships and definitions.

**Usage**:
```bash
python scripts/odoo-type-checker.py [module_path]
# Example: python scripts/odoo-type-checker.py royal_textiles_sales
```

**What it catches**:
- Field type mismatches (like our original deployment error)
- Missing comodel_name in Many2one fields
- Invalid Selection field definitions
- Computed field configuration issues

### `format-xml.py`

XML formatter for Odoo view files with proper indentation and structure.

**Usage**:
```bash
python scripts/format-xml.py <xml_file>
# Example: python scripts/format-xml.py royal_textiles_sales/views/sale_order_views.xml
```

## 🔄 Development Workflow

**Recommended setup workflow**:
1. Run setup script: `./scripts/setup-dev-environment.sh`
2. Activate virtual environment: `source venv/bin/activate`
3. Start developing with automatic pre-commit validation!

**Daily development workflow**:
```bash
# Make your changes...
git add .
# Pre-commit hooks automatically run validation!
git commit -m "feat: your changes"
# Pre-push hooks run additional checks
git push
```

**Manual validation**:
```bash
make deploy-check    # Full validation suite
make validate        # Module structure validation
make lint           # Code quality checks
make format         # Code formatting
```

## 📋 Integration with Make Targets

All scripts are integrated with the project's Makefile:
- `make setup` - Runs the setup script
- `make validate` - Runs module validation
- `make odoo-type-check` - Runs Odoo type checking
- `make format-xml` - Formats XML files

## 🎯 Pre-commit Hooks (Task 1.6)

The setup script automatically installs comprehensive pre-commit hooks that:
- Run before every commit
- Automatically format code with Black and isort
- Run linting with flake8 and pylint-odoo
- Validate Odoo module structure
- Check for type mismatches
- Format XML files

This ensures code quality and catches deployment errors **before** they reach odoo.sh!

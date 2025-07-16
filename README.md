# Odoo DevKit - Complete Development & Testing Framework
*Professional-grade Odoo development environment with systematic validation and deployment pipeline*

## 🚀 Quick Start (< 5 minutes)

### Prerequisites
- Python 3.10+ (recommended 3.11)
- Docker and Docker Compose
- Git
- VS Code/Cursor IDE

### Instant Setup
```bash
# 1. Clone and enter directory
git clone https://github.com/matthewbergvinson/odoo-devkit.git
cd odoo-devkit

# 2. Set up development environment
chmod +x scripts/setup-dev-environment.sh
./scripts/setup-dev-environment.sh

# 3. Start Odoo environment
make start-odoo

# 4. Validate everything is working
make validate
make test
```

**You're ready to develop!** Open any module in `custom_modules/` and start coding.

---

## 📋 System Overview

This is a **production-ready Odoo development environment** with comprehensive testing, validation, and deployment pipeline. Perfect for developers who want to build high-quality Odoo modules with confidence.

### What's Included
- **Complete Local Odoo Environment** (Docker-based)
- **Advanced Testing Framework** (Unit, Integration, Functional, Performance)
- **Code Quality Pipeline** (Linting, Formatting, Type Checking)
- **Module Validation System** (Odoo-specific validation)
- **Documentation Generation** (API docs, testing procedures)
- **Deployment Readiness Checks** (CI/CD simulation)
- **Cursor IDE Integration** (64+ tasks, 13+ debug configs)

### Key Features
- **Catches 90% of deployment errors** before pushing to production
- **Comprehensive test suite** with base classes and fixtures
- **Automated code quality** checks and formatting
- **Professional documentation** generation
- **Security scanning** and vulnerability detection
- **Performance monitoring** and optimization
- **Complete CI/CD simulation** matching Odoo.sh

---

## 🏗️ Architecture & Directory Structure

```
odoo-devkit/
├── 📁 custom_modules/           # Your Odoo modules go here
│   └── example_module/          # Example module showing best practices
├── 📁 tests/                   # Comprehensive test suite
│   ├── unit/                   # Unit tests
│   ├── integration/            # Integration tests
│   ├── functional/             # Functional tests
│   └── performance/            # Performance tests
├── 📁 scripts/                 # Development and deployment scripts
│   ├── validate-demo-data.py   # Demo data validation script
│   ├── setup-dev-environment.sh # Environment setup
│   └── run-pre-push-checks.sh  # Pre-push validation
├── 📁 docs/                    # Documentation and guides
│   ├── ODOO_18_LESSONS_LEARNED.md  # Key lessons from Royal Textiles project
│   └── ROYAL_TEXTILES_DEMO_DATA_ANALYSIS.md  # Demo data analysis
├── 📁 templates/               # Best practices templates
│   └── demo_data_template.xml  # Demo data template with validation checklist
├── 📁 docker/                  # Docker configurations
├── 📁 reports/                 # Test and validation reports
├── 🗂️ .vscode/                 # VS Code/Cursor configurations
├── 📄 Makefile                 # 45+ automation targets
├── 📄 docker-compose.yml       # Multi-service orchestration
└── 📄 pyproject.toml          # Python project configuration
```

---

## 🛠️ Available Tools & Commands

### Core Development Commands
```bash
# Start/Stop Environment
make start-odoo          # Start complete Odoo environment
make stop-odoo           # Stop all services
make restart-odoo        # Restart Odoo services

# Code Quality
make lint               # Run all linting tools
make format             # Format code (black, isort)
make validate           # Validate Odoo modules
make type-check         # Run type checking

# Testing
make test               # Run all tests
make test-unit          # Run unit tests only
make test-integration   # Run integration tests
make test-coverage      # Run tests with coverage report
make test-performance   # Run performance tests

# Documentation
make docs               # Generate all documentation
make docs-api           # Generate API documentation
make docs-html          # Generate HTML documentation
make docs-serve         # Serve documentation locally

# Deployment Readiness
make deploy-check       # Full deployment readiness check
make security-scan      # Security vulnerability scan
make dependency-check   # Check for outdated dependencies
```

### Validation & Quality Assurance
```bash
# Demo data validation (NEW)
python scripts/validate-demo-data.py path/to/your/module

# Pre-push validation pipeline
./scripts/run-pre-push-checks.sh

# All available make targets (45+)
make help               # Show all available commands
```

---

## 🧪 Testing Framework

### Test Structure
```
tests/
├── unit/              # Fast, isolated tests
├── integration/       # Cross-module tests
├── functional/        # User workflow tests
├── performance/       # Load and performance tests
├── fixtures/          # Test data and factories
└── base_*_test.py    # Base test classes
```

### Writing Tests
```python
# Unit Test Example
from tests.base_model_test import BaseModelTest

class TestMyModel(BaseModelTest):
    def test_create_record(self):
        record = self.env['my.model'].create({
            'name': 'Test Record',
            'value': 100
        })
        self.assertEqual(record.name, 'Test Record')

# Integration Test Example
from tests.base_controller_test import BaseControllerTest

class TestMyWorkflow(BaseControllerTest):
    def test_complete_workflow(self):
        # Test end-to-end business process
        pass
```

### Test Execution
```bash
# Run specific test file
python -m pytest tests/unit/test_my_model.py -v

# Run with coverage
python -m pytest tests/ --cov=custom_modules --cov-report=html

# Run performance tests
python -m pytest tests/performance/ -v
```

---

## 🔧 Module Development

### Creating a New Module
```bash
# 1. Create module structure
mkdir custom_modules/my_new_module
cd custom_modules/my_new_module

# 2. Create basic files
touch __init__.py __manifest__.py

# 3. Create subdirectories
mkdir models views controllers data security tests

# 4. Validate structure
make validate

# 5. Add to git and commit
git add .
git commit -m "feat: create my_new_module skeleton"
```

### Module Structure
```
my_module/
├── __init__.py              # Module initialization
├── __manifest__.py          # Module metadata
├── models/
│   ├── __init__.py
│   └── my_model.py         # Business logic
├── views/
│   └── my_views.xml        # UI definitions
├── controllers/
│   ├── __init__.py
│   └── my_controller.py    # HTTP endpoints
├── data/
│   └── my_data.xml         # Initial data
├── security/
│   ├── ir.model.access.csv # Access rights
│   └── my_security.xml     # Security rules
├── tests/
│   ├── __init__.py
│   └── test_my_model.py    # Unit tests
└── static/
    └── description/
        └── icon.png        # Module icon
```

---

## 🎯 Development Workflows

### Daily Development Cycle
```bash
# 1. Make changes to your module
# 2. Run validation
make validate

# 3. Run tests
make test

# 4. Check code quality
make lint

# 5. Generate documentation
make docs

# 6. Deploy readiness check
make deploy-check
```

### Before Every Commit
```bash
make format                 # Format code
make lint                   # Check quality
make validate               # Validate modules
make test                   # Run tests
git add .
git commit -m "feat: description"
```

### Before Deployment
```bash
make deploy-check           # Full validation
make docs                   # Generate docs
make security-scan          # Security check
# If all pass, deploy!
```

---

## 🔍 Code Quality & Validation

### Linting Tools
- **flake8**: Code style and error detection
- **pylint**: Advanced code analysis
- **mypy**: Type checking
- **black**: Code formatting
- **isort**: Import organization

### Odoo-Specific Validation
```bash
# Validate module structure
python scripts/validate-module.py custom_modules/my_module

# Validate manifest files
python scripts/validate-manifest.py custom_modules/my_module/__manifest__.py

# Validate demo data against models (NEW)
python scripts/validate-demo-data.py custom_modules/my_module

# Format XML files
python scripts/format-xml.py custom_modules/my_module/views/

# Check for anti-patterns
python scripts/odoo-type-checker.py custom_modules/my_module
```

### Pre-commit Hooks
Automatically runs on every commit:
- Code formatting
- Import sorting
- Basic validation
- Commit message formatting

---

## 📚 Documentation Generation

### API Documentation
```bash
# Generate comprehensive API docs
make docs-api

# Generate HTML documentation
make docs-html

# Serve documentation locally
make docs-serve
```

### Documentation Structure
```
docs/
├── generated/          # Auto-generated documentation
├── guides/            # Development guides
├── api/               # API documentation
└── testing/           # Testing documentation
```

### Generated Documentation Includes
- **Model Documentation**: Fields, methods, relationships
- **Controller Documentation**: Routes, parameters, responses
- **View Documentation**: XML structure and components
- **Test Documentation**: Coverage and procedures
- **API Reference**: Complete module APIs

---

## 🐳 Docker Environment

### Services
- **Odoo**: Main application server
- **PostgreSQL**: Database server
- **pgAdmin**: Database management UI

### Environment Management
```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f odoo

# Access containers
docker-compose exec odoo bash
docker-compose exec postgres psql -U odoo

# Database management
make db-backup
make db-restore
```

---

## 🚦 Deployment Readiness

### Full Deployment Check
```bash
make deploy-check
```

This runs:
- ✅ Git status validation
- ✅ Code quality checks
- ✅ Test suite execution
- ✅ Module validation
- ✅ Security scanning
- ✅ Dependency checking
- ✅ Documentation generation
- ✅ Deployment simulation

### CI/CD Simulation
```bash
# Simulate Odoo.sh deployment
make simulate-odoo-sh

# Check deployment readiness
make readiness-check
```

### Security Scanning
```bash
# Full security scan
make security-scan

# Dependency vulnerabilities
make dependency-scan

# License compliance
make license-scan
```

---

## 🔧 Cursor IDE Integration

### Debug Configurations (13 available)
- **Odoo Server Debug**: Full server debugging
- **Module Debug**: Debug specific modules
- **Test Debug**: Debug test execution
- **Performance Debug**: Profile performance issues

### Tasks (64+ available)
- **Development Tasks**: Start/stop services, run tests
- **Validation Tasks**: Lint, format, validate
- **Documentation Tasks**: Generate docs, serve locally
- **Deployment Tasks**: Check readiness, simulate CI/CD

### Code Snippets
- **Odoo Model**: Quick model creation
- **Odoo View**: XML view templates
- **Test Cases**: Test method templates
- **Controller**: HTTP controller templates

---

## 📊 Monitoring & Reports

### Test Reports
```bash
# Generate HTML coverage report
make test-coverage

# Open coverage report
make test-report-open

# Generate performance report
make performance-report
```

### Code Quality Reports
```bash
# Generate lint report
make lint-report

# Generate security report
make security-report

# View all reports
make reports-open
```

### Report Locations
- **Test Coverage**: `reports/coverage/`
- **Security Scans**: `reports/security/`
- **Performance**: `reports/performance/`
- **Documentation**: `docs/generated/`

---

## 🚨 Troubleshooting

### Common Issues

#### Docker Issues
```bash
# Docker daemon not running
brew services start docker

# Port conflicts
docker-compose down
docker-compose up -d

# Database connection issues
make db-reset
```

#### Python Issues
```bash
# Wrong Python version
pyenv install 3.11
pyenv local 3.11

# Missing dependencies
pip install -r requirements.txt
pip install -r local-odoo/requirements.txt
```

#### Test Issues
```bash
# Tests failing
make test-unit -v
# Check individual test output

# Coverage issues
make test-coverage
# Open HTML report for details
```

### Getting Help
```bash
# Show available commands
make help

# Validate current state
make validate

# Check system status
make status

# Generate diagnostic report
make diagnostic
```

---

## 🔄 Development Best Practices

### Code Organization
1. **One concern per file**
2. **Clear naming conventions**
3. **Comprehensive docstrings**
4. **Type hints everywhere**
5. **Test coverage > 90%**

### Commit Workflow
```bash
# 1. Make changes
# 2. Run validation
make validate

# 3. Run tests
make test

# 4. Format code
make format

# 5. Commit (pre-commit hooks run automatically)
git commit -m "feat: add new feature"

# 6. Push (pre-push hooks run automatically)
git push
```

### Release Workflow
```bash
# 1. Full validation
make deploy-check

# 2. Generate documentation
make docs

# 3. Security scan
make security-scan

# 4. Create release
git tag v1.0.0
git push origin v1.0.0
```

---

## 📞 Support & Resources

### Documentation
- **Quick Reference**: `QUICK_REFERENCE.md`
- **System Reference**: `SYSTEM_REFERENCE.md`
- **API Reference**: `docs/api/`
- **Testing Guide**: `docs/testing/`

### External Resources
- **Odoo Documentation**: https://www.odoo.com/documentation/
- **Python Testing**: https://docs.pytest.org/
- **Docker**: https://docs.docker.com/
- **Demo Data Best Practices**: `docs/ODOO_18_LESSONS_LEARNED.md`
- **Validation Examples**: `docs/ROYAL_TEXTILES_DEMO_DATA_ANALYSIS.md`

### Example Module
Check out the `custom_modules/example_module/` for a complete example showing:
- Proper module structure
- Model creation with relationships
- Views and controllers
- Comprehensive testing
- Documentation generation

---

## 📄 License & Contributing

This project is open source and available under the MIT License.

### Contributing
1. Fork the repository
2. Create feature branch
3. Run full test suite
4. Submit pull request

### System Health
```bash
# Check overall system health
make health-check

# Validate all components
make system-validate

# Performance benchmark
make benchmark
```

---

**🎯 Ready to build amazing Odoo modules!**

Start with `make help` to see all available commands, then dive into `custom_modules/` to begin development.

## 🌟 Features at a Glance

- ✅ **Complete Odoo Environment** - Docker-based, production-ready
- ✅ **Advanced Testing** - Unit, integration, functional, performance
- ✅ **Code Quality** - Automated linting, formatting, type checking
- ✅ **Documentation** - Auto-generated API docs and guides
- ✅ **Security** - Vulnerability scanning and compliance checks
- ✅ **IDE Integration** - 64+ VS Code tasks and debug configurations
- ✅ **Deployment Ready** - CI/CD simulation and readiness checks
- ✅ **Example Module** - Complete reference implementation

**Get started in under 5 minutes and build Odoo modules with confidence!**

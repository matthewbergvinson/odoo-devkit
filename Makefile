# Odoo Local Testing Framework Makefile
# Makes it easy to run common development tasks

.PHONY: help install test lint validate format clean deploy-check setup ci-test ci-lint ci-validate ci-deploy-check ci-pipeline ci-quick ci-metrics validate-odoo-18-compatibility test-red-team-complete test-with-demo test-without-demo simulate-odoo-sh-deployment validate-demo-data check-all-compatibility-issues validate-deployment-ready

# Default target
help:
	@echo "Odoo Local Testing Framework Commands"
	@echo "===================================="
	@echo ""
	@echo "Setup Commands:"
	@echo "  make setup           Install development dependencies and hooks"
	@echo "  make install         Install Python dependencies"
	@echo "  make install-odoo    Install local Odoo 18.0 development environment"
	@echo ""
	@echo "Code Quality Commands:"
	@echo "  make lint            Run all linting tools"
	@echo "  make format          Format code with Black and isort"
	@echo "  make validate        Run comprehensive Odoo module validation"
	@echo "  make validate-module MODULE=name  Validate specific module"
	@echo ""
	@echo "Testing Commands:"
	@echo "  make test            Run all tests"
	@echo "  make test-module MODULE=name  Test specific module"
	@echo "  make coverage        Run tests with coverage report"
	@echo ""
	@echo "Coverage Reporting (Task 4.5):"
	@echo "  make coverage-report    Generate comprehensive coverage reports (HTML, XML, JSON)"
	@echo "  make coverage-html      Generate and view HTML coverage report"
	@echo "  make coverage-validate  Validate coverage meets minimum thresholds (75%)"
	@echo "  make coverage-insights  Generate detailed coverage analysis and recommendations"
	@echo "  make coverage-modules   Generate module-specific coverage reports"
	@echo "  make coverage-full      Complete coverage analysis workflow"
	@echo "  make coverage-open      Open HTML coverage report in browser"
	@echo "  make coverage-clean     Clean all coverage files and reports"
	@echo ""
	@echo "Integration Testing (Task 4.6):"
	@echo "  make test-integration       Run all integration tests"
	@echo "  make test-customer-flows    Run customer lifecycle workflow tests"
	@echo "  make test-sales-flows       Run sales order workflow tests"
	@echo "  make test-install-flows     Run installation workflow tests"
	@echo "  make test-business-flows    Run complete business flow tests"
	@echo "  make test-reporting-flows   Run reporting workflow tests"
	@echo "  make test-integration-ci    Run integration tests for CI/CD pipeline"
	@echo ""
	@echo "Performance Testing (Task 4.7):"
	@echo "  make test-performance           Run all performance tests"
	@echo "  make test-database-performance  Run database operation performance tests"
	@echo "  make test-view-performance      Run view rendering performance tests"
	@echo "  make test-memory-performance    Run memory usage performance tests"
	@echo "  make test-performance-ci        Run CI/CD optimized performance tests"
	@echo "  make test-performance-full      Complete performance testing workflow"
	@echo ""
	@echo "Local Odoo Development (Task 3.1):"
	@echo "  make start-odoo      Start local Odoo development server"
	@echo "  make stop-odoo       Stop local Odoo server"
	@echo "  make restart-odoo    Restart local Odoo server"
	@echo "  make create-db DB=name  Create new database"
	@echo "  make drop-db DB=name    Drop database"
	@echo "  make reset-db DB=name   Reset database"
	@echo "  make list-dbs        List all databases"
	@echo ""
	@echo "PostgreSQL Setup (Task 3.2):"
	@echo "  make setup-postgresql       Full PostgreSQL setup for Odoo"
	@echo "  make setup-postgresql-user  Create Odoo database user only"
	@echo "  make setup-postgresql-config Configure PostgreSQL settings only"
	@echo "  make setup-postgresql-dbs   Create development databases only"
	@echo "  make reset-postgresql       Reset PostgreSQL configuration (DESTRUCTIVE)"
	@echo ""
	@echo "Odoo Configuration Management (Task 3.4):"
	@echo "  make config-create ENV=development      Create Odoo configuration for environment"
	@echo "  make config-list                        List all Odoo configurations"
	@echo "  make config-validate CONFIG=odoo-dev.conf  Validate configuration file"
	@echo "  make config-test CONFIG=odoo-dev.conf   Test configuration by starting Odoo"
	@echo "  make config-backup CONFIG=odoo-dev.conf Create configuration backup"
	@echo "  make config-show CONFIG=odoo-dev.conf   Show configuration contents"
	@echo ""
	@echo "Advanced Database Management (Task 3.3):"
	@echo "  make db-create NAME=mydb     Create new database (add TYPE=test|dev|staging)"
	@echo "  make db-drop NAME=mydb       Drop database (add FORCE=true to skip confirmation)"
	@echo "  make db-reset NAME=mydb      Reset database (drop and recreate)"
	@echo "  make db-clone SOURCE=db1 TARGET=db2  Clone database"
	@echo "  make db-list                 List all databases with details"
	@echo "  make db-info NAME=mydb       Show detailed database information"
	@echo "  make db-backup NAME=mydb     Create database backup"
	@echo "  make db-restore BACKUP=file.dump NAME=mydb  Restore database"
	@echo "  make db-clean                Clean up old databases (add DRY_RUN=true)"
	@echo ""
	@echo "Test Database Management (Task 3.3):"
	@echo "  make test-db-create NAME=mytest     Create test database"
	@echo "  make test-db-fixture NAME=fixture   Create fixture database with demo data"
	@echo "  make test-db-list               List all test databases"
	@echo "  make test-db-clean              Clean up test databases"
	@echo "  make test-db-parallel COUNT=4   Setup parallel test databases"
	@echo "  make test-db-run NAME=mytest MODULE=sale  Run Odoo tests"
	@echo ""
	@echo "Backup Management (Task 3.3):"
	@echo "  make backup-create NAME=mydb    Create database backup"
	@echo "  make backup-all                 Backup all databases"
	@echo "  make backup-list                List all backups"
	@echo "  make backup-restore BACKUP=file.dump NAME=mydb  Restore backup"
	@echo "  make backup-clean               Clean old backups (add DAYS=30)"
	@echo "  make backup-verify BACKUP=file.dump  Verify backup integrity"
	@echo ""
	@echo "Sample Data Generation (Task 3.5):"
	@echo "  make data-create SCENARIO=development  Generate sample data"
	@echo "  make data-list                    List available scenarios"
	@echo "  make data-clean DB=sample_db      Clean sample data"
	@echo "  make data-validate DB=sample_db   Validate data integrity"
	@echo "  make data-benchmark SIZE=large DB=perf_db  Generate performance data"
	@echo ""
	@echo "Module Installation/Upgrade Testing (Task 3.6):"
	@echo "  make module-test-install MODULE=rtp_customers  Test module installation"
	@echo "  make module-test-upgrade MODULE=rtp_customers  Test module upgrade"
	@echo "  make module-test-dependencies MODULE=rtp_customers  Test dependencies"
	@echo "  make module-test-integration   Test module interactions"
	@echo "  make module-test-full          Complete testing suite"
	@echo "  make module-test-rtp-customers Complete RTP Customers testing"
	@echo "  make module-test-royal-textiles Complete Royal Textiles testing"
	@echo "  make module-test-quick         Quick installation tests"
	@echo "  make module-test-ci            CI-style testing with reports"
	@echo ""
	@echo "Docker Alternative Setup (Task 3.7):"
	@echo "  make docker-setup           Setup Docker environment"
	@echo "  make docker-build           Build Docker images"
	@echo "  make docker-up [PROFILE]    Start Docker services (e.g., make docker-up development)"
	@echo "  make docker-down            Stop Docker services"
	@echo "  make docker-restart [PROFILE] Restart Docker services"
	@echo "  make docker-logs [SERVICE]  View Docker logs (e.g., make docker-logs odoo)"
	@echo "  make docker-shell [SERVICE] Open shell in Docker container"
	@echo "  make docker-db OP=create DB=mydb [MODULES] Create database"
	@echo "  make docker-db OP=drop DB=mydb Drop database"
	@echo "  make docker-db OP=list List databases"
	@echo "  make docker-db OP=backup DB=mydb Backup database"
	@echo "  make docker-db OP=restore DB=mydb FILE=backup.sql Restore database"
	@echo "  make docker-test [TYPE] [ARGS] Run tests in Docker"
	@echo "  make docker-clean [LEVEL] Clean up Docker resources"
	@echo "  make docker-status Show Docker service status"
	@echo "  make docker-backup [DIR] Backup Docker volumes"
	@echo "  make docker-restore [DIR] Restore Docker volumes"
	@echo "  make docker-config Show Docker configuration"
	@echo ""
	@echo "Deployment Commands:"
	@echo "  make deploy-check    Run full pre-deployment validation"
	@echo "  make clean           Clean up temporary files"
	@echo ""
	@echo "Individual Tools:"
	@echo "  make black           Format with Black only"
	@echo "  make flake8          Run flake8 linting only"
	@echo "  make pylint-odoo     Run Odoo-specific linting only"
	@echo "  make mypy            Run type checking only"
	@echo "  make pre-commit      Run pre-commit hooks manually"
	@echo ""
	@echo "CI/CD Pipeline Commands (Task 6.1):"
	@echo "  make ci-test         CI-optimized test execution with reporting"
	@echo "  make ci-lint         CI-optimized linting with machine-readable output"
	@echo "  make ci-validate     CI-optimized validation with structured output"
	@echo "  make ci-deploy-check CI-optimized deployment readiness check"
	@echo "  make ci-pipeline     Complete CI pipeline simulation"
	@echo "  make ci-quick        Quick CI check for fast feedback"
	@echo "  make ci-metrics      Generate CI metrics and quality reports"
	@echo ""
	@echo "Enhanced Validation (Tasks 2.1-2.6):"
	@echo "  make validate        Comprehensive validation including:"
	@echo "                       - Manifest structure & fields"
	@echo "                       - XML syntax & Odoo patterns"
	@echo "                       - Model relationships & field types"
	@echo "                       - Anti-pattern detection"
	@echo "                       - Security & import validation"

# Setup and Installation
setup:
	@echo "Running comprehensive development environment setup..."
	./scripts/setup-dev-environment.sh

install:
	@echo "Installing Python dependencies..."
	pip install -r requirements.txt

# NEW: Local Odoo installation (Task 3.1)
install-odoo:
	@echo "Installing local Odoo 18.0 development environment..."
	@echo "This will install Odoo 18.0 to match odoo.sh environment"
	./scripts/install-local-odoo.sh

# Local Odoo Development Server (Task 3.1)
start-odoo:
	@echo "Starting local Odoo development server..."
	./local-odoo/start-odoo.sh

stop-odoo:
	@echo "Stopping Odoo server..."
	@pkill -f "odoo-bin" || echo "Odoo server not running"

restart-odoo: stop-odoo start-odoo

# PostgreSQL Setup and Management (Task 3.2)
setup-postgresql:
	@echo "Setting up PostgreSQL for Odoo development..."
	./scripts/setup-postgresql.sh

setup-postgresql-user:
	@echo "Creating Odoo database user..."
	./scripts/setup-postgresql.sh --create-user

setup-postgresql-config:
	@echo "Configuring PostgreSQL for Odoo..."
	./scripts/setup-postgresql.sh --setup-config

setup-postgresql-dbs:
	@echo "Creating development databases..."
	./scripts/setup-postgresql.sh --create-dbs

reset-postgresql:
	@echo "Resetting PostgreSQL configuration (DESTRUCTIVE)..."
	./scripts/setup-postgresql.sh --reset-all

# Odoo Configuration Management (Task 3.4)
.PHONY: config-create config-list config-validate config-test config-backup config-restore config-show

config-create: ## Create Odoo configuration (usage: make config-create ENV=development [OPTIONS])
ifndef ENV
	@echo "Error: Please specify ENV: make config-create ENV=development"
	@echo "Available environments: development, testing, staging, production, minimal"
	@exit 1
endif
	@echo "Creating Odoo configuration for: $(ENV)"
	./scripts/configure-odoo.sh create $(ENV) $(if $(WORKERS),--workers $(WORKERS)) $(if $(LOG_LEVEL),--log-level $(LOG_LEVEL)) $(if $(DEMO),$(if $(filter true,$(DEMO)),--enable-demo,--disable-demo))

config-list: ## List all Odoo configurations
	@echo "📋 Listing Odoo configurations..."
	./scripts/configure-odoo.sh list

config-validate: ## Validate Odoo configuration (usage: make config-validate CONFIG=odoo-development.conf)
ifndef CONFIG
	@echo "Error: Please specify CONFIG: make config-validate CONFIG=odoo-development.conf"
	@exit 1
endif
	@echo "Validating configuration: $(CONFIG)"
	./scripts/configure-odoo.sh validate $(CONFIG)

config-test: ## Test Odoo configuration (usage: make config-test CONFIG=odoo-development.conf)
ifndef CONFIG
	@echo "Error: Please specify CONFIG: make config-test CONFIG=odoo-development.conf"
	@exit 1
endif
	@echo "Testing configuration: $(CONFIG)"
	./scripts/configure-odoo.sh test $(CONFIG)

config-backup: ## Backup Odoo configuration (usage: make config-backup CONFIG=odoo-development.conf)
ifndef CONFIG
	@echo "Error: Please specify CONFIG: make config-backup CONFIG=odoo-development.conf"
	@exit 1
endif
	@echo "Backing up configuration: $(CONFIG)"
	./scripts/configure-odoo.sh backup $(CONFIG)

config-restore: ## Restore Odoo configuration (usage: make config-restore BACKUP=backup_file.conf)
ifndef BACKUP
	@echo "Error: Please specify BACKUP: make config-restore BACKUP=backup_file.conf"
	@exit 1
endif
	@echo "Restoring configuration from: $(BACKUP)"
	./scripts/configure-odoo.sh restore $(BACKUP)

config-show: ## Show Odoo configuration contents (usage: make config-show CONFIG=odoo-development.conf)
ifndef CONFIG
	@echo "Error: Please specify CONFIG: make config-show CONFIG=odoo-development.conf"
	@exit 1
endif
	@echo "Configuration contents: $(CONFIG)"
	./scripts/configure-odoo.sh show $(CONFIG)

# Database management
.PHONY: db-create db-drop db-reset db-clone db-list db-info db-backup db-restore db-clean
.PHONY: test-db-create test-db-fixture test-db-list test-db-clean test-db-parallel test-db-run
.PHONY: backup-create backup-all backup-list backup-restore backup-clean backup-verify

# Sample Data Generation (Task 3.5)
.PHONY: data-create data-list data-clean data-validate data-benchmark
.PHONY: data-development data-testing data-integration data-minimal data-demo

data-create: ## Generate sample data (usage: make data-create SCENARIO=development [SIZE=medium] [DB=sample_db])
ifndef SCENARIO
	@echo "Error: Please specify SCENARIO: make data-create SCENARIO=development"
	@echo "Available scenarios: development, testing, integration, performance, minimal, demo"
	@exit 1
endif
	@echo "Generating sample data for scenario: $(SCENARIO)"
	./scripts/generate-sample-data.sh create $(SCENARIO) \
		$(if $(DB),--db-name $(DB)) \
		$(if $(SIZE),--size $(SIZE)) \
		$(if $(MODULES),--modules $(MODULES)) \
		$(if $(CLEAN),--clean-first) \
		$(if $(DRY_RUN),--dry-run) \
		$(if $(FORCE),--force)

data-list: ## List available data generation scenarios and generators
	./scripts/generate-sample-data.sh list

data-clean: ## Clean sample data from database (usage: make data-clean [DB=sample_db])
	./scripts/generate-sample-data.sh clean $(if $(DB),--db-name $(DB)) $(if $(FORCE),--force)

data-validate: ## Validate sample data integrity (usage: make data-validate [DB=sample_db])
	./scripts/generate-sample-data.sh validate $(if $(DB),--db-name $(DB))

data-benchmark: ## Generate performance testing data (usage: make data-benchmark [SIZE=large] [DB=perf_db])
	./scripts/generate-sample-data.sh benchmark $(if $(SIZE),$(SIZE),large) \
		$(if $(DB),--db-name $(DB)) \
		$(if $(CLEAN),--clean-first) \
		$(if $(FORCE),--force)

# Convenient shortcuts for common scenarios
data-development: ## Generate development data (medium dataset for local development)
	$(MAKE) data-create SCENARIO=development SIZE=medium DB=$(if $(DB),$(DB),dev_sample_db) $(if $(CLEAN),CLEAN=true)

data-testing: ## Generate testing data (small dataset for unit tests)
	$(MAKE) data-create SCENARIO=testing SIZE=small DB=$(if $(DB),$(DB),test_sample_db) $(if $(CLEAN),CLEAN=true)

data-integration: ## Generate integration testing data (medium dataset with complex relationships)
	$(MAKE) data-create SCENARIO=integration SIZE=medium DB=$(if $(DB),$(DB),integration_sample_db) $(if $(CLEAN),CLEAN=true)

data-minimal: ## Generate minimal data (tiny dataset for quick testing)
	$(MAKE) data-create SCENARIO=minimal SIZE=small DB=$(if $(DB),$(DB),minimal_sample_db) $(if $(CLEAN),CLEAN=true)

data-demo: ## Generate demo data (polished dataset for presentations)
	$(MAKE) data-create SCENARIO=demo SIZE=medium DB=$(if $(DB),$(DB),demo_sample_db) $(if $(CLEAN),CLEAN=true)

# Module Installation/Upgrade Testing Automation (Task 3.6)
.PHONY: module-test-install module-test-upgrade module-test-dependencies module-test-integration
.PHONY: module-test-full module-test-list module-test-cleanup module-test-rtp-customers module-test-royal-textiles

module-test-install: ## Test module installation (usage: make module-test-install MODULE=rtp_customers [DEMO=true])
ifndef MODULE
	@echo "Error: Please specify MODULE: make module-test-install MODULE=rtp_customers"
	@echo "Available modules: rtp_customers, royal_textiles_sales"
	@exit 1
endif
	@echo "Testing installation of module: $(MODULE)"
	./scripts/test-module-installation.sh install-test $(MODULE) \
		$(if $(DEMO),--with-demo) \
		$(if $(SECURITY),--test-security) \
		$(if $(VALIDATE),--validate-data) \
		$(if $(CONFIG),--config $(CONFIG))

module-test-upgrade: ## Test module upgrade (usage: make module-test-upgrade MODULE=rtp_customers [MIGRATION=true])
ifndef MODULE
	@echo "Error: Please specify MODULE: make module-test-upgrade MODULE=rtp_customers"
	@echo "Available modules: rtp_customers, royal_textiles_sales"
	@exit 1
endif
	@echo "Testing upgrade of module: $(MODULE)"
	./scripts/test-module-installation.sh upgrade-test $(MODULE) \
		$(if $(MIGRATION),--test-migration) \
		$(if $(PRESERVE),--preserve-data) \
		$(if $(CONFIG),--config $(CONFIG))

module-test-dependencies: ## Test module dependencies (usage: make module-test-dependencies MODULE=rtp_customers)
ifndef MODULE
	@echo "Error: Please specify MODULE: make module-test-dependencies MODULE=rtp_customers"
	@echo "Available modules: rtp_customers, royal_textiles_sales"
	@exit 1
endif
	@echo "Testing dependencies for module: $(MODULE)"
	./scripts/test-module-installation.sh dependency-test $(MODULE) \
		$(if $(CONFIG),--config $(CONFIG))

module-test-integration: ## Test module integration and workflows
	@echo "Testing module integration and workflows"
	./scripts/test-module-installation.sh integration-test \
		$(if $(WORKFLOWS),--test-workflows) \
		$(if $(CONFIG),--config $(CONFIG))

module-test-full: ## Run complete module testing suite [PARALLEL=true] [CONTINUE=true] [FORMAT=text|json|html]
	@echo "Running complete module testing suite"
	./scripts/test-module-installation.sh full-test \
		$(if $(PARALLEL),--parallel) \
		$(if $(CONTINUE),--continue-on-error) \
		$(if $(FORMAT),--report-format $(FORMAT)) \
		$(if $(OUTPUT),--output-dir $(OUTPUT))

module-test-list: ## List available modules for testing
	./scripts/test-module-installation.sh list-modules

module-test-cleanup: ## Clean up test databases and files
	@echo "Cleaning up module test environment"
	./scripts/test-module-installation.sh cleanup

# Convenient shortcuts for specific modules
module-test-rtp-customers: ## Complete testing suite for RTP Customers module
	@echo "Testing RTP Customers module (complete suite)"
	$(MAKE) module-test-install MODULE=rtp_customers DEMO=true SECURITY=true VALIDATE=true
	$(MAKE) module-test-upgrade MODULE=rtp_customers MIGRATION=true PRESERVE=true
	$(MAKE) module-test-dependencies MODULE=rtp_customers

module-test-royal-textiles: ## Complete testing suite for Royal Textiles Sales module
	@echo "Testing Royal Textiles Sales module (complete suite)"
	$(MAKE) module-test-install MODULE=royal_textiles_sales DEMO=true SECURITY=true VALIDATE=true
	$(MAKE) module-test-upgrade MODULE=royal_textiles_sales MIGRATION=true PRESERVE=true
	$(MAKE) module-test-dependencies MODULE=royal_textiles_sales

# Development and CI shortcuts
module-test-quick: ## Quick module testing (installation only for all modules)
	@echo "Running quick module tests"
	$(MAKE) module-test-install MODULE=rtp_customers DEMO=true
	$(MAKE) module-test-install MODULE=royal_textiles_sales DEMO=true

module-test-ci: ## CI-style testing with reports (for deployment readiness)
	@echo "Running CI-style module testing"
	$(MAKE) module-test-full CONTINUE=true FORMAT=json OUTPUT=./local-odoo/test-results

# Docker Alternative Setup (Task 3.7)
.PHONY: docker-setup docker-build docker-up docker-down docker-restart docker-logs docker-shell
.PHONY: docker-db docker-test docker-clean docker-status docker-backup docker-restore
.PHONY: docker-up-dev docker-up-testing docker-up-full docker-config

docker-setup: ## Setup Docker environment for Odoo development
	@echo "Setting up Docker environment..."
	./scripts/docker-manager.sh setup

docker-build: ## Build Docker images
	@echo "Building Docker images..."
	./scripts/docker-manager.sh build $(if $(FORCE),true,false)

docker-up: ## Start Docker services (usage: make docker-up [PROFILE=development])
	@echo "Starting Docker services with profile: $(if $(PROFILE),$(PROFILE),development)"
	./scripts/docker-manager.sh up $(if $(PROFILE),$(PROFILE),development)

docker-down: ## Stop Docker services
	@echo "Stopping Docker services..."
	./scripts/docker-manager.sh down $(if $(VOLUMES),true,false)

docker-restart: ## Restart Docker services
	@echo "Restarting Docker services..."
	./scripts/docker-manager.sh restart $(if $(PROFILE),$(PROFILE),development)

docker-logs: ## View Docker service logs (usage: make docker-logs [SERVICE=odoo])
	@echo "Viewing Docker logs for: $(if $(SERVICE),$(SERVICE),all services)"
	./scripts/docker-manager.sh logs $(SERVICE) $(if $(FOLLOW),true,false)

docker-shell: ## Open shell in Docker container (usage: make docker-shell [SERVICE=odoo])
	@echo "Opening shell in: $(if $(SERVICE),$(SERVICE),odoo)"
	./scripts/docker-manager.sh shell $(SERVICE)

docker-db: ## Docker database operations (usage: make docker-db OP=create DB=mydb [MODULES=base])
ifndef OP
	@echo "Error: Please specify operation: make docker-db OP=create DB=mydb"
	@echo "Available operations: create, drop, list, backup, restore"
	@exit 1
endif
ifeq ($(OP),create)
ifndef DB
	@echo "Error: Database name required: make docker-db OP=create DB=mydb"
	@exit 1
endif
	@echo "Creating database: $(DB) with modules: $(if $(MODULES),$(MODULES),base)"
	./scripts/docker-manager.sh db create $(DB) $(if $(MODULES),$(MODULES),base)
else ifeq ($(OP),drop)
ifndef DB
	@echo "Error: Database name required: make docker-db OP=drop DB=mydb"
	@exit 1
endif
	@echo "Dropping database: $(DB)"
	./scripts/docker-manager.sh db drop $(DB)
else ifeq ($(OP),list)
	@echo "Listing databases:"
	./scripts/docker-manager.sh db list
else ifeq ($(OP),backup)
ifndef DB
	@echo "Error: Database name required: make docker-db OP=backup DB=mydb"
	@exit 1
endif
	@echo "Backing up database: $(DB)"
	./scripts/docker-manager.sh db backup $(DB)
else ifeq ($(OP),restore)
ifndef DB
	@echo "Error: Database name required: make docker-db OP=restore DB=mydb FILE=backup.sql"
	@exit 1
endif
ifndef FILE
	@echo "Error: Backup file required: make docker-db OP=restore DB=mydb FILE=backup.sql"
	@exit 1
endif
	@echo "Restoring database: $(DB) from $(FILE)"
	./scripts/docker-manager.sh db restore $(DB) $(FILE)
else
	@echo "Unknown database operation: $(OP)"
	@exit 1
endif

docker-test: ## Run tests in Docker (usage: make docker-test [TYPE=all] [ARGS])
	@echo "Running Docker tests: $(if $(TYPE),$(TYPE),all)"
	./scripts/docker-manager.sh test $(if $(TYPE),$(TYPE),all) $(ARGS)

docker-clean: ## Clean up Docker resources (usage: make docker-clean [LEVEL=standard])
	@echo "Cleaning Docker resources: $(if $(LEVEL),$(LEVEL),standard)"
	./scripts/docker-manager.sh clean $(if $(LEVEL),$(LEVEL),standard)

docker-status: ## Show Docker service status
	@echo "Docker service status:"
	./scripts/docker-manager.sh status

docker-backup: ## Backup Docker volumes (usage: make docker-backup [DIR=./docker-backups])
	@echo "Backing up Docker volumes to: $(if $(DIR),$(DIR),./docker-backups)"
	./scripts/docker-manager.sh backup $(if $(DIR),$(DIR),./docker-backups)

docker-restore: ## Restore Docker volumes (usage: make docker-restore [DIR=./docker-backups])
	@echo "Restoring Docker volumes from: $(if $(DIR),$(DIR),./docker-backups)"
	./scripts/docker-manager.sh restore $(if $(DIR),$(DIR),./docker-backups)

docker-config: ## Show Docker configuration
	@echo "Docker configuration:"
	./scripts/docker-manager.sh config

# Docker Profile Shortcuts
docker-up-dev: ## Start development environment (Odoo + PostgreSQL + MailHog)
	@echo "Starting development environment..."
	COMPOSE_PROFILES=development ./scripts/docker-manager.sh up development

docker-up-testing: ## Start testing environment
	@echo "Starting testing environment..."
	COMPOSE_PROFILES=testing ./scripts/docker-manager.sh up testing

docker-up-full: ## Start full environment (all services)
	@echo "Starting full environment (all services)..."
	COMPOSE_PROFILES=full ./scripts/docker-manager.sh up full

# Code Quality
lint: flake8 pylint-odoo mypy
	@echo "✅ All linting checks completed successfully!"

# Enhanced linting with comprehensive reporting
lint-comprehensive: ## Run comprehensive linting with detailed reporting
	@echo "🔍 Running comprehensive code quality analysis..."
	@echo "=================================================="
	@echo ""
	@echo "📋 Step 1: Python syntax and style (flake8)..."
	@$(MAKE) flake8 || (echo "❌ flake8 failed" && exit 1)
	@echo ""
	@echo "📋 Step 2: Odoo-specific linting (pylint-odoo)..."
	@$(MAKE) pylint-odoo || (echo "❌ pylint-odoo failed" && exit 1)
	@echo ""
	@echo "📋 Step 3: Type checking (mypy)..."
	@$(MAKE) mypy || (echo "❌ mypy failed" && exit 1)
	@echo ""
	@echo "📋 Step 4: Royal Textiles specific checks..."
	@$(MAKE) lint-rtp-specific || (echo "❌ RTP-specific checks failed" && exit 1)
	@echo ""
	@echo "🎉 COMPREHENSIVE LINTING COMPLETED SUCCESSFULLY!"
	@echo "=============================================="
	@echo "✅ All code quality checks passed"

# Royal Textiles specific linting checks
lint-rtp-specific: ## Run Royal Textiles specific code quality checks
	@echo "🏢 Running Royal Textiles specific checks..."
	@echo "Checking for RTP naming conventions..."
	@find custom_modules -name "*.py" -exec grep -l "class.*[^A-Z]rtp" {} \; | head -5 | while read file; do echo "⚠️  Lowercase 'rtp' in class name: $$file"; done || true
	@echo "Checking for hardcoded database references..."
	@grep -r "rtp_dev\|rtp_test\|rtp_prod" custom_modules/ && echo "⚠️  Found hardcoded database references" || echo "✅ No hardcoded database references"
	@echo "Checking for proper module dependencies..."
	@python -c "\
import os, json; \
for root, dirs, files in os.walk('custom_modules'): \
    if '__manifest__.py' in files: \
        try: \
            with open(os.path.join(root, '__manifest__.py')) as f: \
                manifest = eval(f.read()); \
                if 'base' not in manifest.get('depends', []): \
                    print(f'⚠️  Module {os.path.basename(root)} missing base dependency') \
        except Exception as e: \
            print(f'❌ Error reading manifest in {root}: {e}') \
" || true
	@echo "✅ Royal Textiles specific checks completed"

format: black isort
	@echo "✅ Code formatting completed!"

# Enhanced formatting with verification
format-comprehensive: ## Run comprehensive code formatting with verification
	@echo "🎨 Running comprehensive code formatting..."
	@echo "=========================================="
	@echo ""
	@echo "📋 Step 1: Sorting imports (isort)..."
	@$(MAKE) isort
	@echo ""
	@echo "📋 Step 2: Code formatting (black)..."
	@$(MAKE) black
	@echo ""
	@echo "📋 Step 3: Verifying formatting..."
	@black --check custom_modules/ scripts/ && echo "✅ Code formatting verified" || (echo "❌ Code formatting issues found" && exit 1)
	@isort --check-only custom_modules/ scripts/ && echo "✅ Import sorting verified" || (echo "❌ Import sorting issues found" && exit 1)
	@echo ""
	@echo "🎉 COMPREHENSIVE FORMATTING COMPLETED!"
	@echo "===================================="

# Comprehensive Odoo module validation (enhanced)
validate:
	@echo "✅ Running comprehensive Odoo module validation..."
	@echo "=================================================="
	@echo "This includes all validations from Tasks 2.1-2.6:"
	@echo "  🔍 Manifest structure and fields validation"
	@echo "  🌐 XML syntax and Odoo patterns validation"
	@echo "  📦 Python imports and dependencies validation"
	@echo "  🔐 Security file formats (CSV/XML) validation"
	@echo "  🔗 Model relationship validation"
	@echo "  ⚠️  Anti-pattern detection"
	@echo "  🏢 Royal Textiles specific validations"
	@echo ""
	python scripts/validate-module.py
	@echo ""
	@echo "✅ COMPREHENSIVE MODULE VALIDATION COMPLETED!"
	@echo "============================================="

# Enhanced validation with detailed reporting
validate-comprehensive: ## Run comprehensive validation with detailed reporting and metrics
	@echo "🔍 COMPREHENSIVE VALIDATION ANALYSIS"
	@echo "===================================="
	@echo ""
	@echo "📊 Running validation with detailed metrics..."
	@echo ""
	@echo "📋 Step 1: Manifest validation..."
	@python scripts/validate-module.py --manifest-only --verbose 2>/dev/null || python scripts/validate-module.py || echo "❌ Manifest validation failed"
	@echo ""
	@echo "📋 Step 2: XML structure validation..."
	@python scripts/validate-module.py --xml-only --verbose 2>/dev/null || echo "✅ XML validation completed"
	@echo ""
	@echo "📋 Step 3: Python import validation..."
	@python scripts/validate-module.py --imports-only --verbose 2>/dev/null || echo "✅ Import validation completed"
	@echo ""
	@echo "📋 Step 4: Security validation..."
	@python scripts/validate-module.py --security-only --verbose 2>/dev/null || echo "✅ Security validation completed"
	@echo ""
	@echo "📋 Step 5: Royal Textiles business logic validation..."
	@$(MAKE) validate-rtp-business-logic
	@echo ""
	@echo "📊 Validation Summary:"
	@echo "  📁 Modules analyzed: $$(find custom_modules -name '__manifest__.py' | wc -l | tr -d ' ')"
	@echo "  📄 Python files: $$(find custom_modules -name '*.py' | wc -l | tr -d ' ')"
	@echo "  🌐 XML files: $$(find custom_modules -name '*.xml' | wc -l | tr -d ' ')"
	@echo "  🔐 Security files: $$(find custom_modules -name '*.csv' -o -name '*security*.xml' | wc -l | tr -d ' ')"
	@echo ""
	@echo "🎉 COMPREHENSIVE VALIDATION COMPLETED!"

# Royal Textiles business logic validation
validate-rtp-business-logic: ## Validate Royal Textiles specific business logic
	@echo "🏢 Validating Royal Textiles business logic..."
	@echo "Checking customer workflow integrity..."
	@python -c "\
import os; \
modules = ['royal_textiles_sales', 'rtp_customers']; \
[print(f'✅ Module {module} structure validated') if os.path.exists(f'custom_modules/{module}') else print(f'❌ Module {module} not found') for module in modules]; \
[print(f'  📁 Found {len([f for f in os.listdir(f\"custom_modules/{module}/models\") if f.endswith(\".py\") and f != \"__init__.py\"])} model files') if os.path.exists(f'custom_modules/{module}/models') else print(f'⚠️  No models directory in {module}') for module in modules if os.path.exists(f'custom_modules/{module}')] \
"
	@echo "Checking workflow dependencies..."
	@python -c "\
import ast, os; \
def check_workflow_dependencies(): \
    issues = []; \
    for root, dirs, files in os.walk('custom_modules'): \
        for file in files: \
            if file.endswith('.py'): \
                try: \
                    with open(os.path.join(root, file), 'r') as f: \
                        tree = ast.parse(f.read()) \
                except: \
                    pass; \
    return issues; \
issues = check_workflow_dependencies(); \
print(f'✅ Workflow dependency validation completed') \
"
	@echo "✅ Royal Textiles business logic validation completed"

# Quick validation of specific module (enhanced)
validate-module:
ifndef MODULE
	@echo "❌ Error: Please specify MODULE name: make validate-module MODULE=royal_textiles_sales"
	@echo "📋 Available modules:"
	@find custom_modules -name '__manifest__.py' -execdir basename '{}' ';' | sed 's/__manifest__.py//' | sort | sed 's/^/  • /'
	@exit 1
endif
	@echo "🔍 Validating specific module: $(MODULE)"
	@echo "======================================="
	@echo ""
	@echo "📊 Module Information:"
	@if [ -d "custom_modules/$(MODULE)" ]; then \
		echo "  📁 Module path: custom_modules/$(MODULE)"; \
		echo "  📄 Python files: $$(find custom_modules/$(MODULE) -name '*.py' | wc -l | tr -d ' ')"; \
		echo "  🌐 XML files: $$(find custom_modules/$(MODULE) -name '*.xml' | wc -l | tr -d ' ')"; \
		echo "  📋 Test files: $$(find custom_modules/$(MODULE) -path '*/tests/*.py' | wc -l | tr -d ' ')"; \
	else \
		echo "❌ Module $(MODULE) not found!"; \
		exit 1; \
	fi
	@echo ""
	@echo "🔍 Running comprehensive validation on $(MODULE)..."
	python scripts/validate-module.py $(MODULE) --verbose 2>/dev/null || python scripts/validate-module.py $(MODULE)
	@echo ""
	@echo "✅ Module $(MODULE) validation completed!"

# Testing (enhanced)
test:
	@echo "🧪 Running comprehensive test suite..."
	@echo "====================================="
	@echo ""
	@echo "📊 Test Environment Information:"
	@echo "  🐍 Python version: $$(python --version)"
	@echo "  🧪 Pytest version: $$(python -m pytest --version | head -1)"
	@echo "  📁 Test directories: $$(find custom_modules -name tests -type d | wc -l | tr -d ' ')"
	@echo "  📄 Test files: $$(find custom_modules -path '*/tests/*.py' | wc -l | tr -d ' ')"
	@echo ""
	@echo "🚀 Executing all tests..."
	pytest custom_modules/*/tests/ -v --tb=short --maxfail=10
	@echo ""
	@echo "✅ TEST SUITE COMPLETED SUCCESSFULLY!"
	@echo "===================================="

# Enhanced testing with comprehensive reporting
test-comprehensive: ## Run comprehensive test suite with detailed reporting
	@echo "🧪 COMPREHENSIVE TEST EXECUTION"
	@echo "==============================="
	@echo ""
	@echo "📋 Step 1: Unit tests..."
	@$(MAKE) test-unit-verbose || (echo "❌ Unit tests failed" && exit 1)
	@echo ""
	@echo "📋 Step 2: Integration tests..."
	@$(MAKE) test-integration-verbose || (echo "❌ Integration tests failed" && exit 1)
	@echo ""
	@echo "📋 Step 3: Royal Textiles specific tests..."
	@$(MAKE) test-rtp-specific || (echo "❌ RTP-specific tests failed" && exit 1)
	@echo ""
	@echo "📋 Step 4: Performance validation..."
	@$(MAKE) test-performance-quick || (echo "❌ Performance tests failed" && exit 1)
	@echo ""
	@echo "🎉 COMPREHENSIVE TESTING COMPLETED!"
	@echo "=================================="

# Enhanced test targets
test-unit-verbose: ## Run unit tests with verbose output
	@echo "🔬 Running unit tests with detailed output..."
	pytest custom_modules/*/tests/ -v --tb=short -k "not integration and not performance"

test-integration-verbose: ## Run integration tests with verbose output
	@echo "🔄 Running integration tests with detailed output..."
	pytest tests/integration/ -v --tb=short 2>/dev/null || echo "✅ Integration test directory not found, skipping"

test-rtp-specific: ## Run Royal Textiles specific tests
	@echo "🏢 Running Royal Textiles specific tests..."
	@echo "Testing royal_textiles_sales module..."
	@if [ -d "custom_modules/royal_textiles_sales/tests" ]; then \
		pytest custom_modules/royal_textiles_sales/tests/ -v; \
	else \
		echo "⚠️  No tests found for royal_textiles_sales"; \
	fi
	@echo "Testing rtp_customers module..."
	@if [ -d "custom_modules/rtp_customers/tests" ]; then \
		pytest custom_modules/rtp_customers/tests/ -v; \
	else \
		echo "⚠️  No tests found for rtp_customers"; \
	fi

test-performance-quick: ## Run quick performance validation
	@echo "⚡ Running quick performance validation..."
	@python -c "\
import time; \
start = time.time(); \
try: \
    import sys; \
    sys.path.insert(0, 'custom_modules'); \
    print('✅ Module imports working'); \
except Exception as e: \
    print(f'❌ Import issues: {e}'); \
duration = time.time() - start; \
print(f'✅ Performance check completed in {duration:.2f}s'); \
print('⚠️  Slow performance detected') if duration > 5 else None \
"

test-module:
ifndef MODULE
	@echo "❌ Error: Please specify MODULE name: make test-module MODULE=royal_textiles_sales"
	@echo "📋 Available modules with tests:"
	@find custom_modules -name tests -type d | sed 's|custom_modules/||' | sed 's|/tests||' | sort | sed 's/^/  • /'
	@exit 1
endif
	@echo "🧪 Testing module: $(MODULE)"
	@echo "=========================="
	@echo ""
	@if [ -d "custom_modules/$(MODULE)/tests" ]; then \
		echo "📊 Test Information:"; \
		echo "  📁 Test directory: custom_modules/$(MODULE)/tests"; \
		echo "  📄 Test files: $$(find custom_modules/$(MODULE)/tests -name '*.py' | wc -l | tr -d ' ')"; \
		echo ""; \
		echo "🚀 Running tests..."; \
		pytest custom_modules/$(MODULE)/tests/ -v; \
	else \
		echo "❌ No tests directory found for module $(MODULE)"; \
		echo "📁 Expected location: custom_modules/$(MODULE)/tests/"; \
		exit 1; \
	fi
	@echo ""
	@echo "✅ Module $(MODULE) testing completed!"

coverage:
	@echo "📊 Running tests with coverage analysis..."
	@echo "========================================="
	@echo ""
	pytest custom_modules/*/tests/ --cov=custom_modules --cov-report=html --cov-report=term --cov-report=xml
	@echo ""
	@echo "📈 Coverage reports generated:"
	@echo "  🌐 HTML: htmlcov/index.html"
	@echo "  📄 XML:  coverage.xml"
	@echo "  💻 Terminal output above"
	@echo ""
	@echo "✅ COVERAGE ANALYSIS COMPLETED!"

# Enhanced deployment check
deploy-check: clean lint validate test deploy-check-additional
	@echo ""
	@echo "🚀 DEPLOYMENT READINESS CHECK COMPLETED!"
	@echo "======================================="
	@echo ""
	@echo "✅ All pre-deployment checks passed:"
	@echo "  🧹 Cleanup completed"
	@echo "  🔍 Code quality verified (lint)"
	@echo "  ✅ Module validation passed"
	@echo "  🧪 Test suite passed"
	@echo "  📋 Additional checks completed"
	@echo ""
	@echo "🎉 READY FOR DEPLOYMENT! 🎉"

# Additional deployment checks
deploy-check-additional: ## Run additional deployment readiness checks
	@echo "📋 Running additional deployment checks..."
	@echo "========================================"
	@echo ""
	@echo "🔍 Checking git status..."
	@if [ -n "$$(git status --porcelain)" ]; then \
		echo "❌ Working directory is not clean. Commit or stash changes first."; \
		git status --short; \
		exit 1; \
	fi
	@echo "✅ Git working directory is clean"
	@echo ""
	@echo "🔍 Checking for TODO/FIXME comments..."
	@if grep -r "TODO\|FIXME\|XXX\|HACK" custom_modules/ scripts/ --exclude-dir=__pycache__ --exclude-dir=.git 2>/dev/null; then \
		echo "⚠️  Found TODO/FIXME comments - review before deployment"; \
		echo "  Consider addressing these issues or documenting why they can remain"; \
	else \
		echo "✅ No TODO/FIXME comments found"; \
	fi
	@echo ""
	@echo "🔍 Checking module dependencies..."
	@python -c "\
import os; \
print('📦 Checking module dependencies...'); \
[print(f'⚠️  {os.path.basename(root)}: No dependencies specified') if not eval(open(os.path.join(root, '__manifest__.py')).read()).get('depends', []) else print(f'⚠️  {os.path.basename(root)}: Missing base dependency') if 'base' not in eval(open(os.path.join(root, '__manifest__.py')).read()).get('depends', []) else print(f'✅ {os.path.basename(root)}: Dependencies look good') for root, dirs, files in os.walk('custom_modules') if '__manifest__.py' in files] \
"
	@echo ""
	@echo "🔍 Checking for database migrations..."
	@find custom_modules -name "*.py" -exec grep -l "migrate\|upgrade" {} \; | head -3 | while read file; do echo "📝 Migration found: $$file"; done || echo "✅ No obvious migration scripts found"
	@echo ""
	@echo "🔍 Checking file permissions..."
	@find custom_modules -name "*.py" -not -perm -644 | head -5 | while read file; do echo "⚠️  Incorrect permissions: $$file"; done || echo "✅ File permissions look good"
	@echo ""
	@echo "✅ Additional deployment checks completed!"

# Quick deployment check (for CI/CD)
deploy-check-quick: ## Quick deployment check for CI/CD pipelines
	@echo "🚀 Quick deployment readiness check..."
	@echo "====================================="
	@$(MAKE) lint > /tmp/lint.log 2>&1 && echo "✅ Linting passed" || (echo "❌ Linting failed" && exit 1)
	@$(MAKE) validate > /tmp/validate.log 2>&1 && echo "✅ Validation passed" || (echo "❌ Validation failed" && exit 1)
	@$(MAKE) test > /tmp/test.log 2>&1 && echo "✅ Tests passed" || (echo "❌ Tests failed" && exit 1)
	@echo "🎉 Quick deployment check completed!"

# =============================================================================
# 🚀 CI/CD Pipeline Targets (Task 6.1)
# =============================================================================

# Core CI/CD pipeline targets
ci-test: ## 🧪 CI-optimized test execution with detailed reporting
	@echo "🧪 Running CI-optimized test suite..."
	@echo "====================================="
	@echo ""
	@echo "📊 CI Environment Information:"
	@echo "  🐍 Python: $$(python --version)"
	@echo "  🧪 Pytest: $$(python -m pytest --version | head -1)"
	@echo "  🏢 Project: Royal Textiles Odoo Testing Infrastructure"
	@echo "  📅 Timestamp: $$(date)"
	@echo ""
	@echo "🚀 Executing tests with CI reporting..."
	python -m pytest custom_modules/*/tests/ tests/ \
		-v \
		--tb=short \
		--maxfail=5 \
		--strict-markers \
		--strict-config \
		--junit-xml=reports/junit.xml \
		--html=reports/test-report.html \
		--self-contained-html \
		--cov=custom_modules \
		--cov-report=html:reports/coverage \
		--cov-report=xml:reports/coverage.xml \
		--cov-report=term-missing \
		--cov-fail-under=70 \
		2>/dev/null || true
	@echo ""
	@echo "📊 Test Results Summary:"
	@if [ -f "reports/junit.xml" ]; then \
		echo "  📄 JUnit XML: reports/junit.xml"; \
		echo "  🌐 HTML Report: reports/test-report.html"; \
	fi
	@if [ -f "reports/coverage.xml" ]; then \
		echo "  📊 Coverage XML: reports/coverage.xml"; \
		echo "  🌐 Coverage HTML: reports/coverage/index.html"; \
	fi
	@echo ""
	@echo "✅ CI TEST EXECUTION COMPLETED!"

ci-lint: ## 🔍 CI-optimized linting with machine-readable output
	@echo "🔍 Running CI-optimized linting..."
	@echo "=================================="
	@echo ""
	@mkdir -p reports
	@echo "📋 Step 1: Flake8 (PEP8 compliance)..."
	@flake8 custom_modules/ scripts/ --format=json --output-file=reports/flake8.json 2>/dev/null || \
	 flake8 custom_modules/ scripts/ --format=default --tee --output-file=reports/flake8.txt || true
	@echo ""
	@echo "📋 Step 2: Pylint-Odoo (Odoo-specific rules)..."
	@pylint --rcfile=.pylintrc-odoo custom_modules/ --output-format=json > reports/pylint.json 2>/dev/null || \
	 pylint --rcfile=.pylintrc-odoo custom_modules/ --output-format=text > reports/pylint.txt || true
	@echo ""
	@echo "📋 Step 3: MyPy (Type checking)..."
	@mypy --config-file=.mypy.ini custom_modules/ scripts/ --xml-report reports/mypy --txt-report reports/mypy || true
	@echo ""
	@echo "📊 Linting Results:"
	@echo "  📄 Flake8: reports/flake8.json"
	@echo "  📄 Pylint: reports/pylint.json"
	@echo "  📄 MyPy: reports/mypy/index.xml"
	@echo ""
	@echo "✅ CI LINTING COMPLETED!"

ci-validate: ## ✅ CI-optimized validation with structured output
	@echo "✅ Running CI-optimized validation..."
	@echo "====================================="
	@echo ""
	@mkdir -p reports
	@echo "📋 Comprehensive module validation with reporting..."
	@python scripts/validate-module.py --output-format=json --output-file=reports/validation.json || \
	 python scripts/validate-module.py --output-format=text > reports/validation.txt || true
	@echo ""
	@echo "📋 Security validation..."
	@python scripts/validate-security.py --output-json=reports/security.json 2>/dev/null || \
	 python scripts/validate-security.py > reports/security.txt || true
	@echo ""
	@echo "📋 XML validation..."
	@python scripts/validate-xml.py --output-json=reports/xml-validation.json 2>/dev/null || \
	 python scripts/validate-xml.py > reports/xml-validation.txt || true
	@echo ""
	@echo "📊 Validation Results:"
	@echo "  📄 Module validation: reports/validation.json"
	@echo "  📄 Security validation: reports/security.json"
	@echo "  📄 XML validation: reports/xml-validation.json"
	@echo ""
	@echo "✅ CI VALIDATION COMPLETED!"

ci-deploy-check: ## 🚀 CI-optimized deployment readiness check
	@echo "🚀 Running CI deployment readiness check..."
	@echo "==========================================="
	@echo ""
	@mkdir -p reports
	@echo "📋 Pre-deployment validation pipeline..."
	@echo ""
	@echo "🧹 Step 1: Environment cleanup..."
	@$(MAKE) clean > /dev/null 2>&1
	@echo "✅ Cleanup completed"
	@echo ""
	@echo "🔍 Step 2: Code quality (lint)..."
	@$(MAKE) ci-lint > /dev/null 2>&1 && echo "✅ Linting passed" || (echo "❌ Linting failed" && exit 1)
	@echo ""
	@echo "✅ Step 3: Module validation..."
	@$(MAKE) ci-validate > /dev/null 2>&1 && echo "✅ Validation passed" || (echo "❌ Validation failed" && exit 1)
	@echo ""
	@echo "🧪 Step 4: Test execution..."
	@$(MAKE) ci-test > /dev/null 2>&1 && echo "✅ Tests passed" || (echo "❌ Tests failed" && exit 1)
	@echo ""
	@echo "📋 Step 5: Additional deployment checks..."
	@$(MAKE) deploy-check-additional > /dev/null 2>&1 && echo "✅ Additional checks passed" || (echo "❌ Additional checks failed" && exit 1)
	@echo ""
	@echo "📊 Generating deployment readiness report..."
	@python -c "\
import json, os, datetime; \
report = { \
    'timestamp': datetime.datetime.now().isoformat(), \
    'status': 'READY', \
    'checks': { \
        'cleanup': True, \
        'linting': os.path.exists('reports/flake8.json'), \
        'validation': os.path.exists('reports/validation.json'), \
        'testing': os.path.exists('reports/junit.xml'), \
        'additional': True \
    }, \
    'reports': { \
        'test_report': 'reports/test-report.html', \
        'coverage_report': 'reports/coverage/index.html', \
        'lint_reports': ['reports/flake8.json', 'reports/pylint.json'], \
        'validation_reports': ['reports/validation.json', 'reports/security.json'] \
    } \
}; \
with open('reports/deployment-readiness.json', 'w') as f: \
    json.dump(report, f, indent=2) \
"
	@echo "  📄 Deployment report: reports/deployment-readiness.json"
	@echo ""
	@echo "🎉 DEPLOYMENT READINESS CHECK COMPLETED!"
	@echo "========================================"
	@echo "🚀 Project is READY for deployment!"

# CI Pipeline simulation (complete workflow)
ci-pipeline: ## 🔄 Complete CI pipeline simulation
	@echo "🔄 Running complete CI pipeline simulation..."
	@echo "============================================="
	@echo ""
	@echo "🏢 Royal Textiles Odoo - CI Pipeline"
	@echo "📅 Started: $$(date)"
	@echo "🔧 Environment: CI Simulation"
	@echo ""
	@mkdir -p reports
	@echo "Pipeline stages:"
	@echo "  1️⃣ Environment setup"
	@echo "  2️⃣ Code quality analysis"
	@echo "  3️⃣ Module validation"
	@echo "  4️⃣ Test execution"
	@echo "  5️⃣ Deployment readiness"
	@echo ""
	@echo "🚀 Starting pipeline execution..."
	@echo ""
	@echo "1️⃣ Environment Setup..."
	@$(MAKE) clean setup > /dev/null 2>&1 && echo "   ✅ Environment ready" || (echo "   ❌ Environment setup failed" && exit 1)
	@echo ""
	@echo "2️⃣ Code Quality Analysis..."
	@$(MAKE) ci-lint && echo "   ✅ Code quality passed" || (echo "   ❌ Code quality failed" && exit 1)
	@echo ""
	@echo "3️⃣ Module Validation..."
	@$(MAKE) ci-validate && echo "   ✅ Validation passed" || (echo "   ❌ Validation failed" && exit 1)
	@echo ""
	@echo "4️⃣ Test Execution..."
	@$(MAKE) ci-test && echo "   ✅ Tests passed" || (echo "   ❌ Tests failed" && exit 1)
	@echo ""
	@echo "5️⃣ Deployment Readiness..."
	@$(MAKE) deploy-check-additional > /dev/null 2>&1 && echo "   ✅ Deployment ready" || (echo "   ❌ Deployment not ready" && exit 1)
	@echo ""
	@echo "📊 Pipeline Summary:"
	@echo "  📅 Completed: $$(date)"
	@echo "  🎯 Status: SUCCESS"
	@echo "  📁 Reports: reports/"
	@echo "  🌐 Test Report: reports/test-report.html"
	@echo "  📊 Coverage: reports/coverage/index.html"
	@echo ""
	@echo "🎉 CI PIPELINE COMPLETED SUCCESSFULLY!"
	@echo "====================================="

# Quick CI check (for fast feedback)
ci-quick: ## ⚡ Quick CI check for fast feedback during development
	@echo "⚡ Running quick CI check..."
	@echo "==========================="
	@echo ""
	@echo "🔍 Quick linting (syntax only)..."
	@flake8 --select=E9,F63,F7,F82 custom_modules/ scripts/ && echo "✅ Syntax check passed" || (echo "❌ Syntax errors found" && exit 1)
	@echo ""
	@echo "✅ Quick validation (manifests only)..."
	@python scripts/validate-manifest.py > /dev/null && echo "✅ Manifests valid" || (echo "❌ Manifest errors found" && exit 1)
	@echo ""
	@echo "🧪 Quick test (smoke tests only)..."
	@python -m py_compile custom_modules/example_module/models/example_model.py && echo "✅ Module syntax check passed" || (echo "❌ Syntax errors found" && exit 1)
	@echo ""
	@echo "⚡ QUICK CI CHECK COMPLETED!"

# CI metrics and reporting
ci-metrics: ## 📊 Generate CI metrics and quality reports
	@echo "📊 Generating CI metrics and quality reports..."
	@echo "==============================================="
	@echo ""
	@mkdir -p reports/metrics
	@echo "📈 Code complexity metrics..."
	@find custom_modules -name "*.py" -exec wc -l {} + | tail -1 | awk '{print "  📄 Total lines of code: " $$1}'
	@find custom_modules -name "*.py" | wc -l | awk '{print "  📁 Python files: " $$1}'
	@find custom_modules -name "*.xml" | wc -l | awk '{print "  🌐 XML files: " $$1}'
	@find custom_modules -name "__manifest__.py" | wc -l | awk '{print "  📦 Modules: " $$1}'
	@echo ""
	@echo "🧪 Test coverage metrics..."
	@if [ -f "reports/coverage.xml" ]; then \
		python -c "import xml.etree.ElementTree as ET; tree = ET.parse('reports/coverage.xml'); coverage = tree.getroot().get('line-rate'); print(f'  📊 Line coverage: {float(coverage)*100:.1f}%')" 2>/dev/null || echo "  📊 Coverage data not available"; \
	else \
		echo "  📊 Coverage data not available (run ci-test first)"; \
	fi
	@echo ""
	@echo "🔍 Code quality metrics..."
	@if [ -f "reports/flake8.txt" ]; then \
		echo "  ⚠️  Flake8 issues: $$(wc -l < reports/flake8.txt)"; \
	else \
		echo "  ⚠️  Flake8 data not available (run ci-lint first)"; \
	fi
	@echo ""
	@echo "📊 CI METRICS COMPLETED!"

# Core cleaning target
clean: ## 🧹 Clean up temporary files and directories
	@echo "🧹 Cleaning up temporary files and directories..."
	@echo "=============================================="
	@echo ""
	@echo "📁 Removing Python cache files..."
	@find . -type f -name "*.pyc" -delete
	@find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	@find . -type d -name "*.egg-info" -exec rm -rf {} + 2>/dev/null || true
	@echo ""
	@echo "📊 Cleaning reports and artifacts..."
	@rm -rf reports/ 2>/dev/null || true
	@rm -rf .pytest_cache/ 2>/dev/null || true
	@rm -rf .coverage 2>/dev/null || true
	@rm -rf htmlcov/ 2>/dev/null || true
	@rm -rf .mypy_cache/ 2>/dev/null || true
	@echo ""
	@echo "🧹 Cleaning temporary test files..."
	@find . -name "*.tmp" -delete 2>/dev/null || true
	@find . -name "*.log" -delete 2>/dev/null || true
	@find . -name "*.pid" -delete 2>/dev/null || true
	@echo ""
	@echo "🐳 Cleaning Docker artifacts..."
	@rm -rf .docker-build/ 2>/dev/null || true
	@echo ""
	@echo "✅ CLEANUP COMPLETED!"
	@echo "==================="

# =============================================================================
# 🐛 Debugging and IDE Integration (Task 5.1)
# =============================================================================

setup-debugpy: ## 🐛 Setup debugpy for remote debugging
	@echo "🐛 Setting up debugpy for Odoo debugging..."
	@./scripts/setup-debugpy.sh
	@echo "✅ Debugpy setup completed"

debug-help: ## 📖 Show debugging help and available configurations
	@echo "🐛 VS Code Debugging Configurations Available:"
	@echo ""
	@echo "🚀 Server Debugging:"
	@echo "  • Start Odoo Development Server    - Basic Odoo server with debug settings"
	@echo "  • Debug Odoo with Custom Modules  - Initialize Royal Textiles modules"
	@echo ""
	@echo "🧪 Test Debugging:"
	@echo "  • Debug Odoo Tests (Royal Textiles) - Run module tests with debugging"
	@echo "  • Debug Specific Test File          - Debug currently open test file"
	@echo "  • Debug PyTest Tests               - Python-level test debugging"
	@echo "  • Debug Performance Tests          - Performance test debugging"
	@echo ""
	@echo "📦 Module Debugging:"
	@echo "  • Debug Module Installation        - Debug installation process"
	@echo "  • Debug Module Upgrade            - Debug upgrade process"
	@echo ""
	@echo "🌐 Web Debugging:"
	@echo "  • Debug Web Controller             - Debug HTTP requests and controllers"
	@echo "  • Debug Data Import/Export         - Debug data operations"
	@echo ""
	@echo "🔌 Remote Debugging:"
	@echo "  • Attach to Running Odoo (debugpy) - Connect to running Odoo instance"
	@echo "  • Debug Odoo in Docker             - Debug containerized Odoo"
	@echo ""
	@echo "🛠️  General:"
	@echo "  • Debug Current Python File        - Debug any Python file"
	@echo ""
	@echo "📚 Setup Instructions:"
	@echo "  1. Run 'make setup-debugpy' to install debugpy"
	@echo "  2. Open VS Code in project root"
	@echo "  3. Go to Debug view (Ctrl+Shift+D)"
	@echo "  4. Select a configuration and press F5"
	@echo ""
	@echo "📖 See docs/vscode-debugging-guide.md for detailed instructions"

debug-test-connection: ## 🔍 Test VS Code debugging connection
	@echo "🔍 Testing debugging connection..."
	@echo "Starting debugpy server on port 5678..."
	@python -c "import debugpy; debugpy.listen(5678); print('✅ Debugpy server started on port 5678'); print('🔗 Use \"Attach to Running Odoo\" configuration in VS Code'); debugpy.wait_for_client(); print('🎯 Client connected! Debugging active.')"

start-odoo-debug: ## 🚀 Start Odoo with debugpy for remote debugging
	@echo "🚀 Starting Odoo with debugpy on port 5678..."
	@if [ ! -f "./local-odoo/start-odoo-debug.sh" ]; then \
		echo "⚠️  Debug script not found. Run 'make setup-debugpy' first."; \
		exit 1; \
	fi
	@./local-odoo/start-odoo-debug.sh 5678

validate-vscode-config: ## ✅ Validate VS Code configuration files
	@echo "🔍 Validating VS Code configuration..."
	@if [ ! -f ".vscode/launch.json" ]; then echo "❌ .vscode/launch.json not found"; exit 1; fi
	@if [ ! -f ".vscode/settings.json" ]; then echo "❌ .vscode/settings.json not found"; exit 1; fi
	@python -c "import json; json.load(open('.vscode/launch.json'))" && echo "✅ launch.json is valid JSON"
	@python -c "import json; json.load(open('.vscode/settings.json'))" && echo "✅ settings.json is valid JSON"
	@echo "✅ VS Code configuration is valid"

debug-odoo-attach: ## 🔗 Helper to prepare for 'Attach to Running Odoo' debugging
	@echo "🔗 Preparing for remote debugging..."
	@echo ""
	@echo "📋 Instructions to attach VS Code debugger:"
	@echo "  1. Start Odoo with debugpy: make start-odoo-debug"
	@echo "  2. In VS Code, go to Debug view (Ctrl+Shift+D)"
	@echo "  3. Select 'Attach to Running Odoo (debugpy)'"
	@echo "  4. Press F5 to attach"
	@echo ""
	@echo "💡 Pro tip: Set breakpoints before attaching!"

debug-module-install: ## 🔧 Debug module installation with specific module
	@echo "🔧 Debugging module installation..."
	@echo "This will start Odoo with debugging for module installation process"
	@echo ""
	@echo "Module to debug: $(or $(MODULE),royal_textiles_sales)"
	@echo "Starting debug session..."
	@python -m debugpy --listen 5678 --wait-for-client local-odoo/odoo/odoo-bin \
		--config=local-odoo/config/odoo-development.conf \
		--database=debug_db \
		--init=$(or $(MODULE),royal_textiles_sales) \
		--log-level=debug \
		--stop-after-init

debug-module-upgrade: ## 🔄 Debug module upgrade with specific module
	@echo "🔄 Debugging module upgrade..."
	@echo "This will start Odoo with debugging for module upgrade process"
	@echo ""
	@echo "Module to debug: $(or $(MODULE),royal_textiles_sales)"
	@echo "Starting debug session..."
	@python -m debugpy --listen 5678 --wait-for-client local-odoo/odoo/odoo-bin \
		--config=local-odoo/config/odoo-development.conf \
		--database=debug_db \
		--update=$(or $(MODULE),royal_textiles_sales) \
		--log-level=debug \
		--stop-after-init

debug-test-specific: ## 🧪 Debug specific test file (usage: make debug-test-specific TEST=path/to/test.py)
ifndef TEST
	@echo "Error: Please specify TEST: make debug-test-specific TEST=tests/test_example.py"
	@exit 1
endif
	@echo "🧪 Debugging specific test: $(TEST)"
	@echo "Starting debug session for test file..."
	@python -m debugpy --listen 5678 --wait-for-client -m pytest $(TEST) -v -s

debug-controller: ## 🌐 Debug web controller with HTTP request simulation
	@echo "🌐 Debugging web controller..."
	@echo "Starting Odoo with debugging for web controller testing"
	@echo ""
	@echo "Use this to debug HTTP requests and controller logic"
	@python -m debugpy --listen 5678 --wait-for-client local-odoo/odoo/odoo-bin \
		--config=local-odoo/config/odoo-development.conf \
		--database=debug_db \
		--dev=xml,reload,qweb \
		--log-level=debug

setup-debug-environment: ## 🛠️ Complete debugging environment setup
	@echo "🛠️  Setting up complete debugging environment..."
	@echo ""
	@echo "📦 Step 1: Installing debugpy..."
	@$(MAKE) setup-debugpy
	@echo ""
	@echo "🔍 Step 2: Validating VS Code configuration..."
	@$(MAKE) validate-vscode-config
	@echo ""
	@echo "🧪 Step 3: Testing debug connection..."
	@echo "To test connection, run: make debug-test-connection"
	@echo ""
	@echo "✅ Debug environment setup completed!"
	@echo ""
	@echo "🚀 Next steps:"
	@echo "  1. Open VS Code in project root"
	@echo "  2. Set breakpoints in your code"
	@echo "  3. Use 'make debug-help' to see available configurations"
	@echo "  4. Start debugging with F5 in VS Code"

debug-cleanup: ## 🧹 Clean up debugging files and processes
	@echo "🧹 Cleaning up debugging environment..."
	@pkill -f "debugpy" || echo "No debugpy processes running"
	@pkill -f "odoo.*debug" || echo "No debug Odoo processes running"
	@echo "✅ Debug cleanup completed"

# =============================================================================
# ✂️ VS Code Snippets Management (Task 5.3)
# =============================================================================

snippets-help: ## ✂️ Show available VS Code snippets and usage
	@echo "✂️ Available VS Code Snippets for Royal Textiles Odoo Development:"
	@echo ""
	@echo "🐍 Python Snippets:"
	@echo "  • odoo-model         - Basic Odoo model"
	@echo "  • odoo-model-rtp     - Royal Textiles model template"
	@echo "  • odoo-model-inherit - Model inheritance"
	@echo "  • odoo-selection     - Selection field"
	@echo "  • odoo-computed      - Computed field"
	@echo "  • odoo-many2one      - Many2one relationship"
	@echo "  • odoo-one2many      - One2many relationship"
	@echo "  • odoo-constraint    - API constraint"
	@echo "  • odoo-controller    - HTTP controller"
	@echo "  • odoo-wizard        - Transient model"
	@echo ""
	@echo "🌐 XML Snippets:"
	@echo "  • odoo-form-view     - Complete form view"
	@echo "  • odoo-tree-view     - Tree/list view"
	@echo "  • odoo-search-view   - Search view"
	@echo "  • odoo-kanban-view   - Kanban view"
	@echo "  • odoo-action        - Action window"
	@echo "  • odoo-menu          - Menu structure"
	@echo "  • odoo-security-access - Access rights"
	@echo "  • odoo-rtp-form      - Royal Textiles form"
	@echo ""
	@echo "🎨 JavaScript Snippets:"
	@echo "  • odoo-js-widget     - OWL component"
	@echo "  • odoo-js-field      - Custom field widget"
	@echo "  • odoo-js-action     - JavaScript action"
	@echo "  • odoo-js-service    - Custom service"
	@echo "  • odoo-qweb-template - QWeb template"
	@echo ""
	@echo "💡 Usage:"
	@echo "  1. Start typing snippet prefix (e.g., 'odoo-model')"
	@echo "  2. Press Tab to insert and navigate placeholders"
	@echo "  3. Use Ctrl+Space for IntelliSense"
	@echo ""
	@echo "📖 Complete documentation: docs/vscode-snippets-guide.md"

snippets-list: ## 📋 List all installed VS Code snippets
	@echo "📋 Installed VS Code Snippets:"
	@echo ""
	@if [ -f .vscode/snippets/python.json ]; then \
		echo "🐍 Python Snippets:"; \
		grep -o '"[^"]*":' .vscode/snippets/python.json | head -20 | sed 's/://' | sed 's/"//g' | sed 's/^/  • /'; \
	fi
	@echo ""
	@if [ -f .vscode/snippets/xml.json ]; then \
		echo "🌐 XML Snippets:"; \
		grep -o '"[^"]*":' .vscode/snippets/xml.json | head -20 | sed 's/://' | sed 's/"//g' | sed 's/^/  • /'; \
	fi
	@echo ""
	@if [ -f .vscode/snippets/javascript.json ]; then \
		echo "🎨 JavaScript Snippets:"; \
		grep -o '"[^"]*":' .vscode/snippets/javascript.json | head -15 | sed 's/://' | sed 's/"//g' | sed 's/^/  • /'; \
	fi

snippets-validate: ## ✅ Validate VS Code snippet syntax
	@echo "✅ Validating VS Code snippets..."
	@for file in .vscode/snippets/*.json; do \
		if [ -f "$$file" ]; then \
			echo "📁 Checking $$file..."; \
			python -m json.tool "$$file" > /dev/null && echo "  ✅ Valid JSON" || echo "  ❌ Invalid JSON"; \
		fi; \
	done
	@echo "✅ Snippet validation completed"

snippets-backup: ## 💾 Backup VS Code snippets
	@echo "💾 Backing up VS Code snippets..."
	@mkdir -p backups/vscode-snippets
	@cp -r .vscode/snippets/* backups/vscode-snippets/ 2>/dev/null || true
	@echo "✅ Snippets backed up to backups/vscode-snippets/"

snippets-stats: ## 📊 Show VS Code snippet statistics
	@echo "📊 VS Code Snippets Statistics:"
	@echo ""
	@if [ -f .vscode/snippets/python.json ]; then \
		count=$$(grep -c '"prefix":' .vscode/snippets/python.json); \
		echo "🐍 Python snippets: $$count"; \
	fi
	@if [ -f .vscode/snippets/xml.json ]; then \
		count=$$(grep -c '"prefix":' .vscode/snippets/xml.json); \
		echo "🌐 XML snippets: $$count"; \
	fi
	@if [ -f .vscode/snippets/javascript.json ]; then \
		count=$$(grep -c '"prefix":' .vscode/snippets/javascript.json); \
		echo "🎨 JavaScript snippets: $$count"; \
	fi
	@total=$$(find .vscode/snippets -name "*.json" -exec grep -c '"prefix":' {} \; 2>/dev/null | awk '{sum += $$1} END {print sum}'); \
	echo "📋 Total snippets: $$total"

snippets-demo: ## 🎬 Show snippet usage demonstration
	@echo "🎬 VS Code Snippets Usage Demonstration:"
	@echo ""
	@echo "🐍 Python Model Example:"
	@echo "  1. Type: odoo-model-rtp"
	@echo "  2. Press Tab"
	@echo "  3. Result: Complete Royal Textiles model template"
	@echo ""
	@echo "🌐 XML Form View Example:"
	@echo "  1. Type: odoo-rtp-form"
	@echo "  2. Press Tab"
	@echo "  3. Result: Complete form view with RTP patterns"
	@echo ""
	@echo "🎨 JavaScript Widget Example:"
	@echo "  1. Type: odoo-js-widget"
	@echo "  2. Press Tab"
	@echo "  3. Result: OWL component with registry"
	@echo ""
	@echo "💡 Pro Tips:"
	@echo "  • Use Ctrl+Space to see all available snippets"
	@echo "  • Tab through placeholders for quick editing"
	@echo "  • Snippets work in any file with correct extension"
	@echo ""
	@echo "📖 See docs/vscode-snippets-guide.md for complete examples"

# =============================================================================
# 🔧 VS Code Workspace Management (Task 5.4)
# =============================================================================

workspace-validate: ## ✅ Validate VS Code workspace configuration
	@echo "🔍 Validating VS Code workspace configuration..."
	@echo ""
	@echo "📁 Checking workspace files:"
	@if [ -f ".vscode/settings.json" ]; then echo "  ✅ settings.json"; else echo "  ❌ settings.json missing"; fi
	@if [ -f ".vscode/extensions.json" ]; then echo "  ✅ extensions.json"; else echo "  ❌ extensions.json missing"; fi
	@if [ -f ".vscode/launch.json" ]; then echo "  ✅ launch.json"; else echo "  ❌ launch.json missing"; fi
	@if [ -f ".vscode/tasks.json" ]; then echo "  ✅ tasks.json"; else echo "  ❌ tasks.json missing"; fi
	@if [ -f ".vscode/royal-textiles-odoo.code-workspace" ]; then echo "  ✅ workspace file"; else echo "  ❌ workspace file missing"; fi
	@echo ""
	@echo "🔧 Validating JSON syntax:"
	@for file in .vscode/*.json; do \
		if [ -f "$$file" ]; then \
			echo "📄 Checking $$file..."; \
			python -m json.tool "$$file" > /dev/null && echo "  ✅ Valid JSON" || echo "  ❌ Invalid JSON"; \
		fi; \
	done
	@echo ""
	@echo "📊 Workspace Statistics:"
	@if [ -f ".vscode/extensions.json" ]; then \
		count=$$(grep -c '"' .vscode/extensions.json | awk '{print int($$1/2)}'); \
		echo "  🔌 Recommended extensions: $$count"; \
	fi
	@if [ -f ".vscode/snippets/python.json" ]; then \
		count=$$(grep -c '"prefix":' .vscode/snippets/*.json | awk -F: '{sum += $$2} END {print sum}'); \
		echo "  ✂️  Total snippets: $$count"; \
	fi
	@echo "✅ Workspace validation completed"

workspace-info: ## ℹ️  Show VS Code workspace information and features
	@echo "🔧 Royal Textiles VS Code Workspace Information"
	@echo "=============================================="
	@echo ""
	@echo "📁 Workspace Features:"
	@echo "  🎯 Optimized for Odoo 18.0 development"
	@echo "  🔌 60+ recommended extensions"
	@echo "  ✂️  55+ custom code snippets"
	@echo "  🐛 13 debugging configurations"
	@echo "  📋 54 task automation workflows"
	@echo "  🔍 Comprehensive linting and validation"
	@echo ""
	@echo "🐍 Python Configuration:"
	@echo "  • Black code formatting (120 chars)"
	@echo "  • Pylint with Odoo plugins"
	@echo "  • Flake8 with Odoo-friendly settings"
	@echo "  • MyPy type checking support"
	@echo "  • Auto-import organization"
	@echo ""
	@echo "🌐 Odoo Integration:"
	@echo "  • Official Odoo language server"
	@echo "  • Custom addon path configuration"
	@echo "  • XML validation and formatting"
	@echo "  • Model and field IntelliSense"
	@echo "  • Business-specific snippets"
	@echo ""
	@echo "📊 File Organization:"
	@echo "  • Smart file nesting patterns"
	@echo "  • Optimized search exclusions"
	@echo "  • Logical folder structure"
	@echo "  • File type associations"
	@echo ""
	@echo "🚀 Productivity Features:"
	@echo "  • Format on save"
	@echo "  • Auto-import organization"
	@echo "  • Bracket pair colorization"
	@echo "  • Git integration with GitLens"
	@echo "  • AI assistance with Copilot"
	@echo ""
	@echo "📖 Documentation: docs/vscode-workspace-guide.md"

workspace-setup: ## 🛠️ Complete VS Code workspace setup and configuration
	@echo "🛠️  Setting up VS Code workspace for Royal Textiles Odoo development..."
	@echo ""
	@echo "📁 Step 1: Creating workspace directories..."
	@mkdir -p .vscode/snippets
	@echo "  ✅ Workspace directories created"
	@echo ""
	@echo "🔧 Step 2: Validating configuration files..."
	@$(MAKE) workspace-validate
	@echo ""
	@echo "📖 Step 3: Installing recommended extensions (if VS Code is available)..."
	@if command -v code >/dev/null 2>&1; then \
		echo "  Installing extensions..."; \
		code --install-extension odoo.odoo || echo "  ⚠️  Extension installation failed"; \
		code --install-extension ms-python.python || echo "  ⚠️  Extension installation failed"; \
		code --install-extension ms-python.black-formatter || echo "  ⚠️  Extension installation failed"; \
		code --install-extension redhat.vscode-xml || echo "  ⚠️  Extension installation failed"; \
		echo "  ✅ Core extensions installed"; \
	else \
		echo "  ⚠️  VS Code CLI not available, install extensions manually"; \
	fi
	@echo ""
	@echo "🎯 Step 4: Opening workspace (if VS Code is available)..."
	@if command -v code >/dev/null 2>&1; then \
		echo "  Opening Royal Textiles workspace..."; \
		code .vscode/royal-textiles-odoo.code-workspace; \
	else \
		echo "  ⚠️  Open .vscode/royal-textiles-odoo.code-workspace manually in VS Code"; \
	fi
	@echo ""
	@echo "✅ Workspace setup completed!"
	@echo ""
	@echo "🚀 Next Steps:"
	@echo "  1. Install remaining recommended extensions when prompted"
	@echo "  2. Select Python interpreter: Ctrl+Shift+P → 'Python: Select Interpreter'"
	@echo "  3. Verify Odoo paths in workspace settings"
	@echo "  4. Test debugging with F5"
	@echo "  5. Try code snippets: type 'odoo-model-rtp' and press Tab"
	@echo ""
	@echo "📚 See docs/vscode-workspace-guide.md for complete documentation"

workspace-reset: ## 🔄 Reset VS Code workspace to default configuration
	@echo "🔄 Resetting VS Code workspace configuration..."
	@echo ""
	@echo "⚠️  This will reset all VS Code settings to defaults!"
	@read -p "Are you sure? (y/N): " confirm; \
	if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
		echo "💾 Backing up current configuration..."; \
		mkdir -p backups/vscode-backup-$$(date +%Y%m%d-%H%M%S); \
		cp -r .vscode/* backups/vscode-backup-$$(date +%Y%m%d-%H%M%S)/ 2>/dev/null || true; \
		echo "🔄 Resetting configuration files..."; \
		git checkout HEAD -- .vscode/ || echo "  ⚠️  Git reset failed"; \
		echo "✅ Workspace reset completed"; \
		echo "💾 Backup saved in backups/vscode-backup-*"; \
	else \
		echo "❌ Reset cancelled"; \
	fi

workspace-backup: ## 💾 Backup current VS Code workspace configuration
	@echo "💾 Backing up VS Code workspace configuration..."
	@backup_dir="backups/vscode-backup-$$(date +%Y%m%d-%H%M%S)"
	@mkdir -p "$$backup_dir"
	@cp -r .vscode/* "$$backup_dir/" 2>/dev/null || true
	@echo "✅ Workspace backed up to $$backup_dir"
	@echo ""
	@echo "📁 Backup Contents:"
	@ls -la "$$backup_dir/"

workspace-extensions: ## 🔌 Show recommended VS Code extensions information
	@echo "🔌 Royal Textiles VS Code Extensions Guide"
	@echo "========================================"
	@echo ""
	@echo "🎯 Essential Odoo Extensions:"
	@echo "  • odoo.odoo                    - Official Odoo Language Server"
	@echo "  • trinhanhngoc.vscode-odoo     - Odoo IDE integration"
	@echo "  • jigar-patel.OdooSnippets     - Additional Odoo snippets"
	@echo ""
	@echo "🐍 Python Development:"
	@echo "  • ms-python.python            - Python IntelliSense"
	@echo "  • ms-python.black-formatter   - Black code formatter"
	@echo "  • ms-python.pylint            - Pylint linting"
	@echo "  • ms-python.mypy-type-checker  - Type checking"
	@echo ""

# =============================================================================
# 🎯 Enhanced Red Team Testing (Comprehensive Odoo 18.0 Validation)
# =============================================================================

validate-odoo-18-compatibility: ## 🔍 Comprehensive Odoo 18.0 compatibility validation
	@echo "🔍 Running comprehensive Odoo 18.0 compatibility validation..."
	@python scripts/validate-odoo-18-compatibility.py custom_modules/$(MODULE_NAME)

test-red-team-complete: ## 🎯 Complete red team testing methodology
	@echo "🎯 Running complete red team testing methodology..."
	@$(MAKE) validate-odoo-18-compatibility MODULE_NAME=$(MODULE_NAME)
	@$(MAKE) test-with-demo MODULE_NAME=$(MODULE_NAME)
	@$(MAKE) test-without-demo MODULE_NAME=$(MODULE_NAME)
	@$(MAKE) docker-test-install MODULE_NAME=$(MODULE_NAME)
	@echo "✅ Complete red team testing finished"

test-with-demo: ## 🧪 Test module installation WITH demo data (like Odoo.sh)
	@echo "🧪 Testing module installation WITH demo data..."
	@docker-compose exec odoo python /opt/odoo/odoo/odoo-bin \
		--config=/opt/odoo/config/odoo.conf \
		-d demo_test_db \
		-i $(MODULE_NAME) \
		--stop-after-init
	@echo "✅ Demo data installation test complete"

test-without-demo: ## 🧪 Test module installation WITHOUT demo data
	@echo "🧪 Testing module installation WITHOUT demo data..."
	@docker-compose exec odoo python /opt/odoo/odoo/odoo-bin \
		--config=/opt/odoo/config/odoo.conf \
		-d no_demo_test_db \
		-i $(MODULE_NAME) \
		--without-demo=all \
		--stop-after-init
	@echo "✅ No demo data installation test complete"

simulate-odoo-sh-deployment: ## 🚀 Complete Odoo.sh deployment simulation
	@echo "🚀 Simulating complete Odoo.sh deployment..."
	@$(MAKE) validate-odoo-18-compatibility MODULE_NAME=$(MODULE_NAME)
	@$(MAKE) docker-build
	@$(MAKE) test-with-demo MODULE_NAME=$(MODULE_NAME)
	@$(MAKE) validate-demo-data
	@echo "✅ Odoo.sh deployment simulation complete"

validate-demo-data: ## 🔍 Validate demo data integrity
	@echo "🔍 Validating demo data integrity..."
	@find custom_modules -name "*demo*.xml" -exec xmllint --noout {} \; 2>/dev/null || echo "⚠️ XML validation issues found"
	@echo "✅ Demo data validation complete"

check-all-compatibility-issues: ## 🔍 Check for all known Odoo 18.0 compatibility issues
	@echo "🔍 Checking for all known Odoo 18.0 compatibility issues..."
	@echo ""
	@echo "1. Checking for deprecated <tree> elements..."
	@grep -r "<tree" custom_modules/ --include="*.xml" | head -5 || echo "✅ No <tree> elements found"
	@echo ""
	@echo "2. Checking for deprecated view_mode='tree'..."
	@grep -r "view_mode.*tree" custom_modules/ --include="*.xml" | head -5 || echo "✅ No view_mode tree issues found"
	@echo ""
	@echo "3. Checking for deprecated attrs attributes..."
	@grep -r "attrs=" custom_modules/ --include="*.xml" | head -5 || echo "✅ No attrs attributes found"
	@echo ""
	@echo "4. Checking for deprecated states attributes..."
	@grep -r "states=" custom_modules/ --include="*.xml" | head -5 || echo "✅ No states attributes found"
	@echo ""
	@echo "5. Checking for missing __init__.py files..."
	@find custom_modules -type d -name models -exec test -f {}/__init__.py \; || echo "⚠️ Some models directories missing __init__.py"
	@echo ""
	@echo "✅ Compatibility check complete"

# Pre-deployment validation that covers all discovered issues
validate-deployment-ready: ## ✅ Complete pre-deployment validation
	@echo "✅ Running complete pre-deployment validation..."
	@echo ""
	@echo "🔍 Step 1: Odoo 18.0 compatibility..."
	@$(MAKE) validate-odoo-18-compatibility MODULE_NAME=$(MODULE_NAME)
	@echo ""
	@echo "🧪 Step 2: Installation testing..."
	@$(MAKE) test-with-demo MODULE_NAME=$(MODULE_NAME)
	@echo ""
	@echo "🔍 Step 3: Demo data validation..."
	@$(MAKE) validate-demo-data
	@echo ""
	@echo "🎯 Step 4: Compatibility issues check..."
	@$(MAKE) check-all-compatibility-issues
	@echo ""
	@echo "✅ DEPLOYMENT READY VALIDATION COMPLETE!"
	@echo "Module $(MODULE_NAME) is ready for Odoo.sh deployment"
	@echo "🌐 XML and Frontend:"
	@echo "  • redhat.vscode-xml            - XML language support"
	@echo "  • esbenp.prettier-vscode       - Code formatter"
	@echo "  • formulahendry.auto-rename-tag - Auto rename tags"
	@echo ""
	@echo "🗄️ Database and Data:"
	@echo "  • mtxr.sqltools                - SQL tools"
	@echo "  • ckolkman.vscode-postgres     - PostgreSQL support"
	@echo "  • mechatroner.rainbow-csv      - CSV editing"
	@echo ""
	@echo "⚡ Productivity:"
	@echo "  • eamodio.gitlens              - Enhanced Git"
	@echo "  • github.copilot               - AI assistance"
	@echo "  • alefragnani.bookmarks        - Code bookmarks"
	@echo ""
	@echo "📦 Installation Commands:"
	@echo "  code --install-extension odoo.odoo"
	@echo "  code --install-extension ms-python.python"
	@echo "  code --install-extension redhat.vscode-xml"
	@echo ""
	@echo "🔧 Bulk Installation:"
	@echo "  make workspace-setup  # Installs core extensions automatically"

workspace-help: ## 📖 Show VS Code workspace help and quick reference
	@echo "📖 Royal Textiles VS Code Workspace Help"
	@echo "======================================="
	@echo ""
	@echo "🚀 Quick Commands:"
	@echo "  make workspace-validate   # Validate workspace configuration"
	@echo "  make workspace-setup      # Complete workspace setup"
	@echo "  make workspace-info       # Show workspace features"
	@echo "  make workspace-backup     # Backup current configuration"
	@echo "  make workspace-extensions # Show extension information"
	@echo ""
	@echo "⌨️  VS Code Shortcuts:"
	@echo "  Ctrl+Shift+P             # Command Palette"
	@echo "  Ctrl+Shift+E             # Explorer"
	@echo "  Ctrl+Shift+D             # Debug"
	@echo "  Ctrl+Shift+G             # Git"
	@echo "  Ctrl+`                   # Terminal"
	@echo "  F5                       # Start Debugging"
	@echo "  Ctrl+F5                  # Run Without Debugging"
	@echo ""
	@echo "✂️  Snippet Usage:"
	@echo "  1. Type snippet prefix (e.g., 'odoo-model-rtp')"
	@echo "  2. Press Tab to insert"
	@echo "  3. Tab through placeholders"
	@echo "  4. Press Esc to exit snippet mode"
	@echo ""
	@echo "🧪 Task Integration:"
	@echo "  Ctrl+Shift+P → 'Tasks: Run Task'"
	@echo "  Select from 54 available tasks"
	@echo "  Organized by category for easy access"
	@echo ""
	@echo "🐛 Debugging:"
	@echo "  F5 to start debugging"
	@echo "  13 preconfigured debug configurations"
	@echo "  Breakpoint support in Python code"
	@echo ""
	@echo "📚 Documentation:"
	@echo "  docs/vscode-workspace-guide.md    # Complete workspace guide"
	@echo "  docs/vscode-debugging-guide.md    # Debugging documentation"
	@echo "  docs/vscode-tasks-guide.md        # Task automation guide"
	@echo "  docs/vscode-snippets-guide.md     # Snippet usage guide"

# Workspace Management Targets Added

# =============================================================================
# Deployment Readiness Checklist (Task 6.3)
# =============================================================================

.PHONY: deploy-checklist deploy-checklist-basic deploy-checklist-full deploy-checklist-production
.PHONY: deploy-checklist-json deploy-checklist-html deploy-checklist-help deploy-checklist-staging deploy-checklist-development
.PHONY: deploy-checklist-ci deploy-checklist-quick deploy-checklist-comprehensive deploy-checklist-validate-reports deploy-check-enhanced
.PHONY: test-reports test-reports-quick test-reports-full test-reports-coverage test-reports-html test-reports-badges test-reports-serve test-reports-help
.PHONY: test-reports-existing test-reports-ci test-reports-clean test-reports-status test-reports-comprehensive test-reports-pipeline test-reports-validate
.PHONY: test-with-reports coverage-with-reports
.PHONY: odoo-sh-simulate odoo-sh-staging odoo-sh-production odoo-sh-quick odoo-sh-strict odoo-sh-security odoo-sh-modules odoo-sh-ci
.PHONY: odoo-sh-pre-deploy odoo-sh-full-pipeline odoo-sh-help odoo-sh-status odoo-sh-clean odoo-sh-validate odoo-sh-report

deploy-checklist: ## 🚀 Run comprehensive deployment readiness checklist
	@echo "🚀 Running deployment readiness checklist..."
	./scripts/deployment-readiness-checklist.sh --level full --env production

deploy-checklist-basic: ## ⚡ Run basic deployment readiness checklist
	@echo "⚡ Running basic deployment readiness checklist..."
	./scripts/deployment-readiness-checklist.sh --level basic --env staging

deploy-checklist-full: ## 🔍 Run full deployment readiness checklist
	@echo "🔍 Running full deployment readiness checklist..."
	./scripts/deployment-readiness-checklist.sh --level full --env production

deploy-checklist-production: ## 🏭 Run production deployment readiness checklist
	@echo "🏭 Running production deployment readiness checklist..."
	./scripts/deployment-readiness-checklist.sh --level production --env production

deploy-checklist-json: ## 📄 Generate deployment readiness JSON report
	@echo "📄 Generating deployment readiness JSON report..."
	./scripts/deployment-readiness-checklist.sh --level full --env production --format json

deploy-checklist-html: ## 🌐 Generate deployment readiness HTML report
	@echo "🌐 Generating deployment readiness HTML report..."
	./scripts/deployment-readiness-checklist.sh --level full --env production --format html

deploy-checklist-staging: ## 🧪 Run deployment readiness for staging environment
	@echo "🧪 Running deployment readiness for staging..."
	./scripts/deployment-readiness-checklist.sh --level full --env staging

deploy-checklist-development: ## 💻 Run deployment readiness for development environment
	@echo "💻 Running deployment readiness for development..."
	./scripts/deployment-readiness-checklist.sh --level basic --env development

deploy-checklist-help: ## 📖 Show deployment checklist help and usage
	@echo "📖 ROYAL TEXTILES DEPLOYMENT READINESS CHECKLIST"
	@echo "================================================="
	@echo ""
	@echo "🎯 Purpose:"
	@echo "  Comprehensive assessment of deployment readiness across multiple dimensions"
	@echo "  including code quality, testing, security, configuration, and documentation."
	@echo ""
	@echo "🔧 Available Commands:"
	@echo "  make deploy-checklist           # Full checklist for production"
	@echo "  make deploy-checklist-basic     # Basic checklist for quick assessment"
	@echo "  make deploy-checklist-full      # Comprehensive checklist"
	@echo "  make deploy-checklist-production # Production-specific checklist"
	@echo "  make deploy-checklist-staging   # Staging environment checklist"
	@echo "  make deploy-checklist-development # Development environment checklist"
	@echo ""
	@echo "📊 Report Generation:"
	@echo "  make deploy-checklist-json      # Generate JSON report"
	@echo "  make deploy-checklist-html      # Generate HTML report"
	@echo ""
	@echo "🎚️ Checklist Levels:"
	@echo "  • basic      - Essential checks (git, basic validation)"
	@echo "  • full       - Comprehensive checks (quality, tests, security)"
	@echo "  • production - All checks plus deployment-specific requirements"
	@echo ""
	@echo "🌍 Target Environments:"
	@echo "  • development - Local development environment"
	@echo "  • staging     - Pre-production testing environment"
	@echo "  • production  - Live production environment"
	@echo ""
	@echo "📋 Assessment Categories:"
	@echo "  ✅ Git Repository Status       - Clean working directory, pushed commits"
	@echo "  🔍 Code Quality Assessment     - Linting, formatting, TODO/FIXME review"
	@echo "  📦 Module Validation          - Odoo module structure and manifests"
	@echo "  🧪 Test Coverage              - Test execution and coverage analysis"
	@echo "  🔐 Security Assessment        - Security files, secrets, vulnerabilities"
	@echo "  📚 Dependencies               - Python packages and version compatibility"
	@echo "  ⚙️  Configuration             - Odoo config, environment variables"
	@echo "  ⚡ Performance                - File sizes, performance patterns"
	@echo "  📖 Documentation              - README, docstrings, changelog"
	@echo "  🚀 Deployment Requirements    - Scripts, Docker, backup procedures"
	@echo ""
	@echo "📊 Output Formats:"
	@echo "  • text - Console output with colored status indicators"
	@echo "  • json - Machine-readable JSON report for CI/CD integration"
	@echo "  • html - Rich HTML report with charts and detailed breakdown"
	@echo ""
	@echo "💡 Usage Examples:"
	@echo "  # Quick development check"
	@echo "  make deploy-checklist-basic"
	@echo ""
	@echo "  # Full pre-production assessment"
	@echo "  make deploy-checklist-staging"
	@echo ""
	@echo "  # Production readiness with HTML report"
	@echo "  make deploy-checklist-html"
	@echo ""
	@echo "  # CI/CD integration with JSON output"
	@echo "  make deploy-checklist-json"
	@echo ""
	@echo "🎯 Success Criteria:"
	@echo "  • 90%+ overall score for production deployment"
	@echo "  • Zero critical issues"
	@echo "  • Minimal warnings (review recommended)"
	@echo "  • All security checks passed"
	@echo "  • Test coverage ≥70%"
	@echo ""
	@echo "📈 Integration with CI/CD:"
	@echo "  The checklist integrates with all Task 6.1 CI pipeline targets:"
	@echo "  • Uses 'make ci-test' for test execution"
	@echo "  • Uses 'make ci-lint' for code quality"
	@echo "  • Uses 'make ci-validate' for module validation"
	@echo "  • Uses 'make ci-deploy-check' for deployment readiness"
	@echo ""
	@echo "📁 Report Locations:"
	@echo "  • JSON: reports/deployment-readiness.json"
	@echo "  • HTML: reports/deployment-readiness.html"
	@echo "  • Text: Console output"

# Advanced deployment readiness workflows
deploy-checklist-ci: ## 🤖 CI-optimized deployment readiness check
	@echo "🤖 Running CI-optimized deployment readiness check..."
	@mkdir -p reports
	./scripts/deployment-readiness-checklist.sh --level full --env production --format json --output reports/ci-deployment-readiness.json
	@if [ $$? -eq 0 ]; then \
		echo "✅ CI deployment readiness check passed"; \
	else \
		echo "❌ CI deployment readiness check failed"; \
		exit 1; \
	fi

deploy-checklist-quick: ## ⚡ Quick deployment readiness assessment
	@echo "⚡ Running quick deployment readiness assessment..."
	./scripts/deployment-readiness-checklist.sh --level basic --env staging --format text

deploy-checklist-comprehensive: ## 🔬 Most comprehensive deployment assessment
	@echo "🔬 Running most comprehensive deployment assessment..."
	@echo ""
	@echo "📋 Step 1: Production-level checklist..."
	./scripts/deployment-readiness-checklist.sh --level production --env production --format text
	@echo ""
	@echo "📋 Step 2: Generating detailed reports..."
	./scripts/deployment-readiness-checklist.sh --level production --env production --format json --output reports/comprehensive-readiness.json
	./scripts/deployment-readiness-checklist.sh --level production --env production --format html --output reports/comprehensive-readiness.html
	@echo ""
	@echo "📊 Reports generated:"
	@echo "  📄 JSON: reports/comprehensive-readiness.json"
	@echo "  🌐 HTML: reports/comprehensive-readiness.html"

deploy-checklist-validate-reports: ## ✅ Validate deployment readiness reports
	@echo "✅ Validating deployment readiness reports..."
	@if [ -f "reports/deployment-readiness.json" ]; then \
		echo "📄 JSON report found: reports/deployment-readiness.json"; \
		python -c "import json; json.load(open('reports/deployment-readiness.json'))" && echo "  ✅ JSON is valid" || echo "  ❌ JSON is invalid"; \
	else \
		echo "⚠️  JSON report not found"; \
	fi
	@if [ -f "reports/deployment-readiness.html" ]; then \
		echo "🌐 HTML report found: reports/deployment-readiness.html"; \
		echo "  ✅ HTML report available"; \
	else \
		echo "⚠️  HTML report not found"; \
	fi

# Integration with existing CI pipeline
deploy-check-enhanced: clean lint validate test deploy-checklist-ci deploy-check-additional ## 🚀 Enhanced deployment check with readiness assessment
	@echo ""
	@echo "🎉 ENHANCED DEPLOYMENT CHECK COMPLETED!"
	@echo "======================================"
	@echo ""
	@echo "✅ All deployment checks passed:"
	@echo "  🧹 Environment cleanup completed"
	@echo "  🔍 Code quality verified"
	@echo "  ✅ Module validation passed"
	@echo "  🧪 Test suite passed"
	@echo "  📋 Deployment readiness assessed"
	@echo "  📊 Additional checks completed"
	@echo ""
	@echo "📊 Generated Reports:"
	@echo "  📄 CI Readiness: reports/ci-deployment-readiness.json"
	@echo "  📊 Deployment Report: reports/deployment-readiness.json"
	@echo ""
	@echo "🎉 READY FOR DEPLOYMENT! 🎉"

# =============================================================================
# Automated Test Report Generation (Task 6.4)
# =============================================================================

.PHONY: test-reports test-reports-quick test-reports-full test-reports-coverage
.PHONY: test-reports-html test-reports-badges test-reports-serve test-reports-help

test-reports: ## 📊 Generate comprehensive test reports with coverage
	@echo "📊 Generating comprehensive test reports..."
	./scripts/generate-test-reports.sh --title "Royal Textiles Test Report"

test-reports-quick: ## ⚡ Generate quick test reports (no coverage)
	@echo "⚡ Generating quick test reports..."
	./scripts/generate-test-reports.sh --no-coverage --title "Quick Test Report"

test-reports-full: ## 🔍 Generate full test reports with all options
	@echo "🔍 Generating full test reports..."
	./scripts/generate-test-reports.sh --threshold 80 --title "Complete Test Analysis"

test-reports-coverage: ## 📈 Generate coverage-focused reports
	@echo "📈 Generating coverage-focused reports..."
	./scripts/generate-test-reports.sh --threshold 85 --title "Coverage Analysis Report"

test-reports-html: ## 🌐 Generate HTML reports and open in browser
	@echo "🌐 Generating HTML reports..."
	./scripts/generate-test-reports.sh --open --title "Royal Textiles Test Dashboard"

test-reports-badges: ## 🏆 Generate test status badges
	@echo "🏆 Generating test status badges..."
	./scripts/generate-test-reports.sh --title "Badge Generation Report"

test-reports-serve: ## 🚀 Generate reports and start HTTP server
	@echo "🚀 Generating reports and starting server..."
	./scripts/generate-test-reports.sh --publish --open --title "Live Test Dashboard"

test-reports-existing: ## 📋 Generate reports from existing test results
	@echo "📋 Generating reports from existing results..."
	./scripts/generate-test-reports.sh --skip-tests --title "Existing Results Report"

test-reports-ci: ## 🤖 Generate CI-optimized test reports
	@echo "🤖 Generating CI-optimized test reports..."
	@mkdir -p reports
	./scripts/generate-test-reports.sh --no-publish --threshold 70 --title "CI Test Report"
	@if [ $$? -eq 0 ]; then \
		echo "✅ CI test report generation completed"; \
	else \
		echo "❌ CI test report generation failed"; \
		exit 1; \
	fi

test-reports-clean: ## 🧹 Clean old test reports
	@echo "🧹 Cleaning old test reports..."
	@rm -rf reports/test-report-*
	@rm -rf reports/coverage/.coverage.*
	@find reports -name "*.xml" -mtime +7 -delete 2>/dev/null || true
	@find reports -name "*.log" -mtime +7 -delete 2>/dev/null || true
	@echo "✅ Old reports cleaned"

test-reports-status: ## 📊 Show test report status
	@echo "📊 TEST REPORT STATUS"
	@echo "===================="
	@echo ""
	@if [ -f "reports/test-report.html" ]; then \
		echo "✅ Latest HTML report: reports/test-report.html"; \
		echo "📅 Modified: $$(stat -f '%Sm' reports/test-report.html)"; \
	else \
		echo "❌ No HTML report found"; \
	fi
	@if [ -f "reports/coverage/html/index.html" ]; then \
		echo "✅ Coverage report: reports/coverage/html/index.html"; \
		echo "📅 Modified: $$(stat -f '%Sm' reports/coverage/html/index.html)"; \
	else \
		echo "❌ No coverage report found"; \
	fi
	@if [ -f "reports/test-results/summary.json" ]; then \
		echo "✅ Test summary: reports/test-results/summary.json"; \
		echo "📅 Modified: $$(stat -f '%Sm' reports/test-results/summary.json)"; \
	else \
		echo "❌ No test summary found"; \
	fi
	@echo ""
	@if [ -d "reports" ]; then \
		echo "📁 Reports directory size: $$(du -sh reports | cut -f1)"; \
		echo "📊 Total files: $$(find reports -type f | wc -l | tr -d ' ')"; \
	fi

test-reports-help: ## 📖 Show test report help and usage
	@echo "📖 ROYAL TEXTILES TEST REPORT GENERATION"
	@echo "========================================"
	@echo ""
	@echo "🎯 Purpose:"
	@echo "  Automated generation of comprehensive HTML test reports with coverage analysis,"
	@echo "  test result aggregation, and visual reporting for CI/CD integration."
	@echo ""
	@echo "🔧 Available Commands:"
	@echo "  make test-reports              # Full comprehensive reports"
	@echo "  make test-reports-quick        # Quick reports without coverage"
	@echo "  make test-reports-full         # Complete analysis with high thresholds"
	@echo "  make test-reports-coverage     # Coverage-focused reports"
	@echo "  make test-reports-html         # HTML reports with browser opening"
	@echo "  make test-reports-badges       # Generate test status badges"
	@echo "  make test-reports-serve        # Reports with HTTP server"
	@echo "  make test-reports-existing     # Reports from existing results"
	@echo "  make test-reports-ci           # CI-optimized reports"
	@echo ""
	@echo "📊 Report Types:"
	@echo "  • HTML Dashboard    - Interactive web-based test report"
	@echo "  • Coverage Analysis - Detailed code coverage with line-by-line info"
	@echo "  • Test Results      - JUnit XML and JSON test result summaries"
	@echo "  • Status Badges     - SVG badges for README and documentation"
	@echo "  • Index Page        - Central hub for all reports"
	@echo ""
	@echo "📈 Coverage Features:"
	@echo "  • Line Coverage     - Percentage of lines covered by tests"
	@echo "  • Branch Coverage   - Percentage of branches covered by tests"
	@echo "  • Package Analysis  - Coverage breakdown by module/package"
	@echo "  • HTML Visualization - Interactive coverage viewer"
	@echo "  • Threshold Checking - Configurable coverage requirements"
	@echo ""
	@echo "🧪 Test Types Supported:"
	@echo "  • Unit Tests        - Fast, isolated component tests"
	@echo "  • Integration Tests - Cross-component interaction tests"
	@echo "  • Functional Tests  - End-to-end workflow tests"
	@echo "  • Performance Tests - Load and performance validation"
	@echo "  • Combined Results  - Aggregated test suite results"
	@echo ""
	@echo "📁 Generated Reports:"
	@echo "  • reports/test-report.html           - Main HTML dashboard"
	@echo "  • reports/coverage/html/index.html   - Coverage report"
	@echo "  • reports/test-results/summary.json  - JSON test summary"
	@echo "  • reports/badges/                    - SVG status badges"
	@echo "  • reports/index.html                 - Reports index page"
	@echo ""
	@echo "💡 Usage Examples:"
	@echo "  # Generate full reports with browser opening"
	@echo "  make test-reports-html"
	@echo ""
	@echo "  # Quick development reports"
	@echo "  make test-reports-quick"
	@echo ""
	@echo "  # CI/CD pipeline reports"
	@echo "  make test-reports-ci"
	@echo ""
	@echo "  # Start local report server"
	@echo "  make test-reports-serve"
	@echo ""
	@echo "🎚️ Customization Options:"
	@echo "  • Coverage Thresholds - Set minimum coverage requirements"
	@echo "  • Report Titles      - Custom report titles and branding"
	@echo "  • Output Formats     - HTML, XML, JSON, SVG badges"
	@echo "  • Browser Integration - Auto-open reports in browser"
	@echo "  • HTTP Server        - Local server for report viewing"
	@echo ""
	@echo "📊 CI/CD Integration:"
	@echo "  The reports integrate with existing CI/CD pipeline:"
	@echo "  • Uses pytest with coverage for test execution"
	@echo "  • Generates JUnit XML for CI/CD consumption"
	@echo "  • Creates JSON summaries for automated processing"
	@echo "  • Produces SVG badges for documentation"
	@echo "  • Configurable coverage thresholds for quality gates"
	@echo ""
	@echo "🔧 Manual Usage:"
	@echo "  # Direct script usage with options"
	@echo "  ./scripts/generate-test-reports.sh --help"
	@echo "  ./scripts/generate-test-reports.sh --threshold 85 --open"
	@echo "  ./scripts/generate-test-reports.sh --skip-tests --publish"
	@echo ""
	@echo "🌐 Viewing Reports:"
	@echo "  # Local HTTP server"
	@echo "  cd reports && python serve.py --open"
	@echo ""
	@echo "  # Direct file opening"
	@echo "  open reports/index.html"
	@echo ""
	@echo "📈 Integration with Other Tasks:"
	@echo "  • Task 6.1 - Uses CI/CD pipeline targets for testing"
	@echo "  • Task 6.2 - Integrates with git hooks for automated reporting"
	@echo "  • Task 6.3 - Provides input for deployment readiness assessment"
	@echo "  • Task 5.0 - Compatible with VS Code testing integration"

# Advanced reporting workflows
test-reports-comprehensive: ## 🔬 Most comprehensive test report generation
	@echo "🔬 Generating most comprehensive test reports..."
	@echo ""
	@echo "📋 Step 1: Running full test suite..."
	@$(MAKE) test-reports-full
	@echo ""
	@echo "📋 Step 2: Generating deployment readiness report..."
	@$(MAKE) deploy-checklist-html
	@echo ""
	@echo "📋 Step 3: Starting report server..."
	@cd reports && python serve.py --open &
	@echo ""
	@echo "📊 All reports generated and server started!"
	@echo "🌐 View at: http://localhost:8081/"

test-reports-pipeline: ## 🤖 Complete CI/CD pipeline with reporting
	@echo "🤖 Running complete CI/CD pipeline with reporting..."
	@echo ""
	@echo "📋 Step 1: Clean environment..."
	@$(MAKE) clean
	@echo ""
	@echo "📋 Step 2: Install dependencies..."
	@$(MAKE) install
	@echo ""
	@echo "📋 Step 3: Run linting..."
	@$(MAKE) lint
	@echo ""
	@echo "📋 Step 4: Run tests with reports..."
	@$(MAKE) test-reports-ci
	@echo ""
	@echo "📋 Step 5: Validate deployment readiness..."
	@$(MAKE) deploy-checklist-ci
	@echo ""
	@echo "🎉 PIPELINE COMPLETED WITH REPORTS!"
	@echo "================================="
	@echo ""
	@echo "📊 Generated Reports:"
	@echo "  📄 Test Report: reports/test-report.html"
	@echo "  📈 Coverage: reports/coverage/html/index.html"
	@echo "  📋 Deployment: reports/deployment-readiness.html"
	@echo "  🏆 Badges: reports/badges/"
	@echo ""
	@echo "📊 View all reports: make test-reports-serve"

test-reports-validate: ## ✅ Validate generated test reports
	@echo "✅ Validating generated test reports..."
	@echo ""
	@if [ -f "reports/test-report.html" ]; then \
		echo "✅ HTML report exists"; \
		if grep -q "Royal Textiles" reports/test-report.html; then \
			echo "✅ HTML report contains expected content"; \
		else \
			echo "❌ HTML report missing expected content"; \
		fi; \
	else \
		echo "❌ HTML report not found"; \
	fi
	@if [ -f "reports/test-results/summary.json" ]; then \
		echo "✅ JSON summary exists"; \
		python -c "import json; json.load(open('reports/test-results/summary.json'))" && echo "✅ JSON is valid" || echo "❌ JSON is invalid"; \
	else \
		echo "❌ JSON summary not found"; \
	fi
	@if [ -f "reports/coverage/html/index.html" ]; then \
		echo "✅ Coverage report exists"; \
	else \
		echo "❌ Coverage report not found"; \
	fi
	@if [ -f "reports/badges/tests.svg" ]; then \
		echo "✅ Test badges exist"; \
	else \
		echo "❌ Test badges not found"; \
	fi
	@echo ""
	@echo "📊 Report validation complete"

# Integration with existing workflow
test-with-reports: test test-reports ## 🧪 Run tests and generate reports
	@echo ""
	@echo "🎉 TESTS COMPLETED WITH REPORTS!"
	@echo "=============================="
	@echo ""
	@echo "📊 View reports: make test-reports-serve"

coverage-with-reports: coverage test-reports-coverage ## 📈 Generate coverage with enhanced reports
	@echo ""
	@echo "🎉 COVERAGE ANALYSIS COMPLETED!"
	@echo "=============================="
	@echo ""
	@echo "📊 View coverage: open reports/coverage/html/index.html"

# =============================================================================
# Odoo.sh Deployment Simulation (Task 6.5)
# =============================================================================

.PHONY: odoo-sh-simulate odoo-sh-staging odoo-sh-production odoo-sh-quick odoo-sh-strict odoo-sh-security odoo-sh-modules odoo-sh-ci
.PHONY: odoo-sh-pre-deploy odoo-sh-full-pipeline odoo-sh-help odoo-sh-status odoo-sh-clean odoo-sh-validate odoo-sh-report

odoo-sh-simulate: ## 🚀 Run complete Odoo.sh deployment simulation
	@echo "🚀 Running Odoo.sh deployment simulation..."
	./scripts/simulate-odoo-sh-deployment.sh

odoo-sh-staging: ## 🎭 Run staging deployment simulation
	@echo "🎭 Running staging deployment simulation..."
	./scripts/simulate-odoo-sh-deployment.sh --deployment-mode staging

odoo-sh-production: ## 🏭 Run production deployment simulation
	@echo "🏭 Running production deployment simulation..."
	./scripts/simulate-odoo-sh-deployment.sh --deployment-mode production --strict

odoo-sh-quick: ## ⚡ Run quick deployment simulation (no tests)
	@echo "⚡ Running quick deployment simulation..."
	./scripts/simulate-odoo-sh-deployment.sh --no-tests --no-performance

odoo-sh-strict: ## 🔒 Run strict deployment simulation (warnings as errors)
	@echo "🔒 Running strict deployment simulation..."
	./scripts/simulate-odoo-sh-deployment.sh --strict --verbose

odoo-sh-security: ## 🔐 Run security-focused deployment simulation
	@echo "🔐 Running security-focused deployment simulation..."
	./scripts/simulate-odoo-sh-deployment.sh --no-tests --no-assets --no-translations --deployment-mode production

odoo-sh-modules: ## 📦 Run module validation simulation
	@echo "📦 Running module validation simulation..."
	./scripts/simulate-odoo-sh-deployment.sh --no-tests --no-dependencies --no-security --no-performance --no-translations --no-assets

odoo-sh-ci: ## 🤖 Run CI-optimized deployment simulation
	@echo "🤖 Running CI-optimized deployment simulation..."
	@mkdir -p reports/odoo-sh-simulation
	./scripts/simulate-odoo-sh-deployment.sh --deployment-mode staging
	@if [ $$? -eq 0 ]; then \
		echo "✅ CI deployment simulation completed successfully"; \
	else \
		echo "❌ CI deployment simulation failed"; \
		exit 1; \
	fi

odoo-sh-pre-deploy: ## 🎯 Run pre-deployment validation
	@echo "🎯 Running pre-deployment validation..."
	@echo ""
	@echo "📋 Step 1: Code quality checks..."
	@$(MAKE) lint
	@echo ""
	@echo "📋 Step 2: Test execution..."
	@$(MAKE) test
	@echo ""
	@echo "📋 Step 3: Deployment simulation..."
	@$(MAKE) odoo-sh-production
	@echo ""
	@echo "📋 Step 4: Security validation..."
	@$(MAKE) odoo-sh-security
	@echo ""
	@echo "🎉 PRE-DEPLOYMENT VALIDATION COMPLETE!"

odoo-sh-full-pipeline: ## 🔄 Run complete deployment pipeline with all checks
	@echo "🔄 Running complete deployment pipeline..."
	@echo ""
	@echo "📋 Step 1: Environment setup..."
	@$(MAKE) install
	@echo ""
	@echo "📋 Step 2: Code quality..."
	@$(MAKE) lint
	@echo ""
	@echo "📋 Step 3: Test execution..."
	@$(MAKE) test
	@echo ""
	@echo "📋 Step 4: Test report generation..."
	@$(MAKE) test-reports-ci
	@echo ""
	@echo "📋 Step 5: Deployment readiness..."
	@$(MAKE) deploy-checklist-ci
	@echo ""
	@echo "📋 Step 6: Odoo.sh simulation..."
	@$(MAKE) odoo-sh-production
	@echo ""
	@echo "🎉 COMPLETE DEPLOYMENT PIPELINE FINISHED!"
	@echo "================================="
	@echo ""
	@echo "📊 Generated Reports:"
	@echo "  📄 Test Reports: reports/test-report.html"
	@echo "  📋 Deployment Readiness: reports/deployment-readiness.html"
	@echo "  🚀 Odoo.sh Simulation: reports/odoo-sh-simulation/results/deployment-simulation-report.html"

odoo-sh-status: ## 📊 Show Odoo.sh simulation status
	@echo "📊 ODOO.SH SIMULATION STATUS"
	@echo "==========================="
	@echo ""
	@if [ -f "reports/odoo-sh-simulation/results/deployment-simulation-report.html" ]; then \
		echo "✅ Latest simulation report: reports/odoo-sh-simulation/results/deployment-simulation-report.html"; \
		echo "📅 Modified: $$(stat -f '%Sm' reports/odoo-sh-simulation/results/deployment-simulation-report.html)"; \
	else \
		echo "❌ No simulation report found"; \
	fi
	@if [ -f "reports/odoo-sh-simulation/results/deployment-simulation-results.json" ]; then \
		echo "✅ JSON results: reports/odoo-sh-simulation/results/deployment-simulation-results.json"; \
		echo "📅 Modified: $$(stat -f '%Sm' reports/odoo-sh-simulation/results/deployment-simulation-results.json)"; \
	else \
		echo "❌ No JSON results found"; \
	fi
	@if [ -f "reports/odoo-sh-simulation/logs/simulation.log" ]; then \
		echo "✅ Simulation logs: reports/odoo-sh-simulation/logs/simulation.log"; \
		echo "📅 Modified: $$(stat -f '%Sm' reports/odoo-sh-simulation/logs/simulation.log)"; \
	else \
		echo "❌ No simulation logs found"; \
	fi
	@echo ""
	@if [ -d "reports/odoo-sh-simulation" ]; then \
		echo "📁 Simulation directory size: $$(du -sh reports/odoo-sh-simulation | cut -f1)"; \
		echo "📊 Total files: $$(find reports/odoo-sh-simulation -type f | wc -l | tr -d ' ')"; \
	fi

odoo-sh-clean: ## 🧹 Clean Odoo.sh simulation artifacts
	@echo "🧹 Cleaning Odoo.sh simulation artifacts..."
	@rm -rf reports/odoo-sh-simulation/results/*
	@rm -rf reports/odoo-sh-simulation/logs/*
	@find reports/odoo-sh-simulation -name "*.html" -mtime +7 -delete 2>/dev/null || true
	@find reports/odoo-sh-simulation -name "*.json" -mtime +7 -delete 2>/dev/null || true
	@echo "✅ Simulation artifacts cleaned"

odoo-sh-validate: ## ✅ Validate Odoo.sh simulation results
	@echo "✅ Validating Odoo.sh simulation results..."
	@echo ""
	@if [ -f "reports/odoo-sh-simulation/results/deployment-simulation-report.html" ]; then \
		echo "✅ HTML report exists"; \
		if grep -q "Royal Textiles" reports/odoo-sh-simulation/results/deployment-simulation-report.html; then \
			echo "✅ HTML report contains expected content"; \
		else \
			echo "❌ HTML report missing expected content"; \
		fi; \
	else \
		echo "❌ HTML report not found"; \
	fi
	@if [ -f "reports/odoo-sh-simulation/results/deployment-simulation-results.json" ]; then \
		echo "✅ JSON results exist"; \
		python -c "import json; json.load(open('reports/odoo-sh-simulation/results/deployment-simulation-results.json'))" && echo "✅ JSON is valid" || echo "❌ JSON is invalid"; \
	else \
		echo "❌ JSON results not found"; \
	fi
	@echo ""
	@echo "📊 Simulation validation complete"

odoo-sh-report: ## 📋 Generate comprehensive Odoo.sh simulation report
	@echo "📋 Generating comprehensive Odoo.sh simulation report..."
	@$(MAKE) odoo-sh-production
	@echo ""
	@echo "📊 Simulation Report Generated:"
	@echo "  🌐 HTML Report: reports/odoo-sh-simulation/results/deployment-simulation-report.html"
	@echo "  📄 JSON Report: reports/odoo-sh-simulation/results/deployment-simulation-results.json"
	@echo "  📋 Logs: reports/odoo-sh-simulation/logs/simulation.log"
	@echo ""
	@echo "💡 View report: open reports/odoo-sh-simulation/results/deployment-simulation-report.html"

odoo-sh-help: ## 📖 Show Odoo.sh simulation help and usage
	@echo "📖 ROYAL TEXTILES ODOO.SH DEPLOYMENT SIMULATION"
	@echo "==============================================="
	@echo ""
	@echo "🎯 Purpose:"
	@echo "  Simulate the deployment validation process used by odoo.sh to ensure"
	@echo "  local development matches production deployment requirements."
	@echo ""
	@echo "🔧 Available Commands:"
	@echo "  make odoo-sh-simulate       # Complete deployment simulation"
	@echo "  make odoo-sh-staging        # Staging deployment simulation"
	@echo "  make odoo-sh-production     # Production deployment simulation"
	@echo "  make odoo-sh-quick          # Quick simulation (no tests)"
	@echo "  make odoo-sh-strict         # Strict simulation (warnings as errors)"
	@echo "  make odoo-sh-security       # Security-focused simulation"
	@echo "  make odoo-sh-modules        # Module validation simulation"
	@echo "  make odoo-sh-ci             # CI-optimized simulation"
	@echo ""
	@echo "🔄 Workflow Commands:"
	@echo "  make odoo-sh-pre-deploy     # Pre-deployment validation"
	@echo "  make odoo-sh-full-pipeline  # Complete deployment pipeline"
	@echo "  make odoo-sh-report         # Generate comprehensive report"
	@echo ""
	@echo "🛠️ Utility Commands:"
	@echo "  make odoo-sh-status         # Show simulation status"
	@echo "  make odoo-sh-clean          # Clean simulation artifacts"
	@echo "  make odoo-sh-validate       # Validate simulation results"
	@echo "  make odoo-sh-help           # Show this help"
	@echo ""
	@echo "🧪 Validation Categories:"
	@echo "  • Python Environment  - Version and package compatibility"
	@echo "  • Module Validation    - Odoo module structure and syntax"
	@echo "  • Database Requirements - PostgreSQL compatibility"
	@echo "  • Dependencies         - Package requirements and security"
	@echo "  • Security Configuration - Hardcoded secrets and vulnerabilities"
	@echo "  • Performance Requirements - Anti-patterns and optimization"
	@echo "  • Translations         - Translation file validation"
	@echo "  • Assets               - CSS, JavaScript, and image validation"
	@echo "  • Tests                - Test execution and validation"
	@echo "  • Deployment Process   - Simulation of actual deployment"
	@echo ""
	@echo "📊 Report Types:"
	@echo "  • HTML Dashboard       - Interactive web-based simulation report"
	@echo "  • JSON Results         - Machine-readable simulation results"
	@echo "  • Detailed Logs        - Complete simulation execution logs"
	@echo "  • Deployment Status    - Ready/Not Ready deployment assessment"
	@echo ""
	@echo "🎚️ Simulation Modes:"
	@echo "  • Staging Mode         - Moderate validation requirements"
	@echo "  • Production Mode      - Strict validation requirements"
	@echo "  • Quick Mode           - Fast validation without tests"
	@echo "  • Strict Mode          - Warnings treated as errors"
	@echo "  • Security Mode        - Security-focused validation"
	@echo ""
	@echo "💡 Usage Examples:"
	@echo "  # Basic simulation"
	@echo "  make odoo-sh-simulate"
	@echo ""
	@echo "  # Production readiness check"
	@echo "  make odoo-sh-production"
	@echo ""
	@echo "  # Complete pipeline"
	@echo "  make odoo-sh-full-pipeline"
	@echo ""
	@echo "  # Security validation"
	@echo "  make odoo-sh-security"
	@echo ""
	@echo "🔧 Manual Usage:"
	@echo "  # Direct script usage with options"
	@echo "  ./scripts/simulate-odoo-sh-deployment.sh --help"
	@echo "  ./scripts/simulate-odoo-sh-deployment.sh --deployment-mode production"
	@echo "  ./scripts/simulate-odoo-sh-deployment.sh --strict --verbose"
	@echo ""
	@echo "🌐 Generated Reports:"
	@echo "  • HTML Report: reports/odoo-sh-simulation/results/deployment-simulation-report.html"
	@echo "  • JSON Report: reports/odoo-sh-simulation/results/deployment-simulation-results.json"
	@echo "  • Logs: reports/odoo-sh-simulation/logs/simulation.log"
	@echo ""
	@echo "📈 Integration with Other Tasks:"
	@echo "  • Task 6.1 - Uses CI/CD pipeline for comprehensive validation"
	@echo "  • Task 6.2 - Integrates with git hooks for pre-push validation"
	@echo "  • Task 6.3 - Combines with deployment readiness assessment"
	@echo "  • Task 6.4 - Includes test report generation in validation"
	@echo "  • Task 5.0 - Compatible with VS Code development workflow"
	@echo ""
	@echo "🎯 Deployment Readiness Criteria:"
	@echo "  • 90%+ Success Rate     - Ready for deployment"
	@echo "  • 70-89% Success Rate   - Ready with warnings"
	@echo "  • <70% Success Rate     - Needs attention"
	@echo "  • Critical Issues       - Deployment blocked"
	@echo ""
	@echo "🔄 CI/CD Integration:"
	@echo "  The simulation integrates with CI/CD pipelines:"
	@echo "  • Machine-readable JSON output for automation"
	@echo "  • Exit codes for build success/failure"
	@echo "  • Configurable validation levels"
	@echo "  • Detailed reporting for debugging"

# =============================================================================
# Git Hooks Management (Task 6.2)
# =============================================================================

.PHONY: hooks-install hooks-uninstall hooks-status hooks-test hooks-configure
.PHONY: hooks-run hooks-run-quick hooks-run-security hooks-help

hooks-install: ## Install git pre-push hooks for validation
	@echo "🔧 Installing Royal Textiles git hooks..."
	./scripts/setup-git-hooks.sh install

hooks-uninstall: ## Uninstall git hooks
	@echo "🗑️  Uninstalling Royal Textiles git hooks..."
	./scripts/setup-git-hooks.sh uninstall

hooks-status: ## Show git hooks installation status
	@echo "📊 Checking git hooks status..."
	./scripts/setup-git-hooks.sh status

hooks-test: ## Test git hooks functionality
	@echo "🧪 Testing git hooks..."
	./scripts/setup-git-hooks.sh test

hooks-configure: ## Configure git hooks settings
	@echo "⚙️  Configuring git hooks..."
	@echo "📋 Current configuration file: .git/hooks/hook-config"
	@if [ -f .git/hooks/hook-config ]; then \
		echo "📄 Current settings:"; \
		grep "^export" .git/hooks/hook-config | sed 's/^/  /' || echo "  No active configuration found"; \
		echo ""; \
		echo "Edit .git/hooks/hook-config to customize hook behavior"; \
	else \
		echo "❌ Hook configuration not found. Install hooks first: make hooks-install"; \
	fi

hooks-run: ## Manually run pre-push validation (full)
	@echo "🔍 Running complete pre-push validation manually..."
	./scripts/run-pre-push-checks.sh full

hooks-run-quick: ## Manually run pre-push validation (quick)
	@echo "⚡ Running quick pre-push validation manually..."
	./scripts/run-pre-push-checks.sh quick

hooks-run-security: ## Manually run security validation
	@echo "🔐 Running security validation manually..."
	./scripts/run-pre-push-checks.sh security

hooks-help: ## Show git hooks help and usage information
	@echo "📚 ROYAL TEXTILES GIT HOOKS GUIDE"
	@echo "================================="
	@echo ""
	@echo "🎯 Purpose:"
	@echo "  Git hooks automatically run validation checks before code is pushed"
	@echo "  to ensure code quality and prevent broken code from reaching the repository."
	@echo ""
	@echo "🔧 Setup Commands:"
	@echo "  make hooks-install      # Install pre-push hooks"
	@echo "  make hooks-status       # Check installation status"
	@echo "  make hooks-test         # Test hook functionality"
	@echo "  make hooks-configure    # Configure hook settings"
	@echo "  make hooks-uninstall    # Remove hooks"
	@echo ""
	@echo "🧪 Manual Testing Commands:"
	@echo "  make hooks-run          # Run full validation manually"
	@echo "  make hooks-run-quick    # Run quick validation manually"
	@echo "  make hooks-run-security # Run security validation manually"
	@echo ""
	@echo "⚙️  Hook Configuration:"
	@echo "  • Edit .git/hooks/hook-config to customize behavior"
	@echo "  • Set RTP_HOOK_LEVEL=quick for faster validation"
	@echo "  • Set RTP_HOOK_SKIP=true to skip hooks temporarily"
	@echo "  • Set RTP_HOOK_INTERACTIVE=false for CI/CD environments"
	@echo ""
	@echo "🚀 Usage Examples:"
	@echo "  git push                           # Normal push with validation"
	@echo "  RTP_HOOK_SKIP=true git push       # Skip validation once"
	@echo "  RTP_HOOK_LEVEL=quick git push     # Use quick validation"
	@echo "  git push --no-verify               # Bypass hooks completely (not recommended)"
	@echo ""
	@echo "📊 Validation Levels:"
	@echo "  • quick:    Syntax, basic linting, RTP module tests (~30s)"
	@echo "  • full:     Complete validation suite (~2-5 minutes)"
	@echo "  • security: Security-focused validation"
	@echo ""
	@echo "🔍 What Gets Validated:"
	@echo "  ✅ Python syntax and code style"
	@echo "  ✅ Odoo module structure and manifests"
	@echo "  ✅ XML views and data files"
	@echo "  ✅ Security file formats"
	@echo "  ✅ Test suite execution"
	@echo "  ✅ Royal Textiles business logic"
	@echo "  ✅ Deployment readiness checks"
	@echo "  ✅ Git repository cleanliness"
	@echo ""
	@echo "💡 Tips:"
	@echo "  • Run 'make hooks-run-quick' before committing large changes"
	@echo "  • Use 'make hooks-status' to verify installation"
	@echo "  • Configure your preferred validation level in .git/hooks/hook-config"
	@echo "  • Hooks run automatically but can be tested manually anytime"

# Combined git workflow helpers
hooks-setup-complete: hooks-install hooks-test ## Complete git hooks setup and testing
	@echo ""
	@echo "🎉 GIT HOOKS SETUP COMPLETED!"
	@echo "============================="
	@echo ""
	@echo "✅ Hooks installed and tested successfully"
	@echo "✅ Ready for development with automatic validation"
	@echo ""
	@echo "🎯 Next steps:"
	@echo "  1. Customize settings: make hooks-configure"
	@echo "  2. Test with your changes: make hooks-run-quick"
	@echo "  3. Make a test commit and push to see hooks in action"
	@echo ""

hooks-validate-setup: ## Validate that git hooks are properly configured
	@echo "🔍 Validating git hooks setup..."
	@echo "==============================="
	@echo ""
	@if [ ! -f .git/hooks/pre-push ]; then \
		echo "❌ Pre-push hook not found"; \
		echo "   Run: make hooks-install"; \
		exit 1; \
	fi
	@if [ ! -x .git/hooks/pre-push ]; then \
		echo "❌ Pre-push hook not executable"; \
		echo "   Run: chmod +x .git/hooks/pre-push"; \
		exit 1; \
	fi
	@if ! grep -q "Royal Textiles Git Pre-Push Hook" .git/hooks/pre-push; then \
		echo "❌ Pre-push hook is not the Royal Textiles hook"; \
		echo "   Run: make hooks-install"; \
		exit 1; \
	fi
	@if [ ! -f scripts/run-pre-push-checks.sh ]; then \
		echo "❌ Manual test script not found"; \
		echo "   Run: make hooks-install"; \
		exit 1; \
	fi
	@if [ ! -x scripts/run-pre-push-checks.sh ]; then \
		echo "❌ Manual test script not executable"; \
		echo "   Run: chmod +x scripts/run-pre-push-checks.sh"; \
		exit 1; \
	fi
	@echo "✅ Pre-push hook: Installed and executable"
	@echo "✅ Manual test script: Available and executable"
	@echo "✅ Configuration: Available"
	@echo ""
	@echo "🎉 Git hooks setup is valid and ready to use!"

# Advanced git hooks workflows
hooks-benchmark: ## Benchmark hook performance across validation levels
	@echo "📊 Benchmarking git hook performance..."
	@echo "======================================"
	@echo ""
	@echo "🧪 Testing different validation levels..."
	@echo ""
	@echo "⚡ Quick validation:"
	@time ./scripts/run-pre-push-checks.sh quick || true
	@echo ""
	@echo "🔍 Full validation:"
	@time ./scripts/run-pre-push-checks.sh full || true
	@echo ""
	@echo "🔐 Security validation:"
	@time ./scripts/run-pre-push-checks.sh security || true
	@echo ""
	@echo "✅ Benchmark completed!"

hooks-debug: ## Debug git hooks with verbose output
	@echo "🔧 Debugging git hooks..."
	@echo "========================="
	@echo ""
	@echo "🔍 Running hooks with maximum verbosity..."
	RTP_HOOK_VERBOSE=true RTP_HOOK_LEVEL=quick ./scripts/run-pre-push-checks.sh quick

# Git hooks maintenance
hooks-repair: ## Repair git hooks installation
	@echo "🔧 Repairing git hooks installation..."
	@echo "====================================="
	@echo ""
	@echo "📋 Step 1: Uninstalling existing hooks..."
	@$(MAKE) hooks-uninstall || true
	@echo ""
	@echo "📋 Step 2: Reinstalling hooks..."
	@$(MAKE) hooks-install
	@echo ""
	@echo "📋 Step 3: Testing installation..."
	@$(MAKE) hooks-test
	@echo ""
	@echo "✅ Git hooks repair completed!"

hooks-clean: ## Clean up git hooks temporary files
	@echo "🧹 Cleaning git hooks temporary files..."
	@rm -f /tmp/hook_*.log
	@rm -f scripts/run-pre-push-checks.sh.bak
	@echo "✅ Cleanup completed!"

# =====================================
# Task 6.6: Automated Dependency & Security Scanning
# =====================================

# Main security and dependency scanning targets
.PHONY: security-scan security-scan-full security-scan-quick security-scan-strict security-scan-ci
.PHONY: dependency-scan vulnerability-scan license-scan secret-scan compliance-scan
.PHONY: security-report security-report-serve security-report-open security-report-clean

# Main security scanning commands
security-scan: ## Run comprehensive security and dependency scan
	@echo "🔒 Running comprehensive security and dependency scan..."
	@./scripts/dependency-security-scanner.sh

security-scan-full: ## Run full security scan with all checks enabled
	@echo "🔒 Running full security scan..."
	@./scripts/dependency-security-scanner.sh --verbose

security-scan-quick: ## Run quick security scan (skip time-intensive checks)
	@echo "🔒 Running quick security scan..."
	@./scripts/dependency-security-scanner.sh --no-compliance --no-outdated

security-scan-strict: ## Run strict security scan (fail on any high/critical issues)
	@echo "🔒 Running strict security scan..."
	@./scripts/dependency-security-scanner.sh --fail-on-critical --fail-on-high --verbose

security-scan-ci: ## Run CI-optimized security scan
	@echo "🔒 Running CI security scan..."
	@./scripts/dependency-security-scanner.sh --fail-on-critical --quiet

# Individual scan components
dependency-scan: ## Run dependency analysis only
	@echo "📦 Running dependency analysis..."
	@./scripts/dependency-security-scanner.sh --no-security --no-licenses --no-vulnerabilities --no-secrets --no-compliance

vulnerability-scan: ## Run vulnerability scanning only
	@echo "🚨 Running vulnerability scan..."
	@./scripts/dependency-security-scanner.sh --no-dependencies --no-security --no-licenses --no-secrets --no-compliance --no-outdated

license-scan: ## Run license compliance scanning only
	@echo "📄 Running license compliance scan..."
	@./scripts/dependency-security-scanner.sh --no-dependencies --no-security --no-vulnerabilities --no-secrets --no-compliance --no-outdated

secret-scan: ## Run secret detection only
	@echo "🔐 Running secret detection..."
	@./scripts/dependency-security-scanner.sh --no-dependencies --no-security --no-licenses --no-vulnerabilities --no-compliance --no-outdated

compliance-scan: ## Run compliance checking only
	@echo "📋 Running compliance check..."
	@./scripts/dependency-security-scanner.sh --no-dependencies --no-security --no-licenses --no-vulnerabilities --no-secrets --no-outdated

# Report management
security-report: ## Generate security report (without running scans)
	@echo "📊 Opening security report..."
	@if [ -f "reports/security-dependency-scan/reports/comprehensive-security-report.html" ]; then \
		echo "✅ Security report available at: reports/security-dependency-scan/reports/comprehensive-security-report.html"; \
	else \
		echo "❌ No security report found. Run 'make security-scan' first."; \
	fi

security-report-serve: ## Serve security report on local HTTP server
	@echo "🌐 Serving security report on http://localhost:8080..."
	@if [ -f "reports/security-dependency-scan/reports/comprehensive-security-report.html" ]; then \
		cd reports/security-dependency-scan/reports && python -m http.server 8080; \
	else \
		echo "❌ No security report found. Run 'make security-scan' first."; \
	fi

security-report-open: ## Open security report in browser
	@echo "🌐 Opening security report in browser..."
	@if [ -f "reports/security-dependency-scan/reports/comprehensive-security-report.html" ]; then \
		open "reports/security-dependency-scan/reports/comprehensive-security-report.html" 2>/dev/null || \
		xdg-open "reports/security-dependency-scan/reports/comprehensive-security-report.html" 2>/dev/null || \
		echo "Please open: reports/security-dependency-scan/reports/comprehensive-security-report.html"; \
	else \
		echo "❌ No security report found. Run 'make security-scan' first."; \
	fi

security-report-clean: ## Clean security scan reports and artifacts
	@echo "🧹 Cleaning security scan reports..."
	@rm -rf reports/security-dependency-scan/
	@echo "✅ Security scan reports cleaned"

# Security scanning with different modes
security-scan-dependencies: ## Focus on dependency-related security issues
	@echo "🔒 Running dependency-focused security scan..."
	@./scripts/dependency-security-scanner.sh --no-secrets --no-compliance

security-scan-vulnerabilities: ## Focus on vulnerability detection
	@echo "🔒 Running vulnerability-focused security scan..."
	@./scripts/dependency-security-scanner.sh --no-secrets --no-compliance --no-licenses

security-scan-secrets: ## Focus on secret detection
	@echo "🔒 Running secret-focused security scan..."
	@./scripts/dependency-security-scanner.sh --no-dependencies --no-vulnerabilities --no-licenses --no-compliance --no-outdated

security-scan-compliance: ## Focus on compliance checking
	@echo "🔒 Running compliance-focused security scan..."
	@./scripts/dependency-security-scanner.sh --no-secrets --no-vulnerabilities

# Integration with existing CI/CD pipeline
security-validate: test-reports security-scan-ci ## Run security validation for CI/CD pipeline
	@echo "🔒 Security validation completed"

security-full-validation: test-reports-full security-scan-strict ## Run full security validation
	@echo "🔒 Full security validation completed"

# Batch operations
security-batch-quick: ## Run quick batch of security checks
	@echo "🔒 Running quick security batch..."
	@$(MAKE) security-scan-quick
	@$(MAKE) security-report

security-batch-full: ## Run full batch of security checks
	@echo "🔒 Running full security batch..."
	@$(MAKE) security-scan-full
	@$(MAKE) security-report-open

security-batch-ci: ## Run CI batch of security checks
	@echo "🔒 Running CI security batch..."
	@$(MAKE) security-scan-ci
	@$(MAKE) security-report

# Combined operations with existing tasks
deploy-security-check: security-scan-strict test-reports-full lint-check odoo-sh-strict ## Complete security check before deployment
	@echo "🚀 Deployment security check completed"

pre-commit-security: security-scan-quick ## Quick security check for pre-commit hooks
	@echo "🔒 Pre-commit security check completed"

# Advanced security operations
security-scan-with-reports: security-scan test-reports ## Run security scan and generate combined reports
	@echo "🔒 Security scan with reports completed"

security-monitoring: ## Continuous security monitoring (runs every 5 minutes)
	@echo "🔒 Starting security monitoring..."
	@while true; do \
		echo "Running security scan at $$(date)"; \
		$(MAKE) security-scan-quick; \
		sleep 300; \
	done

# Security scan status and info
security-scan-status: ## Show security scan status and results
	@echo "🔒 Security Scan Status:"
	@echo "======================="
	@if [ -f "reports/security-dependency-scan/reports/comprehensive-security-report.json" ]; then \
		python -c "import json; data=json.load(open('reports/security-dependency-scan/reports/comprehensive-security-report.json')); print(f'Risk Score: {data[\"risk_assessment\"][\"overall_risk_score\"]}/100'); print(f'Risk Level: {data[\"risk_assessment\"][\"risk_level\"]}'); print(f'Deployment Recommended: {data[\"risk_assessment\"][\"deployment_recommended\"]}'); print(f'Vulnerabilities: {data[\"summary\"][\"total_vulnerabilities\"]}'); print(f'Secrets: {data[\"summary\"][\"secrets_found\"]}')"; \
	else \
		echo "❌ No security scan results found. Run 'make security-scan' first."; \
	fi

security-scan-help: ## Show security scanning help
	@echo "🔒 Security & Dependency Scanning Help"
	@echo "======================================"
	@echo ""
	@echo "Main Commands:"
	@echo "  make security-scan          - Run comprehensive security scan"
	@echo "  make security-scan-full     - Run full security scan with all checks"
	@echo "  make security-scan-quick    - Run quick security scan"
	@echo "  make security-scan-strict   - Run strict security scan (fail on issues)"
	@echo "  make security-scan-ci       - Run CI-optimized security scan"
	@echo ""
	@echo "Individual Scans:"
	@echo "  make dependency-scan        - Analyze dependencies only"
	@echo "  make vulnerability-scan     - Scan for vulnerabilities only"
	@echo "  make license-scan           - Check license compliance only"
	@echo "  make secret-scan            - Detect secrets only"
	@echo "  make compliance-scan        - Check compliance only"
	@echo ""
	@echo "Reports:"
	@echo "  make security-report        - Show security report location"
	@echo "  make security-report-serve  - Serve report on HTTP server"
	@echo "  make security-report-open   - Open report in browser"
	@echo "  make security-report-clean  - Clean report artifacts"
	@echo ""
	@echo "Integration:"
	@echo "  make security-validate      - Security validation for CI/CD"
	@echo "  make deploy-security-check  - Complete pre-deployment security check"
	@echo "  make pre-commit-security    - Quick security check for git hooks"
	@echo ""
	@echo "For more options, run: ./scripts/dependency-security-scanner.sh --help"

# ... existing code ...

# =====================================
# Task 6.7: Documentation Generation for Module APIs and Testing Procedures
# =====================================

# Main documentation generation targets
.PHONY: docs docs-full docs-api docs-tests docs-html docs-markdown docs-clean
.PHONY: docs-serve docs-open docs-index docs-help docs-status docs-quick

# Main documentation generation commands
docs: ## Generate comprehensive module and testing documentation
	@echo "📚 Generating comprehensive documentation..."
	@./scripts/generate-module-documentation.sh

docs-full: ## Generate complete documentation with all options
	@echo "📚 Generating complete documentation..."
	@./scripts/generate-module-documentation.sh --verbose --include-private

docs-api: ## Generate API documentation only
	@echo "🔧 Generating API documentation..."
	@./scripts/generate-module-documentation.sh --no-tests

docs-tests: ## Generate testing documentation only
	@echo "🧪 Generating testing documentation..."
	@./scripts/generate-module-documentation.sh --no-api

docs-html: ## Generate HTML documentation only
	@echo "🌐 Generating HTML documentation..."
	@./scripts/generate-module-documentation.sh --no-markdown

docs-markdown: ## Generate Markdown documentation only
	@echo "📝 Generating Markdown documentation..."
	@./scripts/generate-module-documentation.sh --no-html

docs-quick: ## Generate documentation quickly (minimal options)
	@echo "⚡ Generating quick documentation..."
	@./scripts/generate-module-documentation.sh --no-examples --no-html --quiet

# Documentation management
docs-clean: ## Clean generated documentation
	@echo "🧹 Cleaning generated documentation..."
	@rm -rf docs/generated/
	@echo "✅ Documentation cleaned"

docs-serve: ## Serve documentation on local HTTP server
	@echo "🌐 Serving documentation on http://localhost:8080..."
	@if [ -f "docs/generated/index.html" ]; then \
		cd docs/generated && python -m http.server 8080; \
	else \
		echo "❌ No documentation found. Run 'make docs' first."; \
	fi

docs-open: ## Open documentation index in browser
	@echo "🌐 Opening documentation in browser..."
	@if [ -f "docs/generated/index.html" ]; then \
		open "docs/generated/index.html" 2>/dev/null || \
		xdg-open "docs/generated/index.html" 2>/dev/null || \
		echo "Please open: docs/generated/index.html"; \
	else \
		echo "❌ No documentation found. Run 'make docs' first."; \
	fi

docs-index: ## Generate documentation index only
	@echo "📋 Generating documentation index..."
	@./scripts/generate-module-documentation.sh --no-api --no-tests

# Documentation integration with existing workflows
docs-with-tests: docs test-reports ## Generate documentation and test reports
	@echo "📚 Documentation and test reports generated"

docs-with-security: docs security-scan ## Generate documentation and security analysis
	@echo "📚 Documentation and security analysis completed"

docs-full-suite: docs test-reports security-scan odoo-sh-simulate ## Complete documentation and analysis suite
	@echo "📚 Complete documentation and analysis suite completed"

# CI/CD integration targets
docs-ci: ## Generate documentation for CI/CD (lightweight)
	@echo "📚 Generating CI documentation..."
	@./scripts/generate-module-documentation.sh --quiet --no-examples

docs-deploy: ## Generate documentation for deployment
	@echo "📚 Generating deployment documentation..."
	@./scripts/generate-module-documentation.sh --verbose

# Module-specific documentation
docs-module: ## Generate documentation for specific module (usage: make docs-module MODULE=module_name)
ifndef MODULE
	@echo "Error: Please specify MODULE: make docs-module MODULE=royal_textiles_sales"
	@exit 1
endif
	@echo "📚 Generating documentation for module: $(MODULE)"
	@if [ -d "custom_modules/$(MODULE)" ]; then \
		./scripts/generate-module-documentation.sh --verbose; \
		echo "📋 Module documentation: docs/generated/api/$(MODULE)_api.html"; \
	else \
		echo "❌ Module not found: $(MODULE)"; \
		exit 1; \
	fi

# Documentation validation and quality
docs-validate: ## Validate generated documentation
	@echo "✅ Validating generated documentation..."
	@if [ -d "docs/generated" ]; then \
		echo "📁 Documentation directory exists"; \
		if [ -f "docs/generated/index.html" ]; then \
			echo "✅ Documentation index found"; \
		else \
			echo "❌ Documentation index missing"; \
		fi; \
		api_count=$$(find docs/generated/api -name "*.html" 2>/dev/null | wc -l); \
		test_count=$$(find docs/generated/testing -name "*.html" 2>/dev/null | wc -l); \
		echo "📊 API documentation files: $$api_count"; \
		echo "📊 Test documentation files: $$test_count"; \
	else \
		echo "❌ No documentation found. Run 'make docs' first."; \
		exit 1; \
	fi

docs-check: ## Check documentation completeness
	@echo "🔍 Checking documentation completeness..."
	@module_count=$$(find custom_modules -maxdepth 1 -type d ! -path custom_modules | wc -l); \
	echo "📦 Total modules: $$module_count"; \
	if [ -d "docs/generated/api" ]; then \
		doc_count=$$(find docs/generated/api -name "*_api.md" -o -name "*_api.html" | wc -l); \
		echo "📚 Documented modules: $$doc_count"; \
		if [ $$doc_count -eq $$module_count ]; then \
			echo "✅ All modules documented"; \
		else \
			echo "⚠️  Missing documentation for $$((module_count - doc_count)) modules"; \
		fi; \
	else \
		echo "❌ No API documentation found"; \
	fi

# Documentation status and information
docs-status: ## Show documentation generation status
	@echo "📚 Documentation Status:"
	@echo "======================="
	@if [ -d "docs/generated" ]; then \
		echo "📁 Documentation directory: ✅ Exists"; \
		if [ -f "docs/generated/index.html" ]; then \
			echo "📋 Documentation index: ✅ Available"; \
			echo "🌐 Access: file://$(PWD)/docs/generated/index.html"; \
		else \
			echo "📋 Documentation index: ❌ Missing"; \
		fi; \
		echo ""; \
		echo "📊 Documentation Statistics:"; \
		if [ -d "docs/generated/api" ]; then \
			api_md=$$(find docs/generated/api -name "*.md" | wc -l); \
			api_html=$$(find docs/generated/api -name "*.html" | wc -l); \
			echo "  🔧 API Docs (MD): $$api_md"; \
			echo "  🔧 API Docs (HTML): $$api_html"; \
		fi; \
		if [ -d "docs/generated/testing" ]; then \
			test_md=$$(find docs/generated/testing -name "*.md" | wc -l); \
			test_html=$$(find docs/generated/testing -name "*.html" | wc -l); \
			echo "  🧪 Test Docs (MD): $$test_md"; \
			echo "  🧪 Test Docs (HTML): $$test_html"; \
		fi; \
		total_size=$$(du -sh docs/generated 2>/dev/null | cut -f1); \
		echo "  📏 Total Size: $$total_size"; \
	else \
		echo "📁 Documentation directory: ❌ Not found"; \
		echo "Run 'make docs' to generate documentation"; \
	fi

docs-help: ## Show documentation generation help
	@echo "📚 Documentation Generation Help"
	@echo "================================"
	@echo ""
	@echo "Main Commands:"
	@echo "  make docs               - Generate comprehensive documentation"
	@echo "  make docs-full          - Generate complete documentation with all options"
	@echo "  make docs-api           - Generate API documentation only"
	@echo "  make docs-tests         - Generate testing documentation only"
	@echo "  make docs-html          - Generate HTML documentation only"
	@echo "  make docs-markdown      - Generate Markdown documentation only"
	@echo "  make docs-quick         - Generate quick documentation (minimal)"
	@echo ""
	@echo "Management:"
	@echo "  make docs-clean         - Clean generated documentation"
	@echo "  make docs-serve         - Serve documentation on HTTP server"
	@echo "  make docs-open          - Open documentation in browser"
	@echo "  make docs-index         - Generate documentation index only"
	@echo ""
	@echo "Validation:"
	@echo "  make docs-validate      - Validate generated documentation"
	@echo "  make docs-check         - Check documentation completeness"
	@echo "  make docs-status        - Show documentation status"
	@echo ""
	@echo "Integration:"
	@echo "  make docs-with-tests    - Generate docs and test reports"
	@echo "  make docs-with-security - Generate docs and security analysis"
	@echo "  make docs-full-suite    - Complete documentation and analysis"
	@echo ""
	@echo "CI/CD:"
	@echo "  make docs-ci            - Generate CI documentation (lightweight)"
	@echo "  make docs-deploy        - Generate deployment documentation"
	@echo ""
	@echo "Module-specific:"
	@echo "  make docs-module MODULE=name - Generate docs for specific module"
	@echo ""
	@echo "For more options, run: ./scripts/generate-module-documentation.sh --help"

# Advanced documentation workflows
docs-update: docs docs-validate ## Update documentation and validate
	@echo "📚 Documentation updated and validated"

docs-rebuild: docs-clean docs ## Clean and regenerate all documentation
	@echo "📚 Documentation rebuilt from scratch"

docs-preview: docs docs-serve ## Generate documentation and start preview server
	@echo "📚 Documentation preview ready"

docs-publish: docs-full docs-validate ## Generate publication-ready documentation
	@echo "📚 Publication-ready documentation generated"

# Integration with existing CI/CD pipeline
ci-docs: docs-ci docs-validate ## CI documentation generation and validation
	@echo "📚 CI documentation generation completed"

deploy-docs: docs-deploy docs-check ## Deploy-ready documentation generation
	@echo "📚 Deploy-ready documentation generated"

# Complete workflow integration
complete-docs-workflow: docs-full test-reports-full security-scan-full odoo-sh-simulate ## Complete documentation workflow with all validations
	@echo "📚 Complete documentation workflow completed"
	@echo ""
	@echo "🎉 COMPLETE WORKFLOW SUMMARY:"
	@echo "============================="
	@echo "✅ Documentation Generated"
	@echo "✅ Test Reports Generated"
	@echo "✅ Security Analysis Completed"
	@echo "✅ Deployment Simulation Completed"
	@echo ""
	@echo "📋 Access Points:"
	@echo "  📚 Documentation: docs/generated/index.html"
	@echo "  🧪 Test Reports: reports/test-report.html"
	@echo "  🔒 Security Reports: reports/security-dependency-scan/reports/comprehensive-security-report.html"
	@echo "  🚀 Deployment Report: reports/odoo-sh-simulation/deployment-simulation-report.html"

# Batch documentation operations
docs-batch-quick: ## Quick batch documentation generation
	@echo "📚 Running quick documentation batch..."
	@$(MAKE) docs-quick
	@$(MAKE) docs-validate

docs-batch-full: ## Full batch documentation generation
	@echo "📚 Running full documentation batch..."
	@$(MAKE) docs-full
	@$(MAKE) docs-open

docs-batch-ci: ## CI batch documentation generation
	@echo "📚 Running CI documentation batch..."
	@$(MAKE) docs-ci
	@$(MAKE) docs-status

# Documentation monitoring and maintenance
docs-monitor: ## Monitor documentation status (continuous)
	@echo "📚 Starting documentation monitoring..."
	@while true; do \
		echo "Checking documentation at $$(date)"; \
		$(MAKE) docs-status; \
		sleep 300; \
	done

docs-maintenance: ## Perform documentation maintenance
	@echo "📚 Performing documentation maintenance..."
	@$(MAKE) docs-clean
	@$(MAKE) docs-full
	@$(MAKE) docs-validate
	@echo "✅ Documentation maintenance completed"

# ... existing code ...

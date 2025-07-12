#!/bin/bash

# =============================================================================
# Odoo Development Environment Setup Script
# Royal Textiles Project - Local Testing Infrastructure
# =============================================================================

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check Python version
check_python_version() {
    log_info "Checking Python version..."

    if command_exists python3; then
        python_version=$(python3 --version 2>&1 | cut -d" " -f2)
        python_major=$(echo $python_version | cut -d"." -f1)
        python_minor=$(echo $python_version | cut -d"." -f2)

        if [ "$python_major" -eq 3 ] && [ "$python_minor" -ge 11 ]; then
            log_success "Python $python_version found (compatible with Odoo 18.0)"
            return 0
        else
            log_warning "Python $python_version found, but Odoo 18.0 requires Python 3.11+"
            return 1
        fi
    else
        log_error "Python 3 not found. Please install Python 3.11+ first."
        return 1
    fi
}

# Function to check required system dependencies
check_dependencies() {
    log_info "Checking system dependencies..."

    local missing_deps=()

    # Check for git
    if ! command_exists git; then
        missing_deps+=("git")
    fi

    # Check for pip
    if ! command_exists pip3; then
        missing_deps+=("pip3")
    fi

    # Check for make
    if ! command_exists make; then
        missing_deps+=("make")
    fi

    if [ ${#missing_deps[@]} -ne 0 ]; then
        log_error "Missing required dependencies: ${missing_deps[*]}"
        log_error "Please install them first:"
        log_error "  macOS: brew install git python make"
        log_error "  Ubuntu: sudo apt-get install git python3-pip make"
        log_error "  CentOS: sudo yum install git python3-pip make"
        return 1
    fi

    log_success "All required system dependencies found"
    return 0
}

# Function to create virtual environment
setup_virtual_environment() {
    log_info "Setting up Python virtual environment..."

    if [ ! -d "venv" ]; then
        log_info "Creating virtual environment..."
        python3 -m venv venv
        log_success "Virtual environment created"
    else
        log_info "Virtual environment already exists"
    fi

    log_info "Activating virtual environment..."
    source venv/bin/activate

    # Upgrade pip to latest version
    log_info "Upgrading pip..."
    pip install --upgrade pip

    log_success "Virtual environment setup complete"
}

# Function to install Python dependencies
install_python_dependencies() {
    log_info "Installing Python development dependencies..."

    if [ ! -f "requirements.txt" ]; then
        log_error "requirements.txt not found. Please ensure you're in the rtp-denver directory."
        return 1
    fi

    # Install requirements
    pip install -r requirements.txt

    log_success "Python dependencies installed successfully"
}

# Function to install and configure pre-commit hooks
setup_pre_commit_hooks() {
    log_info "Setting up pre-commit hooks..."

    # Check if .pre-commit-config.yaml exists
    if [ ! -f ".pre-commit-config.yaml" ]; then
        log_error ".pre-commit-config.yaml not found. Pre-commit configuration is missing."
        return 1
    fi

    # Install pre-commit hooks
    log_info "Installing pre-commit hooks..."
    pre-commit install

    # Install pre-push hooks (for additional validation)
    log_info "Installing pre-push hooks..."
    pre-commit install --hook-type pre-push

    # Run pre-commit on all files to initialize and validate setup
    log_info "Running initial pre-commit validation on all files..."
    if pre-commit run --all-files; then
        log_success "Pre-commit hooks installed and initial validation passed"
    else
        log_warning "Pre-commit found some issues. These have been auto-fixed where possible."
        log_info "You may need to review and commit the changes."
    fi
}

# Function to validate Odoo module structure
validate_module_structure() {
    log_info "Validating Royal Textiles module structure..."

    if [ -f "scripts/validate-module.py" ]; then
        if python scripts/validate-module.py royal_textiles_sales; then
            log_success "Module structure validation passed"
        else
            log_warning "Module structure validation found issues. Please review and fix them."
        fi
    else
        log_warning "Module validation script not found, skipping structure validation"
    fi
}

# Function to test make targets
test_make_targets() {
    log_info "Testing Make targets..."

    if [ -f "Makefile" ]; then
        # Test that key make targets work
        log_info "Testing 'make help'..."
        make help >/dev/null

        log_info "Testing 'make lint-check'..."
        if make lint-check; then
            log_success "Linting setup working correctly"
        else
            log_warning "Linting found issues - this is normal for initial setup"
        fi

        log_success "Make targets are functional"
    else
        log_warning "Makefile not found, skipping make target tests"
    fi
}

# Function to create development configuration
create_dev_config() {
    log_info "Creating development configuration files..."

    # Create a simple .env file for development if it doesn't exist
    if [ ! -f ".env" ]; then
        cat > .env << EOF
# Development Environment Configuration
# Royal Textiles Odoo Project

# Python Environment
PYTHONPATH=.

# Development Settings
DEBUG=true
LOG_LEVEL=debug

# Database (for local testing)
DB_HOST=localhost
DB_PORT=5432
DB_NAME=royal_textiles_dev
DB_USER=odoo
DB_PASSWORD=odoo

# Odoo Configuration
ODOO_VERSION=18.0
ADDONS_PATH=./

EOF
        log_success "Created .env file with development defaults"
    else
        log_info ".env file already exists, skipping creation"
    fi
}

# Function to display setup summary
display_setup_summary() {
    echo
    echo "======================================================================"
    log_success "🎉 Odoo Development Environment Setup Complete!"
    echo "======================================================================"
    echo
    log_info "What was installed/configured:"
    echo "  ✅ Python virtual environment (venv/)"
    echo "  ✅ Development dependencies (pylint-odoo, flake8, black, mypy, etc.)"
    echo "  ✅ Pre-commit hooks (automatic code quality checks)"
    echo "  ✅ Module validation tools"
    echo "  ✅ Make targets for common tasks"
    echo "  ✅ Development configuration (.env)"
    echo
    log_info "Quick start commands:"
    echo "  📁 Activate environment:  source venv/bin/activate"
    echo "  🔍 Run full validation:   make deploy-check"
    echo "  🧹 Format code:          make format"
    echo "  🔧 Run linting:          make lint"
    echo "  ✅ Validate module:      make validate"
    echo "  📋 See all commands:     make help"
    echo
    log_info "Files created/modified:"
    echo "  📄 .env (development configuration)"
    echo "  📁 venv/ (Python virtual environment)"
    echo "  🪝 .git/hooks/ (pre-commit hooks installed)"
    echo
    log_warning "Next steps:"
    echo "  1. Activate the virtual environment: source venv/bin/activate"
    echo "  2. Run full validation: make deploy-check"
    echo "  3. Start developing! Pre-commit hooks will auto-check your code."
    echo
    echo "======================================================================"
}

# Main setup function
main() {
    echo "======================================================================"
    log_info "🚀 Setting up Odoo Development Environment"
    log_info "Royal Textiles Project - Local Testing Infrastructure"
    echo "======================================================================"
    echo

    # Change to script directory to ensure we're in the right place
    cd "$(dirname "$0")/.."

    log_info "Current directory: $(pwd)"
    echo

    # Step 1: Check system dependencies
    if ! check_dependencies; then
        exit 1
    fi
    echo

    # Step 2: Check Python version
    if ! check_python_version; then
        log_warning "Python version check failed, but continuing..."
    fi
    echo

    # Step 3: Set up virtual environment
    setup_virtual_environment
    echo

    # Step 4: Install Python dependencies
    install_python_dependencies
    echo

    # Step 5: Set up pre-commit hooks (main task 1.6)
    setup_pre_commit_hooks
    echo

    # Step 6: Validate module structure
    validate_module_structure
    echo

    # Step 7: Test make targets
    test_make_targets
    echo

    # Step 8: Create development configuration
    create_dev_config
    echo

    # Step 9: Display summary
    display_setup_summary
}

# Run main function
main "$@"

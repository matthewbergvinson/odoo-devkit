#!/bin/bash

# RTP Denver - Local Odoo 18.0 Installation Script
# Matches odoo.sh environment for development and testing
# Supports macOS and Linux environments
#
# Usage: ./scripts/install-local-odoo.sh [OPTIONS]
# Options:
#   --force-reinstall  Force reinstallation even if Odoo exists
#   --skip-db         Skip PostgreSQL setup
#   --python-version  Specify Python version (default: 3.11)
#   --help            Show this help message

set -euo pipefail

# Configuration matching odoo.sh environment
ODOO_VERSION="18.0"
PYTHON_VERSION="${PYTHON_VERSION:-3.11}"
POSTGRES_VERSION="14"
ODOO_USER="$(whoami)"
ODOO_HOME="$(pwd)/local-odoo"
ODOO_PATH="${ODOO_HOME}/odoo"
VENV_PATH="${ODOO_HOME}/venv"
CONFIG_PATH="${ODOO_HOME}/odoo.conf"
ADDONS_PATH="${ODOO_HOME}/addons"
LOGS_PATH="${ODOO_HOME}/logs"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Flags
FORCE_REINSTALL=false
SKIP_DB=false
SHOW_HELP=false

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --force-reinstall)
                FORCE_REINSTALL=true
                shift
                ;;
            --skip-db)
                SKIP_DB=true
                shift
                ;;
            --python-version)
                PYTHON_VERSION="$2"
                shift 2
                ;;
            --help)
                SHOW_HELP=true
                shift
                ;;
            *)
                echo -e "${RED}Unknown option: $1${NC}"
                exit 1
                ;;
        esac
    done
}

# Show help message
show_help() {
    echo "RTP Denver - Local Odoo 18.0 Installation Script"
    echo "================================================="
    echo ""
    echo "This script installs Odoo 18.0 locally to match the odoo.sh environment"
    echo "for development and testing purposes."
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --force-reinstall    Force reinstallation even if Odoo exists"
    echo "  --skip-db           Skip PostgreSQL setup"
    echo "  --python-version    Specify Python version (default: 3.11)"
    echo "  --help              Show this help message"
    echo ""
    echo "Requirements:"
    echo "  - macOS with Homebrew OR Ubuntu/Debian Linux"
    echo "  - Python ${PYTHON_VERSION}+"
    echo "  - PostgreSQL ${POSTGRES_VERSION}+"
    echo "  - Git"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Standard installation"
    echo "  $0 --force-reinstall                 # Force reinstall"
    echo "  $0 --skip-db                         # Skip database setup"
    echo "  $0 --python-version 3.12             # Use Python 3.12"
    echo ""
}

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

# Detect operating system
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        log_info "Detected macOS"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
        log_info "Detected Linux"
    else
        log_error "Unsupported operating system: $OSTYPE"
        exit 1
    fi
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install system dependencies
install_system_dependencies() {
    log_info "Installing system dependencies..."

    if [[ "$OS" == "macos" ]]; then
        # macOS with Homebrew
        if ! command_exists brew; then
            log_error "Homebrew is required but not installed."
            log_info "Install Homebrew from: https://brew.sh/"
            exit 1
        fi

        # Install Python if not present
        if ! command_exists "python${PYTHON_VERSION}"; then
            log_info "Installing Python ${PYTHON_VERSION}..."
            brew install "python@${PYTHON_VERSION}"
        fi

        # Install PostgreSQL if not present and not skipping
        if [[ "$SKIP_DB" == false ]] && ! command_exists psql; then
            log_info "Installing PostgreSQL ${POSTGRES_VERSION}..."
            brew install "postgresql@${POSTGRES_VERSION}"
            brew services start "postgresql@${POSTGRES_VERSION}"
        fi

        # Install other dependencies
        dependencies=(
            "git"
            "node"
            "wkhtmltopdf"
            "libxml2"
            "libxslt"
            "libjpeg"
            "freetype"
            "zlib"
        )

        for dep in "${dependencies[@]}"; do
            if ! brew list "$dep" >/dev/null 2>&1; then
                log_info "Installing $dep..."
                brew install "$dep" || log_warning "Failed to install $dep"
            fi
        done

    elif [[ "$OS" == "linux" ]]; then
        # Linux (Ubuntu/Debian)
        log_info "Updating package list..."
        sudo apt-get update

        # Install system packages
        packages=(
            "python${PYTHON_VERSION}"
            "python${PYTHON_VERSION}-dev"
            "python${PYTHON_VERSION}-venv"
            "python3-pip"
            "git"
            "nodejs"
            "npm"
            "wkhtmltopdf"
            "libxml2-dev"
            "libxslt1-dev"
            "libjpeg-dev"
            "libfreetype6-dev"
            "zlib1g-dev"
            "libsasl2-dev"
            "libldap2-dev"
            "libssl-dev"
            "build-essential"
        )

        if [[ "$SKIP_DB" == false ]]; then
            packages+=("postgresql-${POSTGRES_VERSION}" "postgresql-server-dev-${POSTGRES_VERSION}")
        fi

        log_info "Installing system packages..."
        sudo apt-get install -y "${packages[@]}"

        # Start PostgreSQL
        if [[ "$SKIP_DB" == false ]]; then
            sudo systemctl start postgresql
            sudo systemctl enable postgresql
        fi
    fi

    log_success "System dependencies installed"
}

# Setup PostgreSQL database
setup_postgresql() {
    if [[ "$SKIP_DB" == true ]]; then
        log_info "Skipping PostgreSQL setup as requested"
        return
    fi

    log_info "Setting up PostgreSQL for Odoo development using dedicated script..."

    # Use the dedicated PostgreSQL setup script from Task 3.2
    if [[ -f "scripts/setup-postgresql.sh" ]]; then
        log_info "Running comprehensive PostgreSQL setup..."
        export ODOO_DB_USER="$ODOO_USER"
        export POSTGRES_VERSION="$POSTGRES_VERSION"

        # Run the dedicated PostgreSQL setup script
        ./scripts/setup-postgresql.sh

        if [[ $? -eq 0 ]]; then
            log_success "PostgreSQL setup completed using dedicated script"
        else
            log_error "PostgreSQL setup script failed"
            exit 1
        fi
    else
        # Fallback to basic setup if dedicated script not found
        log_warning "Dedicated PostgreSQL setup script not found, using basic setup"

        # Create Odoo database user (basic fallback)
        if [[ "$OS" == "macos" ]]; then
            # On macOS, current user is usually a superuser
            createuser -s "$ODOO_USER" 2>/dev/null || log_info "User $ODOO_USER already exists"
        elif [[ "$OS" == "linux" ]]; then
            # On Linux, switch to postgres user
            sudo -u postgres createuser -s "$ODOO_USER" 2>/dev/null || log_info "User $ODOO_USER already exists"
        fi

        log_success "Basic PostgreSQL setup completed"
    fi
}

# Create directory structure
create_directory_structure() {
    log_info "Creating directory structure..."

    directories=(
        "$ODOO_HOME"
        "$ADDONS_PATH"
        "$LOGS_PATH"
        "${ODOO_HOME}/backups"
        "${ODOO_HOME}/filestore"
    )

    for dir in "${directories[@]}"; do
        mkdir -p "$dir"
    done

    log_success "Directory structure created"
}

# Install Odoo 18.0
install_odoo() {
    log_info "Installing Odoo ${ODOO_VERSION}..."

    # Check if Odoo already exists
    if [[ -d "$ODOO_PATH" ]] && [[ "$FORCE_REINSTALL" == false ]]; then
        log_warning "Odoo installation already exists at $ODOO_PATH"
        log_info "Use --force-reinstall to reinstall"
        return
    fi

    # Remove existing installation if force reinstall
    if [[ -d "$ODOO_PATH" ]] && [[ "$FORCE_REINSTALL" == true ]]; then
        log_info "Removing existing Odoo installation..."
        rm -rf "$ODOO_PATH"
    fi

    # Clone Odoo repository
    log_info "Cloning Odoo ${ODOO_VERSION} repository..."
    git clone --depth 1 --branch "${ODOO_VERSION}" \
        https://github.com/odoo/odoo.git "$ODOO_PATH"

    log_success "Odoo ${ODOO_VERSION} downloaded"
}

# Create Python virtual environment
create_virtual_environment() {
    log_info "Creating Python virtual environment..."

    # Remove existing venv if force reinstall
    if [[ -d "$VENV_PATH" ]] && [[ "$FORCE_REINSTALL" == true ]]; then
        log_info "Removing existing virtual environment..."
        rm -rf "$VENV_PATH"
    fi

    # Create virtual environment
    if [[ ! -d "$VENV_PATH" ]]; then
        "python${PYTHON_VERSION}" -m venv "$VENV_PATH"
        log_success "Virtual environment created"
    else
        log_info "Virtual environment already exists"
    fi

    # Activate virtual environment
    source "${VENV_PATH}/bin/activate"

    # Upgrade pip
    pip install --upgrade pip

    log_success "Virtual environment ready"
}

# Install Python dependencies
install_python_dependencies() {
    log_info "Installing Python dependencies..."

    # Activate virtual environment
    source "${VENV_PATH}/bin/activate"

    # Install wheel first
    pip install wheel

    # Install Odoo requirements
    pip install -r "${ODOO_PATH}/requirements.txt"

    # Install additional development dependencies
    pip install \
        debugpy \
        pytest \
        coverage \
        pylint-odoo \
        black \
        isort \
        flake8 \
        mypy

    log_success "Python dependencies installed"
}

# Create Odoo configuration file
create_odoo_config() {
    log_info "Creating Odoo configuration file..."

    cat > "$CONFIG_PATH" << EOF
[options]
# Server configuration
addons_path = ${ODOO_PATH}/addons,${ADDONS_PATH},$(pwd)/custom_modules
data_dir = ${ODOO_HOME}/filestore
logfile = ${LOGS_PATH}/odoo.log
log_level = info

# Database configuration
db_host = localhost
db_port = 5432
db_user = ${ODOO_USER}
db_password = False

# Development settings
dev_mode = reload,qweb,werkzeug,xml
workers = 0
max_cron_threads = 0

# Security (development only)
admin_passwd = admin123
list_db = True

# Interface
xmlrpc_port = 8069
longpolling_port = 8072

# Performance
limit_memory_hard = 2684354560
limit_memory_soft = 2147483648
limit_request = 8192
limit_time_cpu = 600
limit_time_real = 1200

# Testing
test_enable = True
test_file = False
test_tags = None

# Email (disabled for development)
email_from = False
smtp_server = False

# Storage
unaccent = True
EOF

    log_success "Odoo configuration created at $CONFIG_PATH"
}

# Create startup scripts
create_startup_scripts() {
    log_info "Creating startup scripts..."

    # Create main startup script
    cat > "${ODOO_HOME}/start-odoo.sh" << EOF
#!/bin/bash
# RTP Denver - Start Local Odoo Development Server

# Activate virtual environment
source "${VENV_PATH}/bin/activate"

# Start Odoo
echo "Starting Odoo ${ODOO_VERSION} development server..."
echo "Configuration: ${CONFIG_PATH}"
echo "Access URL: http://localhost:8069"
echo "Admin password: admin123"
echo ""
echo "Press Ctrl+C to stop the server"
echo ""

# Run Odoo with development configuration
python "${ODOO_PATH}/odoo-bin" \\
    --config="${CONFIG_PATH}" \\
    --dev=reload,qweb,werkzeug,xml \\
    "\$@"
EOF

    # Create database management script
    cat > "${ODOO_HOME}/manage-db.sh" << EOF
#!/bin/bash
# RTP Denver - Database Management Script

source "${VENV_PATH}/bin/activate"

case "\$1" in
    create)
        echo "Creating database: \$2"
        python "${ODOO_PATH}/odoo-bin" \\
            --config="${CONFIG_PATH}" \\
            --database="\$2" \\
            --init=base \\
            --stop-after-init
        ;;
    drop)
        echo "Dropping database: \$2"
        dropdb "\$2" 2>/dev/null || echo "Database \$2 does not exist"
        ;;
    list)
        echo "Available databases:"
        psql -l | grep "^ \w" | awk '{print \$1}'
        ;;
    reset)
        echo "Resetting database: \$2"
        dropdb "\$2" 2>/dev/null || true
        python "${ODOO_PATH}/odoo-bin" \\
            --config="${CONFIG_PATH}" \\
            --database="\$2" \\
            --init=base \\
            --stop-after-init
        ;;
    *)
        echo "Usage: \$0 {create|drop|list|reset} [database_name]"
        echo ""
        echo "Examples:"
        echo "  \$0 create test_db    # Create test database"
        echo "  \$0 drop test_db      # Drop test database"
        echo "  \$0 list              # List all databases"
        echo "  \$0 reset test_db     # Reset test database"
        exit 1
        ;;
esac
EOF

    # Make scripts executable
    chmod +x "${ODOO_HOME}/start-odoo.sh"
    chmod +x "${ODOO_HOME}/manage-db.sh"

    log_success "Startup scripts created"
}

# Update Makefile integration
update_makefile_integration() {
    log_info "Updating Makefile integration..."

    # Check if Makefile targets already exist
    if ! grep -q "start-odoo" Makefile; then
        cat >> Makefile << EOF

# Local Odoo Development Server (Task 3.1)
start-odoo:
	@echo "Starting local Odoo development server..."
	./local-odoo/start-odoo.sh

stop-odoo:
	@echo "Stopping Odoo server..."
	@pkill -f "odoo-bin" || echo "Odoo server not running"

restart-odoo: stop-odoo start-odoo

# Database management
create-db:
ifndef DB
	@echo "Error: Please specify DB name: make create-db DB=test_db"
	@exit 1
endif
	@echo "Creating database: \$(DB)"
	./local-odoo/manage-db.sh create \$(DB)

drop-db:
ifndef DB
	@echo "Error: Please specify DB name: make drop-db DB=test_db"
	@exit 1
endif
	@echo "Dropping database: \$(DB)"
	./local-odoo/manage-db.sh drop \$(DB)

list-dbs:
	@echo "Available databases:"
	./local-odoo/manage-db.sh list

reset-db:
ifndef DB
	@echo "Error: Please specify DB name: make reset-db DB=test_db"
	@exit 1
endif
	@echo "Resetting database: \$(DB)"
	./local-odoo/manage-db.sh reset \$(DB)
EOF
        log_success "Makefile targets added"
    else
        log_info "Makefile targets already exist"
    fi
}

# Display installation summary
display_summary() {
    log_success "Local Odoo ${ODOO_VERSION} installation completed!"
    echo ""
    echo -e "${GREEN}Installation Summary:${NC}"
    echo "===================="
    echo "Odoo Version:      ${ODOO_VERSION}"
    echo "Python Version:    $(python${PYTHON_VERSION} --version)"
    echo "Installation Path: ${ODOO_HOME}"
    echo "Configuration:     ${CONFIG_PATH}"
    echo "Virtual Environment: ${VENV_PATH}"
    echo ""
    echo -e "${GREEN}Quick Start:${NC}"
    echo "============"
    echo "1. Start Odoo server:"
    echo "   make start-odoo"
    echo "   # OR directly: ./local-odoo/start-odoo.sh"
    echo ""
    echo "2. Access Odoo:"
    echo "   URL: http://localhost:8069"
    echo "   Admin password: admin123"
    echo ""
    echo "3. Create test database:"
    echo "   make create-db DB=test_db"
    echo ""
    echo "4. Install your custom modules:"
    echo "   # Modules in custom_modules/ are automatically available"
    echo ""
    echo -e "${GREEN}Database Management:${NC}"
    echo "==================="
    echo "make create-db DB=name   # Create new database"
    echo "make drop-db DB=name     # Drop database"
    echo "make reset-db DB=name    # Reset database"
    echo "make list-dbs            # List all databases"
    echo ""
    echo -e "${GREEN}Development Workflow:${NC}"
    echo "====================="
    echo "1. Validate modules:     make validate"
    echo "2. Run tests:           make test"
    echo "3. Start Odoo:          make start-odoo"
    echo "4. Deploy to odoo.sh:   make deploy-check"
    echo ""
    echo -e "${YELLOW}Notes:${NC}"
    echo "======"
    echo "- This installation matches odoo.sh environment (Odoo ${ODOO_VERSION})"
    echo "- Custom modules in custom_modules/ are automatically available"
    echo "- Development mode is enabled for auto-reload"
    echo "- All validation tools work with this local installation"
    echo ""
}

# Main installation function
main() {
    parse_arguments "$@"

    if [[ "$SHOW_HELP" == true ]]; then
        show_help
        exit 0
    fi

    echo -e "${BLUE}"
    echo "=========================================="
    echo "RTP Denver - Local Odoo 18.0 Installation"
    echo "=========================================="
    echo -e "${NC}"
    echo "This script will install Odoo ${ODOO_VERSION} locally to match"
    echo "the odoo.sh environment for development and testing."
    echo ""

    detect_os

    log_info "Starting installation process..."

    # Installation steps
    install_system_dependencies
    setup_postgresql
    create_directory_structure
    install_odoo
    create_virtual_environment
    install_python_dependencies
    create_odoo_config
    create_startup_scripts
    update_makefile_integration

    display_summary
}

# Run main function with all arguments
main "$@"

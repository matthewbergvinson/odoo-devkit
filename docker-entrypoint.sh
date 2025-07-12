#!/bin/bash

# RTP Denver - Docker Entrypoint for Odoo 18.0
# Task 3.7: Create Docker alternative setup for environment consistency
#
# This script provides a flexible entrypoint for the Odoo Docker container
# that integrates with our existing infrastructure from Tasks 3.1-3.6

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
ODOO_HOME="/opt/odoo"
ODOO_PATH="/opt/odoo/odoo"
CUSTOM_MODULES_PATH="/opt/odoo/custom_modules"
CONFIG_PATH="/etc/odoo"
LOGS_PATH="/var/log/odoo"
DATA_PATH="/var/lib/odoo"

# Database configuration
DB_HOST="${DB_HOST:-postgres}"
DB_PORT="${DB_PORT:-5432}"
DB_USER="${DB_USER:-odoo}"
DB_PASSWORD="${DB_PASSWORD:-}"
DB_NAME="${DB_NAME:-}"

# Odoo configuration
ODOO_CONFIG="${ODOO_CONFIG:-/etc/odoo/odoo.conf}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-admin123}"

# Logging functions
log_info() {
    echo -e "${BLUE}[DOCKER-INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') $1"
}

log_success() {
    echo -e "${GREEN}[DOCKER-SUCCESS]${NC} $(date '+%Y-%m-%d %H:%M:%S') $1"
}

log_warning() {
    echo -e "${YELLOW}[DOCKER-WARNING]${NC} $(date '+%Y-%m-%d %H:%M:%S') $1"
}

log_error() {
    echo -e "${RED}[DOCKER-ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') $1"
}

# Wait for PostgreSQL to be ready
wait_for_postgres() {
    log_info "Waiting for PostgreSQL at $DB_HOST:$DB_PORT..."

    local max_attempts=30
    local attempt=1

    while ! pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" >/dev/null 2>&1; do
        if [[ $attempt -ge $max_attempts ]]; then
            log_error "PostgreSQL is not available after $max_attempts attempts"
            exit 1
        fi

        log_info "Waiting for PostgreSQL... (attempt $attempt/$max_attempts)"
        sleep 2
        ((attempt++))
    done

    log_success "PostgreSQL is ready at $DB_HOST:$DB_PORT"
}

# Generate Odoo configuration file
generate_odoo_config() {
    local config_file="$1"
    local environment="${2:-development}"

    log_info "Generating Odoo configuration for environment: $environment"

    # Calculate appropriate addons path
    local addons_path="$ODOO_PATH/addons"
    if [[ -d "$CUSTOM_MODULES_PATH" ]]; then
        addons_path="$addons_path,$CUSTOM_MODULES_PATH"
    fi
    if [[ -d "/opt/odoo/addons" ]]; then
        addons_path="$addons_path,/opt/odoo/addons"
    fi

    # Determine configuration based on environment
    local workers=0
    local log_level="info"
    local dev_mode="reload,qweb,werkzeug,xml"
    local without_demo="False"

    case "$environment" in
        "testing")
            workers=0
            log_level="warn"
            dev_mode=""
            without_demo="all"
            ;;
        "staging")
            workers=2
            log_level="warn"
            dev_mode=""
            without_demo="False"
            ;;
        "production")
            workers=4
            log_level="error"
            dev_mode=""
            without_demo="False"
            ;;
        *)
            # development (default)
            workers=0
            log_level="info"
            dev_mode="reload,qweb,werkzeug,xml"
            without_demo="False"
            ;;
    esac

    cat > "$config_file" << EOF
[options]
# =================================================================
# RTP Denver - Odoo Docker Configuration
# =================================================================
# Generated on: $(date)
# Environment: $environment
# Container: Docker

# Server Configuration
# ===================
addons_path = $addons_path
data_dir = $DATA_PATH
admin_passwd = $ADMIN_PASSWORD
csv_internal_sep = ,

# Database Configuration
# =====================
db_host = $DB_HOST
db_port = $DB_PORT
db_user = $DB_USER
db_password = $DB_PASSWORD
db_name = $DB_NAME
db_template = template0
db_maxconn = 64

# Network Configuration
# ====================
xmlrpc = True
xmlrpc_interface = 0.0.0.0
xmlrpc_port = 8069
longpolling_port = 8072

# Process Configuration
# ====================
workers = $workers
max_cron_threads = 2
proxy_mode = False

# Development Mode Settings
# ========================
dev_mode = $dev_mode
reload = True
auto_reload = True

# Logging Configuration
# ====================
logfile = False
log_level = $log_level
log_db = False
syslog = False
log_handler = :INFO

# Testing Configuration
# ====================
test_enable = True
test_file = False
screencasts = False
screenshots = False

# Security Configuration
# ======================
list_db = True
without_demo = $without_demo

# Internationalization
# ===================
load_language = en_US

# Performance Configuration
# ========================
unaccent = True
server_wide_modules = base,web
limit_memory_hard = 2684354560
limit_memory_soft = 2147483648
limit_request = 8192
limit_time_cpu = 600
limit_time_real = 1200

# Email Configuration (Development)
# ================================
email_from = False
smtp_server = localhost
smtp_port = 1025
smtp_ssl = False

EOF

    log_success "Configuration generated: $config_file"
}

# Initialize Odoo database
init_database() {
    local db_name="$1"
    local modules="${2:-base}"
    local with_demo="${3:-False}"

    log_info "Initializing database: $db_name with modules: $modules"

    local init_cmd="python $ODOO_PATH/odoo-bin"
    init_cmd="$init_cmd --config=$ODOO_CONFIG"
    init_cmd="$init_cmd --database=$db_name"
    init_cmd="$init_cmd --init=$modules"
    init_cmd="$init_cmd --without-demo=$with_demo"
    init_cmd="$init_cmd --stop-after-init"

    if eval "$init_cmd"; then
        log_success "Database $db_name initialized successfully"
    else
        log_error "Failed to initialize database: $db_name"
        exit 1
    fi
}

# Update existing database
update_database() {
    local db_name="$1"
    local modules="${2:-all}"

    log_info "Updating database: $db_name with modules: $modules"

    local update_cmd="python $ODOO_PATH/odoo-bin"
    update_cmd="$update_cmd --config=$ODOO_CONFIG"
    update_cmd="$update_cmd --database=$db_name"
    update_cmd="$update_cmd --update=$modules"
    update_cmd="$update_cmd --stop-after-init"

    if eval "$update_cmd"; then
        log_success "Database $db_name updated successfully"
    else
        log_error "Failed to update database: $db_name"
        exit 1
    fi
}

# Start Odoo server
start_odoo() {
    local additional_args="$*"

    log_info "Starting Odoo server..."
    log_info "Configuration: $ODOO_CONFIG"
    log_info "Database Host: $DB_HOST:$DB_PORT"
    log_info "Access URL: http://localhost:8069"
    log_info "Admin Password: $ADMIN_PASSWORD"

    # Final command
    local odoo_cmd="python $ODOO_PATH/odoo-bin --config=$ODOO_CONFIG $additional_args"

    log_info "Command: $odoo_cmd"
    exec $odoo_cmd
}

# Run scripts from our infrastructure
run_script() {
    local script_name="$1"
    shift
    local script_args="$*"

    local script_path="/opt/odoo/scripts/$script_name"

    if [[ ! -f "$script_path" ]]; then
        log_error "Script not found: $script_path"
        exit 1
    fi

    log_info "Running script: $script_name with args: $script_args"
    exec bash "$script_path" $script_args
}

# Show help
show_help() {
    echo "RTP Denver - Odoo Docker Container"
    echo "================================="
    echo ""
    echo "Usage: docker run [OPTIONS] rtp-denver-odoo [COMMAND] [ARGS...]"
    echo ""
    echo "Commands:"
    echo "  odoo                     Start Odoo server (default)"
    echo "  init DB [MODULES]        Initialize database with modules"
    echo "  update DB [MODULES]      Update database modules"
    echo "  shell                    Start interactive bash shell"
    echo "  script SCRIPT [ARGS]     Run script from our infrastructure"
    echo "  help                     Show this help message"
    echo ""
    echo "Environment Variables:"
    echo "  DB_HOST                  PostgreSQL host (default: postgres)"
    echo "  DB_PORT                  PostgreSQL port (default: 5432)"
    echo "  DB_USER                  PostgreSQL user (default: odoo)"
    echo "  DB_PASSWORD             PostgreSQL password"
    echo "  DB_NAME                 Default database name"
    echo "  ODOO_CONFIG             Odoo configuration file"
    echo "  ADMIN_PASSWORD          Odoo admin password (default: admin123)"
    echo "  ENVIRONMENT             Environment type (development, testing, staging, production)"
    echo ""
    echo "Examples:"
    echo "  # Start Odoo server"
    echo "  docker run -p 8069:8069 rtp-denver-odoo"
    echo ""
    echo "  # Initialize database with custom modules"
    echo "  docker run rtp-denver-odoo init mydb rtp_customers,royal_textiles_sales"
    echo ""
    echo "  # Run database management script"
    echo "  docker run rtp-denver-odoo script db-manager.sh list"
    echo ""
    echo "  # Start interactive shell for debugging"
    echo "  docker run -it rtp-denver-odoo shell"
    echo ""
}

# Main entrypoint logic
main() {
    # Ensure directories exist with proper permissions
    mkdir -p "$LOGS_PATH" "$DATA_PATH" "$CONFIG_PATH"

    # Wait for PostgreSQL if we're going to use it
    if [[ "${1:-odoo}" != "shell" && "${1:-odoo}" != "help" ]]; then
        wait_for_postgres
    fi

    # Generate configuration if it doesn't exist
    if [[ ! -f "$ODOO_CONFIG" ]]; then
        generate_odoo_config "$ODOO_CONFIG" "${ENVIRONMENT:-development}"
    fi

    # Parse command
    case "${1:-odoo}" in
        "odoo"|"")
            shift || true
            start_odoo "$@"
            ;;
        "init")
            if [[ $# -lt 2 ]]; then
                log_error "Database name required for init command"
                exit 1
            fi
            local db_name="$2"
            local modules="${3:-base}"
            local with_demo="${4:-False}"
            init_database "$db_name" "$modules" "$with_demo"
            ;;
        "update")
            if [[ $# -lt 2 ]]; then
                log_error "Database name required for update command"
                exit 1
            fi
            local db_name="$2"
            local modules="${3:-all}"
            update_database "$db_name" "$modules"
            ;;
        "shell")
            log_info "Starting interactive shell..."
            exec /bin/bash
            ;;
        "script")
            if [[ $# -lt 2 ]]; then
                log_error "Script name required for script command"
                exit 1
            fi
            shift
            run_script "$@"
            ;;
        "help"|"--help")
            show_help
            ;;
        *)
            log_error "Unknown command: $1"
            show_help
            exit 1
            ;;
    esac
}

# Run main function
main "$@"

#!/bin/bash

# Odoo Configuration Manager for Development Environment
# Task 3.4: Configure Odoo config file for development environment
#
# This script creates comprehensive Odoo configuration files for different environments
# and integrates with our existing local installation and database management
#
# Usage: ./scripts/configure-odoo.sh [COMMAND] [OPTIONS]

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ODOO_HOME="$PROJECT_ROOT/local-odoo"
ODOO_PATH="$ODOO_HOME/odoo"
VENV_PATH="$ODOO_HOME/venv"
LOGS_PATH="$ODOO_HOME/logs"
ADDONS_PATH="$ODOO_HOME/addons"
CUSTOM_MODULES_PATH="$PROJECT_ROOT/custom_modules"

# Default configuration values
ODOO_USER="${ODOO_DB_USER:-$(whoami)}"
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
HTTP_PORT="${HTTP_PORT:-8069}"
LONGPOLLING_PORT="${LONGPOLLING_PORT:-8072}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-admin123}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Show help message
show_help() {
    echo "Odoo Configuration Manager"
    echo "======================================"
    echo ""
    echo "Comprehensive Odoo configuration for development environments"
    echo ""
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  create ENV              Create configuration for environment"
    echo "  list                    List available configurations"
    echo "  validate CONFIG         Validate configuration file"
    echo "  backup CONFIG           Backup configuration file"
    echo "  restore BACKUP          Restore configuration from backup"
    echo "  show CONFIG             Show configuration contents"
    echo "  test CONFIG             Test configuration by starting Odoo"
    echo ""
    echo "Environments:"
    echo "  development            Full development configuration with debugging"
    echo "  testing                Configuration optimized for running tests"
    echo "  staging                Staging environment configuration"
    echo "  production             Production-like configuration for final testing"
    echo "  minimal                Minimal configuration for quick testing"
    echo ""
    echo "Options:"
    echo "  --port PORT            HTTP port (default: 8069)"
    echo "  --db-host HOST         Database host (default: localhost)"
    echo "  --db-port PORT         Database port (default: 5432)"
    echo "  --db-user USER         Database user (default: current user)"
    echo "  --admin-pass PASS      Admin password (default: admin123)"
    echo "  --workers COUNT        Number of workers (default: auto)"
    echo "  --memory-limit SIZE    Memory limit in bytes"
    echo "  --log-level LEVEL      Log level (debug, info, warn, error)"
    echo "  --enable-demo          Enable demo data"
    echo "  --disable-demo         Disable demo data"
    echo ""
    echo "Examples:"
    echo "  $0 create development                    # Create development config"
    echo "  $0 create testing --log-level debug     # Testing config with debug logs"
    echo "  $0 create production --workers 4        # Production config with 4 workers"
    echo "  $0 validate odoo-development.conf       # Validate configuration"
    echo "  $0 test odoo-development.conf           # Test configuration"
    echo ""
}

# Logging functions
log_info() {
    echo -e "${BLUE}[CONFIG-INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') $1" | tee -a "$LOGS_PATH/config.log"
}

log_success() {
    echo -e "${GREEN}[CONFIG-SUCCESS]${NC} $(date '+%Y-%m-%d %H:%M:%S') $1" | tee -a "$LOGS_PATH/config.log"
}

log_warning() {
    echo -e "${YELLOW}[CONFIG-WARNING]${NC} $(date '+%Y-%m-%d %H:%M:%S') $1" | tee -a "$LOGS_PATH/config.log"
}

log_error() {
    echo -e "${RED}[CONFIG-ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') $1" | tee -a "$LOGS_PATH/config.log"
}

log_debug() {
    if [[ "${DEBUG:-}" == "1" ]]; then
        echo -e "${CYAN}[CONFIG-DEBUG]${NC} $(date '+%Y-%m-%d %H:%M:%S') $1" | tee -a "$LOGS_PATH/config.log"
    fi
}

# Initialize logging
init_logging() {
    mkdir -p "$LOGS_PATH"
    touch "$LOGS_PATH/config.log"
}

# Check prerequisites
check_prerequisites() {
    log_debug "Checking prerequisites..."

    # Check if Odoo is installed
    if [[ ! -d "$ODOO_PATH" ]]; then
        log_error "Odoo installation not found at $ODOO_PATH"
        log_error "Please run: make install-odoo"
        exit 1
    fi

    # Check if virtual environment exists
    if [[ ! -d "$VENV_PATH" ]]; then
        log_error "Python virtual environment not found at $VENV_PATH"
        log_error "Please run: make install-odoo"
        exit 1
    fi

    # Create necessary directories
    mkdir -p "$ODOO_HOME/configs" "$ODOO_HOME/backups" "$LOGS_PATH"

    log_debug "Prerequisites check completed"
}

# Generate comprehensive addons path
generate_addons_path() {
    local addons_paths=()

    # Core Odoo addons
    if [[ -d "$ODOO_PATH/addons" ]]; then
        addons_paths+=("$ODOO_PATH/addons")
    fi

    # Enterprise addons (if available)
    if [[ -d "$ODOO_PATH/enterprise" ]]; then
        addons_paths+=("$ODOO_PATH/enterprise")
    fi

    # Custom addons directory
    if [[ -d "$ADDONS_PATH" ]]; then
        addons_paths+=("$ADDONS_PATH")
    fi

    # Project custom modules
    if [[ -d "$CUSTOM_MODULES_PATH" ]]; then
        addons_paths+=("$CUSTOM_MODULES_PATH")
    fi

    # Join paths with comma
    local IFS=','
    echo "${addons_paths[*]}"
}

# Create development configuration
create_development_config() {
    local config_file="$ODOO_HOME/configs/odoo-development.conf"
    local workers="${1:-0}"
    local log_level="${2:-info}"
    local demo_data="${3:-True}"

    log_info "Creating development configuration..."

    cat > "$config_file" << EOF
[options]
# =================================================================
# RTP Denver - Odoo Development Configuration
# =================================================================
# Generated on: $(date)
# Environment: Development
# Purpose: Local development with auto-reload and debugging support

# Server Configuration
# ===================
addons_path = $(generate_addons_path)
data_dir = ${ODOO_HOME}/filestore
admin_passwd = ${ADMIN_PASSWORD}
csv_internal_sep = ,

# Database Configuration
# =====================
db_host = ${DB_HOST}
db_port = ${DB_PORT}
db_user = ${ODOO_USER}
db_password = False
db_name = False
db_template = template0
db_maxconn = 64
db_sslmode = prefer

# Network Configuration
# ====================
xmlrpc = True
xmlrpc_interface =
xmlrpc_port = ${HTTP_PORT}
xmlrpcs = False
xmlrpcs_interface =
xmlrpcs_port = 8071

# Long Polling (Live Chat, POS)
# =============================
longpolling_port = ${LONGPOLLING_PORT}
gevent_port = ${LONGPOLLING_PORT}

# Process Configuration
# ====================
workers = ${workers}
max_cron_threads = 2
proxy_mode = False

# Development Mode Settings
# ========================
dev_mode = reload,qweb,werkzeug,xml
reload = True
auto_reload = True
shell_interface = ipython

# Memory Limits (Development - Generous)
# =====================================
limit_memory_hard = 4294967296
limit_memory_soft = 3221225472
limit_request = 16384
limit_time_cpu = 3600
limit_time_real = 7200
limit_time_real_cron = 3600

# Logging Configuration
# ====================
logfile = ${LOGS_PATH}/odoo-development.log
log_level = ${log_level}
log_db = False
log_db_level = warning
syslog = False
log_handler = :INFO,werkzeug:WARNING,odoo.modules.loading:INFO

# Email Configuration (Development - Disabled)
# ============================================
email_from = development@rtp-denver.local
smtp_server = localhost
smtp_port = 1025
smtp_ssl = False
smtp_user = False
smtp_password = False

# Testing Configuration
# ====================
test_enable = True
test_file = False
test_tags = None
screencasts = False
screenshots = False

# Security Configuration (Development)
# ===================================
list_db = True
list_db_filter = .*
dbfilter = .*
without_demo = ${demo_data}

# Internationalization
# ===================
load_language = en_US
translate_out = False
translate_in = False
overwrite_existing_translations = False

# Advanced Configuration
# =====================
unaccent = True
geoip_database = False
upgrade_path = False

# Server-wide modules
# ==================
server_wide_modules = base,web

# HTTP Configuration
# =================
http_enable = True
http_interface =
http_port = ${HTTP_PORT}

# Performance Monitoring (Development)
# ===================================
enable_modules = base,web
osv_memory_count_limit =
osv_memory_age_limit = 1.0

# Multiprocessing
# ==============
pidfile = ${ODOO_HOME}/odoo-development.pid
EOF

    log_success "Development configuration created: $config_file"
    echo "$config_file"
}

# Create testing configuration
create_testing_config() {
    local config_file="$ODOO_HOME/configs/odoo-testing.conf"
    local workers="${1:-0}"
    local log_level="${2:-error}"
    local demo_data="${3:-False}"

    log_info "Creating testing configuration..."

    cat > "$config_file" << EOF
[options]
# =================================================================
# RTP Denver - Odoo Testing Configuration
# =================================================================
# Generated on: $(date)
# Environment: Testing
# Purpose: Optimized for running automated tests

# Server Configuration
# ===================
addons_path = $(generate_addons_path)
data_dir = ${ODOO_HOME}/filestore-test
admin_passwd = ${ADMIN_PASSWORD}

# Database Configuration (Testing)
# ================================
db_host = ${DB_HOST}
db_port = ${DB_PORT}
db_user = ${ODOO_USER}
db_password = False
db_name = False
db_template = template0
db_maxconn = 16

# Network Configuration (Testing)
# ===============================
xmlrpc = True
xmlrpc_interface = 127.0.0.1
xmlrpc_port = 8169
longpolling_port = 8172

# Process Configuration (Testing)
# ===============================
workers = ${workers}
max_cron_threads = 0
proxy_mode = False

# Development Mode (Minimal for Testing)
# ======================================
dev_mode =
reload = False
auto_reload = False

# Memory Limits (Testing - Conservative)
# =====================================
limit_memory_hard = 2147483648
limit_memory_soft = 1610612736
limit_request = 8192
limit_time_cpu = 600
limit_time_real = 1200
limit_time_real_cron = 600

# Logging Configuration (Testing - Minimal)
# =========================================
logfile = ${LOGS_PATH}/odoo-testing.log
log_level = ${log_level}
log_db = False
log_db_level = critical
syslog = False
log_handler = :ERROR,werkzeug:CRITICAL

# Email Configuration (Testing - Disabled)
# ========================================
email_from = False
smtp_server = False

# Testing Configuration (Optimized)
# =================================
test_enable = True
test_file = False
test_tags =
screencasts = False
screenshots = False
stop_after_init = True

# Security Configuration (Testing)
# ================================
list_db = False
dbfilter = test_.*
without_demo = ${demo_data}

# Performance (Testing - Fast)
# ============================
unaccent = True
server_wide_modules = base,web
osv_memory_count_limit = 0
osv_memory_age_limit = False

# Multiprocessing
# ==============
pidfile = ${ODOO_HOME}/odoo-testing.pid
EOF

    log_success "Testing configuration created: $config_file"
    echo "$config_file"
}

# Create staging configuration
create_staging_config() {
    local config_file="$ODOO_HOME/configs/odoo-staging.conf"
    local workers="${1:-2}"
    local log_level="${2:-warn}"
    local demo_data="${3:-False}"

    log_info "Creating staging configuration..."

    cat > "$config_file" << EOF
[options]
# =================================================================
# RTP Denver - Odoo Staging Configuration
# =================================================================
# Generated on: $(date)
# Environment: Staging
# Purpose: Pre-production testing environment

# Server Configuration
# ===================
addons_path = $(generate_addons_path)
data_dir = ${ODOO_HOME}/filestore-staging
admin_passwd = ${ADMIN_PASSWORD}

# Database Configuration
# =====================
db_host = ${DB_HOST}
db_port = ${DB_PORT}
db_user = ${ODOO_USER}
db_password = False
db_name = False
db_template = template0
db_maxconn = 32
db_sslmode = require

# Network Configuration
# ====================
xmlrpc = True
xmlrpc_interface =
xmlrpc_port = 8269
longpolling_port = 8272

# Process Configuration (Multi-worker)
# ====================================
workers = ${workers}
max_cron_threads = 2
proxy_mode = True

# Development Mode (Disabled for Staging)
# =======================================
dev_mode =
reload = False
auto_reload = False

# Memory Limits (Staging - Production-like)
# =========================================
limit_memory_hard = 2684354560
limit_memory_soft = 2147483648
limit_request = 8192
limit_time_cpu = 600
limit_time_real = 1200
limit_time_real_cron = 900

# Logging Configuration (Staging)
# ===============================
logfile = ${LOGS_PATH}/odoo-staging.log
log_level = ${log_level}
log_db = True
log_db_level = warning
syslog = False
log_handler = :INFO,werkzeug:WARNING,odoo.sql_db:WARNING

# Email Configuration (Staging - Configured)
# ==========================================
email_from = staging@rtp-denver.local
smtp_server = localhost
smtp_port = 587
smtp_ssl = True
smtp_user = False
smtp_password = False

# Testing Configuration (Staging)
# ===============================
test_enable = False
test_file = False
screencasts = False
screenshots = False

# Security Configuration (Staging - Restrictive)
# ==============================================
list_db = False
dbfilter = staging_.*
without_demo = ${demo_data}

# Performance (Staging - Optimized)
# =================================
unaccent = True
server_wide_modules = base,web
osv_memory_count_limit =
osv_memory_age_limit = 1.0

# Caching
# =======
enable_modules = base,web

# Multiprocessing
# ==============
pidfile = ${ODOO_HOME}/odoo-staging.pid
EOF

    log_success "Staging configuration created: $config_file"
    echo "$config_file"
}

# Create production configuration
create_production_config() {
    local config_file="$ODOO_HOME/configs/odoo-production.conf"
    local workers="${1:-4}"
    local log_level="${2:-warn}"
    local demo_data="${3:-False}"

    log_info "Creating production configuration..."

    cat > "$config_file" << EOF
[options]
# =================================================================
# RTP Denver - Odoo Production Configuration
# =================================================================
# Generated on: $(date)
# Environment: Production
# Purpose: Production-ready configuration for final testing

# Server Configuration
# ===================
addons_path = $(generate_addons_path)
data_dir = ${ODOO_HOME}/filestore-production
admin_passwd = ${ADMIN_PASSWORD}

# Database Configuration (Production)
# ==================================
db_host = ${DB_HOST}
db_port = ${DB_PORT}
db_user = ${ODOO_USER}
db_password = False
db_name = False
db_template = template0
db_maxconn = 64
db_sslmode = require

# Network Configuration (Production)
# ==================================
xmlrpc = True
xmlrpc_interface = 0.0.0.0
xmlrpc_port = 8369
xmlrpcs = True
xmlrpcs_interface = 0.0.0.0
xmlrpcs_port = 8371
longpolling_port = 8372

# Process Configuration (Production)
# ==================================
workers = ${workers}
max_cron_threads = 2
proxy_mode = True

# Development Mode (Disabled)
# ===========================
dev_mode =
reload = False
auto_reload = False

# Memory Limits (Production)
# =========================
limit_memory_hard = 2684354560
limit_memory_soft = 2147483648
limit_request = 8192
limit_time_cpu = 300
limit_time_real = 600
limit_time_real_cron = 600

# Logging Configuration (Production)
# ==================================
logfile = ${LOGS_PATH}/odoo-production.log
log_level = ${log_level}
log_db = True
log_db_level = error
syslog = True
log_handler = :WARNING,werkzeug:ERROR,odoo.sql_db:ERROR

# Email Configuration (Production)
# ================================
email_from = production@rtp-denver.local
smtp_server = localhost
smtp_port = 587
smtp_ssl = True
smtp_user = False
smtp_password = False

# Testing Configuration (Production - Disabled)
# =============================================
test_enable = False
test_file = False
screencasts = False
screenshots = False

# Security Configuration (Production - Strict)
# ============================================
list_db = False
dbfilter = production_.*
without_demo = ${demo_data}

# Performance (Production - Optimized)
# ====================================
unaccent = True
server_wide_modules = base,web
osv_memory_count_limit = 0
osv_memory_age_limit = False

# Caching (Production)
# ===================
enable_modules = base,web

# Multiprocessing
# ==============
pidfile = ${ODOO_HOME}/odoo-production.pid
EOF

    log_success "Production configuration created: $config_file"
    echo "$config_file"
}

# Create minimal configuration
create_minimal_config() {
    local config_file="$ODOO_HOME/configs/odoo-minimal.conf"
    local workers="${1:-0}"
    local log_level="${2:-error}"
    local demo_data="${3:-False}"

    log_info "Creating minimal configuration..."

    cat > "$config_file" << EOF
[options]
# =================================================================
# RTP Denver - Odoo Minimal Configuration
# =================================================================
# Generated on: $(date)
# Environment: Minimal
# Purpose: Lightweight configuration for quick testing

# Essential Configuration Only
# ============================
addons_path = $(generate_addons_path)
data_dir = ${ODOO_HOME}/filestore-minimal
admin_passwd = ${ADMIN_PASSWORD}

# Database
# ========
db_host = ${DB_HOST}
db_port = ${DB_PORT}
db_user = ${ODOO_USER}

# Network
# =======
xmlrpc_port = 8469
longpolling_port = 8472

# Process
# =======
workers = ${workers}
max_cron_threads = 0

# Performance (Minimal)
# ====================
limit_memory_hard = 1073741824
limit_memory_soft = 838860800
limit_request = 4096
limit_time_cpu = 60
limit_time_real = 120

# Logging (Minimal)
# =================
logfile = ${LOGS_PATH}/odoo-minimal.log
log_level = ${log_level}

# Security (Minimal)
# ==================
list_db = True
without_demo = ${demo_data}

# Testing
# =======
test_enable = True

# Multiprocessing
# ==============
pidfile = ${ODOO_HOME}/odoo-minimal.pid
EOF

    log_success "Minimal configuration created: $config_file"
    echo "$config_file"
}

# List available configurations
list_configurations() {
    log_info "Available Odoo configurations:"

    echo -e "\n${CYAN}Configuration Files${NC} | ${CYAN}Environment${NC} | ${CYAN}Size${NC} | ${CYAN}Modified${NC}"
    echo "----------------------------------------------------------------"

    local config_dir="$ODOO_HOME/configs"
    local count=0

    if [[ -d "$config_dir" ]]; then
        for config_file in "$config_dir"/*.conf; do
            if [[ -f "$config_file" ]]; then
                local basename_file
                basename_file=$(basename "$config_file")

                local environment="unknown"
                if [[ "$basename_file" =~ odoo-([^.]+)\.conf ]]; then
                    environment="${BASH_REMATCH[1]}"
                fi

                local file_size
                file_size=$(ls -lh "$config_file" | awk '{print $5}')

                local modified
                modified=$(stat -f %Sm -t "%Y-%m-%d %H:%M" "$config_file" 2>/dev/null || stat -c %y "$config_file" | cut -d' ' -f1,2 | cut -d'.' -f1)

                printf "%-25s | %-12s | %-6s | %s\n" "$basename_file" "$environment" "$file_size" "$modified"
                ((count++))
            fi
        done
    fi

    if [[ $count -eq 0 ]]; then
        echo "No configuration files found. Create one with: $0 create <environment>"
    else
        echo ""
        log_info "Total configurations: $count"
    fi
}

# Validate configuration file
validate_configuration() {
    local config_file="$1"

    if [[ ! -f "$config_file" ]]; then
        config_file="$ODOO_HOME/configs/$config_file"
    fi

    if [[ ! -f "$config_file" ]]; then
        log_error "Configuration file not found: $config_file"
        return 1
    fi

    log_info "Validating configuration: $(basename "$config_file")"

    local errors=0
    local warnings=0

    # Check required sections
    if ! grep -q "^\[options\]" "$config_file"; then
        log_error "Missing [options] section"
        ((errors++))
    fi

    # Check critical options
    local required_options=(
        "addons_path"
        "db_host"
        "db_port"
        "db_user"
        "xmlrpc_port"
    )

    for option in "${required_options[@]}"; do
        if ! grep -q "^${option}" "$config_file"; then
            log_error "Missing required option: $option"
            ((errors++))
        fi
    done

    # Check for common issues
    if grep -q "^admin_passwd = admin$" "$config_file"; then
        log_warning "Using default admin password 'admin' - consider changing"
        ((warnings++))
    fi

    if grep -q "^workers = 0" "$config_file" && grep -q "^max_cron_threads = [1-9]" "$config_file"; then
        log_warning "workers=0 but max_cron_threads>0 - cron jobs won't run"
        ((warnings++))
    fi

    # Check paths exist
    local addons_path
    addons_path=$(grep "^addons_path" "$config_file" | cut -d'=' -f2 | xargs)

    if [[ -n "$addons_path" ]]; then
        IFS=',' read -ra PATHS <<< "$addons_path"
        for path in "${PATHS[@]}"; do
            path=$(echo "$path" | xargs)  # trim whitespace
            if [[ ! -d "$path" ]]; then
                log_warning "Addons path does not exist: $path"
                ((warnings++))
            fi
        done
    fi

    # Summary
    if [[ $errors -eq 0 ]]; then
        log_success "Configuration validation passed"
        if [[ $warnings -gt 0 ]]; then
            log_warning "Found $warnings warnings"
        fi
        return 0
    else
        log_error "Configuration validation failed with $errors errors and $warnings warnings"
        return 1
    fi
}

# Backup configuration
backup_configuration() {
    local config_file="$1"

    if [[ ! -f "$config_file" ]]; then
        config_file="$ODOO_HOME/configs/$config_file"
    fi

    if [[ ! -f "$config_file" ]]; then
        log_error "Configuration file not found: $config_file"
        return 1
    fi

    local backup_dir="$ODOO_HOME/backups"
    mkdir -p "$backup_dir"

    local timestamp
    timestamp=$(date '+%Y%m%d_%H%M%S')

    local backup_file="$backup_dir/$(basename "$config_file" .conf)_${timestamp}.conf"

    if cp "$config_file" "$backup_file"; then
        log_success "Configuration backed up: $backup_file"
        echo "$backup_file"
    else
        log_error "Failed to backup configuration"
        return 1
    fi
}

# Restore configuration
restore_configuration() {
    local backup_file="$1"

    if [[ ! -f "$backup_file" ]]; then
        backup_file="$ODOO_HOME/backups/$backup_file"
    fi

    if [[ ! -f "$backup_file" ]]; then
        log_error "Backup file not found: $backup_file"
        return 1
    fi

    # Extract original config name from backup filename
    local original_name
    original_name=$(basename "$backup_file" | sed 's/_[0-9]*_[0-9]*.conf/.conf/')

    local config_file="$ODOO_HOME/configs/$original_name"

    log_info "Restoring configuration from: $(basename "$backup_file")"

    if cp "$backup_file" "$config_file"; then
        log_success "Configuration restored: $config_file"
        echo "$config_file"
    else
        log_error "Failed to restore configuration"
        return 1
    fi
}

# Show configuration contents
show_configuration() {
    local config_file="$1"

    if [[ ! -f "$config_file" ]]; then
        config_file="$ODOO_HOME/configs/$config_file"
    fi

    if [[ ! -f "$config_file" ]]; then
        log_error "Configuration file not found: $config_file"
        return 1
    fi

    log_info "Configuration contents: $(basename "$config_file")"
    echo ""
    cat "$config_file"
}

# Test configuration
test_configuration() {
    local config_file="$1"

    if [[ ! -f "$config_file" ]]; then
        config_file="$ODOO_HOME/configs/$config_file"
    fi

    if [[ ! -f "$config_file" ]]; then
        log_error "Configuration file not found: $config_file"
        return 1
    fi

    log_info "Testing configuration: $(basename "$config_file")"

    # Validate first
    if ! validate_configuration "$config_file"; then
        log_error "Configuration validation failed"
        return 1
    fi

    # Test by trying to start Odoo
    source "$VENV_PATH/bin/activate"

    log_info "Starting Odoo with test configuration..."

    local test_log="$LOGS_PATH/config-test-$(date +%Y%m%d_%H%M%S).log"

    if timeout 30 python "$ODOO_PATH/odoo-bin" \
        --config="$config_file" \
        --stop-after-init \
        --without-demo=all \
        > "$test_log" 2>&1; then
        log_success "Configuration test passed"
        log_info "Test log: $test_log"
        return 0
    else
        log_error "Configuration test failed"
        log_error "Test log: $test_log"
        log_error "Last 10 lines of test log:"
        tail -10 "$test_log" | sed 's/^/  /'
        return 1
    fi
}

# Main function
main() {
    init_logging

    if [[ $# -eq 0 ]]; then
        show_help
        exit 0
    fi

    local command="$1"

    # Show help without checking prerequisites
    if [[ "$command" == "help" || "$command" == "--help" ]]; then
        show_help
        exit 0
    fi

    # Check prerequisites for all other commands
    check_prerequisites

    shift

    case "$command" in
        create)
            if [[ $# -eq 0 ]]; then
                log_error "Environment type required"
                exit 1
            fi

            local environment="$1"
            local workers=""
            local log_level=""
            local demo_data=""
            shift

            # Parse options
            while [[ $# -gt 0 ]]; do
                case "$1" in
                    --port)
                        HTTP_PORT="$2"
                        shift 2
                        ;;
                    --db-host)
                        DB_HOST="$2"
                        shift 2
                        ;;
                    --db-port)
                        DB_PORT="$2"
                        shift 2
                        ;;
                    --db-user)
                        ODOO_USER="$2"
                        shift 2
                        ;;
                    --admin-pass)
                        ADMIN_PASSWORD="$2"
                        shift 2
                        ;;
                    --workers)
                        workers="$2"
                        shift 2
                        ;;
                    --log-level)
                        log_level="$2"
                        shift 2
                        ;;
                    --enable-demo)
                        demo_data="True"
                        shift
                        ;;
                    --disable-demo)
                        demo_data="False"
                        shift
                        ;;
                    *)
                        log_error "Unknown option: $1"
                        exit 1
                        ;;
                esac
            done

            case "$environment" in
                development)
                    create_development_config "$workers" "$log_level" "$demo_data"
                    ;;
                testing)
                    create_testing_config "$workers" "$log_level" "$demo_data"
                    ;;
                staging)
                    create_staging_config "$workers" "$log_level" "$demo_data"
                    ;;
                production)
                    create_production_config "$workers" "$log_level" "$demo_data"
                    ;;
                minimal)
                    create_minimal_config "$workers" "$log_level" "$demo_data"
                    ;;
                *)
                    log_error "Unknown environment: $environment"
                    log_error "Supported environments: development, testing, staging, production, minimal"
                    exit 1
                    ;;
            esac
            ;;
        list)
            list_configurations
            ;;
        validate)
            if [[ $# -eq 0 ]]; then
                log_error "Configuration file required"
                exit 1
            fi
            validate_configuration "$1"
            ;;
        backup)
            if [[ $# -eq 0 ]]; then
                log_error "Configuration file required"
                exit 1
            fi
            backup_configuration "$1"
            ;;
        restore)
            if [[ $# -eq 0 ]]; then
                log_error "Backup file required"
                exit 1
            fi
            restore_configuration "$1"
            ;;
        show)
            if [[ $# -eq 0 ]]; then
                log_error "Configuration file required"
                exit 1
            fi
            show_configuration "$1"
            ;;
        test)
            if [[ $# -eq 0 ]]; then
                log_error "Configuration file required"
                exit 1
            fi
            test_configuration "$1"
            ;;
        help|--help)
            show_help
            ;;
        *)
            log_error "Unknown command: $command"
            show_help
            exit 1
            ;;
    esac
}

# Run main function
main "$@"

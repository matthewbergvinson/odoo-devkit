#!/bin/bash

# RTP Denver - PostgreSQL Setup for Odoo Development
# Task 3.2: Set up PostgreSQL database with proper user and permissions
#
# This script configures PostgreSQL specifically for Odoo 18.0 development
# with proper users, permissions, and database settings
#
# Usage: ./scripts/setup-postgresql.sh [OPTIONS]
# Options:
#   --create-user     Create Odoo database user
#   --setup-config    Configure PostgreSQL for Odoo
#   --create-dbs      Create development databases
#   --reset-all       Reset all PostgreSQL configuration
#   --help            Show this help message

set -euo pipefail

# Configuration
ODOO_DB_USER="${ODOO_DB_USER:-$(whoami)}"
ODOO_DB_PASSWORD="${ODOO_DB_PASSWORD:-}"
POSTGRES_VERSION="${POSTGRES_VERSION:-14}"
DEV_DATABASES=("odoo_dev" "odoo_test" "odoo_staging")

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Flags
CREATE_USER=false
SETUP_CONFIG=false
CREATE_DBS=false
RESET_ALL=false
SHOW_HELP=false

# Parse command line arguments
parse_arguments() {
    if [[ $# -eq 0 ]]; then
        # If no arguments, run full setup
        CREATE_USER=true
        SETUP_CONFIG=true
        CREATE_DBS=true
        return
    fi

    while [[ $# -gt 0 ]]; do
        case $1 in
            --create-user)
                CREATE_USER=true
                shift
                ;;
            --setup-config)
                SETUP_CONFIG=true
                shift
                ;;
            --create-dbs)
                CREATE_DBS=true
                shift
                ;;
            --reset-all)
                RESET_ALL=true
                shift
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
    echo "RTP Denver - PostgreSQL Setup for Odoo Development"
    echo "================================================="
    echo ""
    echo "Task 3.2: Set up PostgreSQL database with proper user and permissions"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --create-user     Create Odoo database user with proper permissions"
    echo "  --setup-config    Configure PostgreSQL for Odoo development"
    echo "  --create-dbs      Create development databases (dev, test, staging)"
    echo "  --reset-all       Reset all PostgreSQL configuration (DESTRUCTIVE)"
    echo "  --help            Show this help message"
    echo ""
    echo "Environment Variables:"
    echo "  ODOO_DB_USER      Database username (default: current user)"
    echo "  ODOO_DB_PASSWORD  Database password (optional, no password by default)"
    echo "  POSTGRES_VERSION  PostgreSQL version (default: 14)"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Full setup (create user, config, dbs)"
    echo "  $0 --create-user                     # Create user only"
    echo "  $0 --setup-config                    # Configure PostgreSQL only"
    echo "  $0 --create-dbs                      # Create development databases only"
    echo "  ODOO_DB_USER=odoo $0 --create-user   # Create specific user"
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

# Check PostgreSQL installation
check_postgresql() {
    log_info "Checking PostgreSQL installation..."

    if ! command_exists psql; then
        log_error "PostgreSQL is not installed or not in PATH"
        log_info "Please install PostgreSQL first:"
        if [[ "$OS" == "macos" ]]; then
            log_info "  brew install postgresql@${POSTGRES_VERSION}"
        elif [[ "$OS" == "linux" ]]; then
            log_info "  sudo apt-get install postgresql-${POSTGRES_VERSION}"
        fi
        exit 1
    fi

    # Check if PostgreSQL is running
    if ! pg_isready >/dev/null 2>&1; then
        log_warning "PostgreSQL is not running. Starting PostgreSQL..."
        if [[ "$OS" == "macos" ]]; then
            brew services start "postgresql@${POSTGRES_VERSION}" || brew services start postgresql
        elif [[ "$OS" == "linux" ]]; then
            sudo systemctl start postgresql
        fi

        # Wait for PostgreSQL to start
        sleep 3
        if ! pg_isready >/dev/null 2>&1; then
            log_error "Failed to start PostgreSQL"
            exit 1
        fi
    fi

    log_success "PostgreSQL is installed and running"
}

# Get PostgreSQL superuser name
get_postgres_superuser() {
    if [[ "$OS" == "macos" ]]; then
        # On macOS, current user is usually a superuser
        echo "$(whoami)"
    elif [[ "$OS" == "linux" ]]; then
        # On Linux, use postgres user
        echo "postgres"
    fi
}

# Execute PostgreSQL command as superuser
execute_as_superuser() {
    local cmd="$1"
    local superuser
    superuser=$(get_postgres_superuser)

    if [[ "$superuser" == "$(whoami)" ]]; then
        # Current user is superuser
        eval "$cmd"
    else
        # Switch to postgres user
        sudo -u "$superuser" bash -c "$cmd"
    fi
}

# Check if user exists
user_exists() {
    local username="$1"
    execute_as_superuser "psql -tAc \"SELECT 1 FROM pg_roles WHERE rolname='$username'\"" | grep -q 1
}

# Check if database exists
database_exists() {
    local dbname="$1"
    execute_as_superuser "psql -lqt" | cut -d \| -f 1 | grep -qw "$dbname"
}

# Create Odoo database user
create_odoo_user() {
    if [[ "$CREATE_USER" == false ]]; then
        return
    fi

    log_info "Creating Odoo database user: $ODOO_DB_USER"

    # Check if user already exists
    if user_exists "$ODOO_DB_USER"; then
        log_warning "User $ODOO_DB_USER already exists"
        log_info "Updating user permissions..."
    else
        log_info "Creating new user: $ODOO_DB_USER"
    fi

    # Create user with proper permissions for Odoo
    local create_user_sql=""
    if [[ -n "$ODOO_DB_PASSWORD" ]]; then
        create_user_sql="CREATE USER \"$ODOO_DB_USER\" WITH PASSWORD '$ODOO_DB_PASSWORD';"
    else
        create_user_sql="CREATE USER \"$ODOO_DB_USER\";"
    fi

    # Create or update user with Odoo-specific permissions
    execute_as_superuser "psql -c \"
        DO \\\$\\\$
        BEGIN
            IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '$ODOO_DB_USER') THEN
                $create_user_sql
            END IF;

            -- Grant necessary permissions for Odoo
            ALTER USER \"$ODOO_DB_USER\" CREATEDB;
            ALTER USER \"$ODOO_DB_USER\" WITH LOGIN;

            -- Grant permission to create extensions (needed for unaccent, etc.)
            ALTER USER \"$ODOO_DB_USER\" WITH SUPERUSER;
        END
        \\\$\\\$ LANGUAGE plpgsql;
    \""

    log_success "User $ODOO_DB_USER created/updated with proper permissions"

    # Display user information
    log_info "User permissions:"
    execute_as_superuser "psql -c \"\\du $ODOO_DB_USER\""
}

# Configure PostgreSQL for Odoo
setup_postgresql_config() {
    if [[ "$SETUP_CONFIG" == false ]]; then
        return
    fi

    log_info "Configuring PostgreSQL for Odoo development..."

    # Find PostgreSQL configuration directory
    local config_dir
    if [[ "$OS" == "macos" ]]; then
        # Homebrew PostgreSQL location
        if [[ -d "/opt/homebrew/var/postgresql@${POSTGRES_VERSION}" ]]; then
            config_dir="/opt/homebrew/var/postgresql@${POSTGRES_VERSION}"
        elif [[ -d "/usr/local/var/postgresql@${POSTGRES_VERSION}" ]]; then
            config_dir="/usr/local/var/postgresql@${POSTGRES_VERSION}"
        elif [[ -d "/opt/homebrew/var/postgres" ]]; then
            config_dir="/opt/homebrew/var/postgres"
        elif [[ -d "/usr/local/var/postgres" ]]; then
            config_dir="/usr/local/var/postgres"
        else
            log_warning "Could not find PostgreSQL config directory"
            return
        fi
    elif [[ "$OS" == "linux" ]]; then
        config_dir="/etc/postgresql/${POSTGRES_VERSION}/main"
        if [[ ! -d "$config_dir" ]]; then
            # Try alternative location
            config_dir="/var/lib/postgresql/${POSTGRES_VERSION}/main"
        fi
    fi

    local postgresql_conf="$config_dir/postgresql.conf"
    local pg_hba_conf="$config_dir/pg_hba.conf"

    if [[ -f "$postgresql_conf" ]]; then
        log_info "Updating PostgreSQL configuration: $postgresql_conf"

        # Backup original config
        if [[ ! -f "$postgresql_conf.backup" ]]; then
            if [[ "$OS" == "linux" ]]; then
                sudo cp "$postgresql_conf" "$postgresql_conf.backup"
            else
                cp "$postgresql_conf" "$postgresql_conf.backup"
            fi
            log_info "Created backup: $postgresql_conf.backup"
        fi

        # Create optimized configuration for Odoo development
        local temp_config="/tmp/postgresql_odoo.conf"
        cat > "$temp_config" << 'EOF'
# Odoo Development Optimizations
# These settings are optimized for local development, not production

# Connection settings
max_connections = 100                   # Sufficient for development
shared_buffers = 256MB                  # 25% of RAM for small dev systems
effective_cache_size = 1GB              # Estimate of OS cache

# Query optimization
work_mem = 4MB                          # Memory for sorts and joins
maintenance_work_mem = 64MB             # Memory for maintenance operations
checkpoint_completion_target = 0.9      # Spread checkpoints
wal_buffers = 16MB                      # WAL buffer size
default_statistics_target = 100         # Statistics for query planner

# Logging (helpful for development)
log_destination = 'stderr'
logging_collector = on
log_directory = 'pg_log'
log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'
log_statement = 'none'                  # Set to 'all' for debugging
log_duration = off                      # Set to 'on' for performance debugging
log_min_duration_statement = 1000      # Log slow queries (1 second)

# Locale settings for Odoo
lc_messages = 'en_US.UTF-8'
lc_monetary = 'en_US.UTF-8'
lc_numeric = 'en_US.UTF-8'
lc_time = 'en_US.UTF-8'
default_text_search_config = 'pg_catalog.english'

# Extensions needed by Odoo
shared_preload_libraries = 'pg_stat_statements'
EOF

        # Append our settings to the existing config
        if [[ "$OS" == "linux" ]]; then
            sudo bash -c "echo '' >> '$postgresql_conf'"
            sudo bash -c "echo '# RTP Denver - Odoo Development Settings' >> '$postgresql_conf'"
            sudo bash -c "cat '$temp_config' >> '$postgresql_conf'"
        else
            echo "" >> "$postgresql_conf"
            echo "# RTP Denver - Odoo Development Settings" >> "$postgresql_conf"
            cat "$temp_config" >> "$postgresql_conf"
        fi

        rm "$temp_config"
        log_success "PostgreSQL configuration updated"
    else
        log_warning "PostgreSQL config file not found: $postgresql_conf"
    fi

    # Configure authentication
    if [[ -f "$pg_hba_conf" ]]; then
        log_info "Updating PostgreSQL authentication: $pg_hba_conf"

        # Backup original
        if [[ ! -f "$pg_hba_conf.backup" ]]; then
            if [[ "$OS" == "linux" ]]; then
                sudo cp "$pg_hba_conf" "$pg_hba_conf.backup"
            else
                cp "$pg_hba_conf" "$pg_hba_conf.backup"
            fi
        fi

        # Add trust authentication for local development (if not already present)
        local auth_line="host    all             $ODOO_DB_USER        127.0.0.1/32            trust"
        if [[ "$OS" == "linux" ]]; then
            if ! sudo grep -q "$ODOO_DB_USER.*trust" "$pg_hba_conf"; then
                sudo bash -c "echo '$auth_line' >> '$pg_hba_conf'"
                log_info "Added trust authentication for $ODOO_DB_USER"
            fi
        else
            if ! grep -q "$ODOO_DB_USER.*trust" "$pg_hba_conf"; then
                echo "$auth_line" >> "$pg_hba_conf"
                log_info "Added trust authentication for $ODOO_DB_USER"
            fi
        fi
    fi

    # Restart PostgreSQL to apply configuration
    log_info "Restarting PostgreSQL to apply configuration changes..."
    if [[ "$OS" == "macos" ]]; then
        brew services restart "postgresql@${POSTGRES_VERSION}" || brew services restart postgresql
    elif [[ "$OS" == "linux" ]]; then
        sudo systemctl restart postgresql
    fi

    # Wait for restart
    sleep 3
    if pg_isready >/dev/null 2>&1; then
        log_success "PostgreSQL restarted successfully"
    else
        log_error "Failed to restart PostgreSQL"
        exit 1
    fi
}

# Create development databases
create_development_databases() {
    if [[ "$CREATE_DBS" == false ]]; then
        return
    fi

    log_info "Creating development databases..."

    for db in "${DEV_DATABASES[@]}"; do
        if database_exists "$db"; then
            log_warning "Database $db already exists"
        else
            log_info "Creating database: $db"
            execute_as_superuser "createdb -O \"$ODOO_DB_USER\" \"$db\""

            # Create necessary extensions
            execute_as_superuser "psql -d \"$db\" -c \"
                CREATE EXTENSION IF NOT EXISTS unaccent;
                CREATE EXTENSION IF NOT EXISTS pg_trgm;
                CREATE EXTENSION IF NOT EXISTS btree_gist;
            \""

            log_success "Database $db created with extensions"
        fi
    done

    log_success "Development databases ready"
}

# Reset all PostgreSQL configuration
reset_postgresql() {
    if [[ "$RESET_ALL" == false ]]; then
        return
    fi

    log_warning "Resetting PostgreSQL configuration (DESTRUCTIVE OPERATION)"
    read -p "Are you sure you want to reset all PostgreSQL configuration? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Reset cancelled"
        return
    fi

    # Drop development databases
    log_info "Dropping development databases..."
    for db in "${DEV_DATABASES[@]}"; do
        if database_exists "$db"; then
            log_info "Dropping database: $db"
            execute_as_superuser "dropdb \"$db\""
        fi
    done

    # Drop user if exists
    if user_exists "$ODOO_DB_USER"; then
        log_info "Dropping user: $ODOO_DB_USER"
        execute_as_superuser "psql -c \"DROP USER \\\"$ODOO_DB_USER\\\"\""
    fi

    # Restore configuration files
    if [[ "$OS" == "macos" ]]; then
        config_dir="/opt/homebrew/var/postgresql@${POSTGRES_VERSION}"
        [[ ! -d "$config_dir" ]] && config_dir="/usr/local/var/postgresql@${POSTGRES_VERSION}"
        [[ ! -d "$config_dir" ]] && config_dir="/opt/homebrew/var/postgres"
        [[ ! -d "$config_dir" ]] && config_dir="/usr/local/var/postgres"
    elif [[ "$OS" == "linux" ]]; then
        config_dir="/etc/postgresql/${POSTGRES_VERSION}/main"
    fi

    if [[ -f "$config_dir/postgresql.conf.backup" ]]; then
        log_info "Restoring PostgreSQL configuration..."
        if [[ "$OS" == "linux" ]]; then
            sudo cp "$config_dir/postgresql.conf.backup" "$config_dir/postgresql.conf"
            sudo cp "$config_dir/pg_hba.conf.backup" "$config_dir/pg_hba.conf"
        else
            cp "$config_dir/postgresql.conf.backup" "$config_dir/postgresql.conf"
            cp "$config_dir/pg_hba.conf.backup" "$config_dir/pg_hba.conf"
        fi
    fi

    # Restart PostgreSQL
    log_info "Restarting PostgreSQL..."
    if [[ "$OS" == "macos" ]]; then
        brew services restart "postgresql@${POSTGRES_VERSION}" || brew services restart postgresql
    elif [[ "$OS" == "linux" ]]; then
        sudo systemctl restart postgresql
    fi

    log_success "PostgreSQL configuration reset completed"
}

# Display setup summary
display_summary() {
    log_success "PostgreSQL setup for Odoo development completed!"
    echo ""
    echo -e "${GREEN}Configuration Summary:${NC}"
    echo "====================="
    echo "Database User:        $ODOO_DB_USER"
    echo "PostgreSQL Version:   $(psql --version | awk '{print $3}')"
    echo "Development Databases:"
    for db in "${DEV_DATABASES[@]}"; do
        if database_exists "$db"; then
            echo "  ✅ $db"
        else
            echo "  ❌ $db (not created)"
        fi
    done
    echo ""
    echo -e "${GREEN}Connection Testing:${NC}"
    echo "==================="
    echo "# Test database connection:"
    echo "psql -U $ODOO_DB_USER -d odoo_dev -c '\\l'"
    echo ""
    echo "# List all databases:"
    echo "psql -U $ODOO_DB_USER -l"
    echo ""
    echo -e "${GREEN}Next Steps:${NC}"
    echo "==========="
    echo "1. Test connection: psql -U $ODOO_DB_USER -d odoo_dev"
    echo "2. Create Odoo database: make create-db DB=my_project"
    echo "3. Start Odoo: make start-odoo"
    echo ""
    echo -e "${YELLOW}Notes:${NC}"
    echo "======"
    echo "- User $ODOO_DB_USER has SUPERUSER privileges for development"
    echo "- Authentication is set to 'trust' for localhost (development only)"
    echo "- Extensions unaccent, pg_trgm, and btree_gist are installed"
    echo "- Configuration is optimized for development, not production"
    echo ""
}

# Main function
main() {
    parse_arguments "$@"

    if [[ "$SHOW_HELP" == true ]]; then
        show_help
        exit 0
    fi

    echo -e "${BLUE}"
    echo "=============================================="
    echo "RTP Denver - PostgreSQL Setup for Odoo 18.0"
    echo "=============================================="
    echo -e "${NC}"
    echo "Task 3.2: Set up PostgreSQL database with proper user and permissions"
    echo ""

    detect_os
    check_postgresql

    if [[ "$RESET_ALL" == true ]]; then
        reset_postgresql
        exit 0
    fi

    log_info "Starting PostgreSQL setup for Odoo development..."

    # Setup steps
    create_odoo_user
    setup_postgresql_config
    create_development_databases

    display_summary
}

# Run main function with all arguments
main "$@"

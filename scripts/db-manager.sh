#!/bin/bash

# Advanced Database Manager for Odoo Development
# Task 3.3: Create database management scripts (create, drop, reset test databases)
#
# This script provides comprehensive database management for Odoo 18.0 development
# including safety features, backup integration, and test database management
#
# Usage: ./scripts/db-manager.sh [COMMAND] [OPTIONS]
# Commands:
#   create    Create a new database
#   drop      Drop an existing database
#   reset     Reset (drop and recreate) a database
#   clone     Clone an existing database
#   list      List all databases
#   info      Show database information
#   backup    Backup a database
#   restore   Restore a database from backup
#   test      Manage test databases
#   clean     Clean up old/unused databases

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ODOO_HOME="$PROJECT_ROOT/local-odoo"
VENV_PATH="$ODOO_HOME/venv"
CONFIG_PATH="$ODOO_HOME/odoo.conf"
BACKUP_DIR="$ODOO_HOME/backups"
LOGS_DIR="$ODOO_HOME/logs"

# Database configuration
DB_USER="${ODOO_DB_USER:-$(whoami)}"
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Database types
TEST_DB_PREFIX="test_"
DEV_DB_PREFIX="dev_"
STAGING_DB_PREFIX="staging_"

# Default databases
DEFAULT_DATABASES=("odoo_dev" "odoo_test" "odoo_staging")

# Show help message
show_help() {
    echo "Advanced Database Manager for Odoo Development"
    echo "=========================================================="
    echo ""
    echo "Task 3.3: Comprehensive database management for Odoo 18.0"
    echo ""
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  create DB_NAME [OPTIONS]     Create a new database"
    echo "  drop DB_NAME [--force]       Drop an existing database"
    echo "  reset DB_NAME [--force]      Reset (drop and recreate) database"
    echo "  clone SOURCE TARGET          Clone an existing database"
    echo "  list [--pattern PATTERN]     List databases (optionally filtered)"
    echo "  info DB_NAME                 Show detailed database information"
    echo "  backup DB_NAME [--compress]  Backup a database"
    echo "  restore BACKUP_FILE DB_NAME  Restore database from backup"
    echo "  test [SUBCOMMAND]            Manage test databases"
    echo "  clean [--dry-run]            Clean up old/unused databases"
    echo ""
    echo "Create Options:"
    echo "  --type TYPE                  Database type: dev, test, staging (default: dev)"
    echo "  --demo                       Install with demo data"
    echo "  --modules MODULE_LIST        Install specific modules (comma-separated)"
    echo "  --from-template TEMPLATE     Create from template database"
    echo "  --encoding ENCODING          Database encoding (default: UTF8)"
    echo ""
    echo "Test Subcommands:"
    echo "  test create NAME             Create test database"
    echo "  test list                    List all test databases"
    echo "  test clean                   Clean up all test databases"
    echo "  test reset-all               Reset all test databases"
    echo ""
    echo "Environment Variables:"
    echo "  ODOO_DB_USER                Database username (default: current user)"
    echo "  DB_HOST                     Database host (default: localhost)"
    echo "  DB_PORT                     Database port (default: 5432)"
    echo ""
    echo "Examples:"
    echo "  $0 create my_project                    # Create development database"
    echo "  $0 create test_feature --type test     # Create test database"
    echo "  $0 create demo_db --demo                # Create with demo data"
    echo "  $0 clone odoo_dev my_backup             # Clone database"
    echo "  $0 backup my_project --compress         # Create compressed backup"
    echo "  $0 test create unit_tests               # Create test database"
    echo "  $0 clean --dry-run                     # Preview cleanup"
    echo ""
}

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') $1" | tee -a "$LOGS_DIR/db-manager.log"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $(date '+%Y-%m-%d %H:%M:%S') $1" | tee -a "$LOGS_DIR/db-manager.log"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $(date '+%Y-%m-%d %H:%M:%S') $1" | tee -a "$LOGS_DIR/db-manager.log"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') $1" | tee -a "$LOGS_DIR/db-manager.log"
}

log_debug() {
    if [[ "${DEBUG:-}" == "1" ]]; then
        echo -e "${CYAN}[DEBUG]${NC} $(date '+%Y-%m-%d %H:%M:%S') $1" | tee -a "$LOGS_DIR/db-manager.log"
    fi
}

# Initialize logging
init_logging() {
    mkdir -p "$LOGS_DIR"
    touch "$LOGS_DIR/db-manager.log"
}

# Check prerequisites
check_prerequisites() {
    log_debug "Checking prerequisites..."

    # Check if PostgreSQL is available
    if ! command -v psql >/dev/null 2>&1; then
        log_error "PostgreSQL is not installed or not in PATH"
        exit 1
    fi

    # Check if PostgreSQL is running
    if ! pg_isready -h "$DB_HOST" -p "$DB_PORT" >/dev/null 2>&1; then
        log_error "PostgreSQL is not running on $DB_HOST:$DB_PORT"
        exit 1
    fi

    # Create necessary directories
    mkdir -p "$BACKUP_DIR" "$LOGS_DIR"

    log_debug "Prerequisites check completed"
}

# Check if database exists
database_exists() {
    local db_name="$1"
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -lqt | cut -d \| -f 1 | grep -qw "$db_name"
}

# Get database size
get_database_size() {
    local db_name="$1"
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$db_name" -tAc "
        SELECT pg_size_pretty(pg_database_size('$db_name'));
    " 2>/dev/null || echo "Unknown"
}

# Get database connection count
get_connection_count() {
    local db_name="$1"
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -tAc "
        SELECT count(*) FROM pg_stat_activity WHERE datname = '$db_name';
    " 2>/dev/null || echo "0"
}

# Generate database name based on type
generate_db_name() {
    local base_name="$1"
    local db_type="${2:-dev}"

    case "$db_type" in
        test)
            echo "${TEST_DB_PREFIX}${base_name}"
            ;;
        staging)
            echo "${STAGING_DB_PREFIX}${base_name}"
            ;;
        dev)
            if [[ "$base_name" == odoo_* ]]; then
                echo "$base_name"
            else
                echo "${DEV_DB_PREFIX}${base_name}"
            fi
            ;;
        *)
            echo "$base_name"
            ;;
    esac
}

# Create database
create_database() {
    local db_name="$1"
    local db_type="${2:-dev}"
    local demo_data="${3:-false}"
    local modules="${4:-base}"
    local template="${5:-}"
    local encoding="${6:-UTF8}"

    # Generate final database name
    local final_db_name
    final_db_name=$(generate_db_name "$db_name" "$db_type")

    log_info "Creating database: $final_db_name (type: $db_type)"

    # Check if database already exists
    if database_exists "$final_db_name"; then
        log_error "Database $final_db_name already exists"
        return 1
    fi

    # Create the database
    local create_cmd="createdb -h $DB_HOST -p $DB_PORT -U $DB_USER -E $encoding"

    if [[ -n "$template" ]]; then
        if database_exists "$template"; then
            create_cmd="$create_cmd -T $template"
            log_info "Creating from template: $template"
        else
            log_warning "Template database $template does not exist, creating empty database"
        fi
    fi

    create_cmd="$create_cmd $final_db_name"

    if eval "$create_cmd"; then
        log_success "Database $final_db_name created successfully"
    else
        log_error "Failed to create database $final_db_name"
        return 1
    fi

    # Install PostgreSQL extensions
    log_info "Installing PostgreSQL extensions..."
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$final_db_name" -c "
        CREATE EXTENSION IF NOT EXISTS unaccent;
        CREATE EXTENSION IF NOT EXISTS pg_trgm;
        CREATE EXTENSION IF NOT EXISTS btree_gist;
    " >/dev/null

    # Initialize with Odoo if config exists
    if [[ -f "$CONFIG_PATH" && -f "$VENV_PATH/bin/activate" ]]; then
        log_info "Initializing database with Odoo..."

        source "$VENV_PATH/bin/activate"

        local odoo_cmd="python $ODOO_HOME/odoo/odoo-bin --config=$CONFIG_PATH --database=$final_db_name"

        if [[ "$demo_data" == "true" ]]; then
            odoo_cmd="$odoo_cmd --without-demo=False"
        else
            odoo_cmd="$odoo_cmd --without-demo=all"
        fi

        if [[ "$modules" != "base" ]]; then
            odoo_cmd="$odoo_cmd --init=$modules"
        else
            odoo_cmd="$odoo_cmd --init=base"
        fi

        odoo_cmd="$odoo_cmd --stop-after-init"

        log_debug "Running: $odoo_cmd"

        if eval "$odoo_cmd" >/dev/null 2>&1; then
            log_success "Database $final_db_name initialized with Odoo"
        else
            log_warning "Failed to initialize database with Odoo, but database created"
        fi
    else
        log_warning "Odoo installation not found, database created without Odoo initialization"
    fi

    # Log database info
    log_info "Database $final_db_name created:"
    log_info "  Type: $db_type"
    log_info "  Size: $(get_database_size "$final_db_name")"
    log_info "  Encoding: $encoding"
    log_info "  Demo data: $demo_data"
    log_info "  Modules: $modules"
}

# Drop database
drop_database() {
    local db_name="$1"
    local force="${2:-false}"

    log_info "Preparing to drop database: $db_name"

    # Check if database exists
    if ! database_exists "$db_name"; then
        log_warning "Database $db_name does not exist"
        return 0
    fi

    # Check for active connections
    local connections
    connections=$(get_connection_count "$db_name")
    if [[ "$connections" -gt 0 ]]; then
        log_warning "Database $db_name has $connections active connections"

        if [[ "$force" == "true" ]]; then
            log_info "Terminating active connections..."
            psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -c "
                SELECT pg_terminate_backend(pid)
                FROM pg_stat_activity
                WHERE datname = '$db_name' AND pid <> pg_backend_pid();
            " >/dev/null
        else
            log_error "Cannot drop database with active connections. Use --force to terminate them."
            return 1
        fi
    fi

    # Confirm deletion unless force is used
    if [[ "$force" != "true" ]]; then
        local db_size
        db_size=$(get_database_size "$db_name")
        echo -e "${YELLOW}WARNING:${NC} This will permanently delete database '$db_name' (size: $db_size)"
        read -p "Are you sure you want to continue? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Database deletion cancelled"
            return 0
        fi
    fi

    # Drop the database
    if dropdb -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" "$db_name"; then
        log_success "Database $db_name dropped successfully"
    else
        log_error "Failed to drop database $db_name"
        return 1
    fi
}

# Reset database (drop and recreate)
reset_database() {
    local db_name="$1"
    local force="${2:-false}"
    local db_type="${3:-dev}"

    log_info "Resetting database: $db_name"

    # Store original database info for recreation
    local demo_data="false"
    local modules="base"

    if database_exists "$db_name"; then
        # Try to detect if it had demo data (this is a best guess)
        local has_demo
        has_demo=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$db_name" -tAc "
            SELECT count(*) > 0 FROM information_schema.tables
            WHERE table_name LIKE '%demo%' LIMIT 1;
        " 2>/dev/null || echo "false")

        if [[ "$has_demo" == "t" ]]; then
            demo_data="true"
        fi

        # Drop the database
        if ! drop_database "$db_name" "$force"; then
            log_error "Failed to drop database for reset"
            return 1
        fi
    fi

    # Recreate the database
    create_database "$db_name" "$db_type" "$demo_data" "$modules"
}

# Clone database
clone_database() {
    local source_db="$1"
    local target_db="$2"

    log_info "Cloning database: $source_db -> $target_db"

    # Check if source exists
    if ! database_exists "$source_db"; then
        log_error "Source database $source_db does not exist"
        return 1
    fi

    # Check if target already exists
    if database_exists "$target_db"; then
        log_error "Target database $target_db already exists"
        return 1
    fi

    # Create clone using template
    if createdb -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -T "$source_db" "$target_db"; then
        log_success "Database cloned: $source_db -> $target_db"
        log_info "  Source size: $(get_database_size "$source_db")"
        log_info "  Target size: $(get_database_size "$target_db")"
    else
        log_error "Failed to clone database"
        return 1
    fi
}

# List databases
list_databases() {
    local pattern="${1:-.*}"

    log_info "Listing databases (pattern: $pattern):"

    echo -e "\n${CYAN}Database Name${NC}${BLUE} | ${NC}${CYAN}Size${NC}${BLUE} | ${NC}${CYAN}Connections${NC}${BLUE} | ${NC}${CYAN}Type${NC}"
    echo "----------------------------------------"

    while IFS='|' read -r dbname; do
        dbname=$(echo "$dbname" | xargs)  # trim whitespace

        if [[ -n "$dbname" && "$dbname" =~ $pattern && "$dbname" != "template0" && "$dbname" != "template1" && "$dbname" != "postgres" ]]; then
            local size connections db_type
            size=$(get_database_size "$dbname")
            connections=$(get_connection_count "$dbname")

            # Determine database type
            if [[ "$dbname" =~ ^${TEST_DB_PREFIX} ]]; then
                db_type="test"
            elif [[ "$dbname" =~ ^${DEV_DB_PREFIX} ]]; then
                db_type="dev"
            elif [[ "$dbname" =~ ^${STAGING_DB_PREFIX} ]]; then
                db_type="staging"
            elif [[ " ${DEFAULT_DATABASES[*]} " =~ " ${dbname} " ]]; then
                db_type="default"
            else
                db_type="custom"
            fi

            printf "%-20s | %-8s | %-11s | %s\n" "$dbname" "$size" "$connections" "$db_type"
        fi
    done < <(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -lqt | cut -d \| -f 1)

    echo ""
}

# Show database information
show_database_info() {
    local db_name="$1"

    if ! database_exists "$db_name"; then
        log_error "Database $db_name does not exist"
        return 1
    fi

    log_info "Database information for: $db_name"

    # Get detailed database info
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$db_name" -c "
        SELECT
            current_database() as database_name,
            pg_size_pretty(pg_database_size(current_database())) as size,
            (SELECT count(*) FROM pg_stat_activity WHERE datname = current_database()) as connections,
            current_setting('server_encoding') as encoding,
            current_setting('lc_collate') as collate,
            current_setting('lc_ctype') as ctype;
    "

    echo ""
    log_info "Extensions:"
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$db_name" -c "
        SELECT extname as extension_name, extversion as version
        FROM pg_extension
        ORDER BY extname;
    "

    echo ""
    log_info "Table count:"
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$db_name" -c "
        SELECT schemaname, count(*) as table_count
        FROM pg_tables
        WHERE schemaname NOT IN ('information_schema', 'pg_catalog')
        GROUP BY schemaname
        ORDER BY schemaname;
    "
}

# Backup database
backup_database() {
    local db_name="$1"
    local compress="${2:-false}"

    if ! database_exists "$db_name"; then
        log_error "Database $db_name does not exist"
        return 1
    fi

    local timestamp
    timestamp=$(date '+%Y%m%d_%H%M%S')

    local backup_file="$BACKUP_DIR/${db_name}_${timestamp}"

    if [[ "$compress" == "true" ]]; then
        backup_file="${backup_file}.dump"
        log_info "Creating compressed backup: $backup_file"

        if pg_dump -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -Fc "$db_name" > "$backup_file"; then
            log_success "Backup created: $backup_file"
            log_info "  Backup size: $(ls -lh "$backup_file" | awk '{print $5}')"
        else
            log_error "Failed to create backup"
            return 1
        fi
    else
        backup_file="${backup_file}.sql"
        log_info "Creating SQL backup: $backup_file"

        if pg_dump -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" "$db_name" > "$backup_file"; then
            log_success "Backup created: $backup_file"
            log_info "  Backup size: $(ls -lh "$backup_file" | awk '{print $5}')"
        else
            log_error "Failed to create backup"
            return 1
        fi
    fi

    echo "$backup_file"
}

# Restore database from backup
restore_database() {
    local backup_file="$1"
    local db_name="$2"

    if [[ ! -f "$backup_file" ]]; then
        log_error "Backup file not found: $backup_file"
        return 1
    fi

    log_info "Restoring database $db_name from: $backup_file"

    # Drop existing database if it exists
    if database_exists "$db_name"; then
        log_warning "Database $db_name exists, dropping it first"
        if ! drop_database "$db_name" "true"; then
            log_error "Failed to drop existing database"
            return 1
        fi
    fi

    # Create new database
    if ! createdb -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" "$db_name"; then
        log_error "Failed to create database for restore"
        return 1
    fi

    # Determine backup format and restore
    if [[ "$backup_file" == *.dump ]]; then
        log_info "Restoring from custom format backup..."
        if pg_restore -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$db_name" "$backup_file"; then
            log_success "Database restored successfully"
        else
            log_error "Failed to restore database"
            return 1
        fi
    elif [[ "$backup_file" == *.sql ]]; then
        log_info "Restoring from SQL backup..."
        if psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$db_name" < "$backup_file" >/dev/null; then
            log_success "Database restored successfully"
        else
            log_error "Failed to restore database"
            return 1
        fi
    else
        log_error "Unknown backup format: $backup_file"
        return 1
    fi

    log_info "Restored database size: $(get_database_size "$db_name")"
}

# Test database management
manage_test_databases() {
    local subcmd="${1:-help}"
    local name="${2:-}"

    case "$subcmd" in
        create)
            if [[ -z "$name" ]]; then
                log_error "Test database name required"
                return 1
            fi
            create_database "$name" "test" "false" "base"
            ;;
        list)
            log_info "Test databases:"
            list_databases "^${TEST_DB_PREFIX}"
            ;;
        clean)
            log_info "Cleaning up test databases..."
            local count=0
            while IFS='|' read -r dbname; do
                dbname=$(echo "$dbname" | xargs)
                if [[ -n "$dbname" && "$dbname" =~ ^${TEST_DB_PREFIX} ]]; then
                    log_info "Dropping test database: $dbname"
                    drop_database "$dbname" "true"
                    ((count++))
                fi
            done < <(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -lqt | cut -d \| -f 1)
            log_success "Cleaned up $count test databases"
            ;;
        reset-all)
            log_info "Resetting all test databases..."
            while IFS='|' read -r dbname; do
                dbname=$(echo "$dbname" | xargs)
                if [[ -n "$dbname" && "$dbname" =~ ^${TEST_DB_PREFIX} ]]; then
                    log_info "Resetting test database: $dbname"
                    reset_database "$dbname" "true" "test"
                fi
            done < <(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -lqt | cut -d \| -f 1)
            ;;
        help|*)
            echo "Test database management commands:"
            echo "  test create NAME      Create test database"
            echo "  test list            List all test databases"
            echo "  test clean           Clean up all test databases"
            echo "  test reset-all       Reset all test databases"
            ;;
    esac
}

# Clean up databases
clean_databases() {
    local dry_run="${1:-false}"
    local days_old="${2:-7}"

    log_info "Cleaning up databases older than $days_old days (dry-run: $dry_run)"

    local count=0
    local total_size=0

    while IFS='|' read -r dbname; do
        dbname=$(echo "$dbname" | xargs)

        if [[ -n "$dbname" && "$dbname" =~ ^(${TEST_DB_PREFIX}|temp_|tmp_) ]]; then
            # Get database creation time (approximate via system catalog)
            local age_days
            age_days=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -tAc "
                SELECT EXTRACT(epoch FROM now() - pg_stat_file('base/'||oid||'/PG_VERSION').modification)/86400
                FROM pg_database WHERE datname = '$dbname';
            " 2>/dev/null | cut -d. -f1)

            if [[ -n "$age_days" && "$age_days" -gt "$days_old" ]]; then
                local size_mb
                size_mb=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$dbname" -tAc "
                    SELECT pg_database_size('$dbname')/1024/1024;
                " 2>/dev/null | cut -d. -f1)

                log_info "  $dbname (${age_days} days old, ${size_mb}MB)"

                if [[ "$dry_run" != "true" ]]; then
                    drop_database "$dbname" "true"
                fi

                ((count++))
                ((total_size += size_mb))
            fi
        fi
    done < <(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -lqt | cut -d \| -f 1)

    if [[ "$dry_run" == "true" ]]; then
        log_info "Would clean up $count databases (${total_size}MB total)"
        log_info "Run without --dry-run to actually clean up"
    else
        log_success "Cleaned up $count databases (${total_size}MB total)"
    fi
}

# Main function
main() {
    init_logging
    check_prerequisites

    if [[ $# -eq 0 ]]; then
        show_help
        exit 0
    fi

    local command="$1"
    shift

    case "$command" in
        create)
            if [[ $# -eq 0 ]]; then
                log_error "Database name required"
                exit 1
            fi

            local db_name="$1"
            local db_type="dev"
            local demo_data="false"
            local modules="base"
            local template=""
            local encoding="UTF8"

            shift

            while [[ $# -gt 0 ]]; do
                case "$1" in
                    --type)
                        db_type="$2"
                        shift 2
                        ;;
                    --demo)
                        demo_data="true"
                        shift
                        ;;
                    --modules)
                        modules="$2"
                        shift 2
                        ;;
                    --from-template)
                        template="$2"
                        shift 2
                        ;;
                    --encoding)
                        encoding="$2"
                        shift 2
                        ;;
                    *)
                        log_error "Unknown option: $1"
                        exit 1
                        ;;
                esac
            done

            create_database "$db_name" "$db_type" "$demo_data" "$modules" "$template" "$encoding"
            ;;
        drop)
            if [[ $# -eq 0 ]]; then
                log_error "Database name required"
                exit 1
            fi

            local db_name="$1"
            local force="false"
            shift

            while [[ $# -gt 0 ]]; do
                case "$1" in
                    --force)
                        force="true"
                        shift
                        ;;
                    *)
                        log_error "Unknown option: $1"
                        exit 1
                        ;;
                esac
            done

            drop_database "$db_name" "$force"
            ;;
        reset)
            if [[ $# -eq 0 ]]; then
                log_error "Database name required"
                exit 1
            fi

            local db_name="$1"
            local force="false"
            local db_type="dev"
            shift

            while [[ $# -gt 0 ]]; do
                case "$1" in
                    --force)
                        force="true"
                        shift
                        ;;
                    --type)
                        db_type="$2"
                        shift 2
                        ;;
                    *)
                        log_error "Unknown option: $1"
                        exit 1
                        ;;
                esac
            done

            reset_database "$db_name" "$force" "$db_type"
            ;;
        clone)
            if [[ $# -lt 2 ]]; then
                log_error "Source and target database names required"
                exit 1
            fi

            clone_database "$1" "$2"
            ;;
        list)
            local pattern=".*"

            while [[ $# -gt 0 ]]; do
                case "$1" in
                    --pattern)
                        pattern="$2"
                        shift 2
                        ;;
                    *)
                        log_error "Unknown option: $1"
                        exit 1
                        ;;
                esac
            done

            list_databases "$pattern"
            ;;
        info)
            if [[ $# -eq 0 ]]; then
                log_error "Database name required"
                exit 1
            fi

            show_database_info "$1"
            ;;
        backup)
            if [[ $# -eq 0 ]]; then
                log_error "Database name required"
                exit 1
            fi

            local db_name="$1"
            local compress="false"
            shift

            while [[ $# -gt 0 ]]; do
                case "$1" in
                    --compress)
                        compress="true"
                        shift
                        ;;
                    *)
                        log_error "Unknown option: $1"
                        exit 1
                        ;;
                esac
            done

            backup_database "$db_name" "$compress"
            ;;
        restore)
            if [[ $# -lt 2 ]]; then
                log_error "Backup file and database name required"
                exit 1
            fi

            restore_database "$1" "$2"
            ;;
        test)
            manage_test_databases "$@"
            ;;
        clean)
            local dry_run="false"
            local days_old="7"

            while [[ $# -gt 0 ]]; do
                case "$1" in
                    --dry-run)
                        dry_run="true"
                        shift
                        ;;
                    --days)
                        days_old="$2"
                        shift 2
                        ;;
                    *)
                        log_error "Unknown option: $1"
                        exit 1
                        ;;
                esac
            done

            clean_databases "$dry_run" "$days_old"
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

# Run main function with all arguments
main "$@"

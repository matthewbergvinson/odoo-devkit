#!/bin/bash

# RTP Denver - Test Database Manager for Odoo Development
# Task 3.3: Specialized test database management
#
# This script provides comprehensive test database management including
# isolation, data seeding, parallel test support, and automated cleanup
#
# Usage: ./scripts/db-test-manager.sh [COMMAND] [OPTIONS]

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ODOO_HOME="$PROJECT_ROOT/local-odoo"
LOGS_DIR="$ODOO_HOME/logs"

# Test database configuration
TEST_DB_PREFIX="test_"
TEMP_DB_PREFIX="temp_test_"
FIXTURE_DB_PREFIX="fixture_"

# Database settings
DB_USER="${ODOO_DB_USER:-$(whoami)}"
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Show help
show_help() {
    echo "RTP Denver - Test Database Manager"
    echo "================================="
    echo ""
    echo "Specialized test database management for Odoo development"
    echo ""
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  create NAME [OPTIONS]            Create test database"
    echo "  create-fixture NAME [OPTIONS]    Create fixture database for testing"
    echo "  create-temp [OPTIONS]            Create temporary test database"
    echo "  seed DB_NAME [--fixture NAME]    Seed database with test data"
    echo "  clone-for-test SOURCE [NAME]     Clone database for testing"
    echo "  list [--type TYPE]               List test databases"
    echo "  clean [--age DAYS]               Clean up test databases"
    echo "  reset NAME                       Reset test database to clean state"
    echo "  parallel-setup COUNT             Setup parallel test databases"
    echo "  run-test DB_NAME MODULE          Run Odoo tests on specific database"
    echo "  isolate NAME                     Create isolated test environment"
    echo ""
    echo "Create Options:"
    echo "  --modules MODULES               Install specific modules"
    echo "  --demo                          Include demo data"
    echo "  --empty                         Create empty database (no base modules)"
    echo "  --copy-from DB                  Copy structure from existing database"
    echo ""
    echo "Test Types:"
    echo "  --type unit                     Unit test database"
    echo "  --type integration              Integration test database"
    echo "  --type functional               Functional test database"
    echo "  --type performance              Performance test database"
    echo ""
    echo "Examples:"
    echo "  $0 create unit_tests --type unit           # Create unit test database"
    echo "  $0 create-fixture base_data --demo         # Create fixture with demo data"
    echo "  $0 seed test_db --fixture base_data        # Seed with fixture data"
    echo "  $0 parallel-setup 4                       # Setup 4 parallel test DBs"
    echo "  $0 run-test test_sales sale                # Run sales module tests"
    echo "  $0 clean --age 1                          # Clean DBs older than 1 day"
    echo ""
}

# Logging functions
log_info() {
    echo -e "${BLUE}[TEST-DB-INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') $1" | tee -a "$LOGS_DIR/test-db.log"
}

log_success() {
    echo -e "${GREEN}[TEST-DB-SUCCESS]${NC} $(date '+%Y-%m-%d %H:%M:%S') $1" | tee -a "$LOGS_DIR/test-db.log"
}

log_warning() {
    echo -e "${YELLOW}[TEST-DB-WARNING]${NC} $(date '+%Y-%m-%d %H:%M:%S') $1" | tee -a "$LOGS_DIR/test-db.log"
}

log_error() {
    echo -e "${RED}[TEST-DB-ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') $1" | tee -a "$LOGS_DIR/test-db.log"
}

log_debug() {
    if [[ "${DEBUG:-}" == "1" ]]; then
        echo -e "${CYAN}[TEST-DB-DEBUG]${NC} $(date '+%Y-%m-%d %H:%M:%S') $1" | tee -a "$LOGS_DIR/test-db.log"
    fi
}

# Initialize logging
init_logging() {
    mkdir -p "$LOGS_DIR"
    touch "$LOGS_DIR/test-db.log"
}

# Check prerequisites
check_prerequisites() {
    # Check PostgreSQL
    if ! command -v psql >/dev/null 2>&1; then
        log_error "PostgreSQL is not installed"
        exit 1
    fi

    if ! pg_isready -h "$DB_HOST" -p "$DB_PORT" >/dev/null 2>&1; then
        log_error "PostgreSQL is not running on $DB_HOST:$DB_PORT"
        exit 1
    fi

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

# Generate test database name
generate_test_db_name() {
    local base_name="$1"
    local db_type="${2:-test}"
    local timestamp="${3:-$(date +%s)}"

    case "$db_type" in
        fixture)
            echo "${FIXTURE_DB_PREFIX}${base_name}"
            ;;
        temp)
            echo "${TEMP_DB_PREFIX}${base_name}_${timestamp}"
            ;;
        *)
            echo "${TEST_DB_PREFIX}${base_name}"
            ;;
    esac
}

# Create test database
create_test_database() {
    local name="$1"
    local db_type="${2:-test}"
    local modules="${3:-base}"
    local demo_data="${4:-false}"
    local empty="${5:-false}"
    local copy_from="${6:-}"

    local db_name
    db_name=$(generate_test_db_name "$name" "$db_type")

    log_info "Creating test database: $db_name"

    # Check if database already exists
    if database_exists "$db_name"; then
        log_error "Test database $db_name already exists"
        return 1
    fi

    # Create database
    local create_cmd="createdb -h $DB_HOST -p $DB_PORT -U $DB_USER"

    if [[ -n "$copy_from" ]]; then
        if database_exists "$copy_from"; then
            create_cmd="$create_cmd -T $copy_from"
            log_info "Creating from template: $copy_from"
        else
            log_warning "Template database $copy_from does not exist"
        fi
    fi

    create_cmd="$create_cmd $db_name"

    if eval "$create_cmd"; then
        log_success "Test database $db_name created"
    else
        log_error "Failed to create test database $db_name"
        return 1
    fi

    # Install PostgreSQL extensions
    log_info "Installing PostgreSQL extensions..."
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$db_name" -c "
        CREATE EXTENSION IF NOT EXISTS unaccent;
        CREATE EXTENSION IF NOT EXISTS pg_trgm;
        CREATE EXTENSION IF NOT EXISTS btree_gist;
    " >/dev/null

    # Initialize with Odoo if not empty
    if [[ "$empty" != "true" && -d "$ODOO_HOME/odoo" ]]; then
        log_info "Initializing test database with Odoo..."

        if [[ -f "$ODOO_HOME/venv/bin/activate" ]]; then
            source "$ODOO_HOME/venv/bin/activate"
        fi

        local odoo_cmd="python $ODOO_HOME/odoo/odoo-bin"
        local config_file="$ODOO_HOME/odoo.conf"

        if [[ -f "$config_file" ]]; then
            odoo_cmd="$odoo_cmd --config=$config_file"
        fi

        odoo_cmd="$odoo_cmd --database=$db_name"

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

        odoo_cmd="$odoo_cmd --stop-after-init --log-level=error"

        log_debug "Running: $odoo_cmd"

        if eval "$odoo_cmd" >/dev/null 2>&1; then
            log_success "Test database initialized with Odoo"
        else
            log_warning "Failed to initialize with Odoo, but database created"
        fi
    fi

    # Create test metadata
    create_test_metadata "$db_name" "$db_type" "$modules" "$demo_data"

    log_info "Test database created:"
    log_info "  Name: $db_name"
    log_info "  Type: $db_type"
    log_info "  Size: $(get_database_size "$db_name")"
    log_info "  Modules: $modules"
    log_info "  Demo data: $demo_data"

    echo "$db_name"
}

# Create test metadata
create_test_metadata() {
    local db_name="$1"
    local db_type="$2"
    local modules="$3"
    local demo_data="$4"

    local metadata_dir="$ODOO_HOME/test-metadata"
    mkdir -p "$metadata_dir"

    cat > "$metadata_dir/${db_name}.json" << EOF
{
    "database": "$db_name",
    "type": "$db_type",
    "created": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "modules": "$modules",
    "demo_data": $demo_data,
    "creator": "$(whoami)",
    "purpose": "test database for odoo development"
}
EOF
}

# Create fixture database
create_fixture_database() {
    local name="$1"
    local modules="${2:-base}"
    local demo_data="${3:-true}"

    log_info "Creating fixture database: $name"

    local fixture_db
    fixture_db=$(create_test_database "$name" "fixture" "$modules" "$demo_data" "false" "")

    if [[ -n "$fixture_db" ]]; then
        log_success "Fixture database created: $fixture_db"
        log_info "This database can be used as a template for test databases"
        echo "$fixture_db"
    else
        log_error "Failed to create fixture database"
        return 1
    fi
}

# Create temporary test database
create_temp_database() {
    local modules="${1:-base}"
    local demo_data="${2:-false}"
    local copy_from="${3:-}"

    local temp_name="temp_$(date +%s)_$$"
    local temp_db
    temp_db=$(create_test_database "$temp_name" "temp" "$modules" "$demo_data" "false" "$copy_from")

    if [[ -n "$temp_db" ]]; then
        log_success "Temporary test database created: $temp_db"
        echo "$temp_db"
    else
        log_error "Failed to create temporary test database"
        return 1
    fi
}

# Seed database with test data
seed_database() {
    local db_name="$1"
    local fixture_name="${2:-}"
    local custom_data="${3:-}"

    if ! database_exists "$db_name"; then
        log_error "Database $db_name does not exist"
        return 1
    fi

    log_info "Seeding database: $db_name"

    # Seed from fixture if specified
    if [[ -n "$fixture_name" ]]; then
        local fixture_db="${FIXTURE_DB_PREFIX}${fixture_name}"

        if database_exists "$fixture_db"; then
            log_info "Seeding from fixture: $fixture_db"

            # Export fixture data and import to target
            local temp_file
            temp_file=$(mktemp)

            if pg_dump -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" --data-only "$fixture_db" > "$temp_file"; then
                if psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$db_name" < "$temp_file" >/dev/null; then
                    log_success "Database seeded from fixture"
                else
                    log_error "Failed to import fixture data"
                fi
            else
                log_error "Failed to export fixture data"
            fi

            rm -f "$temp_file"
        else
            log_error "Fixture database $fixture_db does not exist"
            return 1
        fi
    fi

    # Seed with custom data if provided
    if [[ -n "$custom_data" && -f "$custom_data" ]]; then
        log_info "Seeding with custom data: $custom_data"

        if psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$db_name" < "$custom_data" >/dev/null; then
            log_success "Database seeded with custom data"
        else
            log_error "Failed to seed with custom data"
            return 1
        fi
    fi

    log_success "Database seeding completed"
}

# Clone database for testing
clone_for_test() {
    local source_db="$1"
    local test_name="${2:-cloned_$(date +%s)}"

    if ! database_exists "$source_db"; then
        log_error "Source database $source_db does not exist"
        return 1
    fi

    local test_db
    test_db=$(generate_test_db_name "$test_name")

    log_info "Cloning $source_db to test database: $test_db"

    if createdb -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -T "$source_db" "$test_db"; then
        create_test_metadata "$test_db" "cloned" "inherited" "inherited"
        log_success "Database cloned for testing: $test_db"
        echo "$test_db"
    else
        log_error "Failed to clone database"
        return 1
    fi
}

# List test databases
list_test_databases() {
    local type_filter="${1:-}"

    log_info "Test databases:"

    echo -e "\n${CYAN}Database Name${NC} | ${CYAN}Type${NC} | ${CYAN}Size${NC} | ${CYAN}Created${NC}"
    echo "---------------------------------------------------------------"

    local count=0

    while IFS='|' read -r dbname; do
        dbname=$(echo "$dbname" | xargs)

        if [[ -n "$dbname" && ("$dbname" =~ ^${TEST_DB_PREFIX} || "$dbname" =~ ^${FIXTURE_DB_PREFIX} || "$dbname" =~ ^${TEMP_DB_PREFIX}) ]]; then
            # Get metadata if available
            local metadata_file="$ODOO_HOME/test-metadata/${dbname}.json"
            local db_type="unknown"
            local created="unknown"

            if [[ -f "$metadata_file" ]]; then
                db_type=$(jq -r '.type' "$metadata_file" 2>/dev/null || echo "unknown")
                created=$(jq -r '.created' "$metadata_file" 2>/dev/null || echo "unknown")
            else
                # Determine type from prefix
                if [[ "$dbname" =~ ^${TEST_DB_PREFIX} ]]; then
                    db_type="test"
                elif [[ "$dbname" =~ ^${FIXTURE_DB_PREFIX} ]]; then
                    db_type="fixture"
                elif [[ "$dbname" =~ ^${TEMP_DB_PREFIX} ]]; then
                    db_type="temporary"
                fi
            fi

            # Filter by type if specified
            if [[ -z "$type_filter" || "$db_type" == "$type_filter" ]]; then
                local size
                size=$(get_database_size "$dbname")

                printf "%-25s | %-8s | %-8s | %s\n" "$dbname" "$db_type" "$size" "$created"
                ((count++))
            fi
        fi
    done < <(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -lqt | cut -d \| -f 1)

    echo ""
    log_info "Total test databases: $count"
}

# Clean up test databases
clean_test_databases() {
    local age_days="${1:-1}"
    local dry_run="${2:-false}"

    log_info "Cleaning test databases older than $age_days days (dry-run: $dry_run)"

    local count=0
    local total_size=0

    while IFS='|' read -r dbname; do
        dbname=$(echo "$dbname" | xargs)

        if [[ -n "$dbname" && ("$dbname" =~ ^${TEST_DB_PREFIX} || "$dbname" =~ ^${TEMP_DB_PREFIX}) ]]; then
            # Check age
            local age_seconds
            age_seconds=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -tAc "
                SELECT EXTRACT(epoch FROM now() - pg_stat_file('base/'||oid||'/PG_VERSION').modification)
                FROM pg_database WHERE datname = '$dbname';
            " 2>/dev/null | cut -d. -f1)

            local age_days_actual=$((age_seconds / 86400))

            if [[ -n "$age_days_actual" && "$age_days_actual" -gt "$age_days" ]]; then
                local size_bytes
                size_bytes=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$dbname" -tAc "
                    SELECT pg_database_size('$dbname');
                " 2>/dev/null || echo "0")

                log_info "  $dbname (${age_days_actual} days old, $(numfmt --to=iec $size_bytes))"

                if [[ "$dry_run" != "true" ]]; then
                    dropdb -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" "$dbname" >/dev/null 2>&1
                    rm -f "$ODOO_HOME/test-metadata/${dbname}.json"
                fi

                ((count++))
                ((total_size += size_bytes))
            fi
        fi
    done < <(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -lqt | cut -d \| -f 1)

    if [[ "$dry_run" == "true" ]]; then
        log_info "Would clean $count databases ($(numfmt --to=iec $total_size))"
    else
        log_success "Cleaned $count test databases ($(numfmt --to=iec $total_size))"
    fi
}

# Reset test database
reset_test_database() {
    local db_name="$1"

    if ! database_exists "$db_name"; then
        log_error "Test database $db_name does not exist"
        return 1
    fi

    # Get original metadata
    local metadata_file="$ODOO_HOME/test-metadata/${db_name}.json"
    local modules="base"
    local demo_data="false"
    local db_type="test"

    if [[ -f "$metadata_file" ]]; then
        modules=$(jq -r '.modules' "$metadata_file" 2>/dev/null || echo "base")
        demo_data=$(jq -r '.demo_data' "$metadata_file" 2>/dev/null || echo "false")
        db_type=$(jq -r '.type' "$metadata_file" 2>/dev/null || echo "test")
    fi

    log_info "Resetting test database: $db_name"

    # Drop and recreate
    if dropdb -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" "$db_name"; then
        log_info "Dropped existing database"

        # Extract base name from full database name
        local base_name="$db_name"
        base_name=${base_name#$TEST_DB_PREFIX}
        base_name=${base_name#$FIXTURE_DB_PREFIX}
        base_name=${base_name#$TEMP_DB_PREFIX}

        if create_test_database "$base_name" "$db_type" "$modules" "$demo_data" "false" "" >/dev/null; then
            log_success "Test database reset successfully"
        else
            log_error "Failed to recreate test database"
            return 1
        fi
    else
        log_error "Failed to drop test database"
        return 1
    fi
}

# Setup parallel test databases
setup_parallel_tests() {
    local count="$1"
    local base_name="${2:-parallel_test}"
    local modules="${3:-base}"

    log_info "Setting up $count parallel test databases"

    local created_dbs=()

    for ((i=1; i<=count; i++)); do
        local db_name="${base_name}_${i}"

        if create_test_database "$db_name" "test" "$modules" "false" "false" "" >/dev/null; then
            created_dbs+=("${TEST_DB_PREFIX}${db_name}")
            log_info "Created parallel test database $i: ${TEST_DB_PREFIX}${db_name}"
        else
            log_error "Failed to create parallel test database $i"
        fi
    done

    log_success "Created ${#created_dbs[@]} parallel test databases"

    # Save parallel test configuration
    local config_file="$ODOO_HOME/parallel-test-config.json"
    printf '%s\n' "${created_dbs[@]}" | jq -R . | jq -s . > "$config_file"

    log_info "Parallel test configuration saved to: $config_file"
}

# Run Odoo tests on specific database
run_odoo_test() {
    local db_name="$1"
    local module="${2:-}"
    local test_tags="${3:-}"

    if ! database_exists "$db_name"; then
        log_error "Test database $db_name does not exist"
        return 1
    fi

    if [[ ! -d "$ODOO_HOME/odoo" ]]; then
        log_error "Odoo installation not found"
        return 1
    fi

    log_info "Running tests on database: $db_name"

    if [[ -f "$ODOO_HOME/venv/bin/activate" ]]; then
        source "$ODOO_HOME/venv/bin/activate"
    fi

    local odoo_cmd="python $ODOO_HOME/odoo/odoo-bin"
    local config_file="$ODOO_HOME/odoo.conf"

    if [[ -f "$config_file" ]]; then
        odoo_cmd="$odoo_cmd --config=$config_file"
    fi

    odoo_cmd="$odoo_cmd --database=$db_name --test-enable --stop-after-init"

    if [[ -n "$module" ]]; then
        odoo_cmd="$odoo_cmd --init=$module"
        log_info "Testing module: $module"
    fi

    if [[ -n "$test_tags" ]]; then
        odoo_cmd="$odoo_cmd --test-tags=$test_tags"
        log_info "Test tags: $test_tags"
    fi

    log_debug "Running: $odoo_cmd"

    local test_log="$LOGS_DIR/test-${db_name}-$(date +%Y%m%d_%H%M%S).log"

    if eval "$odoo_cmd" > "$test_log" 2>&1; then
        log_success "Tests completed successfully"
        log_info "Test log: $test_log"
    else
        log_error "Tests failed"
        log_error "Test log: $test_log"
        return 1
    fi
}

# Create isolated test environment
create_isolated_environment() {
    local name="$1"
    local modules="${2:-base}"

    log_info "Creating isolated test environment: $name"

    # Create main test database
    local test_db
    test_db=$(create_test_database "$name" "test" "$modules" "false" "false" "")

    if [[ -z "$test_db" ]]; then
        log_error "Failed to create test database"
        return 1
    fi

    # Create fixture database for the environment
    local fixture_db
    fixture_db=$(create_fixture_database "${name}_fixture" "$modules" "true")

    if [[ -z "$fixture_db" ]]; then
        log_warning "Failed to create fixture database, but test database created"
    fi

    # Create environment configuration
    local env_config="$ODOO_HOME/test-environments/${name}.json"
    mkdir -p "$(dirname "$env_config")"

    cat > "$env_config" << EOF
{
    "name": "$name",
    "test_database": "$test_db",
    "fixture_database": "$fixture_db",
    "modules": "$modules",
    "created": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "creator": "$(whoami)"
}
EOF

    log_success "Isolated test environment created:"
    log_info "  Test database: $test_db"
    log_info "  Fixture database: $fixture_db"
    log_info "  Configuration: $env_config"
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
                log_error "Test database name required"
                exit 1
            fi

            local name="$1"
            local modules="base"
            local demo_data="false"
            local empty="false"
            local copy_from=""
            local db_type="test"
            shift

            while [[ $# -gt 0 ]]; do
                case "$1" in
                    --modules)
                        modules="$2"
                        shift 2
                        ;;
                    --demo)
                        demo_data="true"
                        shift
                        ;;
                    --empty)
                        empty="true"
                        shift
                        ;;
                    --copy-from)
                        copy_from="$2"
                        shift 2
                        ;;
                    --type)
                        case "$2" in
                            unit|integration|functional|performance)
                                db_type="$2"
                                ;;
                            *)
                                log_error "Invalid test type: $2"
                                exit 1
                                ;;
                        esac
                        shift 2
                        ;;
                    *)
                        log_error "Unknown option: $1"
                        exit 1
                        ;;
                esac
            done

            create_test_database "$name" "$db_type" "$modules" "$demo_data" "$empty" "$copy_from"
            ;;
        create-fixture)
            if [[ $# -eq 0 ]]; then
                log_error "Fixture name required"
                exit 1
            fi

            local name="$1"
            local modules="base"
            local demo_data="true"
            shift

            while [[ $# -gt 0 ]]; do
                case "$1" in
                    --modules)
                        modules="$2"
                        shift 2
                        ;;
                    --no-demo)
                        demo_data="false"
                        shift
                        ;;
                    *)
                        log_error "Unknown option: $1"
                        exit 1
                        ;;
                esac
            done

            create_fixture_database "$name" "$modules" "$demo_data"
            ;;
        create-temp)
            local modules="base"
            local demo_data="false"
            local copy_from=""

            while [[ $# -gt 0 ]]; do
                case "$1" in
                    --modules)
                        modules="$2"
                        shift 2
                        ;;
                    --demo)
                        demo_data="true"
                        shift
                        ;;
                    --copy-from)
                        copy_from="$2"
                        shift 2
                        ;;
                    *)
                        log_error "Unknown option: $1"
                        exit 1
                        ;;
                esac
            done

            create_temp_database "$modules" "$demo_data" "$copy_from"
            ;;
        seed)
            if [[ $# -eq 0 ]]; then
                log_error "Database name required"
                exit 1
            fi

            local db_name="$1"
            local fixture_name=""
            local custom_data=""
            shift

            while [[ $# -gt 0 ]]; do
                case "$1" in
                    --fixture)
                        fixture_name="$2"
                        shift 2
                        ;;
                    --custom-data)
                        custom_data="$2"
                        shift 2
                        ;;
                    *)
                        log_error "Unknown option: $1"
                        exit 1
                        ;;
                esac
            done

            seed_database "$db_name" "$fixture_name" "$custom_data"
            ;;
        clone-for-test)
            if [[ $# -eq 0 ]]; then
                log_error "Source database required"
                exit 1
            fi

            local source_db="$1"
            local test_name="${2:-cloned_$(date +%s)}"

            clone_for_test "$source_db" "$test_name"
            ;;
        list)
            local type_filter=""

            while [[ $# -gt 0 ]]; do
                case "$1" in
                    --type)
                        type_filter="$2"
                        shift 2
                        ;;
                    *)
                        log_error "Unknown option: $1"
                        exit 1
                        ;;
                esac
            done

            list_test_databases "$type_filter"
            ;;
        clean)
            local age_days="1"
            local dry_run="false"

            while [[ $# -gt 0 ]]; do
                case "$1" in
                    --age)
                        age_days="$2"
                        shift 2
                        ;;
                    --dry-run)
                        dry_run="true"
                        shift
                        ;;
                    *)
                        log_error "Unknown option: $1"
                        exit 1
                        ;;
                esac
            done

            clean_test_databases "$age_days" "$dry_run"
            ;;
        reset)
            if [[ $# -eq 0 ]]; then
                log_error "Test database name required"
                exit 1
            fi

            reset_test_database "$1"
            ;;
        parallel-setup)
            if [[ $# -eq 0 ]]; then
                log_error "Database count required"
                exit 1
            fi

            local count="$1"
            local base_name="${2:-parallel_test}"
            local modules="${3:-base}"

            setup_parallel_tests "$count" "$base_name" "$modules"
            ;;
        run-test)
            if [[ $# -eq 0 ]]; then
                log_error "Database name required"
                exit 1
            fi

            local db_name="$1"
            local module="${2:-}"
            local test_tags="${3:-}"

            run_odoo_test "$db_name" "$module" "$test_tags"
            ;;
        isolate)
            if [[ $# -eq 0 ]]; then
                log_error "Environment name required"
                exit 1
            fi

            local name="$1"
            local modules="${2:-base}"

            create_isolated_environment "$name" "$modules"
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

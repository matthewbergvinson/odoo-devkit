#!/bin/bash

# RTP Denver - Docker Manager for Odoo Development
# Task 3.7: Create Docker alternative setup for environment consistency
#
# This script provides comprehensive Docker management that integrates
# with our existing infrastructure from Tasks 3.1-3.6
#
# Usage: ./scripts/docker-manager.sh [COMMAND] [OPTIONS]

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DOCKER_COMPOSE_FILE="$PROJECT_ROOT/docker-compose.yml"
ENV_TEMPLATE="$PROJECT_ROOT/docker-env-template"
ENV_FILE="$PROJECT_ROOT/.env"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Default configuration
DEFAULT_ENVIRONMENT="development"
DEFAULT_PROFILE="development"

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

# Show help message
show_help() {
    cat << EOF
RTP Denver - Docker Manager
===========================

A comprehensive Docker management script for Odoo development that integrates
with our existing infrastructure from Tasks 3.1-3.6.

Usage: $0 [COMMAND] [OPTIONS]

Commands:
  setup                 Initial Docker environment setup
  build                 Build Docker images
  up                    Start services
  down                  Stop services
  restart               Restart services
  logs                  View service logs
  shell                 Open shell in container
  exec                  Execute command in container
  db                    Database operations
  test                  Run tests in Docker
  clean                 Clean up Docker resources
  status                Show service status
  backup                Backup Docker volumes
  restore               Restore Docker volumes
  config                Show Docker configuration
  help                  Show this help message

Database Operations (db):
  create DB [MODULES]   Create new database
  drop DB               Drop database
  list                  List databases
  backup DB             Backup database
  restore DB FILE       Restore database from backup

Examples:
  # Initial setup
  $0 setup

  # Start development environment
  $0 up

  # Start with pgAdmin
  COMPOSE_PROFILES=development,pgadmin $0 up

  # View logs
  $0 logs odoo

  # Open shell in Odoo container
  $0 shell

  # Create database with custom modules
  $0 db create mydb rtp_customers,royal_textiles_sales

  # Run module installation tests
  $0 test module-install rtp_customers

  # Clean up everything
  $0 clean --all

Environment Variables:
  COMPOSE_PROFILES      Service profiles to enable (development, testing, pgadmin, redis, full)
  ENVIRONMENT          Odoo environment (development, testing, staging, production)
  DB_NAME              Database name for operations
  BACKUP_DIR           Directory for backups

EOF
}

# Check dependencies
check_dependencies() {
    local missing_deps=()

    if ! command -v docker >/dev/null 2>&1; then
        missing_deps+=("docker")
    fi

    if ! command -v docker-compose >/dev/null 2>&1 && ! docker compose version >/dev/null 2>&1; then
        missing_deps+=("docker-compose")
    fi

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Missing dependencies: ${missing_deps[*]}"
        log_info "Please install Docker and Docker Compose first"
        exit 1
    fi

    log_success "Docker dependencies found"
}

# Setup Docker environment
setup_docker_environment() {
    log_info "Setting up Docker environment..."

    # Check if .env file exists
    if [[ ! -f "$ENV_FILE" ]]; then
        log_info "Creating .env file from template..."
        cp "$ENV_TEMPLATE" "$ENV_FILE"
        log_success ".env file created from template"
        log_warning "Please review and customize .env file before continuing"
    else
        log_info ".env file already exists"
    fi

    # Create docker directories
    local docker_dirs=(
        "$PROJECT_ROOT/docker/postgres/init"
        "$PROJECT_ROOT/docker/pgadmin"
    )

    for dir in "${docker_dirs[@]}"; do
        mkdir -p "$dir"
    done

    # Create PostgreSQL initialization script
    cat > "$PROJECT_ROOT/docker/postgres/init/01-init.sql" << 'EOF'
-- RTP Denver - PostgreSQL Initialization for Docker
-- Enable required extensions for Odoo

-- Create extensions
CREATE EXTENSION IF NOT EXISTS unaccent;
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS btree_gist;

-- Performance optimizations
ALTER SYSTEM SET shared_buffers = '256MB';
ALTER SYSTEM SET effective_cache_size = '1GB';
ALTER SYSTEM SET maintenance_work_mem = '64MB';
ALTER SYSTEM SET checkpoint_completion_target = 0.9;
ALTER SYSTEM SET wal_buffers = '16MB';
ALTER SYSTEM SET default_statistics_target = 100;

SELECT pg_reload_conf();
EOF

    # Create pgAdmin configuration
    cat > "$PROJECT_ROOT/docker/pgadmin/servers.json" << 'EOF'
{
    "Servers": {
        "1": {
            "Name": "RTP Denver PostgreSQL",
            "Group": "Servers",
            "Host": "postgres",
            "Port": 5432,
            "MaintenanceDB": "postgres",
            "Username": "odoo",
            "PassFile": "/tmp/pgpassfile",
            "SSLMode": "prefer"
        }
    }
}
EOF

    log_success "Docker environment setup completed"
}

# Build Docker images
build_images() {
    local force_rebuild="${1:-false}"

    log_info "Building Docker images..."

    local build_args=()
    if [[ "$force_rebuild" == "true" ]]; then
        build_args+=("--no-cache")
    fi

    if docker compose build "${build_args[@]}"; then
        log_success "Docker images built successfully"
    else
        log_error "Failed to build Docker images"
        exit 1
    fi
}

# Start services
start_services() {
    local profile="${1:-$DEFAULT_PROFILE}"
    local detach="${2:-true}"

    log_info "Starting services with profile: $profile"

    local compose_args=()
    if [[ "$detach" == "true" ]]; then
        compose_args+=("-d")
    fi

    export COMPOSE_PROFILES="$profile"

    if docker compose up "${compose_args[@]}"; then
        log_success "Services started successfully"

        if [[ "$detach" == "true" ]]; then
            log_info "Services are running in the background"
            log_info "Access Odoo at: http://localhost:8069"
            log_info "Admin password: admin123"
        fi
    else
        log_error "Failed to start services"
        exit 1
    fi
}

# Stop services
stop_services() {
    local remove_volumes="${1:-false}"

    log_info "Stopping services..."

    local compose_args=()
    if [[ "$remove_volumes" == "true" ]]; then
        compose_args+=("-v")
    fi

    if docker compose down "${compose_args[@]}"; then
        log_success "Services stopped successfully"
    else
        log_error "Failed to stop services"
        exit 1
    fi
}

# View logs
view_logs() {
    local service="${1:-}"
    local follow="${2:-false}"

    local compose_args=()
    if [[ "$follow" == "true" ]]; then
        compose_args+=("-f")
    fi

    if [[ -n "$service" ]]; then
        compose_args+=("$service")
    fi

    docker compose logs "${compose_args[@]}"
}

# Open shell in container
open_shell() {
    local service="${1:-odoo}"
    local shell="${2:-bash}"

    log_info "Opening $shell shell in $service container..."

    if docker compose exec "$service" "$shell"; then
        log_success "Shell session ended"
    else
        log_error "Failed to open shell in $service container"
        exit 1
    fi
}

# Execute command in container
execute_command() {
    local service="$1"
    shift
    local command="$*"

    log_info "Executing command in $service: $command"

    docker compose exec "$service" $command
}

# Database operations
manage_database() {
    local operation="$1"
    shift

    case "$operation" in
        "create")
            if [[ $# -lt 1 ]]; then
                log_error "Database name required for create operation"
                exit 1
            fi
            local db_name="$1"
            local modules="${2:-base}"

            log_info "Creating database: $db_name with modules: $modules"
            docker compose exec odoo python /opt/odoo/odoo/odoo-bin \
                --config=/etc/odoo/odoo.conf \
                --database="$db_name" \
                --init="$modules" \
                --stop-after-init
            ;;
        "drop")
            if [[ $# -lt 1 ]]; then
                log_error "Database name required for drop operation"
                exit 1
            fi
            local db_name="$1"

            log_warning "Dropping database: $db_name"
            docker compose exec postgres dropdb -U odoo "$db_name"
            ;;
        "list")
            log_info "Listing databases:"
            docker compose exec postgres psql -U odoo -l
            ;;
        "backup")
            if [[ $# -lt 1 ]]; then
                log_error "Database name required for backup operation"
                exit 1
            fi
            local db_name="$1"
            local backup_file="${2:-${db_name}_$(date +%Y%m%d_%H%M%S).sql}"

            log_info "Backing up database: $db_name to $backup_file"
            docker compose exec postgres pg_dump -U odoo "$db_name" > "$backup_file"
            log_success "Database backed up to: $backup_file"
            ;;
        "restore")
            if [[ $# -lt 2 ]]; then
                log_error "Database name and backup file required for restore operation"
                exit 1
            fi
            local db_name="$1"
            local backup_file="$2"

            if [[ ! -f "$backup_file" ]]; then
                log_error "Backup file not found: $backup_file"
                exit 1
            fi

            log_info "Restoring database: $db_name from $backup_file"
            docker compose exec -T postgres psql -U odoo "$db_name" < "$backup_file"
            log_success "Database restored from: $backup_file"
            ;;
        *)
            log_error "Unknown database operation: $operation"
            exit 1
            ;;
    esac
}

# Run tests
run_tests() {
    local test_type="${1:-all}"
    shift
    local test_args="$*"

    log_info "Running tests: $test_type with args: $test_args"

    case "$test_type" in
        "module-install")
            if [[ -z "$test_args" ]]; then
                log_error "Module name required for module-install test"
                exit 1
            fi
            docker compose exec odoo bash /opt/odoo/scripts/test-module-installation.sh install "$test_args"
            ;;
        "module-upgrade")
            if [[ -z "$test_args" ]]; then
                log_error "Module name required for module-upgrade test"
                exit 1
            fi
            docker compose exec odoo bash /opt/odoo/scripts/test-module-installation.sh upgrade "$test_args"
            ;;
        "integration")
            docker compose exec odoo bash /opt/odoo/scripts/test-module-installation.sh integration
            ;;
        "sample-data")
            local scenario="${test_args:-development}"
            docker compose exec odoo bash /opt/odoo/scripts/generate-sample-data.sh create "$scenario"
            ;;
        "all")
            log_info "Running complete test suite..."
            docker compose exec odoo bash /opt/odoo/scripts/test-module-installation.sh full
            ;;
        *)
            log_error "Unknown test type: $test_type"
            exit 1
            ;;
    esac
}

# Clean up Docker resources
cleanup_docker() {
    local cleanup_level="${1:-standard}"

    case "$cleanup_level" in
        "light")
            log_info "Light cleanup - stopping services only"
            stop_services
            ;;
        "standard")
            log_info "Standard cleanup - removing containers and networks"
            stop_services
            docker compose rm -f
            ;;
        "full")
            log_info "Full cleanup - removing everything except volumes"
            stop_services
            docker compose rm -f
            docker system prune -f
            ;;
        "all")
            log_warning "Complete cleanup - WILL DELETE ALL DATA"
            read -p "Are you sure you want to delete all Docker data? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                stop_services true
                docker compose rm -f
                docker system prune -af --volumes
                log_success "Complete cleanup performed"
            else
                log_info "Cleanup cancelled"
            fi
            ;;
        *)
            log_error "Unknown cleanup level: $cleanup_level"
            exit 1
            ;;
    esac
}

# Show service status
show_status() {
    log_info "Docker service status:"
    echo ""

    if docker compose ps; then
        echo ""
        log_info "Service health:"
        docker compose exec odoo curl -f http://localhost:8069/web/health >/dev/null 2>&1 && \
            echo -e "${GREEN}✓${NC} Odoo is healthy" || \
            echo -e "${RED}✗${NC} Odoo is not responding"

        docker compose exec postgres pg_isready -U odoo >/dev/null 2>&1 && \
            echo -e "${GREEN}✓${NC} PostgreSQL is ready" || \
            echo -e "${RED}✗${NC} PostgreSQL is not ready"
    else
        log_warning "No services are running"
    fi
}

# Show Docker configuration
show_config() {
    log_info "Docker configuration:"
    echo ""

    if [[ -f "$ENV_FILE" ]]; then
        echo "Environment variables (.env):"
        cat "$ENV_FILE" | grep -v '^#' | grep -v '^$'
        echo ""
    fi

    echo "Docker Compose configuration:"
    docker compose config
}

# Backup Docker volumes
backup_volumes() {
    local backup_dir="${1:-./docker-backups}"
    local timestamp=$(date +%Y%m%d_%H%M%S)

    mkdir -p "$backup_dir"

    log_info "Backing up Docker volumes to: $backup_dir"

    # List of volumes to backup
    local volumes=(
        "rtp-denver-postgres-data"
        "rtp-denver-odoo-data"
        "rtp-denver-odoo-config"
    )

    for volume in "${volumes[@]}"; do
        local backup_file="$backup_dir/${volume}_${timestamp}.tar.gz"
        log_info "Backing up volume: $volume"

        docker run --rm \
            -v "$volume":/data \
            -v "$backup_dir":/backup \
            alpine tar -czf "/backup/$(basename "$backup_file")" -C /data .

        log_success "Volume backed up: $backup_file"
    done

    log_success "All volumes backed up to: $backup_dir"
}

# Restore Docker volumes
restore_volumes() {
    local backup_dir="${1:-./docker-backups}"

    if [[ ! -d "$backup_dir" ]]; then
        log_error "Backup directory not found: $backup_dir"
        exit 1
    fi

    log_warning "This will restore Docker volumes from backup"
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Restore cancelled"
        return
    fi

    log_info "Available backups in $backup_dir:"
    ls -la "$backup_dir"/*.tar.gz 2>/dev/null || {
        log_error "No backup files found in $backup_dir"
        exit 1
    }

    log_info "Restore functionality requires manual selection of backup files"
    log_info "Use: docker run --rm -v VOLUME:/data -v BACKUP_DIR:/backup alpine tar -xzf /backup/BACKUP_FILE -C /data"
}

# Parse command line arguments
parse_arguments() {
    if [[ $# -eq 0 ]]; then
        show_help
        exit 0
    fi

    local command="$1"
    shift

    case "$command" in
        "setup")
            check_dependencies
            setup_docker_environment
            ;;
        "build")
            check_dependencies
            build_images "${1:-false}"
            ;;
        "up")
            check_dependencies
            start_services "${1:-$DEFAULT_PROFILE}" "${2:-true}"
            ;;
        "down")
            stop_services "${1:-false}"
            ;;
        "restart")
            stop_services
            start_services "${1:-$DEFAULT_PROFILE}" "${2:-true}"
            ;;
        "logs")
            view_logs "${1:-}" "${2:-false}"
            ;;
        "shell")
            open_shell "${1:-odoo}" "${2:-bash}"
            ;;
        "exec")
            if [[ $# -lt 1 ]]; then
                log_error "Service name required for exec command"
                exit 1
            fi
            execute_command "$@"
            ;;
        "db")
            if [[ $# -lt 1 ]]; then
                log_error "Database operation required"
                exit 1
            fi
            manage_database "$@"
            ;;
        "test")
            run_tests "${1:-all}" "${@:2}"
            ;;
        "clean")
            cleanup_docker "${1:-standard}"
            ;;
        "status")
            show_status
            ;;
        "backup")
            backup_volumes "${1:-./docker-backups}"
            ;;
        "restore")
            restore_volumes "${1:-./docker-backups}"
            ;;
        "config")
            show_config
            ;;
        "help"|"--help")
            show_help
            ;;
        *)
            log_error "Unknown command: $command"
            show_help
            exit 1
            ;;
    esac
}

# Main function
main() {
    cd "$PROJECT_ROOT"
    parse_arguments "$@"
}

# Run main function
main "$@"

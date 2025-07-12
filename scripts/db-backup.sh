#!/bin/bash

# RTP Denver - Database Backup Utility for Odoo Development
# Task 3.3: Specialized backup management for test databases
#
# This script provides automated backup functionality with retention policies,
# compression options, and integration with the main database manager
#
# Usage: ./scripts/db-backup.sh [COMMAND] [OPTIONS]

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BACKUP_DIR="$PROJECT_ROOT/local-odoo/backups"
LOGS_DIR="$PROJECT_ROOT/local-odoo/logs"

# Backup configuration
DEFAULT_RETENTION_DAYS=30
DEFAULT_COMPRESSION=true
DB_USER="${ODOO_DB_USER:-$(whoami)}"
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Show help
show_help() {
    echo "RTP Denver - Database Backup Utility"
    echo "===================================="
    echo ""
    echo "Automated backup management for Odoo development databases"
    echo ""
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  backup DB_NAME [OPTIONS]         Create backup of specific database"
    echo "  backup-all [OPTIONS]             Backup all databases"
    echo "  list [--detailed]                List all backups"
    echo "  restore BACKUP_FILE DB_NAME      Restore database from backup"
    echo "  clean [--dry-run] [--days N]     Clean old backups (default: 30 days)"
    echo "  schedule [--enable|--disable]    Manage scheduled backups"
    echo "  verify BACKUP_FILE               Verify backup integrity"
    echo ""
    echo "Backup Options:"
    echo "  --compress                       Use compression (default)"
    echo "  --no-compress                    Don't use compression"
    echo "  --format FORMAT                  Backup format: custom, sql, tar (default: custom)"
    echo "  --exclude-tables TABLES          Exclude specific tables (comma-separated)"
    echo "  --schema-only                    Backup schema only, no data"
    echo "  --data-only                      Backup data only, no schema"
    echo ""
    echo "Examples:"
    echo "  $0 backup my_project                    # Backup single database"
    echo "  $0 backup-all --compress                # Backup all with compression"
    echo "  $0 restore backup_20241215.dump new_db # Restore backup"
    echo "  $0 clean --days 14                     # Clean backups older than 14 days"
    echo ""
}

# Logging functions
log_info() {
    echo -e "${BLUE}[BACKUP-INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') $1" | tee -a "$LOGS_DIR/backup.log"
}

log_success() {
    echo -e "${GREEN}[BACKUP-SUCCESS]${NC} $(date '+%Y-%m-%d %H:%M:%S') $1" | tee -a "$LOGS_DIR/backup.log"
}

log_warning() {
    echo -e "${YELLOW}[BACKUP-WARNING]${NC} $(date '+%Y-%m-%d %H:%M:%S') $1" | tee -a "$LOGS_DIR/backup.log"
}

log_error() {
    echo -e "${RED}[BACKUP-ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') $1" | tee -a "$LOGS_DIR/backup.log"
}

# Initialize
init_backup_system() {
    mkdir -p "$BACKUP_DIR" "$LOGS_DIR"
    touch "$LOGS_DIR/backup.log"
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
        SELECT pg_database_size('$db_name');
    " 2>/dev/null || echo "0"
}

# Create backup
create_backup() {
    local db_name="$1"
    local compress="${2:-true}"
    local format="${3:-custom}"
    local exclude_tables="${4:-}"
    local schema_only="${5:-false}"
    local data_only="${6:-false}"

    if ! database_exists "$db_name"; then
        log_error "Database $db_name does not exist"
        return 1
    fi

    local timestamp
    timestamp=$(date '+%Y%m%d_%H%M%S')

    local backup_file="$BACKUP_DIR/${db_name}_${timestamp}"
    local pg_dump_cmd="pg_dump -h $DB_HOST -p $DB_PORT -U $DB_USER"

    # Set format and extension
    case "$format" in
        custom)
            backup_file="${backup_file}.dump"
            pg_dump_cmd="$pg_dump_cmd -Fc"
            ;;
        sql)
            backup_file="${backup_file}.sql"
            if [[ "$compress" == "true" ]]; then
                backup_file="${backup_file}.gz"
            fi
            ;;
        tar)
            backup_file="${backup_file}.tar"
            pg_dump_cmd="$pg_dump_cmd -Ft"
            if [[ "$compress" == "true" ]]; then
                backup_file="${backup_file}.gz"
            fi
            ;;
    esac

    # Add options
    if [[ "$schema_only" == "true" ]]; then
        pg_dump_cmd="$pg_dump_cmd --schema-only"
    elif [[ "$data_only" == "true" ]]; then
        pg_dump_cmd="$pg_dump_cmd --data-only"
    fi

    # Add exclude tables
    if [[ -n "$exclude_tables" ]]; then
        IFS=',' read -ra TABLES <<< "$exclude_tables"
        for table in "${TABLES[@]}"; do
            pg_dump_cmd="$pg_dump_cmd --exclude-table=$table"
        done
    fi

    pg_dump_cmd="$pg_dump_cmd $db_name"

    log_info "Creating backup of $db_name..."
    log_info "  Format: $format"
    log_info "  Compress: $compress"
    log_info "  Size: $(numfmt --to=iec $(get_database_size "$db_name"))"

    local start_time
    start_time=$(date +%s)

    # Execute backup
    if [[ "$format" == "sql" && "$compress" == "true" ]]; then
        if eval "$pg_dump_cmd | gzip > $backup_file"; then
            local success=true
        else
            local success=false
        fi
    elif [[ "$format" == "tar" && "$compress" == "true" ]]; then
        if eval "$pg_dump_cmd | gzip > $backup_file"; then
            local success=true
        else
            local success=false
        fi
    else
        if eval "$pg_dump_cmd > $backup_file"; then
            local success=true
        else
            local success=false
        fi
    fi

    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))

    if [[ "$success" == "true" ]]; then
        local backup_size
        backup_size=$(ls -lh "$backup_file" | awk '{print $5}')

        log_success "Backup created: $(basename "$backup_file")"
        log_info "  Duration: ${duration}s"
        log_info "  Size: $backup_size"
        log_info "  Path: $backup_file"

        # Create backup metadata
        cat > "${backup_file}.meta" << EOF
{
    "database": "$db_name",
    "timestamp": "$timestamp",
    "format": "$format",
    "compressed": $compress,
    "schema_only": $schema_only,
    "data_only": $data_only,
    "duration_seconds": $duration,
    "original_size": $(get_database_size "$db_name"),
    "backup_size": $(stat -f%z "$backup_file" 2>/dev/null || stat -c%s "$backup_file"),
    "exclude_tables": "$exclude_tables"
}
EOF

        echo "$backup_file"
    else
        log_error "Failed to create backup"
        [[ -f "$backup_file" ]] && rm -f "$backup_file"
        return 1
    fi
}

# Backup all databases
backup_all_databases() {
    local compress="${1:-true}"
    local format="${2:-custom}"
    local exclude_pattern="${3:-^(template|postgres)}"

    log_info "Starting backup of all databases..."

    local total_count=0
    local success_count=0
    local total_size=0

    while IFS='|' read -r dbname; do
        dbname=$(echo "$dbname" | xargs)

        if [[ -n "$dbname" && ! "$dbname" =~ $exclude_pattern ]]; then
            ((total_count++))

            log_info "Backing up database: $dbname"

            if create_backup "$dbname" "$compress" "$format" "" "false" "false" >/dev/null; then
                ((success_count++))
                total_size=$((total_size + $(get_database_size "$dbname")))
            fi
        fi
    done < <(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -lqt | cut -d \| -f 1)

    log_success "Backup completed: $success_count/$total_count databases"
    log_info "Total data backed up: $(numfmt --to=iec $total_size)"
}

# List backups
list_backups() {
    local detailed="${1:-false}"

    log_info "Available backups:"

    if [[ "$detailed" == "true" ]]; then
        echo -e "\n${BLUE}Backup File${NC} | ${BLUE}Database${NC} | ${BLUE}Date${NC} | ${BLUE}Size${NC} | ${BLUE}Format${NC}"
        echo "----------------------------------------------------------------"
    else
        echo -e "\n${BLUE}Backup File${NC} | ${BLUE}Database${NC} | ${BLUE}Date${NC} | ${BLUE}Size${NC}"
        echo "------------------------------------------------"
    fi

    local backup_count=0
    local total_size=0

    for backup_file in "$BACKUP_DIR"/*.{dump,sql,tar}{,.gz}; do
        if [[ -f "$backup_file" ]]; then
            local basename_file
            basename_file=$(basename "$backup_file")

            local db_name=""
            local timestamp=""
            local format=""

            # Extract info from filename or metadata
            if [[ -f "${backup_file}.meta" ]]; then
                db_name=$(jq -r '.database' "${backup_file}.meta" 2>/dev/null || echo "unknown")
                timestamp=$(jq -r '.timestamp' "${backup_file}.meta" 2>/dev/null || echo "unknown")
                format=$(jq -r '.format' "${backup_file}.meta" 2>/dev/null || echo "unknown")
            else
                # Parse from filename
                if [[ "$basename_file" =~ ^(.+)_([0-9]{8}_[0-9]{6})\.(dump|sql|tar)(\.gz)?$ ]]; then
                    db_name="${BASH_REMATCH[1]}"
                    timestamp="${BASH_REMATCH[2]}"
                    format="${BASH_REMATCH[3]}"
                fi
            fi

            local file_size
            file_size=$(ls -lh "$backup_file" | awk '{print $5}')

            local file_size_bytes
            file_size_bytes=$(stat -f%z "$backup_file" 2>/dev/null || stat -c%s "$backup_file")
            total_size=$((total_size + file_size_bytes))

            # Format timestamp for display
            local display_date=""
            if [[ "$timestamp" =~ ^([0-9]{4})([0-9]{2})([0-9]{2})_([0-9]{2})([0-9]{2})([0-9]{2})$ ]]; then
                display_date="${BASH_REMATCH[1]}-${BASH_REMATCH[2]}-${BASH_REMATCH[3]} ${BASH_REMATCH[4]}:${BASH_REMATCH[5]}:${BASH_REMATCH[6]}"
            else
                display_date="$timestamp"
            fi

            if [[ "$detailed" == "true" ]]; then
                printf "%-25s | %-12s | %-19s | %-8s | %s\n" "$basename_file" "$db_name" "$display_date" "$file_size" "$format"
            else
                printf "%-25s | %-12s | %-19s | %s\n" "$basename_file" "$db_name" "$display_date" "$file_size"
            fi

            ((backup_count++))
        fi
    done

    echo ""
    log_info "Total backups: $backup_count"
    log_info "Total size: $(numfmt --to=iec $total_size)"
}

# Restore backup
restore_backup() {
    local backup_file="$1"
    local target_db="$2"
    local force="${3:-false}"

    # Handle relative paths
    if [[ ! -f "$backup_file" ]]; then
        backup_file="$BACKUP_DIR/$backup_file"
    fi

    if [[ ! -f "$backup_file" ]]; then
        log_error "Backup file not found: $backup_file"
        return 1
    fi

    log_info "Restoring database $target_db from: $(basename "$backup_file")"

    # Check if target database exists
    if database_exists "$target_db"; then
        if [[ "$force" != "true" ]]; then
            log_error "Database $target_db already exists. Use --force to overwrite."
            return 1
        else
            log_warning "Dropping existing database $target_db"
            dropdb -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" "$target_db"
        fi
    fi

    # Create target database
    if ! createdb -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" "$target_db"; then
        log_error "Failed to create target database"
        return 1
    fi

    local start_time
    start_time=$(date +%s)

    # Determine restore method based on file extension
    if [[ "$backup_file" == *.dump ]]; then
        log_info "Restoring from custom format backup..."
        if pg_restore -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$target_db" "$backup_file"; then
            local success=true
        else
            local success=false
        fi
    elif [[ "$backup_file" == *.sql.gz ]]; then
        log_info "Restoring from compressed SQL backup..."
        if gunzip -c "$backup_file" | psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$target_db" >/dev/null; then
            local success=true
        else
            local success=false
        fi
    elif [[ "$backup_file" == *.sql ]]; then
        log_info "Restoring from SQL backup..."
        if psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$target_db" < "$backup_file" >/dev/null; then
            local success=true
        else
            local success=false
        fi
    elif [[ "$backup_file" == *.tar.gz ]]; then
        log_info "Restoring from compressed tar backup..."
        if gunzip -c "$backup_file" | pg_restore -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$target_db"; then
            local success=true
        else
            local success=false
        fi
    else
        log_error "Unknown backup format: $backup_file"
        return 1
    fi

    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))

    if [[ "$success" == "true" ]]; then
        log_success "Database restored successfully"
        log_info "  Duration: ${duration}s"
        log_info "  Size: $(numfmt --to=iec $(get_database_size "$target_db"))"
    else
        log_error "Failed to restore database"
        dropdb -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" "$target_db" 2>/dev/null || true
        return 1
    fi
}

# Clean old backups
clean_old_backups() {
    local dry_run="${1:-false}"
    local retention_days="${2:-$DEFAULT_RETENTION_DAYS}"

    log_info "Cleaning backups older than $retention_days days (dry-run: $dry_run)"

    local count=0
    local total_size=0

    find "$BACKUP_DIR" -name "*.dump" -o -name "*.sql" -o -name "*.tar" -o -name "*.sql.gz" -o -name "*.tar.gz" | while read -r backup_file; do
        if [[ -f "$backup_file" ]]; then
            local file_age_days
            file_age_days=$(find "$backup_file" -mtime +$retention_days | wc -l)

            if [[ "$file_age_days" -gt 0 ]]; then
                local file_size
                file_size=$(stat -f%z "$backup_file" 2>/dev/null || stat -c%s "$backup_file")

                log_info "  $(basename "$backup_file") ($(numfmt --to=iec $file_size))"

                if [[ "$dry_run" != "true" ]]; then
                    rm -f "$backup_file" "${backup_file}.meta"
                fi

                ((count++))
                ((total_size += file_size))
            fi
        fi
    done

    if [[ "$dry_run" == "true" ]]; then
        log_info "Would clean $count backups ($(numfmt --to=iec $total_size))"
    else
        log_success "Cleaned $count backups ($(numfmt --to=iec $total_size))"
    fi
}

# Verify backup integrity
verify_backup() {
    local backup_file="$1"

    if [[ ! -f "$backup_file" ]]; then
        backup_file="$BACKUP_DIR/$backup_file"
    fi

    if [[ ! -f "$backup_file" ]]; then
        log_error "Backup file not found: $backup_file"
        return 1
    fi

    log_info "Verifying backup: $(basename "$backup_file")"

    # Create temporary database for verification
    local temp_db="verify_$(date +%s)"

    if createdb -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" "$temp_db" >/dev/null 2>&1; then
        log_info "Created temporary database: $temp_db"

        # Try to restore backup
        if restore_backup "$backup_file" "$temp_db" "true" >/dev/null 2>&1; then
            log_success "Backup verification successful"

            # Get some stats
            local table_count
            table_count=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$temp_db" -tAc "
                SELECT count(*) FROM information_schema.tables
                WHERE table_schema = 'public';
            " 2>/dev/null || echo "0")

            log_info "  Tables: $table_count"
            log_info "  Size: $(numfmt --to=iec $(get_database_size "$temp_db"))"
        else
            log_error "Backup verification failed - restore unsuccessful"
        fi

        # Clean up
        dropdb -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" "$temp_db" >/dev/null 2>&1
    else
        log_error "Failed to create temporary database for verification"
        return 1
    fi
}

# Main function
main() {
    init_backup_system

    if [[ $# -eq 0 ]]; then
        show_help
        exit 0
    fi

    local command="$1"
    shift

    case "$command" in
        backup)
            if [[ $# -eq 0 ]]; then
                log_error "Database name required"
                exit 1
            fi

            local db_name="$1"
            local compress="true"
            local format="custom"
            local exclude_tables=""
            local schema_only="false"
            local data_only="false"
            shift

            while [[ $# -gt 0 ]]; do
                case "$1" in
                    --compress)
                        compress="true"
                        shift
                        ;;
                    --no-compress)
                        compress="false"
                        shift
                        ;;
                    --format)
                        format="$2"
                        shift 2
                        ;;
                    --exclude-tables)
                        exclude_tables="$2"
                        shift 2
                        ;;
                    --schema-only)
                        schema_only="true"
                        shift
                        ;;
                    --data-only)
                        data_only="true"
                        shift
                        ;;
                    *)
                        log_error "Unknown option: $1"
                        exit 1
                        ;;
                esac
            done

            create_backup "$db_name" "$compress" "$format" "$exclude_tables" "$schema_only" "$data_only"
            ;;
        backup-all)
            local compress="true"
            local format="custom"
            local exclude_pattern="^(template|postgres)"

            while [[ $# -gt 0 ]]; do
                case "$1" in
                    --compress)
                        compress="true"
                        shift
                        ;;
                    --no-compress)
                        compress="false"
                        shift
                        ;;
                    --format)
                        format="$2"
                        shift 2
                        ;;
                    --exclude-pattern)
                        exclude_pattern="$2"
                        shift 2
                        ;;
                    *)
                        log_error "Unknown option: $1"
                        exit 1
                        ;;
                esac
            done

            backup_all_databases "$compress" "$format" "$exclude_pattern"
            ;;
        list)
            local detailed="false"

            while [[ $# -gt 0 ]]; do
                case "$1" in
                    --detailed)
                        detailed="true"
                        shift
                        ;;
                    *)
                        log_error "Unknown option: $1"
                        exit 1
                        ;;
                esac
            done

            list_backups "$detailed"
            ;;
        restore)
            if [[ $# -lt 2 ]]; then
                log_error "Backup file and target database name required"
                exit 1
            fi

            local backup_file="$1"
            local target_db="$2"
            local force="false"
            shift 2

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

            restore_backup "$backup_file" "$target_db" "$force"
            ;;
        clean)
            local dry_run="false"
            local retention_days="$DEFAULT_RETENTION_DAYS"

            while [[ $# -gt 0 ]]; do
                case "$1" in
                    --dry-run)
                        dry_run="true"
                        shift
                        ;;
                    --days)
                        retention_days="$2"
                        shift 2
                        ;;
                    *)
                        log_error "Unknown option: $1"
                        exit 1
                        ;;
                esac
            done

            clean_old_backups "$dry_run" "$retention_days"
            ;;
        verify)
            if [[ $# -eq 0 ]]; then
                log_error "Backup file required"
                exit 1
            fi

            verify_backup "$1"
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

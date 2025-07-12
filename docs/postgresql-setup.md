# PostgreSQL Setup for Odoo Development

This guide covers the PostgreSQL setup and database management system for RTP Denver's Odoo 18.0 development environment.

## Quick Start

### 1. Full PostgreSQL Setup

```bash
# Complete PostgreSQL setup (user, config, databases)
make setup-postgresql

# OR run script directly
./scripts/setup-postgresql.sh
```

### 2. Test Database Connection

```bash
# List all databases
make list-dbs

# Test connection
psql -U $(whoami) -d odoo_dev -c '\l'
```

## PostgreSQL Setup Components

### 1. User Management

The setup creates an Odoo-specific database user with proper permissions:

```bash
# Create user with Odoo permissions
make setup-postgresql-user

# OR with custom username
ODOO_DB_USER=odoo make setup-postgresql-user
```

**User Permissions:**
- `CREATEDB` - Can create new databases
- `LOGIN` - Can connect to PostgreSQL
- `SUPERUSER` - Can create extensions (needed for unaccent, pg_trgm, etc.)

### 2. PostgreSQL Configuration

Optimizes PostgreSQL settings for Odoo development:

```bash
# Configure PostgreSQL for Odoo
make setup-postgresql-config
```

**Configuration Optimizations:**
- **Memory Settings**: Optimized for development workloads
- **Connection Limits**: Appropriate for local development
- **Query Optimization**: Better performance for Odoo queries
- **Logging**: Helpful for debugging (slow query detection)
- **Locale Settings**: UTF-8 support for international data
- **Extensions**: Pre-loads necessary PostgreSQL extensions

### 3. Development Databases

Creates standard development databases:

```bash
# Create development databases
make setup-postgresql-dbs
```

**Default Databases:**
- `odoo_dev` - Main development database
- `odoo_test` - Testing database (isolated from development)
- `odoo_staging` - Staging/demo database

Each database includes essential extensions:
- `unaccent` - Accent-insensitive searches
- `pg_trgm` - Trigram matching for fuzzy searches
- `btree_gist` - Enhanced indexing for Odoo

## Database Management Commands

### Makefile Commands

```bash
# PostgreSQL setup commands
make setup-postgresql              # Full setup
make setup-postgresql-user         # User creation only
make setup-postgresql-config       # Configuration only
make setup-postgresql-dbs          # Development databases only
make reset-postgresql              # Reset everything (DESTRUCTIVE)

# Database operations
make create-db DB=my_project       # Create specific database
make drop-db DB=my_project         # Drop specific database
make reset-db DB=my_project        # Reset specific database
make list-dbs                      # List all databases
```

### Direct Script Usage

```bash
# Full setup with custom user
ODOO_DB_USER=odoo ./scripts/setup-postgresql.sh

# Individual operations
./scripts/setup-postgresql.sh --create-user
./scripts/setup-postgresql.sh --setup-config
./scripts/setup-postgresql.sh --create-dbs

# Reset all configuration
./scripts/setup-postgresql.sh --reset-all
```

## Advanced Database Operations

### Manual Database Creation

```bash
# Create database with specific encoding
createdb -U $(whoami) -E UTF8 -T template0 my_custom_db

# Create database with owner
createdb -U $(whoami) -O odoo_user my_project_db

# Create database with extensions
psql -U $(whoami) -d my_project_db -c "
    CREATE EXTENSION IF NOT EXISTS unaccent;
    CREATE EXTENSION IF NOT EXISTS pg_trgm;
    CREATE EXTENSION IF NOT EXISTS btree_gist;
"
```

### Database Backup and Restore

```bash
# Backup database
pg_dump -U $(whoami) my_project_db > backups/my_project_$(date +%Y%m%d).sql

# Backup with custom format (faster restore)
pg_dump -U $(whoami) -Fc my_project_db > backups/my_project_$(date +%Y%m%d).dump

# Restore SQL backup
createdb -U $(whoami) my_project_restored
psql -U $(whoami) my_project_restored < backups/my_project_20241215.sql

# Restore custom format
pg_restore -U $(whoami) -d my_project_restored backups/my_project_20241215.dump
```

### Performance Monitoring

```bash
# View active connections
psql -U $(whoami) -c "
    SELECT datname, usename, application_name, state, query_start, query
    FROM pg_stat_activity
    WHERE state = 'active';
"

# Check database sizes
psql -U $(whoami) -c "
    SELECT datname, pg_size_pretty(pg_database_size(datname)) as size
    FROM pg_database
    ORDER BY pg_database_size(datname) DESC;
"

# View slow queries (if logging enabled)
psql -U $(whoami) -c "
    SELECT query, mean_exec_time, calls, total_exec_time
    FROM pg_stat_statements
    ORDER BY mean_exec_time DESC
    LIMIT 10;
"
```

## Configuration Details

### PostgreSQL Settings (postgresql.conf)

Our setup adds these optimizations:

```ini
# Connection settings
max_connections = 100
shared_buffers = 256MB
effective_cache_size = 1GB

# Query optimization
work_mem = 4MB
maintenance_work_mem = 64MB
checkpoint_completion_target = 0.9

# Logging for development
log_min_duration_statement = 1000  # Log queries > 1 second
log_statement = 'none'             # Change to 'all' for debugging

# Odoo-specific settings
default_text_search_config = 'pg_catalog.english'
shared_preload_libraries = 'pg_stat_statements'
```

### Authentication (pg_hba.conf)

For development convenience, we use trust authentication:

```
# Trust authentication for development (LOCAL ONLY)
host    all    your_username    127.0.0.1/32    trust
```

⚠️ **Security Note**: This is for development only. Production environments should use proper authentication.

## Troubleshooting

### Common Issues

1. **PostgreSQL not running**
   ```bash
   # macOS
   brew services start postgresql@14

   # Linux
   sudo systemctl start postgresql
   ```

2. **Connection refused**
   ```bash
   # Check if PostgreSQL is running
   pg_isready

   # Check configuration
   psql -U $(whoami) -c "SHOW config_file;"
   ```

3. **Permission denied**
   ```bash
   # Reset user permissions
   make setup-postgresql-user

   # Or manually
   psql -U postgres -c "ALTER USER $(whoami) WITH SUPERUSER;"
   ```

4. **Database does not exist**
   ```bash
   # Create missing database
   make create-db DB=odoo_dev

   # Or recreate development databases
   make setup-postgresql-dbs
   ```

5. **Extensions not found**
   ```bash
   # Install PostgreSQL extensions
   # macOS
   brew install postgresql@14

   # Ubuntu/Debian
   sudo apt-get install postgresql-14-contrib
   ```

### Reset and Recovery

If PostgreSQL setup is corrupted:

```bash
# Full reset (DESTRUCTIVE - removes all data)
make reset-postgresql

# Then re-setup
make setup-postgresql
```

### Manual Recovery

1. **Backup your data first!**
2. Stop PostgreSQL
3. Restore configuration from backups
4. Restart PostgreSQL
5. Re-run setup if needed

## Integration with Odoo

### Odoo Configuration

The PostgreSQL setup automatically configures Odoo's database settings in `local-odoo/odoo.conf`:

```ini
[options]
# Database configuration
db_host = localhost
db_port = 5432
db_user = your_username
db_password = False  # No password for development
```

### Development Workflow

```bash
# 1. Setup PostgreSQL
make setup-postgresql

# 2. Create project database
make create-db DB=my_project

# 3. Start Odoo
make start-odoo

# 4. Access Odoo at http://localhost:8069
# 5. Create database through Odoo web interface
```

### Testing Workflow

```bash
# Use separate test database
make create-db DB=test_project

# Run tests with specific database
python local-odoo/odoo/odoo-bin \
    --config=local-odoo/odoo.conf \
    --database=test_project \
    --test-enable \
    --stop-after-init
```

## Production Considerations

While this setup is optimized for development, key differences for production:

1. **Authentication**: Use password/certificate authentication
2. **Memory**: Increase shared_buffers to 25% of RAM
3. **Connections**: Tune max_connections for your workload
4. **Logging**: Reduce logging overhead
5. **Backup**: Implement automated backup strategy
6. **Security**: Restrict network access, use SSL

## Notes

- This setup matches odoo.sh PostgreSQL configuration
- All validation tools work with this PostgreSQL setup
- Development databases are isolated for safe testing
- Configuration is backed up before changes
- Extensions required by Odoo are pre-installed
- Optimized for development, not production use

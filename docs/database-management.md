# Database Management Guide - Task 3.3

## Overview

Task 3.3 provides comprehensive database management tools for Odoo development, including advanced database operations, test database management, and backup/restore functionality. These tools go beyond basic database operations to provide a complete database management ecosystem.

## 🚀 Quick Start

### Create a Development Database
```bash
make db-create NAME=my_project TYPE=dev MODULES=base,sale
```

### Create a Test Database
```bash
make test-db-create NAME=unit_tests TYPE=unit
```

### Backup a Database
```bash
make backup-create NAME=my_project COMPRESS=true
```

### List All Databases
```bash
make db-list
```

## 📊 Database Management Scripts

### 1. Main Database Manager (`scripts/db-manager.sh`)

The primary tool for comprehensive database management with advanced features:

#### Key Features:
- **Smart Database Naming**: Automatic prefixing based on database type
- **Safety Features**: Confirmation prompts and connection checks
- **Logging**: Comprehensive logging with timestamps
- **Metadata Tracking**: Database creation info and purpose
- **Odoo Integration**: Automatic Odoo initialization

#### Usage Examples:

```bash
# Create different types of databases
./scripts/db-manager.sh create my_project --type dev --modules base,sale
./scripts/db-manager.sh create test_sales --type test --demo
./scripts/db-manager.sh create staging_app --type staging

# Clone databases
./scripts/db-manager.sh clone production_db test_copy

# Get detailed information
./scripts/db-manager.sh info my_project
./scripts/db-manager.sh list --pattern "test_*"

# Safe database operations
./scripts/db-manager.sh drop test_db  # Requires confirmation
./scripts/db-manager.sh drop test_db --force  # Skip confirmation
```

### 2. Test Database Manager (`scripts/db-test-manager.sh`)

Specialized tool for test database management with isolation and parallel testing support:

#### Key Features:
- **Test Isolation**: Separate test environments
- **Fixture Management**: Reusable test data sets
- **Parallel Testing**: Multiple test databases
- **Test Data Seeding**: Automated test data setup
- **Cleanup Automation**: Age-based cleanup

#### Usage Examples:

```bash
# Create test databases
./scripts/db-test-manager.sh create unit_tests --type unit --modules base
./scripts/db-test-manager.sh create integration_tests --type integration --demo

# Create fixtures for reusable test data
./scripts/db-test-manager.sh create-fixture base_data --modules base,sale --demo

# Seed test database with fixture data
./scripts/db-test-manager.sh seed test_sales --fixture base_data

# Setup parallel testing
./scripts/db-test-manager.sh parallel-setup 4 my_tests

# Run Odoo tests
./scripts/db-test-manager.sh run-test test_sales sale
```

### 3. Backup Manager (`scripts/db-backup.sh`)

Advanced backup and restore system with compression, verification, and retention policies:

#### Key Features:
- **Multiple Formats**: Custom, SQL, TAR formats
- **Compression**: Automatic compression support
- **Metadata**: Backup metadata tracking
- **Verification**: Backup integrity checking
- **Retention**: Automated cleanup of old backups

#### Usage Examples:

```bash
# Create backups
./scripts/db-backup.sh backup my_project --compress --format custom
./scripts/db-backup.sh backup-all --format sql --compress

# List and manage backups
./scripts/db-backup.sh list --detailed
./scripts/db-backup.sh verify my_project_20241215_143022.dump

# Restore databases
./scripts/db-backup.sh restore my_project_20241215_143022.dump restored_db

# Cleanup old backups
./scripts/db-backup.sh clean --days 14 --dry-run
```

## 🛠️ Makefile Integration

All database management tools are integrated into the Makefile for easy access:

### Main Database Operations

| Command | Description | Example |
|---------|-------------|---------|
| `make db-create` | Create new database | `make db-create NAME=mydb TYPE=dev` |
| `make db-drop` | Drop database | `make db-drop NAME=mydb FORCE=true` |
| `make db-reset` | Reset database | `make db-reset NAME=mydb` |
| `make db-clone` | Clone database | `make db-clone SOURCE=prod TARGET=test` |
| `make db-list` | List databases | `make db-list PATTERN="test_*"` |
| `make db-info` | Database details | `make db-info NAME=mydb` |

### Test Database Management

| Command | Description | Example |
|---------|-------------|---------|
| `make test-db-create` | Create test database | `make test-db-create NAME=unit_tests TYPE=unit` |
| `make test-db-fixture` | Create fixture | `make test-db-fixture NAME=base_data MODULES=base,sale` |
| `make test-db-list` | List test databases | `make test-db-list TYPE=unit` |
| `make test-db-clean` | Clean test databases | `make test-db-clean AGE=1` |
| `make test-db-parallel` | Setup parallel tests | `make test-db-parallel COUNT=4` |
| `make test-db-run` | Run Odoo tests | `make test-db-run NAME=test_sales MODULE=sale` |

### Backup Management

| Command | Description | Example |
|---------|-------------|---------|
| `make backup-create` | Create backup | `make backup-create NAME=mydb FORMAT=custom` |
| `make backup-all` | Backup all databases | `make backup-all COMPRESS=true` |
| `make backup-list` | List backups | `make backup-list DETAILED=true` |
| `make backup-restore` | Restore backup | `make backup-restore BACKUP=file.dump NAME=mydb` |
| `make backup-clean` | Clean old backups | `make backup-clean DAYS=30` |
| `make backup-verify` | Verify backup | `make backup-verify BACKUP=file.dump` |

## 📁 Database Types and Naming

### Database Types

The system supports different database types with automatic naming:

- **Development (`dev`)**: `dev_myproject` or `myproject` for main DBs
- **Test (`test`)**: `test_myproject`
- **Staging (`staging`)**: `staging_myproject`
- **Fixture (`fixture`)**: `fixture_mydata`
- **Temporary (`temp`)**: `temp_test_12345678_1234`

### Default Databases

When PostgreSQL is set up, these default databases are created:
- `odoo_dev` - Main development database
- `odoo_test` - Main test database
- `odoo_staging` - Staging database

## 🔧 Advanced Features

### 1. Test Environment Isolation

Create completely isolated test environments:

```bash
# Create isolated environment with test and fixture databases
./scripts/db-test-manager.sh isolate my_feature base,sale

# This creates:
# - test_my_feature (main test database)
# - fixture_my_feature_fixture (fixture database)
# - Environment configuration file
```

### 2. Parallel Test Support

Setup multiple test databases for parallel testing:

```bash
# Create 4 parallel test databases
make test-db-parallel COUNT=4 BASE=parallel_test

# This creates:
# - test_parallel_test_1
# - test_parallel_test_2
# - test_parallel_test_3
# - test_parallel_test_4
# - Configuration file for test runners
```

### 3. Database Cloning and Templates

Clone databases for testing without affecting originals:

```bash
# Clone production database for testing
make db-clone SOURCE=odoo_dev TARGET=test_copy

# Create database from template
./scripts/db-manager.sh create new_db --from-template base_template
```

### 4. Backup Verification and Metadata

All backups include metadata and can be verified:

```bash
# Backup with metadata
make backup-create NAME=my_project COMPRESS=true

# This creates:
# - my_project_20241215_143022.dump (backup file)
# - my_project_20241215_143022.dump.meta (metadata JSON)

# Verify backup integrity
make backup-verify BACKUP=my_project_20241215_143022.dump
```

## 📋 Configuration and Environment Variables

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `ODOO_DB_USER` | Database username | Current user |
| `DB_HOST` | Database host | localhost |
| `DB_PORT` | Database port | 5432 |
| `DEBUG` | Enable debug logging | 0 |

### Configuration Files

The scripts create various configuration files:

- `local-odoo/test-metadata/` - Test database metadata
- `local-odoo/test-environments/` - Test environment configs
- `local-odoo/parallel-test-config.json` - Parallel test setup
- `local-odoo/logs/` - All operation logs

## 🚦 Safety Features

### 1. Confirmation Prompts

Operations that could cause data loss require confirmation:

```bash
# Dropping databases requires confirmation unless --force is used
make db-drop NAME=important_db
# Prompts: "Are you sure you want to continue? (y/N)"

# Skip confirmation with FORCE
make db-drop NAME=test_db FORCE=true
```

### 2. Connection Checks

Before dropping databases, the system checks for active connections:

```bash
# Warns about active connections
WARNING: Database mydb has 3 active connections
Cannot drop database with active connections. Use --force to terminate them.
```

### 3. Dry Run Support

Many operations support dry run mode:

```bash
# Preview what would be cleaned up
make db-clean DRY_RUN=true
make backup-clean DRY_RUN=true DAYS=14
```

## 📊 Logging and Monitoring

### Log Files

All operations are logged with timestamps:

- `local-odoo/logs/db-manager.log` - Main database operations
- `local-odoo/logs/test-db.log` - Test database operations
- `local-odoo/logs/backup.log` - Backup/restore operations
- `local-odoo/logs/test-{database}-{timestamp}.log` - Individual test runs

### Log Levels

- **INFO**: General operation information
- **SUCCESS**: Successful completions
- **WARNING**: Non-fatal issues
- **ERROR**: Operation failures
- **DEBUG**: Detailed operation info (when DEBUG=1)

## 🔍 Troubleshooting

### Common Issues

1. **Permission Errors**
   ```bash
   # Ensure scripts are executable
   chmod +x scripts/db-*.sh

   # Check PostgreSQL permissions
   make postgres-status
   ```

2. **Database Connection Issues**
   ```bash
   # Check PostgreSQL is running
   make postgres-status

   # Verify environment variables
   echo $ODOO_DB_USER $DB_HOST $DB_PORT
   ```

3. **Odoo Initialization Failures**
   ```bash
   # Check Odoo installation
   ls -la local-odoo/odoo/

   # Check virtual environment
   ls -la local-odoo/venv/
   ```

### Debug Mode

Enable detailed logging:

```bash
DEBUG=1 ./scripts/db-manager.sh create test_debug
```

## 🎯 Best Practices

### 1. Naming Conventions

- Use descriptive names: `sales_module_tests` not `test1`
- Include purpose: `integration_customer_flow`
- Use consistent prefixes for related databases

### 2. Test Database Management

- Clean up test databases regularly: `make test-db-clean AGE=1`
- Use fixtures for consistent test data
- Isolate test environments for complex features

### 3. Backup Strategy

- Backup before major changes: `make backup-create NAME=mydb`
- Verify critical backups: `make backup-verify BACKUP=file.dump`
- Implement retention policy: `make backup-clean DAYS=30`

### 4. Development Workflow

1. Create feature database: `make db-create NAME=my_feature TYPE=dev`
2. Develop and test changes
3. Create test database: `make test-db-create NAME=my_feature_tests`
4. Run tests: `make test-db-run NAME=my_feature_tests MODULE=my_module`
5. Backup stable version: `make backup-create NAME=my_feature`
6. Clean up when done: `make db-drop NAME=my_feature`

## 📚 Integration with Existing Tools

### Task 3.1 Integration

The database management tools integrate with the local Odoo installation:

- Automatic Odoo initialization for new databases
- Uses existing Odoo configuration files
- Integrates with virtual environment

### Task 3.2 Integration

Works with the PostgreSQL setup from Task 3.2:

- Uses the configured Odoo database user
- Leverages optimized PostgreSQL settings
- Integrates with the created development databases

### Task 2.x Integration

The validation scripts can be run on any managed database:

```bash
# Create test database and validate modules
make test-db-create NAME=validation_test
make validate MODULE=my_module
```

## 🔄 Future Enhancements

The database management system is designed to be extensible:

1. **Scheduled Backups**: Cron-based automatic backups
2. **Cloud Integration**: Support for cloud database storage
3. **Migration Tools**: Database schema migration support
4. **Performance Monitoring**: Database performance metrics
5. **Replication Support**: Master-slave database setups

---

This comprehensive database management system provides all the tools needed for professional Odoo development, from simple database operations to complex test environments and backup strategies. The integration with existing tools ensures a smooth development workflow while the safety features prevent data loss.

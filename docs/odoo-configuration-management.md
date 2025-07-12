# Odoo Configuration Management System
## Task 3.4: Configure Odoo config file for development environment

This document provides comprehensive guidance for managing Odoo configurations in the RTP Denver development environment. Our configuration management system provides optimized configurations for different deployment environments while integrating seamlessly with our existing infrastructure from Tasks 3.1-3.3.

## Quick Start

### 1. Create Your First Configuration

```bash
# Create development configuration (recommended for local development)
make config-create ENV=development

# Or directly with the script
./scripts/configure-odoo.sh create development
```

### 2. List Available Configurations

```bash
make config-list
```

### 3. Test Configuration

```bash
make config-test CONFIG=odoo-development.conf
```

### 4. Start Odoo with Configuration

```bash
# Use the configuration with our local Odoo installation
./local-odoo/start-odoo.sh --config=local-odoo/configs/odoo-development.conf
```

## Configuration Environments

Our system provides five pre-configured environments, each optimized for specific use cases:

### Development Environment
**Best for: Local development with auto-reload and debugging**

```bash
make config-create ENV=development
```

**Features:**
- Auto-reload enabled for code changes
- Development mode with XML/QWeb auto-reload
- Generous memory limits (4GB hard limit)
- Debug-friendly timeouts (3600s CPU, 7200s real)
- Single-worker mode for easier debugging
- Demo data enabled by default
- Comprehensive logging (INFO level)
- Testing enabled

**Configuration highlights:**
- `dev_mode = reload,qweb,werkzeug,xml`
- `workers = 0` (single process for debugging)
- `limit_time_cpu = 3600`
- `test_enable = True`
- `log_level = info`

### Testing Environment
**Best for: Automated testing and CI/CD**

```bash
make config-create ENV=testing
```

**Features:**
- Optimized for fast test execution
- Minimal logging (ERROR level only)
- Conservative memory limits
- Short timeouts for quick failures
- Demo data disabled by default
- Stop after initialization for test runs
- Isolated test environment (separate data directory)

**Configuration highlights:**
- `stop_after_init = True`
- `workers = 0`
- `log_level = error`
- `without_demo = False`
- `test_enable = True`

### Staging Environment
**Best for: Pre-production testing**

```bash
make config-create ENV=staging
```

**Features:**
- Multi-worker configuration (2 workers default)
- Production-like settings
- Intermediate logging (WARN level)
- SSL database connections required
- Proxy mode enabled
- Email configuration enabled
- Restricted database access

**Configuration highlights:**
- `workers = 2`
- `proxy_mode = True`
- `db_sslmode = require`
- `log_level = warn`
- `list_db = False`

### Production Environment
**Best for: Final testing before deployment**

```bash
make config-create ENV=production
```

**Features:**
- Multi-worker configuration (4 workers default)
- HTTPS enabled
- Strict security settings
- Optimized performance settings
- SSL/TLS enforcement
- Syslog integration
- Minimal logging (WARN level)

**Configuration highlights:**
- `workers = 4`
- `xmlrpcs = True` (HTTPS)
- `syslog = True`
- `log_level = warn`
- `db_sslmode = require`
- `limit_time_cpu = 300`

### Minimal Environment
**Best for: Quick testing and prototyping**

```bash
make config-create ENV=minimal
```

**Features:**
- Lightweight configuration
- Minimal resource usage (1GB memory limit)
- Essential settings only
- Fast startup
- Basic logging (ERROR level)

**Configuration highlights:**
- `workers = 0`
- `limit_memory_hard = 1073741824`
- `log_level = error`
- Essential options only

## Advanced Usage

### Custom Configuration Options

All environments support customization through command-line options:

```bash
# Create development config with custom settings
make config-create ENV=development WORKERS=2 LOG_LEVEL=debug DEMO=false

# Using the script directly for more options
./scripts/configure-odoo.sh create development \
    --workers 2 \
    --log-level debug \
    --disable-demo \
    --port 8169 \
    --db-host localhost \
    --admin-pass mypassword
```

### Available Options

| Option | Description | Default | Example |
|--------|-------------|---------|---------|
| `--workers COUNT` | Number of worker processes | Environment-dependent | `--workers 4` |
| `--log-level LEVEL` | Logging level | Environment-dependent | `--log-level debug` |
| `--port PORT` | HTTP port | 8069 | `--port 8169` |
| `--db-host HOST` | Database host | localhost | `--db-host 192.168.1.100` |
| `--db-port PORT` | Database port | 5432 | `--db-port 5433` |
| `--db-user USER` | Database user | Current user | `--db-user odoo` |
| `--admin-pass PASS` | Admin password | admin123 | `--admin-pass secretpass` |
| `--enable-demo` | Enable demo data | Environment-dependent | `--enable-demo` |
| `--disable-demo` | Disable demo data | Environment-dependent | `--disable-demo` |

### Configuration Management Commands

#### Makefile Integration

All configuration management is integrated into our Makefile system:

```bash
# Configuration Management (Task 3.4)
make config-create ENV=development      # Create configuration
make config-list                        # List all configurations
make config-validate CONFIG=odoo-dev.conf  # Validate configuration
make config-test CONFIG=odoo-dev.conf   # Test configuration
make config-backup CONFIG=odoo-dev.conf # Backup configuration
make config-show CONFIG=odoo-dev.conf   # Show configuration contents
```

#### Direct Script Usage

For advanced usage, use the script directly:

```bash
# All available commands
./scripts/configure-odoo.sh help

# Create configurations
./scripts/configure-odoo.sh create development
./scripts/configure-odoo.sh create testing --log-level debug

# Manage configurations
./scripts/configure-odoo.sh list
./scripts/configure-odoo.sh validate odoo-development.conf
./scripts/configure-odoo.sh backup odoo-development.conf
./scripts/configure-odoo.sh restore backup_file.conf
./scripts/configure-odoo.sh show odoo-development.conf
./scripts/configure-odoo.sh test odoo-development.conf
```

## Configuration File Structure

All configuration files are stored in `local-odoo/configs/` with the naming pattern `odoo-{environment}.conf`.

### Directory Structure

```
local-odoo/
├── configs/                    # Configuration files
│   ├── odoo-development.conf  # Development environment
│   ├── odoo-testing.conf      # Testing environment
│   ├── odoo-staging.conf      # Staging environment
│   ├── odoo-production.conf   # Production environment
│   └── odoo-minimal.conf      # Minimal environment
├── backups/                   # Configuration backups
│   ├── odoo-development_20240101_120000.conf
│   └── odoo-testing_20240101_130000.conf
└── logs/                      # Configuration logs
    ├── config.log
    └── config-test-20240101_120000.log
```

### Configuration Sections

Each configuration file contains comprehensive sections:

```ini
[options]
# Server Configuration
addons_path = /path/to/addons
data_dir = /path/to/filestore
admin_passwd = password

# Database Configuration
db_host = localhost
db_port = 5432
db_user = username
# ... more database settings

# Network Configuration
xmlrpc_port = 8069
longpolling_port = 8072
# ... more network settings

# Process Configuration
workers = 0
max_cron_threads = 2
# ... more process settings

# Development Mode Settings (development only)
dev_mode = reload,qweb,werkzeug,xml
# ... more dev settings

# Memory and Performance
limit_memory_hard = 2684354560
limit_time_cpu = 600
# ... more performance settings

# Logging Configuration
logfile = /path/to/logs/odoo.log
log_level = info
# ... more logging settings

# Testing Configuration
test_enable = True
# ... more testing settings

# Security Configuration
list_db = True
without_demo = False
# ... more security settings
```

## Integration with Existing Infrastructure

### Database Integration (Task 3.3)

The configuration system integrates seamlessly with our database management from Task 3.3:

```bash
# Create database using development configuration
make db-create NAME=mydev_db TYPE=dev

# Start Odoo with development configuration and database
./local-odoo/start-odoo.sh --config=local-odoo/configs/odoo-development.conf --database=mydev_db
```

### PostgreSQL Integration (Task 3.2)

Configurations automatically use the PostgreSQL setup from Task 3.2:

- Database user from PostgreSQL setup
- Optimized connection settings
- SSL configuration when available
- Performance tuning based on PostgreSQL configuration

### Local Odoo Integration (Task 3.1)

Configurations are designed to work with the local Odoo installation from Task 3.1:

- Correct addons paths including custom modules
- Virtual environment integration
- Logging to the correct directories
- Filestore and data directory management

## Configuration Validation

### Automatic Validation

All configurations are automatically validated when created or tested:

```bash
# Validate configuration file
make config-validate CONFIG=odoo-development.conf
```

**Validation checks:**
- Required sections and options
- Path existence verification
- Port conflicts detection
- Database connectivity
- Common configuration issues
- Performance setting warnings

### Test Configuration

Test configurations by attempting to start Odoo:

```bash
# Test configuration by starting Odoo
make config-test CONFIG=odoo-development.conf
```

This will:
1. Validate the configuration file
2. Start Odoo with the configuration
3. Check for successful initialization
4. Report any errors or warnings
5. Generate detailed test logs

## Troubleshooting

### Common Issues

#### Configuration File Not Found
```bash
# Error: Configuration file not found
# Solution: Check file exists or create it
make config-list
make config-create ENV=development
```

#### Port Conflicts
```bash
# Error: Port already in use
# Solution: Use different port or stop existing service
make config-create ENV=development --port 8169
```

#### Database Connection Issues
```bash
# Error: Database connection failed
# Solution: Verify PostgreSQL is running and configured
make setup-postgresql
```

#### Permission Issues
```bash
# Error: Permission denied on filestore
# Solution: Fix directory permissions
chmod -R 755 local-odoo/filestore-*
```

### Debugging Configuration Issues

#### Enable Debug Logging
```bash
# Create configuration with debug logging
make config-create ENV=development LOG_LEVEL=debug
```

#### Check Configuration Contents
```bash
# Show configuration file contents
make config-show CONFIG=odoo-development.conf
```

#### Validate Configuration
```bash
# Run comprehensive validation
make config-validate CONFIG=odoo-development.conf
```

#### Test Configuration
```bash
# Test configuration startup
make config-test CONFIG=odoo-development.conf
```

### Log Files

Configuration logs are stored in `local-odoo/logs/`:

- `config.log` - Configuration management operations
- `config-test-*.log` - Configuration test results
- `odoo-{environment}.log` - Odoo runtime logs per environment

## Best Practices

### Development Workflow

1. **Start with Development Environment**
   ```bash
   make config-create ENV=development
   ```

2. **Validate Before Use**
   ```bash
   make config-validate CONFIG=odoo-development.conf
   ```

3. **Test Configuration**
   ```bash
   make config-test CONFIG=odoo-development.conf
   ```

4. **Backup Before Changes**
   ```bash
   make config-backup CONFIG=odoo-development.conf
   ```

### Production Preparation

1. **Test with Staging Environment**
   ```bash
   make config-create ENV=staging
   make config-test CONFIG=odoo-staging.conf
   ```

2. **Use Production-like Settings**
   ```bash
   make config-create ENV=production WORKERS=4
   ```

3. **Validate Performance Settings**
   ```bash
   make config-validate CONFIG=odoo-production.conf
   ```

### Security Considerations

1. **Change Default Passwords**
   ```bash
   make config-create ENV=production --admin-pass strong_password
   ```

2. **Use SSL in Production**
   - Production configurations enable HTTPS
   - Database SSL is required for staging/production

3. **Restrict Database Access**
   - Staging/production configurations disable `list_db`
   - Database filtering is enabled

### Performance Optimization

1. **Use Appropriate Worker Count**
   ```bash
   # For development (single process for debugging)
   make config-create ENV=development WORKERS=0

   # For production (multiple workers for performance)
   make config-create ENV=production WORKERS=4
   ```

2. **Adjust Memory Limits**
   ```bash
   # Custom memory limits
   ./scripts/configure-odoo.sh create development --memory-limit 4294967296
   ```

3. **Configure Timeouts**
   - Development: Generous timeouts for debugging
   - Production: Strict timeouts for performance

## Integration Examples

### Development Workflow

```bash
# 1. Set up development environment
make setup-postgresql
make install-odoo
make config-create ENV=development

# 2. Create development database
make db-create NAME=mydev_db TYPE=dev

# 3. Start Odoo with development configuration
./local-odoo/start-odoo.sh --config=local-odoo/configs/odoo-development.conf --database=mydev_db

# 4. Develop and test
# ... development work ...

# 5. Run validation and tests
make validate
make test

# 6. Prepare for deployment
make config-create ENV=staging
make config-test CONFIG=odoo-staging.conf
```

### Testing Workflow

```bash
# 1. Create testing configuration
make config-create ENV=testing LOG_LEVEL=debug

# 2. Set up test databases
make test-db-create NAME=unittest_db
make test-db-fixture NAME=integration_fixture

# 3. Run tests with testing configuration
make test-db-run NAME=unittest_db MODULE=royal_textiles_sales

# 4. Clean up after testing
make test-db-clean AGE=1
```

### Staging Deployment

```bash
# 1. Create staging configuration
make config-create ENV=staging WORKERS=2

# 2. Clone production data for staging
make db-clone SOURCE=production_db TARGET=staging_db

# 3. Test staging configuration
make config-test CONFIG=odoo-staging.conf

# 4. Start staging server
./local-odoo/start-odoo.sh --config=local-odoo/configs/odoo-staging.conf --database=staging_db
```

## Advanced Features

### Environment Variables

The configuration system supports environment variables for dynamic configuration:

```bash
# Set environment variables
export ODOO_DB_HOST=192.168.1.100
export ODOO_DB_USER=odoo_user
export HTTP_PORT=8169

# Create configuration with environment variables
make config-create ENV=development
```

### Configuration Templates

You can create custom configuration templates by modifying the script functions in `scripts/configure-odoo.sh`.

### Automation Scripts

Integrate configuration management into automation scripts:

```bash
#!/bin/bash
# deployment-script.sh

# Create production configuration
make config-create ENV=production WORKERS=4 --disable-demo

# Validate configuration
if make config-validate CONFIG=odoo-production.conf; then
    echo "Configuration valid, proceeding with deployment"
    # Deploy with validated configuration
else
    echo "Configuration invalid, aborting deployment"
    exit 1
fi
```

## Summary

The Odoo Configuration Management system (Task 3.4) provides:

✅ **Five optimized environments** (development, testing, staging, production, minimal)
✅ **Comprehensive configuration validation** with automatic error detection
✅ **Seamless integration** with Tasks 3.1-3.3 infrastructure
✅ **Makefile integration** for easy command-line usage
✅ **Configuration backup and restore** functionality
✅ **Environment-specific optimizations** for performance and security
✅ **Extensive customization options** via command-line parameters
✅ **Automatic path detection** and addons configuration
✅ **Development-friendly features** like auto-reload and debugging support
✅ **Production-ready security** settings and performance tuning

This system ensures that your Odoo development environment is properly configured for each stage of development while maintaining consistency and reliability across deployments.

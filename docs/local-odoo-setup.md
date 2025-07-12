# Local Odoo 18.0 Development Setup

This guide covers the local Odoo development environment that matches the odoo.sh production environment for RTP Denver.

## Quick Start

### 1. Install Local Odoo

```bash
# Install Odoo 18.0 development environment
make install-odoo

# OR run the script directly
./scripts/install-local-odoo.sh
```

### 2. Start Development Server

```bash
# Start Odoo server
make start-odoo

# Access Odoo at: http://localhost:8069
# Admin password: admin123
```

### 3. Create Test Database

```bash
# Create a test database
make create-db DB=test_db

# List all databases
make list-dbs
```

## Installation Options

The installation script supports several options:

```bash
# Standard installation
./scripts/install-local-odoo.sh

# Force reinstallation (removes existing installation)
./scripts/install-local-odoo.sh --force-reinstall

# Skip PostgreSQL setup (if you have your own database)
./scripts/install-local-odoo.sh --skip-db

# Use specific Python version
./scripts/install-local-odoo.sh --python-version 3.12

# Show help
./scripts/install-local-odoo.sh --help
```

## Environment Specifications

Our local environment matches odoo.sh exactly:

- **Odoo Version**: 18.0 (latest stable)
- **Python Version**: 3.11+ (matches odoo.sh)
- **PostgreSQL**: 14+ (matches odoo.sh)
- **Development Mode**: Enabled (auto-reload, debugging)

## Directory Structure

```
local-odoo/
├── odoo/                 # Odoo 18.0 source code
├── venv/                 # Python virtual environment
├── addons/               # Additional addons directory
├── logs/                 # Log files
├── backups/              # Database backups
├── filestore/            # File storage
├── odoo.conf             # Odoo configuration
├── start-odoo.sh         # Start script
└── manage-db.sh          # Database management
```

## Development Workflow

### 1. Module Development

Your custom modules in `custom_modules/` are automatically available:

```bash
# Validate modules before testing
make validate

# Start Odoo with auto-reload
make start-odoo

# Your modules appear in Apps menu
```

### 2. Database Management

```bash
# Create new database
make create-db DB=my_project

# Reset database (drops and recreates)
make reset-db DB=my_project

# Drop database
make drop-db DB=my_project

# List all databases
make list-dbs
```

### 3. Testing Workflow

```bash
# 1. Validate modules
make validate

# 2. Run tests
make test

# 3. Start local Odoo
make start-odoo

# 4. Test manually in browser
# 5. Deploy to odoo.sh
make deploy-check
```

## Configuration

### Odoo Configuration (`local-odoo/odoo.conf`)

Key settings for development:

```ini
[options]
# Development mode (auto-reload)
dev_mode = reload,qweb,werkzeug,xml

# Custom modules path
addons_path = /path/to/odoo/addons,/path/to/local-odoo/addons,/path/to/custom_modules

# Database settings
db_host = localhost
db_user = your_username

# Testing enabled
test_enable = True

# Security (development only)
admin_passwd = admin123
list_db = True
```

### Custom Addons

Place additional community addons in `local-odoo/addons/`:

```bash
cd local-odoo/addons/
git clone https://github.com/OCA/some-addon.git
```

## Database Operations

### Manual Database Operations

```bash
# Activate virtual environment
source local-odoo/venv/bin/activate

# Create database with demo data
python local-odoo/odoo/odoo-bin \
    --config=local-odoo/odoo.conf \
    --database=demo_db \
    --init=base \
    --without-demo=False \
    --stop-after-init

# Install specific modules
python local-odoo/odoo/odoo-bin \
    --config=local-odoo/odoo.conf \
    --database=demo_db \
    --init=sale,account,your_custom_module \
    --stop-after-init

# Update modules
python local-odoo/odoo/odoo-bin \
    --config=local-odoo/odoo.conf \
    --database=demo_db \
    --update=your_custom_module \
    --stop-after-init
```

### Backup and Restore

```bash
# Backup database
pg_dump demo_db > local-odoo/backups/demo_db_$(date +%Y%m%d).sql

# Restore database
createdb restored_db
psql restored_db < local-odoo/backups/demo_db_20241215.sql
```

## Debugging

### VS Code/Cursor Debugging

The installation includes `debugpy` for Python debugging:

```python
# Add to your Python code
import debugpy
debugpy.listen(5678)
debugpy.wait_for_client()  # Optional: wait for debugger
```

### Log Files

```bash
# View Odoo logs
tail -f local-odoo/logs/odoo.log

# View PostgreSQL logs (macOS with Homebrew)
tail -f /opt/homebrew/var/log/postgresql@14.log
```

## Integration with Validation Tools

Our local Odoo works seamlessly with our validation infrastructure:

```bash
# Validate modules (works with local installation)
make validate

# Run enhanced validation
python scripts/validate-module.py

# Test in local environment
make start-odoo
# Then test your modules manually
```

## Performance Optimization

### Development Settings

For faster development:

```ini
# In odoo.conf
workers = 0                # Single-threaded for development
max_cron_threads = 0       # Disable cron jobs
limit_memory_soft = 0      # Disable memory limits
```

### Production-like Testing

For production testing:

```ini
# In odoo.conf
workers = 2                # Multi-process
max_cron_threads = 2       # Enable cron jobs
limit_memory_soft = 2147483648  # Enable memory limits
```

## Troubleshooting

### Common Issues

1. **Port 8069 already in use**
   ```bash
   # Find and kill process
   lsof -ti:8069 | xargs kill -9
   ```

2. **PostgreSQL connection error**
   ```bash
   # macOS: Start PostgreSQL
   brew services start postgresql@14

   # Linux: Start PostgreSQL
   sudo systemctl start postgresql
   ```

3. **Permission errors**
   ```bash
   # Fix ownership
   sudo chown -R $(whoami) local-odoo/
   ```

4. **Python virtual environment issues**
   ```bash
   # Recreate virtual environment
   rm -rf local-odoo/venv
   ./scripts/install-local-odoo.sh --force-reinstall
   ```

### Getting Help

1. Check installation logs
2. Verify system requirements
3. Review Odoo logs: `local-odoo/logs/odoo.log`
4. Test with minimal configuration

## Production Deployment

When ready to deploy to odoo.sh:

```bash
# 1. Run comprehensive validation
make deploy-check

# 2. Ensure all tests pass
make test

# 3. Push to your odoo.sh git repository
git push odoo-sh main
```

The local environment exactly matches odoo.sh, so modules that work locally will work in production.

## Notes

- This setup is for **development only** - not suitable for production
- Admin password is hardcoded (`admin123`) for development convenience
- Database list is enabled for easy management
- All validation tools work with this local installation
- Custom modules in `custom_modules/` are automatically available

# Docker Alternative Setup for Environment Consistency
## Task 3.7: Create Docker alternative setup for environment consistency

This document provides comprehensive guidance for using Docker as an alternative to local Odoo installation. The Docker setup provides environment consistency across different development machines while maintaining full integration with our existing infrastructure from Tasks 3.1-3.6.

## Overview

The Docker alternative setup includes:
- **Odoo 18.0 Container**: Matches our local installation exactly
- **PostgreSQL 14 Container**: Database with proper Odoo configuration
- **Development Tools**: pgAdmin, MailHog, Redis (optional)
- **Full Integration**: All existing scripts and tools work seamlessly
- **Multiple Environments**: Development, testing, staging, production
- **Service Profiles**: Choose which services to run

## Quick Start

### 1. Prerequisites

Ensure Docker and Docker Compose are installed:

```bash
# Check Docker installation
docker --version
docker-compose --version  # or: docker compose version
```

### 2. Initial Setup

```bash
# Setup Docker environment
make docker-setup

# Build Docker images
make docker-build

# Start development environment
make docker-up-dev
```

### 3. Access Services

- **Odoo**: http://localhost:8069
- **Admin Password**: admin123
- **pgAdmin**: http://localhost:8080 (if enabled)
- **MailHog**: http://localhost:8025 (if enabled)

## Environment Configuration

### Environment Variables

Copy and customize the environment template:

```bash
cp docker-env-template .env
```

Key configuration options:

```bash
# Database
POSTGRES_PASSWORD=odoo
POSTGRES_PORT=5432

# Odoo
ADMIN_PASSWORD=admin123
ENVIRONMENT=development
ODOO_PORT=8069

# Development Tools
PGADMIN_PORT=8080
MAILHOG_WEB_PORT=8025
REDIS_PORT=6379
```

### Service Profiles

Choose which services to run:

```bash
# Development (Odoo + PostgreSQL + MailHog)
COMPOSE_PROFILES=development make docker-up

# Testing (includes testing container)
COMPOSE_PROFILES=testing make docker-up

# With pgAdmin for database management
COMPOSE_PROFILES=development,pgadmin make docker-up

# Full environment (all services)
COMPOSE_PROFILES=full make docker-up
```

## Docker Commands Reference

### Basic Operations

```bash
# Setup and build
make docker-setup              # Initial environment setup
make docker-build              # Build Docker images
make docker-build FORCE=true   # Force rebuild without cache

# Service management
make docker-up                 # Start services (development profile)
make docker-up PROFILE=testing # Start with specific profile
make docker-down              # Stop services
make docker-restart           # Restart services
make docker-status            # Show service status
```

### Development Workflow

```bash
# Open shell in Odoo container
make docker-shell

# View logs
make docker-logs              # All services
make docker-logs SERVICE=odoo # Specific service
make docker-logs SERVICE=postgres FOLLOW=true # Follow logs

# Execute commands
docker compose exec odoo bash
docker compose exec postgres psql -U odoo -l
```

### Database Operations

```bash
# Create database with custom modules
make docker-db OP=create DB=myproject MODULES=rtp_customers,royal_textiles_sales

# Drop database
make docker-db OP=drop DB=myproject

# List databases
make docker-db OP=list

# Backup database
make docker-db OP=backup DB=myproject

# Restore database
make docker-db OP=restore DB=myproject FILE=backup.sql
```

### Testing Operations

```bash
# Run module installation tests
make docker-test TYPE=module-install ARGS=rtp_customers

# Run integration tests
make docker-test TYPE=integration

# Generate sample data
make docker-test TYPE=sample-data ARGS=development

# Complete test suite
make docker-test
```

### Cleanup Operations

```bash
# Light cleanup (stop services only)
make docker-clean LEVEL=light

# Standard cleanup (remove containers)
make docker-clean

# Full cleanup (remove images, networks)
make docker-clean LEVEL=full

# Complete cleanup (remove everything including volumes)
make docker-clean LEVEL=all
```

## Integration with Existing Infrastructure

### Database Management

The Docker setup integrates with our existing database scripts:

```bash
# Use database manager in Docker
docker compose exec odoo bash /opt/odoo/scripts/db-manager.sh list

# Generate sample data
docker compose exec odoo bash /opt/odoo/scripts/generate-sample-data.sh create development

# Test module installation
docker compose exec odoo bash /opt/odoo/scripts/test-module-installation.sh install rtp_customers
```

### Configuration Management

Use existing configuration scripts:

```bash
# Generate Odoo configuration
docker compose exec odoo bash /opt/odoo/scripts/configure-odoo.sh create development
```

### Module Development

Your custom modules are mounted as volumes, so changes are reflected immediately:

```bash
# Custom modules directory is mounted at /opt/odoo/custom_modules
# Edit files locally, changes appear in container automatically

# Test changes
make docker-restart
```

## Advanced Configuration

### Custom Docker Compose Overrides

Create `docker-compose.override.yml` for custom configurations:

```yaml
version: '3.8'

services:
  odoo:
    environment:
      - CUSTOM_ENV_VAR=value
    volumes:
      - ./custom_addons:/opt/odoo/custom_addons:ro
    ports:
      - "9069:8069"  # Use different port
```

### Performance Tuning

For development on resource-constrained machines:

```yaml
services:
  odoo:
    deploy:
      resources:
        limits:
          memory: 1g
        reservations:
          memory: 512m
  postgres:
    deploy:
      resources:
        limits:
          memory: 512m
```

### Production-like Environment

For staging/production testing:

```bash
# Use production environment
ENVIRONMENT=production make docker-up

# With SSL and multiple workers
ODOO_WORKERS=4 ENVIRONMENT=production make docker-up
```

## Volume Management

### Persistent Data

Data is stored in named Docker volumes:
- `rtp-denver-postgres-data`: Database data
- `rtp-denver-odoo-data`: Odoo file storage
- `rtp-denver-odoo-logs`: Log files
- `rtp-denver-odoo-config`: Configuration files

### Backup and Restore

```bash
# Backup all volumes
make docker-backup

# Backup to specific directory
make docker-backup DIR=./my-backups

# Restore from backup
make docker-restore DIR=./my-backups
```

### Volume Inspection

```bash
# List volumes
docker volume ls | grep rtp-denver

# Inspect volume
docker volume inspect rtp-denver-odoo-data

# Access volume data
docker run --rm -v rtp-denver-odoo-data:/data alpine ls -la /data
```

## Troubleshooting

### Common Issues

1. **Port conflicts**:
   ```bash
   # Change ports in .env file
   ODOO_PORT=8070
   POSTGRES_PORT=5433
   ```

2. **Permission issues**:
   ```bash
   # Set user/group IDs in .env
   DOCKER_USER_ID=1001
   DOCKER_GROUP_ID=1001
   ```

3. **Database connection issues**:
   ```bash
   # Check PostgreSQL status
   docker compose exec postgres pg_isready -U odoo

   # View PostgreSQL logs
   make docker-logs SERVICE=postgres
   ```

4. **Module not found**:
   ```bash
   # Verify custom modules mount
   docker compose exec odoo ls -la /opt/odoo/custom_modules

   # Check addons path
   docker compose exec odoo python -c "
   import configparser
   config = configparser.ConfigParser()
   config.read('/etc/odoo/odoo.conf')
   print(config.get('options', 'addons_path'))
   "
   ```

### Health Checks

```bash
# Check service health
make docker-status

# Manual health checks
curl -f http://localhost:8069/web/health
docker compose exec postgres pg_isready -U odoo
```

### Debug Mode

```bash
# Start with debug logging
ENVIRONMENT=development docker compose up

# Enable verbose logging
docker compose exec odoo python /opt/odoo/odoo/odoo-bin \
  --config=/etc/odoo/odoo.conf \
  --log-level=debug \
  --dev=all
```

## Comparison: Local vs Docker

| Aspect | Local Installation | Docker Setup |
|--------|-------------------|--------------|
| **Environment Consistency** | Varies by machine | Identical everywhere |
| **Setup Time** | 15-30 minutes | 5-10 minutes |
| **Resource Usage** | Native performance | Small overhead |
| **Isolation** | System-wide changes | Containerized |
| **Dependencies** | Manual management | Automatic |
| **Cleanup** | Manual removal | One command |
| **Team Collaboration** | Configuration drift | Consistent configs |
| **CI/CD Integration** | Complex setup | Simple integration |

## Integration Examples

### Development Workflow

```bash
# Daily development routine
make docker-up-dev
make docker-db OP=create DB=feature_branch MODULES=rtp_customers
# Edit code in ./custom_modules/
make docker-test TYPE=module-install ARGS=rtp_customers
make docker-down
```

### Testing Workflow

```bash
# Automated testing
make docker-up PROFILE=testing
make docker-test TYPE=all
make docker-clean
```

### CI/CD Pipeline

```bash
# In CI environment
export CI_MODE=true
make docker-setup
make docker-build
make docker-up PROFILE=testing
make docker-test
make docker-clean LEVEL=all
```

## Best Practices

### Development

1. **Use profiles**: Start only necessary services
2. **Mount volumes**: Keep data persistent during development
3. **Regular cleanup**: Remove unused containers and images
4. **Monitor resources**: Use `docker stats` to check usage

### Production

1. **Secure configurations**: Use production environment settings
2. **Health checks**: Monitor service health
3. **Backup volumes**: Regular data backups
4. **Update strategy**: Plan container updates

### Team Collaboration

1. **Shared .env template**: Consistent configurations
2. **Docker Compose overrides**: Personal customizations
3. **Volume backups**: Share development data
4. **Documentation**: Keep this guide updated

## Next Steps

After setting up Docker, you can:

1. **Explore Services**: Use pgAdmin, MailHog for development
2. **Customize Environment**: Modify docker-compose.yml
3. **Automate Workflows**: Create custom scripts
4. **Scale Services**: Add Redis, multiple workers
5. **Deploy**: Use similar setup for staging/production

## Support and Resources

- **Docker Documentation**: https://docs.docker.com/
- **Docker Compose**: https://docs.docker.com/compose/
- **Odoo Docker**: Official Odoo Docker images
- **PostgreSQL Docker**: Official PostgreSQL images

## Task Integration

This Docker setup (Task 3.7) completes our comprehensive local testing infrastructure:

- **Task 3.1**: Local Odoo installation → Docker alternative
- **Task 3.2**: PostgreSQL setup → Containerized database
- **Task 3.3**: Database management → Docker database operations
- **Task 3.4**: Configuration management → Docker configuration
- **Task 3.5**: Sample data generation → Docker data generation
- **Task 3.6**: Module testing → Docker testing automation
- **Task 3.7**: Docker alternative → Environment consistency

All existing tools and workflows work seamlessly with both local and Docker setups, providing maximum flexibility for development teams.

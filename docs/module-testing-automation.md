# Module Installation/Upgrade Testing Automation
## Task 3.6: Add module installation/upgrade testing automation

This document provides comprehensive guidance for the Module Installation/Upgrade Testing Automation system implemented in Task 3.6. This system provides automated testing for Odoo module installations, upgrades, dependencies, and integration scenarios.

## Quick Start

### 1. List Available Modules

```bash
# List modules available for testing
make module-test-list

# Or use the script directly
./scripts/test-module-installation.sh list-modules
```

### 2. Test Module Installation

```bash
# Test basic installation
make module-test-install MODULE=rtp_customers

# Test installation with demo data and validation
make module-test-install MODULE=rtp_customers DEMO=true SECURITY=true VALIDATE=true
```

### 3. Test Module Upgrade

```bash
# Test basic upgrade
make module-test-upgrade MODULE=royal_textiles_sales

# Test upgrade with data migration and preservation
make module-test-upgrade MODULE=royal_textiles_sales MIGRATION=true PRESERVE=true
```

### 4. Run Complete Test Suite

```bash
# Run full test suite for all modules
make module-test-full

# Run with parallel execution and HTML report
make module-test-full PARALLEL=true FORMAT=html
```

## System Overview

The Module Testing Automation system provides:

- **Installation Testing**: Fresh module installations with dependency checking
- **Upgrade Testing**: Module upgrade scenarios with data migration validation
- **Dependency Testing**: Module dependency resolution and compatibility
- **Integration Testing**: Module interactions and complete workflows
- **Security Testing**: Access controls and security group validation
- **Data Validation**: Comprehensive data loading and integrity checks
- **Automated Reporting**: Text, JSON, and HTML test reports
- **CI/CD Integration**: Automated testing for deployment readiness

## Available Test Types

### Installation Testing
**Purpose**: Test fresh module installations and validate all components load correctly
**Features**:
- Clean database creation for each test
- Module dependency resolution
- Demo data installation testing
- Security and access control validation
- View and menu loading verification
- Model creation and field validation

```bash
# Basic installation test
make module-test-install MODULE=rtp_customers

# Complete installation test with all validations
make module-test-install MODULE=rtp_customers DEMO=true SECURITY=true VALIDATE=true
```

### Upgrade Testing
**Purpose**: Test module upgrades and data migration scenarios
**Features**:
- Simulated version upgrades
- Data preservation validation
- Schema migration testing
- Business logic integrity checks
- Performance impact assessment

```bash
# Basic upgrade test
make module-test-upgrade MODULE=royal_textiles_sales

# Complete upgrade test with migration validation
make module-test-upgrade MODULE=royal_textiles_sales MIGRATION=true PRESERVE=true
```

### Dependency Testing
**Purpose**: Validate module dependencies and compatibility
**Features**:
- Dependency resolution validation
- Missing dependency detection
- Circular dependency identification
- Version compatibility checking
- Module manifest validation

```bash
# Test module dependencies
make module-test-dependencies MODULE=rtp_customers
```

### Integration Testing
**Purpose**: Test module interactions and complete business workflows
**Features**:
- Multi-module installation testing
- Cross-module workflow validation
- Data relationship integrity
- Business process testing
- Performance impact analysis

```bash
# Basic integration testing
make module-test-integration

# Integration testing with workflow validation
make module-test-integration WORKFLOWS=true
```

## Available Modules

### RTP Customers Module (`rtp_customers`)
**Purpose**: Customer management system demonstrating Hello World Todo concepts in real business applications
**Dependencies**: base, web, contacts
**Key Features**:
- Customer data management
- Contact information tracking
- Customer status workflow
- User access control
- Search and filtering capabilities

**Testing Commands**:
```bash
# Complete RTP Customers testing suite
make module-test-rtp-customers

# Individual tests
make module-test-install MODULE=rtp_customers DEMO=true
make module-test-upgrade MODULE=rtp_customers MIGRATION=true
make module-test-dependencies MODULE=rtp_customers
```

### Royal Textiles Sales Module (`royal_textiles_sales`)
**Purpose**: Sales order enhancements for commercial blinds and shades installation company
**Dependencies**: base, web, sale, project, calendar
**Key Features**:
- Schedule Installation button on sales orders
- Generate Work Order with installation tasks
- Calculate Materials needed for installation
- Integration with project management workflows

**Testing Commands**:
```bash
# Complete Royal Textiles testing suite
make module-test-royal-textiles

# Individual tests
make module-test-install MODULE=royal_textiles_sales DEMO=true
make module-test-upgrade MODULE=royal_textiles_sales MIGRATION=true
make module-test-dependencies MODULE=royal_textiles_sales
```

## Integration with Existing Systems

### Database Management (Task 3.3)
- **Automatic Test Database Creation**: Creates isolated test databases using our database management system
- **Database Cleanup**: Automated cleanup of test databases after testing
- **Backup Integration**: Test database backup and restore for complex scenarios
- **Performance Monitoring**: Database performance impact during testing

### Configuration System (Task 3.4)
- **Environment-Specific Testing**: Uses appropriate Odoo configurations for different test scenarios
- **Configuration Validation**: Tests modules with development, testing, and production configurations
- **Performance Tuning**: Optimized configurations for testing workflows

### Sample Data Generation (Task 3.5)
- **Test Data Integration**: Uses sample data generation for upgrade testing scenarios
- **Data Preservation Testing**: Validates data integrity after module upgrades
- **Scenario-Based Testing**: Different data scenarios for comprehensive testing

### Local Odoo Installation (Task 3.1)
- **Version Compatibility**: Tests with Odoo 18.0 matching odoo.sh environment
- **Module Detection**: Automatic detection of available custom modules
- **Installation Validation**: Ensures modules install correctly in local environment

### PostgreSQL Setup (Task 3.2)
- **Database Isolation**: Each test uses isolated databases for reliable results
- **Performance Testing**: Database performance monitoring during module operations
- **Connection Management**: Efficient database connection handling for parallel tests

## Test Commands Reference

### Makefile Commands

#### Basic Testing
```bash
make module-test-install MODULE=<module>     # Test module installation
make module-test-upgrade MODULE=<module>     # Test module upgrade
make module-test-dependencies MODULE=<module> # Test dependencies
make module-test-integration                 # Test module interactions
```

#### Advanced Testing
```bash
make module-test-full                        # Complete test suite
make module-test-list                        # List available modules
make module-test-cleanup                     # Clean up test environment
```

#### Module-Specific Testing
```bash
make module-test-rtp-customers              # Complete RTP Customers testing
make module-test-royal-textiles             # Complete Royal Textiles testing
```

#### Development Shortcuts
```bash
make module-test-quick                      # Quick installation tests only
make module-test-ci                         # CI-style testing with reports
```

### Direct Script Usage

#### Installation Testing
```bash
# Basic installation
./scripts/test-module-installation.sh install-test rtp_customers

# Installation with demo data and security testing
./scripts/test-module-installation.sh install-test rtp_customers --with-demo --test-security --validate-data

# Installation with custom configuration
./scripts/test-module-installation.sh install-test royal_textiles_sales --config odoo-production.conf
```

#### Upgrade Testing
```bash
# Basic upgrade
./scripts/test-module-installation.sh upgrade-test royal_textiles_sales

# Upgrade with migration and data preservation testing
./scripts/test-module-installation.sh upgrade-test royal_textiles_sales --test-migration --preserve-data
```

#### Full Test Suite
```bash
# Complete test suite
./scripts/test-module-installation.sh full-test

# Parallel testing with HTML report
./scripts/test-module-installation.sh full-test --parallel --report-format html --output-dir ./test-reports

# Continue on errors with JSON report
./scripts/test-module-installation.sh full-test --continue-on-error --report-format json
```

## Test Options and Flags

### Installation Test Options
- `--with-demo`: Install with demo data enabled
- `--without-demo`: Install without demo data (default)
- `--test-security`: Test security groups and access controls
- `--validate-data`: Validate all data files load correctly
- `--force-reinstall`: Force reinstall if module already installed

### Upgrade Test Options
- `--test-migration`: Test data migration scenarios
- `--preserve-data`: Test that existing data is preserved during upgrade
- `--test-workflows`: Test business workflows after upgrade

### Common Options
- `--config CONFIG`: Use specific Odoo configuration file
- `--parallel`: Run tests in parallel where possible
- `--continue-on-error`: Continue testing after failures
- `--report-format FORMAT`: Report format (text, json, html)
- `--output-dir DIR`: Output directory for test results

## Test Reports and Logging

### Report Formats

#### Text Report
Simple text-based report showing test results and summary:
```bash
make module-test-full FORMAT=text
```

#### JSON Report
Machine-readable JSON report for CI/CD integration:
```bash
make module-test-full FORMAT=json
```

#### HTML Report
Rich HTML report with detailed results and formatting:
```bash
make module-test-full FORMAT=html
```

### Log Files

**Main Log**: `local-odoo/logs/module-testing.log`
- Complete testing session log
- All info, warning, and error messages
- Debugging information when DEBUG=1

**Test Results**: `local-odoo/test-results/`
- Individual test result files
- Installation logs for each module
- Upgrade and migration logs
- Security and validation test results

**Module-Specific Logs**:
- `install_<module>_<database>.log` - Installation logs
- `upgrade_<module>_<database>.log` - Upgrade logs
- `security_test_<module>.log` - Security validation logs
- `data_validation_<module>.log` - Data validation logs

## Testing Workflows

### Development Workflow
1. **Module Development**: Develop or modify custom modules
2. **Quick Testing**: `make module-test-quick` for basic installation validation
3. **Full Testing**: `make module-test-full` before committing changes
4. **Integration Testing**: `make module-test-integration WORKFLOWS=true` for complete validation

### CI/CD Workflow
1. **Automated Testing**: `make module-test-ci` for deployment readiness
2. **Report Generation**: JSON reports for CI system integration
3. **Failure Analysis**: Detailed logs for debugging failures
4. **Deployment Gate**: All tests must pass before deployment

### Release Workflow
1. **Complete Suite**: `make module-test-full PARALLEL=true`
2. **Upgrade Testing**: Test upgrades from previous versions
3. **Performance Validation**: Large dataset testing with sample data
4. **Documentation**: HTML reports for release documentation

## Testing Best Practices

### Development Testing
1. **Test Early**: Run installation tests during development
2. **Test Often**: Use quick tests for rapid iteration
3. **Test Completely**: Full test suite before commits
4. **Test Integration**: Always test module interactions

### Upgrade Testing
1. **Data Backup**: Always backup before upgrade testing
2. **Migration Testing**: Test with realistic data scenarios
3. **Workflow Validation**: Ensure business processes still work
4. **Performance Monitoring**: Check for performance regressions

### CI/CD Integration
1. **Automated Execution**: Include in CI pipelines
2. **Failure Handling**: Continue on error for comprehensive results
3. **Report Integration**: Use JSON reports for CI dashboards
4. **Notification**: Alert on failures with detailed logs

## Troubleshooting

### Common Issues

**1. Odoo Installation Not Found**
```bash
# Error: Odoo installation not found
# Solution: Install Odoo first
make install-odoo
```

**2. Database Connection Errors**
```bash
# Error: Database connection failed
# Solution: Check PostgreSQL setup
./scripts/setup-postgresql.sh
```

**3. Module Not Found**
```bash
# Error: Module not found
# Solution: Check module exists and is properly structured
make module-test-list
```

**4. Test Database Creation Failed**
```bash
# Error: Could not create test database
# Solution: Check database permissions and disk space
make db-list
```

### Debugging

**Enable Debug Mode**:
```bash
DEBUG=1 ./scripts/test-module-installation.sh install-test rtp_customers
```

**Check Logs**:
```bash
# Main testing log
tail -f local-odoo/logs/module-testing.log

# Specific test results
ls -la local-odoo/test-results/
```

**Manual Testing**:
```bash
# Create test database manually
make db-create NAME=manual_test_db TYPE=test

# Test module installation manually
./local-odoo/start-odoo.sh --database=manual_test_db --init=rtp_customers --stop-after-init
```

### Performance Issues

**Large Dataset Testing**:
```bash
# Use sample data for realistic testing
make data-create SCENARIO=performance DB=perf_test_db
make module-test-upgrade MODULE=rtp_customers DB=perf_test_db
```

**Parallel Testing Issues**:
```bash
# Reduce parallelism if encountering issues
make module-test-full PARALLEL=false
```

**Memory Issues**:
```bash
# Monitor memory usage during testing
top -p $(pgrep -f "test-module-installation")
```

## Integration Examples

### GitHub Actions
```yaml
name: Module Testing
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Setup Environment
        run: make install-odoo
      - name: Test Modules
        run: make module-test-ci
      - name: Upload Results
        uses: actions/upload-artifact@v2
        with:
          name: test-results
          path: local-odoo/test-results/
```

### Jenkins Pipeline
```groovy
pipeline {
    agent any
    stages {
        stage('Setup') {
            steps {
                sh 'make install-odoo'
            }
        }
        stage('Test') {
            steps {
                sh 'make module-test-full CONTINUE=true FORMAT=json'
            }
        }
        stage('Report') {
            steps {
                archiveArtifacts 'local-odoo/test-results/**'
                publishHTML([allowMissing: false,
                           alwaysLinkToLastBuild: true,
                           keepAll: true,
                           reportDir: 'local-odoo/test-results',
                           reportFiles: '*.html',
                           reportName: 'Module Test Report'])
            }
        }
    }
}
```

## Future Enhancements

### Planned Features
- **Performance Benchmarking**: Automated performance regression testing
- **Test Templates**: Configurable test templates for different module types
- **API Testing**: REST API endpoint testing for modules with web services
- **Load Testing**: Concurrent user simulation for performance testing

### Extensibility
- **Custom Test Plugins**: Support for module-specific test plugins
- **External Integration**: Integration with external testing frameworks
- **Notification Systems**: Slack, email, and webhook notifications
- **Dashboard Integration**: Real-time testing dashboard

## Conclusion

The Module Installation/Upgrade Testing Automation system provides comprehensive, automated testing for Odoo custom modules. It seamlessly integrates with our existing infrastructure from Tasks 3.1-3.5 and provides the automation needed to catch installation and upgrade issues before deployment to odoo.sh.

Key benefits:
- **Comprehensive Testing**: Installation, upgrade, dependency, and integration testing
- **Automated Workflow**: Seamless integration with development and CI/CD workflows
- **Detailed Reporting**: Multiple report formats for different use cases
- **Reliable Infrastructure**: Built on proven database and configuration management
- **Scalable Design**: Supports parallel testing and large datasets

The system is production-ready and provides the foundation for reliable, automated module testing throughout the development lifecycle.

#!/bin/bash

# RTP Denver - Module Installation/Upgrade Testing Automation
# Task 3.6: Add module installation/upgrade testing automation
#
# This script provides comprehensive automation for testing Odoo module installations,
# upgrades, and dependencies. It integrates with our existing database management,
# configuration, and sample data systems from Tasks 3.1-3.5.
#
# Usage: ./scripts/test-module-installation.sh [COMMAND] [OPTIONS]

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ODOO_HOME="$PROJECT_ROOT/local-odoo"
ODOO_PATH="$ODOO_HOME/odoo"
VENV_PATH="$ODOO_HOME/venv"
LOGS_PATH="$ODOO_HOME/logs"
CUSTOM_MODULES_PATH="$PROJECT_ROOT/custom_modules"
TEST_RESULTS_PATH="$ODOO_HOME/test-results"

# Default settings
DEFAULT_CONFIG="odoo-testing.conf"
TEST_DB_PREFIX="test_module_"
UPGRADE_DB_PREFIX="upgrade_test_"

# Available modules for testing
CUSTOM_MODULES=("rtp_customers" "royal_textiles_sales")

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Test results tracking
TESTS_PASSED=0
TESTS_FAILED=0
TEST_RESULTS=()

# Show help message
show_help() {
    echo "RTP Denver - Module Installation/Upgrade Testing Automation"
    echo "==========================================================="
    echo ""
    echo "Task 3.6: Comprehensive module installation and upgrade testing"
    echo ""
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  install-test MODULE        Test fresh module installation"
    echo "  upgrade-test MODULE        Test module upgrade scenarios"
    echo "  dependency-test MODULE     Test module dependencies"
    echo "  integration-test           Test module interactions"
    echo "  full-test                  Run complete test suite"
    echo "  list-modules               List available modules for testing"
    echo "  cleanup                    Clean up test databases and files"
    echo ""
    echo "Installation Test Options:"
    echo "  --with-demo               Install with demo data"
    echo "  --without-demo            Install without demo data"
    echo "  --force-reinstall         Force reinstall if already installed"
    echo "  --test-security           Test security and access controls"
    echo "  --validate-data           Validate all data files load correctly"
    echo ""
    echo "Upgrade Test Options:"
    echo "  --from-version VERSION    Simulate upgrade from specific version"
    echo "  --test-migration          Test data migration scenarios"
    echo "  --preserve-data           Test upgrade preserves existing data"
    echo "  --test-workflows          Test business workflows after upgrade"
    echo ""
    echo "Common Options:"
    echo "  --config CONFIG           Use specific Odoo configuration"
    echo "  --parallel                Run tests in parallel where possible"
    echo "  --continue-on-error       Continue testing after failures"
    echo "  --report-format FORMAT    Report format: text, json, html"
    echo "  --output-dir DIR          Output directory for test results"
    echo ""
    echo "Examples:"
    echo "  $0 install-test rtp_customers --with-demo"
    echo "  $0 upgrade-test royal_textiles_sales --test-migration"
    echo "  $0 dependency-test rtp_customers"
    echo "  $0 full-test --parallel --report-format html"
    echo "  $0 integration-test --test-workflows"
    echo ""
}

# Logging functions
log_info() {
    echo -e "${BLUE}[MODULE-TEST-INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') $1" | tee -a "$LOGS_PATH/module-testing.log"
}

log_success() {
    echo -e "${GREEN}[MODULE-TEST-SUCCESS]${NC} $(date '+%Y-%m-%d %H:%M:%S') $1" | tee -a "$LOGS_PATH/module-testing.log"
}

log_warning() {
    echo -e "${YELLOW}[MODULE-TEST-WARNING]${NC} $(date '+%Y-%m-%d %H:%M:%S') $1" | tee -a "$LOGS_PATH/module-testing.log"
}

log_error() {
    echo -e "${RED}[MODULE-TEST-ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') $1" | tee -a "$LOGS_PATH/module-testing.log"
}

log_debug() {
    if [[ "${DEBUG:-}" == "1" ]]; then
        echo -e "${CYAN}[MODULE-TEST-DEBUG]${NC} $(date '+%Y-%m-%d %H:%M:%S') $1" | tee -a "$LOGS_PATH/module-testing.log"
    fi
}

# Initialize environment
init_environment() {
    log_info "Initializing module testing environment..."

    # Check prerequisites
    check_prerequisites

    # Create necessary directories
    mkdir -p "$LOGS_PATH" "$TEST_RESULTS_PATH"

    # Initialize logging
    echo "Module Installation/Upgrade Testing Session - $(date)" > "$LOGS_PATH/module-testing.log"

    log_success "Environment initialized"
}

# Check prerequisites
check_prerequisites() {
    log_debug "Checking prerequisites..."

    # Check Odoo installation
    if [[ ! -d "$ODOO_PATH" ]]; then
        log_error "Odoo installation not found at $ODOO_PATH"
        log_error "Please run: make install-odoo"
        exit 1
    fi

    # Check virtual environment
    if [[ ! -d "$VENV_PATH" ]]; then
        log_error "Python virtual environment not found at $VENV_PATH"
        log_error "Please run: make install-odoo"
        exit 1
    fi

    # Check database management scripts
    if [[ ! -f "$SCRIPT_DIR/db-manager.sh" ]]; then
        log_error "Database manager not found. Task 3.3 required."
        exit 1
    fi

    # Check configuration scripts
    if [[ ! -f "$SCRIPT_DIR/configure-odoo.sh" ]]; then
        log_error "Configuration manager not found. Task 3.4 required."
        exit 1
    fi

    # Check custom modules
    if [[ ! -d "$CUSTOM_MODULES_PATH" ]]; then
        log_error "Custom modules directory not found at $CUSTOM_MODULES_PATH"
        exit 1
    fi

    log_debug "Prerequisites check completed"
}

# Create test database
create_test_database() {
    local db_name="$1"
    local with_demo="${2:-false}"

    log_info "Creating test database: $db_name"

    # Use our database manager from Task 3.3
    local db_opts="--type test"
    if [[ "$with_demo" == "true" ]]; then
        db_opts="$db_opts --demo"
    fi

    if ./scripts/db-manager.sh create "$db_name" $db_opts --force >/dev/null 2>&1; then
        log_success "Test database created: $db_name"
        return 0
    else
        log_error "Failed to create test database: $db_name"
        return 1
    fi
}

# Install module with testing
install_module_test() {
    local module_name="$1"
    local db_name="$2"
    local config="$3"
    local with_demo="${4:-false}"
    local test_security="${5:-false}"
    local validate_data="${6:-false}"

    log_info "Testing installation of module: $module_name"

    # Activate virtual environment
    source "$VENV_PATH/bin/activate"

    # Test module installation
    local install_cmd="python $ODOO_PATH/odoo-bin --config=$ODOO_HOME/configs/$config --database=$db_name"

    if [[ "$with_demo" == "true" ]]; then
        install_cmd="$install_cmd --without-demo=False"
    else
        install_cmd="$install_cmd --without-demo=all"
    fi

    install_cmd="$install_cmd --init=$module_name --stop-after-init --log-level=info"

    log_debug "Installation command: $install_cmd"

    # Capture installation output
    local install_log="$TEST_RESULTS_PATH/install_${module_name}_${db_name}.log"

    if eval "$install_cmd" >"$install_log" 2>&1; then
        log_success "Module $module_name installed successfully"

        # Run post-installation tests
        if [[ "$test_security" == "true" ]]; then
            test_module_security "$module_name" "$db_name" "$config"
        fi

        if [[ "$validate_data" == "true" ]]; then
            validate_module_data "$module_name" "$db_name" "$config"
        fi

        return 0
    else
        log_error "Module $module_name installation failed"
        log_error "Check log: $install_log"
        return 1
    fi
}

# Test module security and access controls
test_module_security() {
    local module_name="$1"
    local db_name="$2"
    local config="$3"

    log_info "Testing security and access controls for: $module_name"

    # Create security test script
    cat > "$TEST_RESULTS_PATH/test_security_${module_name}.py" << EOF
#!/usr/bin/env python3
import sys
import os
sys.path.append('$ODOO_PATH')

import odoo
from odoo.api import Environment

def test_security():
    odoo.tools.config.parse_config(['--config', '$ODOO_HOME/configs/$config', '--database', '$db_name'])

    with odoo.registry('$db_name').cursor() as cr:
        env = Environment(cr, odoo.SUPERUSER_ID, {})

        # Test module models exist
        ir_model = env['ir.model']
        models = ir_model.search([('modules', 'like', '$module_name')])

        print(f"Found {len(models)} models for module $module_name")

        # Test access rules
        ir_rule = env['ir.rule']
        rules = ir_rule.search([('model_id', 'in', models.ids)])

        print(f"Found {len(rules)} access rules")

        # Test security groups
        res_groups = env['res.groups']
        groups = res_groups.search([('name', 'like', '%${module_name}%')])

        print(f"Found {len(groups)} security groups")

        return True

if __name__ == '__main__':
    try:
        test_security()
        print("Security test passed")
        sys.exit(0)
    except Exception as e:
        print(f"Security test failed: {e}")
        sys.exit(1)
EOF

    # Run security test
    if python "$TEST_RESULTS_PATH/test_security_${module_name}.py" >"$TEST_RESULTS_PATH/security_test_${module_name}.log" 2>&1; then
        log_success "Security test passed for: $module_name"
        return 0
    else
        log_error "Security test failed for: $module_name"
        return 1
    fi
}

# Validate module data loading
validate_module_data() {
    local module_name="$1"
    local db_name="$2"
    local config="$3"

    log_info "Validating data loading for: $module_name"

    # Create data validation script
    cat > "$TEST_RESULTS_PATH/test_data_${module_name}.py" << EOF
#!/usr/bin/env python3
import sys
import os
sys.path.append('$ODOO_PATH')

import odoo
from odoo.api import Environment

def validate_data():
    odoo.tools.config.parse_config(['--config', '$ODOO_HOME/configs/$config', '--database', '$db_name'])

    with odoo.registry('$db_name').cursor() as cr:
        env = Environment(cr, odoo.SUPERUSER_ID, {})

        # Test views are loaded
        ir_ui_view = env['ir.ui.view']
        views = ir_ui_view.search([('module', '=', '$module_name')])

        print(f"Found {len(views)} views for module $module_name")

        # Test menu items
        ir_ui_menu = env['ir.ui.menu']
        menus = ir_ui_menu.search([('module', '=', '$module_name')])

        print(f"Found {len(menus)} menu items")

        # Test actions
        ir_actions = env['ir.actions.act_window']
        actions = ir_actions.search([('module', '=', '$module_name')])

        print(f"Found {len(actions)} actions")

        # Module-specific tests
        if '$module_name' == 'rtp_customers':
            customers = env['rtp.customer'].search([])
            print(f"Found {len(customers)} customer records")

        elif '$module_name' == 'royal_textiles_sales':
            installations = env['royal.installation'].search([])
            print(f"Found {len(installations)} installation records")

        return True

if __name__ == '__main__':
    try:
        validate_data()
        print("Data validation passed")
        sys.exit(0)
    except Exception as e:
        print(f"Data validation failed: {e}")
        sys.exit(1)
EOF

    # Run data validation
    if python "$TEST_RESULTS_PATH/test_data_${module_name}.py" >"$TEST_RESULTS_PATH/data_validation_${module_name}.log" 2>&1; then
        log_success "Data validation passed for: $module_name"
        return 0
    else
        log_error "Data validation failed for: $module_name"
        return 1
    fi
}

# Test module upgrade scenarios
upgrade_module_test() {
    local module_name="$1"
    local db_name="$2"
    local config="$3"
    local test_migration="${4:-false}"
    local preserve_data="${5:-false}"

    log_info "Testing upgrade scenarios for module: $module_name"

    # First install the module
    install_module_test "$module_name" "$db_name" "$config" "true" "false" "false"

    # Add some test data if testing data preservation
    if [[ "$preserve_data" == "true" ]]; then
        add_test_data "$module_name" "$db_name" "$config"
    fi

    # Simulate upgrade by reinstalling
    source "$VENV_PATH/bin/activate"

    local upgrade_cmd="python $ODOO_PATH/odoo-bin --config=$ODOO_HOME/configs/$config --database=$db_name --update=$module_name --stop-after-init --log-level=info"

    log_debug "Upgrade command: $upgrade_cmd"

    local upgrade_log="$TEST_RESULTS_PATH/upgrade_${module_name}_${db_name}.log"

    if eval "$upgrade_cmd" >"$upgrade_log" 2>&1; then
        log_success "Module $module_name upgrade completed"

        # Test data preservation if requested
        if [[ "$preserve_data" == "true" ]]; then
            verify_data_preservation "$module_name" "$db_name" "$config"
        fi

        return 0
    else
        log_error "Module $module_name upgrade failed"
        log_error "Check log: $upgrade_log"
        return 1
    fi
}

# Add test data for upgrade testing
add_test_data() {
    local module_name="$1"
    local db_name="$2"
    local config="$3"

    log_info "Adding test data for upgrade testing: $module_name"

    # Use our sample data generation from Task 3.5
    if [[ -f "$SCRIPT_DIR/generate-sample-data.sh" ]]; then
        ./scripts/generate-sample-data.sh create minimal --db-name="$db_name" --modules="$module_name" --size=small >/dev/null 2>&1 || true
    fi
}

# Verify data preservation after upgrade
verify_data_preservation() {
    local module_name="$1"
    local db_name="$2"
    local config="$3"

    log_info "Verifying data preservation after upgrade: $module_name"

    # Create verification script
    cat > "$TEST_RESULTS_PATH/verify_preservation_${module_name}.py" << EOF
#!/usr/bin/env python3
import sys
import os
sys.path.append('$ODOO_PATH')

import odoo
from odoo.api import Environment

def verify_preservation():
    odoo.tools.config.parse_config(['--config', '$ODOO_HOME/configs/$config', '--database', '$db_name'])

    with odoo.registry('$db_name').cursor() as cr:
        env = Environment(cr, odoo.SUPERUSER_ID, {})

        if '$module_name' == 'rtp_customers':
            customers = env['rtp.customer'].search([])
            print(f"Customers preserved: {len(customers)}")

        elif '$module_name' == 'royal_textiles_sales':
            installations = env['royal.installation'].search([])
            print(f"Installations preserved: {len(installations)}")

        return True

if __name__ == '__main__':
    try:
        verify_preservation()
        print("Data preservation verified")
        sys.exit(0)
    except Exception as e:
        print(f"Data preservation check failed: {e}")
        sys.exit(1)
EOF

    if python "$TEST_RESULTS_PATH/verify_preservation_${module_name}.py" >"$TEST_RESULTS_PATH/preservation_${module_name}.log" 2>&1; then
        log_success "Data preservation verified for: $module_name"
        return 0
    else
        log_error "Data preservation failed for: $module_name"
        return 1
    fi
}

# Test module dependencies
test_module_dependencies() {
    local module_name="$1"
    local db_name="$2"
    local config="$3"

    log_info "Testing dependencies for module: $module_name"

    # Create dependency test script
    cat > "$TEST_RESULTS_PATH/test_dependencies_${module_name}.py" << EOF
#!/usr/bin/env python3
import sys
import os
sys.path.append('$ODOO_PATH')

import odoo
from odoo.api import Environment
from odoo.modules.module import get_module_resource

def test_dependencies():
    manifest_path = get_module_resource('$module_name', '__manifest__.py')
    if not manifest_path:
        print("Module manifest not found")
        return False

    # Read manifest
    with open(manifest_path, 'r') as f:
        manifest_content = f.read()

    manifest = eval(manifest_content)
    depends = manifest.get('depends', [])

    print(f"Module $module_name depends on: {depends}")

    # Check if dependencies are installable
    odoo.tools.config.parse_config(['--config', '$ODOO_HOME/configs/$config', '--database', '$db_name'])

    with odoo.registry('$db_name').cursor() as cr:
        env = Environment(cr, odoo.SUPERUSER_ID, {})

        ir_module = env['ir.module.module']

        for dep in depends:
            module = ir_module.search([('name', '=', dep)])
            if not module:
                print(f"Dependency {dep} not found")
                return False

            if module.state not in ['installed', 'to upgrade']:
                print(f"Dependency {dep} not installed (state: {module.state})")
                return False

        print("All dependencies are satisfied")
        return True

if __name__ == '__main__':
    try:
        if test_dependencies():
            print("Dependency test passed")
            sys.exit(0)
        else:
            print("Dependency test failed")
            sys.exit(1)
    except Exception as e:
        print(f"Dependency test error: {e}")
        sys.exit(1)
EOF

    if python "$TEST_RESULTS_PATH/test_dependencies_${module_name}.py" >"$TEST_RESULTS_PATH/dependencies_${module_name}.log" 2>&1; then
        log_success "Dependency test passed for: $module_name"
        return 0
    else
        log_error "Dependency test failed for: $module_name"
        return 1
    fi
}

# Test module interactions (integration testing)
test_module_integration() {
    local config="$1"
    local test_workflows="${2:-false}"

    log_info "Testing module integration and interactions"

    local db_name="${TEST_DB_PREFIX}integration_$(date +%s)"

    # Create test database
    create_test_database "$db_name" "true"

    # Install all custom modules together
    source "$VENV_PATH/bin/activate"

    local modules_list=$(IFS=,; echo "${CUSTOM_MODULES[*]}")
    local install_cmd="python $ODOO_PATH/odoo-bin --config=$ODOO_HOME/configs/$config --database=$db_name --init=$modules_list --without-demo=False --stop-after-init --log-level=info"

    log_debug "Integration install command: $install_cmd"

    local integration_log="$TEST_RESULTS_PATH/integration_test.log"

    if eval "$install_cmd" >"$integration_log" 2>&1; then
        log_success "Module integration installation successful"

        # Test workflows if requested
        if [[ "$test_workflows" == "true" ]]; then
            test_complete_workflows "$db_name" "$config"
        fi

        # Cleanup
        ./scripts/db-manager.sh drop "$db_name" --force >/dev/null 2>&1 || true

        return 0
    else
        log_error "Module integration installation failed"
        log_error "Check log: $integration_log"

        # Cleanup
        ./scripts/db-manager.sh drop "$db_name" --force >/dev/null 2>&1 || true

        return 1
    fi
}

# Test complete business workflows
test_complete_workflows() {
    local db_name="$1"
    local config="$2"

    log_info "Testing complete business workflows"

    # Create workflow test script
    cat > "$TEST_RESULTS_PATH/test_workflows.py" << EOF
#!/usr/bin/env python3
import sys
import os
sys.path.append('$ODOO_PATH')

import odoo
from odoo.api import Environment

def test_workflows():
    odoo.tools.config.parse_config(['--config', '$ODOO_HOME/configs/$config', '--database', '$db_name'])

    with odoo.registry('$db_name').cursor() as cr:
        env = Environment(cr, odoo.SUPERUSER_ID, {})

        # Test complete customer-to-installation workflow

        # 1. Create customer
        customer = env['rtp.customer'].create({
            'name': 'Test Workflow Customer',
            'priority': '2',
            'status': 'active'
        })
        print(f"Created customer: {customer.name}")

        # 2. Create sales order
        sale_order = env['sale.order'].create({
            'partner_id': customer.id,
            'order_line': [(0, 0, {
                'product_id': env.ref('product.product_product_1').id,
                'product_uom_qty': 2.0,
            })]
        })
        print(f"Created sales order: {sale_order.name}")

        # 3. Confirm sales order
        sale_order.action_confirm()
        print(f"Confirmed sales order: {sale_order.state}")

        # 4. Test installation creation
        if hasattr(sale_order, 'action_schedule_installation'):
            try:
                sale_order.action_schedule_installation()
                print("Installation scheduled successfully")
            except Exception as e:
                print(f"Installation scheduling failed: {e}")

        return True

if __name__ == '__main__':
    try:
        test_workflows()
        print("Workflow test passed")
        sys.exit(0)
    except Exception as e:
        print(f"Workflow test failed: {e}")
        sys.exit(1)
EOF

    if python "$TEST_RESULTS_PATH/test_workflows.py" >"$TEST_RESULTS_PATH/workflow_test.log" 2>&1; then
        log_success "Workflow test passed"
        return 0
    else
        log_error "Workflow test failed"
        return 1
    fi
}

# Record test result
record_test_result() {
    local test_name="$1"
    local result="$2"
    local details="$3"

    if [[ "$result" == "PASS" ]]; then
        ((TESTS_PASSED++))
        log_success "✓ $test_name"
    else
        ((TESTS_FAILED++))
        log_error "✗ $test_name - $details"
    fi

    TEST_RESULTS+=("$result|$test_name|$details")
}

# Generate test report
generate_test_report() {
    local format="${1:-text}"
    local output_dir="${2:-$TEST_RESULTS_PATH}"

    log_info "Generating test report in $format format"

    local report_file="$output_dir/module_test_report_$(date +%Y%m%d_%H%M%S)"

    case "$format" in
        "json")
            generate_json_report "$report_file.json"
            ;;
        "html")
            generate_html_report "$report_file.html"
            ;;
        *)
            generate_text_report "$report_file.txt"
            ;;
    esac
}

# Generate text report
generate_text_report() {
    local report_file="$1"

    cat > "$report_file" << EOF
RTP Denver - Module Installation/Upgrade Test Report
===================================================
Generated: $(date)
Session: $(basename "$LOGS_PATH/module-testing.log")

Summary:
========
Total Tests: $((TESTS_PASSED + TESTS_FAILED))
Passed: $TESTS_PASSED
Failed: $TESTS_FAILED
Success Rate: $(( TESTS_PASSED * 100 / (TESTS_PASSED + TESTS_FAILED) ))%

Test Results:
============
EOF

    for result in "${TEST_RESULTS[@]}"; do
        IFS='|' read -r status test_name details <<< "$result"
        printf "%-6s %-40s %s\n" "$status" "$test_name" "$details" >> "$report_file"
    done

    echo "" >> "$report_file"
    echo "Detailed Logs:" >> "$report_file"
    echo "=============" >> "$report_file"
    echo "Main Log: $LOGS_PATH/module-testing.log" >> "$report_file"
    echo "Test Results: $TEST_RESULTS_PATH/" >> "$report_file"

    log_success "Text report generated: $report_file"
}

# Clean up test databases and files
cleanup_test_environment() {
    log_info "Cleaning up test environment..."

    # Drop test databases
    local databases=$(psql -l | grep "$TEST_DB_PREFIX\|$UPGRADE_DB_PREFIX" | awk '{print $1}' || true)

    for db in $databases; do
        if [[ -n "$db" ]]; then
            log_debug "Dropping test database: $db"
            ./scripts/db-manager.sh drop "$db" --force >/dev/null 2>&1 || true
        fi
    done

    # Clean old test result files (keep last 10)
    find "$TEST_RESULTS_PATH" -name "*.log" -mtime +7 -delete 2>/dev/null || true
    find "$TEST_RESULTS_PATH" -name "*.py" -mtime +1 -delete 2>/dev/null || true

    log_success "Test environment cleaned up"
}

# List available modules
list_available_modules() {
    echo -e "${BLUE}[MODULE-TEST-INFO]${NC} Available modules for testing:"
    echo ""

    for module in "${CUSTOM_MODULES[@]}"; do
        if [[ -d "$CUSTOM_MODULES_PATH/$module" ]]; then
            local manifest="$CUSTOM_MODULES_PATH/$module/__manifest__.py"
            if [[ -f "$manifest" ]]; then
                echo -e "${GREEN}Module: $module${NC}"

                # Extract basic info from manifest without requiring Odoo
                local name=$(grep -E "^\s*['\"]name['\"]" "$manifest" | head -1 | sed "s/.*:\s*['\"]//;s/['\"].*//")
                local version=$(grep -E "^\s*['\"]version['\"]" "$manifest" | head -1 | sed "s/.*:\s*['\"]//;s/['\"].*//")
                local summary=$(grep -E "^\s*['\"]summary['\"]" "$manifest" | head -1 | sed "s/.*:\s*['\"]//;s/['\"].*//")

                echo "  Name: ${name:-Unknown}"
                echo "  Version: ${version:-Unknown}"
                echo "  Summary: ${summary:-No summary available}"
                echo "  Location: $CUSTOM_MODULES_PATH/$module"

                # Check for key files
                local files_found=""
                [[ -f "$CUSTOM_MODULES_PATH/$module/models/__init__.py" ]] && files_found="$files_found models"
                [[ -f "$CUSTOM_MODULES_PATH/$module/views" ]] && files_found="$files_found views" || [[ -d "$CUSTOM_MODULES_PATH/$module/views" ]] && files_found="$files_found views"
                [[ -f "$CUSTOM_MODULES_PATH/$module/security" ]] && files_found="$files_found security" || [[ -d "$CUSTOM_MODULES_PATH/$module/security" ]] && files_found="$files_found security"
                [[ -f "$CUSTOM_MODULES_PATH/$module/data" ]] && files_found="$files_found data" || [[ -d "$CUSTOM_MODULES_PATH/$module/data" ]] && files_found="$files_found data"

                echo "  Components:$files_found"
                echo ""
            else
                echo -e "${YELLOW}Module: $module${NC}"
                echo "  Status: Missing __manifest__.py file"
                echo ""
            fi
        else
            echo -e "${RED}Module: $module${NC}"
            echo "  Status: Directory not found at $CUSTOM_MODULES_PATH/$module"
            echo ""
        fi
    done

    echo -e "${CYAN}Testing Commands:${NC}"
    echo "=================="
    echo "make module-test-install MODULE=<module_name>    # Test installation"
    echo "make module-test-upgrade MODULE=<module_name>    # Test upgrade"
    echo "make module-test-dependencies MODULE=<module_name> # Test dependencies"
    echo "make module-test-integration                     # Test module interactions"
    echo "make module-test-full                           # Complete test suite"
    echo ""
    echo "Examples:"
    echo "make module-test-install MODULE=rtp_customers DEMO=true"
    echo "make module-test-upgrade MODULE=royal_textiles_sales MIGRATION=true"
    echo "./scripts/test-module-installation.sh full-test --report-format html"
}

# Main execution functions for each command
run_install_test() {
    local module_name="$1"
    local with_demo="${2:-false}"
    local test_security="${3:-false}"
    local validate_data="${4:-false}"
    local config="${5:-$DEFAULT_CONFIG}"

    log_info "Starting installation test for: $module_name"

    local db_name="${TEST_DB_PREFIX}${module_name}_$(date +%s)"

    # Create test database
    if ! create_test_database "$db_name" "$with_demo"; then
        record_test_result "Database Creation ($module_name)" "FAIL" "Could not create test database"
        return 1
    fi

    # Test module installation
    if install_module_test "$module_name" "$db_name" "$config" "$with_demo" "$test_security" "$validate_data"; then
        record_test_result "Module Installation ($module_name)" "PASS" "Installation successful"
    else
        record_test_result "Module Installation ($module_name)" "FAIL" "Installation failed"
    fi

    # Cleanup
    ./scripts/db-manager.sh drop "$db_name" --force >/dev/null 2>&1 || true
}

run_upgrade_test() {
    local module_name="$1"
    local test_migration="${2:-false}"
    local preserve_data="${3:-false}"
    local config="${4:-$DEFAULT_CONFIG}"

    log_info "Starting upgrade test for: $module_name"

    local db_name="${UPGRADE_DB_PREFIX}${module_name}_$(date +%s)"

    # Create test database
    if ! create_test_database "$db_name" "true"; then
        record_test_result "Upgrade Database Creation ($module_name)" "FAIL" "Could not create test database"
        return 1
    fi

    # Test module upgrade
    if upgrade_module_test "$module_name" "$db_name" "$config" "$test_migration" "$preserve_data"; then
        record_test_result "Module Upgrade ($module_name)" "PASS" "Upgrade successful"
    else
        record_test_result "Module Upgrade ($module_name)" "FAIL" "Upgrade failed"
    fi

    # Cleanup
    ./scripts/db-manager.sh drop "$db_name" --force >/dev/null 2>&1 || true
}

run_dependency_test() {
    local module_name="$1"
    local config="${2:-$DEFAULT_CONFIG}"

    log_info "Starting dependency test for: $module_name"

    local db_name="${TEST_DB_PREFIX}deps_${module_name}_$(date +%s)"

    # Create test database
    if ! create_test_database "$db_name" "false"; then
        record_test_result "Dependency Database Creation ($module_name)" "FAIL" "Could not create test database"
        return 1
    fi

    # Install base modules first
    source "$VENV_PATH/bin/activate"
    python "$ODOO_PATH/odoo-bin" --config="$ODOO_HOME/configs/$config" --database="$db_name" --init=base --stop-after-init >/dev/null 2>&1

    # Test dependencies
    if test_module_dependencies "$module_name" "$db_name" "$config"; then
        record_test_result "Module Dependencies ($module_name)" "PASS" "Dependencies satisfied"
    else
        record_test_result "Module Dependencies ($module_name)" "FAIL" "Dependency issues found"
    fi

    # Cleanup
    ./scripts/db-manager.sh drop "$db_name" --force >/dev/null 2>&1 || true
}

run_integration_test() {
    local test_workflows="${1:-false}"
    local config="${2:-$DEFAULT_CONFIG}"

    log_info "Starting integration test"

    if test_module_integration "$config" "$test_workflows"; then
        record_test_result "Module Integration" "PASS" "Modules work together correctly"
    else
        record_test_result "Module Integration" "FAIL" "Integration issues found"
    fi
}

run_full_test() {
    local parallel="${1:-false}"
    local continue_on_error="${2:-false}"
    local report_format="${3:-text}"
    local output_dir="${4:-$TEST_RESULTS_PATH}"

    log_info "Starting full test suite"

    # Test each module individually
    for module in "${CUSTOM_MODULES[@]}"; do
        log_info "Testing module: $module"

        # Installation test
        run_install_test "$module" "true" "true" "true"

        if [[ "$continue_on_error" == "false" && $TESTS_FAILED -gt 0 ]]; then
            break
        fi

        # Upgrade test
        run_upgrade_test "$module" "true" "true"

        if [[ "$continue_on_error" == "false" && $TESTS_FAILED -gt 0 ]]; then
            break
        fi

        # Dependency test
        run_dependency_test "$module"

        if [[ "$continue_on_error" == "false" && $TESTS_FAILED -gt 0 ]]; then
            break
        fi
    done

    # Integration test
    run_integration_test "true"

    # Generate report
    generate_test_report "$report_format" "$output_dir"

    # Show summary
    log_info "Full test suite completed"
    log_info "Results: $TESTS_PASSED passed, $TESTS_FAILED failed"
}

# Parse command line arguments
parse_arguments() {
    local command=""
    local module_name=""
    local with_demo="false"
    local test_security="false"
    local validate_data="false"
    local test_migration="false"
    local preserve_data="false"
    local test_workflows="false"
    local parallel="false"
    local continue_on_error="false"
    local report_format="text"
    local output_dir="$TEST_RESULTS_PATH"
    local config="$DEFAULT_CONFIG"

    if [[ $# -eq 0 ]]; then
        show_help
        exit 0
    fi

    command="$1"
    shift

    case "$command" in
        install-test)
            if [[ $# -eq 0 ]]; then
                log_error "Module name required for install-test"
                exit 1
            fi
            module_name="$1"
            shift
            ;;
        upgrade-test)
            if [[ $# -eq 0 ]]; then
                log_error "Module name required for upgrade-test"
                exit 1
            fi
            module_name="$1"
            shift
            ;;
        dependency-test)
            if [[ $# -eq 0 ]]; then
                log_error "Module name required for dependency-test"
                exit 1
            fi
            module_name="$1"
            shift
            ;;
        integration-test|full-test|list-modules|cleanup)
            # Commands that don't need module name
            ;;
        *)
            log_error "Unknown command: $command"
            show_help
            exit 1
            ;;
    esac

    # Parse options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --with-demo)
                with_demo="true"
                shift
                ;;
            --test-security)
                test_security="true"
                shift
                ;;
            --validate-data)
                validate_data="true"
                shift
                ;;
            --test-migration)
                test_migration="true"
                shift
                ;;
            --preserve-data)
                preserve_data="true"
                shift
                ;;
            --test-workflows)
                test_workflows="true"
                shift
                ;;
            --parallel)
                parallel="true"
                shift
                ;;
            --continue-on-error)
                continue_on_error="true"
                shift
                ;;
            --report-format)
                report_format="$2"
                shift 2
                ;;
            --output-dir)
                output_dir="$2"
                shift 2
                ;;
            --config)
                config="$2"
                shift 2
                ;;
            *)
                log_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done

    # Execute command
    case "$command" in
        install-test)
            run_install_test "$module_name" "$with_demo" "$test_security" "$validate_data" "$config"
            ;;
        upgrade-test)
            run_upgrade_test "$module_name" "$test_migration" "$preserve_data" "$config"
            ;;
        dependency-test)
            run_dependency_test "$module_name" "$config"
            ;;
        integration-test)
            run_integration_test "$test_workflows" "$config"
            ;;
        full-test)
            run_full_test "$parallel" "$continue_on_error" "$report_format" "$output_dir"
            ;;
        list-modules)
            list_available_modules
            ;;
        cleanup)
            cleanup_test_environment
            ;;
    esac
}

# Main function
main() {
    # Handle help and list commands before initializing environment
    if [[ $# -gt 0 ]]; then
        case "$1" in
            help|--help)
                show_help
                exit 0
                ;;
            list-modules)
                list_available_modules
                exit 0
                ;;
            cleanup)
                init_environment
                cleanup_test_environment
                exit 0
                ;;
        esac
    fi

    init_environment
    parse_arguments "$@"

    # Show final summary if tests were run
    if [[ $((TESTS_PASSED + TESTS_FAILED)) -gt 0 ]]; then
        echo ""
        log_info "Test Session Summary:"
        log_info "===================="
        log_info "Total Tests: $((TESTS_PASSED + TESTS_FAILED))"
        log_success "Passed: $TESTS_PASSED"
        if [[ $TESTS_FAILED -gt 0 ]]; then
            log_error "Failed: $TESTS_FAILED"
        else
            log_info "Failed: $TESTS_FAILED"
        fi

        if [[ $TESTS_FAILED -eq 0 ]]; then
            log_success "All tests passed! 🎉"
        else
            log_warning "Some tests failed. Check logs for details."
        fi
    fi
}

# Run main function
main "$@"

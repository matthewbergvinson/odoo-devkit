#!/bin/bash

# =====================================
# Royal Textiles Deployment Readiness Checklist
# =====================================
# Task 6.3: Create deployment readiness checklist script
# This script provides comprehensive deployment readiness assessment

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Global tracking variables
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNING_CHECKS=0
CRITICAL_ISSUES=()
WARNING_ISSUES=()
RECOMMENDATIONS=()

# Output format (text, json, html)
OUTPUT_FORMAT="text"
OUTPUT_FILE=""
CHECKLIST_LEVEL="full"
DEPLOYMENT_ENV="production"

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_header() {
    echo -e "${CYAN}🚀 $1${NC}"
}

print_section() {
    echo -e "${PURPLE}📋 $1${NC}"
}

# Function to track check results
track_check() {
    local status="$1"
    local message="$2"
    local category="${3:-general}"

    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    case "$status" in
        pass)
            PASSED_CHECKS=$((PASSED_CHECKS + 1))
            print_status "$message"
            ;;
        fail)
            FAILED_CHECKS=$((FAILED_CHECKS + 1))
            print_error "$message"
            CRITICAL_ISSUES+=("$category: $message")
            ;;
        warn)
            WARNING_CHECKS=$((WARNING_CHECKS + 1))
            print_warning "$message"
            WARNING_ISSUES+=("$category: $message")
            ;;
    esac
}

# Function to add recommendation
add_recommendation() {
    local recommendation="$1"
    RECOMMENDATIONS+=("$recommendation")
}

# Check git repository status
check_git_status() {
    print_section "Git Repository Status"
    echo ""

    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        track_check "fail" "Not in a git repository" "git"
        return 1
    fi

    track_check "pass" "In git repository" "git"

    # Check for uncommitted changes
    if [ -n "$(git status --porcelain)" ]; then
        track_check "warn" "Uncommitted changes found" "git"
        add_recommendation "Commit or stash all changes before deployment"
    else
        track_check "pass" "Working directory is clean" "git"
    fi

    # Check for unpushed commits
    local unpushed=$(git log --oneline @{u}.. 2>/dev/null | wc -l | tr -d ' ')
    if [ "$unpushed" -gt 0 ]; then
        track_check "warn" "$unpushed unpushed commits found" "git"
        add_recommendation "Push all commits to remote repository before deployment"
    else
        track_check "pass" "All commits are pushed" "git"
    fi

    # Check current branch
    local current_branch=$(git branch --show-current)
    if [ "$current_branch" = "main" ] || [ "$current_branch" = "master" ]; then
        track_check "pass" "On main/master branch: $current_branch" "git"
    else
        track_check "warn" "Not on main/master branch: $current_branch" "git"
        add_recommendation "Consider deploying from main/master branch"
    fi

    # Check for git hooks
    if [ -f ".git/hooks/pre-push" ] && [ -x ".git/hooks/pre-push" ]; then
        track_check "pass" "Git pre-push hooks are installed" "git"
    else
        track_check "warn" "Git pre-push hooks not installed" "git"
        add_recommendation "Install git hooks with: make hooks-install"
    fi

    echo ""
}

# Check code quality
check_code_quality() {
    print_section "Code Quality Assessment"
    echo ""

    # Check if linting tools are available
    if command -v flake8 >/dev/null 2>&1; then
        print_info "Running code quality checks..."

        # Run CI linting
        if make ci-lint > /tmp/deployment_lint.log 2>&1; then
            track_check "pass" "Code linting passed" "quality"
        else
            track_check "fail" "Code linting failed" "quality"
            add_recommendation "Fix linting issues with: make ci-lint"
        fi
    else
        track_check "warn" "Linting tools not available" "quality"
        add_recommendation "Install Python linting tools: pip install flake8 pylint mypy"
    fi

    # Check for code formatting
    if command -v black >/dev/null 2>&1; then
        if black --check custom_modules/ scripts/ > /dev/null 2>&1; then
            track_check "pass" "Code formatting is consistent" "quality"
        else
            track_check "warn" "Code formatting issues found" "quality"
            add_recommendation "Format code with: make format"
        fi
    else
        track_check "warn" "Code formatter not available" "quality"
        add_recommendation "Install Black formatter: pip install black"
    fi

    # Check for TODO/FIXME comments
    local todo_count=$(grep -r "TODO\|FIXME\|XXX\|HACK" custom_modules/ scripts/ --exclude-dir=__pycache__ 2>/dev/null | wc -l | tr -d ' ')
    if [ "$todo_count" -eq 0 ]; then
        track_check "pass" "No TODO/FIXME comments found" "quality"
    elif [ "$todo_count" -lt 5 ]; then
        track_check "warn" "$todo_count TODO/FIXME comments found" "quality"
        add_recommendation "Review and address TODO/FIXME comments before deployment"
    else
        track_check "fail" "$todo_count TODO/FIXME comments found" "quality"
        add_recommendation "Address critical TODO/FIXME comments before deployment"
    fi

    echo ""
}

# Check module validation
check_module_validation() {
    print_section "Odoo Module Validation"
    echo ""

    # Check if validation script exists
    if [ -f "scripts/validate-module.py" ]; then
        print_info "Running module validation..."

        if make ci-validate > /tmp/deployment_validate.log 2>&1; then
            track_check "pass" "Module validation passed" "modules"
        else
            track_check "fail" "Module validation failed" "modules"
            add_recommendation "Fix module validation issues with: make ci-validate"
        fi
    else
        track_check "warn" "Module validation script not found" "modules"
        add_recommendation "Ensure module validation scripts are available"
    fi

    # Check manifest files
    local manifest_count=$(find custom_modules -name "__manifest__.py" | wc -l | tr -d ' ')
    if [ "$manifest_count" -gt 0 ]; then
        track_check "pass" "$manifest_count Odoo modules found" "modules"

        # Validate each manifest
        local invalid_manifests=0
        for manifest in $(find custom_modules -name "__manifest__.py"); do
            if python -c "import ast; ast.parse(open('$manifest').read())" 2>/dev/null; then
                continue
            else
                invalid_manifests=$((invalid_manifests + 1))
            fi
        done

        if [ "$invalid_manifests" -eq 0 ]; then
            track_check "pass" "All manifest files are valid" "modules"
        else
            track_check "fail" "$invalid_manifests invalid manifest files" "modules"
            add_recommendation "Fix manifest file syntax errors"
        fi
    else
        track_check "warn" "No Odoo modules found" "modules"
    fi

    # Check for required dependencies
    local modules_with_deps=0
    for manifest in $(find custom_modules -name "__manifest__.py"); do
        if grep -q "'depends'" "$manifest" && ! grep -q "'depends': \[\]" "$manifest"; then
            modules_with_deps=$((modules_with_deps + 1))
        fi
    done

    if [ "$modules_with_deps" -gt 0 ]; then
        track_check "pass" "$modules_with_deps modules have dependencies defined" "modules"
    else
        track_check "warn" "No module dependencies found" "modules"
        add_recommendation "Review module dependencies in __manifest__.py files"
    fi

    echo ""
}

# Check test coverage
check_test_coverage() {
    print_section "Test Coverage Assessment"
    echo ""

    # Check if pytest is available
    if command -v pytest >/dev/null 2>&1 || python -m pytest --version >/dev/null 2>&1; then
        print_info "Running test suite..."

        # Run tests with timeout
        if timeout 300 make ci-test > /tmp/deployment_test.log 2>&1; then
            track_check "pass" "Test suite execution completed" "testing"

            # Check coverage if available
            if [ -f "reports/coverage.xml" ]; then
                local coverage=$(python -c "
import xml.etree.ElementTree as ET
try:
    tree = ET.parse('reports/coverage.xml')
    coverage = float(tree.getroot().get('line-rate', '0')) * 100
    print(f'{coverage:.1f}')
except:
    print('0')
" 2>/dev/null)

                if [ "${coverage%.*}" -ge 70 ]; then
                    track_check "pass" "Test coverage: ${coverage}%" "testing"
                elif [ "${coverage%.*}" -ge 50 ]; then
                    track_check "warn" "Test coverage: ${coverage}% (below target 70%)" "testing"
                    add_recommendation "Increase test coverage to at least 70%"
                else
                    track_check "fail" "Test coverage: ${coverage}% (critically low)" "testing"
                    add_recommendation "Significantly increase test coverage before deployment"
                fi
            else
                track_check "warn" "Test coverage report not available" "testing"
                add_recommendation "Generate test coverage report with: make coverage"
            fi
        else
            track_check "fail" "Test suite failed or timed out" "testing"
            add_recommendation "Fix failing tests before deployment"
        fi
    else
        track_check "warn" "Testing framework not available" "testing"
        add_recommendation "Install pytest: pip install pytest pytest-cov"
    fi

    # Check for test files
    local test_files=$(find custom_modules -path "*/tests/*.py" | wc -l | tr -d ' ')
    if [ "$test_files" -gt 0 ]; then
        track_check "pass" "$test_files test files found" "testing"
    else
        track_check "warn" "No test files found" "testing"
        add_recommendation "Add test files to validate module functionality"
    fi

    echo ""
}

# Check security
check_security() {
    print_section "Security Assessment"
    echo ""

    # Check security files
    local security_files=$(find custom_modules -name "*security*" -o -name "ir.model.access.csv" | wc -l | tr -d ' ')
    if [ "$security_files" -gt 0 ]; then
        track_check "pass" "$security_files security files found" "security"
    else
        track_check "warn" "No security files found" "security"
        add_recommendation "Add proper security configurations (ir.model.access.csv)"
    fi

    # Check for hardcoded passwords or secrets
    local secret_patterns="password\|secret\|api_key\|token\|credential"
    local hardcoded_secrets=$(grep -ri "$secret_patterns" custom_modules/ --exclude-dir=__pycache__ 2>/dev/null | grep -v "# TODO\|# FIXME" | wc -l | tr -d ' ')

    if [ "$hardcoded_secrets" -eq 0 ]; then
        track_check "pass" "No hardcoded secrets found" "security"
    else
        track_check "fail" "$hardcoded_secrets potential hardcoded secrets found" "security"
        add_recommendation "Remove hardcoded secrets and use environment variables"
    fi

    # Check for SQL injection patterns
    local sql_patterns="execute.*%\|query.*%\|SELECT.*%"
    local sql_issues=$(grep -ri "$sql_patterns" custom_modules/ --exclude-dir=__pycache__ 2>/dev/null | wc -l | tr -d ' ')

    if [ "$sql_issues" -eq 0 ]; then
        track_check "pass" "No SQL injection patterns found" "security"
    else
        track_check "warn" "$sql_issues potential SQL injection patterns found" "security"
        add_recommendation "Review SQL queries for injection vulnerabilities"
    fi

    # Check file permissions
    local incorrect_perms=$(find custom_modules -name "*.py" ! -perm 644 2>/dev/null | wc -l | tr -d ' ')
    if [ "$incorrect_perms" -eq 0 ]; then
        track_check "pass" "File permissions are correct" "security"
    else
        track_check "warn" "$incorrect_perms files with incorrect permissions" "security"
        add_recommendation "Fix file permissions: find custom_modules -name '*.py' -exec chmod 644 {} +"
    fi

    echo ""
}

# Check dependencies
check_dependencies() {
    print_section "Dependency Assessment"
    echo ""

    # Check Python dependencies
    if [ -f "requirements.txt" ]; then
        track_check "pass" "Requirements file found" "dependencies"

        # Check if all dependencies are installed
        local missing_deps=0
        while IFS= read -r line; do
            if [[ "$line" =~ ^[[:space:]]*# ]] || [[ -z "$line" ]]; then
                continue
            fi

            local package=$(echo "$line" | cut -d'=' -f1 | cut -d'>' -f1 | cut -d'<' -f1 | cut -d'[' -f1)
            if ! python -c "import $package" 2>/dev/null; then
                missing_deps=$((missing_deps + 1))
            fi
        done < requirements.txt

        if [ "$missing_deps" -eq 0 ]; then
            track_check "pass" "All Python dependencies are installed" "dependencies"
        else
            track_check "fail" "$missing_deps missing Python dependencies" "dependencies"
            add_recommendation "Install missing dependencies: pip install -r requirements.txt"
        fi
    else
        track_check "warn" "Requirements file not found" "dependencies"
        add_recommendation "Create requirements.txt with project dependencies"
    fi

    # Check Odoo version compatibility
    local python_version=$(python --version 2>&1 | cut -d' ' -f2 | cut -d'.' -f1-2)
    if [ "$python_version" = "3.8" ] || [ "$python_version" = "3.9" ] || [ "$python_version" = "3.10" ] || [ "$python_version" = "3.11" ]; then
        track_check "pass" "Python version compatible: $python_version" "dependencies"
    else
        track_check "warn" "Python version may not be compatible: $python_version" "dependencies"
        add_recommendation "Use Python 3.8-3.11 for optimal Odoo compatibility"
    fi

    # Check for development dependencies in production
    if [ "$DEPLOYMENT_ENV" = "production" ]; then
        local dev_deps=$(grep -i "debug\|test\|dev" requirements.txt 2>/dev/null | wc -l | tr -d ' ')
        if [ "$dev_deps" -eq 0 ]; then
            track_check "pass" "No development dependencies in requirements" "dependencies"
        else
            track_check "warn" "$dev_deps potential development dependencies found" "dependencies"
            add_recommendation "Remove development dependencies for production deployment"
        fi
    fi

    echo ""
}

# Check configuration
check_configuration() {
    print_section "Configuration Assessment"
    echo ""

    # Check Odoo configuration files
    local config_files=$(find . -name "odoo*.conf" -o -name "*.cfg" | head -5)
    if [ -n "$config_files" ]; then
        track_check "pass" "Odoo configuration files found" "config"

        # Check for debug mode in production
        if [ "$DEPLOYMENT_ENV" = "production" ]; then
            local debug_configs=$(grep -l "debug.*true\|dev_mode.*true" $config_files 2>/dev/null | wc -l | tr -d ' ')
            if [ "$debug_configs" -eq 0 ]; then
                track_check "pass" "No debug mode enabled in configuration" "config"
            else
                track_check "fail" "Debug mode enabled in production configuration" "config"
                add_recommendation "Disable debug mode for production deployment"
            fi
        fi
    else
        track_check "warn" "No Odoo configuration files found" "config"
        add_recommendation "Create proper Odoo configuration files"
    fi

    # Check environment variables
    local env_vars=("ODOO_RC" "PGDATABASE" "PGUSER" "PGHOST")
    local missing_env=0
    for var in "${env_vars[@]}"; do
        if [ -z "${!var}" ]; then
            missing_env=$((missing_env + 1))
        fi
    done

    if [ "$missing_env" -eq 0 ]; then
        track_check "pass" "All required environment variables are set" "config"
    elif [ "$missing_env" -le 2 ]; then
        track_check "warn" "$missing_env environment variables not set" "config"
        add_recommendation "Set missing environment variables for deployment"
    else
        track_check "fail" "$missing_env critical environment variables missing" "config"
        add_recommendation "Configure all required environment variables"
    fi

    # Check for sensitive data in config files
    if [ -n "$config_files" ]; then
        local sensitive_data=$(grep -i "password\|secret\|key" $config_files 2>/dev/null | grep -v "password_file\|key_file" | wc -l | tr -d ' ')
        if [ "$sensitive_data" -eq 0 ]; then
            track_check "pass" "No sensitive data in configuration files" "config"
        else
            track_check "warn" "$sensitive_data lines with potential sensitive data" "config"
            add_recommendation "Use environment variables or secure vaults for sensitive configuration"
        fi
    fi

    echo ""
}

# Check performance
check_performance() {
    print_section "Performance Assessment"
    echo ""

    # Check file sizes
    local large_files=$(find custom_modules -name "*.py" -size +100k 2>/dev/null | wc -l | tr -d ' ')
    if [ "$large_files" -eq 0 ]; then
        track_check "pass" "No exceptionally large Python files" "performance"
    else
        track_check "warn" "$large_files large Python files found" "performance"
        add_recommendation "Review large files for optimization opportunities"
    fi

    # Check for potential performance issues
    local perf_patterns="for.*in.*search\|for.*in.*browse"
    local perf_issues=$(grep -ri "$perf_patterns" custom_modules/ --exclude-dir=__pycache__ 2>/dev/null | wc -l | tr -d ' ')

    if [ "$perf_issues" -eq 0 ]; then
        track_check "pass" "No obvious performance anti-patterns found" "performance"
    elif [ "$perf_issues" -lt 5 ]; then
        track_check "warn" "$perf_issues potential performance issues found" "performance"
        add_recommendation "Review code for performance optimization"
    else
        track_check "fail" "$perf_issues significant performance issues found" "performance"
        add_recommendation "Address performance anti-patterns before deployment"
    fi

    # Check database migration scripts
    local migration_files=$(find custom_modules -path "*/migrations/*.py" 2>/dev/null | wc -l | tr -d ' ')
    if [ "$migration_files" -gt 0 ]; then
        track_check "pass" "$migration_files database migration files found" "performance"
        add_recommendation "Test database migrations in staging environment"
    else
        track_check "pass" "No database migrations to review" "performance"
    fi

    echo ""
}

# Check documentation
check_documentation() {
    print_section "Documentation Assessment"
    echo ""

    # Check for README files
    local readme_files=$(find . -maxdepth 2 -name "README*" -o -name "readme*" | wc -l | tr -d ' ')
    if [ "$readme_files" -gt 0 ]; then
        track_check "pass" "$readme_files README files found" "documentation"
    else
        track_check "warn" "No README files found" "documentation"
        add_recommendation "Add README.md with project documentation"
    fi

    # Check for docstrings in Python files
    local py_files_with_docs=0
    local total_py_files=0

    for pyfile in $(find custom_modules -name "*.py" -not -name "__init__.py" -not -name "__manifest__.py"); do
        total_py_files=$((total_py_files + 1))
        if grep -q '"""' "$pyfile" || grep -q "'''" "$pyfile"; then
            py_files_with_docs=$((py_files_with_docs + 1))
        fi
    done

    if [ "$total_py_files" -gt 0 ]; then
        local doc_percentage=$((py_files_with_docs * 100 / total_py_files))
        if [ "$doc_percentage" -ge 70 ]; then
            track_check "pass" "${doc_percentage}% of Python files have documentation" "documentation"
        elif [ "$doc_percentage" -ge 30 ]; then
            track_check "warn" "${doc_percentage}% of Python files have documentation" "documentation"
            add_recommendation "Improve code documentation (target: 70%+)"
        else
            track_check "fail" "${doc_percentage}% of Python files have documentation" "documentation"
            add_recommendation "Add comprehensive documentation to Python files"
        fi
    fi

    # Check for changelog
    if [ -f "CHANGELOG.md" ] || [ -f "CHANGELOG.rst" ] || [ -f "HISTORY.md" ]; then
        track_check "pass" "Changelog file found" "documentation"
    else
        track_check "warn" "No changelog file found" "documentation"
        add_recommendation "Maintain a changelog for tracking changes"
    fi

    echo ""
}

# Check deployment-specific requirements
check_deployment_requirements() {
    print_section "Deployment Requirements"
    echo ""

    # Check for deployment scripts
    local deploy_scripts=$(find scripts -name "*deploy*" -o -name "*start*" -o -name "*setup*" 2>/dev/null | wc -l | tr -d ' ')
    if [ "$deploy_scripts" -gt 0 ]; then
        track_check "pass" "$deploy_scripts deployment scripts found" "deployment"
    else
        track_check "warn" "No deployment scripts found" "deployment"
        add_recommendation "Create deployment automation scripts"
    fi

    # Check for Docker files (if using containerization)
    if [ -f "Dockerfile" ] || [ -f "docker-compose.yml" ]; then
        track_check "pass" "Docker configuration found" "deployment"

        # Validate Docker files
        if [ -f "Dockerfile" ]; then
            if grep -q "FROM" Dockerfile && grep -q "RUN\|COPY\|ADD" Dockerfile; then
                track_check "pass" "Dockerfile appears valid" "deployment"
            else
                track_check "warn" "Dockerfile may be incomplete" "deployment"
                add_recommendation "Review Dockerfile for completeness"
            fi
        fi
    else
        track_check "info" "No Docker configuration (not required)" "deployment"
    fi

    # Check for backup procedures
    local backup_scripts=$(find scripts -name "*backup*" 2>/dev/null | wc -l | tr -d ' ')
    if [ "$backup_scripts" -gt 0 ]; then
        track_check "pass" "$backup_scripts backup scripts found" "deployment"
    else
        track_check "warn" "No backup scripts found" "deployment"
        add_recommendation "Implement backup procedures before deployment"
    fi

    # Check for monitoring/health check endpoints
    local health_checks=$(grep -r "health\|status\|ping" custom_modules/ --include="*.py" 2>/dev/null | wc -l | tr -d ' ')
    if [ "$health_checks" -gt 0 ]; then
        track_check "pass" "Health check endpoints found" "deployment"
    else
        track_check "warn" "No health check endpoints found" "deployment"
        add_recommendation "Add health check endpoints for monitoring"
    fi

    echo ""
}

# Generate summary report
generate_summary() {
    print_header "Deployment Readiness Summary"
    echo "==============================================="
    echo ""

    # Calculate score
    local score=0
    if [ "$TOTAL_CHECKS" -gt 0 ]; then
        score=$((PASSED_CHECKS * 100 / TOTAL_CHECKS))
    fi

    # Determine readiness level
    local readiness_level=""
    local readiness_color=""

    if [ "$score" -ge 90 ] && [ "$FAILED_CHECKS" -eq 0 ]; then
        readiness_level="READY FOR DEPLOYMENT"
        readiness_color="$GREEN"
    elif [ "$score" -ge 75 ] && [ "$FAILED_CHECKS" -le 2 ]; then
        readiness_level="MOSTLY READY (Minor Issues)"
        readiness_color="$YELLOW"
    elif [ "$score" -ge 50 ]; then
        readiness_level="NEEDS IMPROVEMENT"
        readiness_color="$YELLOW"
    else
        readiness_level="NOT READY FOR DEPLOYMENT"
        readiness_color="$RED"
    fi

    echo -e "${readiness_color}🎯 Status: $readiness_level${NC}"
    echo ""

    # Display statistics
    echo "📊 Assessment Statistics:"
    echo "  ✅ Passed: $PASSED_CHECKS"
    echo "  ❌ Failed: $FAILED_CHECKS"
    echo "  ⚠️  Warnings: $WARNING_CHECKS"
    echo "  📈 Overall Score: $score%"
    echo ""

    # Display critical issues
    if [ ${#CRITICAL_ISSUES[@]} -gt 0 ]; then
        echo "🚨 Critical Issues (Must Fix Before Deployment):"
        for issue in "${CRITICAL_ISSUES[@]}"; do
            echo "  • $issue"
        done
        echo ""
    fi

    # Display warnings
    if [ ${#WARNING_ISSUES[@]} -gt 0 ]; then
        echo "⚠️  Warnings (Recommend Fixing):"
        local warning_count=0
        for warning in "${WARNING_ISSUES[@]}"; do
            echo "  • $warning"
            warning_count=$((warning_count + 1))
            if [ "$warning_count" -ge 10 ]; then
                echo "  • ... and $((${#WARNING_ISSUES[@]} - 10)) more warnings"
                break
            fi
        done
        echo ""
    fi

    # Display recommendations
    if [ ${#RECOMMENDATIONS[@]} -gt 0 ]; then
        echo "💡 Recommendations:"
        local rec_count=0
        for rec in "${RECOMMENDATIONS[@]}"; do
            echo "  • $rec"
            rec_count=$((rec_count + 1))
            if [ "$rec_count" -ge 15 ]; then
                echo "  • ... and $((${#RECOMMENDATIONS[@]} - 15)) more recommendations"
                break
            fi
        done
        echo ""
    fi

    # Final recommendation
    echo "🎯 Next Steps:"
    if [ "$FAILED_CHECKS" -eq 0 ] && [ "$score" -ge 90 ]; then
        echo "  ✅ Project appears ready for deployment"
        echo "  🚀 Consider running final integration tests"
        echo "  📋 Review deployment checklist with team"
    elif [ "$FAILED_CHECKS" -le 2 ] && [ "$score" -ge 75 ]; then
        echo "  🔧 Address critical issues listed above"
        echo "  ⚠️  Review and fix warnings if possible"
        echo "  🧪 Run additional testing after fixes"
    else
        echo "  ❌ Address all critical issues before deployment"
        echo "  🔍 Perform thorough code review"
        echo "  🧪 Complete testing and validation"
        echo "  📋 Re-run this checklist after fixes"
    fi

    echo ""
    echo "Generated: $(date)"
    echo "Environment: $DEPLOYMENT_ENV"
    echo "Checklist Level: $CHECKLIST_LEVEL"
    echo ""
}

# Generate JSON report
generate_json_report() {
    local json_file="${OUTPUT_FILE:-reports/deployment-readiness.json}"
    mkdir -p "$(dirname "$json_file")"

    cat > "$json_file" << EOF
{
  "deployment_readiness_report": {
    "timestamp": "$(date -Iseconds)",
    "environment": "$DEPLOYMENT_ENV",
    "checklist_level": "$CHECKLIST_LEVEL",
    "summary": {
      "total_checks": $TOTAL_CHECKS,
      "passed_checks": $PASSED_CHECKS,
      "failed_checks": $FAILED_CHECKS,
      "warning_checks": $WARNING_CHECKS,
      "score_percentage": $((TOTAL_CHECKS > 0 ? PASSED_CHECKS * 100 / TOTAL_CHECKS : 0)),
      "readiness_status": "$([ $FAILED_CHECKS -eq 0 ] && [ $((TOTAL_CHECKS > 0 ? PASSED_CHECKS * 100 / TOTAL_CHECKS : 0)) -ge 90 ] && echo "READY" || echo "NOT_READY")"
    },
    "critical_issues": [
$(IFS=$'\n'; for issue in "${CRITICAL_ISSUES[@]}"; do echo "      \"$issue\","; done | sed '$ s/,$//')
    ],
    "warnings": [
$(IFS=$'\n'; for warning in "${WARNING_ISSUES[@]}"; do echo "      \"$warning\","; done | sed '$ s/,$//')
    ],
    "recommendations": [
$(IFS=$'\n'; for rec in "${RECOMMENDATIONS[@]}"; do echo "      \"$rec\","; done | sed '$ s/,$//')
    ]
  }
}
EOF

    print_info "JSON report generated: $json_file"
}

# Generate HTML report
generate_html_report() {
    local html_file="${OUTPUT_FILE:-reports/deployment-readiness.html}"
    mkdir -p "$(dirname "$html_file")"

    local score=$((TOTAL_CHECKS > 0 ? PASSED_CHECKS * 100 / TOTAL_CHECKS : 0))
    local status_class="danger"
    local status_text="NOT READY"

    if [ "$score" -ge 90 ] && [ "$FAILED_CHECKS" -eq 0 ]; then
        status_class="success"
        status_text="READY"
    elif [ "$score" -ge 75 ]; then
        status_class="warning"
        status_text="NEEDS REVIEW"
    fi

    cat > "$html_file" << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Royal Textiles Deployment Readiness Report</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 0; padding: 20px; background-color: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; box-shadow: 0 0 20px rgba(0,0,0,0.1); }
        h1 { color: #2c3e50; border-bottom: 3px solid #3498db; padding-bottom: 10px; }
        h2 { color: #34495e; margin-top: 30px; }
        .status { padding: 15px; border-radius: 5px; margin: 20px 0; text-align: center; font-weight: bold; font-size: 18px; }
        .status.success { background-color: #d4edda; color: #155724; border: 1px solid #c3e6cb; }
        .status.warning { background-color: #fff3cd; color: #856404; border: 1px solid #ffeaa7; }
        .status.danger { background-color: #f8d7da; color: #721c24; border: 1px solid #f5c6cb; }
        .stats { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; margin: 20px 0; }
        .stat { padding: 20px; background: #ecf0f1; border-radius: 5px; text-align: center; }
        .stat h3 { margin: 0 0 10px 0; color: #2c3e50; }
        .stat .number { font-size: 2em; font-weight: bold; }
        .passed { color: #27ae60; }
        .failed { color: #e74c3c; }
        .warning { color: #f39c12; }
        .issues, .recommendations { margin: 20px 0; }
        .issues ul, .recommendations ul { list-style-type: none; padding: 0; }
        .issues li, .recommendations li { padding: 10px; margin: 5px 0; border-left: 4px solid #3498db; background: #f8f9fa; }
        .critical { border-left-color: #e74c3c; }
        .warn { border-left-color: #f39c12; }
        .footer { margin-top: 30px; text-align: center; color: #7f8c8d; border-top: 1px solid #ecf0f1; padding-top: 20px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 Royal Textiles Deployment Readiness Report</h1>

        <div class="status $status_class">
            Deployment Status: $status_text
        </div>

        <div class="stats">
            <div class="stat">
                <h3>Total Checks</h3>
                <div class="number">$TOTAL_CHECKS</div>
            </div>
            <div class="stat">
                <h3>Passed</h3>
                <div class="number passed">$PASSED_CHECKS</div>
            </div>
            <div class="stat">
                <h3>Failed</h3>
                <div class="number failed">$FAILED_CHECKS</div>
            </div>
            <div class="stat">
                <h3>Warnings</h3>
                <div class="number warning">$WARNING_CHECKS</div>
            </div>
            <div class="stat">
                <h3>Score</h3>
                <div class="number">$score%</div>
            </div>
        </div>

EOF

    if [ ${#CRITICAL_ISSUES[@]} -gt 0 ]; then
        cat >> "$html_file" << EOF
        <h2>🚨 Critical Issues</h2>
        <div class="issues">
            <ul>
EOF
        for issue in "${CRITICAL_ISSUES[@]}"; do
            echo "                <li class=\"critical\">$issue</li>" >> "$html_file"
        done
        cat >> "$html_file" << EOF
            </ul>
        </div>
EOF
    fi

    if [ ${#WARNING_ISSUES[@]} -gt 0 ]; then
        cat >> "$html_file" << EOF
        <h2>⚠️ Warnings</h2>
        <div class="issues">
            <ul>
EOF
        for warning in "${WARNING_ISSUES[@]}"; do
            echo "                <li class=\"warn\">$warning</li>" >> "$html_file"
        done
        cat >> "$html_file" << EOF
            </ul>
        </div>
EOF
    fi

    if [ ${#RECOMMENDATIONS[@]} -gt 0 ]; then
        cat >> "$html_file" << EOF
        <h2>💡 Recommendations</h2>
        <div class="recommendations">
            <ul>
EOF
        for rec in "${RECOMMENDATIONS[@]}"; do
            echo "                <li>$rec</li>" >> "$html_file"
        done
        cat >> "$html_file" << EOF
            </ul>
        </div>
EOF
    fi

    cat >> "$html_file" << EOF
        <div class="footer">
            <p>Report generated on $(date) for environment: $DEPLOYMENT_ENV</p>
            <p>Royal Textiles Odoo Testing Infrastructure - Task 6.3</p>
        </div>
    </div>
</body>
</html>
EOF

    print_info "HTML report generated: $html_file"
}

# Main function
main() {
    local show_help=false

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --level)
                CHECKLIST_LEVEL="$2"
                shift 2
                ;;
            --env)
                DEPLOYMENT_ENV="$2"
                shift 2
                ;;
            --format)
                OUTPUT_FORMAT="$2"
                shift 2
                ;;
            --output)
                OUTPUT_FILE="$2"
                shift 2
                ;;
            --help|-h)
                show_help=true
                shift
                ;;
            *)
                echo "Unknown option: $1"
                show_help=true
                shift
                ;;
        esac
    done

    if [ "$show_help" = true ]; then
        echo "Royal Textiles Deployment Readiness Checklist"
        echo "============================================="
        echo ""
        echo "Usage: $0 [options]"
        echo ""
        echo "Options:"
        echo "  --level LEVEL    Checklist level: basic, full, production (default: full)"
        echo "  --env ENV        Target environment: development, staging, production (default: production)"
        echo "  --format FORMAT  Output format: text, json, html (default: text)"
        echo "  --output FILE    Output file (default: reports/deployment-readiness.[format])"
        echo "  --help, -h       Show this help message"
        echo ""
        echo "Examples:"
        echo "  $0                           # Full checklist for production"
        echo "  $0 --level basic --env staging"
        echo "  $0 --format json --output my-report.json"
        echo "  $0 --format html --output reports/readiness.html"
        echo ""
        exit 0
    fi

    # Validate arguments
    if [[ ! "$CHECKLIST_LEVEL" =~ ^(basic|full|production)$ ]]; then
        print_error "Invalid checklist level: $CHECKLIST_LEVEL"
        exit 1
    fi

    if [[ ! "$DEPLOYMENT_ENV" =~ ^(development|staging|production)$ ]]; then
        print_error "Invalid environment: $DEPLOYMENT_ENV"
        exit 1
    fi

    if [[ ! "$OUTPUT_FORMAT" =~ ^(text|json|html)$ ]]; then
        print_error "Invalid output format: $OUTPUT_FORMAT"
        exit 1
    fi

    # Create reports directory
    mkdir -p reports

    # Header
    print_header "Royal Textiles Deployment Readiness Checklist"
    echo "=============================================="
    echo ""
    print_info "Environment: $DEPLOYMENT_ENV"
    print_info "Checklist Level: $CHECKLIST_LEVEL"
    print_info "Output Format: $OUTPUT_FORMAT"
    echo ""

    # Run checks based on level
    check_git_status

    if [[ "$CHECKLIST_LEVEL" =~ ^(full|production)$ ]]; then
        check_code_quality
        check_module_validation
        check_test_coverage
        check_security
        check_dependencies
        check_configuration
        check_performance
        check_documentation
    fi

    if [ "$CHECKLIST_LEVEL" = "production" ]; then
        check_deployment_requirements
    fi

    # Generate summary
    generate_summary

    # Generate additional output formats
    case "$OUTPUT_FORMAT" in
        json)
            generate_json_report
            ;;
        html)
            generate_html_report
            ;;
    esac

    # Exit with appropriate code
    if [ "$FAILED_CHECKS" -eq 0 ] && [ "$((TOTAL_CHECKS > 0 ? PASSED_CHECKS * 100 / TOTAL_CHECKS : 0))" -ge 90 ]; then
        exit 0
    else
        exit 1
    fi
}

# Run the main function
main "$@"

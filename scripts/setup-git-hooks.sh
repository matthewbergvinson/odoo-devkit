#!/bin/bash

# =====================================
# Royal Textiles Git Hooks Setup Script
# =====================================
# Task 6.2: Implement git pre-push hooks to run full validation suite
# This script installs, configures, and manages git hooks for the project

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOKS_DIR="$PROJECT_ROOT/.git/hooks"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

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
    echo -e "${CYAN}🔧 $1${NC}"
}

# Function to install git hooks
install_hooks() {
    print_header "Installing Royal Textiles Git Hooks"
    echo "===================================="
    echo ""

    # Ensure hooks directory exists
    mkdir -p "$HOOKS_DIR"

    # Install pre-push hook
    print_info "Installing pre-push validation hook..."
    cat > "$HOOKS_DIR/pre-push" << 'EOF'
#!/bin/bash
# =====================================
# Royal Textiles Git Pre-Push Hook
# =====================================
# Task 6.2: Implement git pre-push hooks to run full validation suite
# This hook runs comprehensive validation before allowing push operations

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Hook configuration
HOOK_CONFIG_FILE="$(dirname "$0")/hook-config"

# Load configuration if it exists
if [ -f "$HOOK_CONFIG_FILE" ]; then
    source "$HOOK_CONFIG_FILE"
fi

# Default configuration
RTP_HOOK_LEVEL=${RTP_HOOK_LEVEL:-full}
RTP_HOOK_SKIP=${RTP_HOOK_SKIP:-false}
RTP_HOOK_INTERACTIVE=${RTP_HOOK_INTERACTIVE:-true}
RTP_HOOK_VERBOSE=${RTP_HOOK_VERBOSE:-false}

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

# Function to run validation
run_validation() {
    local validation_level="$1"

    print_header "Royal Textiles Pre-Push Validation"
    echo "================================="
    echo ""
    print_info "Validation level: $validation_level"
    print_info "Interactive mode: $RTP_HOOK_INTERACTIVE"
    echo ""

    # Check if we're in the right directory
    if [ ! -f "Makefile" ] || [ ! -d "custom_modules" ]; then
        print_error "Not in Royal Textiles project directory"
        return 1
    fi

    # Run validation based on level
    case "$validation_level" in
        quick)
            print_info "Running quick validation (CI-optimized)..."
            echo ""

            # Quick lint check
            print_info "1/3 Quick linting..."
            if ! make ci-quick > /dev/null 2>&1; then
                print_error "Quick validation failed"
                if [ "$RTP_HOOK_INTERACTIVE" = "true" ]; then
                    echo ""
                    print_info "Run 'make ci-quick' for details"
                    read -p "Continue anyway? (y/N): " -r
                    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                        return 1
                    fi
                else
                    return 1
                fi
            else
                print_status "Quick linting passed"
            fi

            # Module validation
            print_info "2/3 Module validation..."
            if ! make ci-validate > /dev/null 2>&1; then
                print_error "Module validation failed"
                if [ "$RTP_HOOK_INTERACTIVE" = "true" ]; then
                    echo ""
                    print_info "Run 'make ci-validate' for details"
                    read -p "Continue anyway? (y/N): " -r
                    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                        return 1
                    fi
                else
                    return 1
                fi
            else
                print_status "Module validation passed"
            fi

            # Quick test
            print_info "3/3 Quick tests..."
            if ! timeout 120 make ci-test > /dev/null 2>&1; then
                print_warning "Quick tests failed or timed out"
                if [ "$RTP_HOOK_INTERACTIVE" = "true" ]; then
                    echo ""
                    print_info "Run 'make ci-test' for details"
                    read -p "Continue anyway? (y/N): " -r
                    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                        return 1
                    fi
                else
                    return 1
                fi
            else
                print_status "Quick tests passed"
            fi
            ;;

        full)
            print_info "Running full validation suite..."
            echo ""

            # Full CI pipeline
            print_info "Running complete CI pipeline..."
            if ! make ci-pipeline; then
                print_error "Full validation failed"
                if [ "$RTP_HOOK_INTERACTIVE" = "true" ]; then
                    echo ""
                    print_info "Review the output above for details"
                    read -p "Continue push anyway? (y/N): " -r
                    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                        return 1
                    fi
                else
                    return 1
                fi
            else
                print_status "Full validation passed"
            fi
            ;;

        security)
            print_info "Running security-focused validation..."
            echo ""

            # Security validation
            print_info "1/2 Security validation..."
            if ! make ci-validate > /dev/null 2>&1; then
                print_error "Security validation failed"
                return 1
            else
                print_status "Security validation passed"
            fi

            # Deployment readiness
            print_info "2/2 Deployment readiness..."
            if ! make ci-deploy-check > /dev/null 2>&1; then
                print_error "Deployment readiness check failed"
                return 1
            else
                print_status "Deployment readiness check passed"
            fi
            ;;

        *)
            print_error "Unknown validation level: $validation_level"
            return 1
            ;;
    esac

    echo ""
    print_status "Pre-push validation completed successfully!"
    echo ""

    return 0
}

# Main hook logic
main() {
    # Check if hook should be skipped
    if [ "$RTP_HOOK_SKIP" = "true" ]; then
        print_warning "Pre-push hook skipped by configuration"
        exit 0
    fi

    # Check if in CI environment
    if [ -n "$CI" ] || [ -n "$GITHUB_ACTIONS" ] || [ -n "$JENKINS_URL" ]; then
        print_info "CI environment detected, using non-interactive mode"
        RTP_HOOK_INTERACTIVE=false
    fi

    # Get remote and branch information
    remote="$1"
    url="$2"

    # Read stdin for branch information
    local_ref=""
    local_sha=""
    remote_ref=""
    remote_sha=""

    while read local_ref local_sha remote_ref remote_sha; do
        if [ "$local_sha" = "0000000000000000000000000000000000000000" ]; then
            # Deleting branch - no validation needed
            print_info "Deleting branch, skipping validation"
            continue
        fi

        if [ "$remote_sha" = "0000000000000000000000000000000000000000" ]; then
            # New branch
            print_info "Creating new branch: $local_ref"
        else
            # Existing branch
            print_info "Updating branch: $local_ref"
        fi

        # Run validation
        if ! run_validation "$RTP_HOOK_LEVEL"; then
            print_error "Pre-push validation failed"
            echo ""
            print_info "To skip validation temporarily: RTP_HOOK_SKIP=true git push"
            print_info "To use quick validation: RTP_HOOK_LEVEL=quick git push"
            print_info "To bypass hooks entirely: git push --no-verify"
            echo ""
            exit 1
        fi
    done

    print_status "All pre-push validations passed! 🎉"
    exit 0
}

# Run the main function
main "$@"
EOF

    chmod +x "$HOOKS_DIR/pre-push"
    print_status "Pre-push hook installed and made executable"

    # Create or update hook configuration
    print_info "Creating hook configuration..."
    cat > "$HOOKS_DIR/hook-config" << 'EOF'
# Royal Textiles Git Hook Configuration
#
# This file can be sourced to configure hook behavior
# Copy to .git/hooks/hook-config and modify as needed
#
# Available settings:

# Validation level: quick, full, security
export RTP_HOOK_LEVEL=full

# Skip hook entirely
# export RTP_HOOK_SKIP=true

# Interactive mode (allow user choices on failures)
export RTP_HOOK_INTERACTIVE=true

# Verbose output
# export RTP_HOOK_VERBOSE=true

# Non-interactive mode for CI/CD
# export RTP_HOOK_INTERACTIVE=false

EOF
    print_status "Hook configuration created"

    # Install manual test script
    print_info "Installing manual test script..."
    cat > "$PROJECT_ROOT/scripts/run-pre-push-checks.sh" << 'EOF'
#!/bin/bash
# =====================================
# Royal Textiles Manual Pre-Push Validation
# =====================================
# Task 6.2: Manual execution of pre-push validation checks
# This script allows manual testing of pre-push validation

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

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
    echo -e "${CYAN}🧪 $1${NC}"
}

# Function to run validation
run_validation() {
    local validation_level="${1:-full}"

    print_header "Manual Pre-Push Validation"
    echo "=========================="
    echo ""
    print_info "Validation level: $validation_level"
    print_info "Manual execution mode"
    echo ""

    # Check if we're in the right directory
    if [ ! -f "Makefile" ] || [ ! -d "custom_modules" ]; then
        print_error "Not in Royal Textiles project directory"
        return 1
    fi

    # Run validation based on level
    case "$validation_level" in
        quick)
            print_info "Running quick validation..."
            echo ""

            print_info "1/3 Quick CI check..."
            if make ci-quick; then
                print_status "Quick CI check passed"
            else
                print_error "Quick CI check failed"
                return 1
            fi
            echo ""

            print_info "2/3 Module validation..."
            if make ci-validate; then
                print_status "Module validation passed"
            else
                print_error "Module validation failed"
                return 1
            fi
            echo ""

            print_info "3/3 Quick tests..."
            if timeout 120 make ci-test; then
                print_status "Quick tests passed"
            else
                print_error "Quick tests failed or timed out"
                return 1
            fi
            ;;

        full)
            print_info "Running full validation suite..."
            echo ""

            if make ci-pipeline; then
                print_status "Full validation passed"
            else
                print_error "Full validation failed"
                return 1
            fi
            ;;

        security)
            print_info "Running security-focused validation..."
            echo ""

            print_info "1/2 Security validation..."
            if make ci-validate; then
                print_status "Security validation passed"
            else
                print_error "Security validation failed"
                return 1
            fi
            echo ""

            print_info "2/2 Deployment readiness..."
            if make ci-deploy-check; then
                print_status "Deployment readiness check passed"
            else
                print_error "Deployment readiness check failed"
                return 1
            fi
            ;;

        *)
            print_error "Unknown validation level: $validation_level"
            echo ""
            print_info "Available levels: quick, full, security"
            return 1
            ;;
    esac

    echo ""
    print_status "Manual validation completed successfully! 🎉"
    echo ""

    return 0
}

# Main script logic
main() {
    local validation_level="${1:-full}"

    # Handle help request
    if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
        echo "Royal Textiles Manual Pre-Push Validation"
        echo "========================================"
        echo ""
        echo "Usage: $0 [validation_level]"
        echo ""
        echo "Available validation levels:"
        echo "  quick    - Quick validation (syntax, manifests, quick tests)"
        echo "  full     - Complete validation suite (default)"
        echo "  security - Security-focused validation"
        echo ""
        echo "Examples:"
        echo "  $0 quick     # Quick validation"
        echo "  $0 full      # Full validation"
        echo "  $0 security  # Security validation"
        echo ""
        exit 0
    fi

    # Run validation
    if run_validation "$validation_level"; then
        print_status "Validation completed successfully!"
        exit 0
    else
        print_error "Validation failed!"
        exit 1
    fi
}

# Run the main function
main "$@"
EOF

    chmod +x "$PROJECT_ROOT/scripts/run-pre-push-checks.sh"
    print_status "Manual test script installed and made executable"

    echo ""
    print_status "Git hooks installation completed successfully!"
    echo ""
    print_info "Next steps:"
    echo "  1. Test the hooks: make hooks-test"
    echo "  2. Configure settings: make hooks-configure"
    echo "  3. Run manual test: make hooks-run-quick"
    echo ""
}

# Function to uninstall git hooks
uninstall_hooks() {
    print_header "Uninstalling Royal Textiles Git Hooks"
    echo "======================================"
    echo ""

    # Remove pre-push hook
    if [ -f "$HOOKS_DIR/pre-push" ]; then
        rm -f "$HOOKS_DIR/pre-push"
        print_status "Pre-push hook removed"
    else
        print_info "Pre-push hook not found"
    fi

    # Remove hook configuration
    if [ -f "$HOOKS_DIR/hook-config" ]; then
        rm -f "$HOOKS_DIR/hook-config"
        print_status "Hook configuration removed"
    else
        print_info "Hook configuration not found"
    fi

    # Remove manual test script
    if [ -f "$PROJECT_ROOT/scripts/run-pre-push-checks.sh" ]; then
        rm -f "$PROJECT_ROOT/scripts/run-pre-push-checks.sh"
        print_status "Manual test script removed"
    else
        print_info "Manual test script not found"
    fi

    echo ""
    print_status "Git hooks uninstalled successfully!"
    echo ""
}

# Function to show hook status
show_status() {
    print_header "Royal Textiles Git Hooks Status"
    echo "================================"
    echo ""

    # Check pre-push hook
    if [ -f "$HOOKS_DIR/pre-push" ]; then
        if [ -x "$HOOKS_DIR/pre-push" ]; then
            if grep -q "Royal Textiles Git Pre-Push Hook" "$HOOKS_DIR/pre-push"; then
                print_status "Pre-push hook: Installed and configured"
            else
                print_warning "Pre-push hook: Installed but not Royal Textiles hook"
            fi
        else
            print_warning "Pre-push hook: Installed but not executable"
        fi
    else
        print_error "Pre-push hook: Not installed"
    fi

    # Check hook configuration
    if [ -f "$HOOKS_DIR/hook-config" ]; then
        print_status "Hook configuration: Available"
        echo "  Current settings:"
        grep "^export" "$HOOKS_DIR/hook-config" | sed 's/^/    /' || print_info "    No active configuration"
    else
        print_warning "Hook configuration: Not found"
    fi

    # Check manual test script
    if [ -f "$PROJECT_ROOT/scripts/run-pre-push-checks.sh" ]; then
        if [ -x "$PROJECT_ROOT/scripts/run-pre-push-checks.sh" ]; then
            print_status "Manual test script: Available and executable"
        else
            print_warning "Manual test script: Available but not executable"
        fi
    else
        print_warning "Manual test script: Not found"
    fi

    echo ""

    # Overall status
    if [ -f "$HOOKS_DIR/pre-push" ] && [ -x "$HOOKS_DIR/pre-push" ] && [ -f "$HOOKS_DIR/hook-config" ] && [ -f "$PROJECT_ROOT/scripts/run-pre-push-checks.sh" ]; then
        print_status "Overall status: Git hooks are properly installed and configured"
    else
        print_warning "Overall status: Git hooks setup is incomplete"
        print_info "Run 'make hooks-install' to complete setup"
    fi
}

# Function to test git hooks
test_hooks() {
    print_header "Testing Royal Textiles Git Hooks"
    echo "================================="
    echo ""

    # Test manual script
    print_info "Testing manual validation script..."
    if [ -f "$PROJECT_ROOT/scripts/run-pre-push-checks.sh" ] && [ -x "$PROJECT_ROOT/scripts/run-pre-push-checks.sh" ]; then
        print_status "Manual validation script is executable"

        # Test quick validation
        print_info "Running quick validation test..."
        if timeout 180 "$PROJECT_ROOT/scripts/run-pre-push-checks.sh" quick; then
            print_status "Quick validation test passed"
        else
            print_warning "Quick validation test failed"
            print_info "This may be expected if there are validation issues"
        fi
    else
        print_error "Manual validation script not found or not executable"
        return 1
    fi

    # Test hook configuration
    print_info "Testing hook configuration..."
    if [ -f "$HOOKS_DIR/hook-config" ]; then
        if source "$HOOKS_DIR/hook-config" 2>/dev/null; then
            print_status "Hook configuration is valid"
        else
            print_error "Hook configuration has syntax errors"
            return 1
        fi
    else
        print_warning "Hook configuration not found"
    fi

    # Test pre-push hook
    print_info "Testing pre-push hook..."
    if [ -f "$HOOKS_DIR/pre-push" ] && [ -x "$HOOKS_DIR/pre-push" ]; then
        print_status "Pre-push hook is installed and executable"

        # Test hook syntax
        if bash -n "$HOOKS_DIR/pre-push"; then
            print_status "Pre-push hook syntax is valid"
        else
            print_error "Pre-push hook has syntax errors"
            return 1
        fi
    else
        print_error "Pre-push hook not found or not executable"
        return 1
    fi

    echo ""
    print_status "Git hooks testing completed successfully!"
    echo ""
    print_info "To test hooks with actual push simulation:"
    echo "  make hooks-run-quick   # Quick validation"
    echo "  make hooks-run         # Full validation"
    echo ""
}

# Main script logic
main() {
    local action="${1:-help}"

    case "$action" in
        install)
            install_hooks
            ;;
        uninstall)
            uninstall_hooks
            ;;
        status)
            show_status
            ;;
        test)
            test_hooks
            ;;
        *)
            echo "Royal Textiles Git Hooks Setup"
            echo "=============================="
            echo ""
            echo "Usage: $0 {install|uninstall|status|test}"
            echo ""
            echo "Commands:"
            echo "  install   - Install git pre-push hooks"
            echo "  uninstall - Remove git hooks"
            echo "  status    - Show installation status"
            echo "  test      - Test hook functionality"
            echo ""
            echo "Examples:"
            echo "  $0 install   # Install hooks"
            echo "  $0 status    # Check status"
            echo "  $0 test      # Test hooks"
            echo ""
            exit 1
            ;;
    esac
}

# Run the main function
main "$@"

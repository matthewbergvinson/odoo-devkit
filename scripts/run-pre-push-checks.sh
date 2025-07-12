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

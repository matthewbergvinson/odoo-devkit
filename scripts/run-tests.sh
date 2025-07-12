#!/bin/bash

# RTP Denver - Test Runner Script
# Task 4.1: Easy test execution with pytest-odoo

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Default values
TEST_TYPE="all"
MODULE=""
COVERAGE=false
PARALLEL=false
HTML_REPORT=false
VERBOSE=false

show_help() {
    echo "RTP Denver - Test Runner"
    echo "======================="
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -t, --type TYPE      Test type: all, unit, integration, functional, performance"
    echo "  -m, --module MODULE  Test specific module: rtp_customers, royal_textiles_sales"
    echo "  -c, --coverage       Generate coverage report"
    echo "  -p, --parallel       Run tests in parallel"
    echo "  -r, --report         Generate HTML report"
    echo "  -v, --verbose        Verbose output"
    echo "  -h, --help          Show this help"
    echo ""
    echo "Examples:"
    echo "  $0                           # Run all tests"
    echo "  $0 -t unit                   # Run unit tests only"
    echo "  $0 -m rtp_customers -c       # Test RTP customers with coverage"
    echo "  $0 -t integration -p -r      # Integration tests with parallel execution and HTML report"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--type)
            TEST_TYPE="$2"
            shift 2
            ;;
        -m|--module)
            MODULE="$2"
            shift 2
            ;;
        -c|--coverage)
            COVERAGE=true
            shift
            ;;
        -p|--parallel)
            PARALLEL=true
            shift
            ;;
        -r|--report)
            HTML_REPORT=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Build pytest command
PYTEST_CMD="pytest"

# Add test type selection
case $TEST_TYPE in
    unit)
        PYTEST_CMD="$PYTEST_CMD -m unit"
        ;;
    integration)
        PYTEST_CMD="$PYTEST_CMD -m integration"
        ;;
    functional)
        PYTEST_CMD="$PYTEST_CMD -m functional"
        ;;
    performance)
        PYTEST_CMD="$PYTEST_CMD -m performance"
        ;;
    fast)
        PYTEST_CMD="$PYTEST_CMD -m fast"
        ;;
    slow)
        PYTEST_CMD="$PYTEST_CMD -m slow"
        ;;
    all)
        # Run all tests
        ;;
    *)
        echo "Unknown test type: $TEST_TYPE"
        exit 1
        ;;
esac

# Add module selection
if [[ -n "$MODULE" ]]; then
    PYTEST_CMD="$PYTEST_CMD -m $MODULE"
fi

# Add coverage
if [[ "$COVERAGE" == true ]]; then
    PYTEST_CMD="$PYTEST_CMD --cov=custom_modules --cov-report=term-missing --cov-report=html"
fi

# Add parallel execution
if [[ "$PARALLEL" == true ]]; then
    PYTEST_CMD="$PYTEST_CMD -n auto"
fi

# Add HTML report
if [[ "$HTML_REPORT" == true ]]; then
    PYTEST_CMD="$PYTEST_CMD --html=reports/pytest_report.html --self-contained-html"
fi

# Add verbose output
if [[ "$VERBOSE" == true ]]; then
    PYTEST_CMD="$PYTEST_CMD -v"
fi

# Ensure directories exist
mkdir -p reports

# Run tests
echo -e "${BLUE}Running tests with command:${NC} $PYTEST_CMD"
echo ""

cd "$PROJECT_ROOT"
eval "$PYTEST_CMD"

echo ""
echo -e "${GREEN}Test execution completed!${NC}"

if [[ "$COVERAGE" == true ]]; then
    echo -e "${BLUE}Coverage report available at:${NC} htmlcov/index.html"
fi

if [[ "$HTML_REPORT" == true ]]; then
    echo -e "${BLUE}Test report available at:${NC} reports/pytest_report.html"
fi

#!/bin/bash

# =====================================
# Royal Textiles Automated Test Report Generation
# =====================================
# Task 6.4: Add automated test report generation (HTML coverage reports, test results)
# This script generates comprehensive HTML test reports and coverage analysis

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

# Configuration
REPORTS_DIR="$PROJECT_ROOT/reports"
COVERAGE_DIR="$REPORTS_DIR/coverage"
TEST_RESULTS_DIR="$REPORTS_DIR/test-results"
TEMPLATES_DIR="$SCRIPT_DIR/templates"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
REPORT_NAME="test-report-$TIMESTAMP"

# Default settings
GENERATE_COVERAGE=true
GENERATE_JUNIT=true
GENERATE_HTML=true
GENERATE_BADGES=true
RUN_TESTS=true
COVERAGE_THRESHOLD=70
OPEN_BROWSER=false
PUBLISH_REPORTS=false
REPORT_TITLE="Royal Textiles Test Report"

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

# Function to create directory structure
setup_directories() {
    print_section "Setting up report directories"
    
    mkdir -p "$REPORTS_DIR"
    mkdir -p "$COVERAGE_DIR"
    mkdir -p "$TEST_RESULTS_DIR"
    mkdir -p "$REPORTS_DIR/assets"
    mkdir -p "$REPORTS_DIR/badges"
    
    print_status "Report directories created"
}

# Function to run tests with coverage
run_test_suite() {
    print_section "Running test suite with coverage"
    
    cd "$PROJECT_ROOT"
    
    # Set environment variables for testing
    export PYTHONPATH="$PROJECT_ROOT:$PYTHONPATH"
    export COVERAGE_FILE="$COVERAGE_DIR/.coverage"
    
    # Run different test types
    local test_results_file="$TEST_RESULTS_DIR/combined-results.xml"
    local coverage_xml="$COVERAGE_DIR/coverage.xml"
    local coverage_html="$COVERAGE_DIR/html"
    
    print_info "Running comprehensive test suite..."
    
    # Combined test run with coverage
    if command -v pytest >/dev/null 2>&1; then
        pytest \
            --cov=custom_modules \
            --cov=tests \
            --cov-report=html:"$coverage_html" \
            --cov-report=xml:"$coverage_xml" \
            --cov-report=term-missing \
            --cov-fail-under=$COVERAGE_THRESHOLD \
            --junit-xml="$test_results_file" \
            --tb=short \
            -v \
            tests/ \
            custom_modules/ \
            2>&1 | tee "$TEST_RESULTS_DIR/pytest-output.log"
        
        local pytest_exit=$?
        if [ $pytest_exit -eq 0 ]; then
            print_status "Test suite completed successfully"
        else
            print_warning "Test suite completed with issues (exit code: $pytest_exit)"
        fi
    else
        print_warning "pytest not available, running basic tests"
        python -m unittest discover -s tests -p "test_*.py" -v > "$TEST_RESULTS_DIR/unittest-output.log" 2>&1
    fi
    
    # Generate coverage data if available
    if [ -f "$coverage_xml" ]; then
        print_status "Coverage data generated"
    else
        print_warning "Coverage data not available"
    fi
    
    # Generate individual test type reports
    run_unit_tests
    run_integration_tests
    run_functional_tests
    run_performance_tests
}

# Function to run unit tests specifically
run_unit_tests() {
    print_info "Running unit tests..."
    
    local unit_results="$TEST_RESULTS_DIR/unit-results.xml"
    local unit_log="$TEST_RESULTS_DIR/unit-tests.log"
    
    if command -v pytest >/dev/null 2>&1; then
        pytest \
            --junit-xml="$unit_results" \
            --tb=short \
            -v \
            tests/unit/ \
            2>&1 | tee "$unit_log"
    fi
}

# Function to run integration tests
run_integration_tests() {
    print_info "Running integration tests..."
    
    local integration_results="$TEST_RESULTS_DIR/integration-results.xml"
    local integration_log="$TEST_RESULTS_DIR/integration-tests.log"
    
    if command -v pytest >/dev/null 2>&1; then
        pytest \
            --junit-xml="$integration_results" \
            --tb=short \
            -v \
            tests/integration/ \
            2>&1 | tee "$integration_log"
    fi
}

# Function to run functional tests
run_functional_tests() {
    print_info "Running functional tests..."
    
    local functional_results="$TEST_RESULTS_DIR/functional-results.xml"
    local functional_log="$TEST_RESULTS_DIR/functional-tests.log"
    
    if command -v pytest >/dev/null 2>&1; then
        pytest \
            --junit-xml="$functional_results" \
            --tb=short \
            -v \
            tests/functional/ \
            2>&1 | tee "$functional_log"
    fi
}

# Function to run performance tests
run_performance_tests() {
    print_info "Running performance tests..."
    
    local performance_results="$TEST_RESULTS_DIR/performance-results.xml"
    local performance_log="$TEST_RESULTS_DIR/performance-tests.log"
    
    if command -v pytest >/dev/null 2>&1; then
        pytest \
            --junit-xml="$performance_results" \
            --tb=short \
            -v \
            tests/performance/ \
            2>&1 | tee "$performance_log"
    fi
}

# Function to parse test results
parse_test_results() {
    print_section "Parsing test results"
    
    local results_summary="$TEST_RESULTS_DIR/summary.json"
    
    # Parse JUnit XML files using Python
    cat > "$TEST_RESULTS_DIR/parse_results.py" << 'EOF'
import xml.etree.ElementTree as ET
import json
import os
import glob
from datetime import datetime

def parse_junit_xml(file_path):
    """Parse JUnit XML file and extract test results."""
    try:
        tree = ET.parse(file_path)
        root = tree.getroot()
        
        # Handle both testsuites and testsuite as root
        if root.tag == 'testsuites':
            testsuites = root.findall('testsuite')
        else:
            testsuites = [root]
        
        results = {
            'total_tests': 0,
            'passed_tests': 0,
            'failed_tests': 0,
            'skipped_tests': 0,
            'error_tests': 0,
            'duration': 0.0,
            'test_cases': []
        }
        
        for testsuite in testsuites:
            tests = int(testsuite.get('tests', 0))
            failures = int(testsuite.get('failures', 0))
            errors = int(testsuite.get('errors', 0))
            skipped = int(testsuite.get('skipped', 0))
            time = float(testsuite.get('time', 0))
            
            results['total_tests'] += tests
            results['failed_tests'] += failures
            results['error_tests'] += errors
            results['skipped_tests'] += skipped
            results['duration'] += time
            
            # Parse individual test cases
            for testcase in testsuite.findall('testcase'):
                case_info = {
                    'name': testcase.get('name', ''),
                    'classname': testcase.get('classname', ''),
                    'time': float(testcase.get('time', 0)),
                    'status': 'passed'
                }
                
                if testcase.find('failure') is not None:
                    case_info['status'] = 'failed'
                    case_info['failure'] = testcase.find('failure').text
                elif testcase.find('error') is not None:
                    case_info['status'] = 'error'
                    case_info['error'] = testcase.find('error').text
                elif testcase.find('skipped') is not None:
                    case_info['status'] = 'skipped'
                    case_info['skip_reason'] = testcase.find('skipped').text
                
                results['test_cases'].append(case_info)
        
        results['passed_tests'] = results['total_tests'] - results['failed_tests'] - results['error_tests'] - results['skipped_tests']
        
        return results
    
    except Exception as e:
        print(f"Error parsing {file_path}: {e}")
        return None

def parse_coverage_xml(file_path):
    """Parse coverage XML file and extract coverage data."""
    try:
        tree = ET.parse(file_path)
        root = tree.getroot()
        
        coverage_data = {
            'line_rate': float(root.get('line-rate', 0)),
            'branch_rate': float(root.get('branch-rate', 0)),
            'lines_covered': int(root.get('lines-covered', 0)),
            'lines_valid': int(root.get('lines-valid', 0)),
            'branches_covered': int(root.get('branches-covered', 0)),
            'branches_valid': int(root.get('branches-valid', 0)),
            'complexity': float(root.get('complexity', 0)),
            'packages': []
        }
        
        # Calculate percentages
        coverage_data['line_coverage_percent'] = coverage_data['line_rate'] * 100
        coverage_data['branch_coverage_percent'] = coverage_data['branch_rate'] * 100
        
        # Parse package details
        for package in root.findall('.//package'):
            package_data = {
                'name': package.get('name', ''),
                'line_rate': float(package.get('line-rate', 0)),
                'branch_rate': float(package.get('branch-rate', 0)),
                'complexity': float(package.get('complexity', 0)),
                'classes': []
            }
            
            for class_elem in package.findall('classes/class'):
                class_data = {
                    'name': class_elem.get('name', ''),
                    'filename': class_elem.get('filename', ''),
                    'line_rate': float(class_elem.get('line-rate', 0)),
                    'branch_rate': float(class_elem.get('branch-rate', 0)),
                    'complexity': float(class_elem.get('complexity', 0))
                }
                package_data['classes'].append(class_data)
            
            coverage_data['packages'].append(package_data)
        
        return coverage_data
    
    except Exception as e:
        print(f"Error parsing coverage XML {file_path}: {e}")
        return None

def main():
    results_dir = os.path.dirname(os.path.abspath(__file__))
    
    # Parse all JUnit XML files
    xml_files = glob.glob(os.path.join(results_dir, '*-results.xml'))
    
    combined_results = {
        'timestamp': datetime.now().isoformat(),
        'test_suites': {},
        'total_summary': {
            'total_tests': 0,
            'passed_tests': 0,
            'failed_tests': 0,
            'skipped_tests': 0,
            'error_tests': 0,
            'duration': 0.0
        },
        'coverage': None
    }
    
    # Process each test results file
    for xml_file in xml_files:
        suite_name = os.path.basename(xml_file).replace('-results.xml', '')
        results = parse_junit_xml(xml_file)
        
        if results:
            combined_results['test_suites'][suite_name] = results
            
            # Add to totals
            combined_results['total_summary']['total_tests'] += results['total_tests']
            combined_results['total_summary']['passed_tests'] += results['passed_tests']
            combined_results['total_summary']['failed_tests'] += results['failed_tests']
            combined_results['total_summary']['skipped_tests'] += results['skipped_tests']
            combined_results['total_summary']['error_tests'] += results['error_tests']
            combined_results['total_summary']['duration'] += results['duration']
    
    # Parse coverage data
    coverage_file = os.path.join(os.path.dirname(results_dir), 'coverage', 'coverage.xml')
    if os.path.exists(coverage_file):
        coverage_data = parse_coverage_xml(coverage_file)
        if coverage_data:
            combined_results['coverage'] = coverage_data
    
    # Calculate success rate
    total = combined_results['total_summary']['total_tests']
    if total > 0:
        passed = combined_results['total_summary']['passed_tests']
        combined_results['total_summary']['success_rate'] = (passed / total) * 100
    else:
        combined_results['total_summary']['success_rate'] = 0
    
    # Save results
    with open(os.path.join(results_dir, 'summary.json'), 'w') as f:
        json.dump(combined_results, f, indent=2)
    
    print(f"Parsed {len(xml_files)} test result files")
    print(f"Total tests: {combined_results['total_summary']['total_tests']}")
    print(f"Success rate: {combined_results['total_summary']['success_rate']:.1f}%")
    
    if combined_results['coverage']:
        print(f"Line coverage: {combined_results['coverage']['line_coverage_percent']:.1f}%")
        print(f"Branch coverage: {combined_results['coverage']['branch_coverage_percent']:.1f}%")

if __name__ == '__main__':
    main()
EOF
    
    # Run the parser
    python "$TEST_RESULTS_DIR/parse_results.py"
    
    if [ -f "$results_summary" ]; then
        print_status "Test results parsed successfully"
    else
        print_warning "Failed to parse test results"
    fi
}

# Function to generate HTML report
generate_html_report() {
    print_section "Generating HTML test report"
    
    local html_report="$REPORTS_DIR/test-report.html"
    local results_summary="$TEST_RESULTS_DIR/summary.json"
    
    # Create HTML report generator
    cat > "$REPORTS_DIR/generate_html.py" << 'EOF'
import json
import os
import sys
from datetime import datetime
from pathlib import Path

def load_results(summary_file):
    """Load test results from JSON summary."""
    try:
        with open(summary_file, 'r') as f:
            return json.load(f)
    except Exception as e:
        print(f"Error loading results: {e}")
        return None

def generate_html_report(results, output_file, title="Test Report"):
    """Generate comprehensive HTML test report."""
    
    # Calculate summary statistics
    summary = results.get('total_summary', {})
    coverage = results.get('coverage', {})
    test_suites = results.get('test_suites', {})
    
    success_rate = summary.get('success_rate', 0)
    total_tests = summary.get('total_tests', 0)
    passed_tests = summary.get('passed_tests', 0)
    failed_tests = summary.get('failed_tests', 0)
    skipped_tests = summary.get('skipped_tests', 0)
    error_tests = summary.get('error_tests', 0)
    duration = summary.get('duration', 0)
    
    # Coverage statistics
    line_coverage = coverage.get('line_coverage_percent', 0) if coverage else 0
    branch_coverage = coverage.get('branch_coverage_percent', 0) if coverage else 0
    
    # Determine status colors
    def get_status_color(rate):
        if rate >= 90:
            return '#28a745'  # Green
        elif rate >= 70:
            return '#ffc107'  # Yellow
        else:
            return '#dc3545'  # Red
    
    def get_coverage_color(rate):
        if rate >= 80:
            return '#28a745'  # Green
        elif rate >= 60:
            return '#ffc107'  # Yellow
        else:
            return '#dc3545'  # Red
    
    html_content = f"""
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{title}</title>
    <style>
        * {{
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }}
        
        body {{
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            color: #333;
            background-color: #f8f9fa;
        }}
        
        .container {{
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
        }}
        
        .header {{
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 30px 0;
            text-align: center;
            margin-bottom: 30px;
            border-radius: 10px;
        }}
        
        .header h1 {{
            font-size: 2.5em;
            margin-bottom: 10px;
        }}
        
        .header .subtitle {{
            font-size: 1.2em;
            opacity: 0.9;
        }}
        
        .stats-grid {{
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }}
        
        .stat-card {{
            background: white;
            padding: 25px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            text-align: center;
            transition: transform 0.3s ease;
        }}
        
        .stat-card:hover {{
            transform: translateY(-5px);
        }}
        
        .stat-card h3 {{
            color: #666;
            font-size: 0.9em;
            text-transform: uppercase;
            letter-spacing: 1px;
            margin-bottom: 10px;
        }}
        
        .stat-card .value {{
            font-size: 2.5em;
            font-weight: bold;
            margin-bottom: 5px;
        }}
        
        .stat-card .label {{
            color: #888;
            font-size: 0.9em;
        }}
        
        .success-rate {{
            color: {get_status_color(success_rate)};
        }}
        
        .coverage-rate {{
            color: {get_coverage_color(line_coverage)};
        }}
        
        .section {{
            background: white;
            margin-bottom: 30px;
            border-radius: 10px;
            overflow: hidden;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }}
        
        .section-header {{
            background: #f8f9fa;
            padding: 20px;
            border-bottom: 1px solid #dee2e6;
            font-weight: bold;
            font-size: 1.3em;
            color: #495057;
        }}
        
        .section-content {{
            padding: 20px;
        }}
        
        .progress-bar {{
            width: 100%;
            height: 20px;
            background: #e9ecef;
            border-radius: 10px;
            overflow: hidden;
            margin: 10px 0;
        }}
        
        .progress-fill {{
            height: 100%;
            background: linear-gradient(90deg, #28a745, #20c997);
            transition: width 0.3s ease;
        }}
        
        .test-suites {{
            display: grid;
            gap: 20px;
        }}
        
        .test-suite {{
            border: 1px solid #dee2e6;
            border-radius: 8px;
            overflow: hidden;
        }}
        
        .test-suite-header {{
            background: #f8f9fa;
            padding: 15px;
            font-weight: bold;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }}
        
        .test-suite-stats {{
            display: flex;
            gap: 15px;
        }}
        
        .test-suite-stat {{
            display: flex;
            align-items: center;
            gap: 5px;
        }}
        
        .status-badge {{
            padding: 4px 8px;
            border-radius: 4px;
            font-size: 0.8em;
            font-weight: bold;
            text-transform: uppercase;
        }}
        
        .status-passed {{
            background: #d4edda;
            color: #155724;
        }}
        
        .status-failed {{
            background: #f8d7da;
            color: #721c24;
        }}
        
        .status-skipped {{
            background: #fff3cd;
            color: #856404;
        }}
        
        .status-error {{
            background: #f5c6cb;
            color: #721c24;
        }}
        
        .coverage-details {{
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 20px;
            margin-top: 20px;
        }}
        
        .coverage-metric {{
            text-align: center;
            padding: 15px;
            border: 1px solid #dee2e6;
            border-radius: 8px;
        }}
        
        .coverage-metric h4 {{
            color: #666;
            margin-bottom: 10px;
        }}
        
        .coverage-metric .percentage {{
            font-size: 2em;
            font-weight: bold;
            margin-bottom: 5px;
        }}
        
        .footer {{
            text-align: center;
            margin-top: 40px;
            padding: 20px;
            color: #666;
            background: white;
            border-radius: 10px;
        }}
        
        .timestamp {{
            font-size: 0.9em;
            color: #888;
        }}
        
        @media (max-width: 768px) {{
            .stats-grid {{
                grid-template-columns: 1fr;
            }}
            
            .coverage-details {{
                grid-template-columns: 1fr;
            }}
        }}
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🧪 {title}</h1>
            <div class="subtitle">Royal Textiles Odoo Testing Infrastructure</div>
        </div>
        
        <div class="stats-grid">
            <div class="stat-card">
                <h3>Total Tests</h3>
                <div class="value">{total_tests:,}</div>
                <div class="label">Test Cases</div>
            </div>
            
            <div class="stat-card">
                <h3>Success Rate</h3>
                <div class="value success-rate">{success_rate:.1f}%</div>
                <div class="label">Passed Tests</div>
            </div>
            
            <div class="stat-card">
                <h3>Line Coverage</h3>
                <div class="value coverage-rate">{line_coverage:.1f}%</div>
                <div class="label">Code Coverage</div>
            </div>
            
            <div class="stat-card">
                <h3>Duration</h3>
                <div class="value">{duration:.1f}s</div>
                <div class="label">Total Time</div>
            </div>
        </div>
        
        <div class="section">
            <div class="section-header">
                📊 Test Results Summary
            </div>
            <div class="section-content">
                <div class="progress-bar">
                    <div class="progress-fill" style="width: {success_rate}%"></div>
                </div>
                <div class="test-suite-stats">
                    <div class="test-suite-stat">
                        <span class="status-badge status-passed">✅ {passed_tests}</span>
                        <span>Passed</span>
                    </div>
                    <div class="test-suite-stat">
                        <span class="status-badge status-failed">❌ {failed_tests}</span>
                        <span>Failed</span>
                    </div>
                    <div class="test-suite-stat">
                        <span class="status-badge status-skipped">⏭️ {skipped_tests}</span>
                        <span>Skipped</span>
                    </div>
                    <div class="test-suite-stat">
                        <span class="status-badge status-error">💥 {error_tests}</span>
                        <span>Errors</span>
                    </div>
                </div>
            </div>
        </div>
    """
    
    # Add coverage section if available
    if coverage:
        html_content += f"""
        <div class="section">
            <div class="section-header">
                📈 Code Coverage Analysis
            </div>
            <div class="section-content">
                <div class="coverage-details">
                    <div class="coverage-metric">
                        <h4>Line Coverage</h4>
                        <div class="percentage" style="color: {get_coverage_color(line_coverage)}">{line_coverage:.1f}%</div>
                        <div>{coverage.get('lines_covered', 0):,} of {coverage.get('lines_valid', 0):,} lines</div>
                    </div>
                    <div class="coverage-metric">
                        <h4>Branch Coverage</h4>
                        <div class="percentage" style="color: {get_coverage_color(branch_coverage)}">{branch_coverage:.1f}%</div>
                        <div>{coverage.get('branches_covered', 0):,} of {coverage.get('branches_valid', 0):,} branches</div>
                    </div>
                </div>
            </div>
        </div>
        """
    
    # Add test suites section
    if test_suites:
        html_content += """
        <div class="section">
            <div class="section-header">
                🔍 Test Suites Breakdown
            </div>
            <div class="section-content">
                <div class="test-suites">
        """
        
        for suite_name, suite_data in test_suites.items():
            suite_total = suite_data.get('total_tests', 0)
            suite_passed = suite_data.get('passed_tests', 0)
            suite_failed = suite_data.get('failed_tests', 0)
            suite_skipped = suite_data.get('skipped_tests', 0)
            suite_error = suite_data.get('error_tests', 0)
            suite_duration = suite_data.get('duration', 0)
            
            suite_success_rate = (suite_passed / suite_total * 100) if suite_total > 0 else 0
            
            html_content += f"""
                    <div class="test-suite">
                        <div class="test-suite-header">
                            <span>{suite_name.title()} Tests</span>
                            <div class="test-suite-stats">
                                <div class="test-suite-stat">
                                    <span class="status-badge status-passed">✅ {suite_passed}</span>
                                </div>
                                <div class="test-suite-stat">
                                    <span class="status-badge status-failed">❌ {suite_failed}</span>
                                </div>
                                <div class="test-suite-stat">
                                    <span class="status-badge status-skipped">⏭️ {suite_skipped}</span>
                                </div>
                                <div class="test-suite-stat">
                                    <span class="status-badge status-error">💥 {suite_error}</span>
                                </div>
                                <div class="test-suite-stat">
                                    <span>⏱️ {suite_duration:.1f}s</span>
                                </div>
                            </div>
                        </div>
                        <div class="section-content">
                            <div class="progress-bar">
                                <div class="progress-fill" style="width: {suite_success_rate}%"></div>
                            </div>
                            <p>Success Rate: <strong style="color: {get_status_color(suite_success_rate)}">{suite_success_rate:.1f}%</strong></p>
                        </div>
                    </div>
            """
        
        html_content += """
                </div>
            </div>
        </div>
        """
    
    # Add footer
    html_content += f"""
        <div class="footer">
            <p><strong>Royal Textiles Odoo Testing Infrastructure</strong></p>
            <p>Task 6.4 - Automated Test Report Generation</p>
            <p class="timestamp">Generated on {datetime.now().strftime('%B %d, %Y at %I:%M %p')}</p>
        </div>
    </div>
</body>
</html>
    """
    
    with open(output_file, 'w') as f:
        f.write(html_content)
    
    print(f"HTML report generated: {output_file}")

def main():
    if len(sys.argv) < 3:
        print("Usage: python generate_html.py <results_file> <output_file> [title]")
        sys.exit(1)
    
    results_file = sys.argv[1]
    output_file = sys.argv[2]
    title = sys.argv[3] if len(sys.argv) > 3 else "Test Report"
    
    results = load_results(results_file)
    if results:
        generate_html_report(results, output_file, title)
    else:
        print("Failed to load results")
        sys.exit(1)

if __name__ == '__main__':
    main()
EOF
    
    # Generate the HTML report
    python "$REPORTS_DIR/generate_html.py" "$results_summary" "$html_report" "$REPORT_TITLE"
    
    if [ -f "$html_report" ]; then
        print_status "HTML report generated: $html_report"
    else
        print_error "Failed to generate HTML report"
    fi
}

# Function to generate test badges
generate_test_badges() {
    print_section "Generating test badges"
    
    local results_summary="$TEST_RESULTS_DIR/summary.json"
    local badges_dir="$REPORTS_DIR/badges"
    
    if [ ! -f "$results_summary" ]; then
        print_warning "No test results available for badge generation"
        return
    fi
    
    # Create badge generator
    cat > "$badges_dir/generate_badges.py" << 'EOF'
import json
import sys
import os

def generate_svg_badge(label, value, color, output_file):
    """Generate SVG badge."""
    
    # Determine color based on value for different badge types
    if 'coverage' in label.lower():
        if float(value.replace('%', '')) >= 80:
            color = '#4c1'
        elif float(value.replace('%', '')) >= 60:
            color = '#dfb317'
        else:
            color = '#e05d44'
    elif 'tests' in label.lower():
        if 'passing' in value.lower() or value == '100%':
            color = '#4c1'
        elif 'failing' in value.lower():
            color = '#e05d44'
        else:
            color = '#dfb317'
    
    # Calculate widths
    label_width = len(label) * 7 + 10
    value_width = len(value) * 7 + 10
    total_width = label_width + value_width
    
    svg_content = f"""<svg xmlns="http://www.w3.org/2000/svg" width="{total_width}" height="20">
    <linearGradient id="b" x2="0" y2="100%">
        <stop offset="0" stop-color="#bbb" stop-opacity=".1"/>
        <stop offset="1" stop-opacity=".1"/>
    </linearGradient>
    <mask id="a">
        <rect width="{total_width}" height="20" rx="3" fill="#fff"/>
    </mask>
    <g mask="url(#a)">
        <path fill="#555" d="M0 0h{label_width}v20H0z"/>
        <path fill="{color}" d="M{label_width} 0h{value_width}v20H{label_width}z"/>
        <path fill="url(#b)" d="M0 0h{total_width}v20H0z"/>
    </g>
    <g fill="#fff" text-anchor="middle" font-family="DejaVu Sans,Verdana,Geneva,sans-serif" font-size="11">
        <text x="{label_width/2}" y="15" fill="#010101" fill-opacity=".3">{label}</text>
        <text x="{label_width/2}" y="14">{label}</text>
        <text x="{label_width + value_width/2}" y="15" fill="#010101" fill-opacity=".3">{value}</text>
        <text x="{label_width + value_width/2}" y="14">{value}</text>
    </g>
</svg>"""
    
    with open(output_file, 'w') as f:
        f.write(svg_content)

def main():
    if len(sys.argv) < 2:
        print("Usage: python generate_badges.py <results_file>")
        sys.exit(1)
    
    results_file = sys.argv[1]
    badges_dir = os.path.dirname(os.path.abspath(__file__))
    
    try:
        with open(results_file, 'r') as f:
            results = json.load(f)
    except Exception as e:
        print(f"Error loading results: {e}")
        sys.exit(1)
    
    summary = results.get('total_summary', {})
    coverage = results.get('coverage', {})
    
    # Generate test results badge
    total_tests = summary.get('total_tests', 0)
    passed_tests = summary.get('passed_tests', 0)
    failed_tests = summary.get('failed_tests', 0)
    
    if total_tests > 0:
        if failed_tests == 0:
            test_status = f"{passed_tests}/{total_tests} passing"
            test_color = '#4c1'
        else:
            test_status = f"{failed_tests}/{total_tests} failing"
            test_color = '#e05d44'
    else:
        test_status = "no tests"
        test_color = '#9f9f9f'
    
    generate_svg_badge("tests", test_status, test_color, 
                      os.path.join(badges_dir, 'tests.svg'))
    
    # Generate coverage badge
    if coverage:
        line_coverage = coverage.get('line_coverage_percent', 0)
        coverage_value = f"{line_coverage:.0f}%"
        generate_svg_badge("coverage", coverage_value, '#4c1', 
                          os.path.join(badges_dir, 'coverage.svg'))
    
    # Generate success rate badge
    success_rate = summary.get('success_rate', 0)
    success_value = f"{success_rate:.0f}%"
    generate_svg_badge("success", success_value, '#4c1', 
                      os.path.join(badges_dir, 'success.svg'))
    
    print(f"Generated badges in {badges_dir}")

if __name__ == '__main__':
    main()
EOF
    
    # Generate badges
    python "$badges_dir/generate_badges.py" "$results_summary"
    
    print_status "Test badges generated"
}

# Function to create index page
create_index_page() {
    print_section "Creating reports index page"
    
    local index_file="$REPORTS_DIR/index.html"
    
    cat > "$index_file" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Royal Textiles Test Reports</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            color: #333;
            background-color: #f8f9fa;
        }
        
        .container {
            max-width: 1000px;
            margin: 0 auto;
            padding: 20px;
        }
        
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 40px 0;
            text-align: center;
            margin-bottom: 40px;
            border-radius: 10px;
        }
        
        .header h1 {
            font-size: 2.5em;
            margin-bottom: 10px;
        }
        
        .header .subtitle {
            font-size: 1.2em;
            opacity: 0.9;
        }
        
        .reports-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
            margin-bottom: 40px;
        }
        
        .report-card {
            background: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            transition: transform 0.3s ease;
        }
        
        .report-card:hover {
            transform: translateY(-5px);
        }
        
        .report-card h3 {
            color: #495057;
            margin-bottom: 15px;
            font-size: 1.3em;
        }
        
        .report-card p {
            color: #6c757d;
            margin-bottom: 20px;
        }
        
        .report-card .btn {
            display: inline-block;
            background: #667eea;
            color: white;
            padding: 12px 24px;
            text-decoration: none;
            border-radius: 5px;
            transition: background 0.3s ease;
        }
        
        .report-card .btn:hover {
            background: #5a6fd8;
        }
        
        .badges-section {
            background: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            margin-bottom: 40px;
        }
        
        .badges-section h2 {
            color: #495057;
            margin-bottom: 20px;
            text-align: center;
        }
        
        .badges {
            display: flex;
            justify-content: center;
            gap: 10px;
            flex-wrap: wrap;
        }
        
        .footer {
            text-align: center;
            color: #6c757d;
            background: white;
            padding: 30px;
            border-radius: 10px;
        }
        
        .icon {
            font-size: 2em;
            margin-bottom: 10px;
        }
        
        @media (max-width: 768px) {
            .reports-grid {
                grid-template-columns: 1fr;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>📊 Royal Textiles Test Reports</h1>
            <div class="subtitle">Comprehensive Testing & Coverage Analysis</div>
        </div>
        
        <div class="badges-section">
            <h2>🏆 Current Status</h2>
            <div class="badges">
                <img src="badges/tests.svg" alt="Test Status" style="height: 20px;">
                <img src="badges/coverage.svg" alt="Coverage Status" style="height: 20px;">
                <img src="badges/success.svg" alt="Success Rate" style="height: 20px;">
            </div>
        </div>
        
        <div class="reports-grid">
            <div class="report-card">
                <div class="icon">🧪</div>
                <h3>Latest Test Report</h3>
                <p>Comprehensive test results with detailed coverage analysis and performance metrics.</p>
                <a href="test-report.html" class="btn">View Report</a>
            </div>
            
            <div class="report-card">
                <div class="icon">📈</div>
                <h3>Coverage Report</h3>
                <p>Detailed code coverage analysis with line-by-line coverage information.</p>
                <a href="coverage/html/index.html" class="btn">View Coverage</a>
            </div>
            
            <div class="report-card">
                <div class="icon">🔍</div>
                <h3>Test Results</h3>
                <p>Raw test results and detailed logs for debugging and analysis.</p>
                <a href="test-results/" class="btn">Browse Results</a>
            </div>
            
            <div class="report-card">
                <div class="icon">🚀</div>
                <h3>Deployment Check</h3>
                <p>Deployment readiness assessment and validation results.</p>
                <a href="deployment-readiness.html" class="btn">Check Status</a>
            </div>
        </div>
        
        <div class="footer">
            <p><strong>Royal Textiles Odoo Testing Infrastructure</strong></p>
            <p>Task 6.4 - Automated Test Report Generation</p>
            <p>Generated automatically with every test run</p>
        </div>
    </div>
</body>
</html>
EOF
    
    print_status "Index page created: $index_file"
}

# Function to publish reports
publish_reports() {
    print_section "Publishing test reports"
    
    # Create a simple HTTP server for local viewing
    local server_port=8081
    
    cat > "$REPORTS_DIR/serve.py" << 'EOF'
#!/usr/bin/env python3
import os
import sys
import webbrowser
from http.server import HTTPServer, SimpleHTTPRequestHandler
import socketserver

class CustomHTTPRequestHandler(SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Cache-Control', 'no-cache, no-store, must-revalidate')
        self.send_header('Pragma', 'no-cache')
        self.send_header('Expires', '0')
        super().end_headers()

def serve_reports(port=8081):
    """Serve test reports on local HTTP server."""
    
    # Change to reports directory
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    
    handler = CustomHTTPRequestHandler
    
    try:
        with socketserver.TCPServer(("", port), handler) as httpd:
            print(f"📊 Serving test reports at http://localhost:{port}/")
            print(f"📊 Main report: http://localhost:{port}/index.html")
            print(f"📊 Coverage: http://localhost:{port}/coverage/html/index.html")
            print("Press Ctrl+C to stop the server")
            
            # Open browser if requested
            if len(sys.argv) > 1 and sys.argv[1] == '--open':
                webbrowser.open(f'http://localhost:{port}/')
            
            httpd.serve_forever()
    
    except KeyboardInterrupt:
        print("\n🛑 Server stopped")
    except OSError as e:
        if e.errno == 48:  # Address already in use
            print(f"❌ Port {port} is already in use")
            print(f"💡 Try a different port: python serve.py {port + 1}")
        else:
            print(f"❌ Error starting server: {e}")

if __name__ == '__main__':
    port = int(sys.argv[1]) if len(sys.argv) > 1 and sys.argv[1].isdigit() else 8081
    serve_reports(port)
EOF
    
    chmod +x "$REPORTS_DIR/serve.py"
    
    print_status "Report server script created"
    print_info "To view reports: cd $REPORTS_DIR && python serve.py --open"
}

# Function to clean old reports
clean_old_reports() {
    print_section "Cleaning old reports"
    
    # Keep last 10 reports
    local keep_count=10
    
    if [ -d "$REPORTS_DIR" ]; then
        # Remove old timestamped reports
        find "$REPORTS_DIR" -name "test-report-*" -type f -print0 | \
        sort -z | head -z -n -$keep_count | xargs -0 rm -f
        
        # Clean old coverage data
        find "$COVERAGE_DIR" -name ".coverage.*" -type f -mtime +7 -delete 2>/dev/null || true
        
        print_status "Old reports cleaned"
    fi
}

# Function to show summary
show_summary() {
    print_header "Test Report Generation Summary"
    echo "============================================"
    echo ""
    
    local results_summary="$TEST_RESULTS_DIR/summary.json"
    
    if [ -f "$results_summary" ]; then
        # Parse and display summary using Python
        python << EOF
import json
import os

try:
    with open('$results_summary', 'r') as f:
        results = json.load(f)
    
    summary = results.get('total_summary', {})
    coverage = results.get('coverage', {})
    
    print("📊 Test Results:")
    print(f"  Total Tests: {summary.get('total_tests', 0):,}")
    print(f"  Passed: {summary.get('passed_tests', 0):,}")
    print(f"  Failed: {summary.get('failed_tests', 0):,}")
    print(f"  Skipped: {summary.get('skipped_tests', 0):,}")
    print(f"  Errors: {summary.get('error_tests', 0):,}")
    print(f"  Success Rate: {summary.get('success_rate', 0):.1f}%")
    print(f"  Duration: {summary.get('duration', 0):.1f}s")
    print("")
    
    if coverage:
        print("📈 Coverage Analysis:")
        print(f"  Line Coverage: {coverage.get('line_coverage_percent', 0):.1f}%")
        print(f"  Branch Coverage: {coverage.get('branch_coverage_percent', 0):.1f}%")
        print(f"  Lines Covered: {coverage.get('lines_covered', 0):,} / {coverage.get('lines_valid', 0):,}")
        print("")
    
    print("📁 Generated Reports:")
    print(f"  HTML Report: $REPORTS_DIR/test-report.html")
    print(f"  Coverage Report: $COVERAGE_DIR/html/index.html")
    print(f"  JSON Summary: $TEST_RESULTS_DIR/summary.json")
    print(f"  Index Page: $REPORTS_DIR/index.html")
    print("")
    
    print("🚀 View Reports:")
    print(f"  cd $REPORTS_DIR && python serve.py --open")
    print("")

except Exception as e:
    print(f"Error reading results: {e}")
EOF
    else
        print_warning "No test results summary available"
    fi
    
    print_info "Reports location: $REPORTS_DIR"
    print_info "Coverage location: $COVERAGE_DIR"
    print_info "Test results location: $TEST_RESULTS_DIR"
}

# Main function
main() {
    local show_help=false
    local skip_tests=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --no-coverage)
                GENERATE_COVERAGE=false
                shift
                ;;
            --no-junit)
                GENERATE_JUNIT=false
                shift
                ;;
            --no-html)
                GENERATE_HTML=false
                shift
                ;;
            --no-badges)
                GENERATE_BADGES=false
                shift
                ;;
            --skip-tests)
                RUN_TESTS=false
                shift
                ;;
            --threshold)
                COVERAGE_THRESHOLD="$2"
                shift 2
                ;;
            --open)
                OPEN_BROWSER=true
                shift
                ;;
            --publish)
                PUBLISH_REPORTS=true
                shift
                ;;
            --title)
                REPORT_TITLE="$2"
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
        echo "Royal Textiles Automated Test Report Generation"
        echo "============================================="
        echo ""
        echo "Usage: $0 [options]"
        echo ""
        echo "Options:"
        echo "  --no-coverage      Skip coverage report generation"
        echo "  --no-junit         Skip JUnit XML report generation"
        echo "  --no-html          Skip HTML report generation"
        echo "  --no-badges        Skip badge generation"
        echo "  --skip-tests       Skip test execution (use existing results)"
        echo "  --threshold N      Coverage threshold percentage (default: 70)"
        echo "  --open             Open reports in browser after generation"
        echo "  --publish          Start HTTP server for reports"
        echo "  --title TITLE      Custom report title"
        echo "  --help, -h         Show this help message"
        echo ""
        echo "Examples:"
        echo "  $0                                    # Full report generation"
        echo "  $0 --skip-tests --open               # Generate reports from existing results"
        echo "  $0 --threshold 80 --publish          # Higher coverage threshold with server"
        echo "  $0 --no-coverage --title 'Quick Test' # Quick test without coverage"
        echo ""
        exit 0
    fi
    
    # Header
    print_header "Royal Textiles Automated Test Report Generation"
    echo "=============================================="
    echo ""
    print_info "Coverage: $GENERATE_COVERAGE"
    print_info "JUnit XML: $GENERATE_JUNIT"
    print_info "HTML Reports: $GENERATE_HTML"
    print_info "Badge Generation: $GENERATE_BADGES"
    print_info "Coverage Threshold: $COVERAGE_THRESHOLD%"
    print_info "Report Title: $REPORT_TITLE"
    echo ""
    
    # Setup
    setup_directories
    clean_old_reports
    
    # Run tests if requested
    if [ "$RUN_TESTS" = true ]; then
        run_test_suite
    else
        print_info "Skipping test execution (using existing results)"
    fi
    
    # Process results
    parse_test_results
    
    # Generate reports
    if [ "$GENERATE_HTML" = true ]; then
        generate_html_report
    fi
    
    if [ "$GENERATE_BADGES" = true ]; then
        generate_test_badges
    fi
    
    # Create index page
    create_index_page
    
    # Publish reports if requested
    if [ "$PUBLISH_REPORTS" = true ]; then
        publish_reports
    fi
    
    # Show summary
    show_summary
    
    # Open browser if requested
    if [ "$OPEN_BROWSER" = true ]; then
        if command -v open >/dev/null 2>&1; then
            open "$REPORTS_DIR/index.html"
        elif command -v xdg-open >/dev/null 2>&1; then
            xdg-open "$REPORTS_DIR/index.html"
        else
            print_info "To view reports: open $REPORTS_DIR/index.html"
        fi
    fi
    
    print_header "Test Report Generation Complete!"
    echo ""
}

# Run the main function
main "$@" 
#!/bin/bash

# =====================================
# Royal Textiles Automated Dependency & Security Scanner
# =====================================
# Task 6.6: Set up automated dependency checking and security scanning
# This script provides comprehensive dependency analysis and security scanning

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
SCAN_DIR="$PROJECT_ROOT/reports/security-dependency-scan"
REPORTS_DIR="$SCAN_DIR/reports"
LOGS_DIR="$SCAN_DIR/logs"
ARTIFACTS_DIR="$SCAN_DIR/artifacts"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
SCAN_ID="security-scan-$TIMESTAMP"

# Scan settings
DEPENDENCY_SCAN=true
SECURITY_SCAN=true
LICENSE_SCAN=true
VULNERABILITY_SCAN=true
SECRET_SCAN=true
COMPLIANCE_SCAN=true
OUTDATED_SCAN=true
GENERATE_REPORTS=true
FAIL_ON_CRITICAL=true
FAIL_ON_HIGH=false
VERBOSE=false
QUIET=false

# Global tracking variables
TOTAL_VULNERABILITIES=0
CRITICAL_VULNERABILITIES=0
HIGH_VULNERABILITIES=0
MEDIUM_VULNERABILITIES=0
LOW_VULNERABILITIES=0
TOTAL_DEPENDENCIES=0
OUTDATED_DEPENDENCIES=0
LICENSE_ISSUES=0
SECRETS_FOUND=0
COMPLIANCE_ISSUES=0

CRITICAL_ISSUES=()
HIGH_ISSUES=()
MEDIUM_ISSUES=()
LOW_ISSUES=()
RECOMMENDATIONS=()

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

print_critical() {
    echo -e "${RED}🚨 $1${NC}"
}

print_success() {
    echo -e "${GREEN}🎉 $1${NC}"
}

# Function to log messages
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$LOGS_DIR/scan.log"

    if [ "$VERBOSE" = true ]; then
        echo "[$timestamp] [$level] $message"
    fi
}

# Function to setup scan environment
setup_scan_environment() {
    print_section "Setting up dependency and security scan environment"

    # Create directory structure
    mkdir -p "$SCAN_DIR"
    mkdir -p "$REPORTS_DIR"
    mkdir -p "$LOGS_DIR"
    mkdir -p "$ARTIFACTS_DIR"

    # Initialize log file
    cat > "$LOGS_DIR/scan.log" << EOF
===============================================
Royal Textiles Dependency & Security Scan Log
===============================================
Scan ID: $SCAN_ID
Timestamp: $(date)
Project Root: $PROJECT_ROOT
Dependency Scan: $DEPENDENCY_SCAN
Security Scan: $SECURITY_SCAN
License Scan: $LICENSE_SCAN
Vulnerability Scan: $VULNERABILITY_SCAN
Secret Scan: $SECRET_SCAN
===============================================

EOF

    print_status "Scan environment initialized"
    log_message "INFO" "Scan environment initialized: $SCAN_ID"
}

# Function to install scanning tools
install_scanning_tools() {
    print_section "Installing and verifying scanning tools"

    # Check if pip-audit is available for vulnerability scanning
    if ! command -v pip-audit >/dev/null 2>&1; then
        print_info "Installing pip-audit for vulnerability scanning..."
        pip install pip-audit 2>/dev/null || {
            print_warning "Failed to install pip-audit, vulnerability scanning will be limited"
        }
    fi

    # Check if safety is available
    if ! command -v safety >/dev/null 2>&1; then
        print_info "Installing safety for dependency vulnerability scanning..."
        pip install safety 2>/dev/null || {
            print_warning "Failed to install safety, using alternative methods"
        }
    fi

    # Check if bandit is available for security scanning
    if ! command -v bandit >/dev/null 2>&1; then
        print_info "Installing bandit for security analysis..."
        pip install bandit 2>/dev/null || {
            print_warning "Failed to install bandit, security scanning will be limited"
        }
    fi

    # Check if semgrep is available
    if ! command -v semgrep >/dev/null 2>&1; then
        print_info "Semgrep not available, using alternative security scanning methods"
    fi

    # Check if pip-licenses is available
    if ! command -v pip-licenses >/dev/null 2>&1; then
        print_info "Installing pip-licenses for license analysis..."
        pip install pip-licenses 2>/dev/null || {
            print_warning "Failed to install pip-licenses, license scanning will be limited"
        }
    fi

    # Check if pip-check is available
    if ! command -v pip-check >/dev/null 2>&1; then
        print_info "Installing pip-check for dependency analysis..."
        pip install pip-check 2>/dev/null || {
            print_warning "Failed to install pip-check, using alternative methods"
        }
    fi

    print_status "Scanning tools verification completed"
}

# Function to perform dependency analysis
perform_dependency_analysis() {
    print_section "Performing dependency analysis"

    if [ "$DEPENDENCY_SCAN" = false ]; then
        print_info "Dependency scanning disabled"
        return
    fi

    local dep_report="$REPORTS_DIR/dependency-analysis.json"
    local requirements_file="$PROJECT_ROOT/requirements.txt"

    # Check if requirements.txt exists
    if [ ! -f "$requirements_file" ]; then
        print_warning "No requirements.txt found, creating from current environment"
        pip freeze > "$requirements_file.generated"
        requirements_file="$requirements_file.generated"
    fi

    # Count total dependencies
    TOTAL_DEPENDENCIES=$(wc -l < "$requirements_file" 2>/dev/null || echo 0)

    # Create dependency analysis
    cat > "$ARTIFACTS_DIR/analyze_dependencies.py" << 'EOF'
import json
import sys
import subprocess
import re
from datetime import datetime

def analyze_requirements_file(file_path):
    """Analyze requirements.txt file for dependency information."""
    dependencies = []

    try:
        with open(file_path, 'r') as f:
            lines = f.readlines()

        for line in lines:
            line = line.strip()
            if line and not line.startswith('#'):
                # Parse package name and version
                if '==' in line:
                    package, version = line.split('==', 1)
                elif '>=' in line:
                    package, version = line.split('>=', 1)
                    version = f">={version}"
                elif '<=' in line:
                    package, version = line.split('<=', 1)
                    version = f"<={version}"
                elif '>' in line:
                    package, version = line.split('>', 1)
                    version = f">{version}"
                elif '<' in line:
                    package, version = line.split('<', 1)
                    version = f"<{version}"
                else:
                    package = line
                    version = "latest"

                dependencies.append({
                    'name': package.strip(),
                    'version': version.strip(),
                    'specification': line
                })

    except Exception as e:
        print(f"Error analyzing requirements file: {e}")
        return []

    return dependencies

def get_installed_packages():
    """Get list of installed packages with versions."""
    try:
        result = subprocess.run(['pip', 'list', '--format=json'],
                              capture_output=True, text=True)
        if result.returncode == 0:
            return json.loads(result.stdout)
    except Exception as e:
        print(f"Error getting installed packages: {e}")

    return []

def check_outdated_packages():
    """Check for outdated packages."""
    outdated = []

    try:
        result = subprocess.run(['pip', 'list', '--outdated', '--format=json'],
                              capture_output=True, text=True)
        if result.returncode == 0:
            outdated = json.loads(result.stdout)
    except Exception as e:
        print(f"Error checking outdated packages: {e}")

    return outdated

def analyze_dependency_conflicts():
    """Check for dependency conflicts."""
    conflicts = []

    try:
        result = subprocess.run(['pip', 'check'],
                              capture_output=True, text=True)
        if result.returncode != 0:
            # Parse pip check output for conflicts
            lines = result.stdout.split('\n')
            for line in lines:
                if line.strip():
                    conflicts.append(line.strip())
    except Exception as e:
        print(f"Error checking dependency conflicts: {e}")

    return conflicts

def main():
    if len(sys.argv) < 2:
        print("Usage: python analyze_dependencies.py <requirements_file>")
        sys.exit(1)

    requirements_file = sys.argv[1]
    output_file = sys.argv[2] if len(sys.argv) > 2 else 'dependency-analysis.json'

    # Analyze dependencies
    dependencies = analyze_requirements_file(requirements_file)
    installed_packages = get_installed_packages()
    outdated_packages = check_outdated_packages()
    conflicts = analyze_dependency_conflicts()

    # Create analysis report
    analysis = {
        'scan_timestamp': datetime.now().isoformat(),
        'requirements_file': requirements_file,
        'total_dependencies': len(dependencies),
        'dependencies': dependencies,
        'installed_packages': installed_packages,
        'outdated_packages': outdated_packages,
        'outdated_count': len(outdated_packages),
        'dependency_conflicts': conflicts,
        'conflict_count': len(conflicts),
        'analysis_summary': {
            'total_requirements': len(dependencies),
            'total_installed': len(installed_packages),
            'total_outdated': len(outdated_packages),
            'total_conflicts': len(conflicts)
        }
    }

    # Write analysis to file
    with open(output_file, 'w') as f:
        json.dump(analysis, f, indent=2)

    print(f"Dependency analysis completed: {output_file}")
    print(f"Total dependencies: {len(dependencies)}")
    print(f"Outdated packages: {len(outdated_packages)}")
    print(f"Conflicts: {len(conflicts)}")

if __name__ == '__main__':
    main()
EOF

    # Run dependency analysis
    python "$ARTIFACTS_DIR/analyze_dependencies.py" "$requirements_file" "$dep_report"

    # Extract key metrics
    if [ -f "$dep_report" ]; then
        OUTDATED_DEPENDENCIES=$(python -c "
import json
with open('$dep_report') as f:
    data = json.load(f)
print(data.get('outdated_count', 0))
" 2>/dev/null || echo 0)

        print_status "Dependency analysis completed"
        print_info "Total dependencies: $TOTAL_DEPENDENCIES"
        print_info "Outdated dependencies: $OUTDATED_DEPENDENCIES"
    else
        print_error "Dependency analysis failed"
    fi
}

# Function to perform vulnerability scanning
perform_vulnerability_scanning() {
    print_section "Performing vulnerability scanning"

    if [ "$VULNERABILITY_SCAN" = false ]; then
        print_info "Vulnerability scanning disabled"
        return
    fi

    local vuln_report="$REPORTS_DIR/vulnerability-scan.json"
    local vuln_summary="$REPORTS_DIR/vulnerability-summary.txt"

    # Try pip-audit first
    if command -v pip-audit >/dev/null 2>&1; then
        print_info "Running pip-audit vulnerability scan..."

        pip-audit --format=json --output="$vuln_report" 2>/dev/null || {
            print_warning "pip-audit scan failed, trying alternative methods"
            echo '{"vulnerabilities": []}' > "$vuln_report"
        }
    else
        # Try safety as alternative
        if command -v safety >/dev/null 2>&1; then
            print_info "Running safety vulnerability scan..."

            safety check --json --output="$vuln_report" 2>/dev/null || {
                print_warning "safety scan failed, using manual vulnerability detection"
                echo '{"vulnerabilities": []}' > "$vuln_report"
            }
        else
            print_warning "No vulnerability scanning tools available"
            echo '{"vulnerabilities": []}' > "$vuln_report"
        fi
    fi

    # Parse vulnerability results
    if [ -f "$vuln_report" ]; then
        python << EOF
import json
import sys

try:
    with open('$vuln_report', 'r') as f:
        data = json.load(f)

    vulnerabilities = data.get('vulnerabilities', [])

    critical = sum(1 for v in vulnerabilities if v.get('severity', '').lower() == 'critical')
    high = sum(1 for v in vulnerabilities if v.get('severity', '').lower() == 'high')
    medium = sum(1 for v in vulnerabilities if v.get('severity', '').lower() == 'medium')
    low = sum(1 for v in vulnerabilities if v.get('severity', '').lower() == 'low')
    total = len(vulnerabilities)

    print(f"TOTAL_VULNERABILITIES={total}")
    print(f"CRITICAL_VULNERABILITIES={critical}")
    print(f"HIGH_VULNERABILITIES={high}")
    print(f"MEDIUM_VULNERABILITIES={medium}")
    print(f"LOW_VULNERABILITIES={low}")

    # Write summary
    with open('$vuln_summary', 'w') as f:
        f.write(f"Vulnerability Scan Summary\\n")
        f.write(f"========================\\n")
        f.write(f"Total Vulnerabilities: {total}\\n")
        f.write(f"Critical: {critical}\\n")
        f.write(f"High: {high}\\n")
        f.write(f"Medium: {medium}\\n")
        f.write(f"Low: {low}\\n\\n")

        if vulnerabilities:
            f.write("Vulnerability Details:\\n")
            f.write("--------------------\\n")
            for i, vuln in enumerate(vulnerabilities[:10], 1):  # Show first 10
                f.write(f"{i}. {vuln.get('package', 'Unknown')} - {vuln.get('vulnerability_id', 'N/A')}\\n")
                f.write(f"   Severity: {vuln.get('severity', 'Unknown')}\\n")
                f.write(f"   Summary: {vuln.get('summary', 'No description')}\\n\\n")

except Exception as e:
    print(f"Error parsing vulnerability report: {e}")
    print("TOTAL_VULNERABILITIES=0")
    print("CRITICAL_VULNERABILITIES=0")
    print("HIGH_VULNERABILITIES=0")
    print("MEDIUM_VULNERABILITIES=0")
    print("LOW_VULNERABILITIES=0")
EOF

        # Extract vulnerability counts
        eval $(python << EOF
import json
try:
    with open('$vuln_report', 'r') as f:
        data = json.load(f)
    vulnerabilities = data.get('vulnerabilities', [])
    critical = sum(1 for v in vulnerabilities if v.get('severity', '').lower() == 'critical')
    high = sum(1 for v in vulnerabilities if v.get('severity', '').lower() == 'high')
    medium = sum(1 for v in vulnerabilities if v.get('severity', '').lower() == 'medium')
    low = sum(1 for v in vulnerabilities if v.get('severity', '').lower() == 'low')
    total = len(vulnerabilities)
    print(f"TOTAL_VULNERABILITIES={total}")
    print(f"CRITICAL_VULNERABILITIES={critical}")
    print(f"HIGH_VULNERABILITIES={high}")
    print(f"MEDIUM_VULNERABILITIES={medium}")
    print(f"LOW_VULNERABILITIES={low}")
except:
    print("TOTAL_VULNERABILITIES=0")
    print("CRITICAL_VULNERABILITIES=0")
    print("HIGH_VULNERABILITIES=0")
    print("MEDIUM_VULNERABILITIES=0")
    print("LOW_VULNERABILITIES=0")
EOF
)

        print_status "Vulnerability scanning completed"
        print_info "Total vulnerabilities: $TOTAL_VULNERABILITIES"
        if [ "$CRITICAL_VULNERABILITIES" -gt 0 ]; then
            print_critical "Critical vulnerabilities: $CRITICAL_VULNERABILITIES"
        fi
        if [ "$HIGH_VULNERABILITIES" -gt 0 ]; then
            print_error "High vulnerabilities: $HIGH_VULNERABILITIES"
        fi
    else
        print_error "Vulnerability scanning failed"
    fi
}

# Function to perform security scanning
perform_security_scanning() {
    print_section "Performing security code analysis"

    if [ "$SECURITY_SCAN" = false ]; then
        print_info "Security scanning disabled"
        return
    fi

    local security_report="$REPORTS_DIR/security-scan.json"
    local security_summary="$REPORTS_DIR/security-summary.txt"

    # Try bandit for Python security analysis
    if command -v bandit >/dev/null 2>&1; then
        print_info "Running bandit security analysis..."

        bandit -r "$PROJECT_ROOT/custom_modules" -f json -o "$security_report" 2>/dev/null || {
            print_warning "bandit scan failed, using manual security checks"
        }
    else
        print_info "Running manual security pattern analysis..."

        # Manual security pattern detection
        cat > "$ARTIFACTS_DIR/security_scanner.py" << 'EOF'
import os
import re
import json
from datetime import datetime

def scan_for_security_patterns(directory):
    """Scan for common security issues in Python code."""
    patterns = {
        'hardcoded_passwords': [
            r'password\s*=\s*["\'][^"\']+["\']',
            r'passwd\s*=\s*["\'][^"\']+["\']',
            r'pwd\s*=\s*["\'][^"\']+["\']'
        ],
        'hardcoded_secrets': [
            r'secret\s*=\s*["\'][^"\']+["\']',
            r'token\s*=\s*["\'][^"\']+["\']',
            r'api_key\s*=\s*["\'][^"\']+["\']',
            r'private_key\s*=\s*["\'][^"\']+["\']'
        ],
        'sql_injection': [
            r'execute\s*\(\s*["\'][^"\']*%[^"\']*["\']',
            r'query\s*\(\s*["\'][^"\']*%[^"\']*["\']',
            r'SELECT\s+.*%.*FROM',
            r'INSERT\s+.*%.*INTO',
            r'UPDATE\s+.*%.*SET',
            r'DELETE\s+.*%.*FROM'
        ],
        'command_injection': [
            r'os\.system\s*\(',
            r'subprocess\.call\s*\([^)]*shell\s*=\s*True',
            r'subprocess\.run\s*\([^)]*shell\s*=\s*True',
            r'eval\s*\(',
            r'exec\s*\('
        ],
        'insecure_random': [
            r'random\.random\s*\(',
            r'random\.randint\s*\(',
            r'random\.choice\s*\('
        ],
        'debug_code': [
            r'print\s*\(',
            r'console\.log\s*\(',
            r'debugger;',
            r'DEBUG\s*=\s*True'
        ]
    }

    issues = []

    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.py'):
                file_path = os.path.join(root, file)
                try:
                    with open(file_path, 'r', encoding='utf-8') as f:
                        content = f.read()

                    for category, pattern_list in patterns.items():
                        for pattern in pattern_list:
                            matches = re.finditer(pattern, content, re.IGNORECASE | re.MULTILINE)
                            for match in matches:
                                line_num = content[:match.start()].count('\n') + 1
                                issues.append({
                                    'file': file_path,
                                    'line': line_num,
                                    'category': category,
                                    'pattern': pattern,
                                    'match': match.group(),
                                    'severity': 'high' if category in ['sql_injection', 'command_injection'] else 'medium'
                                })

                except Exception as e:
                    print(f"Error scanning {file_path}: {e}")

    return issues

def main():
    import sys

    if len(sys.argv) < 2:
        print("Usage: python security_scanner.py <directory> [output_file]")
        sys.exit(1)

    directory = sys.argv[1]
    output_file = sys.argv[2] if len(sys.argv) > 2 else 'security-scan.json'

    issues = scan_for_security_patterns(directory)

    report = {
        'scan_timestamp': datetime.now().isoformat(),
        'scanned_directory': directory,
        'total_issues': len(issues),
        'issues': issues,
        'summary': {
            'high_severity': sum(1 for issue in issues if issue['severity'] == 'high'),
            'medium_severity': sum(1 for issue in issues if issue['severity'] == 'medium'),
            'low_severity': sum(1 for issue in issues if issue['severity'] == 'low')
        }
    }

    with open(output_file, 'w') as f:
        json.dump(report, f, indent=2)

    print(f"Security scan completed: {output_file}")
    print(f"Total issues found: {len(issues)}")

if __name__ == '__main__':
    main()
EOF

        python "$ARTIFACTS_DIR/security_scanner.py" "$PROJECT_ROOT/custom_modules" "$security_report"
    fi

    # Parse security results
    if [ -f "$security_report" ]; then
        python << EOF
import json

try:
    with open('$security_report', 'r') as f:
        data = json.load(f)

    # Handle different report formats
    if 'issues' in data:
        issues = data['issues']
    elif 'results' in data:
        issues = data['results']
    else:
        issues = []

    total_issues = len(issues)
    high_issues = sum(1 for issue in issues if issue.get('severity', '').lower() in ['high', 'critical'])
    medium_issues = sum(1 for issue in issues if issue.get('severity', '').lower() == 'medium')
    low_issues = sum(1 for issue in issues if issue.get('severity', '').lower() == 'low')

    # Write summary
    with open('$security_summary', 'w') as f:
        f.write(f"Security Scan Summary\\n")
        f.write(f"===================\\n")
        f.write(f"Total Issues: {total_issues}\\n")
        f.write(f"High/Critical: {high_issues}\\n")
        f.write(f"Medium: {medium_issues}\\n")
        f.write(f"Low: {low_issues}\\n\\n")

        if issues:
            f.write("Security Issues:\\n")
            f.write("---------------\\n")
            for i, issue in enumerate(issues[:10], 1):  # Show first 10
                f.write(f"{i}. {issue.get('category', 'Unknown')}\\n")
                f.write(f"   File: {issue.get('file', 'Unknown')}\\n")
                f.write(f"   Line: {issue.get('line', 'Unknown')}\\n")
                f.write(f"   Severity: {issue.get('severity', 'Unknown')}\\n\\n")

except Exception as e:
    print(f"Error parsing security report: {e}")
EOF

        print_status "Security scanning completed"
    else
        print_error "Security scanning failed"
    fi
}

# Function to perform license scanning
perform_license_scanning() {
    print_section "Performing license analysis"

    if [ "$LICENSE_SCAN" = false ]; then
        print_info "License scanning disabled"
        return
    fi

    local license_report="$REPORTS_DIR/license-scan.json"

    # Try pip-licenses
    if command -v pip-licenses >/dev/null 2>&1; then
        print_info "Running pip-licenses analysis..."

        pip-licenses --format=json --output-file="$license_report" 2>/dev/null || {
            print_warning "pip-licenses failed, using alternative method"
        }
    else
        print_info "Running manual license detection..."

        # Manual license detection
        pip list --format=json > "$ARTIFACTS_DIR/packages.json"

        cat > "$ARTIFACTS_DIR/license_scanner.py" << 'EOF'
import json
import subprocess
import sys
from datetime import datetime

def get_package_info(package_name):
    """Get package information including license."""
    try:
        result = subprocess.run(['pip', 'show', package_name],
                              capture_output=True, text=True)
        if result.returncode == 0:
            info = {}
            for line in result.stdout.split('\n'):
                if ':' in line:
                    key, value = line.split(':', 1)
                    info[key.strip().lower()] = value.strip()
            return info
    except:
        pass
    return {}

def analyze_licenses():
    """Analyze licenses of installed packages."""

    try:
        with open('packages.json', 'r') as f:
            packages = json.load(f)
    except:
        packages = []

    license_info = []

    for package in packages:
        name = package.get('name', '')
        version = package.get('version', '')

        info = get_package_info(name)
        license_name = info.get('license', 'Unknown')

        license_info.append({
            'name': name,
            'version': version,
            'license': license_name,
            'author': info.get('author', 'Unknown'),
            'summary': info.get('summary', '')
        })

    # Categorize licenses
    restrictive_licenses = ['GPL', 'AGPL', 'LGPL']
    permissive_licenses = ['MIT', 'BSD', 'Apache', 'ISC']

    analysis = {
        'scan_timestamp': datetime.now().isoformat(),
        'total_packages': len(license_info),
        'licenses': license_info,
        'summary': {
            'unknown_licenses': sum(1 for pkg in license_info if pkg['license'] == 'Unknown'),
            'restrictive_licenses': sum(1 for pkg in license_info if any(rl in pkg['license'] for rl in restrictive_licenses)),
            'permissive_licenses': sum(1 for pkg in license_info if any(pl in pkg['license'] for pl in permissive_licenses))
        }
    }

    return analysis

def main():
    output_file = sys.argv[1] if len(sys.argv) > 1 else 'license-scan.json'

    analysis = analyze_licenses()

    with open(output_file, 'w') as f:
        json.dump(analysis, f, indent=2)

    print(f"License analysis completed: {output_file}")

if __name__ == '__main__':
    main()
EOF

        cd "$ARTIFACTS_DIR"
        python license_scanner.py "$license_report"
        cd "$PROJECT_ROOT"
    fi

    # Parse license results
    if [ -f "$license_report" ]; then
        LICENSE_ISSUES=$(python -c "
import json
try:
    with open('$license_report') as f:
        data = json.load(f)

    if isinstance(data, list):
        licenses = data
    else:
        licenses = data.get('licenses', [])

    # Count potential license issues
    restrictive = sum(1 for pkg in licenses if any(x in pkg.get('license', '') for x in ['GPL', 'AGPL']))
    unknown = sum(1 for pkg in licenses if pkg.get('license', '') in ['Unknown', '', 'UNKNOWN'])

    print(restrictive + unknown)
except:
    print(0)
" 2>/dev/null || echo 0)

        print_status "License scanning completed"
        print_info "License issues found: $LICENSE_ISSUES"
    else
        print_error "License scanning failed"
    fi
}

# Function to perform secret scanning
perform_secret_scanning() {
    print_section "Performing secret detection"

    if [ "$SECRET_SCAN" = false ]; then
        print_info "Secret scanning disabled"
        return
    fi

    local secrets_report="$REPORTS_DIR/secrets-scan.json"

    # Manual secret detection
    print_info "Running secret pattern detection..."

    cat > "$ARTIFACTS_DIR/secret_scanner.py" << 'EOF'
import os
import re
import json
from datetime import datetime

def scan_for_secrets(directory):
    """Scan for potential secrets in code files."""

    secret_patterns = {
        'aws_access_key': r'AKIA[0-9A-Z]{16}',
        'aws_secret_key': r'[0-9a-zA-Z/+]{40}',
        'api_key': r'api[_-]?key["\']?\s*[:=]\s*["\'][^"\']+["\']',
        'password': r'password["\']?\s*[:=]\s*["\'][^"\']+["\']',
        'secret': r'secret["\']?\s*[:=]\s*["\'][^"\']+["\']',
        'token': r'token["\']?\s*[:=]\s*["\'][^"\']+["\']',
        'private_key': r'-----BEGIN\s+(RSA\s+)?PRIVATE\s+KEY-----',
        'database_url': r'(postgres|mysql|mongodb)://[^\\s]+',
        'email_password': r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}:[^\\s]+',
        'generic_secret': r'["\'][0-9a-f]{32,}["\']'
    }

    secrets_found = []

    for root, dirs, files in os.walk(directory):
        # Skip hidden directories and common ignore patterns
        dirs[:] = [d for d in dirs if not d.startswith('.') and d not in ['__pycache__', 'node_modules', 'venv', 'env', 'virtualenv', '.git', '.pytest_cache', 'htmlcov']]

        for file in files:
            if file.endswith(('.py', '.js', '.yaml', '.yml', '.json', '.txt', '.env')):
                file_path = os.path.join(root, file)

                try:
                    with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                        content = f.read()

                    for secret_type, pattern in secret_patterns.items():
                        matches = re.finditer(pattern, content, re.IGNORECASE | re.MULTILINE)

                        for match in matches:
                            line_num = content[:match.start()].count('\\n') + 1

                            # Skip common false positives
                            match_text = match.group()
                            if any(fp in match_text.lower() for fp in ['example', 'placeholder', 'dummy', 'test', 'fake']):
                                continue

                            secrets_found.append({
                                'file': file_path,
                                'line': line_num,
                                'type': secret_type,
                                'pattern': pattern,
                                'match': match_text[:50] + '...' if len(match_text) > 50 else match_text,
                                'severity': 'high' if secret_type in ['aws_access_key', 'aws_secret_key', 'private_key'] else 'medium'
                            })

                except Exception as e:
                    print(f"Error scanning {file_path}: {e}")

    return secrets_found

def main():
    import sys

    if len(sys.argv) < 2:
        print("Usage: python secret_scanner.py <directory> [output_file]")
        sys.exit(1)

    directory = sys.argv[1]
    output_file = sys.argv[2] if len(sys.argv) > 2 else 'secrets-scan.json'

    secrets = scan_for_secrets(directory)

    report = {
        'scan_timestamp': datetime.now().isoformat(),
        'scanned_directory': directory,
        'total_secrets': len(secrets),
        'secrets': secrets,
        'summary': {
            'high_severity': sum(1 for s in secrets if s['severity'] == 'high'),
            'medium_severity': sum(1 for s in secrets if s['severity'] == 'medium'),
            'by_type': {}
        }
    }

    # Count by type
    for secret in secrets:
        secret_type = secret['type']
        if secret_type not in report['summary']['by_type']:
            report['summary']['by_type'][secret_type] = 0
        report['summary']['by_type'][secret_type] += 1

    with open(output_file, 'w') as f:
        json.dump(report, f, indent=2)

    print(f"Secret scan completed: {output_file}")
    print(f"Potential secrets found: {len(secrets)}")

if __name__ == '__main__':
    main()
EOF

    python "$ARTIFACTS_DIR/secret_scanner.py" "$PROJECT_ROOT/custom_modules" "$secrets_report"

    # Parse secret results
    if [ -f "$secrets_report" ]; then
        SECRETS_FOUND=$(python -c "
import json
try:
    with open('$secrets_report') as f:
        data = json.load(f)
    print(data.get('total_secrets', 0))
except:
    print(0)
" 2>/dev/null || echo 0)

        print_status "Secret scanning completed"
        if [ "$SECRETS_FOUND" -gt 0 ]; then
            print_critical "Potential secrets found: $SECRETS_FOUND"
        else
            print_info "No potential secrets found"
        fi
    else
        print_error "Secret scanning failed"
    fi
}

# Function to generate comprehensive report
generate_comprehensive_report() {
    print_section "Generating comprehensive security and dependency report"

    local final_report="$REPORTS_DIR/comprehensive-security-report.html"
    local json_report="$REPORTS_DIR/comprehensive-security-report.json"

    # Create JSON summary report
    cat > "$ARTIFACTS_DIR/generate_report.py" << 'EOF'
import json
import os
from datetime import datetime

def load_json_file(file_path):
    """Load JSON file if it exists."""
    try:
        if os.path.exists(file_path):
            with open(file_path, 'r') as f:
                return json.load(f)
    except:
        pass
    return {}

def generate_comprehensive_report(reports_dir, output_file):
    """Generate comprehensive security and dependency report."""

    # Load individual reports
    dependency_report = load_json_file(os.path.join(reports_dir, 'dependency-analysis.json'))
    vulnerability_report = load_json_file(os.path.join(reports_dir, 'vulnerability-scan.json'))
    security_report = load_json_file(os.path.join(reports_dir, 'security-scan.json'))
    license_report = load_json_file(os.path.join(reports_dir, 'license-scan.json'))
    secrets_report = load_json_file(os.path.join(reports_dir, 'secrets-scan.json'))

    # Calculate overall risk score
    def calculate_risk_score():
        score = 0

        # Vulnerability score (40% weight)
        vuln_score = 0
        vulnerabilities = vulnerability_report.get('vulnerabilities', [])
        for vuln in vulnerabilities:
            severity = vuln.get('severity', '').lower()
            if severity == 'critical':
                vuln_score += 10
            elif severity == 'high':
                vuln_score += 7
            elif severity == 'medium':
                vuln_score += 4
            elif severity == 'low':
                vuln_score += 1

        score += min(vuln_score, 100) * 0.4

        # Security issues score (30% weight)
        security_score = 0
        security_issues = security_report.get('issues', [])
        for issue in security_issues:
            severity = issue.get('severity', '').lower()
            if severity in ['critical', 'high']:
                security_score += 8
            elif severity == 'medium':
                security_score += 5
            elif severity == 'low':
                security_score += 2

        score += min(security_score, 100) * 0.3

        # Secrets score (20% weight)
        secrets_score = secrets_report.get('total_secrets', 0) * 15
        score += min(secrets_score, 100) * 0.2

        # License issues score (10% weight)
        license_summary = license_report.get('summary', {})
        license_score = (license_summary.get('unknown_licenses', 0) +
                        license_summary.get('restrictive_licenses', 0)) * 5
        score += min(license_score, 100) * 0.1

        return min(score, 100)

    risk_score = calculate_risk_score()

    # Determine risk level
    if risk_score >= 80:
        risk_level = 'CRITICAL'
    elif risk_score >= 60:
        risk_level = 'HIGH'
    elif risk_score >= 40:
        risk_level = 'MEDIUM'
    elif risk_score >= 20:
        risk_level = 'LOW'
    else:
        risk_level = 'MINIMAL'

    # Create comprehensive report
    report = {
        'scan_timestamp': datetime.now().isoformat(),
        'risk_assessment': {
            'overall_risk_score': round(risk_score, 2),
            'risk_level': risk_level,
            'deployment_recommended': risk_score < 60
        },
        'summary': {
            'total_dependencies': dependency_report.get('total_dependencies', 0),
            'outdated_dependencies': dependency_report.get('outdated_count', 0),
            'total_vulnerabilities': len(vulnerability_report.get('vulnerabilities', [])),
            'critical_vulnerabilities': sum(1 for v in vulnerability_report.get('vulnerabilities', [])
                                          if v.get('severity', '').lower() == 'critical'),
            'high_vulnerabilities': sum(1 for v in vulnerability_report.get('vulnerabilities', [])
                                      if v.get('severity', '').lower() == 'high'),
            'security_issues': len(security_report.get('issues', [])),
            'secrets_found': secrets_report.get('total_secrets', 0),
            'license_issues': license_report.get('summary', {}).get('unknown_licenses', 0) +
                             license_report.get('summary', {}).get('restrictive_licenses', 0)
        },
        'reports': {
            'dependencies': dependency_report,
            'vulnerabilities': vulnerability_report,
            'security': security_report,
            'licenses': license_report,
            'secrets': secrets_report
        },
        'recommendations': []
    }

    # Generate recommendations
    recommendations = []

    if report['summary']['critical_vulnerabilities'] > 0:
        recommendations.append({
            'priority': 'CRITICAL',
            'category': 'Vulnerabilities',
            'description': f"Address {report['summary']['critical_vulnerabilities']} critical vulnerabilities immediately",
            'action': 'Update affected packages to secure versions'
        })

    if report['summary']['secrets_found'] > 0:
        recommendations.append({
            'priority': 'HIGH',
            'category': 'Secrets',
            'description': f"Remove {report['summary']['secrets_found']} potential secrets from code",
            'action': 'Use environment variables or secure vaults for sensitive data'
        })

    if report['summary']['outdated_dependencies'] > 5:
        recommendations.append({
            'priority': 'MEDIUM',
            'category': 'Dependencies',
            'description': f"Update {report['summary']['outdated_dependencies']} outdated dependencies",
            'action': 'Review and update package versions regularly'
        })

    if report['summary']['license_issues'] > 0:
        recommendations.append({
            'priority': 'LOW',
            'category': 'Licenses',
            'description': f"Review {report['summary']['license_issues']} license compliance issues",
            'action': 'Ensure all dependencies have compatible licenses'
        })

    report['recommendations'] = recommendations

    # Write report
    with open(output_file, 'w') as f:
        json.dump(report, f, indent=2)

    return report

if __name__ == '__main__':
    import sys

    reports_dir = sys.argv[1] if len(sys.argv) > 1 else '.'
    output_file = sys.argv[2] if len(sys.argv) > 2 else 'comprehensive-security-report.json'

    report = generate_comprehensive_report(reports_dir, output_file)

    print(f"Comprehensive report generated: {output_file}")
    print(f"Overall risk score: {report['risk_assessment']['overall_risk_score']}")
    print(f"Risk level: {report['risk_assessment']['risk_level']}")
EOF

    # Generate JSON report
    python "$ARTIFACTS_DIR/generate_report.py" "$REPORTS_DIR" "$json_report"

    # Generate HTML report
    python << EOF
import json
import os

# Load comprehensive report
with open('$json_report', 'r') as f:
    report = json.load(f)

risk_score = report['risk_assessment']['overall_risk_score']
risk_level = report['risk_assessment']['risk_level']
summary = report['summary']

# Determine color based on risk level
risk_colors = {
    'CRITICAL': '#dc3545',
    'HIGH': '#fd7e14',
    'MEDIUM': '#ffc107',
    'LOW': '#28a745',
    'MINIMAL': '#6f42c1'
}

risk_color = risk_colors.get(risk_level, '#6c757d')

html_content = f'''<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Royal Textiles Security & Dependency Report</title>
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
            background: linear-gradient(135deg, #e83e8c 0%, #6f42c1 100%);
            color: white;
            padding: 40px 0;
            text-align: center;
            margin-bottom: 40px;
            border-radius: 10px;
        }}

        .header h1 {{
            font-size: 2.5em;
            margin-bottom: 10px;
        }}

        .risk-assessment {{
            background: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            margin-bottom: 30px;
            text-align: center;
        }}

        .risk-score {{
            font-size: 4em;
            font-weight: bold;
            color: {risk_color};
            margin-bottom: 10px;
        }}

        .risk-level {{
            font-size: 1.5em;
            font-weight: bold;
            color: {risk_color};
            margin-bottom: 20px;
        }}

        .deployment-status {{
            padding: 15px 30px;
            border-radius: 25px;
            font-size: 1.2em;
            font-weight: bold;
            color: white;
            background-color: {"#28a745" if report["risk_assessment"]["deployment_recommended"] else "#dc3545"};
        }}

        .stats-grid {{
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }}

        .stat-card {{
            background: white;
            padding: 25px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            text-align: center;
        }}

        .stat-number {{
            font-size: 2.5em;
            font-weight: bold;
            margin-bottom: 10px;
        }}

        .stat-label {{
            color: #666;
            text-transform: uppercase;
            font-size: 0.9em;
            letter-spacing: 1px;
        }}

        .critical {{ color: #dc3545; }}
        .high {{ color: #fd7e14; }}
        .medium {{ color: #ffc107; }}
        .low {{ color: #28a745; }}

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
        }}

        .section-content {{
            padding: 20px;
        }}

        .recommendations {{
            list-style: none;
        }}

        .recommendation {{
            padding: 15px;
            margin-bottom: 15px;
            border-left: 4px solid #dc3545;
            background: #f8f9fa;
            border-radius: 4px;
        }}

        .recommendation.high {{ border-left-color: #fd7e14; }}
        .recommendation.medium {{ border-left-color: #ffc107; }}
        .recommendation.low {{ border-left-color: #28a745; }}

        .footer {{
            text-align: center;
            color: #666;
            margin-top: 40px;
        }}

        .progress-bar {{
            width: 100%;
            height: 20px;
            background: #e9ecef;
            border-radius: 10px;
            overflow: hidden;
            margin: 20px 0;
        }}

        .progress-fill {{
            height: 100%;
            background: {risk_color};
            width: {risk_score}%;
            transition: width 0.3s ease;
        }}
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🔒 Security & Dependency Report</h1>
            <p>Royal Textiles Platform Security Analysis</p>
        </div>

        <div class="risk-assessment">
            <div class="risk-score">{risk_score:.1f}</div>
            <div class="risk-level">{risk_level} RISK</div>
            <div class="deployment-status">
                {"✅ DEPLOYMENT RECOMMENDED" if report["risk_assessment"]["deployment_recommended"] else "❌ DEPLOYMENT NOT RECOMMENDED"}
            </div>
            <div class="progress-bar">
                <div class="progress-fill"></div>
            </div>
        </div>

        <div class="stats-grid">
            <div class="stat-card">
                <div class="stat-number">{summary["total_dependencies"]}</div>
                <div class="stat-label">Total Dependencies</div>
            </div>
            <div class="stat-card">
                <div class="stat-number critical">{summary["critical_vulnerabilities"]}</div>
                <div class="stat-label">Critical Vulnerabilities</div>
            </div>
            <div class="stat-card">
                <div class="stat-number high">{summary["high_vulnerabilities"]}</div>
                <div class="stat-label">High Vulnerabilities</div>
            </div>
            <div class="stat-card">
                <div class="stat-number medium">{summary["security_issues"]}</div>
                <div class="stat-label">Security Issues</div>
            </div>
            <div class="stat-card">
                <div class="stat-number critical">{summary["secrets_found"]}</div>
                <div class="stat-label">Potential Secrets</div>
            </div>
            <div class="stat-card">
                <div class="stat-number medium">{summary["outdated_dependencies"]}</div>
                <div class="stat-label">Outdated Packages</div>
            </div>
        </div>'''

# Add recommendations section
if report['recommendations']:
    html_content += '''
        <div class="section">
            <div class="section-header">🎯 Recommendations</div>
            <div class="section-content">
                <ul class="recommendations">'''

    for rec in report['recommendations']:
        priority_class = rec['priority'].lower()
        html_content += f'''
                    <li class="recommendation {priority_class}">
                        <strong>{rec['priority']} - {rec['category']}:</strong><br>
                        {rec['description']}<br>
                        <em>Action: {rec['action']}</em>
                    </li>'''

    html_content += '''
                </ul>
            </div>
        </div>'''

# Close HTML
html_content += f'''
        <div class="footer">
            <p><strong>Royal Textiles Security & Dependency Analysis</strong></p>
            <p>Generated on {report["scan_timestamp"]}</p>
            <p>Task 6.6 - Automated Dependency & Security Scanning</p>
        </div>
    </div>
</body>
</html>'''

with open('$final_report', 'w') as f:
    f.write(html_content)

print(f"HTML report generated: $final_report")
EOF

    print_status "Comprehensive report generated"
    print_info "HTML Report: $final_report"
    print_info "JSON Report: $json_report"
}

# Function to show summary
show_summary() {
    print_header "Security and Dependency Scan Summary"
    echo "======================================"
    echo ""

    if [ -f "$REPORTS_DIR/comprehensive-security-report.json" ]; then
        python << EOF
import json

try:
    with open('$REPORTS_DIR/comprehensive-security-report.json', 'r') as f:
        report = json.load(f)

    risk_assessment = report['risk_assessment']
    summary = report['summary']

    print("🔒 Security Assessment:")
    print(f"  Overall Risk Score: {risk_assessment['overall_risk_score']:.1f}/100")
    print(f"  Risk Level: {risk_assessment['risk_level']}")
    print(f"  Deployment Recommended: {'✅ YES' if risk_assessment['deployment_recommended'] else '❌ NO'}")
    print("")

    print("📊 Scan Results:")
    print(f"  Total Dependencies: {summary['total_dependencies']:,}")
    print(f"  Outdated Dependencies: {summary['outdated_dependencies']:,}")
    print(f"  Total Vulnerabilities: {summary['total_vulnerabilities']:,}")
    print(f"  Critical Vulnerabilities: {summary['critical_vulnerabilities']:,}")
    print(f"  High Vulnerabilities: {summary['high_vulnerabilities']:,}")
    print(f"  Security Issues: {summary['security_issues']:,}")
    print(f"  Potential Secrets: {summary['secrets_found']:,}")
    print(f"  License Issues: {summary['license_issues']:,}")
    print("")

    print("📁 Generated Reports:")
    print(f"  HTML Report: $REPORTS_DIR/comprehensive-security-report.html")
    print(f"  JSON Report: $REPORTS_DIR/comprehensive-security-report.json")
    print(f"  Individual Reports: $REPORTS_DIR/")
    print("")

    recommendations = report.get('recommendations', [])
    if recommendations:
        print("🎯 Key Recommendations:")
        for rec in recommendations[:5]:  # Show top 5
            print(f"  {rec['priority']}: {rec['description']}")
        print("")

except Exception as e:
    print(f"Error reading summary: {e}")
EOF
    else
        print_error "No comprehensive report found"
    fi

    print_info "Scan artifacts location: $SCAN_DIR"
    print_info "Individual reports: $REPORTS_DIR"
    print_info "Scan logs: $LOGS_DIR"
}

# Main function
main() {
    local show_help=false

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --no-dependencies)
                DEPENDENCY_SCAN=false
                shift
                ;;
            --no-security)
                SECURITY_SCAN=false
                shift
                ;;
            --no-licenses)
                LICENSE_SCAN=false
                shift
                ;;
            --no-vulnerabilities)
                VULNERABILITY_SCAN=false
                shift
                ;;
            --no-secrets)
                SECRET_SCAN=false
                shift
                ;;
            --no-compliance)
                COMPLIANCE_SCAN=false
                shift
                ;;
            --no-outdated)
                OUTDATED_SCAN=false
                shift
                ;;
            --no-reports)
                GENERATE_REPORTS=false
                shift
                ;;
            --fail-on-critical)
                FAIL_ON_CRITICAL=true
                shift
                ;;
            --fail-on-high)
                FAIL_ON_HIGH=true
                shift
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            --quiet)
                QUIET=true
                shift
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
        echo "Royal Textiles Automated Dependency & Security Scanner"
        echo "===================================================="
        echo ""
        echo "Usage: $0 [options]"
        echo ""
        echo "Options:"
        echo "  --no-dependencies     Skip dependency analysis"
        echo "  --no-security         Skip security code analysis"
        echo "  --no-licenses         Skip license scanning"
        echo "  --no-vulnerabilities  Skip vulnerability scanning"
        echo "  --no-secrets          Skip secret detection"
        echo "  --no-compliance       Skip compliance checking"
        echo "  --no-outdated         Skip outdated package checking"
        echo "  --no-reports          Skip report generation"
        echo "  --fail-on-critical    Fail on critical vulnerabilities"
        echo "  --fail-on-high        Fail on high severity issues"
        echo "  --verbose             Enable verbose output"
        echo "  --quiet               Suppress non-essential output"
        echo "  --help, -h            Show this help message"
        echo ""
        echo "Examples:"
        echo "  $0                                    # Full security scan"
        echo "  $0 --fail-on-critical                # Fail on critical issues"
        echo "  $0 --no-licenses --verbose           # Skip licenses with verbose output"
        echo "  $0 --no-secrets --no-compliance      # Focus on dependencies and security"
        echo ""
        exit 0
    fi

    # Header
    print_header "Royal Textiles Automated Dependency & Security Scanner"
    echo "======================================================"
    echo ""
    print_info "Scan ID: $SCAN_ID"
    print_info "Dependency Scan: $DEPENDENCY_SCAN"
    print_info "Security Scan: $SECURITY_SCAN"
    print_info "License Scan: $LICENSE_SCAN"
    print_info "Vulnerability Scan: $VULNERABILITY_SCAN"
    print_info "Secret Scan: $SECRET_SCAN"
    echo ""

    # Setup
    setup_scan_environment
    install_scanning_tools

    # Run scans
    if [ "$DEPENDENCY_SCAN" = true ]; then
        perform_dependency_analysis
    fi

    if [ "$VULNERABILITY_SCAN" = true ]; then
        perform_vulnerability_scanning
    fi

    if [ "$SECURITY_SCAN" = true ]; then
        perform_security_scanning
    fi

    if [ "$LICENSE_SCAN" = true ]; then
        perform_license_scanning
    fi

    if [ "$SECRET_SCAN" = true ]; then
        perform_secret_scanning
    fi

    # Generate reports
    if [ "$GENERATE_REPORTS" = true ]; then
        generate_comprehensive_report
    fi

    # Show summary
    show_summary

    # Determine exit code
    local exit_code=0

    if [ "$FAIL_ON_CRITICAL" = true ] && [ "$CRITICAL_VULNERABILITIES" -gt 0 ]; then
        print_error "Scan failed due to critical vulnerabilities"
        exit_code=1
    elif [ "$FAIL_ON_HIGH" = true ] && [ "$HIGH_VULNERABILITIES" -gt 0 ]; then
        print_error "Scan failed due to high severity vulnerabilities"
        exit_code=1
    elif [ "$SECRETS_FOUND" -gt 0 ]; then
        print_warning "Potential secrets found - review required"
        exit_code=1
    fi

    if [ $exit_code -eq 0 ]; then
        print_success "Security and dependency scan completed successfully"
    fi

    exit $exit_code
}

# Run the main function
main "$@"

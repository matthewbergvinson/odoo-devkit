#!/bin/bash

# Setup Debugpy for Odoo Remote Debugging
# This script helps configure debugpy for remote debugging of Odoo applications

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

print_header() {
    echo -e "${BLUE}=================================${NC}"
    echo -e "${BLUE}🐛 Odoo Debugpy Setup Script${NC}"
    echo -e "${BLUE}=================================${NC}"
    echo ""
}

print_section() {
    echo -e "${YELLOW}📋 $1${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

install_debugpy() {
    print_section "Installing debugpy"

    # Check if virtual environment exists
    if [ -d "$PROJECT_ROOT/.venv" ]; then
        echo "🐍 Using project virtual environment"
        source "$PROJECT_ROOT/.venv/bin/activate"
    else
        print_warning "No virtual environment found at $PROJECT_ROOT/.venv"
        echo "Consider creating one with: python -m venv .venv"
    fi

    # Install debugpy
    echo "📦 Installing debugpy..."
    pip install debugpy

    print_success "Debugpy installed successfully"
    echo ""
}

create_debug_odoo_script() {
    print_section "Creating debug-enabled Odoo startup script"

    local debug_script="$PROJECT_ROOT/local-odoo/start-odoo-debug.sh"

    cat > "$debug_script" << 'EOF'
#!/bin/bash

# Start Odoo with debugpy enabled for remote debugging
# Usage: ./start-odoo-debug.sh [port] [config]

# Default values
DEBUG_PORT=${1:-5678}
CONFIG_FILE=${2:-"config/odoo-development.conf"}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

echo "🐛 Starting Odoo with debugpy on port $DEBUG_PORT"
echo "📝 Using config: $CONFIG_FILE"
echo ""

# Ensure debugpy is available
python -c "import debugpy" 2>/dev/null || {
    echo "❌ debugpy not found. Install with: pip install debugpy"
    exit 1
}

# Start Odoo with debugpy
python -m debugpy --listen 0.0.0.0:$DEBUG_PORT --wait-for-client \
    "$SCRIPT_DIR/odoo/odoo-bin" \
    --config="$SCRIPT_DIR/$CONFIG_FILE" \
    --dev=xml,reload,qweb \
    --log-level=debug \
    --limit-time-cpu=600 \
    --limit-time-real=1200
EOF

    chmod +x "$debug_script"

    print_success "Created debug script: $debug_script"
    echo ""
}

create_debugpy_config() {
    print_section "Creating debugpy configuration helper"

    local config_script="$PROJECT_ROOT/scripts/debugpy-config.py"

    cat > "$config_script" << 'EOF'
#!/usr/bin/env python3
"""
Debugpy Configuration Helper for Odoo Development

This script helps configure debugpy in Odoo code for remote debugging.
Usage examples:

1. Add to your Odoo module __init__.py:
   from scripts.debugpy_config import start_debugpy
   start_debugpy()

2. Add breakpoint in your code:
   from scripts.debugpy_config import debug_here
   debug_here()
"""

import os
import sys

def start_debugpy(port=5678, wait_for_client=False):
    """
    Start debugpy server for remote debugging

    Args:
        port (int): Port to listen on (default: 5678)
        wait_for_client (bool): Whether to wait for client before continuing
    """
    try:
        import debugpy

        # Check if debugpy is already listening
        if not debugpy.is_client_connected():
            print(f"🐛 Starting debugpy on port {port}")
            debugpy.listen(("0.0.0.0", port))

            if wait_for_client:
                print("⏳ Waiting for debugger client to attach...")
                debugpy.wait_for_client()
                print("🔗 Debugger client attached!")
        else:
            print("🔗 Debugpy client already connected")

    except ImportError:
        print("❌ debugpy not installed. Run: pip install debugpy")
    except Exception as e:
        print(f"❌ Failed to start debugpy: {e}")

def debug_here(port=5678):
    """
    Set a breakpoint at this location and start debugpy if not already running

    Args:
        port (int): Port to listen on (default: 5678)
    """
    start_debugpy(port, wait_for_client=False)

    try:
        import debugpy
        debugpy.breakpoint()
        print("🔍 Breakpoint set - debugger should pause here")
    except ImportError:
        print("❌ debugpy not available for breakpoint")

def is_debugging():
    """Check if we're currently in a debugging session"""
    try:
        import debugpy
        return debugpy.is_client_connected()
    except ImportError:
        return False

# Auto-start debugpy in development mode
if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="Start debugpy server")
    parser.add_argument("--port", type=int, default=5678, help="Port to listen on")
    parser.add_argument("--wait", action="store_true", help="Wait for client to attach")

    args = parser.parse_args()
    start_debugpy(args.port, args.wait)
EOF

    chmod +x "$config_script"

    print_success "Created debugpy config helper: $config_script"
    echo ""
}

update_requirements() {
    print_section "Updating requirements.txt"

    local requirements_file="$PROJECT_ROOT/requirements.txt"

    # Check if debugpy is already in requirements
    if grep -q "debugpy" "$requirements_file" 2>/dev/null; then
        print_success "debugpy already in requirements.txt"
    else
        echo "debugpy>=1.6.0  # Remote debugging support" >> "$requirements_file"
        print_success "Added debugpy to requirements.txt"
    fi
    echo ""
}

create_vscode_debugging_guide() {
    print_section "Creating VS Code debugging guide"

    local guide_file="$PROJECT_ROOT/docs/vscode-debugging-guide.md"

    cat > "$guide_file" << 'EOF'
# VS Code Debugging Guide for Odoo Development

This guide explains how to use the VS Code debugging configurations for Royal Textiles Odoo development.

## Quick Start

1. **Open VS Code** in the project root directory
2. **Install Python extension** if not already installed
3. **Open the Debug view** (Ctrl+Shift+D / Cmd+Shift+D)
4. **Select a debug configuration** from the dropdown
5. **Start debugging** by pressing F5 or clicking the play button

## Available Debug Configurations

### 🚀 Server Debugging

#### "Start Odoo Development Server"
- Starts local Odoo server with development settings
- Includes XML/QWeb reloading and debug logging
- Best for: General development and testing

#### "Debug Odoo with Custom Modules"
- Initializes Royal Textiles modules with debugging
- Stops after initialization for inspection
- Best for: Module development and troubleshooting

### 🧪 Test Debugging

#### "Debug Odoo Tests (Royal Textiles)"
- Runs Royal Textiles module tests with debugging
- Uses test-specific configuration
- Best for: Debugging failing tests

#### "Debug Specific Test File"
- Debugs the currently open test file
- Uses `${file}` variable for current file
- Best for: Focused test debugging

#### "Debug PyTest Tests"
- Runs pytest with debugging support
- Includes performance and integration tests
- Best for: Python-level test debugging

### 📦 Module Debugging

#### "Debug Module Installation"
- Debugs module installation process
- Prompts for module name input
- Best for: Installation issues and hooks

#### "Debug Module Upgrade"
- Debugs module upgrade process
- Useful for migration debugging
- Best for: Upgrade scripts and data migration

### 🌐 Web Debugging

#### "Debug Web Controller"
- Debugs web controllers and HTTP requests
- Includes gevent support for async operations
- Best for: Web interface and API debugging

### 🔌 Remote Debugging

#### "Attach to Running Odoo (debugpy)"
- Connects to running Odoo with debugpy
- Requires debugpy server to be started
- Best for: Production-like debugging

#### "Debug Odoo in Docker"
- Connects to Odoo running in Docker container
- Uses path mapping for container files
- Best for: Containerized development

## How to Use Each Configuration

### Basic Debugging Workflow

1. **Set breakpoints** by clicking left of line numbers
2. **Select debug configuration** from dropdown
3. **Start debugging** with F5
4. **Use debug controls**:
   - Continue (F5)
   - Step Over (F10)
   - Step Into (F11)
   - Step Out (Shift+F11)

### Remote Debugging Setup

For remote debugging with debugpy:

1. **Start Odoo with debugpy**:
   ```bash
   ./local-odoo/start-odoo-debug.sh 5678
   ```

2. **Or add to your code**:
   ```python
   import debugpy
   debugpy.listen(5678)
   debugpy.wait_for_client()  # Optional: wait for VS Code
   ```

3. **Use "Attach to Running Odoo" configuration**

### Debugging Tips

#### Setting Effective Breakpoints
- Set breakpoints in model methods, not class definitions
- Use conditional breakpoints for specific conditions
- Set logpoints for logging without stopping execution

#### Debugging Odoo Specifics
- **Model methods**: Set breakpoints in `create()`, `write()`, `unlink()`
- **Controllers**: Set breakpoints in route methods
- **Workflows**: Debug state transitions and validations
- **Reports**: Debug report generation and data preparation

#### Common Debugging Scenarios

**Database Issues**:
```python
# In model method
def create(self, vals):
    import debugpy; debugpy.breakpoint()  # Pause here
    result = super().create(vals)
    return result
```

**View Rendering**:
```python
# In controller
@http.route('/my/route')
def my_route(self):
    import debugpy; debugpy.breakpoint()  # Check request data
    return self._render_template(data)
```

**Business Logic**:
```python
# In computed field
@api.depends('field1', 'field2')
def _compute_total(self):
    for record in self:
        import debugpy; debugpy.breakpoint()  # Check computation
        record.total = record.field1 + record.field2
```

## Troubleshooting

### Common Issues

**"Module not found" errors**:
- Check PYTHONPATH in launch configuration
- Ensure virtual environment is activated
- Verify Odoo and custom module paths

**Debugger not stopping at breakpoints**:
- Ensure `"justMyCode": false` in configuration
- Check if code is actually being executed
- Verify file paths match between local and remote

**Port conflicts**:
- Change debugpy port in configuration
- Check if port is already in use: `lsof -i :5678`
- Use different ports for multiple debug sessions

### Performance Considerations

- Disable breakpoints when not needed
- Use conditional breakpoints to reduce overhead
- Consider using logpoints for logging without stopping
- Remove debugpy calls before production deployment

## Integration with Testing

The debug configurations work seamlessly with our testing infrastructure:

- **Unit Tests**: Use "Debug PyTest Tests" for Python-level debugging
- **Integration Tests**: Use "Debug Odoo Tests" for full Odoo environment
- **Performance Tests**: Use "Debug Performance Tests" with resource monitoring

## Best Practices

1. **Use descriptive breakpoint conditions**
2. **Remove debug statements before committing**
3. **Use logging for production debugging**
4. **Test debug configurations regularly**
5. **Document complex debugging setups**

For more information on Odoo debugging, see the [Odoo Development Documentation](https://odoo-development.readthedocs.io/).
EOF

    print_success "Created VS Code debugging guide: $guide_file"
    echo ""
}

show_usage_instructions() {
    print_section "🎯 Next Steps"

    echo "1. 🚀 Start debugging with VS Code:"
    echo "   - Open VS Code in project root"
    echo "   - Go to Debug view (Ctrl+Shift+D)"
    echo "   - Select a debug configuration"
    echo "   - Press F5 to start debugging"
    echo ""

    echo "2. 🐛 For remote debugging:"
    echo "   - Run: ./local-odoo/start-odoo-debug.sh"
    echo "   - Use 'Attach to Running Odoo' configuration"
    echo ""

    echo "3. 📚 Read the debugging guide:"
    echo "   - docs/vscode-debugging-guide.md"
    echo ""

    echo "4. 🧪 Test the setup:"
    echo "   - Set a breakpoint in your code"
    echo "   - Start a debug configuration"
    echo "   - Verify debugger stops at breakpoint"
    echo ""
}

main() {
    print_header

    # Check if we're in the right directory
    if [ ! -f "$PROJECT_ROOT/pyproject.toml" ]; then
        print_error "This doesn't appear to be the project root directory"
        print_error "Please run this script from the RTP Denver project root"
        exit 1
    fi

    install_debugpy
    create_debug_odoo_script
    create_debugpy_config
    update_requirements
    create_vscode_debugging_guide
    show_usage_instructions

    print_success "Debugpy setup completed successfully!"
    echo ""
    echo -e "${GREEN}🎉 Your Odoo debugging environment is ready!${NC}"
    echo -e "${BLUE}   Launch VS Code and start debugging with F5${NC}"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  -h, --help     Show this help message"
            echo ""
            echo "This script sets up debugpy for Odoo remote debugging."
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

# Run main function
main "$@"

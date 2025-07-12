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

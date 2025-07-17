#!/bin/bash
#
# Pre-push hook for bulletproof Odoo module validation
# 
# Install this hook by copying it to .git/hooks/pre-push and making it executable:
# cp templates/pre-push-hook.sh .git/hooks/pre-push
# chmod +x .git/hooks/pre-push
#
# This hook will run bulletproof validation before allowing pushes to prevent
# failed odoo.sh deployments.

echo "🛡️ Running Bulletproof Validation Before Push..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if we're in the odoo-devkit directory
if [ ! -f "scripts/bulletproof-validation.py" ]; then
    echo -e "${YELLOW}⚠️  Bulletproof validation script not found. Skipping validation.${NC}"
    exit 0
fi

# Find all Odoo modules in custom_modules directory
modules_found=0
validation_failed=0

if [ -d "custom_modules" ]; then
    for module_dir in custom_modules/*/; do
        if [ -d "$module_dir" ] && [ -f "$module_dir/__manifest__.py" ]; then
            module_name=$(basename "$module_dir")
            modules_found=1
            
            echo -e "${BLUE}📦 Validating module: $module_name${NC}"
            
            # Run bulletproof validation
            python scripts/bulletproof-validation.py "$module_dir"
            
            if [ $? -ne 0 ]; then
                echo -e "${RED}❌ Bulletproof validation FAILED for $module_name${NC}"
                validation_failed=1
            else
                echo -e "${GREEN}✅ Bulletproof validation PASSED for $module_name${NC}"
            fi
            
            echo "" # Empty line for readability
        fi
    done
fi

# Check if any modules were found
if [ $modules_found -eq 0 ]; then
    echo -e "${YELLOW}⚠️  No Odoo modules found in custom_modules/. Skipping validation.${NC}"
    exit 0
fi

# Check validation results
if [ $validation_failed -eq 1 ]; then
    echo -e "${RED}💥 VALIDATION FAILED - PUSH BLOCKED${NC}"
    echo -e "${RED}🚨 Fix the validation errors above before pushing${NC}"
    echo -e "${YELLOW}💡 This prevents failed odoo.sh deployments that waste 15+ minutes${NC}"
    echo ""
    echo -e "${BLUE}🔧 Quick fixes:${NC}"
    echo "   • Check completion dates are in the future"
    echo "   • Verify selection field values match model definitions"
    echo "   • Ensure proper XML encoding (& → &amp;)"
    echo "   • Validate field relationships and types"
    echo ""
    echo -e "${BLUE}📋 Re-run validation manually:${NC}"
    echo "   python scripts/bulletproof-validation.py custom_modules/your_module/"
    exit 1
else
    echo -e "${GREEN}🎉 ALL VALIDATIONS PASSED!${NC}"
    echo -e "${GREEN}🚀 Safe to push - odoo.sh deployment will succeed${NC}"
    echo -e "${BLUE}⏱️  Time saved: 15+ minutes per avoided failed deployment${NC}"
    exit 0
fi
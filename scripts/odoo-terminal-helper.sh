#!/bin/bash

# =====================================
# Royal Textiles Odoo Terminal Helper
# =====================================
# Task 5.7: Configure integrated terminal settings for Odoo commands
# This script provides quick access to common Odoo commands in the terminal

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to show help
show_help() {
    echo -e "${CYAN}🚀 Royal Textiles Odoo Terminal Helper${NC}"
    echo -e "${CYAN}=====================================${NC}"
    echo ""
    echo -e "${YELLOW}Usage: odoo-helper [command]${NC}"
    echo ""
    echo -e "${GREEN}Development Commands:${NC}"
    echo "  start       Start Odoo development server"
    echo "  stop        Stop Odoo server"
    echo "  restart     Restart Odoo server"
    echo "  shell       Open Odoo interactive shell"
    echo "  logs        Show Odoo logs"
    echo "  status      Show Odoo status"
    echo ""
    echo -e "${GREEN}Testing Commands:${NC}"
    echo "  test        Run all tests"
    echo "  test-module Run tests for specific module"
    echo "  coverage    Run tests with coverage"
    echo "  lint        Run code linting"
    echo "  validate    Validate modules"
    echo ""
    echo -e "${GREEN}Database Commands:${NC}"
    echo "  db-create   Create new database"
    echo "  db-list     List all databases"
    echo "  db-drop     Drop database"
    echo "  db-backup   Backup database"
    echo "  db-restore  Restore database"
    echo ""
    echo -e "${GREEN}Module Commands:${NC}"
    echo "  install     Install module"
    echo "  upgrade     Upgrade module"
    echo "  uninstall   Uninstall module"
    echo "  list        List installed modules"
    echo ""
    echo -e "${GREEN}Docker Commands:${NC}"
    echo "  docker-up   Start Docker environment"
    echo "  docker-down Stop Docker environment"
    echo "  docker-logs Show Docker logs"
    echo "  docker-shell Open Docker shell"
    echo ""
    echo -e "${GREEN}Utility Commands:${NC}"
    echo "  deploy-check Run deployment readiness check"
    echo "  clean       Clean temporary files"
    echo "  format      Format code"
    echo "  help        Show this help message"
    echo ""
    echo -e "${PURPLE}Examples:${NC}"
    echo "  odoo-helper start"
    echo "  odoo-helper test-module royal_textiles_sales"
    echo "  odoo-helper db-create my_test_db"
    echo "  odoo-helper shell my_dev_db"
}

# Function to start Odoo
start_odoo() {
    echo -e "${GREEN}🚀 Starting Odoo development server...${NC}"
    make start-odoo
}

# Function to stop Odoo
stop_odoo() {
    echo -e "${YELLOW}🛑 Stopping Odoo server...${NC}"
    make stop-odoo
}

# Function to restart Odoo
restart_odoo() {
    echo -e "${BLUE}🔄 Restarting Odoo server...${NC}"
    make restart-odoo
}

# Function to open Odoo shell
open_shell() {
    local db_name=${1:-"$(read -p 'Enter database name: ' db && echo $db)"}
    echo -e "${CYAN}🔧 Opening Odoo shell for database: $db_name${NC}"
    python3 local-odoo/odoo/odoo-bin shell -c local-odoo/config/odoo-development.conf -d "$db_name"
}

# Function to show logs
show_logs() {
    echo -e "${CYAN}📋 Showing Odoo logs...${NC}"
    if [ -f "local-odoo/logs/odoo.log" ]; then
        tail -f local-odoo/logs/odoo.log
    else
        echo -e "${RED}❌ Log file not found. Is Odoo running?${NC}"
    fi
}

# Function to show status
show_status() {
    echo -e "${CYAN}📊 Checking Odoo status...${NC}"
    if pgrep -f "odoo-bin" > /dev/null; then
        echo -e "${GREEN}✅ Odoo server is running${NC}"
        ps aux | grep odoo-bin | grep -v grep
    else
        echo -e "${RED}❌ Odoo server is not running${NC}"
    fi
}

# Function to run tests
run_tests() {
    echo -e "${GREEN}🧪 Running all tests...${NC}"
    make test
}

# Function to run module tests
run_module_tests() {
    local module_name=${1:-"$(read -p 'Enter module name: ' module && echo $module)"}
    echo -e "${GREEN}🧪 Running tests for module: $module_name${NC}"
    make test-module MODULE="$module_name"
}

# Function to run coverage
run_coverage() {
    echo -e "${GREEN}📊 Running tests with coverage...${NC}"
    make coverage
}

# Function to run linting
run_lint() {
    echo -e "${BLUE}🔍 Running code linting...${NC}"
    make lint
}

# Function to validate modules
validate_modules() {
    echo -e "${BLUE}✅ Validating modules...${NC}"
    make validate
}

# Function to create database
create_database() {
    local db_name=${1:-"$(read -p 'Enter database name: ' db && echo $db)"}
    echo -e "${GREEN}🗃️ Creating database: $db_name${NC}"
    make db-create NAME="$db_name"
}

# Function to list databases
list_databases() {
    echo -e "${CYAN}📋 Listing databases...${NC}"
    make db-list
}

# Function to drop database
drop_database() {
    local db_name=${1:-"$(read -p 'Enter database name to drop: ' db && echo $db)"}
    echo -e "${RED}🗑️ Dropping database: $db_name${NC}"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        make db-drop NAME="$db_name"
    else
        echo -e "${YELLOW}❌ Operation cancelled${NC}"
    fi
}

# Function to backup database
backup_database() {
    local db_name=${1:-"$(read -p 'Enter database name to backup: ' db && echo $db)"}
    echo -e "${GREEN}💾 Backing up database: $db_name${NC}"
    make backup-create NAME="$db_name"
}

# Function to install module
install_module() {
    local module_name=${1:-"$(read -p 'Enter module name: ' module && echo $module)"}
    local db_name=${2:-"$(read -p 'Enter database name: ' db && echo $db)"}
    echo -e "${GREEN}📦 Installing module: $module_name in database: $db_name${NC}"
    make module-test-install MODULE="$module_name"
}

# Function to upgrade module
upgrade_module() {
    local module_name=${1:-"$(read -p 'Enter module name: ' module && echo $module)"}
    echo -e "${BLUE}🔄 Upgrading module: $module_name${NC}"
    make module-test-upgrade MODULE="$module_name"
}

# Function to run deployment check
deployment_check() {
    echo -e "${PURPLE}🚀 Running deployment readiness check...${NC}"
    make deploy-check
}

# Function to clean temporary files
clean_files() {
    echo -e "${YELLOW}🧹 Cleaning temporary files...${NC}"
    make clean
}

# Function to format code
format_code() {
    echo -e "${BLUE}🎨 Formatting code...${NC}"
    make format
}

# Function to start Docker
start_docker() {
    echo -e "${GREEN}🐳 Starting Docker environment...${NC}"
    make docker-up
}

# Function to stop Docker
stop_docker() {
    echo -e "${YELLOW}🐳 Stopping Docker environment...${NC}"
    make docker-down
}

# Function to show Docker logs
show_docker_logs() {
    local service=${1:-"odoo"}
    echo -e "${CYAN}📋 Showing Docker logs for service: $service${NC}"
    make docker-logs SERVICE="$service"
}

# Function to open Docker shell
open_docker_shell() {
    local service=${1:-"odoo"}
    echo -e "${CYAN}🔧 Opening Docker shell for service: $service${NC}"
    make docker-shell SERVICE="$service"
}

# Main command handler
case "${1:-help}" in
    "start")
        start_odoo
        ;;
    "stop")
        stop_odoo
        ;;
    "restart")
        restart_odoo
        ;;
    "shell")
        open_shell "$2"
        ;;
    "logs")
        show_logs
        ;;
    "status")
        show_status
        ;;
    "test")
        run_tests
        ;;
    "test-module")
        run_module_tests "$2"
        ;;
    "coverage")
        run_coverage
        ;;
    "lint")
        run_lint
        ;;
    "validate")
        validate_modules
        ;;
    "db-create")
        create_database "$2"
        ;;
    "db-list")
        list_databases
        ;;
    "db-drop")
        drop_database "$2"
        ;;
    "db-backup")
        backup_database "$2"
        ;;
    "install")
        install_module "$2" "$3"
        ;;
    "upgrade")
        upgrade_module "$2"
        ;;
    "deploy-check")
        deployment_check
        ;;
    "clean")
        clean_files
        ;;
    "format")
        format_code
        ;;
    "docker-up")
        start_docker
        ;;
    "docker-down")
        stop_docker
        ;;
    "docker-logs")
        show_docker_logs "$2"
        ;;
    "docker-shell")
        open_docker_shell "$2"
        ;;
    "help")
        show_help
        ;;
    *)
        echo -e "${RED}❌ Unknown command: $1${NC}"
        echo -e "${YELLOW}Use 'odoo-helper help' to see available commands${NC}"
        exit 1
        ;;
esac

# VS Code Tasks Guide for Royal Textiles Odoo Development

This guide explains how to use the comprehensive VS Code task system for Royal Textiles Odoo development. All tasks are designed to integrate seamlessly with our Makefile-based workflow.

## 🚀 Quick Start

### Accessing Tasks
1. **Command Palette**: Press `Ctrl+Shift+P` (or `Cmd+Shift+P` on Mac)
2. Type "Tasks: Run Task"
3. Select from the categorized task list
4. **Or** use keyboard shortcut: `Ctrl+Shift+T`

### Running a Task
- Select any task from the list
- Tasks will prompt for input when needed (module names, database names, etc.)
- Output appears in VS Code's integrated terminal
- Problem matchers will highlight errors directly in the editor

## 📋 Task Categories

### 🧪 Testing Tasks

**Core Testing:**
- `🧪 Test: Run All Tests` - Complete test suite (unit, integration, performance)
- `🧪 Test: Current Module` - Test specific module (prompts for module name)
- `🔄 Test: Integration Tests` - End-to-end workflow testing
- `⚡ Test: Performance Tests` - Database and view performance validation

**Workflow-Specific Testing:**
- `👥 Test: Customer Workflows` - Customer lifecycle testing
- `💰 Test: Sales Workflows` - Sales order process testing
- `🗃️ Test: Database Performance` - Database operation benchmarks
- `🖥️ Test: View Performance` - UI rendering performance tests

**CI/CD Testing:**
- `🚀 Test: CI/CD Pipeline` - Continuous integration simulation

### 📊 Coverage Tasks

- `📊 Coverage: Generate Report` - HTML, XML, and JSON coverage reports
- `📊 Coverage: HTML Report` - Interactive HTML coverage browser
- `📊 Coverage: Validate Thresholds` - Ensure 75%+ coverage requirements
- `📊 Coverage: Full Analysis` - Complete coverage workflow with insights
- `📊 Coverage: Insights & Recommendations` - Detailed coverage analysis

### 🔍 Code Quality Tasks

**Linting:**
- `🔍 Lint: All Code` - Complete codebase linting (flake8, pylint-odoo, mypy)
- `🔍 Lint: Current File` - Quick file-specific linting
- `🔍 Lint: Pylint Odoo` - Odoo-specific code analysis
- `🔍 Type Check: MyPy` - Static type checking

**Formatting:**
- `🎨 Format: All Code` - Format entire codebase with Black and isort
- `🎨 Format: Current File` - Format currently open file

### ✅ Validation Tasks

- `✅ Validate: All Modules` - Comprehensive Odoo module validation
- `✅ Validate: Current Module` - Validate specific module
- `✅ Validate: Pre-commit Hooks` - Run all pre-commit checks

### 📦 Module Management Tasks

- `📦 Module: Test Installation` - Test module installation process
- `📦 Module: Test Upgrade` - Test module upgrade workflow
- `📦 Module: Test Dependencies` - Validate module dependencies
- `📦 Module: Royal Textiles Complete Test` - Full Royal Textiles testing
- `📦 Module: RTP Customers Complete Test` - Full RTP Customers testing

### 🗃️ Database Management Tasks

- `🗃️ DB: Create Database` - Create new development database
- `🗃️ DB: List Databases` - Show all available databases
- `🗃️ DB: Drop Database` - Remove database (with confirmation)
- `🗃️ DB: Backup Database` - Create database backup
- `🗃️ DB: Create Test Database` - Create isolated test database
- `🗃️ DB: Generate Sample Data` - Populate database with test data

### 🚀 Development Server Tasks

- `🚀 Server: Start Odoo` - Start local Odoo development server
- `🚀 Server: Stop Odoo` - Stop running Odoo server
- `🚀 Server: Restart Odoo` - Restart Odoo server
- `🚀 Server: Start with Debugpy` - Start Odoo with debugpy for VS Code debugging

### 🐳 Docker Tasks

- `🐳 Docker: Start Development Environment` - Launch Docker development stack
- `🐳 Docker: Stop Services` - Stop all Docker services
- `🐳 Docker: View Logs` - Monitor Docker service logs
- `🐳 Docker: Open Shell` - Access Docker container shell
- `🐳 Docker: Status` - Check Docker service status

### 🐛 Debugging Tasks

- `🐛 Debug: Setup Debugpy` - Install and configure debugging environment
- `🐛 Debug: Test Connection` - Verify debugpy connection
- `🐛 Debug: Show Help` - Display debugging configuration help
- `🐛 Debug: Validate VS Code Config` - Verify launch.json and settings.json

### 🚢 CI/CD and Deployment Tasks

- `🚢 Deploy: Check Readiness` - Full pre-deployment validation
- `🚢 Deploy: Full Validation Pipeline` - Complete quality assurance workflow
- `🚢 Deploy: CI Simulation` - Simulate continuous integration environment

### 🧹 Utility Tasks

- `🧹 Utility: Clean Temporary Files` - Remove build artifacts and cache
- `🧹 Utility: Clean Coverage Files` - Clean coverage reports
- `🧹 Utility: Clean Debug Processes` - Terminate debugging processes
- `📖 Help: Show All Make Commands` - Display all available Makefile targets

## 🎯 Common Workflows

### Development Workflow
1. `🚀 Server: Start Odoo` - Start development server
2. `🔍 Lint: Current File` - Lint code as you develop
3. `🎨 Format: Current File` - Format code before commit
4. `🧪 Test: Current Module` - Test your changes
5. `📊 Coverage: HTML Report` - Check test coverage

### Quality Assurance Workflow
1. `🔍 Lint: All Code` - Full codebase linting
2. `✅ Validate: All Modules` - Comprehensive validation
3. `🧪 Test: Run All Tests` - Complete test suite
4. `📊 Coverage: Validate Thresholds` - Ensure coverage requirements
5. `🚢 Deploy: Check Readiness` - Pre-deployment validation

### Module Development Workflow
1. `📦 Module: Test Installation` - Verify installation process
2. `🧪 Test: Current Module` - Test module functionality
3. `📦 Module: Test Dependencies` - Validate dependencies
4. `📦 Module: Test Upgrade` - Test upgrade process
5. `✅ Validate: Current Module` - Final validation

### Performance Analysis Workflow
1. `⚡ Test: Performance Tests` - Run performance benchmarks
2. `🗃️ Test: Database Performance` - Analyze database operations
3. `🖥️ Test: View Performance` - Check UI rendering performance
4. `📊 Coverage: Full Analysis` - Comprehensive performance + coverage

### Debugging Workflow
1. `🐛 Debug: Setup Debugpy` - Configure debugging environment
2. `🚀 Server: Start with Debugpy` - Start Odoo with debugging
3. Set breakpoints in VS Code
4. Use launch configurations from Command Palette
5. `🐛 Debug: Test Connection` - Verify connection if needed

## 🔧 Task Configuration

### Input Variables
Tasks automatically prompt for:
- **Module Name**: Default is "royal_textiles_sales"
- **Database Name**: Default is "rtp_dev"
- **Test Database Name**: Default is "test_rtp"
- **Docker Service**: Default is "odoo"
- **Test Type**: Options include unit, integration, performance, functional, all
- **Coverage Threshold**: Default is "75"

### Problem Matchers
Tasks include problem matchers for:
- **Python errors**: Standard Python exception parsing
- **Flake8**: PEP8 and code quality issues
- **Pylint**: Advanced code analysis
- **MyPy**: Type checking errors
- **Odoo Validator**: Module validation errors
- **Deploy Check**: Deployment readiness issues

### Task Groups
Tasks are organized into logical groups:
- **testing**: All test-related tasks
- **coverage**: Coverage analysis tasks
- **quality**: Code quality and linting
- **validation**: Module and configuration validation
- **modules**: Module management tasks
- **database**: Database operations
- **server**: Development server management
- **docker**: Container operations
- **debug**: Debugging utilities
- **deploy**: Deployment and CI/CD
- **utility**: Maintenance and cleanup

## 🎨 Task Presentation

### Panel Organization
- **Shared Panel**: Most tasks use shared terminal panel for efficiency
- **Dedicated Panel**: Important tasks (server start, deploy check) get dedicated panels
- **Silent Reveal**: Formatting tasks run quietly
- **Focus Control**: Critical tasks automatically focus for attention

### Background Tasks
Long-running tasks are marked as background:
- Server startup tasks
- Docker environment startup
- Debug connection testing

## 🚨 Troubleshooting

### Common Issues

**Task Not Found:**
- Ensure you're in the project root directory
- Check that tasks.json is valid JSON
- Restart VS Code if tasks don't appear

**Permission Errors:**
- Ensure scripts have execute permissions: `chmod +x scripts/*.sh`
- Check PostgreSQL user permissions for database tasks

**Docker Issues:**
- Verify Docker is running: `docker ps`
- Check Docker Compose configuration
- Use `🐳 Docker: Status` task for diagnostics

**Debugging Connection Issues:**
- Run `🐛 Debug: Setup Debugpy` to reconfigure
- Check firewall settings for port 5678
- Use `🐛 Debug: Test Connection` to verify setup

### Performance Considerations
- Use task groups to organize terminal panels
- Background tasks don't block interactive development
- Problem matchers provide immediate feedback
- Shared panels reduce resource usage

## 🔗 Integration with Other Tools

### Git Integration
- Pre-commit hooks work with validation tasks
- Linting tasks integrate with Git workflow
- Deploy check tasks validate Git status

### Docker Integration
- Docker tasks manage containerized development
- Path mapping ensures proper file synchronization
- Volume management for persistent data

### Debugging Integration
- Launch configurations work with task system
- Debugpy tasks prepare remote debugging
- Problem matchers highlight debuggable issues

## 📚 Advanced Usage

### Custom Task Combinations
Create compound tasks by chaining commands:
```json
{
    "label": "🔥 Full Quality Check",
    "dependsOrder": "sequence",
    "dependsOn": [
        "🔍 Lint: All Code",
        "✅ Validate: All Modules",
        "🧪 Test: Run All Tests",
        "📊 Coverage: Validate Thresholds"
    ]
}
```

### Keyboard Shortcuts
Add custom shortcuts in keybindings.json:
```json
{
    "key": "ctrl+shift+t",
    "command": "workbench.action.tasks.runTask",
    "args": "🧪 Test: Run All Tests"
}
```

### Task-Specific Settings
Configure task behavior in settings.json:
```json
{
    "task.autoDetect": "on",
    "task.showDecorations": true,
    "task.problemMatchers.neverPrompt": true
}
```

## 📖 Best Practices

1. **Use Task Groups**: Organize related tasks in the same terminal panel
2. **Monitor Output**: Watch problem matchers for immediate feedback
3. **Background Tasks**: Let long-running tasks run in background
4. **Input Validation**: Use provided defaults for consistent development
5. **Error Handling**: Check problem panel for issues before proceeding
6. **Resource Management**: Clean up with utility tasks regularly
7. **Documentation**: Refer to this guide and task descriptions

## 🎉 Conclusion

This comprehensive task system provides one-click access to all development workflows:
- **50+ specialized tasks** covering every aspect of Odoo development
- **Organized by function** for easy discovery
- **Integrated with our Makefile** for consistency
- **Problem matchers** for immediate error feedback
- **Input prompts** for dynamic configuration
- **Background processing** for efficiency

Use `📖 Help: Show All Make Commands` to see the complete list of available operations, and refer to this guide for detailed usage instructions.

For debugging-specific workflows, see [docs/vscode-debugging-guide.md](./vscode-debugging-guide.md).

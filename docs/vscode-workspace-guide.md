# VS Code Workspace Configuration Guide for Royal Textiles Odoo Development

This guide explains the comprehensive VS Code workspace configuration optimized for Royal Textiles Odoo development, including settings, extensions, and productivity features.

## 🚀 Quick Start

### Opening the Workspace
1. **From Command Line**: `code royal-textiles-odoo.code-workspace`
2. **From VS Code**: File → Open Workspace from File → select `royal-textiles-odoo.code-workspace`
3. **From Explorer**: Double-click the `.code-workspace` file

### First-Time Setup
1. Install recommended extensions when prompted
2. Select Python interpreter: `Ctrl+Shift+P` → "Python: Select Interpreter" → choose `./venv/bin/python`
3. Verify Odoo paths in settings are correct
4. Run `make setup-dev-environment` to ensure all tools are installed

## 📁 Workspace Structure

The workspace is organized into logical folders for efficient navigation:

### 🏗️ **Royal Textiles Project Root**
- Main project directory with configuration files
- Makefile, requirements.txt, documentation

### 🔧 **Custom Modules**
- All Royal Textiles Odoo modules
- Organized by functionality (rtp_customers, royal_textiles_sales, etc.)
- Easy access to models, views, controllers

### 🧪 **Tests**
- Unit tests, integration tests, performance tests
- Test fixtures and utilities
- Coverage reports

### ⚙️ **Scripts**
- Development automation scripts
- Database management tools
- Validation and setup utilities

### 📚 **Documentation**
- Development guides and API documentation
- Architecture diagrams and workflows
- Best practices and standards

### 🐳 **Local Odoo Environment**
- Local Odoo installation and configuration
- Database setup and management
- Development server configuration

## ⚙️ Settings Configuration

### 🐍 **Python Development Settings**

**Interpreter Configuration:**
```json
"python.defaultInterpreter": "./venv/bin/python"
"python.terminal.activateEnvironment": true
```

**Code Analysis:**
```json
"python.analysis.typeCheckingMode": "basic"
"python.analysis.autoImportCompletions": true
"python.analysis.extraPaths": [
    "./custom_modules",
    "./local-odoo/odoo"
]
```

**Why This Matters:**
- Ensures consistent Python environment across the team
- Provides accurate IntelliSense for Odoo imports
- Enables proper type checking and autocompletion

### 🔍 **Linting and Code Quality**

**Pylint with Odoo Support:**
```json
"python.linting.pylintArgs": [
    "--load-plugins=pylint_odoo",
    "--disable=C0103,C0111,R0903,R0913,W0212,W0613,W0622,W0703,W1203",
    "--rcfile=.pylintrc-odoo"
]
```

**Flake8 Configuration:**
```json
"python.linting.flake8Args": [
    "--max-line-length=120",
    "--extend-ignore=E203,W503",
    "--config=.flake8"
]
```

**Benefits:**
- Catches Odoo-specific anti-patterns and errors
- Maintains consistent code style across the team
- Prevents common Odoo development mistakes

### 🌐 **Odoo-Specific Configuration**

**Addon Paths:**
```json
"odoo.addonsPath": [
    "./custom_modules",
    "./local-odoo/odoo/addons",
    "./local-odoo/odoo/odoo/addons"
]
```

**Language Server:**
```json
"odoo.enableLanguageServer": true
"odoo.autoScanAddons": true
"odoo.configPath": "./local-odoo/config/odoo-development.conf"
```

**Royal Textiles Benefits:**
- IntelliSense for Odoo models, fields, and methods
- Navigation to model definitions and view files
- Real-time validation of Odoo code patterns

## 🚨 **Odoo-Specific Problem Matchers**

### **What Are Problem Matchers?**

Problem matchers in VS Code parse console output from tasks and convert errors into clickable entries in the Problems panel. Our setup includes 11 specialized matchers for Odoo development:

1. **🚀 odoo-server-startup** - Module loading failures, server startup issues
2. **📦 odoo-module-import-error** - Python import failures, dependency issues
3. **🌐 odoo-xml-validation** - View definition errors, malformed XML
4. **🗃️ odoo-database-constraint** - PostgreSQL integrity/constraint errors
5. **🔧 odoo-field-definition-error** - Field type mismatches
6. **🔐 odoo-access-rights-error** - Security rule violations
7. **⚙️ odoo-workflow-error** - Workflow transition failures
8. **🧪 odoo-test-failure** - Unit test failures with file locations
9. **📋 odoo-comprehensive** - General catch-all for Odoo issues
10. **📊 odoo-performance-warning** - Performance alerts and slow queries
11. **🔌 odoo-integration-error** - Third-party integration failures

### **Benefits for Royal Textiles Development**

**Immediate Error Navigation:**
- Click any error to jump directly to the problematic code
- See all issues organized by severity in Problems panel
- Get context-aware error messages with file/line information

**Enhanced Debugging:**
- Automatic detection of common Odoo pitfalls
- Performance warnings for slow database queries
- Security rule violations highlighted immediately

**Example Error Detection:**
```
2024-01-15 10:30:45,123 ERROR royal_textiles_sales models/sale_order.py:45:
Field 'installation_date' type mismatch: expected Date, got Text
```
↓ **Becomes clickable link to** `models/sale_order.py` **line 45**

## 🖥️ **Enhanced Terminal Configuration**

### **Multiple Terminal Profiles**

VS Code is configured with 5 specialized terminal profiles, each optimized for different Royal Textiles workflows:

#### **🐍 Odoo Development** (Default)
- **Purpose**: Primary development environment
- **Features**: Full Odoo environment variables, virtual environment activation
- **Prompt**: `🐍 RTP-Odoo ~/project $`
- **Database**: `rtp_dev`
- **Use for**: Daily development, module creation, debugging

#### **🧪 Odoo Testing**
- **Purpose**: Isolated testing environment
- **Features**: Test-specific database, coverage reporting enabled
- **Prompt**: `🧪 RTP-Test ~/project $`
- **Database**: `test_rtp`
- **Use for**: Running tests, validation, CI/CD workflows

#### **🚀 Odoo Production**
- **Purpose**: Production-like environment for final testing
- **Features**: Production configuration, performance monitoring
- **Prompt**: `🚀 RTP-Prod ~/project $`
- **Database**: `rtp_production`
- **Use for**: Final validation, deployment preparation

#### **🗃️ Database Admin**
- **Purpose**: Database management and administration
- **Features**: Direct PostgreSQL tools, backup/restore utilities
- **Prompt**: `🗃️ RTP-DB ~/project $`
- **Use for**: Database maintenance, backups, data migration

#### **🐳 Docker Environment**
- **Purpose**: Container-based development
- **Features**: Docker commands, container management
- **Prompt**: `🐳 RTP-Docker ~/project $`
- **Use for**: Container deployment, Docker testing

### **Comprehensive Environment Variables**

**Project-Specific Variables:**
```bash
RTP_PROJECT_ROOT=/Users/username/rtp-denver
RTP_MODULES_PATH=/Users/username/rtp-denver/custom_modules
RTP_CONFIG_PATH=/Users/username/rtp-denver/local-odoo/config
RTP_SCRIPTS_PATH=/Users/username/rtp-denver/scripts
```

**Odoo Configuration:**
```bash
ODOO_HOME=/Users/username/rtp-denver/local-odoo
ODOO_RC=/Users/username/rtp-denver/local-odoo/config/odoo-development.conf
ODOO_ADDONS_PATH=custom_modules,local-odoo/odoo/addons,local-odoo/odoo/odoo/addons
```

**Database Settings:**
```bash
PGDATABASE=rtp_dev
PGUSER=odoo
PGHOST=localhost
PGPORT=5432
DATABASE_URL=postgresql://odoo@localhost:5432/rtp_dev
```

**Python Environment:**
```bash
PYTHONPATH=custom_modules:local-odoo/odoo:tests
VIRTUAL_ENV=venv
PATH=venv/bin:scripts:local-odoo:$PATH
```

### **Odoo Command Aliases and Functions**

**Access via terminal or source the configuration:**
```bash
source .vscode/odoo-terminal-config.sh
```

#### **🚀 Server Management Commands**
```bash
odoo-start           # Start Odoo server in development mode
odoo-debug           # Start with debug logging
odoo-update-all      # Start server and update all modules
odoo-test-mode       # Start in test mode
odoo-stop            # Stop Odoo server
odoo-status          # Check if Odoo is running
```

#### **📦 Module Management Commands**
```bash
odoo-install <module>     # Install specific module
odoo-update <module>      # Update specific module
odoo-uninstall <module>   # Uninstall specific module
odoo-modules              # List installed modules
odoo-scaffold <module>    # Create new module
```

#### **🗃️ Database Management Commands**
```bash
odoo-db-create <db>       # Create new database
odoo-db-drop <db>         # Drop database
odoo-db-list              # List all databases
odoo-db-connect [db]      # Connect to database (default: rtp_dev)
odoo-db-backup <db>       # Backup database
odoo-db-restore <db> <file> # Restore database from backup
```

#### **🧪 Testing and Quality Commands**
```bash
odoo-test-all             # Run all tests
odoo-test <module>        # Test specific module
odoo-lint                 # Lint all code
odoo-lint-file <file>     # Lint specific file
odoo-coverage             # Generate coverage report
```

#### **🔍 Development Utilities**
```bash
cdmod                     # Navigate to modules directory
cdconf                    # Navigate to config directory
cdscr                     # Navigate to scripts directory
cdodoo                    # Navigate to Odoo core
odoo-grep <term>          # Search in Python files
odoo-find <pattern>       # Find Python files by name
odoo-logs                 # Show server logs
```

#### **🏢 Royal Textiles Specific Commands**
```bash
rtp-install-all           # Install all RTP modules
rtp-update-all            # Update all RTP modules
rtp-test                  # Run RTP-specific tests
rtp-dev-start             # Start complete development environment
```

### **Terminal Features and Enhancements**

**Enhanced Scrollback:**
- 50,000 lines of history (vs default 1,000)
- Persistent sessions across VS Code restarts
- Smart scroll sensitivity

**Improved UX:**
- Copy on selection enabled
- Right-click for copy/paste
- Smooth scrolling
- Block cursor with blinking

**Shell Integration:**
- Command decorations show success/failure
- 1,000 commands in shell history
- Automatic working directory detection

**Visual Customization:**
- Color-coded terminal profiles
- Custom fonts (MesloLGS NF, Monaco, Courier New)
- Icon indicators for different terminal types
- Terminal tabs with custom separators

### **Quick Terminal Access**

**Keyboard Shortcuts:**
- `Ctrl+`` - Toggle terminal
- `Ctrl+Shift+`` - Create new terminal
- `Ctrl+Shift+5` - Split terminal
- `Ctrl+Shift+C` - Copy terminal selection
- `Ctrl+Shift+V` - Paste to terminal

**Profile Selection:**
1. Open Command Palette (`Ctrl+Shift+P`)
2. Type "Terminal: Select Default Profile"
3. Choose from available profiles:
   - 🐍 Odoo Development
   - 🧪 Odoo Testing
   - 🚀 Odoo Production
   - 🗃️ Database Admin
   - 🐳 Docker Environment

### **Best Practices for Royal Textiles Development**

**Daily Development Workflow:**
1. Start with **🐍 Odoo Development** profile
2. Use `rtp-dev-start` to initialize environment
3. Switch to **🧪 Odoo Testing** for running tests
4. Use **🗃️ Database Admin** for database tasks

**Module Development:**
```bash
# Create new module
odoo-scaffold my_new_module

# Install and test
odoo-install my_new_module
odoo-test my_new_module

# Lint and coverage
odoo-lint-file custom_modules/my_new_module/models/my_model.py
odoo-coverage
```

**Database Management:**
```bash
# Backup before major changes
odoo-db-backup rtp_dev

# Create test database
odoo-db-create test_new_feature

# Restore if needed
odoo-db-restore rtp_dev rtp_dev_20240115_103045.sql
```

**Troubleshooting:**
- Use `odoo-status` to check server status
- Use `odoo-logs` to view real-time server logs
- Use `odoo-help` to see all available commands
- Switch to **🚀 Odoo Production** profile for production-like testing

## 📝 **File Associations**

**Optimized File Recognition:**
```json
"files.associations": {
    "*.xml": "xml",
    "__manifest__.py": "python",
    "*.po": "gettext",
    "*.pot": "gettext",
    "*.csv": "csv"
}
```

**XML Configuration:**
```json
"xml.validation.enabled": true
"xml.format.enabled": true
"xml.format.splitAttributes": false
```

**Benefits:**
- Proper syntax highlighting for all Odoo file types
- XML validation for views and data files
- Gettext support for translations

## 🚨 **Odoo-Specific Problem Matchers**

### **What Are Problem Matchers?**

Problem matchers in VS Code parse console output from tasks and convert errors, warnings, and other issues into clickable entries in the **Problems panel**. This means Odoo errors become instantly navigable - click an error to jump directly to the problematic file and line.

### **Our Comprehensive Odoo Problem Matcher Suite**

We've implemented **11 specialized problem matchers** that catch and parse common Odoo error patterns:

#### **🚀 Server Startup Errors (`odoo-server-startup`)**
**Catches**: Module loading failures, configuration errors, database connection issues
**Example**: `2024-01-15 10:30:45,123 1234 ERROR rtp_customers models/customer.py: ImportError: No module named 'custom_library'`
**Benefit**: Instantly navigate to the file causing server startup failures

#### **📦 Module Import Errors (`odoo-module-import-error`)**
**Catches**: Python import failures, missing dependencies, circular imports
**Example**: `ImportError: cannot import name 'SaleOrder' in custom_modules/royal_textiles_sales/models/sale_order.py`
**Benefit**: Quickly identify and fix module dependency issues

#### **🌐 XML Validation Errors (`odoo-xml-validation`)**
**Catches**: View definition errors, malformed XML, schema violations
**Example**: `custom_modules/rtp_customers/views/customer_views.xml:45: error: Element 'field' not allowed here`
**Benefit**: Navigate directly to problematic XML elements in view files

#### **🗃️ Database Constraint Errors (`odoo-database-constraint`)**
**Catches**: PostgreSQL integrity errors, constraint violations, foreign key issues
**Example**: `psycopg2.IntegrityError: duplicate key value violates unique constraint "customers_email_unique"`
**Benefit**: Understand database-level errors that affect Odoo models

#### **🔧 Field Definition Errors (`odoo-field-definition-error`)**
**Catches**: Field type mismatches, relation errors, invalid field configurations
**Example**: `ValueError: Invalid field type 'Text' for related field 'customer_notes' in model 'sale.order'`
**Benefit**: Catch the field type errors that caused our earlier issues

#### **🔐 Access Rights Errors (`odoo-access-rights-error`)**
**Catches**: Security rule violations, insufficient permissions, access denials
**Example**: `AccessError: You do not have access to modify 'Customer' records (rtp.customers)`
**Benefit**: Quickly identify and fix security configuration issues

#### **🎨 QWeb Template Errors (`odoo-qweb-template-error`)**
**Catches**: Template rendering errors, undefined variables, syntax issues
**Example**: `QWebException: name 'customer_name' is not defined in template 'rtp_customers.customer_form'`
**Benefit**: Navigate to specific templates causing rendering failures

#### **⚙️ ORM Errors (`odoo-orm-error`)**
**Catches**: Model validation errors, search domain issues, recordset problems
**Example**: `ValidationError: Invalid search domain for field 'installation_date' in model 'rtp.installation'`
**Benefit**: Understand and fix Odoo ORM-specific issues

#### **🔄 Migration Errors (`odoo-migration-error`)**
**Catches**: Database migration failures, upgrade script errors
**Example**: `MigrationError: Failed to execute migration 1.0.2.0 in custom_modules/rtp_customers/migrations/1.0.2.0/pre-migration.py`
**Benefit**: Debug module upgrade and migration processes

#### **🌍 Translation Errors (`odoo-translation-error`)**
**Catches**: .po file syntax errors, translation inconsistencies
**Example**: `PoError: syntax error in custom_modules/rtp_customers/i18n/es.po:42`
**Benefit**: Fix internationalization issues in translation files

#### **📋 Manifest Errors (`odoo-manifest-error`)**
**Catches**: `__manifest__.py` structural issues, dependency errors
**Example**: `ManifestError: Invalid dependency 'non_existent_module' in custom_modules/rtp_customers/__manifest__.py`
**Benefit**: Validate module manifest files and dependencies

#### **🔍 Comprehensive Matcher (`odoo-comprehensive`)**
**Catches**: General Odoo errors with standard severity patterns
**Example**: `custom_modules/rtp_customers/models/customer.py:25: ERROR: Undefined variable 'self.customer_type'`
**Benefit**: Fallback for any Odoo-related errors not caught by specific matchers

### **Task Integration and Usage**

**Tasks Using Multiple Problem Matchers:**

**Server Startup Tasks:**
```json
"problemMatcher": [
    "$odoo-server-startup",
    "$odoo-module-import-error",
    "$odoo-database-constraint",
    "$odoo-comprehensive"
]
```

**Module Testing Tasks:**
```json
"problemMatcher": [
    "$python",
    "$odoo-module-import-error",
    "$odoo-manifest-error",
    "$odoo-field-definition-error",
    "$odoo-comprehensive"
]
```

**Validation Tasks:**
```json
"problemMatcher": [
    "odoo-validator",
    "$odoo-xml-validation",
    "$odoo-manifest-error",
    "$odoo-field-definition-error"
]
```

### **Royal Textiles Development Benefits**

**1. Faster Error Resolution**
- **Before**: Search through console output manually
- **After**: Click error in Problems panel to jump to exact location

**2. Field Type Error Prevention**
- **Detection**: Our `odoo-field-definition-error` matcher catches the Text/related field issues we encountered earlier
- **Prevention**: Immediate feedback when field types don't match relationships

**3. Customer Module Quality**
- **Import Validation**: Catch missing dependencies in RTP Customers module
- **XML Validation**: Ensure customer view definitions are correct
- **Security Validation**: Verify access rights for customer records

**4. Sales Module Reliability**
- **ORM Validation**: Catch search domain errors in sales order workflows
- **Database Validation**: Ensure foreign key relationships are correct
- **Template Validation**: Verify QWeb templates render properly

**5. Development Efficiency**
- **Real-time Feedback**: Errors appear in Problems panel as tasks run
- **Context Switching**: No need to scan terminal output manually
- **Team Consistency**: Same error handling across all developers

### **How to Use Problem Matchers**

**1. Run Any Task with Odoo Problem Matchers**
- Use keyboard shortcuts (e.g., `Ctrl+Shift+T` for tests)
- Run tasks from Command Palette (`Ctrl+Shift+P` → "Tasks: Run Task")
- Use VS Code task runner interface

**2. View Errors in Problems Panel**
- Open Problems panel: `Ctrl+Shift+M` or View → Problems
- Errors appear automatically as tasks complete
- Click any error to navigate to the source

**3. Navigate and Fix Issues**
- **File Navigation**: Click error to open file at exact line
- **Error Context**: See full error message with context
- **Multi-file Issues**: Handle errors across multiple modules

**4. Real-time Development Workflow**
```
1. Edit Odoo code (Python, XML, manifest)
2. Run relevant task (test, validate, start server)
3. Check Problems panel for issues
4. Click errors to navigate and fix
5. Re-run task to verify fixes
```

### **Advanced Problem Matcher Features**

**Severity Detection:**
- **Errors**: Red icons, high priority in Problems panel
- **Warnings**: Yellow icons, medium priority
- **Info**: Blue icons, informational

**File Location Intelligence:**
- **Relative Paths**: Properly resolve file paths within workspace
- **Line Numbers**: Jump to exact line causing the issue
- **Column Numbers**: Precise cursor positioning when available

**Multi-pattern Matching:**
- **Primary Patterns**: Most common error formats
- **Fallback Patterns**: Alternative formats for edge cases
- **Owner Grouping**: Organize errors by source (pylint, odoo-xml, etc.)

### **Troubleshooting Problem Matchers**

**Problem Matcher Not Working?**

1. **Check Task Configuration**
   - Verify task uses correct problem matcher references
   - Ensure matcher names start with `$` (e.g., `$odoo-comprehensive`)

2. **Verify Pattern Matching**
   - Problem matchers rely on specific output formats
   - If tools change output format, patterns may need updates

3. **Clear Problems Panel**
   - Sometimes old entries persist
   - Use View → Command Palette → "Problems: Clear All"

4. **Restart Language Server**
   - If patterns seem incorrect: `Ctrl+Shift+P` → "Python: Restart Language Server"

**Custom Problem Matcher Configuration:**
All problem matchers are defined in `.vscode/tasks.json` under the `"problemMatchers"` section. You can:
- **Modify Patterns**: Update regex patterns for different error formats
- **Add New Matchers**: Create matchers for additional tools
- **Customize Severity**: Adjust how errors/warnings are categorized

### ✏️ **Editor Optimization**

**Code Formatting:**
```json
"editor.formatOnSave": true
"editor.rulers": [80, 120]
"editor.wordWrap": "bounded"
"editor.wordWrapColumn": 120
```

**Language-Specific Settings:**
```json
"[python]": {
    "editor.defaultFormatter": "ms-python.black-formatter",
    "editor.tabSize": 4,
    "editor.rulers": [80, 120]
},
"[xml]": {
    "editor.defaultFormatter": "redhat.vscode-xml",
    "editor.tabSize": 2,
    "editor.formatOnSave": true
}
```

**Productivity Features:**
- Automatic code formatting on save
- Visual rulers for line length guidelines
- Language-specific formatting preferences

## 🔌 Extensions Configuration

### **Essential Odoo Extensions**

**🎯 Official Odoo Extension (`odoo.odoo`)**
- **Features**: Language server, IntelliSense, code navigation
- **Benefits**: Official support for Odoo development patterns
- **Usage**: Automatic model and field completion

**🛠️ Odoo IDE (`trinhanhngoc.vscode-odoo`)**
- **Features**: Framework integration, project structure understanding
- **Benefits**: Better understanding of Odoo module architecture
- **Usage**: Enhanced navigation and refactoring

**✂️ Odoo Snippets (`jigar-patel.OdooSnippets`)**
- **Features**: Additional code snippets for Odoo patterns
- **Benefits**: Complements our custom snippet system
- **Usage**: Quick insertion of common Odoo code patterns

### **Python Development Extensions**

**🐍 Core Python Extensions:**
- `ms-python.python` - Python IntelliSense and debugging
- `ms-python.black-formatter` - Code formatting with Black
- `ms-python.pylint` - Linting with Odoo support
- `ms-python.mypy-type-checker` - Type checking

**📊 Testing and Quality:**
- `ms-toolsai.jupyter` - Jupyter notebook support
- `littlefoxteam.vscode-python-test-adapter` - Test runner integration
- `njpwerner.autodocstring` - Automatic docstring generation

### **XML and Frontend Extensions**

**🌐 XML Development:**
- `redhat.vscode-xml` - XML language support with validation
- `dotjoshjohnson.xml` - Additional XML tools
- `formulahendry.auto-rename-tag` - Auto-rename paired tags

**🎨 Frontend Development:**
- `esbenp.prettier-vscode` - Code formatter for JS/CSS/HTML
- `bradlc.vscode-tailwindcss` - Tailwind CSS support
- `ms-vscode.vscode-typescript-next` - TypeScript support

### **Database and Data Extensions**

**🗄️ Database Tools:**
- `mtxr.sqltools` - SQL tools and database management
- `ckolkman.vscode-postgres` - PostgreSQL support
- `mechatroner.rainbow-csv` - CSV file editing

### **Productivity Extensions**

**⚡ Development Efficiency:**
- `eamodio.gitlens` - Enhanced Git capabilities
- `streetsidesoftware.code-spell-checker` - Spell checking
- `aaron-bond.better-comments` - Enhanced comment highlighting
- `alefragnani.bookmarks` - Code bookmarks

**🤖 AI Assistance:**
- `github.copilot` - AI code completion
- `github.copilot-chat` - AI chat assistance
- `visualstudioexptteam.vscodeintellicode` - IntelliCode

## 🎯 Workflow Optimizations

### **File Management**

**Smart File Nesting:**
```json
"explorer.fileNesting.patterns": {
    "*.py": "${capture}.pyc, ${capture}.pyo",
    "__manifest__.py": "__init__.py, *.pot, *.po",
    "requirements.txt": "requirements-*.txt, pyproject.toml"
}
```

**Benefits:**
- Cleaner file explorer with related files grouped
- Easier navigation in complex module structures
- Reduced visual clutter

**Search Exclusions:**
```json
"search.exclude": {
    "**/__pycache__": true,
    "**/venv": true,
    "**/htmlcov": true,
    "**/.pytest_cache": true
}
```

**Benefits:**
- Faster search results by excluding generated files
- Focus on relevant source code only
- Improved search performance

### **Terminal Integration**

**Environment Configuration:**
```json
"terminal.integrated.env.osx": {
    "PYTHONPATH": "${workspaceFolder}/custom_modules:${workspaceFolder}/local-odoo/odoo"
}
```

**Benefits:**
- Automatic Python path configuration
- Seamless integration with Odoo development tools
- Consistent environment across terminal sessions

### **IntelliSense Optimization**

**Path Configuration:**
```json
"intelliSense.includePaths": [
    "./custom_modules",
    "./local-odoo/odoo",
    "./tests"
]
```

**Benefits:**
- Accurate autocompletion for Odoo imports
- Navigation to model and view definitions
- Improved code intelligence

## 🚀 Advanced Features

### **Task Integration**

The workspace integrates with our comprehensive task system:

**Quick Access to Tasks:**
- `Ctrl+Shift+P` → "Tasks: Run Task"
- Access all 54 predefined tasks from the command palette
- Organized task groups for easy navigation

**Common Development Tasks:**
- **🧪 Testing**: `pytest`, `test-module`, `test-coverage`
- **🔍 Code Quality**: `lint`, `format`, `validate`
- **📦 Module Management**: `install-module`, `upgrade-module`
- **🗃️ Database**: `db-create`, `db-reset`, `backup`

### **Debugging Integration**

**Pre-configured Debug Configurations:**
- **Start Odoo Development Server** - Basic server debugging
- **Debug Odoo with Custom Modules** - Module-specific debugging
- **Debug Odoo Tests** - Test debugging with breakpoints
- **Attach to Running Odoo** - Remote debugging support

**Debug Features:**
- Breakpoint support in Python code
- Variable inspection and watches
- Call stack navigation
- Console integration

### **Snippet Integration**

**60+ Custom Snippets Available:**
- **Python**: `odoo-model-rtp`, `odoo-controller`, `odoo-constraint`
- **XML**: `odoo-rtp-form`, `odoo-tree-view`, `odoo-action`
- **JavaScript**: `odoo-js-widget`, `odoo-qweb-template`

**Usage:**
1. Type snippet prefix (e.g., `odoo-model-rtp`)
2. Press `Tab` to insert
3. Navigate placeholders with `Tab`
4. Customize for your specific needs

## 🔧 Customization

### **Personal Settings Override**

**User-Specific Customizations:**
1. Open VS Code User Settings (`Ctrl+,`)
2. Add overrides for personal preferences
3. Workspace settings take precedence for team consistency

**Example Personal Overrides:**
```json
{
    "workbench.colorTheme": "Monokai",
    "editor.fontSize": 14,
    "terminal.integrated.fontSize": 12
}
```

### **Team Settings**

**Shared Team Configuration:**
- All team members get consistent workspace settings
- Centralized configuration in `.vscode/settings.json`
- Version controlled for team synchronization

### **Extension Customization**

**Adding Extensions:**
1. Install extension in VS Code
2. Add to `.vscode/extensions.json` recommendations
3. Commit changes for team sharing

**Configuring Extensions:**
1. Add extension-specific settings to `.vscode/settings.json`
2. Use namespace prefixes (e.g., `python.`, `odoo.`)
3. Document configuration choices

## ⌨️ Keyboard Shortcuts for Testing Workflows

### **Essential Testing Shortcuts**

**Core Testing Commands:**
- `Ctrl+Shift+T` - **🧪 Run All Tests** - Execute complete test suite
- `Ctrl+Alt+T` - **🧪 Test Current Module** - Run tests for active module
- `Ctrl+Shift+I` - **🔄 Integration Tests** - Run integration test suite
- `Ctrl+Alt+P` - **⚡ Performance Tests** - Execute performance benchmarks
- `Ctrl+Shift+C` - **📊 Coverage Report** - Generate test coverage analysis

**Why These Shortcuts Matter:**
- **Fast Feedback Loop** - Instant test execution without leaving editor
- **Context-Aware Testing** - Module-specific testing based on current file
- **Comprehensive Coverage** - Easy access to all test types
- **Development Efficiency** - Keyboard-driven workflow for faster iteration

### **Code Quality Shortcuts**

**Linting and Formatting:**
- `Ctrl+Shift+L` - **🔍 Lint All Code** - Run complete linting suite
- `Ctrl+Alt+L` - **🔍 Lint Current File** - Quick file-specific linting
- `Ctrl+Shift+F` - **🎨 Format Current File** - Auto-format current file
- `Ctrl+Alt+O` - **🔍 Odoo-Specific Linting** - Run Pylint with Odoo rules
- `Ctrl+Shift+M` - **🔍 Type Checking** - Run MyPy type analysis

**Benefits:**
- **Immediate Feedback** - Instant code quality checks
- **Consistent Style** - Automated formatting for team consistency
- **Odoo Best Practices** - Specialized linting for Odoo patterns
- **Error Prevention** - Catch issues early in development

### **Module and Validation Shortcuts**

**Module Management:**
- `Ctrl+Shift+V` - **✅ Validate All Modules** - Comprehensive module validation
- `Ctrl+Alt+V` - **✅ Validate Current Module** - Context-specific validation
- `Ctrl+Shift+U` - **📦 Test Module Installation** - Test module installation process
- `Ctrl+Alt+U` - **📦 Test Module Upgrade** - Test module upgrade process

**Benefits:**
- **Deployment Readiness** - Ensure modules are ready for production
- **Royal Textiles Compliance** - Validate business logic and data integrity
- **Installation Testing** - Verify module installation in clean environments
- **Upgrade Safety** - Test upgrade processes before deployment

### **Business Workflow Shortcuts**

**Royal Textiles Specific:**
- `Ctrl+Shift+W` - **👥 Customer Workflow Tests** - Test customer management flows
- `Ctrl+Alt+W` - **💰 Sales Workflow Tests** - Test sales order processes
- `Ctrl+Shift+D` - **🗃️ Database Performance Tests** - Test database operations
- `Ctrl+Alt+D` - **🖥️ View Performance Tests** - Test UI rendering performance

**Business Value:**
- **End-to-End Testing** - Validate complete business processes
- **Customer Experience** - Ensure smooth customer interaction flows
- **Sales Efficiency** - Verify sales order processing performance
- **System Performance** - Monitor and optimize system responsiveness

### **Function Key Shortcuts (Python Files)**

**Context-Aware File Actions:**
- `F5` - **🧪 Run All Tests** - Quick test execution (Python files only)
- `F6` - **🔍 Lint Current File** - Immediate linting feedback
- `F7` - **🎨 Format Current File** - Instant code formatting
- `F8` - **✅ Validate Modules** - Quick validation (Python/XML files)

**Workflow Benefits:**
- **Single-Key Actions** - Fastest possible execution
- **File-Type Awareness** - Only active for relevant file types
- **Immediate Feedback** - No context switching required
- **Muscle Memory** - Consistent shortcuts across different file types

### **Context-Sensitive Shortcuts**

**Module-Specific Actions:**
- `Ctrl+Alt+Shift+T` - **Royal Textiles Complete Test** (when in royal_textiles_sales/)
- `Ctrl+Alt+Shift+R` - **RTP Customers Complete Test** (when in rtp_customers/)

**Advanced Testing:**
- `Ctrl+Shift+Alt+C` - **📊 Full Coverage Analysis** - Complete coverage workflow
- `Ctrl+Shift+Alt+I` - **📊 Coverage Insights** - Detailed coverage recommendations
- `Ctrl+Shift+Alt+P` - **🚀 CI/CD Pipeline Tests** - Full deployment testing

**Smart Context Features:**
- **Location-Aware** - Different shortcuts based on current file location
- **Module-Specific** - Targeted testing for specific modules
- **Progressive Testing** - From quick checks to comprehensive analysis
- **CI/CD Integration** - Simulate deployment pipeline locally

### **Terminal and Task Integration**

**Quick Access:**
- `Ctrl+Shift+\`` - **Toggle Terminal** - Quick terminal access
- `Ctrl+Shift+P` - **Run Task** - Open task selection menu

**Benefits:**
- **Seamless Integration** - Keyboard shortcuts work with existing task system
- **No Mouse Required** - Complete keyboard-driven workflow
- **Fast Context Switching** - Quick movement between editor and terminal
- **Task Discovery** - Easy access to all 54+ predefined tasks

### **Customization and Conflicts**

**Avoiding Conflicts:**
- **Standard Compliance** - Shortcuts follow VS Code conventions
- **Context Awareness** - Most shortcuts only active when editing text
- **File Type Specificity** - Function keys only work with appropriate file types
- **Modifier Combinations** - Use Ctrl+Alt and Ctrl+Shift to avoid conflicts

**Customization Options:**
1. **Override Shortcuts** - Edit `.vscode/keybindings.json` for personal preferences
2. **Add New Shortcuts** - Extend the configuration for team-specific needs
3. **Disable Shortcuts** - Comment out or remove unwanted shortcuts
4. **Context Modification** - Adjust `when` clauses for different contexts

### **Workflow Integration Examples**

**Typical Development Workflow:**
1. **Edit Code** - Make changes to Python/XML files
2. **Quick Check** - `F6` to lint current file
3. **Format** - `F7` to format code
4. **Test** - `F5` to run tests
5. **Validate** - `F8` to validate modules
6. **Integration** - `Ctrl+Shift+I` for integration tests
7. **Coverage** - `Ctrl+Shift+C` for coverage analysis

**Royal Textiles Specific Workflow:**
1. **Customer Module Work** - Edit customer-related files
2. **Module Test** - `Ctrl+Alt+Shift+R` for RTP Customers complete test
3. **Sales Flow** - `Ctrl+Alt+W` for sales workflow tests
4. **Performance Check** - `Ctrl+Shift+D` for database performance
5. **Full Validation** - `Ctrl+Shift+V` for complete validation
6. **CI/CD Check** - `Ctrl+Shift+Alt+P` for deployment readiness

## 🎨 Themes and Appearance

### **Recommended Themes**

**For Royal Textiles Development:**
- **Default Dark+** - Good contrast for long coding sessions
- **Material Theme** - Modern, colorful syntax highlighting
- **Monokai Pro** - Popular theme with excellent Python support

**Icon Themes:**
- **Material Icon Theme** - Clear file type recognition
- **VS Code Icons** - Comprehensive icon set

### **UI Customization**

**Optimized Settings:**
```json
"workbench.tree.indent": 20,
"workbench.list.smoothScrolling": true,
"editor.minimap.renderCharacters": false,
"editor.bracketPairColorization.enabled": true
```

## 🔍 Troubleshooting

### **Common Issues**

**Python Interpreter Not Found:**
1. Check virtual environment is activated
2. Verify interpreter path in settings
3. Reload VS Code window

**Odoo IntelliSense Not Working:**
1. Verify Odoo extension is installed and enabled
2. Check `odoo.addonsPath` settings
3. Restart language server: `Ctrl+Shift+P` → "Python: Restart Language Server"

**Extensions Not Loading:**
1. Check VS Code version compatibility
2. Disable conflicting extensions
3. Clear extension cache and reload

### **Performance Optimization**

**For Large Projects:**
```json
"search.useIgnoreFiles": true,
"files.watcherExclude": {
    "**/node_modules/**": true,
    "**/venv/**": true,
    "**/.git/objects/**": true
}
```

**Memory Usage:**
- Close unused editor tabs
- Disable preview mode for better performance
- Use workspace folders to organize large projects

## 📚 Additional Resources

### **Documentation Links**
- **VS Code Python Development**: https://code.visualstudio.com/docs/python/python-tutorial
- **Odoo Development Documentation**: https://www.odoo.com/documentation/18.0/developer.html
- **VS Code Workspace Guide**: https://code.visualstudio.com/docs/editor/workspaces

### **Team Resources**
- **Debugging Guide**: [docs/vscode-debugging-guide.md](./vscode-debugging-guide.md)
- **Tasks Guide**: [docs/vscode-tasks-guide.md](./vscode-tasks-guide.md)
- **Snippets Guide**: [docs/vscode-snippets-guide.md](./vscode-snippets-guide.md)
- **Testing Guide**: [docs/testing-guide.md](./testing-guide.md)

### **Extension Documentation**
- **Official Odoo Extension**: https://marketplace.visualstudio.com/items?itemName=Odoo.odoo
- **Odoo IDE Extension**: https://marketplace.visualstudio.com/items?itemName=trinhanhngoc.vscode-odoo
- **Python Extension**: https://marketplace.visualstudio.com/items?itemName=ms-python.python

## 🎉 Conclusion

This comprehensive VS Code workspace configuration provides:

- **🎯 Optimized Settings** for Royal Textiles Odoo development
- **🔌 Essential Extensions** for productivity and code quality
- **⚙️ Seamless Integration** with debugging, testing, and automation
- **📁 Organized Structure** for efficient project navigation
- **🚀 Advanced Features** for professional development workflows

**Key Benefits:**
- **Faster Development** with IntelliSense and autocompletion
- **Better Code Quality** with integrated linting and formatting
- **Team Consistency** with shared configuration and standards
- **Professional Workflow** with debugging, testing, and automation
- **Royal Textiles Optimization** with business-specific patterns

For questions or customization requests, see the team documentation or reach out to the development team!

**Quick Command Reference:**

**VS Code Essentials:**
- `Ctrl+Shift+P` - Command Palette
- `Ctrl+Shift+E` - Explorer
- `Ctrl+Shift+G` - Git
- `Ctrl+`` - Terminal
- `Ctrl+Shift+``- Toggle Terminal

**Testing Workflow Shortcuts:**
- `Ctrl+Shift+T` - Run All Tests
- `Ctrl+Alt+T` - Test Current Module
- `Ctrl+Shift+I` - Integration Tests
- `Ctrl+Alt+P` - Performance Tests
- `Ctrl+Shift+C` - Coverage Report

**Code Quality Shortcuts:**
- `Ctrl+Shift+L` - Lint All Code
- `Ctrl+Alt+L` - Lint Current File
- `Ctrl+Shift+F` - Format Current File
- `Ctrl+Alt+O` - Odoo-Specific Linting
- `Ctrl+Shift+M` - Type Checking

**Function Key Shortcuts (Python Files):**
- `F5` - Run All Tests
- `F6` - Lint Current File
- `F7` - Format Current File
- `F8` - Validate Modules

**Module Management:**
- `Ctrl+Shift+V` - Validate All Modules
- `Ctrl+Alt+V` - Validate Current Module
- `Ctrl+Shift+U` - Test Module Installation
- `Ctrl+Alt+U` - Test Module Upgrade

**Business Workflows:**
- `Ctrl+Shift+W` - Customer Workflow Tests
- `Ctrl+Alt+W` - Sales Workflow Tests
- `Ctrl+Shift+D` - Database Performance Tests
- `Ctrl+Alt+D` - View Performance Tests

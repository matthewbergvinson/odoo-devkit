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

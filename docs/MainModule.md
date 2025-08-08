# Enhanced MainModule Documentation

## Overview
The Enhanced MainModule is a robust, production-ready module loader and system manager for the Kaiju Battle Arena game. It provides a structured way to load, initialize, and manage game systems with comprehensive error handling and logging.

## Features

- **System Management**: Load and manage game systems with dependencies
- **Error Handling**: Comprehensive error catching and reporting
- **Logging**: Configurable logging with multiple severity levels
- **Status Tracking**: Monitor system initialization and status
- **Dependency Management**: Handle system dependencies automatically
- **Retry Mechanism**: Automatic retries for failed initializations

## Getting Started

### Prerequisites
- Roblox Studio
- Basic knowledge of Luau scripting
- Familiarity with Roblox services

### Installation
1. Place `MainModule.lua` in `ServerScriptService`
2. Place system modules in `ServerScriptService/systems/`
3. Add system names to the `systemsToLoad` array in the MainModule

## Usage

### Basic Initialization

```lua
local ServerScriptService = game:GetService("ServerScriptService")
local MainModule = require(ServerScriptService:WaitForChild("MainModule"))

-- Initialize all systems
local success, result = MainModule:init()
if not success then
    warn("Initialization failed:", result)
    return
end

-- Get a specific system
local characterSystem = MainModule:getSystem("CharacterSystem")
if characterSystem then
    -- Use the system
end
```

### Configuration

Configure the MainModule by modifying the `config` table:

```lua
-- Before calling init()
MainModule.config = {
    debug = true,          -- Enable debug logging
    strictMode = true,     -- Fail fast on errors
    autoStart = true,      -- Automatically start systems after initialization
    maxInitRetries = 3,    -- Number of retry attempts for failed initializations
    initRetryDelay = 1     -- Delay between retry attempts (seconds)
}
```

### Logging

The MainModule includes a built-in logger with multiple severity levels:

```lua
-- Set log level (TRACE, DEBUG, INFO, WARN, ERROR, FATAL)
MainModule.logger:setLevel(MainModule.logger.levels.INFO)

-- Log messages
MainModule.logger:info("System initialized")
MainModule.logger:warn("Warning message")
MainModule.logger:error("Error message")
```

## System Development

### Creating a New System

1. Create a new ModuleScript in `ServerScriptService/systems/`
2. Implement the required `init()` function
3. Optionally implement `start()` and `stop()` functions

Example system:

```lua
-- ServerScriptService/systems/ExampleSystem.lua
local ExampleSystem = {}
ExampleSystem.name = "ExampleSystem"
ExampleSystem.version = "1.0.0"
ExampleSystem.dependencies = {"DependencySystem"}  -- Optional dependencies

function ExampleSystem:init()
    -- Initialize the system
    print("Initializing ExampleSystem")
    return true  -- Return true on success
end

function ExampleSystem:start()
    -- Optional: Start the system
    print("Starting ExampleSystem")
    return true
end

function ExampleSystem:customMethod()
    -- Add custom methods as needed
    return "Hello from ExampleSystem"
end

return ExampleSystem
```

## API Reference

### Methods

#### `init(): (boolean, string)`
Initializes all systems in the specified order.

**Returns:**
- `success` (boolean): Whether initialization was successful
- `message` (string): Status message or error description

#### `start(): (boolean, string)`
Starts all initialized systems that have a `start()` method.

**Returns:**
- `success` (boolean): Whether starting was successful
- `message` (string): Status message or error description

#### `getSystem(systemName: string): any?`
Retrieves a system by name.

**Parameters:**
- `systemName` (string): Name of the system to retrieve

**Returns:**
- The system instance, or `nil` if not found

#### `getSystemStatus(systemName: string): SystemStatus?`
Gets the status of a system.

**Parameters:**
- `systemName` (string): Name of the system

**Returns:**
- `SystemStatus` table or `nil` if not found

#### `getAllSystemStatuses(): {[string]: SystemStatus}`
Gets the status of all systems.

**Returns:**
- Table mapping system names to their status

#### `verifySystems(): (boolean, {[string]: string}?)`
Verifies that all required systems are initialized.

**Returns:**
- `allValid` (boolean): Whether all systems are valid
- `errors` (table?): Table of error messages if not all systems are valid

### SystemStatus Type

```lua
type SystemStatus = {
    name: string,           -- System name
    loaded: boolean,        -- Whether the system was loaded
    initialized: boolean,   -- Whether the system was initialized
    started: boolean,       -- Whether the system was started
    error: string?,         -- Last error message (if any)
    dependencies: {string}, -- System dependencies
    loadTime: number?,      -- Time taken to load (seconds)
    initTime: number?,      -- Time taken to initialize (seconds)
    startTime: number?,     -- Time taken to start (seconds)
    lastError: string?      -- Timestamp of last error
}
```

## Best Practices

1. **Error Handling**: Always check return values from MainModule methods
2. **Dependencies**: Declare all system dependencies in the `dependencies` table
3. **Logging**: Use the built-in logger for consistent logging
4. **Initialization**: Call `init()` before accessing any systems
5. **Cleanup**: Implement `stop()` methods for systems that need cleanup

## Troubleshooting

### Common Issues

1. **System Not Found**
   - Ensure the system script is in `ServerScriptService/systems/`
   - Check for typos in the system name

2. **Dependency Errors**
   - Ensure all dependencies are listed in the `dependencies` table
   - Check that dependencies are loaded before the system that needs them

3. **Initialization Failures**
   - Check the logs for error messages
   - Verify that all required services are available

### Debugging

Enable debug logging for more detailed information:

```lua
MainModule.logger:setLevel(MainModule.logger.levels.DEBUG)
```

## License

This project is part of the Kaiju Battle Arena codebase and is subject to the project's license terms.

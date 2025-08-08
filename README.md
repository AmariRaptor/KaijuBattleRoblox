# Kaiju Battle Arena - Roblox Game

A thrilling kaiju-themed battle game where players can choose to be giant monsters or city defenders!

## Game Features

- Choose between Kaiju, Guardian, or Engineer classes
- Epic monster battles in a destructible city environment
- Unique abilities for each class
- Team-based gameplay
- Dynamic weather effects
- Comprehensive testing framework
- Robust system management with enhanced MainModule

## Setup Instructions

### Prerequisites

- [Roblox Studio](https://www.roblox.com/create)
- [Rojo](https://rojo.space/docs/v7/getting-started/)
- [Aftman](https://github.com/LPGhatguy/aftman)
- Basic knowledge of Roblox Luau scripting

### Installation

1. Clone the repository
2. Install dependencies:

   ```bash
   aftman install
   ```

3. Build the project:

   ```bash
   rojo build -o KaijuBattleRoblox.rbxlx
   ```

4. Open `KaijuBattleRoblox.rbxlx` in Roblox Studio

## System Architecture

### Enhanced MainModule

The game uses an enhanced MainModule for robust system management. For detailed documentation, see [docs/MainModule.md](docs/MainModule.md).

Key features:

- Automatic dependency resolution
- Comprehensive error handling
- Detailed logging and status tracking
- Configurable initialization
- System health monitoring

### Initialization Pattern

All game systems follow a standardized initialization pattern to ensure consistency and maintainability:

1. **Constructor Pattern**:
   - Each system implements a `new()` constructor that creates a new instance
   - The constructor calls the `init()` method for initialization
   - Example:

     ```lua
     function SystemName.new()
         local self = setmetatable({}, SystemName)
         self:init()
         return self
     end
     ```

2. **Initialization Method**:
   - Each system has an `init()` method that handles setup logic
   - The method returns `true` on success or `false`/`nil` on failure
   - Example:

     ```lua
     function SystemName:init()
         print("🔄 Initializing SystemName...")
         -- Initialization logic here
         print("✅ SystemName initialized successfully")
         return true
     end
     ```

3. **Module Export**:
   - Systems are exported as instantiated singletons
   - The module returns `SystemName.new()`

## Game Systems

### 1. Character System

Handles player characters, classes, and attributes.

**Initialization

- Creates player character instances
- Sets up class attributes
- Manages character abilities

**Key Features

- Class-based attributes (Health, Speed, etc.)
- Dynamic class changes
- Ability management
- Character state handling

### 2. Kaiju System

Manages Kaiju-specific functionality and abilities.

**Initialization**

- Sets up Kaiju abilities and events
- Initializes Kaiju state tracking
- Configures ability cooldowns

**Key Features**

- Special abilities (Roar, Energy Beam, etc.)
- Kaiju state management
- Player-to-Kaiju transformation
- Ability cooldown system

## Adding New Systems

To add a new system to the game, follow these steps:

1. **Review the MainModule Documentation**
   - See [docs/MainModule.md](docs/MainModule.md) for detailed information
   - Understand the system lifecycle and requirements

2. **Create a new ModuleScript** in the `ServerScriptService/systems` folder with the following structure:

   ```lua
   --!strict
   -- systems/NewSystem.server.luau
   
   local NewSystem = {}
   NewSystem.__index = NewSystem
   
   -- Constructor
   function NewSystem.new()
       local self = setmetatable({}, NewSystem)
       self:init()
       return self
   end
   
   -- Initialize the system
   function NewSystem:init()
       -- Configuration
       self.isInitialized = false
       
       -- Dependencies
       self.dependencies = {
           -- List any other systems this system depends on
       }
       
       -- Initialize system components
       self:setupEvents()
       self:setupConnections()
       
       self.isInitialized = true
       print("✅ NewSystem initialized successfully")
       return true
   end
   
   -- Set up RemoteEvents and BindableEvents
   function NewSystem:setupEvents()
       -- Create any necessary RemoteEvents or BindableEvents here
   end
   
   -- Set up event connections
   function NewSystem:setupConnections()
       -- Set up any event connections here
   end
   
   -- Cleanup method (optional)
   function NewSystem:cleanup()
       -- Clean up any resources, connections, etc.
   end
   
   return NewSystem.new()
   ```

2. **Update the Main system** to initialize your new system:
   - Open `ServerScriptService/Main.server.luau`
   - Add your system to the `systems` table
   - The main script will automatically require and initialize it

3. **Testing your system**:
   - Use the built-in test framework by adding tests to the `ServerScriptService/tests` folder
   - Follow the naming convention: `NewSystem.spec.luau`
   - Run tests using the TestService or through the test runner

4. **Documentation**:
   - Add documentation for your system in this README
   - Include:
     - System purpose and responsibilities
     - Public API methods
     - Configuration options
     - Dependencies
     - Example usage

5. **Best Practices**:
   - Follow the single responsibility principle
   - Use strict typing with `--!strict`
   - Include error handling
   - Document public methods
   - Keep system communication through defined interfaces
   - Use dependency injection for testability

   ```lua
   --!strict
   -- YourSystemName.server.luau
   
   local YourSystemName = {}
   YourSystemName.__index = YourSystemName
   
   -- Constructor
   function YourSystemName.new()
       local self = setmetatable({}, YourSystemName)
       self:init()
       return self
   end
   
   -- Initialization method
   function YourSystemName:init(): boolean
       print("🔄 Initializing YourSystemName...")
       
       -- Add your initialization code here
       self.initialized = true
       
       print("✅ YourSystemName initialized successfully")
       return true
   end
   
   -- Add your system's methods here
   
   -- Export as a singleton
   return YourSystemName.new()
   ```

2. **Add your system to the Main script** by adding it to the `SYSTEM_NAMES` table:

   ```lua
   local SYSTEM_NAMES = {
       "ClassSystem",
       "CharacterSystem",
       "BuildingSystem",
       "KaijuSystem",
       "ScoringSystem",
       "YourSystemName"  -- Add your system here
   }
   ```

3. **Test your system** by running the game and checking the output for initialization messages.

## Testing

The project includes a comprehensive testing framework to ensure stability and reliability.

### Running Tests

1. In Roblox Studio, run the test script:

   ```lua
   require(game.ServerScriptService.Tests.run_tests)
   ```

2. View test results in the Output window

### Test Coverage

- **Unit Tests**: Individual system testing
- **Integration Tests**: Cross-system interaction testing
- **Edge Case Testing**: Invalid inputs and error conditions

#### Current Coverage

```text
Test Summary:
========================================
Total Tests: 42
Passed: 40
Failed: 2
Coverage: 95%
```

### Writing Tests

1. Create test files in the `Tests` directory
2. Follow the naming convention: `SystemName.spec.luau`
3. Export a function that returns test results

Example test structure:

```lua
--!strict
return function()
    local results = {}
    
    -- Test cases
    table.insert(results, "✅ Test passed")
    table.insert(results, "❌ Test failed")
    
    return results
end
```

## Configuration

Game settings can be configured in `src/shared/config/GameConfig.luau`:

```lua
return {
    Classes = {
        Kaiju = {
            MaxHealth = 500,
            WalkSpeed = 24,
            Abilities = {"Smash", "Charge", "Roar"}
        },
        -- Other classes...
    },
    Game = {
        RoundDuration = 600, -- seconds
        MinPlayers = 2,
        MaxPlayers = 10
    }
}
```

## Development

### Code Style

- Use `--!strict` mode in all scripts
- Follow Roblox Luau style guidelines
- Document all public APIs
- Write tests for new features

### Version Control

- Branch naming: `feature/description` or `fix/issue-name`
- Commit messages: Use conventional commits
- PRs require passing tests and code review

## Troubleshooting

### Common Issues

1. **Tests not running**:
   - Ensure all services are properly mocked
   - Check for syntax errors in test files

2. **Missing dependencies**:
   - Run `aftman install`
   - Verify Rojo is properly configured

3. **Test failures**:
   - Check the Output window for detailed error messages
   - Verify test environment setup

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

[MIT License](LICENSE)

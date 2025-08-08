--!strict

-- Fixed version of MainModule with proper state management
print("Loading FixedMainModule...")

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Module interface
local FixedMainModule = {}
FixedMainModule.__index = FixedMainModule

-- Private state (local to this module)
local state = {
    initialized = false,
    initializedSystems = {}
}

-- List of systems to load (moved to module-level scope)
local systemsToLoad = {
    "ClassSystem",
    "CharacterSystem",
    "BuildingSystem",
    "KaijuSystem",
    "ScoringSystem"
}

-- Initialize a single system
local function initializeSystem(name: string): any
    print(`\n🔍 Initializing system: {name}`)
    
    -- Look for systems folder in ServerScriptService
    local systemsFolder = ServerScriptService:FindFirstChild("systems")
    if not systemsFolder then
        warn("❌ 'systems' folder not found in ServerScriptService")
        return nil
    end
    
    -- Find the module
    local moduleScript = systemsFolder:FindFirstChild(name)
    if not moduleScript or not moduleScript:IsA("ModuleScript") then
        warn(`❌ System module not found: {name}`)
        return nil
    end
    
    -- Require the module
    local success, result = pcall(require, moduleScript)
    if not success then
        warn(`❌ Failed to require system {name}:`)
        warn(result)
        return nil
    end
    
    -- Verify the module has the required structure
    if type(result) ~= "table" then
        warn(`❌ {name} did not return a table (got: {type(result)})`)
        return nil
    end
    
    -- Check for init function
    if type(result.init) ~= "function" then
        warn(`⚠️ {name} is missing init() method - adding default implementation`)
        result.init = function()
            print(`✅ {name} initialized (default implementation)`)
            return true
        end
    end
    
    -- Initialize the system
    print(`🔄 Calling {name}:init()...`)
    local initSuccess, initResult = pcall(function()
        return result.init()
    end)
    
    if not initSuccess then
        warn(`❌ {name}:init() failed with error:`)
        warn(initResult)
        return nil
    end
    
    if initResult == false then
        warn(`⚠️ {name}:init() returned false, indicating initialization failure`)
        return nil
    end
    
    print(`✅ {name} initialized successfully`)
    return result
end

-- Constructor
function FixedMainModule.new()
    local self = setmetatable({}, FixedMainModule)
    return self
end

-- Check if initialized
function FixedMainModule:isInitialized(): boolean
    return state.initialized
end

-- Get a system by name
function FixedMainModule:getSystem(systemName: string): any
    return state.initializedSystems[systemName]
end

-- Get all initialized systems
function FixedMainModule:getInitializedSystems(): {[string]: any}
    local result = {}
    for name, system in pairs(state.initializedSystems) do
        result[name] = system
    end
    return result
end

-- Initialize the module
function FixedMainModule:init(): boolean
    if self:isInitialized() then
        warn("⚠️ FixedMainModule already initialized")
        return true
    end
    
    print("\n🚀 Initializing FixedMainModule...")
    print("📋 Systems to load: " .. table.concat(systemsToLoad, ", ") .. "\n")
    
    -- Set up shared folders
    local shared = Instance.new("Folder")
    shared.Name = "Shared"
    shared.Parent = ReplicatedStorage
    
    -- Ensure systems folder exists
    local systemsFolder = ServerScriptService:FindFirstChild("systems")
    if not systemsFolder then
        systemsFolder = Instance.new("Folder")
        systemsFolder.Name = "systems"
        systemsFolder.Parent = ServerScriptService
        warn("⚠️ Created 'systems' folder in ServerScriptService")
    end
    
    -- Initialize all systems
    local successCount = 0
    for _, systemName in ipairs(systemsToLoad) do
        local system = initializeSystem(systemName)
        if system then
            state.initializedSystems[systemName] = system
            successCount += 1
            print(`✅ Successfully initialized {systemName}`)
        else
            warn(`❌ Failed to initialize {systemName}`)
        end
    end
    
    -- Mark as initialized
    state.initialized = true
    
    -- Print summary
    print("\n=== Initialization Summary ===")
    print(string.format("Successfully initialized %d/%d systems", successCount, #systemsToLoad))
    print("Initialized systems:")
    for name, _ in pairs(state.initializedSystems) do
        print("  - " .. name)
    end
    
    -- Set up player events
    self:setupPlayerEvents()
    
    print("\n✅ FixedMainModule initialization complete")
    return true
end

-- Set up player events
function FixedMainModule:setupPlayerEvents()
    print("\nSetting up player events...")
    
    game.Players.PlayerAdded:Connect(function(player)
        print(`\nPlayer {player.Name} joined the game`)
        
        -- Assign initial class
        local classSystem = self:getSystem("ClassSystem")
        if classSystem and type(classSystem.assignRandomClass) == "function" then
            print(`- Assigning random class to {player.Name}`)
            classSystem.assignRandomClass(player)
        end
        
        -- Set up character
        local characterSystem = self:getSystem("CharacterSystem")
        if characterSystem and type(characterSystem.setupCharacter) == "function" then
            player.CharacterAdded:Connect(function(character)
                local class = player:FindFirstChild("PlayerClass")
                if class then
                    print(`- Setting up character for {player.Name} (Class: {class.Value})")
                    characterSystem.setupCharacter(player, class.Value)
                end
            end)
        end
    end)
    
    print("✅ Player events set up")
end

-- Return the module
return FixedMainModule

--!strict

print("Server initialization started.")

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Module interface
local MainModule = {}
MainModule.__index = MainModule

-- State
local initialized = false
local initializedSystems = {}

-- List of systems to load
local systemsToLoad = {
    "ClassSystem",
    "CharacterSystem",
    "BuildingSystem",
    "KaijuSystem",
    "ScoringSystem"
}

-- Initialize a single system
local function initializeSystem(name: string): any
    print(`\n🔍 [${os.clock()}] Initializing system: {name}`)
    
    -- Look for systems folder in ServerScriptService
    print("🔍 [1/7] Looking for 'systems' folder in ServerScriptService...")
    local systemsFolder = ServerScriptService:FindFirstChild("systems")
    
    if not systemsFolder then
        print("ℹ️ 'systems' folder not found in ServerScriptService, checking parent directory...")
        systemsFolder = script.Parent and script.Parent:FindFirstChild("systems")
        if not systemsFolder then
            warn("❌ ERROR: 'systems' folder not found in ServerScriptService or script parent")
            return nil
        end
    end
    
    print(`✅ Found systems folder at: {systemsFolder:GetFullName()}`)
    
    -- List all modules in the systems folder for debugging
    print("📋 [2/7] Modules in systems folder:")
    local foundModule = false
    for _, child in ipairs(systemsFolder:GetChildren()) do
        print(`- {child.Name} (Type: {child.ClassName})`)
        if child.Name == name and child:IsA("ModuleScript") then
            foundModule = true
            print(`  ✅ Found matching ModuleScript for {name}`)
        end
    end
    if not foundModule then
        print(`❌ [2/7] No ModuleScript found with name: {name}`)
    end
    
    print(`\n🔍 [3/7] Looking for module: {name}`)
    local modulePath = systemsFolder:FindFirstChild(name, true) -- Recursive search
    
    if not modulePath then
        warn(`❌ ERROR: System module not found: {name}`)
        local availableModules = {}
        for _, child in ipairs(systemsFolder:GetChildren()) do
            table.insert(availableModules, child.Name)
        end
        warn(`   Available modules: {table.concat(availableModules, ", ")}`)
        return nil
    end
    
    print(`✅ Found module: {modulePath:GetFullName()}`)
    
    -- Check if it's a ModuleScript
    print(`🔍 [4/7] Verifying module type...`)
    if not modulePath:IsA("ModuleScript") then
        warn(`❌ ERROR: {name} is not a ModuleScript (found: {modulePath.ClassName})`)
        return nil
    end
    
    -- Require the module
    print(`📦 [5/7] Requiring module: {name}...`)
    print(`    Path: {modulePath:GetFullName()}`)
    local success, result = pcall(require, modulePath)
    
    if not success then
        warn(`❌ ERROR: Failed to require system {name}:`)
        warn(result)
        return nil
    end
    
    print(`✅ Successfully required module: {name}`)
    print(`📝 Module type: {type(result)}`)
    
    -- Check the result type
    print(`🔍 [6/7] Verifying module result type...`)
    if type(result) ~= "table" then
        warn(`❌ ERROR: {name} did not return a table (got: {type(result)})`)
        return nil
    end
    
    -- Check for required methods
    print("🔍 Checking for required methods...")
    if type(result.init) ~= "function" then
        warn(`⚠️ WARNING: {name} is missing init() method - adding default implementation`)
        result.init = function()
            print(`✅ {name} initialized (default implementation)`)
            return true
        end
    end
    
    -- Initialize the system
    print(`🔄 [7/7] Calling {name}:init()...`)
    print(`    Init function type: {type(result.init)}`)
    local initSuccess, initResult = pcall(function()
        return result.init(result)
    end)
    
    if not initSuccess then
        warn(`❌ ERROR: {name}:init() failed with error:`)
        warn(initResult)
        return nil
    end
    
    -- Verify initialization result
    if initResult == false then
        warn(`⚠️ WARNING: {name}:init() returned false, indicating initialization failure`)
        return nil
    end
    
    print(`✅ {name} initialized successfully`)
    return result
end

-- Check if MainModule is initialized
function MainModule:isInitialized()
    return initialized
end

-- Get a system by name
function MainModule:getSystem(systemName: string)
    return initializedSystems[systemName]
end

-- Get all initialized systems
function MainModule:getInitializedSystems()
    local result = {}
    for name, system in pairs(initializedSystems) do
        result[name] = system
    end
    return result
end

-- Initialize the MainModule
function MainModule:init()
    print("\n=== MainModule:init() started ===")
    
    if self:isInitialized() then
        warn("MainModule already initialized")
        return true
    end
    
    print("🚀 Initializing MainModule...")
    print("\n🔧 Starting system initialization...")
    
    -- Debug: Print systemsToLoad table
    print("📋 Systems to load (count: " .. #systemsToLoad .. "):")
    for i, name in ipairs(systemsToLoad) do
        print(string.format("  [%d] %s (type: %s)", i, tostring(name), type(name)))
    end
    
    -- Set up shared folders
    print("\n🛠️ Setting up shared folders...")
    local shared = Instance.new("Folder")
    shared.Name = "Shared"
    shared.Parent = ReplicatedStorage
    
    -- Use existing systems folder or create it if it doesn't exist
    print("\n📂 Locating systems folder...")
    local systemsFolder = ServerScriptService:FindFirstChild("systems")
    if not systemsFolder then
        print("ℹ️ 'systems' folder not found in ServerScriptService, creating...")
        systemsFolder = Instance.new("Folder")
        systemsFolder.Name = "systems"
        systemsFolder.Parent = ServerScriptService
    else
        print("✅ Found existing 'systems' folder")
    end
    
    -- List all modules in systems folder for debugging
    print("\n📦 Modules in systems folder:")
    local moduleCount = 0
    for _, child in ipairs(systemsFolder:GetChildren()) do
        print(string.format("  - %s (%s)", child.Name, child.ClassName))
        moduleCount += 1
    end
    print("  Total modules found:", moduleCount)
    
    -- Initialize all systems
    print("\n🔧 Initializing systems...")
    local successCount = 0
    local failCount = 0
    
    for i, systemName in ipairs(systemsToLoad) do
        print("\n" .. string.rep("=", 50))
        print(string.format("🔄 [%d/%d] Initializing system: %s", i, #systemsToLoad, systemName))
        
        -- Try to initialize the system
        local system = initializeSystem(systemName)
        
        if system then
            print(string.format("✅ Successfully initialized %s", systemName))
            initializedSystems[systemName] = system
            successCount += 1
            
            -- Verify the system was added to initializedSystems
            if initializedSystems[systemName] == system then
                print("  ✓ System reference stored in initializedSystems")
            else
                warn("  ❌ System reference NOT stored in initializedSystems!")
            end
        else
            print(string.format("❌ Failed to initialize %s", systemName))
            failCount += 1
            
            -- Try to find the module directly for more detailed error
            local moduleScript = systemsFolder:FindFirstChild(systemName)
            if moduleScript and moduleScript:IsA("ModuleScript") then
                print("🔍 Attempting direct require...")
                local success, result = pcall(require, moduleScript)
                if success then
                    print("✅ Direct require succeeded!")
                    print("   Module type:", type(result))
                    if type(result) == "table" then
                        print("   Has init function:", type(result.init) == "function")
                    end
                else
                    print(`❌ Direct require of {systemName} failed: {tostring(result)}`)
                end
            end
        end
    end
    
    -- Mark as initialized
    initialized = true
    print("\n✅ MainModule initialization complete")
    
    -- Connect player events
    game.Players.PlayerAdded:Connect(function(player)
        print(`Player {player.Name} joined the game`)
        
        -- Assign initial class
        local classSystem = self:getSystem("ClassSystem")
        if classSystem and type(classSystem.assignRandomClass) == "function" then
            classSystem.assignRandomClass(player)
        end
        
        -- Set up character
        local characterSystem = self:getSystem("CharacterSystem")
        if characterSystem and type(characterSystem.setupCharacter) == "function" then
            player.CharacterAdded:Connect(function(character)
                local class = player:FindFirstChild("PlayerClass")
                if class then
                    characterSystem.setupCharacter(player, class.Value)
                end
            end)
        end
    end)
    
    return true
end

-- Return the MainModule
return MainModule
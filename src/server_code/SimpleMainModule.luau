--!strict
-- Simplified MainModule for testing

print("=== Loading SimpleMainModule ===")

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Module interface
local SimpleMainModule = {}
SimpleMainModule.__index = SimpleMainModule

-- State
local initialized = false
local initializedSystems = {}

-- List of systems to load (simplified for testing)
local systemsToLoad = {"TestSystem1", "TestSystem2"}

-- Initialize a single system (simplified)
local function initializeSystem(name: string): any
    print("🔍 Initializing system: " .. name)
    
    -- Simulate a system module
    local system = {
        name = name,
        init = function()
            print("✅ " .. name .. " initialized")
            return true
        end
    }
    
    -- Initialize the system
    local success, result = pcall(system.init)
    if not success then
        warn("❌ " .. name .. " initialization failed: " .. tostring(result))
        return nil
    end
    
    return system
end

-- Check if MainModule is initialized
function SimpleMainModule:isInitialized(): boolean
    return initialized
end

-- Get a system by name
function SimpleMainModule:getSystem(systemName: string): any?
    return initializedSystems[systemName]
end

-- Get all initialized systems
function SimpleMainModule:getInitializedSystems(): {[string]: any}
    local result = {}
    for name, system in pairs(initializedSystems) do
        result[name] = system
    end
    return result
end

-- Initialize the MainModule
function SimpleMainModule:init(): boolean
    print("\n=== SimpleMainModule:init() started ===")
    
    if self:isInitialized() then
        warn("SimpleMainModule already initialized")
        return true
    end
    
    print("🚀 Initializing SimpleMainModule...")
    
    -- Initialize all systems
    print("\n🔧 Initializing systems...")
    for _, systemName in ipairs(systemsToLoad) do
        local system = initializeSystem(systemName)
        if system then
            initializedSystems[systemName] = system
            print("✅ Successfully initialized system: " .. systemName)
        else
            warn("❌ Failed to initialize system: " .. systemName)
        end
    end
    
    -- Mark as initialized
    initialized = true
    
    -- Print summary
    print("\n=== Initialization Summary ===")
    local count = 0
    for _ in pairs(initializedSystems) do count += 1 end
    print(string.format("Successfully initialized %d/%d systems", count, #systemsToLoad))
    
    print("\n✅ SimpleMainModule initialization complete")
    return true
end

-- Create a new instance
local function new()
    return setmetatable({}, SimpleMainModule)
end

-- Return the module
return {
    new = new,
    isInitialized = SimpleMainModule.isInitialized,
    getSystem = SimpleMainModule.getSystem,
    getInitializedSystems = SimpleMainModule.getInitializedSystems,
    init = SimpleMainModule.init
}

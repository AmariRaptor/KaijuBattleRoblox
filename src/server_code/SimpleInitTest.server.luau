--!strict

-- This is a simplified test to isolate the initialization issue
local ServerScriptService = game:GetService("ServerScriptService")

print("\n=== Simple Initialization Test ===\n")

-- 1. Create a simple module with similar structure to MainModule
local SimpleModule = {}
SimpleModule.__index = SimpleModule

-- Private state
local initialized = false
local initializedSystems = {}

-- Public methods
function SimpleModule:getInitializedSystems()
    local result = {}
    for name, system in pairs(initializedSystems) do
        result[name] = system
    end
    return result
end

function SimpleModule:isInitialized()
    return initialized
end

function SimpleModule:getSystem(name)
    return initializedSystems[name]
end

function SimpleModule:init()
    if self:isInitialized() then
        print("⚠️ Already initialized")
        return true
    end
    
    print("Initializing SimpleModule...")
    
    -- Simulate adding a system
    initializedSystems["TestSystem"] = {
        name = "TestSystem",
        init = function() return true end
    }
    
    initialized = true
    print("✅ SimpleModule initialized successfully")
    
    -- Verify the system was added
    print("\n=== Verification ===")
    print("Number of systems in initializedSystems:", #initializedSystems)
    print("Systems in initializedSystems:")
    for name, _ in pairs(initializedSystems) do
        print("  - " .. name)
    end
    
    return true
end

-- 2. Test the module
print("=== Testing SimpleModule ===")
local instance = {}
setmetatable(instance, SimpleModule)

print("Before init:")
print("- isInitialized:", instance:isInitialized())
print("- initializedSystems count:", #instance:getInitializedSystems())

print("\nCalling init()...")
local success, result = pcall(instance.init, instance)
if not success then
    warn("❌ Init failed:", result)
else
    print("✅ Init result:", result)
end

print("\nAfter init:")
print("- isInitialized:", instance:isInitialized())
local systems = instance:getInitializedSystems()
print("- initializedSystems count:", #systems)
print("- Systems:")
for name, _ in pairs(systems) do
    print("  - " .. name)
end

-- 3. Now test with the actual MainModule
print("\n=== Testing MainModule ===")
local mainModule = ServerScriptService:FindFirstChild("MainModule")
if not mainModule or not mainModule:IsA("ModuleScript") then
    warn("❌ MainModule not found in ServerScriptService")
    return
end

print("✅ Found MainModule")

-- Require MainModule
local success, module = pcall(require, mainModule)
if not success then
    warn("❌ Failed to require MainModule:")
    warn(module)
    return
end

print("✅ Successfully required MainModule")

-- Check if we can access initializedSystems directly
print("\n=== Checking MainModule State ===")
print("Module type:", typeof(module))
print("Has metatable:", getmetatable(module) ~= nil)

-- Try to get initialized systems before init
print("\nBefore init:")
print("- isInitialized:", module:isInitialized())
local systemsBefore = module:getInitializedSystems()
print("- initializedSystems count:", #systemsBefore)

-- Initialize MainModule
print("\nInitializing MainModule...")
local initSuccess, initResult = pcall(module.init, module)
if not initSuccess then
    warn("❌ MainModule:init() failed:")
    warn(initResult)
    return
end

print("✅ MainModule:init() completed successfully")

-- Check after init
print("\nAfter init:")
print("- isInitialized:", module:isInitialized())
local systemsAfter = module:getInitializedSystems()
print("- initializedSystems count:", #systemsAfter)
print("- Systems:")
for name, _ in pairs(systemsAfter) do
    print("  - " .. name)
end

print("\n=== Test Complete ===")

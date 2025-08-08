--!strict

-- This script tests the MainModule's table behavior
local ServerScriptService = game:GetService("ServerScriptService")

print("\n=== Testing MainModule Table Behavior ===\n")

-- 1. Create a test module that mimics MainModule's structure
local testModule = {}
testModule.__index = testModule

-- State
local initialized = false
local initializedSystems = {}

-- Method to get initialized systems
function testModule:getInitializedSystems()
    local result = {}
    for name, system in pairs(initializedSystems) do
        result[name] = system
    end
    return result
end

-- Method to check if initialized
function testModule:isInitialized()
    return initialized
end

-- Method to get a system
function testModule:getSystem(name)
    return initializedSystems[name]
end

-- Initialize method
function testModule:init()
    if self:isInitialized() then
        warn("Test module already initialized")
        return true
    end
    
    print("Initializing test module...")
    
    -- Simulate adding a system
    initializedSystems["TestSystem"] = {
        name = "TestSystem",
        init = function() return true end
    }
    
    initialized = true
    print("Test module initialized successfully")
    return true
end

-- 2. Create an instance of our test module
local instance = {}
setmetatable(instance, testModule)

-- 3. Test the instance
print("=== Testing Instance ===")
print("Before init:")
print("- isInitialized:", instance:isInitialized())
print("- initializedSystems count:", #instance:getInitializedSystems())

print("\nCalling init()...")
local success, result = pcall(instance.init, instance)
if not success then
    warn("Init failed:", result)
else
    print("Init result:", result)
end

print("\nAfter init:")
print("- isInitialized:", instance:isInitialized())
local systems = instance:getInitializedSystems()
print("- initializedSystems count:", #systems)
print("- Systems:")
for name, _ in pairs(systems) do
    print("  - " .. name)
end

-- 4. Now test with the actual MainModule
print("\n=== Testing Actual MainModule ===")
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

-- Try to access initializedSystems directly (if possible)
print("\n=== Debug: Direct Table Access ===")
for k, v in pairs(module) do
    if k == "initializedSystems" then
        print("Found initializedSystems in module table")
        print("Type:", typeof(v))
        if type(v) == "table" then
            print("Contents:")
            for sysName, _ in pairs(v) do
                print("  - " .. tostring(sysName))  -- Convert to string in case sysName is not a string
            end
        end
    end
end

print("\n=== Test Complete ===")

--!strict
-- Test script for SimpleMainModule

print("=== Starting SimpleMainModule Test ===\n")

-- 1. Require the SimpleMainModule
print("1. Requiring SimpleMainModule...")
local SimpleMainModule = require(script.Parent:WaitForChild("SimpleMainModule"))

-- 2. Create a new instance
print("\n2. Creating new SimpleMainModule instance...")
local mainModule = SimpleMainModule.new()
print("   Instance created successfully")

-- 3. Check initial state
print("\n3. Checking initial state...")
print("   isInitialized(): " .. tostring(mainModule:isInitialized()))
print("   Initialized systems count: " .. #mainModule:getInitializedSystems())

-- 4. Initialize the module
print("\n4. Initializing SimpleMainModule...")
local success, result = pcall(function()
    return mainModule:init()
end)

if not success then
    warn("❌ Initialization failed:")
    warn(result)
    return
end

print("✅ Initialization completed successfully")

-- 5. Check post-init state
print("\n5. Checking post-initialization state...")
print("   isInitialized(): " .. tostring(mainModule:isInitialized()))

local systems = mainModule:getInitializedSystems()
local systemCount = 0
for _ in pairs(systems) do systemCount += 1 end

print("   Initialized systems count: " .. systemCount)
if systemCount > 0 then
    print("   Systems:")
    for name, _ in pairs(systems) do
        print("   - " .. name)
    end
end

-- 6. Test getting a system
print("\n6. Testing getSystem()...")
local testSystem = mainModule:getSystem("TestSystem1")
print("   getSystem(\"TestSystem1\"): " .. (testSystem and "✅ Found" or "❌ Not found"))

-- 7. Test re-initialization
print("\n7. Testing re-initialization...")
local reinitSuccess, reinitResult = pcall(mainModule.init, mainModule)
print("   Re-initialization result: " .. (reinitSuccess and "✅ Success" or "❌ Failed"))
if not reinitSuccess then
    print("   Error: " .. tostring(reinitResult))
end

print("\n=== SimpleMainModule Test Complete ===\n")

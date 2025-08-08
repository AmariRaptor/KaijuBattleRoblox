--!strict

-- Test script for FixedMainModule
local ServerScriptService = game:GetService("ServerScriptService")

print("\n=== Testing FixedMainModule ===\n")

-- 1. Get the FixedMainModule
local fixedModule = script.Parent:FindFirstChild("FixedMainModule")
if not fixedModule or not fixedModule:IsA("ModuleScript") then
    warn("❌ FixedMainModule not found")
    return
end

print("✅ Found FixedMainModule")

-- 2. Require the module
local success, module = pcall(require, fixedModule)
if not success then
    warn("❌ Failed to require FixedMainModule:")
    warn(module)
    return
end

print("✅ Successfully required FixedMainModule")

-- 3. Create an instance
print("\nCreating FixedMainModule instance...")
local instance = module.new()
print("Instance created:", tostring(instance))

-- 4. Check initial state
print("\n=== Initial State ===")
print("isInitialized():", instance:isInitialized())
local initialSystems = instance:getInitializedSystems()
print("Initialized systems count:", #initialSystems)

-- 5. Initialize the module
print("\n=== Initializing FixedMainModule ===")
local initSuccess, initResult = pcall(instance.init, instance)
if not initSuccess then
    warn("❌ FixedMainModule:init() failed:")
    warn(initResult)
    return
end

print("✅ FixedMainModule:init() completed successfully")

-- 6. Check post-init state
print("\n=== Post-Initialization State ===")
print("isInitialized():", instance:isInitialized())

-- 7. Check initialized systems
local systems = instance:getInitializedSystems()
print("Initialized systems count:", #systems)
print("Systems:")
for name, _ in pairs(systems) do
    print("  - " .. name)
end

-- 8. Test getting a specific system
print("\n=== Testing System Access ===")
local classSystem = instance:getSystem("ClassSystem")
print("ClassSystem:", classSystem and "✅ Found" or "❌ Not found")

if classSystem then
    print("ClassSystem methods:")
    for k, v in pairs(classSystem) do
        if type(v) == "function" then
            print("  - " .. k)
        end
    end
end

-- 9. Test re-initialization
print("\n=== Testing Re-initialization ===")
local reinitSuccess, reinitResult = pcall(instance.init, instance)
print("Re-initialization result:", reinitSuccess and "✅ Success" or "❌ Failed")
if not reinitSuccess then
    warn(reinitResult)
end

print("\n=== Test Complete ===")

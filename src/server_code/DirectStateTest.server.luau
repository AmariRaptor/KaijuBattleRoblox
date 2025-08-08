--!strict

-- Direct test of MainModule's state management
local ServerScriptService = game:GetService("ServerScriptService")

print("\n=== Direct State Test ===\n")

-- 1. Get the MainModule
local mainModule = ServerScriptService:FindFirstChild("MainModule")
if not mainModule or not mainModule:IsA("ModuleScript") then
    warn("❌ MainModule not found in ServerScriptService")
    return
end

print("✅ Found MainModule")

-- 2. Require the MainModule
local success, module = pcall(require, mainModule)
if not success then
    warn("❌ Failed to require MainModule:")
    warn(module)
    return
end

print("✅ Successfully required MainModule")

-- 3. Check the module's metatable
local meta = getmetatable(module)
print("\n=== Metatable Info ===")
print("Has metatable:", meta ~= nil)
if meta then
    print("Metatable __index:", tostring(meta.__index))
    print("Metatable type:", typeof(meta.__index))
end

-- 4. Check module's initial state
print("\n=== Initial State ===")
print("isInitialized():", module:isInitialized())
print("getInitializedSystems() count:", #module:getInitializedSystems())

-- 5. Try to access private state directly (for debugging)
print("\n=== Direct State Access ===")
print("Module keys:")
for k, v in pairs(module) do
    print(string.format("  %s: %s (%s)", tostring(k), tostring(v), typeof(v)))
end

-- 6. Initialize the module
print("\n=== Initializing MainModule ===")
local initSuccess, initResult = pcall(module.init, module)
if not initSuccess then
    warn("❌ MainModule:init() failed:")
    warn(initResult)
    return
end

print("✅ MainModule:init() completed successfully")

-- 7. Check state after initialization
print("\n=== Post-Initialization State ===")
print("isInitialized():", module:isInitialized())

-- 8. Check initialized systems
local systems = module:getInitializedSystems()
print("Initialized systems count:", #systems)
print("Systems:")
for name, _ in pairs(systems) do
    print("  - " .. tostring(name))
end

-- 9. Try to access private state again
print("\n=== Post-Init Direct State Access ===")
print("Module keys:")
local hasInitializedSystems = false
for k, v in pairs(module) do
    print(string.format("  %s: %s (%s)", tostring(k), tostring(v), typeof(v)))
    if k == "initializedSystems" then
        hasInitializedSystems = true
        print("  ^ Found initializedSystems!")
        if type(v) == "table" then
            print("  Contents:")
            for sysName, _ in pairs(v) do
                print("    - " .. tostring(sysName))
            end
        end
    end
end

if not hasInitializedSystems then
    print("  ❌ initializedSystems not found in module table")
end

-- 10. Try to get a specific system
print("\n=== System Access ===")
local classSystem = module:getSystem("ClassSystem")
print("ClassSystem:", classSystem and "✅ Found" or "❌ Not found")

print("\n=== Test Complete ===")

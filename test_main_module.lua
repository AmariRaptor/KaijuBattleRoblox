local ServerScriptService = game:GetService("ServerScriptService")
local MainModule = require(ServerScriptService:WaitForChild("MainModule"))

-- Initialize MainModule
print("=== Initializing MainModule ===")
local success, result = pcall(function()
    return MainModule:init()
end)

if not success then
    warn("❌ MainModule:init() failed:", result)
    return
end

print("✅ MainModule initialized successfully")

-- Test isInitialized
print("\n=== Testing isInitialized() ===")
print("isInitialized:", MainModule:isInitialized())

-- Test getSystem
print("\n=== Testing getSystem() ===")
local classSystem = MainModule:getSystem("ClassSystem")
print("ClassSystem found:", classSystem ~= nil)

-- Test getInitializedSystems
print("\n=== Testing getInitializedSystems() ===")
local systems = MainModule:getInitializedSystems()
print("Initialized Systems:")
for name, _ in pairs(systems) do
    print("-", name)
end

print("\n=== Test Complete ===")

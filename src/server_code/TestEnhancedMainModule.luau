--!strict
-- TestEnhancedMainModule.luau
-- Test script for the enhanced MainModule

local ServerScriptService = game:GetService("ServerScriptService")

-- Load the enhanced MainModule
local success, MainModule = pcall(function()
    return require(script.Parent.EnhancedMainModule)
end)

if not success then
    warn("❌ Failed to load EnhancedMainModule:")
    warn(MainModule)
    return
end

print("✅ Successfully loaded EnhancedMainModule")

-- Configure logger level (TRACE, DEBUG, INFO, WARN, ERROR, FATAL)
MainModule.logger:setLevel(MainModule.logger.levels.DEBUG)

-- Test initialization
print("\n=== Testing Initialization ===")
local initSuccess, initError = MainModule:init()
if not initSuccess then
    warn("❌ Initialization failed:", initError)
    return
end

print("✅ Initialization successful")

-- Test system retrieval
print("\n=== Testing System Retrieval ===")
for _, systemName in ipairs({"ClassSystem", "CharacterSystem", "BuildingSystem", "KaijuSystem", "ScoringSystem"}) do
    local system = MainModule:getSystem(systemName)
    if system then
        print(string.format("✅ Found system: %s", systemName))
    else
        warn(string.format("❌ System not found: %s", systemName))
    end
end

-- Test system status
print("\n=== System Status ===")
local allStatuses = MainModule:getAllSystemStatuses()
for name, status in pairs(allStatuses) do
    local statusSymbol = status.initialized and "✅" or "❌"
    print(string.format("%s %-15s - Loaded: %-5s | Initialized: %-5s | Started: %-5s | Error: %s",
        statusSymbol,
        name,
        tostring(status.loaded),
        tostring(status.initialized),
        tostring(status.started),
        status.error or "None"
    ))
end

-- Test verification
print("\n=== System Verification ===")
local allValid, errors = MainModule:verifySystems()
if allValid then
    print("✅ All systems are valid")
else
    warn("❌ Some systems have issues:")
    for sysName, err in pairs(errors or {}) do
        warn(string.format("  - %s: %s", sysName, tostring(err)))
    end
end

print("\n=== Test Complete ===")

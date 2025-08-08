--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- List of systems to test
local systemsToTest = {
    "ClassSystem",
    "CharacterSystem",
    "BuildingSystem",
    "KaijuSystem",
    "ScoringSystem"
}

print("=== System Initialization Test ===\n")

-- Function to test loading a single system
local function testSystemLoad(systemName: string): boolean
    print(string.format("🔍 Testing system: %s", systemName))
    
    -- Find the system module
    local systemsFolder = ServerScriptService:FindFirstChild("systems")
    if not systemsFolder then
        warn("❌ Systems folder not found in ServerScriptService")
        return false
    end
    
    local moduleScript = systemsFolder:FindFirstChild(systemName)
    if not moduleScript or not moduleScript:IsA("ModuleScript") then
        warn(string.format("❌ %s not found or is not a ModuleScript", systemName))
        return false
    end
    
    -- Require the module
    local success, module = pcall(require, moduleScript)
    if not success then
        warn(string.format("❌ Failed to require %s:", systemName))
        warn(module)
        return false
    end
    
    -- Check if the module has an init function
    if type(module.init) ~= "function" then
        warn(string.format("⚠️ %s does not have an init function", systemName))
        return false
    end
    
    -- Try to initialize the system
    local initSuccess, result = pcall(module.init, module)
    if not initSuccess then
        warn(string.format("❌ %s:init() failed:", systemName))
        warn(result)
        return false
    end
    
    print(string.format("✅ %s initialized successfully", systemName))
    return true
end

-- Test all systems
local allPassed = true
for _, systemName in ipairs(systemsToTest) do
    if not testSystemLoad(systemName) then
        allPassed = false
    end
    print("")
end

-- Print final result
print("\n=== Test Results ===")
if allPassed then
    print("✅ All systems initialized successfully")
else
    warn("❌ Some systems failed to initialize")
end

return allPassed

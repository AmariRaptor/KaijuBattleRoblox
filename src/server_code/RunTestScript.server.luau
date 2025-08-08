--!strict

-- This script will be automatically run when the game starts
local ServerScriptService = game:GetService("ServerScriptService")

-- Find the test script
local testScript = script.Parent:FindFirstChild("TestMainModuleInit")
if not testScript or not testScript:IsA("ModuleScript") then
    warn("❌ TestMainModuleInit script not found")
    return
end

print("\n=== Running TestMainModuleInit ===\n")

-- Run the test script
local success, result = pcall(require, testScript)
if not success then
    warn("❌ Test script failed:")
    warn(result)
else
    print("\n✅ Test script completed successfully")
end

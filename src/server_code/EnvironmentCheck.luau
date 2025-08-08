-- EnvironmentCheck.luau
-- A simple script to check the execution environment

print("=== Environment Check ===")

-- Basic environment info
print("_VERSION: " .. tostring(_VERSION))
print("os.time(): " .. tostring(os.time()))

-- Check for Roblox globals
local function checkGlobal(name)
    local value = _G[name]
    print(string.format("%-15s: %s (%s)", name, 
        tostring(value ~= nil),
        type(value)))
end

-- Check important globals
print("\nGlobal Variables:")
checkGlobal("game")
checkGlobal("workspace")
checkGlobal("script")
checkGlobal("require")
checkGlobal("print")
checkGlobal("warn")
checkGlobal("error")

-- Try to access services
local function checkService(name)
    local success, service = pcall(function()
        return game:GetService(name)
    end)
    print(string.format("%-15s: %s", 
        name, 
        success and "✅ Available" or "❌ Not available"))
end

print("\nServices:")
checkService("ServerScriptService")
checkService("ReplicatedStorage")
checkService("Workspace")
checkService("Players")
checkService("TestService")

-- Check if we can list ServerScriptService contents
print("\nServerScriptService Contents:")
local success, sss = pcall(function() return game:GetService("ServerScriptService") end)
if success and sss then
    local children = sss:GetChildren()
    if #children == 0 then
        print("  (empty)")
    else
        for _, child in ipairs(children) do
            print(string.format("  - %s (%s)", child.Name, child.ClassName))
        end
    end
else
    print("  Could not access ServerScriptService")
end

print("\n=== Environment Check Complete ===")

return true, "Environment check completed successfully"

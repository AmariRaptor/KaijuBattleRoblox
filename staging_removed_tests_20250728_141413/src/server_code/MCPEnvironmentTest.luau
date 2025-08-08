--!strict
-- MCPEnvironmentTest.luau
-- A minimal script to test the MCP environment

local function runTest()
    print("=== Starting MCP Environment Test ===\n")
    
    -- Test 1: Basic output
    print("🔹 Test 1: Basic output - This should appear in the console")
    
    -- Test 2: Environment information
    print("\n🔹 Test 2: Environment Information")
    print("_VERSION: " .. tostring(_VERSION))
    print("typeof(game): " .. tostring(type(game)))
    print("typeof(script): " .. tostring(type(script)))
    
    -- Test 3: Access to game services
    print("\n🔹 Test 3: Game Services")
    local services = {
        "ServerScriptService",
        "ReplicatedStorage",
        "Workspace"
    }
    
    for _, serviceName in ipairs(services) do
        local success, service = pcall(game.GetService, game, serviceName)
        print(string.format("%s: %s", 
            serviceName, 
            success and "✅ Available" or "❌ Not available: " .. tostring(service)))
    end
    
    -- Test 4: File system access
    print("\n🔹 Test 4: File System Access")
    local fsSuccess, fsError = pcall(function()
        return readfile and "✅ Available" or "❌ Not available"
    end)
    print("readfile: " .. (fsSuccess and fsError or "❌ Error: " .. tostring(fsError)))
    
    -- Test 5: Module loading
    print("\n🔹 Test 5: Module Loading")
    if script.Parent and script.Parent:FindFirstChild("systems") then
        print("Systems folder found. Checking for system modules...")
        local systems = script.Parent.systems:GetChildren()
        for _, module in ipairs(systems) do
            if module:IsA("ModuleScript") then
                local success, result = pcall(require, module)
                print(string.format("%s: %s", 
                    module.Name, 
                    success and "✅ Loaded successfully" or "❌ Failed to load: " .. tostring(result)))
            end
        end
    else
        print("❌ Systems folder not found or not accessible")
    end
    
    print("\n=== MCP Environment Test Complete ===")
    return true
end

-- Run the test
local success, result = pcall(runTest)
if not success then
    warn("❌ Test failed: " .. tostring(result))
    return false, "Test failed: " .. tostring(result)
end

return result

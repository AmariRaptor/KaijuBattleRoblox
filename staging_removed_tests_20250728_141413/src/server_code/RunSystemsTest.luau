--!strict
-- RunSystemsTest.luau
-- Simple test script to verify system initialization in Roblox Studio

local function testSystem(systemName: string, systemModule: any): (boolean, string?)
    print("\n🔍 Testing system: " .. systemName)
    
    -- Check if the system exists
    if systemModule == nil then
        warn("❌ " .. systemName .. " module is nil")
        return false, "Module is nil"
    end
    
    -- Check if the system is a table
    if type(systemModule) ~= "table" then
        warn("❌ " .. systemName .. " is not a table (got " .. type(systemModule) .. ")")
        return false, "Not a table (got " .. type(systemModule) .. ")"
    end
    
    -- Check for init method
    if type(systemModule.init) ~= "function" then
        warn("❌ " .. systemName .. " is missing init method")
        return false, "Missing init method"
    end
    
    -- Try to initialize the system
    local initSuccess, initResult = pcall(systemModule.init, systemModule)
    if not initSuccess then
        warn("❌ " .. systemName .. " init failed: " .. tostring(initResult))
        return false, "Init failed: " .. tostring(initResult)
    end
    
    print("✅ " .. systemName .. " initialized successfully")
    return true, "Success"
end

-- Main test function
local function runTests()
    print("\n🚀 Starting System Tests in Roblox Studio...\n")
    
    -- Get the systems folder
    local systemsFolder = script.Parent and script.Parent:FindFirstChild("systems")
    if not systemsFolder then
        warn("❌ Systems folder not found!")
        return false, "Systems folder not found"
    end
    
    -- List of systems to test
    local systemsToTest = {
        "ClassSystem",
        "CharacterSystem",
        "BuildingSystem",
        "KaijuSystem",
        "ScoringSystem"
    }
    
    -- Run tests
    local passed = 0
    local total = #systemsToTest
    local results = {}
    
    for _, systemName in ipairs(systemsToTest) do
        -- Try to find and require the module
        local moduleScript = systemsFolder:FindFirstChild(systemName)
        if not moduleScript then
            warn("❌ " .. systemName .. " module not found in systems folder")
            results[systemName] = {success = false, message = "Module not found"}
        else
            local success, system = pcall(require, moduleScript)
            if not success then
                warn("❌ Failed to require " .. systemName .. ": " .. tostring(system))
                results[systemName] = {success = false, message = "Require failed: " .. tostring(system)}
            else
                -- Test the system
                local testSuccess, testMessage = testSystem(systemName, system)
                results[systemName] = {success = testSuccess, message = testMessage}
                if testSuccess then
                    passed = passed + 1
                end
            end
        end
    end
    
    -- Print detailed results
    print("\n📊 Test Results:")
    for systemName, result in pairs(results) do
        local status = result.success and "✅" or "❌"
        print(string.format("%s %s: %s", status, systemName, result.message))
    end
    
    print("\n📈 Summary:")
    print(string.format("✅ %d/%d tests passed", passed, total))
    print(string.format("📉 %.0f%% success rate", (passed / total) * 100))
    
    return passed == total, results
end

-- Run the tests
print("=== Starting System Tests ===")
local success, result = pcall(runTests)

if not success then
    warn("❌ Test runner encountered an error: " .. tostring(result))
    return false, "Test runner error: " .. tostring(result)
end

print("=== Test Execution Complete ===")
return result

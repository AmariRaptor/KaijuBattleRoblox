--!strict
-- TestAllSystems.luau
-- Simple script to test all systems in Roblox Studio

local function testSystem(systemName: string, systemModule: ModuleScript): (boolean, string?)
    print("\n🔍 Testing system: " .. systemName)
    
    -- Try to require the module
    local success, system = pcall(require, systemModule)
    if not success then
        warn("❌ Failed to load " .. systemName .. ": " .. tostring(system))
        return false, "Load failed"
    end
    
    -- Check if the system has an init method
    if type(system) ~= "table" then
        warn("❌ " .. systemName .. " is not a table")
        return false, "Not a table"
    end
    
    if type(system.init) ~= "function" then
        warn("❌ " .. systemName .. " is missing init method")
        return false, "Missing init method"
    end
    
    -- Try to initialize the system
    local initSuccess, initResult = pcall(system.init, system)
    if not initSuccess then
        warn("❌ " .. systemName .. " init failed: " .. tostring(initResult))
        return false, "Init failed"
    end
    
    print("✅ " .. systemName .. " initialized successfully")
    return true, "Success"
end

-- Main test function
local function runTests()
    print("\n🚀 Starting System Tests in Roblox Studio...\n")
    
    -- Get the script's parent (should be ServerScriptService)
    local serverScriptService = script.Parent
    if not serverScriptService then
        warn("❌ Script must be a child of ServerScriptService!")
        return false
    end
    
    -- Find the systems folder
    local systemsFolder = serverScriptService:FindFirstChild("systems")
    if not systemsFolder then
        warn("❌ Systems folder not found in ServerScriptService!")
        return false
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
    
    for _, systemName in ipairs(systemsToTest) do
        local systemModule = systemsFolder:FindFirstChild(systemName)
        if not systemModule then
            warn("❌ " .. systemName .. " module not found!")
        else
            local success, _ = testSystem(systemName, systemModule)
            if success then
                passed = passed + 1
            end
        end
    end
    
    -- Print summary
    print("\n📊 Test Results:")
    print(string.format("✅ %d/%d tests passed", passed, total))
    print(string.format("📈 %.0f%% success rate", (passed / total) * 100))
    
    return passed == total
end

-- Run the tests
local success, result = pcall(runTests)
if not success then
    warn("❌ Test runner encountered an error: " .. tostring(result))
end

return success and result

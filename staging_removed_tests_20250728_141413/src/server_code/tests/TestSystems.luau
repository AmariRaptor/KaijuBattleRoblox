--!strict
-- TestSystems.luau
-- Simple test script to verify system initialization in Roblox Studio

local function runTests()
    print("\n🔍 Starting System Tests...")
    
    -- Helper function to test a single system
    local function testSystem(systemName: string): boolean
        print("\nTesting system: " .. systemName)
        
        -- Try to find the system module
        local systemsFolder = script.Parent.Parent:FindFirstChild("systems")
        if not systemsFolder then
            warn("❌ Systems folder not found!")
            return false
        end
        
        local systemModule = systemsFolder:FindFirstChild(systemName)
        if not systemModule then
            warn("❌ " .. systemName .. " module not found!")
            return false
        end
        
        -- Try to require the module
        local success, system = pcall(require, systemModule)
        if not success then
            warn("❌ Failed to load " .. systemName .. ": " .. tostring(system))
            return false
        end
        
        -- Check if the system has an init method
        if type(system) == "table" and type(system.init) == "function" then
            print("✅ " .. systemName .. " loaded successfully")
            
            -- Try to call init if it exists
            local initSuccess, initResult = pcall(system.init, system)
            if initSuccess then
                print("✅ " .. systemName .. " initialized successfully")
                return true
            else
                warn("❌ " .. systemName .. " init failed: " .. tostring(initResult))
                return false
            end
        else
            warn("❌ " .. systemName .. " is missing init method")
            return false
        end
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
        if testSystem(systemName) then
            passed = passed + 1
        end
    end
    
    -- Print summary
    print("\n📊 Test Results:")
    print(string.format("✅ %d/%d tests passed", passed, total))
    print(string.format("📈 %.0f%% success rate", (passed / total) * 100))
    
    return passed == total
end

-- Run tests
return runTests()

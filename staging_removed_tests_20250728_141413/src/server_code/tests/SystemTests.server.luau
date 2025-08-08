--!strict
-- SystemTests.server.luau
-- Test script to verify system initialization and basic functionality

-- Helper to safely get services
local function getService(name: string): Instance?
    local success, service = pcall(function()
        return game:GetService(name)
    end)
    return if success then service else nil
end

-- Try to get services, but don't fail if they don't exist
local ServerScriptService = getService("ServerScriptService") or {
    Name = "ServerScriptService",
    FindFirstChild = function(_self: any, name: string): Instance?
        return nil
    end
}

local _TestService = getService("TestService") -- Unused for now

-- Test runner
local function runTests()
    print("\n🚀 Starting System Tests...\n")
    
    -- Track test results
    local passed = 0
    local failed = 0
    
    -- Helper function to run a test
    local function test(name: string, testFunc: () -> (boolean, string?))
        local success, result = pcall(testFunc)
        local message: string = ""
        
        if not success then
            -- Test function threw an error
            message = tostring(result)
            success = false
        else
            -- Test function returned values
            local testResult = result
            if type(testResult) == "boolean" then
                success = testResult
                message = ""
            else
                success, message = table.unpack(testResult)
            end
        end
        
        if success then
            print("✅ [PASS] " .. name)
            passed += 1
        else
            print("❌ [FAIL] " .. name .. (message ~= "" and (" - " .. message) or ""))
            failed += 1
        end
    end
    
    -- Test 1: Verify systems folder exists
    test("Systems folder exists", function()
        local systems = ServerScriptService and ServerScriptService:FindFirstChild("systems")
        return systems ~= nil, "Systems folder not found in ServerScriptService"
    end)
    
    -- Test 2: Verify all required systems exist
    local requiredSystems = {
        "ClassSystem",
        "CharacterSystem",
        "BuildingSystem",
        "KaijuSystem",
        "ScoringSystem"
    }
    
    -- Find the systems folder in a more flexible way
    local systemsFolder = nil
    if ServerScriptService then
        systemsFolder = ServerScriptService:FindFirstChild("systems")
    end
    
    if not systemsFolder and script.Parent and script.Parent.Parent then
        -- Try to find systems folder relative to the test script
        systemsFolder = script.Parent.Parent:FindFirstChild("systems")
    end
    
    if systemsFolder then
        for _, systemName in ipairs(requiredSystems) do
            test("System exists: " .. systemName, function()
                local systemModule = systemsFolder:FindFirstChild(systemName)
                if not systemModule then
                    return false, systemName .. " module not found"
                end
                
                local success, system = pcall(require, systemModule)
                if not success then
                    return false, systemName .. " failed to load: " .. tostring(system)
                end
                
                return system ~= nil, systemName .. " loaded successfully"
            end)
        end
        
        -- Test 3: Verify Main script exists and runs
        local mainScript = ServerScriptService and ServerScriptService:FindFirstChild("Main")
        if mainScript then
            test("Main script initializes", function()
                local success, result = pcall(require, mainScript)
                if not success then
                    return false, "Failed to run Main script: " .. tostring(result)
                end
                return true
            end)
        else
            print("⚠️  Main script not found, skipping initialization test")
        end
    else
        print("⚠️  Systems folder not found, skipping system tests")
    end
    
    -- Print summary
    print("\n📊 Test Results:")
    print(string.format("✅ %d tests passed", passed))
    print(string.format("❌ %d tests failed", failed))
    
    local totalTests = passed + failed
    if totalTests > 0 then
        print(string.format("📈 %.0f%% success rate", (passed / totalTests) * 100))
    end
    
    return passed, failed
end

-- Run tests and return results
local passed, failed = runTests()
return passed, failed

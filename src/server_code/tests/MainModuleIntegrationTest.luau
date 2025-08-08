--!strict
-- MainModuleIntegrationTest.luau
-- Integration test for MainModule functionality

local TestService = game:GetService("TestService")

local function runTest()
    print("🚀 Starting MainModule Integration Test...")
    
    -- Load MainModule
    local MainModule = require(game:GetService("ServerScriptService").MainModule)
    
    -- Test 1: Verify initialization
    print("\n🧪 Test 1: Initialization")
    local success, err = MainModule.init()
    if not success then
        warn("❌ Initialization failed:", err)
        return false
    end
    print("✅ MainModule initialized successfully")
    
    -- Test 2: Verify configuration
    print("\n🧪 Test 2: Configuration")
    local config = MainModule.getConfig()
    print("- Debug mode:", config.debug)
    print("- Max players:", config.maxPlayers)
    print("- Default volume:", config.defaultSettings.volume)
    print("- Difficulty:", config.defaultSettings.difficulty)
    
    -- Test 3: Event System
    print("\n🧪 Test 3: Event System")
    local eventReceived = false
    local testMessage = "Test event message"
    
    local unregister = MainModule.on("testEvent", function(message)
        print("📢 Event received:", message)
        eventReceived = (message == testMessage)
    end)
    
    MainModule.emit("testEvent", testMessage)
    
    task.wait(0.5) -- Allow time for event to be processed
    
    if not eventReceived then
        warn("❌ Event system test failed")
        return false
    end
    print("✅ Event system working correctly")
    
    -- Test 4: System Registration
    print("\n🧪 Test 4: System Registration")
    local testSystem = {
        name = "TestSystem",
        init = function() return true end
    }
    
    local registerSuccess = MainModule.registerSystem("TestSystem", testSystem)
    if not registerSuccess then
        warn("❌ System registration failed")
        return false
    end
    print("✅ System registered successfully")
    
    -- Test 5: Retrieve Registered System
    local retrievedSystem = MainModule.getSystem("TestSystem")
    if not retrievedSystem or retrievedSystem ~= testSystem then
        warn("❌ Failed to retrieve registered system")
        return false
    end
    print("✅ Successfully retrieved registered system")
    
    -- Test 6: Configuration Updates
    print("\n🧪 Test 5: Configuration Updates")
    local updateSuccess, updateError = MainModule.updateConfig({
        debug = false,
        defaultSettings = {
            volume = 0.8
        }
    })
    
    if not updateSuccess then
        warn("❌ Configuration update failed:", updateError)
        return false
    end
    
    local updatedConfig = MainModule.getConfig()
    if updatedConfig.debug ~= false or updatedConfig.defaultSettings.volume ~= 0.8 then
        warn("❌ Configuration not updated correctly")
        return false
    end
    print("✅ Configuration updated successfully")
    
    -- Cleanup
    unregister()
    
    print("\n🎉 All MainModule tests passed successfully!")
    return true
end

-- Run the test
local success = runTest()
if not success then
    warn("❌ Some tests failed. Check the output above for details.")
end

return success

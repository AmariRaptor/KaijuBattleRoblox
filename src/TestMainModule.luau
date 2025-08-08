--!strict
-- Test script for MainModule functionality

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Load the MainModule
local MainModule = require(script.Parent.shared.MainModule)

-- Test function
local function testMainModule()
    print("🔍 Starting MainModule tests...")
    
    -- Test 1: Check if MainModule is a table
    if type(MainModule) ~= "table" then
        error("❌ MainModule is not a table")
    end
    print("✅ MainModule is a table")
    
    -- Test 2: Check if init function exists
    if type(MainModule.init) ~= "function" then
        error("❌ MainModule.init is not a function")
    end
    print("✅ MainModule.init is a function")
    
    -- Test 3: Initialize the module
    local success, result = MainModule.init()
    if not success then
        error("❌ MainModule.init failed: " .. tostring(result))
    end
    print("✅ MainModule initialized successfully")
    
    -- Test 4: Try to initialize again (should return false)
    success, result = MainModule.init()
    if success then
        error("❌ MainModule allowed multiple initializations")
    end
    print("✅ MainModule correctly prevents multiple initializations")
    
    -- Test 5: Check if getConfig function exists and returns expected structure
    if type(MainModule.getConfig) ~= "function" then
        error("❌ MainModule.getConfig is not a function")
    end
    
    local config = MainModule.getConfig()
    if type(config) ~= "table" then
        error("❌ MainModule.getConfig() did not return a table")
    end
    
    if type(config.debug) ~= "boolean" then
        error("❌ Config debug flag is not a boolean")
    end
    
    if type(config.maxPlayers) ~= "number" then
        error("❌ Config maxPlayers is not a number")
    end
    
    print("✅ MainModule configuration is valid")
    
    print("\n🎉 All MainModule tests passed successfully!")
    return true
end

-- Run the tests
local success, err = pcall(testMainModule)
if not success then
    warn("❌ Test failed:", err)
else
    print("\n✅ All tests completed successfully!")
end

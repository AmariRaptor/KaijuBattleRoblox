--!strict
-- Test script for the refactored MainModule

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MainModule = require(ReplicatedStorage.MainModule)

-- Test 1: Check initialization state
print("\n=== Test 1: Initial State ===")
local isInitialized = MainModule.isInitialized()
print("Is initialized:", isInitialized)
assert(not isInitialized, "Module should not be initialized yet")

-- Test 2: Initialize the module
print("\n=== Test 2: Initialize ===")
local success, err = MainModule.init()
print("Init result:", success, err or "")
assert(success, "Failed to initialize MainModule: " .. tostring(err))

-- Test 3: Verify initialization state
print("\n=== Test 3: Verify Initialization ===")
isInitialized = MainModule.isInitialized()
print("Is initialized:", isInitialized)
assert(isInitialized, "Module should be initialized now")

-- Test 4: Get default config
print("\n=== Test 4: Default Config ===")
local config = MainModule.getConfig()
print("Default config:", game:GetService("HttpService"):JSONEncode(config))
assert(type(config) == "table", "Config should be a table")
assert(config.debug ~= nil, "Config should have debug field")

-- Test 5: Update config
print("\n=== Test 5: Update Config ===")
success, err = MainModule.updateConfig({
    debug = false,
    maxPlayers = 8,
    defaultSettings = {
        volume = 0.8
    }
})
print("Update result:", success, err or "")
assert(success, "Failed to update config: " .. tostring(err))

-- Verify config update
local updatedConfig = MainModule.getConfig()
print("Updated config:", game:GetService("HttpService"):JSONEncode(updatedConfig))
assert(updatedConfig.debug == false, "Debug should be false")
assert(updatedConfig.maxPlayers == 8, "maxPlayers should be 8")
assert(updatedConfig.defaultSettings.volume == 0.8, "Volume should be 0.8")
assert(updatedConfig.defaultSettings.difficulty == "normal", "Difficulty should remain 'normal'")

-- Test 6: System registration
print("\n=== Test 6: System Registration ===")
local testSystem = { name = "TestSystem", version = "1.0.0" }
success, err = MainModule.registerSystem("TestSystem", testSystem)
print("Register system result:", success, err or "")
assert(success, "Failed to register system: " .. tostring(err))

-- Test 7: Get registered system
print("\n=== Test 7: Get System ===")
local system = MainModule.getSystem("TestSystem")
print("Got system:", system and "success" or "failed")
assert(system ~= nil, "Failed to get registered system")
assert(system.name == "TestSystem", "System name should be 'TestSystem'")

-- Test 8: Event system
print("\n=== Test 8: Event System ===")
local eventReceived = false
local unregister = MainModule.on("testEvent", function(message)
    print("Event received:", message)
    eventReceived = true
end)

print("Emitting test event...")
MainModule.emit("testEvent", "Hello from test!")
task.wait(0.1) -- Give time for the event to process
assert(eventReceived, "Event handler was not called")

-- Test 9: Unregister event
print("\n=== Test 9: Unregister Event ===")
eventReceived = false
unregister()
MainModule.emit("testEvent", "This should not be received")
task.wait(0.1)
assert(not eventReceived, "Event handler should have been unregistered")

print("\n✅ All tests passed successfully!")

return {
    success = true,
    config = MainModule.getConfig(),
    isInitialized = MainModule.isInitialized()
}

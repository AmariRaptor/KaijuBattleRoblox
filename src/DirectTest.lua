-- DirectTest.lua
-- A minimal test that directly tests the ClassSystem

print("=== Starting Direct Test ===")

-- Try to require the actual ClassSystem module
local success, classSystem = pcall(function()
    return require(game:GetService("ServerScriptService").systems.ClassSystem)
end)

if not success then
    print("❌ Failed to load ClassSystem:", tostring(classSystem))
    return false
end

print("✅ Successfully loaded ClassSystem")

-- Create a simple test
local function testClassSystem()
    print("\nTesting ClassSystem...")
    
    -- Create a mock player
    local player = {
        Name = "TestPlayer",
        Character = {Name = "TestCharacter"}
    }
    
    -- Call onPlayerAdded
    print("Calling onPlayerAdded...")
    local playerClass = classSystem.onPlayerAdded(player)
    
    -- Verify the result
    if not playerClass then
        return false, "onPlayerAdded returned nil"
    end
    
    if playerClass.Name ~= "PlayerClass" then
        return false, "PlayerClass name is incorrect: " .. tostring(playerClass.Name)
    end
    
    if playerClass.Parent ~= player then
        return false, "PlayerClass parent is not set to player"
    end
    
    -- Check if the assigned class is valid
    local isValidClass = false
    for _, className in ipairs(classSystem.CLASSES or {}) do
        if className == playerClass.Value then
            isValidClass = true
            break
        end
    end
    
    if not isValidClass then
        return false, "Assigned class is not valid: " .. tostring(playerClass.Value)
    end
    
    return true, "All tests passed!"
end

-- Run the test
local testSuccess, testMessage = pcall(testClassSystem)
if testSuccess and type(testMessage) == "string" and testMessage:find("passed") then
    print("\n✅ " .. testMessage)
    return true
else
    local errorMsg = testSuccess and tostring(testMessage) or tostring(testMessage)
    print("\n❌ Test failed: " .. errorMsg)
    return false, errorMsg
end

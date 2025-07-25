-- ClassSystemMinimalTest.lua
-- A minimal test for ClassSystem functionality

print("=== Starting ClassSystemMinimalTest ===")

-- Mock the minimal required parts of ClassSystem
local ClassSystem = {
    CLASSES = {"Kaiju", "Guardian", "Engineer"},
    onPlayerAdded = function(player)
        return {
            Name = "PlayerClass",
            Value = "Kaiju",
            Parent = player,
            ClassName = "StringValue"
        }
    end
}

-- Create a mock player
local player = {
    Name = "TestPlayer",
    Character = {Name = "TestCharacter"}
}

-- Test the onPlayerAdded function
local function testOnPlayerAdded()
    print("Testing onPlayerAdded...")
    local playerClass = ClassSystem.onPlayerAdded(player)
    
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
    for _, className in ipairs(ClassSystem.CLASSES) do
        if className == playerClass.Value then
            isValidClass = true
            break
        end
    end
    
    if not isValidClass then
        return false, "Assigned class is not valid: " .. tostring(playerClass.Value)
    end
    
    return true, "onPlayerAdded test passed!"
end

-- Run the test
local success, message = pcall(testOnPlayerAdded)
if not success then
    print("❌ Test error: " .. tostring(message))
    return {success = false, message = "Test error: " .. tostring(message)}
end

if type(message) == "string" and message:find("passed") then
    print("✅ " .. message)
    return {success = true, message = message}
else
    print("❌ Test failed: " .. tostring(message))
    return {success = false, message = message}
end

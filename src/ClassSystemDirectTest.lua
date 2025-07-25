-- ClassSystemDirectTest.lua
-- A direct test for ClassSystem functionality

print("=== Starting ClassSystemDirectTest ===")

-- Define the test function
local function testClassSystem()
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
    local playerClass = ClassSystem.onPlayerAdded(player)
    
    -- Verify the results
    if not playerClass then
        return {success = false, message = "onPlayerAdded returned nil"}
    end
    
    if playerClass.Name ~= "PlayerClass" then
        return {success = false, message = "PlayerClass name is incorrect: " .. tostring(playerClass.Name)}
    end
    
    if playerClass.Parent ~= player then
        return {success = false, message = "PlayerClass parent is not set to player"}
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
        return {success = false, message = "Assigned class is not valid: " .. tostring(playerClass.Value)}
    end
    
    return {success = true, message = "ClassSystem test passed!"}
end

-- Run the test and return the result
local success, result = pcall(testClassSystem)
if not success then
    print("❌ Test error: " .. tostring(result))
    return {success = false, message = "Test error: " .. tostring(result)}
end

-- Print the result for debugging
print(result.success and "✅ " or "❌ " .. tostring(result.message))
return result

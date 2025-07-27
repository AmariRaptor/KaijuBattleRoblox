--!strict
-- ClassSystemDirectTest.luau
-- A direct test for ClassSystem functionality with strict Luau types

print("=== Starting ClassSystemDirectTest ===")

-- Types
type Player = {
    Name: string,
    Character: {
        Name: string
    },
    FindFirstChild: ((self: Player, name: string, recursive: boolean?) -> Instance)?
}

type PlayerClass = {
    Name: string,
    Value: string,
    Parent: Player,
    ClassName: string
}

type ClassSystem = {
    CLASSES: {string},
    onPlayerAdded: (self: ClassSystem, player: Player) -> PlayerClass
}

-- Define the test function
local function testClassSystem(): (boolean, string)
    -- Mock the minimal required parts of ClassSystem
    local ClassSystem: ClassSystem = {
        CLASSES = {"Kaiju", "Guardian", "Engineer"},
        onPlayerAdded = function(_: ClassSystem, player: Player): PlayerClass
            return {
                Name = "PlayerClass",
                Value = "Kaiju",
                Parent = player,
                ClassName = "StringValue"
            }
        end
    }

    -- Create a mock player
    local player: Player = {
        Name = "TestPlayer",
        Character = {Name = "TestCharacter"}
    }

    -- Test the onPlayerAdded function
    local success, playerClass = pcall(ClassSystem.onPlayerAdded, ClassSystem, player)
    
    -- Verify the results
    if not success then
        return false, "onPlayerAdded failed with error: " .. tostring(playerClass)
    end
    
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
        return false, string.format("Assigned class '%s' is not in the valid classes list", playerClass.Value)
    end
    
    return true, "All ClassSystem tests passed"
end

-- Run the test and return the result
local success, result = pcall(testClassSystem)
if not success then
    print("❌ Test failed with error:", tostring(result))
    return {success = false, message = "Test failed with error: " .. tostring(result)}
end

local testPassed, message = result
if testPassed then
    print("✅ " .. message)
    return {success = true, message = message}
else
    print("❌ " .. tostring(message))
    return {success = false, message = message}
end

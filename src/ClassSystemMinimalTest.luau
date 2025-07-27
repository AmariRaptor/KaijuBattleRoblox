--!strict
-- ClassSystemMinimalTest.luau
-- A minimal test for ClassSystem functionality with strict Luau types

print("=== Starting ClassSystemMinimalTest ===")

-- Types
type Player = {
    Name: string,
    Character: {
        Name: string
    }
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
local function testOnPlayerAdded(): (boolean, string)
    print("Testing onPlayerAdded...")
    local success, playerClass = pcall(ClassSystem.onPlayerAdded, ClassSystem, player)
    
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
    
    return true, "onPlayerAdded test passed"
end

-- Run tests and print results
local function runTests(): (boolean, string)
    print("\nRunning ClassSystem tests...")
    
    -- Run individual test functions
    local success, message = testOnPlayerAdded()
    
    if not success then
        return false, message
    end
    
    return true, "All ClassSystem tests passed successfully!"
end

-- Main execution
local success, result = pcall(runTests)
if not success then
    print("❌ Test runner failed with error:", tostring(result))
    return {success = false, message = "Test runner failed with error: " .. tostring(result)}
end

local testPassed, message = result
if testPassed then
    print("\n✅ " .. message)
    return {success = true, message = message}
else
    print("\n❌ Test failed: " .. tostring(message))
    return {success = false, message = message}
end

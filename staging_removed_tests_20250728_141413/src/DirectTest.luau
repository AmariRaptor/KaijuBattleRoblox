--!strict
-- DirectTest.luau
-- A minimal test that directly tests the ClassSystem with strict Luau types

print("=== Starting Direct Test ===")

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

-- Try to require the actual ClassSystem module
local success, classSystem = pcall(function()
    return require(game:GetService("ServerScriptService").systems.ClassSystem) :: ClassSystem
end)

if not success then
    print("❌ Failed to load ClassSystem:", tostring(classSystem))
    return {success = false, message = "Failed to load ClassSystem: " .. tostring(classSystem)}
end

print("✅ Successfully loaded ClassSystem")

-- Create a simple test
local function testClassSystem(): (boolean, string)
    print("\nTesting ClassSystem...")
    
    -- Create a mock player
    local player: Player = {
        Name = "TestPlayer",
        Character = {Name = "TestCharacter"}
    }
    
    -- Call onPlayerAdded
    print("Calling onPlayerAdded...")
    local success, playerClass = pcall(classSystem.onPlayerAdded, classSystem, player)
    
    if not success then
        return false, "onPlayerAdded failed with error: " .. tostring(playerClass)
    end
    
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
        return false, string.format("Assigned class '%s' is not in the valid classes list", playerClass.Value)
    end
    
    return true, "ClassSystem test passed"
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

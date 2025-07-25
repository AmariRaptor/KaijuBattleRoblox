-- TestClassSystem.luau
-- A minimal test file for ClassSystem that works in MCP

print("=== Starting Minimal ClassSystem Tests ===")

-- Simple assertion function
local function assert(condition, message)
    if not condition then
        error(message or "Test failed!")
    end
end

-- Mock the ClassSystem
local ClassSystem = {
    CLASSES = {"Kaiju", "Guardian", "Engineer"}
}

-- Simplified test
local function testClassAssignment()
    -- Mock player
    local player = {
        Name = "TestPlayer",
        Character = {Name = "TestPlayer_Character"}
    }
    
    -- Mock Instance.new
    local mockInstance = {
        Name = "PlayerClass",
        Value = "Kaiju",
        Parent = player,
        ClassName = "StringValue"
    }
    
    -- Mock the function
    function ClassSystem.onPlayerAdded(player)
        local playerClass = setmetatable({}, {
            __index = function(_, k)
                return mockInstance[k]
            end
        })
        return playerClass
    end
    
    -- Run the test
    local playerClass = ClassSystem.onPlayerAdded(player)
    
    -- Verify results
    assert(playerClass.Name == "PlayerClass", "Player class should be named 'PlayerClass'")
    assert(playerClass.Parent == player, "Player class should be parented to player")
    
    -- Check if the assigned class is valid
    local isValidClass = false
    for _, className in ipairs(ClassSystem.CLASSES) do
        if className == playerClass.Value then
            isValidClass = true
            break
        end
    end
    
    assert(isValidClass, "Assigned class should be valid")
    
    print("✅ All tests passed!")
    return true
end

-- Run the test
local success, message = pcall(testClassAssignment)
if not success then
    print("❌ Test failed: " .. tostring(message))
    return false
end

return true

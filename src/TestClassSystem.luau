-- TestClassSystem.lua
-- Minimal test file for ClassSystem

print("=== Starting ClassSystem Test ===")

-- Simple test function
local function runTest()
    -- Mock player
    local player = {
        Name = "TestPlayer"
    }
    
    -- Mock class system
    local ClassSystem = {
        CLASSES = {"Kaiju", "Guardian", "Engineer"},
        onPlayerAdded = function(player)
            return {
                Name = "PlayerClass",
                Value = "Kaiju",
                Parent = player
            }
        end
    }
    
    -- Test class assignment
    local playerClass = ClassSystem.onPlayerAdded(player)
    
    -- Verify results
    if playerClass.Name ~= "PlayerClass" then
        return false, "Player class name is incorrect"
    end
    
    if playerClass.Parent ~= player then
        return false, "Player class parent is incorrect"
    end
    
    local isValidClass = false
    for _, className in ipairs(ClassSystem.CLASSES) do
        if className == playerClass.Value then
            isValidClass = true
            break
        end
    end
    
    if not isValidClass then
        return false, "Assigned class is not valid"
    end
    
    return true
end

-- Run the test
local success, message = pcall(runTest)
if success and message == true then
    print("✅ Test passed!")
    return true
else
    local errorMsg = "❌ Test failed: " .. tostring(message or "Unknown error")
    print(errorMsg)
    return false, errorMsg
end

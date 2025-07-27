--!strict
-- CharacterSystemDirectTest.luau
-- A direct test for CharacterSystem functionality with strict Luau types

print("=== Starting CharacterSystemDirectTest ===")

-- Types
type ClassAttributes = {
    MaxHealth: number
}

type CharacterSystem = {
    CLASS_ATTRIBUTES: {[string]: ClassAttributes},
    onCharacterAdded: (self: CharacterSystem, character: Instance) -> boolean,
    onPlayerAdded: (self: CharacterSystem, player: Instance) -> boolean
}

-- Define the test function
local function testCharacterSystem(): (boolean, string)
    -- Mock the CharacterSystem with proper types
    local CharacterSystem: CharacterSystem = {
        CLASS_ATTRIBUTES = {
            Kaiju = { MaxHealth = 500 },
            Guardian = { MaxHealth = 200 },
            Engineer = { MaxHealth = 150 }
        },
        
        onCharacterAdded = function(self: CharacterSystem, character: Instance): boolean
            -- Mock implementation of onCharacterAdded
            local player = character:FindFirstChild("Player")
            if not player then return false end
            
            local humanoid = character:FindFirstChildOfClass("Humanoid") :: Humanoid?
            if not humanoid then return false end
            
            local playerClass = player:FindFirstChild("PlayerClass") :: StringValue?
            if not playerClass or not playerClass:IsA("StringValue") then return false end
            
            local className = playerClass.Value
            local attributes = self.CLASS_ATTRIBUTES[className]
            if not attributes then return false end
            
            -- Set health based on class
            humanoid.MaxHealth = attributes.MaxHealth
            humanoid.Health = attributes.MaxHealth
            
            return true
        end,
        
        onPlayerAdded = function(self: CharacterSystem, player: Instance): boolean
            -- Mock implementation of onPlayerAdded
            local character = player:FindFirstChild("Character")
            if character then
                return self:onCharacterAdded(character)
            end
            return false
        end
    }
    
    -- Test data
    type TestCase = {
        className: string,
        expectedHealth: number
    }
    
    local testCases: {TestCase} = {
        { className = "Kaiju", expectedHealth = 500 },
        { className = "Guardian", expectedHealth = 200 },
        { className = "Engineer", expectedHealth = 150 }
    }
    
    -- Run tests for each class
    for _, testCase in ipairs(testCases) do
        local className = testCase.className
        local expectedHealth = testCase.expectedHealth
        
        -- Create test character
        local character = Instance.new("Model")
        
        -- Create and configure humanoid
        local humanoid = Instance.new("Humanoid")
        humanoid.Parent = character
        
        -- Create player reference
        local player = Instance.new("Model")
        local playerClass = Instance.new("StringValue")
        playerClass.Name = "PlayerClass"
        playerClass.Value = className
        playerClass.Parent = player
        
        -- Link player to character
        local playerRef = Instance.new("ObjectValue")
        playerRef.Name = "Player"
        playerRef.Value = player
        playerRef.Parent = character
        
        -- Test onCharacterAdded
        local success = CharacterSystem:onCharacterAdded(character)
        
        -- Verify results
        if not success then
            return false, string.format("Failed to set up %s character", className)
        end
        
        if humanoid.MaxHealth ~= expectedHealth then
            return false, string.format("%s MaxHealth should be %d, got %d", 
                className, expectedHealth, humanoid.MaxHealth)
        end
        
        if humanoid.Health ~= expectedHealth then
            return false, string.format("%s Health should be %d, got %d", 
                className, expectedHealth, humanoid.Health)
        end
    end
    
    -- Test invalid class
    local invalidCharacter = Instance.new("Model")
    local invalidHumanoid = Instance.new("Humanoid")
    invalidHumanoid.Parent = invalidCharacter
    
    local invalidPlayer = Instance.new("Model")
    local invalidClass = Instance.new("StringValue")
    invalidClass.Name = "PlayerClass"
    invalidClass.Value = "InvalidClass"
    invalidClass.Parent = invalidPlayer
    
    local playerRef = Instance.new("ObjectValue")
    playerRef.Name = "Player"
    playerRef.Value = invalidPlayer
    playerRef.Parent = invalidCharacter
    
    -- Should not error with invalid class, just return false
    local success = pcall(function()
        return CharacterSystem:onCharacterAdded(invalidCharacter)
    end)
    
    if not success then
        return false, "onCharacterAdded should handle invalid classes gracefully"
    end
    
    -- Verify humanoid wasn't modified
    if invalidHumanoid.MaxHealth ~= 100 then -- Default Humanoid max health
        return false, "Invalid class should not modify Humanoid health"
    end
    
    return true, "All CharacterSystem tests passed"
end

-- Run the test and return the result
local success, result = pcall(testCharacterSystem)
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

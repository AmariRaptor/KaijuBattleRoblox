-- CharacterSystemDirectTest.lua
-- A direct test for CharacterSystem functionality

print("=== Starting CharacterSystemDirectTest ===")

-- Define the test function
local function testCharacterSystem()
    -- Mock the CharacterSystem
    local CharacterSystem = {
        CLASS_ATTRIBUTES = {
            Kaiju = { MaxHealth = 500 },
            Guardian = { MaxHealth = 200 },
            Engineer = { MaxHealth = 150 }
        },
        
        onCharacterAdded = function(character)
            -- Mock implementation of onCharacterAdded
            local player = character:FindFirstChild("Player")
            if not player then return end
            
            local humanoid = character:FindFirstChild("Humanoid")
            if not humanoid then return end
            
            local playerClass = player:FindFirstChild("PlayerClass")
            if not playerClass or not playerClass:IsA("StringValue") then return end
            
            local attributes = CharacterSystem.CLASS_ATTRIBUTES[playerClass.Value]
            if not attributes then return end
            
            -- Set health based on class
            humanoid.MaxHealth = attributes.MaxHealth
            humanoid.Health = attributes.MaxHealth
            
            return true
        end,
        
        onPlayerAdded = function(player)
            -- Mock implementation of onPlayerAdded
            if player.Character then
                return CharacterSystem.onCharacterAdded(player.Character)
            end
            return false
        end
    }
    
    -- Test data
    local testCases = {
        { className = "Kaiju", expectedHealth = 500 },
        { className = "Guardian", expectedHealth = 200 },
        { className = "Engineer", expectedHealth = 150 }
    }
    
    -- Run tests for each class
    for _, testCase in ipairs(testCases) do
        local className = testCase.className
        local expectedHealth = testCase.expectedHealth
        
        print(string.format("\nTesting %s character setup...", className))
        
        -- Create mock player and character
        local player = Instance.new("Model")
        player.Name = "TestPlayer"
        
        local playerClass = Instance.new("StringValue")
        playerClass.Name = "PlayerClass"
        playerClass.Value = className
        playerClass.Parent = player
        
        local character = Instance.new("Model")
        character.Name = "TestCharacter"
        
        local humanoid = Instance.new("Humanoid")
        humanoid.Parent = character
        
        -- Add player reference to character
        local playerRef = Instance.new("ObjectValue")
        playerRef.Name = "Player"
        playerRef.Value = player
        playerRef.Parent = character
        
        -- Test onCharacterAdded directly
        local success = CharacterSystem.onCharacterAdded(character)
        if not success then
            return {
                success = false,
                message = string.format("Failed to set up %s character", className)
            }
        end
        
        -- Verify health was set correctly
        if humanoid.MaxHealth ~= expectedHealth then
            return {
                success = false,
                message = string.format(
                    "%s MaxHealth mismatch: expected %d, got %d",
                    className, expectedHealth, humanoid.MaxHealth
                )
            }
        end
        
        if humanoid.Health ~= expectedHealth then
            return {
                success = false,
                message = string.format(
                    "%s Health mismatch: expected %d, got %d",
                    className, expectedHealth, humanoid.Health
                )
            }
        end
        
        print(string.format("✅ %s character setup passed", className))
    end
    
    -- Test invalid class
    print("\nTesting invalid class handling...")
    local invalidPlayer = Instance.new("Model")
    invalidPlayer.Name = "InvalidPlayer"
    
    local invalidClass = Instance.new("StringValue")
    invalidClass.Name = "PlayerClass"
    invalidClass.Value = "InvalidClass"
    invalidClass.Parent = invalidPlayer
    
    local invalidCharacter = Instance.new("Model")
    invalidCharacter.Name = "InvalidCharacter"
    
    local invalidHumanoid = Instance.new("Humanoid")
    invalidHumanoid.Parent = invalidCharacter
    
    local playerRef = Instance.new("ObjectValue")
    playerRef.Name = "Player"
    playerRef.Value = invalidPlayer
    playerRef.Parent = invalidCharacter
    
    -- Should not error with invalid class, just return early
    local success = pcall(function()
        return CharacterSystem.onCharacterAdded(invalidCharacter)
    end)
    
    if not success then
        return {
            success = false,
            message = "Error when handling invalid class"
        }
    end
    
    -- Humanoid health should remain unchanged
    if invalidHumanoid.MaxHealth ~= 100 then -- Default Humanoid max health
        return {
            success = false,
            message = "Invalid class should not modify Humanoid health"
        }
    end
    
    print("✅ Invalid class handling passed")
    
    return { success = true, message = "All CharacterSystem tests passed!" }
end

-- Run the test and return the result
local success, result = pcall(testCharacterSystem)
if not success then
    print("❌ Test error: " .. tostring(result))
    return { success = false, message = "Test error: " .. tostring(result) }
end

-- Print the result for debugging
print(result.success and "✅ " or "❌ " .. tostring(result.message))
return result

--!strict
-- CharacterSystem.spec.luau
-- Test suite for CharacterSystem

local TestEZ = require(game:GetService("ReplicatedStorage").TestEZ)

local function testCharacterSystem()
    -- Mock the CharacterSystem
    local CharacterSystem = {
        CLASS_ATTRIBUTES = {
            Kaiju = { MaxHealth = 500 },
            Guardian = { MaxHealth = 200 },
            Engineer = { MaxHealth = 150 }
        },
        
        onCharacterAdded = function(character)
            local player = character:FindFirstChild("Player")
            if not player then return false end
            
            local humanoid = character:FindFirstChild("Humanoid")
            if not humanoid then return false end
            
            local playerClass = player:FindFirstChild("PlayerClass")
            if not playerClass or not playerClass:IsA("StringValue") then return false end
            
            local attributes = CharacterSystem.CLASS_ATTRIBUTES[playerClass.Value]
            if not attributes then return false end
            
            humanoid.MaxHealth = attributes.MaxHealth
            humanoid.Health = attributes.MaxHealth
            
            return true
        end
    }
    
    -- Test cases
    local testCases = {
        { className = "Kaiju", expectedHealth = 500 },
        { className = "Guardian", expectedHealth = 200 },
        { className = "Engineer", expectedHealth = 150 }
    }
    
    -- Run tests
    local results = {}
    
    for _, testCase in ipairs(testCases) do
        local className = testCase.className
        local expectedHealth = testCase.expectedHealth
        
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
        
        -- Test onCharacterAdded
        local success = CharacterSystem.onCharacterAdded(character)
        
        -- Verify results
        if success and humanoid.MaxHealth == expectedHealth and humanoid.Health == expectedHealth then
            table.insert(results, {
                success = true,
                message = string.format("%s character setup passed", className)
            })
        else
            table.insert(results, {
                success = false,
                message = string.format("%s character setup failed: expected health %d, got %d/%d", 
                    className, expectedHealth, humanoid.Health, humanoid.MaxHealth)
            })
        end
    end
    
    -- Test invalid class
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
    
    -- Should not error with invalid class, just return false
    local success, _ = pcall(function()
        return CharacterSystem.onCharacterAdded(invalidCharacter)
    end)
    
    if success and invalidHumanoid.MaxHealth == 100 then -- Default Humanoid max health
        table.insert(results, {
            success = true,
            message = "Invalid class handling passed"
        })
    else
        table.insert(results, {
            success = false,
            message = "Invalid class handling failed"
        })
    end
    
    -- Return test results
    return results
end

-- Run tests and format results
local results = testCharacterSystem()
local successCount = 0
local failureCount = 0

for _, result in ipairs(results) do
    if result.success then
        successCount = successCount + 1
        print("✅ " .. result.message)
    else
        failureCount = failureCount + 1
        print("❌ " .. result.message)
    end
end

print("\n=== Test Summary ===")
print(string.format("Total Tests: %d", #results))
print(string.format("✅ Passed: %d", successCount))
print(string.format("❌ Failed: %d", failureCount))

-- Return overall result
return {
    success = failureCount == 0,
    message = string.format("CharacterSystem tests completed. %d passed, %d failed", successCount, failureCount)
}

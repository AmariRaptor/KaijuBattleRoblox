--!strict
-- CharacterSystem.spec.luau
-- Unit tests for the CharacterSystem module

local Players = game:GetService("Players")

-- Mock the necessary services and modules
local function mockServices()
    -- Create a mock player
    local mockPlayer = Instance.new("Player")
    mockPlayer.Name = "TestPlayer"
    
    -- Create a mock character
    local mockCharacter = Instance.new("Model")
    local humanoid = Instance.new("Humanoid")
    humanoid.Parent = mockCharacter
    
    -- Create a mock PlayerClass
    local playerClass = Instance.new("StringValue")
    playerClass.Name = "PlayerClass"
    playerClass.Value = "Guardian"
    playerClass.Parent = mockPlayer
    
    -- Create a mock CharacterSystem
    local CharacterSystem = require(script.Parent.src.server_code.systems.CharacterSystem.server)
    
    return {
        CharacterSystem = CharacterSystem,
        mockPlayer = mockPlayer,
        mockCharacter = mockCharacter,
        mockHumanoid = humanoid
    }
end

return function()
    local results = {}
    local mocks = mockServices()
    local CharacterSystem = mocks.CharacterSystem
    local mockPlayer = mocks.mockPlayer
    local mockCharacter = mocks.mockCharacter
    local mockHumanoid = mocks.mockHumanoid
    
    -- Helper function to reset test state
    local function resetTestState()
        -- Clear existing character
        mockPlayer.Character = nil
        
        -- Reset mock character
        mockCharacter:ClearAllChildren()
        mockHumanoid = Instance.new("Humanoid")
        mockHumanoid.Parent = mockCharacter
        
        -- Reset PlayerClass
        local playerClass = mockPlayer:FindFirstChild("PlayerClass")
        if playerClass then
            playerClass.Value = "Guardian"
        end
    end
    
    -- Test 1: Initialize CharacterSystem
    do
        resetTestState()
        
        local success = pcall(function()
            CharacterSystem.init()
        end)
        
        if success then
            table.insert(results, "✅ CharacterSystem initializes successfully")
        else
            table.insert(results, "❌ CharacterSystem failed to initialize")
        end
    end
    
    -- Test 2: Test getClassAttributes
    do
        resetTestState()
        
        local attributes = CharacterSystem.getClassAttributes("Guardian")
        if attributes and attributes.MaxHealth == 200 then
            table.insert(results, "✅ getClassAttributes returns correct Guardian attributes")
        else
            table.insert(results, "❌ getClassAttributes failed to return Guardian attributes")
        end
        
        local invalidAttributes = CharacterSystem.getClassAttributes("InvalidClass")
        if invalidAttributes == nil then
            table.insert(results, "✅ getClassAttributes returns nil for invalid class")
        else
            table.insert(results, "❌ getClassAttributes should return nil for invalid class")
        end
    end
    
    -- Test 3: Test character setup with different classes
    local testClasses = {
        {name = "Guardian", health = 200, speed = 16},
        {name = "Kaiju", health = 500, speed = 24},
        {name = "Engineer", health = 150, speed = 18}
    }
    
    for _, classInfo in ipairs(testClasses) do
        resetTestState()
        
        -- Set player class
        local playerClass = mockPlayer:FindFirstChild("PlayerClass")
        playerClass.Value = classInfo.name
        
        -- Set up character
        mockPlayer.Character = mockCharacter
        
        -- Call onCharacterAdded directly
        CharacterSystem.onCharacterAdded(mockCharacter)
        
        -- Verify attributes
        if math.floor(mockHumanoid.MaxHealth) == classInfo.health then
            table.insert(results, string.format("✅ %s has correct MaxHealth: %d", 
                classInfo.name, classInfo.health))
        else
            table.insert(results, string.format("❌ %s has incorrect MaxHealth. Expected: %d, Got: %d", 
                classInfo.name, classInfo.health, math.floor(mockHumanoid.MaxHealth)))
        end
        
        if math.floor(mockHumanoid.WalkSpeed) == classInfo.speed then
            table.insert(results, string.format("✅ %s has correct WalkSpeed: %d", 
                classInfo.name, classInfo.speed))
        else
            table.insert(results, string.format("❌ %s has incorrect WalkSpeed. Expected: %d, Got: %d", 
                classInfo.name, classInfo.speed, math.floor(mockHumanoid.WalkSpeed)))
        end
        
        -- Verify class tag
        local classTag = mockCharacter:FindFirstChild("ClassTag")
        if classTag and classTag.Value == classInfo.name then
            table.insert(results, string.format("✅ %s has correct ClassTag", classInfo.name))
        else
            table.insert(results, string.format("❌ %s has incorrect or missing ClassTag", classInfo.name))
        end
    end
    
    -- Test 4: Test error cases
    do
        resetTestState()
        
        -- Test with invalid player class
        local playerClass = mockPlayer:FindFirstChild("PlayerClass")
        playerClass.Value = "InvalidClass"
        
        -- This should not error but should log a warning
        local success = pcall(function()
            CharacterSystem.onCharacterAdded(mockCharacter)
        end)
        
        if success then
            table.insert(results, "✅ Handles invalid class gracefully")
        else
            table.insert(results, "❌ Failed to handle invalid class")
        end
        
        -- Test with missing humanoid
        resetTestState()
        mockCharacter:ClearAllChildren() -- Remove humanoid
        
        -- This should not error but should log a warning
        local success = pcall(function()
            CharacterSystem.onCharacterAdded(mockCharacter)
        end)
        
        if success then
            table.insert(results, "✅ Handles missing humanoid gracefully")
        else
            table.insert(results, "❌ Failed to handle missing humanoid")
        end
    end
    
    return results
end

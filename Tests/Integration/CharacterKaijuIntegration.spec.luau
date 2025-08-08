--!strict
-- CharacterKaijuIntegration.spec.luau
-- Integration tests for CharacterSystem and KaijuSystem interaction

local Players = game:GetService("Players")

-- Mock the necessary services and modules
local function mockServices()
    -- Create mock services
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    
    -- Create mock player
    local mockPlayer = Instance.new("Player")
    mockPlayer.Name = "TestPlayer"
    
    -- Create mock character
    local mockCharacter = Instance.new("Model")
    local humanoid = Instance.new("Humanoid")
    humanoid.Parent = mockCharacter
    
    -- Set up PlayerClass
    local playerClass = Instance.new("StringValue")
    playerClass.Name = "PlayerClass"
    playerClass.Value = "Kaiju"
    playerClass.Parent = mockPlayer
    
    -- Load systems
    local CharacterSystem = require(script.Parent.Parent.src.server_code.systems.CharacterSystem.server)
    local KaijuSystem = require(script.Parent.Parent.src.server_code.systems.KaijuSystem.server)
    
    -- Initialize systems
    CharacterSystem.init()
    local kaijuSystem = KaijuSystem.new()
    
    return {
        CharacterSystem = CharacterSystem,
        KaijuSystem = kaijuSystem,
        mockPlayer = mockPlayer,
        mockCharacter = mockCharacter,
        mockHumanoid = humanoid
    }
end

return function()
    local results = {}
    local mocks = mockServices()
    local CharacterSystem = mocks.CharacterSystem
    local KaijuSystem = mocks.KaijuSystem
    local mockPlayer = mocks.mockPlayer
    local mockCharacter = mocks.mockCharacter
    
    -- Helper function to reset test state
    local function resetTestState()
        -- Clear existing character
        mockPlayer.Character = nil
        
        -- Reset mock character
        mockCharacter:ClearAllChildren()
        local humanoid = Instance.new("Humanoid")
        humanoid.Parent = mockCharacter
        
        -- Reset PlayerClass
        local playerClass = mockPlayer:FindFirstChild("PlayerClass")
        if playerClass then
            playerClass.Value = "Kaiju"
        end
    end
    
    -- Test 1: Kaiju character setup
    do
        resetTestState()
        
        -- Set up character
        mockPlayer.Character = mockCharacter
        CharacterSystem.onCharacterAdded(mockCharacter)
        
        -- Verify character has Kaiju attributes
        local humanoid = mockCharacter:FindFirstChildOfClass("Humanoid")
        if humanoid and math.floor(humanoid.MaxHealth) == 500 then
            table.insert(results, "✅ Kaiju character has correct MaxHealth")
        else
            table.insert(results, "❌ Kaiju character has incorrect MaxHealth")
        end
        
        -- Spawn Kaiju
        local kaiju = KaijuSystem:spawnKaiju(mockPlayer)
        
        -- Verify Kaiju was created
        if kaiju and kaiju:IsA("Model") then
            table.insert(results, "✅ Kaiju model was created successfully")
            
            -- Verify Kaiju abilities
            local energyBeam = kaiju:FindFirstChild("EnergyBeam")
            local roar = kaiju:FindFirstChild("Roar")
            
            if energyBeam and energyBeam:IsA("RemoteEvent") then
                table.insert(results, "✅ Kaiju has EnergyBeam ability")
            else
                table.insert(results, "❌ Kaiju is missing EnergyBeam ability")
            end
            
            if roar and roar:IsA("Sound") then
                table.insert(results, "✅ Kaiju has Roar ability")
            else
                table.insert(results, "❌ Kaiju is missing Roar ability")
            end
        else
            table.insert(results, "❌ Failed to create Kaiju model")
        end
    end
    
    -- Test 2: Class change after character creation
    do
        resetTestState()
        
        -- Set up initial character as Guardian
        local playerClass = mockPlayer:FindFirstChild("PlayerClass")
        playerClass.Value = "Guardian"
        
        -- Set up character
        mockPlayer.Character = mockCharacter
        CharacterSystem.onCharacterAdded(mockCharacter)
        
        -- Verify initial class
        local humanoid = mockCharacter:FindFirstChildOfClass("Humanoid")
        if humanoid and math.floor(humanoid.MaxHealth) == 200 then
            table.insert(results, "✅ Initial Guardian setup has correct MaxHealth")
        else
            table.insert(results, "❌ Initial Guardian setup has incorrect MaxHealth")
        end
        
        -- Change to Kaiju class
        playerClass.Value = "Kaiju"
        
        -- Simulate character respawn
        mockCharacter:ClearAllChildren()
        local newHumanoid = Instance.new("Humanoid")
        newHumanoid.Parent = mockCharacter
        
        -- Set up character again
        CharacterSystem.onCharacterAdded(mockCharacter)
        
        -- Verify new class attributes
        humanoid = mockCharacter:FindFirstChildOfClass("Humanoid")
        if humanoid and math.floor(humanoid.MaxHealth) == 500 then
            table.insert(results, "✅ Class change to Kaiju applied correctly")
        else
            table.insert(results, "❌ Class change to Kaiju not applied correctly")
        end
    end
    
    -- Test 3: Ability usage
    do
        resetTestState()
        
        -- Set up character
        mockPlayer.Character = mockCharacter
        CharacterSystem.onCharacterAdded(mockCharacter)
        
        -- Spawn Kaiju
        local kaiju = KaijuSystem:spawnKaiju(mockPlayer)
        
        if kaiju then
            -- Test EnergyBeam
            local energyBeam = kaiju:FindFirstChild("EnergyBeam")
            if energyBeam and energyBeam:IsA("RemoteEvent") then
                -- This would normally be called from the client
                energyBeam:FireServer(Vector3.new(0, 0, 0))
                table.insert(results, "✅ EnergyBeam can be triggered")
            else
                table.insert(results, "❌ EnergyBeam RemoteEvent not found")
            end
            
            -- Test Roar
            local roarEvent = kaiju:FindFirstChild("RoarEvent")
            if roarEvent and roarEvent:IsA("RemoteEvent") then
                -- This would normally be called from the client
                roarEvent:FireServer()
                table.insert(results, "✅ Roar can be triggered")
            else
                table.insert(results, "❌ RoarEvent RemoteEvent not found")
            end
        else
            table.insert(results, "❌ Cannot test abilities - Kaiju not created")
        end
    end
    
    return results
end

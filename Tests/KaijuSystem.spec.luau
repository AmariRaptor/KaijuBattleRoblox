--!strict
-- KaijuSystem.spec.luau
-- Unit tests for the KaijuSystem module

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Mock the necessary services and modules
local function mockServices()
    local mockPlayer = {
        Name = "TestPlayer",
        Character = Instance.new("Model")
    }
    
    -- Create a mock KaijuSystem
    local KaijuSystem = require(script.Parent.src.server_code.systems.KaijuSystem.server)
    
    return {
        KaijuSystem = KaijuSystem,
        mockPlayer = mockPlayer
    }
end

return function()
    local results = {}
    local mocks = mockServices()
    local KaijuSystem = mocks.KaijuSystem
    local mockPlayer = mocks.mockPlayer
    
    -- Test 1: Create a new KaijuSystem instance
    do
        local system = KaijuSystem.new()
        if typeof(system) == "table" then
            table.insert(results, "✅ KaijuSystem.new() returns a table")
        else
            table.insert(results, "❌ KaijuSystem.new() should return a table")
        end
    end
    
    -- Test 2: Spawn a Kaiju for a player
    do
        local system = KaijuSystem.new()
        local kaiju = system:spawnKaiju(mockPlayer)
        
        if kaiju and kaiju:IsA("Model") then
            table.insert(results, "✅ spawnKaiju() returns a Model")
            
            -- Verify Kaiju has required components
            local humanoid = kaiju:FindFirstChildOfClass("Humanoid")
            local hitbox = kaiju:FindFirstChild("HumanoidRootPart")
            
            if humanoid then
                table.insert(results, "✅ Kaiju has a Humanoid")
            else
                table.insert(results, "❌ Kaiju is missing Humanoid")
            end
            
            if hitbox then
                table.insert(results, "✅ Kaiju has a HumanoidRootPart")
            else
                table.insert(results, "❌ Kaiju is missing HumanoidRootPart")
            end
        else
            table.insert(results, "❌ spawnKaiju() should return a Model")
        end
    end
    
    -- Test 3: Test ability setup
    do
        local system = KaijuSystem.new()
        local kaiju = system:spawnKaiju(mockPlayer)
        
        -- Test EnergyBeam ability
        local energyBeam = kaiju:FindFirstChild("EnergyBeam")
        if energyBeam and energyBeam:IsA("RemoteEvent") then
            table.insert(results, "✅ EnergyBeam RemoteEvent is created")
            
            -- Test ability usage
            system:onAbilityUsed(mockPlayer, "EnergyBeam", {target = Vector3.new(0, 0, 0)})
            -- If we get here without error, the test passes
            table.insert(results, "✅ EnergyBeam ability can be used")
        else
            table.insert(results, "❌ EnergyBeam RemoteEvent is missing or invalid")
        end
        
        -- Test Roar ability
        local roarSound = kaiju:FindFirstChild("Roar")
        local roarEvent = kaiju:FindFirstChild("RoarEvent")
        
        if roarSound and roarSound:IsA("Sound") then
            table.insert(results, "✅ Roar Sound is created")
        else
            table.insert(results, "❌ Roar Sound is missing or invalid")
        end
        
        if roarEvent and roarEvent:IsA("RemoteEvent") then
            table.insert(results, "✅ RoarEvent RemoteEvent is created")
            
            -- Test roar ability usage
            system:onAbilityUsed(mockPlayer, "Roar", {})
            -- If we get here without error, the test passes
            table.insert(results, "✅ Roar ability can be used")
        else
            table.insert(results, "❌ RoarEvent RemoteEvent is missing or invalid")
        end
    end
    
    -- Test 4: Test invalid ability
    do
        local system = KaijuSystem.new()
        local success = pcall(function()
            system:onAbilityUsed(mockPlayer, "InvalidAbility", {})
        end)
        
        if not success then
            table.insert(results, "✅ Invalid ability name is handled gracefully")
        else
            table.insert(results, "❌ Invalid ability name should trigger a warning")
        end
    end
    
    return results
end

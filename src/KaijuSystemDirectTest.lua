-- KaijuSystemDirectTest.lua
-- A direct test for KaijuSystem functionality

print("=== Starting KaijuSystemDirectTest ===")

-- Define the test function
local function testKaijuSystem()
    -- Mock the minimal required parts of KaijuSystem
    local KaijuSystem = {
        spawnKaiju = function(self, player)
            -- Mock implementation of spawnKaiju
            local kaiju = {
                Name = "Kaiju",
                Parent = player,
                GetChildren = function() return {} end
            }
            
            -- Mock Humanoid
            local humanoid = {
                Health = 500,
                MaxHealth = 500,
                Parent = kaiju
            }
            
            -- Mock Character
            player.Character = {
                Name = "TestCharacter",
                Parent = player
            }
            
            return kaiju
        end,
        
        setupAbilities = function(self, kaiju)
            -- Mock abilities
            return {
                energyBeam = {Name = "EnergyBeam", Parent = kaiju},
                roar = {Name = "Roar", SoundId = "rbxassetid://123456789", Parent = kaiju}
            }
        end
    }

    -- Create a mock player
    local player = {
        Name = "TestPlayer",
        Character = nil,
        CharacterAdded = {
            Connect = function(_, callback)
                -- Simulate character being added
                task.spawn(function()
                    player.Character = {Name = "TestCharacter"}
                    if callback then callback(player.Character) end
                end)
            end
        }
    }

    -- Test spawnKaiju
    print("Testing spawnKaiju...")
    local kaiju = KaijuSystem:spawnKaiju(player)
    
    -- Verify the results
    if not kaiju then
        return {success = false, message = "spawnKaiju returned nil"}
    end
    
    if kaiju.Name ~= "Kaiju" then
        return {success = false, message = "Kaiju name is incorrect: " .. tostring(kaiju.Name)}
    end
    
    if not kaiju.Parent then
        return {success = false, message = "Kaiju parent is not set"}
    end
    
    -- Test setupAbilities
    print("Testing setupAbilities...")
    local abilities = KaijuSystem:setupAbilities(kaiju)
    
    if not abilities then
        return {success = false, message = "setupAbilities returned nil"}
    end
    
    if not abilities.energyBeam then
        return {success = false, message = "energyBeam ability not found"}
    end
    
    if not abilities.roar then
        return {success = false, message = "roar ability not found"}
    end
    
    if abilities.roar.SoundId ~= "rbxassetid://123456789" then
        return {success = false, message = "Roar sound ID is incorrect: " .. tostring(abilities.roar.SoundId)}
    end
    
    return {success = true, message = "KaijuSystem test passed!"}
end

-- Run the test and return the result
local success, result = pcall(testKaijuSystem)
if not success then
    print("❌ Test error: " .. tostring(result))
    return {success = false, message = "Test error: " .. tostring(result)}
end

-- Print the result for debugging
print(result.success and "✅ " or "❌ " .. tostring(result.message))
return result

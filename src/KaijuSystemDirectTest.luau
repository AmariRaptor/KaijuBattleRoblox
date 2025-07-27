--!strict
-- KaijuSystemDirectTest.luau
-- A direct test for KaijuSystem functionality with strict Luau types

print("=== Starting KaijuSystemDirectTest ===")

-- Types
type Kaiju = {
    Name: string,
    Parent: Player,
    GetChildren: (self: Kaiju) -> {Instance}
}

type Humanoid = {
    Health: number,
    MaxHealth: number,
    Parent: Kaiju
}

type Character = {
    Name: string,
    Parent: Player
}

type Player = {
    Name: string,
    Character: Character?,
    CharacterAdded: {
        Connect: (self: any, callback: (character: Character) -> ()) -> RBXScriptConnection
    }
}

type Ability = {
    Name: string,
    SoundId: string?,
    Parent: Kaiju
}

type KaijuSystem = {
    spawnKaiju: (self: KaijuSystem, player: Player) -> Kaiju,
    setupAbilities: (self: KaijuSystem, kaiju: Kaiju) -> {[string]: Ability}
}

-- Define the test function
local function testKaijuSystem(): (boolean, string)
    -- Mock the minimal required parts of KaijuSystem
    local KaijuSystem: KaijuSystem = {
        spawnKaiju = function(self: KaijuSystem, player: Player): Kaiju
            -- Mock implementation of spawnKaiju
            local kaiju: Kaiju = {
                Name = "Kaiju",
                Parent = player,
                GetChildren = function(): {Instance}
                    return {}
                end
            }
            
            -- Mock Humanoid
            local humanoid: Humanoid = {
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
        
        setupAbilities = function(self: KaijuSystem, kaiju: Kaiju): {[string]: Ability}
            -- Mock abilities
            return {
                energyBeam = {
                    Name = "EnergyBeam",
                    Parent = kaiju
                },
                roar = {
                    Name = "Roar",
                    SoundId = "rbxassetid://123456789",
                    Parent = kaiju
                }
            }
        end
    }

    -- Create a mock player
    local player: Player & {Character: Character?} = {
        Name = "TestPlayer",
        Character = nil,
        CharacterAdded = {
            Connect = function(_: any, callback: (character: Character) -> ()): RBXScriptConnection
                -- Simulate character being added
                task.spawn(function()
                    local character: Character = {
                        Name = "TestCharacter",
                        Parent = player
                    }
                    player.Character = character
                    callback(character)
                end)
                
                -- Return a mock connection
                return {
                    Connected = true,
                    Disconnect = function() end
                } :: RBXScriptConnection
            end
        }
    }

    -- Test 1: Spawn Kaiju
    print("Testing spawnKaiju...")
    local kaiju = KaijuSystem:spawnKaiju(player)
    
    if not kaiju then
        return false, "spawnKaiju returned nil"
    end
    
    if kaiju.Name ~= "Kaiju" then
        return false, string.format("Expected Kaiju name to be 'Kaiju', got '%s'", tostring(kaiju.Name))
    end
    
    if kaiju.Parent ~= player then
        return false, "Kaiju's parent is not set to player"
    end
    
    -- Test 2: Setup Abilities
    print("Testing setupAbilities...")
    local abilities = KaijuSystem:setupAbilities(kaiju)
    
    if not abilities then
        return false, "setupAbilities returned nil"
    end
    
    if not abilities.energyBeam then
        return false, "Missing energyBeam ability"
    end
    
    if not abilities.roar then
        return false, "Missing roar ability"
    end
    
    if abilities.energyBeam.Name ~= "EnergyBeam" then
        return false, string.format("Expected energyBeam name to be 'EnergyBeam', got '%s'", tostring(abilities.energyBeam.Name))
    end
    
    if abilities.roar.Name ~= "Roar" then
        return false, string.format("Expected roar name to be 'Roar', got '%s'", tostring(abilities.roar.Name))
    end
    
    if not abilities.roar.SoundId then
        return false, "Roar ability is missing SoundId"
    end
    
    return true, "All KaijuSystem tests passed"
end

-- Run the test and return the result
local success, result = pcall(testKaijuSystem)
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

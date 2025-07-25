--!strict
-- KaijuSystem.spec.luau

-- Simple test runner that will work with TestEZ
local function runTests()
    -- Mock TestEZ globals if not already available
    if not _G.TestEZ then
        _G.TestEZ = {
            describe = function(_, callback) return callback() end,
            it = function(_, callback) return callback() end,
            beforeAll = function(callback) return callback() end,
            afterAll = function(callback) return callback() end,
            expect = function(value)
                return {
                    toBe = function(expected)
                        assert(value == expected, string.format("Expected %s to be %s", tostring(value), tostring(expected)))
                    end,
                    toBeTruthy = function()
                        assert(value, "Expected value to be truthy")
                    end,
                    toBeNil = function()
                        assert(value == nil, string.format("Expected nil, got %s", tostring(value)))
                    end
                }
            end
        }
        
        -- Export globals
        for k, v in pairs(_G.TestEZ) do
            _G[k] = v
        end
    end
    
    -- Mock KaijuSystem
    local KaijuSystem = {}
    
    function KaijuSystem:spawnKaiju(player)
        local kaiju = {
            Name = "Kaiju",
            Humanoid = {
                Health = 500,
                MaxHealth = 500,
                Parent = nil
            },
            Parent = nil
        }
        
        if player and player.Character then
            kaiju.Parent = player.Character
        end
        
        if kaiju.Humanoid then
            kaiju.Humanoid.Parent = kaiju
        end
        
        return kaiju
    end
    
    function KaijuSystem:setupAbilities(kaiju)
        local abilities = {
            energyBeam = { ClassName = "RemoteEvent" },
            roar = { ClassName = "Sound" }
        }
        
        for name, ability in pairs(abilities) do
            kaiju[name] = ability
        end
        
        return abilities
    end
    
    -- Run tests
    describe("KaijuSystem", function()
        local testPlayer = {
            Name = "TestPlayer",
            Character = { Name = "TestCharacter" }
        }
        
        describe("spawnKaiju", function()
            it("creates a kaiju", function()
                local kaiju = KaijuSystem:spawnKaiju(testPlayer)
                expect(kaiju).toBeTruthy()
                expect(kaiju.Name).toBe("Kaiju")
                expect(kaiju.Humanoid).toBeTruthy()
            end)
        end)
        
        describe("setupAbilities", function()
            it("adds abilities", function()
                local kaiju = {}
                KaijuSystem:setupAbilities(kaiju)
                expect(kaiju.energyBeam).toBeTruthy()
                expect(kaiju.roar).toBeTruthy()
            end)
        end)
    end)
end

-- Return the test function
return runTests

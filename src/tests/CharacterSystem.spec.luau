--!strict

return function()
    local ServerScriptService = game:GetService("ServerScriptService")

    -- Wait for the modules to be available
    local ClassSystem = require(ServerScriptService.systems.ClassSystem)
    local CharacterSystem = require(ServerScriptService.systems.CharacterSystem)

    describe("CharacterSystem", function()
        it("should set the correct health for a character based on their class", function()
            -- Setup
            local mockPlayer = Instance.new("Folder")
            mockPlayer.Name = "TestPlayer"

            ClassSystem.onPlayerAdded(mockPlayer)
            local playerClassValue = mockPlayer:FindFirstChild("PlayerClass")
            assert(playerClassValue, "Class was not assigned!")

            local mockCharacter = Instance.new("Model")
            local humanoid = Instance.new("Humanoid")
            humanoid.Parent = mockCharacter

            -- Associate character and player for the system to find
            mockCharacter.Parent = game.Workspace
            mockPlayer.Character = mockCharacter

            -- Run
            CharacterSystem.onCharacterAdded(mockCharacter)

            -- Verify
            local CLASS_ATTRIBUTES = {
                Kaiju = { MaxHealth = 500 },
                Guardian = { MaxHealth = 200 },
                Engineer = { MaxHealth = 150 }
            }
            local expectedHealth = CLASS_ATTRIBUTES[playerClassValue.Value].MaxHealth
            expect(humanoid.MaxHealth).to.equal(expectedHealth)
            expect(humanoid.Health).to.equal(expectedHealth)
        end)
    end)
end
